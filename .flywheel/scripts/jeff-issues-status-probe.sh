#!/usr/bin/env bash
set -euo pipefail

STATUS_BIN="${JEFF_ISSUES_STATUS_BIN:-$HOME/.local/bin/jeff-issues-status}"
MODE="doctor"
JSON=0

usage() {
  cat <<'USAGE'
Usage:
  jeff-issues-status-probe.sh doctor|health [--json]
  jeff-issues-status-probe.sh --json
  jeff-issues-status-probe.sh --info [--json]
  jeff-issues-status-probe.sh --examples
  jeff-issues-status-probe.sh completion
  jeff-issues-status-probe.sh --help
USAGE
}

emit_json() {
  local doctor stale tracked
  doctor="$("$STATUS_BIN" --json doctor 2>/dev/null | tail -n 1 || true)"
  stale="$("$STATUS_BIN" --json stale --days 7 2>/dev/null | tail -n 1 || true)"
  tracked="$("$STATUS_BIN" --json list 2>/dev/null | tail -n 1 || true)"
  jq -e . >/dev/null 2>&1 <<<"$doctor" || doctor='{"status":"fail","warnings":["jeff_issues_doctor_failed"]}'
  jq -e . >/dev/null 2>&1 <<<"$stale" || stale='[]'
  jq -e . >/dev/null 2>&1 <<<"$tracked" || tracked='[]'
  jq -nc \
    --argjson doctor "$doctor" \
    --argjson stale "$stale" \
    --argjson tracked "$tracked" \
    '{
      command:"jeff-issues-status-probe",
      status:(if ($doctor.status // "fail") == "ok" then "ok" else "degraded" end),
      doctor:$doctor,
      stale_open_count:(if ($stale | type) == "array" then ($stale | length) else 0 end),
      tracked_count:(if ($tracked | type) == "array" then ($tracked | length) else 0 end),
      stale:$stale,
      warnings:(if ($doctor.status // "fail") == "ok" then [] else ["jeff_issues_status_degraded"] end)
    }'
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    doctor|--doctor) MODE="doctor"; shift ;;
    health|--health) MODE="health"; shift ;;
    --json) JSON=1; shift ;;
    --info) MODE="info"; shift ;;
    --examples) MODE="examples"; shift ;;
    completion) MODE="completion"; shift ;;
    --help|-h) MODE="help"; shift ;;
    *) usage >&2; exit 2 ;;
  esac
done

case "$MODE" in
  doctor|health)
    if [[ "$JSON" -eq 1 ]]; then
      emit_json
    else
      emit_json | jq -r '"jeff-issues-status-probe " + .status + " tracked=" + (.tracked_count|tostring) + " stale_open=" + (.stale_open_count|tostring)'
    fi
    ;;
  info)
    jq -nc --arg bin "$STATUS_BIN" '{command:"jeff-issues-status-probe",status_bin:$bin,read_only:true}'
    ;;
  examples)
    printf '%s\n' '.flywheel/scripts/jeff-issues-status-probe.sh doctor --json'
    ;;
  completion)
    printf 'complete -W "doctor health --json --info --examples completion --help" jeff-issues-status-probe.sh\n'
    ;;
  help)
    usage
    ;;
esac

# Meta-Learning Cross-References (2026-05-19)
# Batch-16 comment backfill; citations are documentation-only and do not alter runtime behavior.
# Related: `/Users/josh/Developer/skillos/.flywheel/doctrine/meta-learnings/MP-02-conformance-fixtures.md`
# Related: `/Users/josh/Developer/skillos/.flywheel/doctrine/meta-learnings/MP-68-schema-executable-validator-pair.md`
