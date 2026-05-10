#!/usr/bin/env python3
# canonical-cli-scoping-allow-large: existing report generator exceeds the Python threshold; this patch adds a bounded security rollup while decomposition remains owned by flywheel-useh.
from __future__ import annotations

import argparse
import base64
import json
import os
import re
import statistics
import subprocess
import sys
from collections import Counter, defaultdict
from datetime import datetime, timezone, timedelta
from pathlib import Path
from typing import Any, Sequence


VERSION = "daily-report.v1"


def utc_now() -> datetime:
    raw = os.environ.get("FLYWHEEL_DAILY_REPORT_NOW")
    if raw:
        parsed = parse_ts(raw)
        if parsed:
            return parsed
    return datetime.now(timezone.utc)


def parse_ts(value: Any) -> datetime | None:
    if value is None:
        return None
    text = str(value).strip()
    if not text:
        return None
    for candidate in (text, text.replace("Z", "+00:00")):
        try:
            parsed = datetime.fromisoformat(candidate)
            if parsed.tzinfo is None:
                parsed = parsed.replace(tzinfo=timezone.utc)
            return parsed.astimezone(timezone.utc)
        except ValueError:
            continue
    return None


def read_json(path: Path) -> Any:
    try:
        return json.loads(path.read_text())
    except Exception:
        return None


def read_jsonl(path: Path, limit: int | None = None) -> list[dict[str, Any]]:
    if not path.exists():
        return []
    rows: list[dict[str, Any]] = []
    try:
        lines = path.read_text(errors="replace").splitlines()
    except Exception:
        return []
    if limit:
        lines = lines[-limit:]
    for line in lines:
        if not line.strip():
            continue
        try:
            row = json.loads(line)
        except Exception:
            continue
        if isinstance(row, dict):
            rows.append(row)
    return rows


def run_json(cmd: list[str], cwd: Path) -> Any:
    try:
        proc = subprocess.run(
            cmd,
            cwd=str(cwd),
            stdout=subprocess.PIPE,
            stderr=subprocess.DEVNULL,
            text=True,
            check=False,
            timeout=20,
        )
    except Exception:
        return None
    try:
        return json.loads(proc.stdout)
    except Exception:
        return None


def normalize_issues(payload: Any) -> list[dict[str, Any]]:
    if isinstance(payload, list):
        return [row for row in payload if isinstance(row, dict)]
    if isinstance(payload, dict):
        for key in ("issues", "beads", "items"):
            rows = payload.get(key)
            if isinstance(rows, list):
                return [row for row in rows if isinstance(row, dict)]
    return []


def issue_id(row: dict[str, Any]) -> str:
    return str(row.get("id") or row.get("bead_id") or row.get("key") or "?")


def issue_title(row: dict[str, Any]) -> str:
    return str(row.get("title") or row.get("summary") or "(untitled)")


def issue_status(row: dict[str, Any]) -> str:
    return str(row.get("status") or row.get("state") or "").lower()


def issue_priority(row: dict[str, Any]) -> str:
    raw = row.get("priority")
    if raw is None:
        raw = row.get("priority_label")
    return str(raw if raw is not None else "?")


def issue_updated(row: dict[str, Any]) -> datetime | None:
    for key in ("updated_at", "closed_at", "created_at", "modified_at"):
        parsed = parse_ts(row.get(key))
        if parsed:
            return parsed
    return None


def load_beads(repo: Path, br_bin: str) -> tuple[list[dict[str, Any]], list[dict[str, Any]]]:
    all_payload = run_json([br_bin, "list", "--all", "--json", "--limit", "0"], repo)
    if all_payload is None:
        all_payload = run_json([br_bin, "list", "--json"], repo)
    ready_payload = run_json([br_bin, "ready", "--json"], repo)
    all_issues = normalize_issues(all_payload)
    ready_issues = normalize_issues(ready_payload)
    issues_jsonl = repo / ".beads" / "issues.jsonl"
    if not all_issues and issues_jsonl.exists():
        all_issues = read_jsonl(issues_jsonl)
    return all_issues, ready_issues


def classify_title(title: str) -> str:
    lowered = title.lower()
    if "validate" in lowered or "redispatch" in lowered:
        return "validate-everything"
    if "jeff" in lowered or "dicklesworth" in lowered:
        return "jeff-substrate"
    if "doctrine" in lowered or "agents.md" in lowered or "l7" in lowered:
        return "doctrine"
    if "ecosystem" in lowered or "watchtower" in lowered:
        return "ecosystem"
    return "other"


def same_utc_date(ts: datetime | None, date_text: str) -> bool:
    return bool(ts and ts.strftime("%Y-%m-%d") == date_text)


def recent_files(directory: Path, since: datetime) -> list[Path]:
    if not directory.exists():
        return []
    rows: list[Path] = []
    for path in directory.glob("*.md"):
        try:
            mtime = datetime.fromtimestamp(path.stat().st_mtime, timezone.utc)
        except OSError:
            continue
        if mtime >= since:
            rows.append(path)
    return sorted(rows, key=lambda p: p.name)


def summarize_dispatch(rows: list[dict[str, Any]], date_text: str) -> tuple[int, int]:
    todays = [row for row in rows if same_utc_date(parse_ts(row.get("ts") or row.get("created_at")), date_text)]
    in_flight = 0
    for row in todays:
        if row.get("callback_received_at"):
            continue
        event = str(row.get("event") or row.get("action") or "")
        if "dispatch" in event or row.get("task_file") or row.get("pane") is not None:
            in_flight += 1
    return len(todays), in_flight


def doctor_json(repo: Path, fixture: Path | None) -> dict[str, Any]:
    if fixture:
        payload = read_json(fixture)
        return payload if isinstance(payload, dict) else {"status": "unknown"}
    loop_bin = os.environ.get("FLYWHEEL_LOOP_BIN", str(Path.home() / ".claude/skills/.flywheel/bin/flywheel-loop"))
    payload = run_json([loop_bin, "doctor", "--repo", str(repo), "--json"], repo)
    return payload if isinstance(payload, dict) else {"status": "unknown", "reason": "doctor_unavailable"}


def state_md_miner_json(repo: Path) -> dict[str, Any]:
    candidates = [
        repo / ".flywheel/scripts/state-md-miner.sh",
        Path.home() / "Developer/flywheel/.flywheel/scripts/state-md-miner.sh",
    ]
    for probe in candidates:
        if not probe.exists():
            continue
        payload = run_json([str(probe), "--repo", str(repo), "--doctor", "--json"], repo)
        if isinstance(payload, dict):
            return payload
    return {
        "schema_version": "state-md-miner/v1",
        "status": "warn",
        "state_md_unmined_count": 0,
        "warnings": [{"code": "state_md_miner_missing"}],
    }


def jeff_storage_projection_json(path: Path) -> dict[str, Any] | None:
    payload = read_json(path)
    return payload if isinstance(payload, dict) else None


def punt_phrase_report_json(repo: Path) -> dict[str, Any]:
    raw = os.environ.get("FLYWHEEL_PUNT_PHRASE_REPORT_JSON")
    if raw:
        try:
            payload = json.loads(raw)
            return payload if isinstance(payload, dict) else {}
        except json.JSONDecodeError:
            return {"schema_version": "flywheel.l70_punt_report.v1", "status": "warn", "event_count": 0}
    file_path = os.environ.get("FLYWHEEL_PUNT_PHRASE_REPORT_JSON_FILE")
    if file_path:
        payload = read_json(Path(file_path).expanduser())
        return payload if isinstance(payload, dict) else {}
    detector = repo / ".flywheel/scripts/punt-phrase-detector.py"
    if not detector.exists():
        detector = Path.home() / "Developer/flywheel/.flywheel/scripts/punt-phrase-detector.py"
    if detector.exists():
        payload = run_json([sys.executable, str(detector), "report", "--since-hours", "24", "--top-phrases", "--json"], repo)
        if isinstance(payload, dict):
            return payload
    return {"schema_version": "flywheel.l70_punt_report.v1", "status": "unavailable", "event_count": 0}


def line_items(items: list[str], empty: str, limit: int = 8) -> list[str]:
    if not items:
        return [f"- {empty}"]
    lines = [f"- {item}" for item in items[:limit]]
    if len(items) > limit:
        lines.append(f"- ... {len(items) - limit} more")
    return lines


def notify_if_needed(notify_bin: str, report_path: Path, hard_blockers: list[str]) -> bool:
    if not hard_blockers:
        return False
    try:
        subprocess.run(
            [notify_bin, "--priority", "1", "--url", str(report_path), "FLYWHEEL DAILY BLOCKERS", hard_blockers[0][:180]],
            stdout=subprocess.DEVNULL,
            stderr=subprocess.DEVNULL,
            check=False,
            timeout=10,
        )
        return True
    except Exception:
        return False


_DISPOSITION_RE = re.compile(r"^(DONE|BLOCKED|DECLINED|ESCALATE|ESCALATED)\b", re.IGNORECASE)
_KV_RE = re.compile(r"(?P<key>[a-z][a-z0-9_]*)=(?P<val>[^\s]+)")
_FOUR_LENS_RE = re.compile(r"four_lens=(?P<spec>[a-z0-9:_,\-\.]+)", re.IGNORECASE)
_COMPLIANCE_RE = re.compile(r"compliance_score=(?P<n>\d+)\s*/\s*1000")


def parse_callback_envelope(text: str) -> dict[str, Any]:
    """Extract grading-relevant fields from a callback envelope.

    Returns a dict with disposition (DONE|BLOCKED|DECLINED|ESCALATE|None),
    identity_name, mission_fitness, compliance_score (int|None), and
    four_lens (dict[str,int]|None).
    """
    text = (text or "").strip()
    fields: dict[str, Any] = {
        "disposition": None,
        "identity_name": None,
        "mission_fitness": None,
        "compliance_score": None,
        "four_lens": None,
    }
    if not text:
        return fields
    head = _DISPOSITION_RE.match(text)
    if head:
        fields["disposition"] = head.group(1).upper().replace("ESCALATED", "ESCALATE")
    for match in _KV_RE.finditer(text):
        key = match.group("key")
        val = match.group("val")
        if key == "identity_name" and not fields["identity_name"]:
            fields["identity_name"] = val
        elif key == "mission_fitness" and not fields["mission_fitness"]:
            fields["mission_fitness"] = val
    cm = _COMPLIANCE_RE.search(text)
    if cm:
        try:
            fields["compliance_score"] = int(cm.group("n"))
        except ValueError:
            pass
    fl = _FOUR_LENS_RE.search(text)
    if fl:
        spec = fl.group("spec")
        axis: dict[str, int] = {}
        for token in spec.split(","):
            if ":" not in token:
                continue
            name, value = token.split(":", 1)
            try:
                axis[name.strip().lower()] = int(value.strip())
            except ValueError:
                continue
        if axis:
            fields["four_lens"] = axis
    return fields


def quartiles(values: Sequence[float]) -> dict[str, Any]:
    """Return avg/median/p25/p75 for a non-empty sample. None fields when n<1."""
    if not values:
        return {"n": 0, "avg": None, "median": None, "p25": None, "p75": None, "min": None, "max": None}
    sorted_vals = sorted(values)
    n = len(sorted_vals)
    avg = sum(sorted_vals) / n
    median = statistics.median(sorted_vals)

    def pick(p: float) -> float:
        if n == 1:
            return float(sorted_vals[0])
        idx = max(0, min(n - 1, round(p * (n - 1))))
        return float(sorted_vals[idx])

    return {
        "n": n,
        "avg": round(avg, 1),
        "median": float(median),
        "p25": pick(0.25),
        "p75": pick(0.75),
        "min": float(sorted_vals[0]),
        "max": float(sorted_vals[-1]),
    }


def quality_grade(callback_log: Path, date_text: str) -> dict[str, Any]:
    """Read callback-validation-log.jsonl rows for date_text and grade them.

    Output:
      callback_count: total rows for the date
      compliance_distribution: {n,avg,median,p25,p75,min,max}
      four_lens_distribution: per-axis {avg, count_lt_8, samples}
      mission_fitness_counts: {direct,adjacent,infrastructure,drift,unknown}
      disposition_counts: {DONE,BLOCKED,DECLINED,ESCALATE,unknown}
      blocked_escalate_rate: float ratio of (BLOCKED+ESCALATE)/total
      identity_attribution: list of {identity, closes, avg_compliance}
      red_flags: list of {code, detail}
    """
    rows = read_jsonl(callback_log, 5000)
    todays_envelopes: list[dict[str, Any]] = []
    for row in rows:
        ts = parse_ts(row.get("ts") or row.get("created_at"))
        if not same_utc_date(ts, date_text):
            continue
        encoded = row.get("callback_b64") or ""
        if not encoded:
            continue
        try:
            text = base64.b64decode(encoded).decode("utf-8", errors="replace")
        except Exception:
            continue
        envelope = parse_callback_envelope(text)
        if envelope["disposition"] is None:
            continue
        todays_envelopes.append(envelope)

    callback_count = len(todays_envelopes)
    compliance_values = [
        env["compliance_score"]
        for env in todays_envelopes
        if isinstance(env["compliance_score"], int)
    ]
    compliance_dist = quartiles(compliance_values)

    axes = ("brand", "sniff", "jeff", "public")
    axis_samples: dict[str, list[int]] = {a: [] for a in axes}
    for env in todays_envelopes:
        fl = env.get("four_lens")
        if not isinstance(fl, dict):
            continue
        for axis in axes:
            if axis in fl and isinstance(fl[axis], int):
                axis_samples[axis].append(fl[axis])
    four_lens_dist = {
        axis: {
            "n": len(samples),
            "avg": round(sum(samples) / len(samples), 2) if samples else None,
            "count_lt_8": sum(1 for v in samples if v < 8),
        }
        for axis, samples in axis_samples.items()
    }

    fitness_counter: Counter[str] = Counter()
    for env in todays_envelopes:
        fitness_counter[env.get("mission_fitness") or "unknown"] += 1

    disposition_counter: Counter[str] = Counter()
    for env in todays_envelopes:
        disposition_counter[env.get("disposition") or "unknown"] += 1

    blocked_plus_escalate = disposition_counter.get("BLOCKED", 0) + disposition_counter.get("ESCALATE", 0)
    blocked_escalate_rate = (
        round(blocked_plus_escalate / callback_count, 3) if callback_count else 0.0
    )

    identity_compliance: dict[str, list[int]] = defaultdict(list)
    identity_closes: Counter[str] = Counter()
    for env in todays_envelopes:
        ident = env.get("identity_name") or "unknown"
        identity_closes[ident] += 1
        score = env.get("compliance_score")
        if isinstance(score, int):
            identity_compliance[ident].append(score)
    identity_rows: list[dict[str, Any]] = []
    for ident, closes in identity_closes.items():
        scores = identity_compliance.get(ident) or []
        avg_compliance: float | None = (
            round(sum(scores) / len(scores), 1) if scores else None
        )
        identity_rows.append(
            {"identity": ident, "closes": int(closes), "avg_compliance": avg_compliance}
        )
    identity_attribution = sorted(
        identity_rows,
        key=lambda r: (-int(r["closes"]), str(r["identity"])),
    )

    red_flags: list[dict[str, str]] = []
    median_compliance = compliance_dist.get("median")
    if isinstance(median_compliance, (int, float)) and median_compliance < 850:
        red_flags.append({"code": "median_compliance_below_850", "detail": f"median={median_compliance}"})
    if blocked_escalate_rate > 0.20 and callback_count >= 5:
        red_flags.append(
            {"code": "blocked_escalate_rate_above_20pct", "detail": f"rate={blocked_escalate_rate}"}
        )
    if (fitness_counter.get("drift") or 0) > 5:
        red_flags.append(
            {"code": "mission_fitness_drift_above_5", "detail": f"drift_count={fitness_counter['drift']}"}
        )
    for row in identity_attribution:
        avg = row.get("avg_compliance")
        closes_value = int(row.get("closes") or 0)
        if isinstance(avg, (int, float)) and avg < 800 and closes_value >= 3:
            red_flags.append(
                {
                    "code": "worker_avg_compliance_below_800",
                    "detail": f"identity={row['identity']} avg={avg} closes={closes_value}",
                }
            )

    return {
        "schema_version": "daily-report-quality-grade.v1",
        "callback_count": callback_count,
        "compliance_distribution": compliance_dist,
        "four_lens_distribution": four_lens_dist,
        "mission_fitness_counts": dict(fitness_counter),
        "disposition_counts": dict(disposition_counter),
        "blocked_escalate_rate": blocked_escalate_rate,
        "identity_attribution": identity_attribution,
        "red_flags": red_flags,
    }


def security_summary(doc: dict[str, Any]) -> dict[str, Any]:
    security = doc.get("security")
    if not isinstance(security, dict):
        return {
            "status": "not_reported",
            "leaked_secret_pattern_count": 0,
            "secret_path_deny_missing_count": 0,
            "precommit_hook_missing_count": 0,
            "runtime_visible_secret_count": 0,
            "top_failing_repos": [],
        }

    def num(*keys: str) -> int:
        for key in keys:
            value: Any = security
            for part in key.split("."):
                if not isinstance(value, dict):
                    value = None
                    break
                value = value.get(part)
            try:
                return int(value or 0)
            except (TypeError, ValueError):
                continue
        return 0

    top_rows = security.get("top_failing_repos") or security.get("failing_repos") or []
    if not isinstance(top_rows, list):
        top_rows = []
    if not top_rows:
        repo_rows = security.get("repo_statuses") or []
        if isinstance(repo_rows, list):
            top_rows = [
                row
                for row in repo_rows
                if isinstance(row, dict) and str(row.get("status") or "pass").lower() != "pass"
            ]

    top_failing: list[str] = []
    for row in top_rows[:5]:
        if isinstance(row, dict):
            repo_name = str(row.get("repo") or row.get("name") or row.get("path") or "unknown")
            status = str(row.get("status") or "fail")
            count = row.get("leaked_secret_pattern_count")
            suffix = f" leaked_secret_pattern_count={count}" if count is not None else ""
            top_failing.append(f"{repo_name} status={status}{suffix}")
        else:
            top_failing.append(str(row))

    return {
        "status": str(security.get("status") or "unknown"),
        "leaked_secret_pattern_count": num("leaked_secret_pattern_count", "leaked_secret_patterns_count"),
        "secret_path_deny_missing_count": num("secret_path_deny_missing_count", "settings_deny_missing_count"),
        "precommit_hook_missing_count": num("precommit_hook_missing_count", "pre_commit_hook_missing_count"),
        "runtime_visible_secret_count": num(
            "runtime_visible_secret_count",
            "runtime_secret_visible_count",
            "runtime.visible_secret_count",
        ),
        "top_failing_repos": top_failing,
    }


def generate(args: argparse.Namespace) -> dict[str, Any]:
    repo = Path(args.repo).expanduser().resolve()
    now = utc_now()
    date_text = args.date or now.strftime("%Y-%m-%d")
    since = parse_ts(f"{date_text}T00:00:00Z") or (now - timedelta(hours=24))
    reports_dir = repo / ".flywheel" / "reports"
    reports_dir.mkdir(parents=True, exist_ok=True)
    report_path = reports_dir / f"daily-{date_text}.md"

    all_issues, ready_issues = load_beads(repo, args.br_bin)
    closed_today = [
        row
        for row in all_issues
        if issue_status(row) in {"closed", "done", "resolved"} and same_utc_date(issue_updated(row), date_text)
    ]
    in_flight_stale = []
    for row in all_issues:
        if issue_status(row) not in {"in_progress", "in-flight", "inflight", "working"}:
            continue
        updated = issue_updated(row)
        if updated and (now - updated).total_seconds() > 86400:
            in_flight_stale.append(row)

    class_counts = Counter(classify_title(issue_title(row)) for row in closed_today)
    def resolve_input(path_text: str) -> Path:
        path = Path(path_text).expanduser()
        if not path.is_absolute():
            path = repo / path
        return path

    memory_dir = resolve_input(args.memory_dir)
    memory_files = recent_files(memory_dir, since)
    dispatch_path = resolve_input(args.dispatch_log)
    dispatch_rows = read_jsonl(dispatch_path, 1000)
    dispatch_count, dispatch_in_flight = summarize_dispatch(dispatch_rows, date_text)
    fuckup_rows = [
        row
        for row in read_jsonl(resolve_input(args.fuckup_log), 2000)
        if same_utc_date(parse_ts(row.get("ts") or row.get("created_at")), date_text)
    ]
    trauma_counts = Counter(str(row.get("trauma_class") or "unknown") for row in fuckup_rows)
    cross_rows = [
        row
        for row in read_jsonl(resolve_input(args.cross_orch_log), 1000)
        if same_utc_date(parse_ts(row.get("ts") or row.get("created_at")), date_text)
    ]
    ack_rows = [row for row in cross_rows if "ack" in json.dumps(row).lower()]
    jeff_rows = [
        row
        for row in read_jsonl(resolve_input(args.jeff_digest), 1000)
        if same_utc_date(parse_ts(row.get("ts") or row.get("created_at") or row.get("checked_at")), date_text)
    ]
    incidents_path = resolve_input(args.incidents_file)
    incidents_text = incidents_path.read_text(errors="replace") if incidents_path.exists() else ""
    incident_lines = [line.strip() for line in incidents_text.splitlines() if date_text in line]
    doc = doctor_json(repo, Path(args.doctor_json).expanduser() if args.doctor_json else None)
    security = security_summary(doc)
    punt_report = punt_phrase_report_json(repo)
    punt_event_count = int(punt_report.get("event_count") or 0)
    state_miner = state_md_miner_json(repo)
    state_md_unmined_count = int(state_miner.get("state_md_unmined_count") or 0)
    jeff_projection = jeff_storage_projection_json(Path(args.jeff_storage_projection).expanduser())
    quality = quality_grade(resolve_input(args.callback_log), date_text)

    hard_blockers: list[str] = []
    if str(doc.get("status") or "").lower() == "fail":
        hard_blockers.append("doctor status is fail")
    hard_blockers.extend([f"{issue_id(row)} in_flight >24h: {issue_title(row)}" for row in in_flight_stale[:5]])
    for row in fuckup_rows:
        severity = str(row.get("severity") or "").lower()
        if severity in {"high", "urgent", "critical"}:
            hard_blockers.append(f"high-severity trauma: {row.get('trauma_class') or 'unknown'}")
            break

    notify_sent = False
    if args.notify and not args.no_notify:
        notify_sent = notify_if_needed(args.notify_bin, report_path, hard_blockers)

    shipped_lines = [
        f"{issue_id(row)} [{classify_title(issue_title(row))}] {issue_title(row)}"
        for row in closed_today
    ]
    class_line = ", ".join(f"{name}={count}" for name, count in sorted(class_counts.items())) or "none"
    learn_lines = [path.name for path in memory_files]
    learn_lines.extend([f"{name}={count}" for name, count in trauma_counts.most_common(5)])
    if state_md_unmined_count:
        learn_lines.append(f"state_md_unmined_count={state_md_unmined_count}")
    jeff_lines = [
        str(row.get("title") or row.get("repo") or row.get("source") or row.get("url") or row)[:160]
        for row in jeff_rows[:8]
    ]
    if jeff_projection:
        jeff_lines.insert(
            0,
            "storage_projection "
            f"verified={jeff_projection.get('verified_indexed_count')} "
            f"remaining_actual={jeff_projection.get('remaining_actual_count')} "
            f"scenario_remaining={jeff_projection.get('scenario_remaining_count')} "
            f"projected_actual_gb={jeff_projection.get('projected_actual_remaining_gb')} "
            f"scenario_gb={jeff_projection.get('projected_scenario_remaining_gb')} "
            f"free_gb={jeff_projection.get('disk_free_gb')} "
            f"recommendation={jeff_projection.get('recommendation')}",
        )
    stuck_lines = [f"{issue_id(row)} age>24h {issue_title(row)}" for row in in_flight_stale]
    if dispatch_in_flight:
        stuck_lines.append(f"{dispatch_in_flight} dispatch rows from today have no callback_received_at")
    if (doc.get("ticks_punted_count") or 0) and int(doc.get("ticks_punted_count") or 0) > 0:
        stuck_lines.append(f"ticks_punted_count={doc.get('ticks_punted_count')}")
    if punt_event_count > 0:
        stuck_lines.append(f"l70_punt_phrase_events_24h={punt_event_count}")
    next_lines = [
        f"{issue_id(row)} P{issue_priority(row)} {issue_title(row)}"
        for row in ready_issues[:8]
    ]
    cross_line = f"{len(cross_rows)} coordination rows; ACK-like rows={len(ack_rows)}"

    content: list[str] = [
        f"# Flywheel Daily Report - {date_text}",
        "",
        f"- generated_at: {now.strftime('%Y-%m-%dT%H:%M:%SZ')}",
        f"- repo: {repo}",
        f"- doctor_status: {doc.get('status', 'unknown')}",
        f"- hard_blockers: {len(hard_blockers)}",
        "",
        "## Security",
        f"- status: {security['status']}",
        f"- leaked_secret_pattern_count: {security['leaked_secret_pattern_count']}",
        f"- secret_path_deny_missing_count: {security['secret_path_deny_missing_count']}",
        f"- precommit_hook_missing_count: {security['precommit_hook_missing_count']}",
        f"- runtime_visible_secret_count: {security['runtime_visible_secret_count']}",
        *line_items(security["top_failing_repos"], "No failing security repos reported."),
        "",
        "## What shipped?",
        f"- class_breakdown: {class_line}",
        *line_items(shipped_lines, "No beads closed today."),
        "",
        "## What did we learn?",
        f"- feedback_memories_added_or_changed: {len(memory_files)}",
        f"- fuckup_rows_today: {len(fuckup_rows)}",
        f"- state_md_unmined_count: {state_md_unmined_count}",
        *line_items(learn_lines, "No new feedback memories or trauma classes found."),
        "",
        "## What's Jeff up to?",
        f"- jeff_digest_rows_today: {len(jeff_rows)}",
        f"- jeff_corpus_storage_projection: {jeff_projection.get('recommendation') if jeff_projection else 'missing'}",
        *line_items(jeff_lines, "No Jeff-intel rows found for today."),
        "",
        "## What's stuck?",
        f"- stale_in_flight_beads: {len(in_flight_stale)}",
        f"- dispatch_rows_today: {dispatch_count}",
        f"- l70_punt_phrase_events_24h: {punt_event_count}",
        *line_items(stuck_lines, "No stale in-flight beads or punted phases found."),
        "",
        "## What's next?",
        f"- ready_beads_seen: {len(ready_issues)}",
        *line_items(next_lines, "No ready beads returned by br ready."),
        "",
        "## Cross-orch state",
        f"- {cross_line}",
        *line_items(
            [
                str(row.get("session") or row.get("target_session") or row.get("from") or row.get("to") or row)[:160]
                for row in cross_rows[:6]
            ],
            "No cross-orch coordination rows found for today.",
        ),
        "",
        "## Quality grading",
        f"- callback_count: {quality['callback_count']}",
        f"- compliance: avg={quality['compliance_distribution'].get('avg')} median={quality['compliance_distribution'].get('median')} p25={quality['compliance_distribution'].get('p25')} p75={quality['compliance_distribution'].get('p75')} (n={quality['compliance_distribution'].get('n')})",
        "- four_lens: " + ", ".join(
            f"{a}: avg={d.get('avg')} <8={d.get('count_lt_8')} (n={d.get('n')})"
            for a, d in quality["four_lens_distribution"].items()
        ),
        "- mission_fitness: " + ", ".join(
            f"{k}={v}" for k, v in sorted(quality["mission_fitness_counts"].items())
        ),
        "- disposition: " + ", ".join(
            f"{k}={v}" for k, v in sorted(quality["disposition_counts"].items())
        ),
        f"- blocked_escalate_rate: {quality['blocked_escalate_rate']}",
        *line_items(
            [
                f"{row['identity']}: closes={row['closes']} avg_compliance={row['avg_compliance']}"
                for row in quality["identity_attribution"]
            ],
            "No identity-attributed callbacks today.",
        ),
        *line_items(
            [f"{flag['code']}: {flag['detail']}" for flag in quality["red_flags"]],
            "No quality red flags raised.",
        ),
        "",
        "## Source receipts",
        f"- dispatch_log: {args.dispatch_log}",
        f"- fuckup_log: {args.fuckup_log}",
        f"- cross_orch_log: {args.cross_orch_log}",
        f"- jeff_digest: {args.jeff_digest}",
        f"- incidents_file: {args.incidents_file}",
        "- state_md_miner: .flywheel/scripts/state-md-miner.sh",
        f"- incident_date_hits: {len(incident_lines)}",
        f"- notify_sent: {str(notify_sent).lower()}",
        "",
    ]
    report_path.write_text("\n".join(content))
    return {
        "version": VERSION,
        "status": "pass",
        "repo": str(repo),
        "date": date_text,
        "report_path": str(report_path),
        "hard_blockers_count": len(hard_blockers),
        "notify_sent": notify_sent,
        "closed_today_count": len(closed_today),
        "ready_count": len(ready_issues),
        "stale_in_flight_count": len(in_flight_stale),
        "state_md_unmined_count": state_md_unmined_count,
        "security_summary": security,
        "l70_punt_phrase_report": punt_report,
        "jeff_corpus_storage_projection": jeff_projection,
        "quality_grade": quality,
        "sections": [
            "what_shipped",
            "what_did_we_learn",
            "whats_jeff_up_to",
            "whats_stuck",
            "whats_next",
            "cross_orch_state",
            "quality_grading",
        ],
    }


def schema() -> dict[str, Any]:
    return {
        "$schema": "https://json-schema.org/draft/2020-12/schema",
        "title": "flywheel daily report result",
        "type": "object",
        "required": ["version", "status", "repo", "date", "report_path", "hard_blockers_count"],
        "properties": {
            "version": {"const": VERSION},
            "status": {"enum": ["pass", "fail"]},
            "report_path": {"type": "string"},
            "hard_blockers_count": {"type": "integer"},
        },
    }


def main(argv: list[str]) -> int:
    parser = argparse.ArgumentParser(description="Generate a repo-local flywheel daily report.")
    parser.add_argument("--repo", default=os.getcwd())
    parser.add_argument("--date")
    parser.add_argument("--json", action="store_true")
    parser.add_argument("--notify", action="store_true")
    parser.add_argument("--no-notify", action="store_true")
    parser.add_argument("--notify-bin", default=os.environ.get("NOTIFY_BIN", str(Path.home() / ".local/bin/notify")))
    parser.add_argument("--br-bin", default=os.environ.get("BR_BIN", "br"))
    parser.add_argument("--memory-dir", default=os.environ.get("FLYWHEEL_MEMORY_DIR", str(Path.home() / ".claude/projects/-Users-josh-Developer-flywheel/memory")))
    parser.add_argument("--dispatch-log", default=os.environ.get("FLYWHEEL_DISPATCH_LOG", ".flywheel/dispatch-log.jsonl"))
    parser.add_argument("--callback-log", default=os.environ.get("FLYWHEEL_CALLBACK_LOG", ".flywheel/callback-validation-log.jsonl"))
    parser.add_argument("--fuckup-log", default=os.environ.get("FLYWHEEL_FUCKUP_LOG", str(Path.home() / ".local/state/flywheel/fuckup-log.jsonl")))
    parser.add_argument("--cross-orch-log", default=os.environ.get("FLYWHEEL_CROSS_ORCH_LOG", str(Path.home() / ".local/state/flywheel/cross-orch-coordination.jsonl")))
    parser.add_argument("--jeff-digest", default=os.environ.get("FLYWHEEL_JEFF_DIGEST", str(Path.home() / ".local/state/jeff-intel/digest.jsonl")))
    parser.add_argument("--jeff-storage-projection", default=os.environ.get("FLYWHEEL_JEFF_STORAGE_PROJECTION", str(Path.home() / ".local/state/jeff-intel/storage-projection.json")))
    parser.add_argument("--incidents-file", default=os.environ.get("FLYWHEEL_INCIDENTS_FILE", "INCIDENTS.md"))
    parser.add_argument("--doctor-json", default=os.environ.get("FLYWHEEL_DAILY_REPORT_DOCTOR_JSON", ""))
    parser.add_argument("--schema", action="store_true")
    parser.add_argument("--info", action="store_true")
    parser.add_argument("--examples", action="store_true")
    args = parser.parse_args(argv)

    if args.schema:
        print(json.dumps(schema(), separators=(",", ":")))
        return 0
    if args.info:
        print(json.dumps({"version": VERSION, "script": __file__}, separators=(",", ":")))
        return 0
    if args.examples:
        print(".flywheel/scripts/daily-report.sh --repo /Users/josh/Developer/flywheel --json")
        print(".flywheel/scripts/daily-report.sh --repo /Users/josh/Developer/flywheel --notify --json")
        return 0

    result = generate(args)
    if args.json:
        print(json.dumps(result, separators=(",", ":")))
    else:
        print(result["report_path"])
    return 0


if __name__ == "__main__":
    raise SystemExit(main(sys.argv[1:]))
