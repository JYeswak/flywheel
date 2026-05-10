#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd -P)"
LIB="$ROOT/.flywheel/scripts/fleet-coherence-lib.sh"
if [[ -f "$LIB" ]]; then
  # shellcheck source=/dev/null
  source "$LIB"
fi

PYTHON="${PYTHON:-python3}"
WINDOW="24h"
EVENTS_FILE="${FLYWHEEL_FLEET_COHERENCE_EVENTS:-}"
LATEST_FILE="${FLYWHEEL_FLEET_COHERENCE_LATEST:-}"
SUPPRESSIONS_FILE="$ROOT/.flywheel/fixtures/fleet-coherence-suppressions-v2.jsonl"
SCAN_LOG=""
OUTPUT="$ROOT/.flywheel/PLANS/fleet-coherence-signal-quality-report.md"
NOW=""
MODE="report"
JSON=0
DRY_RUN=0

if [[ -z "$EVENTS_FILE" ]] && declare -F fc_events_path >/dev/null 2>&1; then
  EVENTS_FILE="$(fc_events_path)"
fi
if [[ -z "$LATEST_FILE" ]] && declare -F fc_latest_path >/dev/null 2>&1; then
  LATEST_FILE="$(fc_latest_path)"
fi
EVENTS_FILE="${EVENTS_FILE:-$HOME/.local/state/flywheel/fleet-coherence-events-v2.jsonl}"
LATEST_FILE="${LATEST_FILE:-$HOME/.local/state/flywheel/fleet-coherence-latest-v2.json}"

usage() {
  cat <<'USAGE'
Usage: fleet-coherence-quality-report.sh [options]

Options:
  --window <24h|48h|Nd|Nm>       Shadow window to summarize (default: 24h)
  --events-file <path>           Fleet coherence JSONL events
  --latest-file <path>           Latest snapshot JSON
  --suppressions-file <path>     Suppression JSONL file
  --scan-log <path>              Optional scan/status log
  --output <path>                Markdown report output path
  --now <iso8601>                Fixed clock for tests
  --json                         Emit machine-readable summary
  --dry-run                      Do not write the markdown report
  --info|--schema|--doctor|--health|--validate|--audit|--why|--repair
USAGE
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --window) WINDOW="${2:?missing --window value}"; shift 2 ;;
    --events-file) EVENTS_FILE="${2:?missing --events-file value}"; shift 2 ;;
    --latest-file) LATEST_FILE="${2:?missing --latest-file value}"; shift 2 ;;
    --suppressions-file) SUPPRESSIONS_FILE="${2:?missing --suppressions-file value}"; shift 2 ;;
    --scan-log) SCAN_LOG="${2:?missing --scan-log value}"; shift 2 ;;
    --output) OUTPUT="${2:?missing --output value}"; shift 2 ;;
    --now) NOW="${2:?missing --now value}"; shift 2 ;;
    --json) JSON=1; shift ;;
    --dry-run) DRY_RUN=1; shift ;;
    --info|--schema|--doctor|--health|--validate|--audit|--why|--repair)
      MODE="${1#--}"
      shift
      ;;
    -h|--help) usage; exit 0 ;;
    *) echo "unknown option: $1" >&2; usage >&2; exit 64 ;;
  esac
done

"$PYTHON" - "$MODE" "$WINDOW" "$EVENTS_FILE" "$LATEST_FILE" "$SUPPRESSIONS_FILE" "$SCAN_LOG" "$OUTPUT" "$NOW" "$JSON" "$DRY_RUN" <<'PY'
import json
import math
import os
import re
import sys
from collections import defaultdict
from datetime import datetime, timezone, timedelta
from pathlib import Path

mode, window, events_file, latest_file, suppressions_file, scan_log, output, now_arg, json_flag, dry_run_flag = sys.argv[1:11]
json_mode = json_flag == "1"
dry_run = dry_run_flag == "1"

def emit(obj, status=0):
    if json_mode:
        print(json.dumps(obj, sort_keys=True, separators=(",", ":")))
    else:
        if isinstance(obj, str):
            print(obj)
        else:
            print(json.dumps(obj, indent=2, sort_keys=True))
    raise SystemExit(status)

def iso_now():
    return datetime.now(timezone.utc).replace(microsecond=0)

def parse_time(value):
    if not value:
        return None
    text = str(value).strip()
    if text.endswith("Z"):
        text = text[:-1] + "+00:00"
    try:
        dt = datetime.fromisoformat(text)
    except ValueError:
        return None
    if dt.tzinfo is None:
        dt = dt.replace(tzinfo=timezone.utc)
    return dt.astimezone(timezone.utc)

def parse_window(value):
    m = re.fullmatch(r"([0-9]+)([smhd])", value)
    if not m:
        raise SystemExit(f"invalid --window: {value}")
    n = int(m.group(1))
    unit = m.group(2)
    return {
        "s": timedelta(seconds=n),
        "m": timedelta(minutes=n),
        "h": timedelta(hours=n),
        "d": timedelta(days=n),
    }[unit]

def load_jsonl(path):
    rows = []
    malformed = 0
    p = Path(path).expanduser()
    if not p.exists():
        return rows, malformed, False
    with p.open("r", encoding="utf-8") as fh:
        for line in fh:
            raw = line.strip()
            if not raw:
                continue
            try:
                rows.append(json.loads(raw))
            except json.JSONDecodeError:
                malformed += 1
    return rows, malformed, True

def load_json(path):
    p = Path(path).expanduser()
    if not p.exists():
        return None, False
    try:
        return json.loads(p.read_text(encoding="utf-8")), True
    except json.JSONDecodeError:
        return {"_malformed": True}, True

def nested(row, dotted):
    cur = row
    for part in dotted.split("."):
        if not isinstance(cur, dict) or part not in cur:
            return None
        cur = cur[part]
    return cur

def number(value):
    if isinstance(value, bool) or value is None:
        return None
    try:
        return float(value)
    except (TypeError, ValueError):
        return None

def duration_seconds(row, prefix):
    second_paths = [
        f"{prefix}_time_s",
        f"{prefix}_time_sec",
        f"{prefix}_duration_s",
        f"{prefix}_duration_sec",
        f"evidence.{prefix}_time_s",
        f"evidence.{prefix}_time_sec",
        f"evidence.{prefix}_duration_s",
        f"evidence.{prefix}_duration_sec",
        f"evidence.timings.{prefix}_s",
        f"evidence.timings.{prefix}_sec",
    ]
    millisecond_paths = [
        f"{prefix}_duration_ms",
        f"{prefix}_time_ms",
        f"evidence.{prefix}_duration_ms",
        f"evidence.{prefix}_time_ms",
        f"evidence.timings.{prefix}_ms",
    ]
    if prefix == "scan":
        second_paths += ["evidence.sources.scan.duration_s", "evidence.sources.scan.elapsed_s"]
        millisecond_paths += ["evidence.sources.scan.duration_ms", "evidence.sources.scan.elapsed_ms"]
    if prefix == "status":
        second_paths += ["evidence.sources.status.duration_s", "evidence.sources.status.elapsed_s", "evidence.sources.ntm.health.duration_s", "evidence.sources.ntm.health.elapsed_s"]
        millisecond_paths += ["evidence.sources.status.duration_ms", "evidence.sources.status.elapsed_ms", "evidence.sources.ntm.health.duration_ms", "evidence.sources.ntm.health.elapsed_ms"]
    for path in second_paths:
        v = number(nested(row, path))
        if v is not None:
            return v
    for path in millisecond_paths:
        v = number(nested(row, path))
        if v is not None:
            return v / 1000.0
    return None

def percentile_95(values):
    vals = sorted(v for v in values if isinstance(v, (int, float)))
    if not vals:
        return None
    idx = max(0, math.ceil(len(vals) * 0.95) - 1)
    return vals[idx]

def fmt(value, suffix=""):
    if value is None:
        return "n/a"
    if isinstance(value, float):
        return f"{value:.3f}{suffix}"
    return f"{value}{suffix}"

def truthy_path(row, *paths):
    for path in paths:
        if nested(row, path) is True:
            return True
    return False

if mode == "info":
    emit({
        "name": "fleet-coherence-quality-report",
        "purpose": "Summarize fleet coherence shadow signal quality before Phase 2a live effects.",
        "default_window": "24h",
        "mutates": "markdown_report_only",
        "canonical_cli_surfaces": ["info", "schema", "doctor", "health", "validate", "audit", "why", "dry-run", "json"],
    })

if mode == "schema":
    emit({
        "schema_version": "fleet-coherence-quality-report/v1",
        "inputs": ["events_jsonl", "latest_json", "suppressions_jsonl", "optional_scan_log"],
        "metrics": ["rows_per_class", "malformed_rows", "p95_scan_time_s", "p95_status_time_s", "dedupe_resend_behavior", "shadow_side_effects", "phase_2a_decision"],
        "side_effect_policy": "no L61 sends, bead filing, or topology mutation",
    })

if mode == "why":
    emit("Phase 1f converts the shadow JSONL stream into an auditable go/no-go report before enabling Phase 2a live effects.")

if mode == "repair":
    emit({"status": "refused", "reason": "quality report is read-only except markdown output; repair would mutate shadow evidence"}, status=1)

now = parse_time(now_arg) if now_arg else iso_now()
delta = parse_window(window)
cutoff = now - delta

rows, malformed_rows, events_exists = load_jsonl(events_file)
suppressions, malformed_suppressions, suppressions_exists = load_jsonl(suppressions_file)
latest, latest_exists = load_json(latest_file)

if mode in {"doctor", "health", "validate"}:
    status = "ok" if events_exists else "blocked"
    checks = {
        "events_file": {"path": events_file, "exists": events_exists},
        "latest_file": {"path": latest_file, "exists": latest_exists},
        "suppressions_file": {"path": suppressions_file, "exists": suppressions_exists, "malformed_rows": malformed_suppressions},
        "output_parent": {"path": str(Path(output).expanduser().parent), "exists": Path(output).expanduser().parent.exists()},
        "mode": mode,
    }
    if mode == "validate" and malformed_rows:
        status = "blocked"
    emit({"status": status, "checks": checks, "malformed_rows": malformed_rows})

selected = []
invalid_ts_rows = 0
for row in rows:
    ts = parse_time(row.get("ts") or row.get("source_ts") or row.get("last_seen_ts"))
    if ts is None:
        invalid_ts_rows += 1
        continue
    if cutoff <= ts <= now:
        selected.append(row)

class_rows = defaultdict(lambda: {
    "rows": 0,
    "open": 0,
    "closed": 0,
    "suppressed": 0,
    "would_l61": 0,
    "would_bead": 0,
    "blocking_open": 0,
})
scan_times = []
status_times = []
dedupe_keys = []
resend_count = 0
real_l61_attempts = 0
real_bead_filing = 0
topology_mutations = 0

for row in selected:
    cls = str(row.get("class") or "unknown")
    state = str(row.get("state") or "unknown")
    severity = str(row.get("severity") or "").lower()
    actions = row.get("actions") if isinstance(row.get("actions"), dict) else {}
    stats = class_rows[cls]
    stats["rows"] += 1
    if state == "closed":
        stats["closed"] += 1
    elif state == "suppressed" or row.get("suppression_id"):
        stats["suppressed"] += 1
    else:
        stats["open"] += 1
    if actions.get("would_l61") is True:
        stats["would_l61"] += 1
    if actions.get("would_bead") is True:
        stats["would_bead"] += 1
    if state not in {"closed", "suppressed"} and (severity in {"warn", "warning", "error", "critical"} or actions.get("would_bead") is True or actions.get("would_l61") is True or actions.get("receipt_required") is True):
        stats["blocking_open"] += 1
    scan = duration_seconds(row, "scan")
    status = duration_seconds(row, "status")
    if scan is not None:
        scan_times.append(scan)
    if status is not None:
        status_times.append(status)
    key = row.get("dedupe_key")
    if key:
        dedupe_keys.append(str(key))
    if row.get("resend_after_ts"):
        resend_count += 1
    if truthy_path(row, "l61.ntm_attempted", "l61.agent_mail_attempted", "l61.sent", "evidence.l61_sent"):
        real_l61_attempts += 1
    if actions.get("bead_id") or actions.get("filed_bead_id") or truthy_path(row, "evidence.bead_filed"):
        real_bead_filing += 1
    if truthy_path(row, "evidence.topology_mutated", "topology_mutated"):
        topology_mutations += 1

p95_scan = percentile_95(scan_times)
p95_status = percentile_95(status_times)
unique_dedupe = len(set(dedupe_keys))
duplicate_rows = max(0, len(dedupe_keys) - unique_dedupe)
duplicate_keys = sorted(k for k in set(dedupe_keys) if dedupe_keys.count(k) > 1)

blocked_classes = sorted(cls for cls, stats in class_rows.items() if stats["blocking_open"] > 0)
blockers = []
if not selected:
    blockers.append("no_shadow_events")
if malformed_rows:
    blockers.append("malformed_event_rows")
if invalid_ts_rows:
    blockers.append("invalid_event_timestamps")
if p95_scan is None:
    blockers.append("scan_timing_missing")
elif p95_scan > 10.0:
    blockers.append("scan_timing_over_budget")
if p95_status is None:
    blockers.append("status_timing_missing")
elif p95_status > 10.0:
    blockers.append("status_timing_over_budget")
if real_l61_attempts:
    blockers.append("real_l61_attempts_detected")
if real_bead_filing:
    blockers.append("real_bead_filing_detected")
if topology_mutations:
    blockers.append("topology_mutations_detected")
if blocked_classes:
    blockers.append("blocking_open_classes")

decision = "blocked" if blockers else "unblocked"
phase_line = "Phase 2a: BLOCKED" if blockers else "Phase 2a: UNBLOCKED"

summary = {
    "schema_version": "fleet-coherence-quality-report/v1",
    "status": "ok",
    "decision": decision,
    "phase_2a": phase_line,
    "generated_at": now.isoformat().replace("+00:00", "Z"),
    "window": window,
    "cutoff": cutoff.isoformat().replace("+00:00", "Z"),
    "events_file": events_file,
    "latest_file": latest_file,
    "suppressions_file": suppressions_file,
    "events_file_exists": events_exists,
    "latest_file_exists": latest_exists,
    "total_rows": len(selected),
    "malformed_rows": malformed_rows,
    "invalid_ts_rows": invalid_ts_rows,
    "p95_scan_time_s": p95_scan,
    "p95_status_time_s": p95_status,
    "class_rows": dict(sorted(class_rows.items())),
    "blocked_classes": blocked_classes,
    "blockers": blockers,
    "dedupe": {
        "keys_observed": len(dedupe_keys),
        "unique_keys": unique_dedupe,
        "duplicate_rows": duplicate_rows,
        "duplicate_keys": duplicate_keys,
        "resend_after_rows": resend_count,
    },
    "shadow_side_effects": {
        "real_l61_attempts": real_l61_attempts,
        "real_bead_filing": real_bead_filing,
        "topology_mutations": topology_mutations,
    },
    "suppression_rows": len(suppressions),
    "malformed_suppression_rows": malformed_suppressions,
    "output_path": output,
    "dry_run": dry_run,
}

def markdown_report():
    lines = [
        "# Fleet Coherence Signal Quality Report",
        "",
        f"- Generated: `{summary['generated_at']}`",
        f"- Window: `{window}` (`{summary['cutoff']}` through `{summary['generated_at']}`)",
        f"- Events: `{events_file}`",
        f"- Latest snapshot: `{latest_file}`",
        f"- Suppressions: `{suppressions_file}`",
        "",
        "## Summary",
        "",
        "| metric | value |",
        "|---|---:|",
        f"| shadow rows | {len(selected)} |",
        f"| malformed rows | {malformed_rows} |",
        f"| invalid timestamp rows | {invalid_ts_rows} |",
        f"| p95 scan time | {fmt(p95_scan, 's')} |",
        f"| p95 status time | {fmt(p95_status, 's')} |",
        f"| suppression rows | {len(suppressions)} |",
        "",
        "## Rows Per Class",
        "",
        "| class | rows | open | closed | suppressed | would_l61 | would_bead | false-positive notes |",
        "|---|---:|---:|---:|---:|---:|---:|---|",
    ]
    if class_rows:
        for cls, stats in sorted(class_rows.items()):
            notes = []
            if stats["closed"]:
                notes.append(f"closed={stats['closed']}")
            if stats["suppressed"]:
                notes.append(f"suppressed={stats['suppressed']}")
            if not notes:
                notes.append("none observed")
            lines.append(f"| `{cls}` | {stats['rows']} | {stats['open']} | {stats['closed']} | {stats['suppressed']} | {stats['would_l61']} | {stats['would_bead']} | {', '.join(notes)} |")
    else:
        lines.append("| `none` | 0 | 0 | 0 | 0 | 0 | 0 | no rows in window |")
    lines += [
        "",
        "## Dedupe Resend Behavior",
        "",
        "| metric | value |",
        "|---|---:|",
        f"| dedupe keys observed | {len(dedupe_keys)} |",
        f"| unique dedupe keys | {unique_dedupe} |",
        f"| duplicate rows | {duplicate_rows} |",
        f"| resend_after rows | {resend_count} |",
        "",
        "Duplicate keys: " + (", ".join(f"`{k}`" for k in duplicate_keys[:20]) if duplicate_keys else "none observed"),
        "",
        "## Shadow Side Effects",
        "",
        "| side effect | rows detected |",
        "|---|---:|",
        f"| real L61 sends | {real_l61_attempts} |",
        f"| bead filing | {real_bead_filing} |",
        f"| topology mutation | {topology_mutations} |",
        "",
        "No real L61 sends, bead filing, or topology mutation were detected in the selected shadow rows." if not (real_l61_attempts or real_bead_filing or topology_mutations) else "One or more live-effect markers were detected; Phase 2a remains blocked.",
        "",
        "## Latest Snapshot",
        "",
    ]
    if latest_exists and isinstance(latest, dict) and not latest.get("_malformed"):
        latest_keys = ["schema_version", "generated_at", "ts", "session_count", "pane_count", "event_count"]
        found = False
        for key in latest_keys:
            if key in latest:
                lines.append(f"- `{key}`: `{latest[key]}`")
                found = True
        if not found:
            lines.append("- Snapshot loaded; no standard summary fields present.")
    elif latest_exists:
        lines.append("- Latest snapshot is malformed.")
    else:
        lines.append("- Latest snapshot was not present.")
    lines += [
        "",
        "## Phase 2a Decision",
        "",
        f"Final go/no-go: **{phase_line}**",
        "",
    ]
    if blockers:
        lines.append("Blocked by: " + ", ".join(f"`{b}`" for b in blockers) + ".")
        if blocked_classes:
            lines.append("Classes remaining blocked: " + ", ".join(f"`{c}`" for c in blocked_classes) + ".")
    else:
        lines.append("Phase 2a is unblocked for the observed classes in this shadow window.")
    lines += [
        "",
        "Close evidence:",
        "- `socraticode_queries=1 indexed_chunks_observed=10`",
        "- Targeted validator: `tests/fleet-coherence-quality-report.sh`",
    ]
    return "\n".join(lines) + "\n"

report = markdown_report()

if mode == "audit":
    summary["audit_report"] = report
    emit(summary)

if not dry_run:
    out = Path(output).expanduser()
    out.parent.mkdir(parents=True, exist_ok=True)
    out.write_text(report, encoding="utf-8")

if json_mode:
    emit(summary)
else:
    print(report if dry_run else f"wrote {output}\n{phase_line}")
PY
