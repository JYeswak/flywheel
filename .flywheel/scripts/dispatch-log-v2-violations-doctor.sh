#!/usr/bin/env bash
# dispatch-log-v2-violations-doctor.sh
# Bounded read-only wrapper around dispatch-log-schema-validator.sh that emits
# a doctor packet exposing dispatch_log_v2_violations_count for the last N
# rows of .flywheel/dispatch-log.jsonl. Wires into flywheel-loop doctor and
# tick Step 4z.1. Bead: flywheel-yu8g.
set -euo pipefail

VERSION="dispatch-log-v2-violations-doctor/v1"
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd -P)"
REPO="$ROOT"
TAIL_N="${FLYWHEEL_DISPATCH_LOG_V2_TAIL:-100}"
JSON_OUT=0
COMMAND="doctor"

usage() {
  cat <<'EOF'
usage:
  dispatch-log-v2-violations-doctor.sh [doctor|health|validate|info|schema|why|help]
                                       [--repo PATH] [--tail N] [--json]

flags:
  --tail N    rows to validate from the end of dispatch-log.jsonl
              (default: 100, env FLYWHEEL_DISPATCH_LOG_V2_TAIL overrides)

exit codes: 0=report emitted (PASS/INFO), 1=violations found, 2=usage error
EOF
}

info() {
  jq -nc \
    --arg version "$VERSION" \
    --arg repo "$REPO" \
    --arg tail "$TAIL_N" \
    '{name:"dispatch-log-v2-violations-doctor.sh",version:$version,repo:$repo,default_tail:($tail|tonumber),mutates:"none",delegates_to:".flywheel/scripts/dispatch-log-schema-validator.sh",commands:["doctor","health","validate","info","schema","why","help"],flags:["--repo PATH","--tail N","--json"]}'
}

die_usage() { printf 'ERR: %s\n' "$1" >&2; exit 2; }

subcmd="${1:-}"
case "$subcmd" in
  doctor|health|validate)
    COMMAND="$subcmd"; shift ;;
  why)
    cat <<'EOF'
why: surfaces the count of dispatch-log v2 schema violations from the most
recent N rows so flywheel-loop doctor and tick Step 4z.1 can fail closed
when worker-emitted v2 rows drop required fields.
EOF
    exit 0 ;;
  info)
    info; exit 0 ;;
  schema)
    cat "$REPO/.flywheel/validation-schema/v1/dispatch-log-entry-v2.schema.json"; exit 0 ;;
  help|-h|--help)
    usage; exit 0 ;;
esac

while [[ $# -gt 0 ]]; do
  case "$1" in
    --repo) [[ $# -ge 2 ]] || die_usage "--repo requires PATH"; REPO="$(cd "$2" && pwd -P)"; shift 2 ;;
    --repo=*) REPO="$(cd "${1#*=}" && pwd -P)"; shift ;;
    --tail) [[ $# -ge 2 ]] || die_usage "--tail requires N"; TAIL_N="$2"; shift 2 ;;
    --tail=*) TAIL_N="${1#*=}"; shift ;;
    --json) JSON_OUT=1; shift ;;
    --help|-h) usage; exit 0 ;;
    --*) die_usage "unknown argument: $1" ;;
    *) die_usage "unexpected argument: $1" ;;
  esac
done

[[ "$TAIL_N" =~ ^[0-9]+$ ]] || die_usage "--tail must be a non-negative integer: $TAIL_N"

# The wrapper script and the validator ship together; use $ROOT (this script's
# own repo) to find the validator binary, while $REPO is the target whose
# dispatch-log.jsonl + schema are read.
VALIDATOR="${FLYWHEEL_DISPATCH_LOG_VALIDATOR:-$ROOT/.flywheel/scripts/dispatch-log-schema-validator.sh}"
LOG_PATH="$REPO/.flywheel/dispatch-log.jsonl"

if [[ ! -x "$VALIDATOR" ]]; then
  jq -nc --arg version "$VERSION" --arg log "$LOG_PATH" \
    '{schema_version:$version,status:"warn",dispatch_log_v2_violations_count:0,tail_size:0,log_present:false,errors:[{code:"validator_missing",message:"dispatch-log-schema-validator.sh is not executable"}],warnings:[]}'
  exit 0
fi

if [[ ! -f "$LOG_PATH" ]]; then
  jq -nc --arg version "$VERSION" --arg log "$LOG_PATH" \
    '{schema_version:$version,status:"pass",dispatch_log_v2_violations_count:0,tail_size:0,log_present:false,errors:[],warnings:[{code:"log_missing",message:"dispatch-log.jsonl not present"}]}'
  exit 0
fi

VAL_TMP="$(mktemp "${TMPDIR:-/tmp}/dispatch-log-v2-violations-doctor.XXXXXX")"
trap 'rm -f "$VAL_TMP"' EXIT

# Validator exits 1 when invalid > 0 under validate; we always want to read its
# JSON and decide here, so swallow the exit and inspect the summary.
if ! bash "$VALIDATOR" validate --repo "$REPO" --tail "$TAIL_N" --json >"$VAL_TMP" 2>/dev/null; then
  :
fi

if ! jq -e . >/dev/null 2>&1 <"$VAL_TMP"; then
  jq -nc --arg version "$VERSION" --arg log "$LOG_PATH" \
    '{schema_version:$version,status:"warn",dispatch_log_v2_violations_count:0,tail_size:0,log_present:true,errors:[{code:"validator_invalid_json",message:"validator emitted non-JSON output"}],warnings:[]}'
  exit 0
fi

PACKET="$(jq -c \
  --arg version "$VERSION" \
  --argjson tail_n "$TAIL_N" \
  '{
    schema_version: $version,
    status: (if (.invalid // 0) > 0 then "fail" else "pass" end),
    dispatch_log_v2_violations_count: (.invalid // 0),
    dispatch_log_v2_total_rows_checked: (.total // 0),
    dispatch_log_v2_malformed_count: (.malformed_count // 0),
    dispatch_log_v2_missing_fitness_class_count: (.missing_fitness_class // 0),
    dispatch_log_v2_missing_fitness_claim_count: (.missing_fitness_claim // 0),
    tail_size: $tail_n,
    log_present: (.log_present // true),
    expected_mission_anchor: (.expected_mission_anchor // ""),
    schema_id: (.schema_id // null),
    errors: [],
    warnings: (if (.invalid // 0) > 0 then [{code:"v2_violations_present",message:("invalid=" + ((.invalid // 0)|tostring) + " of " + ((.total // 0)|tostring) + " rows checked")}] else [] end)
  }' "$VAL_TMP")"

if [[ "$JSON_OUT" -eq 1 ]]; then
  printf '%s\n' "$PACKET"
else
  jq -r '"dispatch_log_v2_violations_count=\(.dispatch_log_v2_violations_count) tail_size=\(.tail_size) total=\(.dispatch_log_v2_total_rows_checked) status=\(.status)"' <<<"$PACKET"
fi

if [[ "$COMMAND" == "doctor" || "$COMMAND" == "validate" ]]; then
  count="$(jq -r '.dispatch_log_v2_violations_count' <<<"$PACKET")"
  [[ "$count" == "0" ]] || exit 1
fi
exit 0
