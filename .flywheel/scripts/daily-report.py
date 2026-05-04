#!/usr/bin/env python3
from __future__ import annotations

import argparse
import json
import os
import subprocess
import sys
from collections import Counter
from datetime import datetime, timezone, timedelta
from pathlib import Path
from typing import Any


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
    state_miner = state_md_miner_json(repo)
    state_md_unmined_count = int(state_miner.get("state_md_unmined_count") or 0)
    jeff_projection = jeff_storage_projection_json(Path(args.jeff_storage_projection).expanduser())

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
        "jeff_corpus_storage_projection": jeff_projection,
        "sections": [
            "what_shipped",
            "what_did_we_learn",
            "whats_jeff_up_to",
            "whats_stuck",
            "whats_next",
            "cross_orch_state",
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
