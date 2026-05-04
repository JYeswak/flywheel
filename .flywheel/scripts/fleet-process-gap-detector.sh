#!/usr/bin/env bash
set -euo pipefail

python3 - "$@" <<'PY'
import argparse
import hashlib
import json
import os
import re
import shutil
import subprocess
import sys
from datetime import datetime, timedelta, timezone
from pathlib import Path
from typing import Any

SCHEMA_VERSION = "fleet-process-gap-detector/v1"
DEFAULT_FUCKUP_LOG = Path.home() / ".local/state/flywheel/fuckup-log.jsonl"
DEFAULT_TICK_DIR = Path.home() / ".local/state/flywheel-loop"
DEFAULT_STATE_DIR = Path.home() / ".local/state/flywheel/process-gap-detector"
DEFAULT_ROSTER = Path.home() / ".local/state/flywheel/fleet-roster.json"
DEFAULT_REPOS = [
    "/Users/josh/Developer/flywheel",
    "/Users/josh/Developer/mobile-eats",
    "/Users/josh/Developer/skillos",
    "/Users/josh/Developer/alpsinsurance",
    "/Users/josh/Desktop/Projects/clients/alps-insurance",
    "/Users/josh/Developer/vrtx",
]
SEVERITY_RANK = {"low": 1, "medium": 2, "high": 3}


def parse_ts(value: Any):
    if not value:
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
            pass
    return None


def now_utc(override: str | None):
    return parse_ts(override) or datetime.now(timezone.utc)


def iso(dt: datetime | None):
    if not dt:
        return None
    return dt.astimezone(timezone.utc).strftime("%Y-%m-%dT%H:%M:%SZ")


def read_json(path: Path):
    try:
        data = json.loads(path.read_text(encoding="utf-8", errors="replace"))
        return data if isinstance(data, dict) else None
    except Exception:
        return None


def read_jsonl(path: Path):
    rows = []
    if not path.exists():
        return rows
    try:
        lines = path.read_text(encoding="utf-8", errors="replace").splitlines()
    except Exception:
        return rows
    for line_no, line in enumerate(lines, start=1):
        if not line.strip():
            continue
        try:
            row = json.loads(line)
        except Exception:
            continue
        if isinstance(row, dict):
            row["_source_line"] = line_no
            rows.append(row)
    return rows


def event_ts(row: dict[str, Any]):
    for key in ("ts", "checked_at", "generated_at", "created_at", "updated_at", "callback_received_at", "validated_at"):
        parsed = parse_ts(row.get(key))
        if parsed:
            return parsed
    doctor = row.get("doctor")
    if isinstance(doctor, dict):
        for key in ("ts", "checked_at", "generated_at", "created_at"):
            parsed = parse_ts(doctor.get(key))
            if parsed:
                return parsed
    return None


def normalize_error(item: Any):
    if isinstance(item, dict):
        value = item.get("code") or item.get("class") or item.get("issue") or item.get("message")
    else:
        value = item
    text = str(value or "").strip()
    if not text:
        return None
    text = re.sub(r"\s+", "_", text.lower())
    text = re.sub(r"[^a-z0-9_.:-]+", "_", text).strip("_")
    return text[:120] or None


def extract_errors(payload: dict[str, Any]):
    errors = []
    for source in (payload, payload.get("doctor") if isinstance(payload.get("doctor"), dict) else {}):
        for item in source.get("errors") or []:
            norm = normalize_error(item)
            if norm:
                errors.append(norm)
    return sorted(set(errors))


def doctor_payload(row: dict[str, Any]):
    doctor = row.get("doctor")
    return doctor if isinstance(doctor, dict) else row


def doctor_samples(args):
    rows = []
    for raw in args.doctor_json:
        path = Path(raw).expanduser()
        data = read_json(path)
        if data:
            rows.append((event_ts(data) or parse_ts(data.get("checked_at")) or datetime.fromtimestamp(path.stat().st_mtime, timezone.utc), str(data.get("repo") or path.stem), doctor_payload(data), str(path)))
    tick_dir = Path(args.tick_dir).expanduser()
    if tick_dir.exists():
        for path in sorted(tick_dir.rglob("*.json")):
            try:
                if path.stat().st_size > 2_000_000:
                    continue
            except OSError:
                continue
            data = read_json(path)
            if not data:
                continue
            payload = doctor_payload(data)
            repo = payload.get("repo") or data.get("repo") or data.get("project") or data.get("session") or path.stem
            ts = event_ts(data) or datetime.fromtimestamp(path.stat().st_mtime, timezone.utc)
            rows.append((ts, str(repo), payload, str(path)))
    return rows


def severity_for_class(name: str, source: str, occurrences: int, explicit: str | None = None):
    if explicit in SEVERITY_RANK:
        return explicit
    text = f"{name} {source}".lower()
    if any(token in text for token in ("secret", "identity", "sticky_doctor", "doctor_error", "canonical_drift")):
        return "high"
    if occurrences >= 3 or any(token in text for token in ("closed_bead", "watcher", "promotion")):
        return "medium"
    return "low"


def remediation_skill(name: str):
    text = name.lower()
    if "agent" in text or "identity" in text:
        return "agent-mail"
    if "bead" in text or "br" in text:
        return "beads-workflow"
    if "doctor" in text or "sticky" in text:
        return "flywheel-doctor-author"
    if "watcher" in text or "slo" in text:
        return "observability-platform"
    if "drift" in text or "canonical" in text:
        return "canonical-cli-scoping"
    return "flywheel-recovery"


def proposed_remediation(name: str, source: str):
    if name.startswith("sticky_doctor_error:"):
        return "Route the sticky doctor error into a fix-bead and add/repair its consumer gate."
    if name.startswith("three_surface_drift:"):
        return "Backfill the drifting doctrine surface and add it to the 3-surface sync path."
    if name.startswith("unprocessed_promotion:"):
        return "Promote or explicitly reject the stale promotion candidate through the L56 ladder."
    if name == "closed_bead_audit_gap":
        return "Run bead-quality mining and file or close audit-gap beads for the top class."
    if name == "fleet_identity_drift":
        return "Repair tuple-key identity registry drift and sweep orphan token residue."
    if name == "fleet_watcher_coverage_hole":
        return "Restore watcher coverage or record an explicit non-participating session receipt."
    return "File a process fix-bead that changes the gate rather than handling one symptom."


def add_gap(gaps: dict[str, dict[str, Any]], name: str, source: str, first_seen, occurrences: int, severity: str | None = None, evidence: dict[str, Any] | None = None):
    if not name:
        return
    severity = severity_for_class(name, source, occurrences, severity)
    existing = gaps.get(name)
    if existing:
        existing["occurrences"] += occurrences
        if first_seen and (not existing["_first_seen_dt"] or first_seen < existing["_first_seen_dt"]):
            existing["_first_seen_dt"] = first_seen
            existing["first_seen"] = iso(first_seen)
        if SEVERITY_RANK[severity] > SEVERITY_RANK[existing["severity"]]:
            existing["severity"] = severity
        if evidence:
            existing.setdefault("evidence", []).append(evidence)
        return
    gaps[name] = {
        "class": name,
        "severity": severity,
        "_first_seen_dt": first_seen,
        "first_seen": iso(first_seen),
        "occurrences": int(occurrences),
        "proposed_remediation": proposed_remediation(name, source),
        "remediation_skill": remediation_skill(name),
        "source": source,
        "evidence": [evidence] if evidence else [],
    }


def repeating_fuckups(args, gaps, now):
    rows = read_jsonl(Path(args.fuckup_log).expanduser())
    start = now - timedelta(hours=args.lookback_hours)
    by_class: dict[str, list[dict[str, Any]]] = {}
    promotion_rows: dict[str, list[dict[str, Any]]] = {}
    for row in rows:
        cls = str(row.get("trauma_class") or row.get("class") or row.get("source_event_id") or "").strip()
        if not cls:
            continue
        ts = event_ts(row)
        if ts and start <= ts <= now:
            by_class.setdefault(cls, []).append(row)
        promote = row.get("promote") is True or row.get("promotion_ready") is True or row.get("should_promote") is True
        processed = row.get("processed") is True or row.get("promoted") is True or row.get("promoted_at") or row.get("l_rule_id")
        if promote and not processed:
            promotion_rows.setdefault(cls, []).append(row)
    for cls, items in by_class.items():
        if len(items) >= 2:
            first = min((event_ts(item) for item in items if event_ts(item)), default=None)
            explicit = max((str(item.get("severity") or "low") for item in items), key=lambda s: SEVERITY_RANK.get(s, 0), default=None)
            add_gap(gaps, cls, "repeating_fuckup_class", first, len(items), explicit, {"source": str(args.fuckup_log), "lines": [i.get("_source_line") for i in items[:5]]})
    for cls, items in promotion_rows.items():
        first = min((event_ts(item) for item in items if event_ts(item)), default=None)
        if first and first <= now - timedelta(hours=24):
            add_gap(gaps, f"unprocessed_promotion:{cls}", "unprocessed_promotion_candidate", first, len(items), "medium", {"source": str(args.fuckup_log), "lines": [i.get("_source_line") for i in items[:5]]})


def sticky_doctor_errors(samples, gaps):
    by_repo: dict[str, list[tuple[datetime, set[str], str]]] = {}
    for ts, repo, payload, path in samples:
        errors = set(extract_errors(payload))
        by_repo.setdefault(repo, []).append((ts, errors, path))
    seen = set()
    for repo, rows in by_repo.items():
        rows.sort(key=lambda item: item[0])
        for idx in range(0, max(0, len(rows) - 2)):
            window = rows[idx:idx + 3]
            common = set.intersection(*(item[1] for item in window)) if all(item[1] for item in window) else set()
            for code in common:
                key = (repo, code)
                if key in seen:
                    continue
                seen.add(key)
                occurrences = sum(1 for _, errors, _ in rows if code in errors)
                add_gap(gaps, f"sticky_doctor_error:{code}", "sticky_doctor_error", window[0][0], occurrences, "high", {"repo": repo, "paths": [item[2] for item in window]})


def count_l_rules(path: Path):
    try:
        text = path.read_text(encoding="utf-8", errors="replace")
    except Exception:
        return 0
    return len(re.findall(r"^## L\d+\b", text, flags=re.MULTILINE))


def roster_repos():
    rows = []
    data = read_json(DEFAULT_ROSTER)
    if not data:
        return rows
    for item in (data.get("repos") or []) + (data.get("members") or []):
        if isinstance(item, dict):
            value = item.get("repo") or item.get("repo_realpath")
            if value:
                rows.append(value)
    return rows


def fleet_repos(args):
    values = list(args.fleet_repo)
    for root_raw in args.fleet_root:
        root = Path(root_raw).expanduser()
        if root.exists():
            for child in sorted(root.iterdir()):
                if child.is_dir() and ((child / "AGENTS.md").exists() or (child / ".flywheel/loop.json").exists()):
                    values.append(str(child))
    if not values:
        values.extend(roster_repos())
    if not values:
        values.extend(DEFAULT_REPOS)
    seen = set()
    repos = []
    for value in values:
        path = Path(value).expanduser()
        try:
            path = path.resolve()
        except Exception:
            pass
        if path.exists() and str(path) not in seen:
            seen.add(str(path))
            repos.append(path)
    return repos or [Path(args.repo).expanduser().resolve()]


def doctrine_drift(args, gaps, now):
    for repo in fleet_repos(args):
        agents = repo / "AGENTS.md"
        template = repo / "templates/flywheel-install/AGENTS.md"
        agents_count = count_l_rules(agents)
        template_count = count_l_rules(template)
        delta = abs(agents_count - template_count)
        if delta > 5:
            add_gap(
                gaps,
                f"three_surface_drift:{repo.name}",
                "three_surface_rule_count_delta",
                now,
                delta,
                "high" if delta > 10 else "medium",
                {"repo": str(repo), "agents_count": agents_count, "template_count": template_count, "delta": delta},
            )


def latest_value_gap(samples, key_names):
    hits = []
    for ts, repo, payload, path in samples:
        value = None
        for key in key_names:
            if key in payload:
                value = payload.get(key)
                break
        try:
            value_int = int(value or 0)
        except Exception:
            value_int = 0
        if value_int > 0:
            hits.append((ts, repo, payload, path, value_int))
    if not hits:
        return None
    hits.sort(key=lambda item: item[0])
    latest = hits[-1]
    first = hits[0][0]
    total = max(item[4] for item in hits)
    return first, latest, total


def doctor_field_gaps(samples, gaps, now):
    closed = latest_value_gap(samples, ["closed_bead_audit_gap_count"])
    if closed:
        first, latest, total = closed
        add_gap(gaps, "closed_bead_audit_gap", "doctor_closed_bead_audit_gap_count", first, total, "medium", {"repo": latest[1], "path": latest[3], "count": total})
    identity = latest_value_gap(samples, ["fleet_identity_drift_count", "identity_registry_drift"])
    if identity:
        first, latest, total = identity
        add_gap(gaps, "fleet_identity_drift", "doctor_identity_drift", first, total, "high", {"repo": latest[1], "path": latest[3], "count": total})

    watcher_hits = []
    for ts, repo, payload, path in samples:
        try:
            total = int(payload.get("fleet_watcher_coverage_total") or 0)
            count = int(payload.get("fleet_watcher_coverage_count") or 0)
        except Exception:
            continue
        deficit = max(0, total - count)
        age = payload.get("fleet_watcher_coverage_hole_age_seconds")
        try:
            age = int(age or 0)
        except Exception:
            age = 0
        if deficit > 0:
            watcher_hits.append((ts, repo, payload, path, deficit, age))
    if watcher_hits:
        watcher_hits.sort(key=lambda item: item[0])
        latest = watcher_hits[-1]
        first = watcher_hits[0][0]
        age_ok = first <= now - timedelta(hours=24) or latest[5] >= 86400
        if age_ok:
            add_gap(gaps, "fleet_watcher_coverage_hole", "doctor_watcher_coverage_deficit", first, latest[4], "medium", {"repo": latest[1], "path": latest[3], "deficit": latest[4]})


def marker_for(cls: str):
    return hashlib.sha1(cls.encode("utf-8")).hexdigest()[:12]


def issue_status_open(status: str):
    return str(status or "").lower() not in {"closed", "done", "resolved", "cancelled", "wontfix"}


def existing_bead(repo: Path, marker: str, ledger: Path):
    for row in read_jsonl(ledger):
        if row.get("marker") == marker and row.get("bead_id"):
            return {"source": "ledger", "bead_id": row.get("bead_id"), "title": row.get("title")}
    issues = repo / ".beads/issues.jsonl"
    for row in read_jsonl(issues):
        title = str(row.get("title") or row.get("summary") or "")
        if marker in title and issue_status_open(str(row.get("status") or row.get("state") or "")):
            return {"source": "beads", "bead_id": row.get("id"), "title": title}
    return None


def bead_description(gap: dict[str, Any], idempotency_key: str | None):
    return f"""## Goal
Fix the process gap `{gap['class']}` by changing the detector, gate, or routing rule that let it recur.

## Context
The fleet process-gap detector found this as a meta-level process leak, not an individual-agent failure.
Severity: {gap['severity']}
Occurrences: {gap['occurrences']}
First seen: {gap.get('first_seen') or 'unknown'}
Recommended skill: {gap['remediation_skill']}

## Inputs / Outputs
INPUTS: fleet-process-gap-detector/v1 evidence and related doctor/fuckup rows.
OUTPUTS: one durable gate, probe, doctrine, or routing repair.

## Acceptance Criteria
- The class no longer appears in `fleet-process-gap-detector.sh --json`.
- If the class is expected to recur, it routes to a named doctor/status/bead consumer.
- Dedupe marker remains in the bead title.

## Testing Obligations
- Run the relevant probe/test for the repaired substrate.
- Report detector before/after JSON.

## Definition of Done
COMMIT: fix(process): close {gap['class']}
AUTONOMY: autonomous
IDEMPOTENCY_KEY: {idempotency_key or 'stable-class-marker'}
"""


def apply_plan(args, top_gaps):
    repo = Path(args.repo).expanduser().resolve()
    state_dir = Path(args.state_dir).expanduser()
    ledger = state_dir / "process-gap-fix-beads.jsonl"
    planned = []
    actual = []
    filed = []
    blocked = []
    for gap in top_gaps:
        marker = f"auto-process-gap:{marker_for(gap['class'])}"
        title = f"[{marker}] Fix process gap: {gap['class']}"[:180]
        existing = existing_bead(repo, marker, ledger)
        argv = [args.br_bin, "create", title, "--type", "task", "--priority", "P2", "--description", bead_description(gap, args.idempotency_key), "--json"]
        action = {"class": gap["class"], "marker": marker, "title": title, "br_argv": argv, "existing": existing}
        if existing:
            action["action"] = "existing"
        else:
            action["action"] = "create"
        planned.append(action)
    if not args.apply:
        return {"planned_actions": [], "actual_actions": [], "fix_beads_filed": [], "blocked_by": []}
    if args.dry_run:
        return {"planned_actions": planned, "actual_actions": [], "fix_beads_filed": [], "blocked_by": []}
    if not args.idempotency_key:
        return {"planned_actions": planned, "actual_actions": [], "fix_beads_filed": [], "blocked_by": ["missing_idempotency_key"]}
    state_dir.mkdir(parents=True, exist_ok=True)
    def is_beads_db_failure(stderr: str) -> bool:
        text = stderr.lower()
        return any(
            needle in text
            for needle in (
                "database disk image is malformed",
                "b-tree",
                "btree",
                "invalid b-tree page",
                "export_hashes",
                "sqlite",
            )
        )

    for action in planned:
        if action["existing"]:
            actual.append({**action, "applied": False, "reason": "deduped_existing_bead"})
            continue
        br_path = shutil.which(action["br_argv"][0]) or action["br_argv"][0]
        cmd = [br_path] + action["br_argv"][1:]
        proc = subprocess.run(cmd, cwd=repo, text=True, stdout=subprocess.PIPE, stderr=subprocess.PIPE, check=False)
        fallback_used = False
        fallback_cmd = None
        if proc.returncode != 0 and is_beads_db_failure(proc.stderr):
            fallback_cmd = [br_path, "--no-db"] + action["br_argv"][1:]
            proc = subprocess.run(fallback_cmd, cwd=repo, text=True, stdout=subprocess.PIPE, stderr=subprocess.PIPE, check=False)
            fallback_used = True
        bead_id = None
        if proc.stdout.strip():
            try:
                data = json.loads(proc.stdout)
                bead_id = data.get("id") or (data.get("issue") or {}).get("id")
            except Exception:
                pass
        if proc.returncode == 0 and bead_id:
            filed.append(bead_id)
            row = {
                "ts": iso(datetime.now(timezone.utc)),
                "marker": action["marker"],
                "class": action["class"],
                "bead_id": bead_id,
                "title": action["title"],
                "idempotency_key": args.idempotency_key,
                "fallback_used": fallback_used,
            }
            with ledger.open("a", encoding="utf-8") as handle:
                handle.write(json.dumps(row, separators=(",", ":")) + "\n")
            actual.append({**action, "applied": True, "bead_id": bead_id, "fallback_used": fallback_used, "fallback_argv": fallback_cmd})
        else:
            blocked.append({"class": action["class"], "returncode": proc.returncode, "stderr": proc.stderr[-500:]})
            actual.append({**action, "applied": False, "returncode": proc.returncode, "fallback_used": fallback_used, "fallback_argv": fallback_cmd})
    return {"planned_actions": planned, "actual_actions": actual, "fix_beads_filed": filed, "blocked_by": blocked}


def build_payload(args):
    now = now_utc(args.now)
    gaps: dict[str, dict[str, Any]] = {}
    samples = doctor_samples(args)
    repeating_fuckups(args, gaps, now)
    sticky_doctor_errors(samples, gaps)
    doctrine_drift(args, gaps, now)
    doctor_field_gaps(samples, gaps, now)
    all_gaps = list(gaps.values())
    for gap in all_gaps:
        gap.pop("_first_seen_dt", None)
    all_gaps.sort(key=lambda item: (-SEVERITY_RANK.get(item["severity"], 0), -int(item["occurrences"]), item.get("first_seen") or ""))
    top_gaps = all_gaps[: args.max_gaps]
    high = sum(1 for gap in all_gaps if gap["severity"] == "high")
    medium = sum(1 for gap in all_gaps if gap["severity"] == "medium")
    low = sum(1 for gap in all_gaps if gap["severity"] == "low")
    score = max(0, min(100, 100 - high * 25 - medium * 12 - low * 5))
    stuck = sum(1 for gap in all_gaps if gap["severity"] == "high" or gap["occurrences"] >= 3)
    apply_result = apply_plan(args, top_gaps)
    return {
        "schema_version": SCHEMA_VERSION,
        "checked_at": iso(now),
        "open_gap_count": len(all_gaps),
        "top_gaps": top_gaps,
        "stuck_class_count": stuck,
        "process_health_score": score,
        "signals_implemented": [
            "repeating_fuckup_classes",
            "sticky_doctor_errors",
            "three_surface_drift",
            "unprocessed_promotion_candidates",
            "closed_bead_audit_gaps",
            "identity_drift",
            "watcher_coverage_holes",
        ],
        "signal_counts": {"high": high, "medium": medium, "low": low},
        "source_counts": {"doctor_samples": len(samples), "fleet_repos": len(fleet_repos(args))},
        **apply_result,
    }


def emit_info(json_out: bool):
    payload = {
        "schema_version": "canonical-cli-info/v1",
        "name": "fleet-process-gap-detector",
        "summary": "Aggregates recurring fleet failures into process-gap rows and optional fix-bead plans.",
        "doctor_fields": [
            "fleet_process_gap_detector",
            "fleet_process_open_gap_count",
            "fleet_process_stuck_class_count",
            "fleet_process_health_score",
            "fleet_process_top_gap_class",
        ],
        "canonical_flags": ["--info", "--examples", "--schema", "--json", "--apply", "--dry-run", "--idempotency-key"],
        "mutation": "--apply requires a stable class marker; actual br create requires --idempotency-key",
    }
    print(json.dumps(payload, separators=(",", ":")) if json_out else payload["summary"])


def emit_examples(json_out: bool):
    examples = [
        "fleet-process-gap-detector.sh --json",
        "fleet-process-gap-detector.sh --apply --dry-run --json",
        "fleet-process-gap-detector.sh --apply --idempotency-key process-gap-20260504 --json",
    ]
    payload = {"schema_version": SCHEMA_VERSION, "examples": examples}
    print(json.dumps(payload, separators=(",", ":")) if json_out else "\n".join(examples))


def emit_schema():
    print(json.dumps({
        "$schema": "https://json-schema.org/draft/2020-12/schema",
        "schema_version": SCHEMA_VERSION,
        "type": "object",
        "required": ["schema_version", "checked_at", "open_gap_count", "top_gaps", "stuck_class_count", "process_health_score"],
        "properties": {
            "schema_version": {"const": SCHEMA_VERSION},
            "checked_at": {"type": "string"},
            "open_gap_count": {"type": "integer"},
            "stuck_class_count": {"type": "integer"},
            "process_health_score": {"type": "integer", "minimum": 0, "maximum": 100},
            "top_gaps": {"type": "array"},
        },
    }, separators=(",", ":")))


def main():
    parser = argparse.ArgumentParser(prog="fleet-process-gap-detector.sh")
    parser.add_argument("--json", action="store_true")
    parser.add_argument("--info", action="store_true")
    parser.add_argument("--examples", action="store_true")
    parser.add_argument("--schema", action="store_true")
    parser.add_argument("--apply", action="store_true")
    parser.add_argument("--dry-run", action="store_true")
    parser.add_argument("--idempotency-key")
    parser.add_argument("--repo", default=os.getcwd())
    parser.add_argument("--fuckup-log", default=str(DEFAULT_FUCKUP_LOG))
    parser.add_argument("--tick-dir", default=str(DEFAULT_TICK_DIR))
    parser.add_argument("--state-dir", default=str(DEFAULT_STATE_DIR))
    parser.add_argument("--now")
    parser.add_argument("--lookback-hours", type=int, default=24)
    parser.add_argument("--max-gaps", type=int, default=3)
    parser.add_argument("--fleet-root", action="append", default=[])
    parser.add_argument("--fleet-repo", action="append", default=[])
    parser.add_argument("--doctor-json", action="append", default=[])
    parser.add_argument("--br-bin", default="br")
    args = parser.parse_args()

    if args.info:
        emit_info(args.json)
        return
    if args.examples:
        emit_examples(args.json)
        return
    if args.schema:
        emit_schema()
        return
    payload = build_payload(args)
    if args.json:
        print(json.dumps(payload, sort_keys=True, separators=(",", ":")))
    else:
        top = payload["top_gaps"][0]["class"] if payload["top_gaps"] else "none"
        print(f"Fleet process: health={payload['process_health_score']} open-gaps={payload['open_gap_count']} top={top}")
    if payload.get("blocked_by"):
        sys.exit(1)


if __name__ == "__main__":
    main()
PY
