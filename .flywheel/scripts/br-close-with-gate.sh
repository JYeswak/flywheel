#!/usr/bin/env bash
set -euo pipefail

VERSION="br-close-with-gate.v1.0.0"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)"
SCHEMA_GATE="${CALLBACK_ENVELOPE_SCHEMA_VALIDATOR_BIN:-$SCRIPT_DIR/callback-envelope-schema-validator.sh}"
GATE="${AUTO_L112_GATE_BIN:-$SCRIPT_DIR/auto-l112-gate.sh}"
BR_BIN="${AUTO_L112_GATE_BR_BIN:-br}"

BEAD=""
TASK_ID=""
CALLBACK_ENVELOPE_FILE=""
REASON="auto-l112-gate passed"
JSON_OUT=0

usage() {
  cat <<'EOF'
usage: br-close-with-gate.sh --bead ID --task-id ID --callback-envelope-file PATH [--reason TEXT] [--json]

Runs callback-envelope-schema-validator before auto-l112-gate, then br close.
The bead is not closed unless both gates exit 0.
EOF
}

info() {
  jq -nc --arg version "$VERSION" --arg schema_gate "$SCHEMA_GATE" --arg gate "$GATE" --arg br "$BR_BIN" \
    '{name:"br-close-with-gate.sh",version:$version,schema_gate:$schema_gate,gate:$gate,br:$br,exit_codes:{"0":"schema gate and L112 gate passed; br close succeeded","1":"schema gate, L112 gate, or br close failed","2":"usage","3":"validated append, gate timeout, or sandbox refusal"}}'
}

examples() {
  cat <<'EOF'
br-close-with-gate.sh --bead flywheel-123 --task-id b56-example --callback-envelope-file /tmp/callback-envelope.txt --reason "L112 gate passed" --json
EOF
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --bead) BEAD="${2:-}"; shift 2 ;;
    --task-id) TASK_ID="${2:-}"; shift 2 ;;
    --callback-envelope-file) CALLBACK_ENVELOPE_FILE="${2:-}"; shift 2 ;;
    --reason) REASON="${2:-}"; shift 2 ;;
    --json) JSON_OUT=1; shift ;;
    --info) info; exit 0 ;;
    --examples) examples; exit 0 ;;
    --version) printf '%s\n' "$VERSION"; exit 0 ;;
    --help|-h) usage; exit 0 ;;
    *) echo "ERR: unknown argument: $1" >&2; usage >&2; exit 2 ;;
  esac
done

[[ -n "$BEAD" && -n "$TASK_ID" && -n "$CALLBACK_ENVELOPE_FILE" ]] || { usage >&2; exit 2; }

set +e
schema_output="$("$SCHEMA_GATE" validate envelope --callback-envelope-file "$CALLBACK_ENVELOPE_FILE" --apply --json)"
schema_rc=$?
set -e
if ! jq -e . >/dev/null 2>&1 <<<"$schema_output"; then
  schema_output="$(jq -nc --arg raw "$schema_output" '{raw_output:$raw}')"
fi
if [[ "$schema_rc" -ne 0 ]]; then
  if [[ "$JSON_OUT" -eq 1 ]]; then
    jq -nc --arg bead "$BEAD" --argjson schema "$schema_output" --argjson schema_rc "$schema_rc" \
      '{status:"blocked",bead:$bead,failure_class:"callback_envelope_schema_failed",schema_exit_code:$schema_rc,schema:$schema}'
  else
    printf 'BLOCKED bead=%s failure=callback_envelope_schema_failed schema_exit_code=%s\n' "$BEAD" "$schema_rc"
  fi
  exit "$schema_rc"
fi

set +e
gate_output="$("$GATE" --gate --task-id "$TASK_ID" --callback-envelope-file "$CALLBACK_ENVELOPE_FILE" --json)"
gate_rc=$?
set -e
if [[ "$gate_rc" -ne 0 ]]; then
  if [[ "$JSON_OUT" -eq 1 ]]; then
    jq -nc --arg bead "$BEAD" --argjson schema "$schema_output" --argjson gate "$gate_output" --argjson gate_rc "$gate_rc" \
      '{status:"blocked",bead:$bead,gate_exit_code:$gate_rc,schema:$schema,gate:$gate}'
  else
    printf 'BLOCKED bead=%s gate_exit_code=%s\n' "$BEAD" "$gate_rc"
  fi
  exit "$gate_rc"
fi

set +e
close_output="$("$BR_BIN" close "$BEAD" --reason "$REASON" --lock-timeout 5000 --json 2>&1)"
close_rc=$?
set -e
if [[ "$close_rc" -ne 0 ]]; then
  if [[ "$JSON_OUT" -eq 1 ]]; then
    jq -nc --arg bead "$BEAD" --argjson schema "$schema_output" --argjson gate "$gate_output" --arg close_output "$close_output" \
      '{status:"failed",bead:$bead,failure_class:"br_close_failed",schema:$schema,gate:$gate,close_output:$close_output}'
  else
    printf 'FAIL bead=%s failure=br_close_failed\n%s\n' "$BEAD" "$close_output"
  fi
  exit 1
fi

if [[ "$JSON_OUT" -eq 1 ]]; then
  jq -nc --arg bead "$BEAD" --argjson schema "$schema_output" --argjson gate "$gate_output" --argjson close "$close_output" \
    '{status:"closed",bead:$bead,schema:$schema,gate:$gate,br_close:$close}'
else
  printf 'CLOSED bead=%s\n' "$BEAD"
fi
