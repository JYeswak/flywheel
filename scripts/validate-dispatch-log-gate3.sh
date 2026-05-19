#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd -P)"
REPO="$ROOT"
LOG=""
JSON_OUT=0
MODE="lenient"

usage() {
  cat <<'EOF'
usage: validate-dispatch-log-gate3.sh [--repo PATH] [--log PATH] [--json] [--lenient|--strict]

Gate 3 lenient mode requires callback_received_at/cb_received_at only on
dispatch-shaped rows with status=completed|complete. Strict mode requires it on
every dispatch-shaped row.
EOF
}

die_usage() {
  printf 'ERR: %s\n' "$1" >&2
  exit 2
}

case "${1:-}" in
  --help|-h|help)
    usage
    exit 0
    ;;
  doctor|health|validate)
    shift
    [[ "${1:-}" == "--help" || "${1:-}" == "-h" ]] && { usage; exit 0; }
    ;;
esac

while [[ $# -gt 0 ]]; do
  case "$1" in
    --repo) [[ $# -ge 2 ]] || die_usage "--repo requires PATH"; REPO="$(cd "$2" && pwd -P)"; shift 2 ;;
    --repo=*) REPO="$(cd "${1#*=}" && pwd -P)"; shift ;;
    --log) [[ $# -ge 2 ]] || die_usage "--log requires PATH"; LOG="$2"; shift 2 ;;
    --log=*) LOG="${1#*=}"; shift ;;
    --json) JSON_OUT=1; shift ;;
    --lenient) MODE="lenient"; shift ;;
    --strict) MODE="strict"; shift ;;
    --*) die_usage "unknown argument: $1" ;;
    *) die_usage "unexpected argument: $1" ;;
  esac
done

[[ -n "$LOG" ]] || LOG="$REPO/.flywheel/dispatch-log.jsonl"
[[ -r "$LOG" ]] || die_usage "dispatch log not readable: $LOG"

python3 - "$LOG" "$MODE" "$JSON_OUT" <<'PY'
import json
import sys
from pathlib import Path

log_path = Path(sys.argv[1])
mode = sys.argv[2]
json_out = sys.argv[3] == "1"

terminal_statuses = {"completed", "complete"}
dispatch_events = {
    "dispatch_sent",
    "ntm_dispatch_sent",
    "dispatch_completed",
    "dispatch_status",
    "worker_dispatch",
}

total = 0
malformed = []
dispatch_rows = []
terminal_rows = []
terminal_missing = []
strict_missing = []
ignored_non_dispatch = []
intermediate_without_callback = []


def has_callback(row):
    for key in ("callback_received_at", "cb_received_at"):
        value = row.get(key)
        if value is not None and str(value).strip():
            return True
    return False


def event_name(row):
    return str(row.get("event") or "").strip().lower()


def status_name(row):
    return str(row.get("status") or row.get("dispatch_status") or "").strip().lower()


def is_dispatch_row(row):
    event = event_name(row)
    if event in dispatch_events or event.startswith("dispatch_") or event.startswith("ntm_dispatch_"):
        return True
    if row.get("dispatch_id") or row.get("worker_dispatch_id"):
        return True
    if row.get("task_id") and row.get("task_file") and (row.get("pane") is not None or row.get("to")):
        return True
    return False


for number, line in enumerate(log_path.read_text().splitlines(), start=1):
    if not line.strip():
        continue
    total += 1
    try:
        row = json.loads(line)
    except json.JSONDecodeError as exc:
        malformed.append({"line": number, "error": str(exc)})
        continue
    if not isinstance(row, dict):
        malformed.append({"line": number, "error": "json row is not an object"})
        continue

    callback = has_callback(row)
    dispatch_like = is_dispatch_row(row)
    status = status_name(row)
    event = event_name(row)
    entry = {
        "line": number,
        "event": event or None,
        "status": status or None,
        "task_id": row.get("task_id") or row.get("origin_task_id"),
    }

    if not dispatch_like:
        ignored_non_dispatch.append(entry)
        continue

    dispatch_rows.append(entry)
    if not callback:
        strict_missing.append(entry)

    if status in terminal_statuses:
        terminal_rows.append(entry)
        if not callback:
            terminal_missing.append(entry)
    elif not callback:
        intermediate_without_callback.append(entry)

terminal_count = len(terminal_rows)
terminal_with_callback = terminal_count - len(terminal_missing)
terminal_pct = 100.0 if terminal_count == 0 else round((terminal_with_callback / terminal_count) * 100, 2)

violations = strict_missing if mode == "strict" else terminal_missing
result = {
    "schema_version": "dispatch-log-gate3-validator/v1",
    "log": str(log_path),
    "mode": mode,
    "status": "PASS" if not violations else "FAIL",
    "total_rows": total,
    "dispatch_rows": len(dispatch_rows),
    "terminal_statuses": sorted(terminal_statuses),
    "terminal_rows": terminal_count,
    "terminal_with_callback": terminal_with_callback,
    "terminal_missing_callback": len(terminal_missing),
    "terminal_callback_compliance_pct": terminal_pct,
    "strict_missing_callback": len(strict_missing),
    "intermediate_without_callback_allowed": len(intermediate_without_callback),
    "non_dispatch_rows_ignored": len(ignored_non_dispatch),
    "malformed_rows_ignored": len(malformed),
    "violations": violations,
}

if json_out:
    print(json.dumps(result, sort_keys=True))
else:
    print(
        "Gate 3 {status}: terminal_callback_compliance_pct={pct:g} "
        "terminal_rows={terminal} terminal_missing_callback={missing} "
        "intermediate_without_callback_allowed={intermediate} non_dispatch_rows_ignored={ignored}".format(
            status=result["status"],
            pct=result["terminal_callback_compliance_pct"],
            terminal=result["terminal_rows"],
            missing=result["terminal_missing_callback"],
            intermediate=result["intermediate_without_callback_allowed"],
            ignored=result["non_dispatch_rows_ignored"],
        )
    )
    if violations:
        for violation in violations[:20]:
            print(
                "violation line={line} event={event} status={status} task_id={task_id}".format(
                    line=violation.get("line"),
                    event=violation.get("event"),
                    status=violation.get("status"),
                    task_id=violation.get("task_id"),
                ),
                file=sys.stderr,
            )

sys.exit(0 if not violations else 1)
PY
