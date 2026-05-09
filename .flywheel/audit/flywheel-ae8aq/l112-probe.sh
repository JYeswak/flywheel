#!/usr/bin/env bash
set -euo pipefail

if /Users/josh/.local/bin/ntm list --json \
  | jq -e '[.sessions[].name] | any(. == "picoz" or . == "polymarket-pico-z")' >/dev/null; then
  printf 'SESSION_AVAILABLE_retry_delivery\n'
  exit 1
fi

picoz_out="$(
  /Users/josh/.local/bin/ntm send picoz --pane=1 --no-cass-check --json \
    "Stage B mission-fidelity/L70 handoff delivery probe for flywheel-ae8aq" || true
)"
jq -e '.success == false and (.error | contains("session \"picoz\" not found"))' >/dev/null <<<"$picoz_out"

poly_out="$(
  /Users/josh/.local/bin/ntm send polymarket-pico-z --pane=1 --no-cass-check --json \
    "Stage B mission-fidelity/L70 handoff delivery probe for flywheel-ae8aq" || true
)"
jq -e '.success == false and (.error | contains("session \"polymarket-pico-z\" not found"))' >/dev/null <<<"$poly_out"

printf 'BLOCKED_flywheel_ae8aq_picoz_session_missing\n'
