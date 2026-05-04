#!/usr/bin/env bash
set -euo pipefail

VERSION="tick-receipt-validator/v1"
REPO="$PWD"
SESSION="${FLYWHEEL_SESSION:-flywheel}"
RECEIPT=""
DISPATCH_LOG=""
PEER_LEDGER="${FLYWHEEL_CROSS_ORCH_COORDINATION_LEDGER:-$HOME/.local/state/flywheel/cross-orch-coordination.jsonl}"
FUCKUP_LOG="${FLYWHEEL_FUCKUP_LOG:-$HOME/.local/state/flywheel/fuckup-log.jsonl}"
JSON_OUT=0

usage() {
  cat <<'USAGE'
usage: tick-receipt-validator.sh --repo PATH --receipt PATH [--session NAME] [--json]

Validates L70 v2 closeout semantics, then calls idle-pane-mechanical-gate.sh.

Options:
  --repo PATH          Repo whose tick receipt is being accepted.
  --session NAME       NTM session name, default flywheel.
  --receipt PATH       Tick closeout receipt JSON.
  --dispatch-log PATH  Optional dispatch log for l70_chain_decision scan.
  --peer-ledger PATH   Optional cross-orch coordination ledger.
  --fuckup-log PATH    Optional fuckup log for round-cap proof.
  --json               Emit machine-readable result.
  --help               Show this help.

Exit:
  0 receipt accepted
  2 receipt refused
USAGE
}

fail_usage() {
  printf 'ERR: %s\n' "$1" >&2
  usage >&2
  exit 64
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --repo) REPO="${2:?}"; shift 2 ;;
    --session) SESSION="${2:?}"; shift 2 ;;
    --receipt) RECEIPT="${2:?}"; shift 2 ;;
    --dispatch-log) DISPATCH_LOG="${2:?}"; shift 2 ;;
    --peer-ledger) PEER_LEDGER="${2:?}"; shift 2 ;;
    --fuckup-log) FUCKUP_LOG="${2:?}"; shift 2 ;;
    --json) JSON_OUT=1; shift ;;
    --help|-h) usage; exit 0 ;;
    *) fail_usage "unknown argument: $1" ;;
  esac
done

[[ -n "$RECEIPT" ]] || fail_usage "missing --receipt"
[[ -f "$RECEIPT" ]] || { printf 'ERR: receipt missing: %s\n' "$RECEIPT" >&2; exit 2; }
command -v jq >/dev/null 2>&1 || { printf 'ERR: jq required\n' >&2; exit 2; }

REPO="$(cd "$REPO" 2>/dev/null && pwd -P || printf '%s' "$REPO")"
[[ -n "$DISPATCH_LOG" ]] || DISPATCH_LOG="$REPO/.flywheel/dispatch-log.jsonl"
HOOK="$REPO/.flywheel/scripts/idle-pane-mechanical-gate.sh"
if [[ ! -x "$HOOK" ]]; then
  HOOK="/Users/josh/Developer/flywheel/.flywheel/scripts/idle-pane-mechanical-gate.sh"
fi
[[ -x "$HOOK" ]] || { printf 'ERR: idle pane gate missing: %s\n' "$HOOK" >&2; exit 2; }

tmp="$(mktemp -d "${TMPDIR:-/tmp}/tick-receipt-validator.XXXXXX")"
trap 'rm -rf "$tmp"' EXIT
failures="$tmp/failures.txt"
: >"$failures"

record_failure() {
  printf '%s\n' "$1" >>"$failures"
}

run_receipt_probe() {
  local label="$1" filter="$2"
  if ! jq -e "$filter" "$RECEIPT" >/dev/null 2>&1; then
    record_failure "$label"
  fi
}

run_receipt_probe "probe1_next_action_requires_same_tick_chain_attempted" '
  def b: if . == true or . == "true" or . == "yes" then "yes" elif . == false or . == "false" or . == "no" then "no" else . end;
  (.next_action_named // .next_action // .next_phase // .chain_blocker.next_phase // null) as $n
  | (.same_tick_chain_attempted // .chain_result.same_tick_chain_attempted // .l70.same_tick_chain_attempted // null | b) as $a
  | (($n == null) or ($n == "none") or ($a | IN("yes","no")))
'

run_receipt_probe "probe2_no_attempt_requires_allowed_blocker_reason" '
  def b: if . == true or . == "true" or . == "yes" then "yes" elif . == false or . == "false" or . == "no" then "no" else . end;
  (.same_tick_chain_attempted // .chain_result.same_tick_chain_attempted // .l70.same_tick_chain_attempted // null | b) as $a
  | (.chain_blocked_reason // .chain_blocker.chain_blocked_reason // .l70.chain_blocked_reason // "none") as $r
  | (($a == "yes") or ($r | IN("capacity","hard_blocker","peer_owned","none")))
'

run_receipt_probe "probe3_no_attempt_plus_next_action_cannot_use_none" '
  def b: if . == true or . == "true" or . == "yes" then "yes" elif . == false or . == "false" or . == "no" then "no" else . end;
  (.next_action_named // .next_action // .next_phase // .chain_blocker.next_phase // null) as $n
  | (.same_tick_chain_attempted // .chain_result.same_tick_chain_attempted // .l70.same_tick_chain_attempted // null | b) as $a
  | (.chain_blocked_reason // .chain_blocker.chain_blocked_reason // .l70.chain_blocked_reason // "none") as $r
  | (($n == null) or ($n == "none") or ($a == "yes") or ($r | IN("capacity","hard_blocker","peer_owned")))
'

run_receipt_probe "probe4_peer_owned_requires_route" '
  (.chain_blocked_reason // .chain_blocker.chain_blocked_reason // .l70.chain_blocked_reason // "none") as $r
  | (.peer_blocker_routed // .flywheel_blocker_routed // .flywheel_blocker_dispatched_to // "none" | tostring) as $route
  | (($r != "peer_owned") or (($route != "none") and ($route | test("^[A-Za-z0-9_.-]+:[0-9]+$"))))
'

run_receipt_probe "probe5_tick_complete_with_no_chain_requires_idle_class" '
  def b: if . == true or . == "true" or . == "yes" then "yes" elif . == false or . == "false" or . == "no" then "no" else . end;
  (.event // .status // .decision // "" | tostring) as $e
  | (.same_tick_chain_attempted // .chain_result.same_tick_chain_attempted // .l70.same_tick_chain_attempted // null | b) as $a
  | (.idle_reason_class // .idle_state_class // .l70.idle_reason_class // null) as $i
  | ((($e | test("tick_complete|done|IDLE_CLEAN")) | not) or ($a == "yes") or ($i | IN("no_work","no_capacity","hard_blocker","peer_owned")))
'

run_receipt_probe "probe6_idle_class_aligns_to_blocker_reason" '
  (.chain_blocked_reason // .chain_blocker.chain_blocked_reason // .l70.chain_blocked_reason // "none") as $r
  | (.idle_reason_class // .idle_state_class // .l70.idle_reason_class // null) as $i
  | ((($r == "capacity") and ($i == "no_capacity"))
    or (($r == "hard_blocker") and ($i == "hard_blocker"))
    or (($r == "peer_owned") and ($i == "peer_owned"))
    or (($r == "none") and (($i == null) or ($i == "no_work"))))
'

if [[ -f "$DISPATCH_LOG" ]]; then
  if ! jq -s -e '[.[]? | select((.event // "") == "l70_chain_decision") | select((.chain_required // false) == true) | select((.chained // false) != true) | select(((.chain_blocked_reason // .idle_reason_class // "") | tostring | length) == 0)] | length == 0' "$DISPATCH_LOG" >/dev/null 2>&1; then
    record_failure "probe7_v2_compatible_punt_rows"
  fi
fi

peer_owned="$(jq -r '(.chain_blocked_reason // .chain_blocker.chain_blocked_reason // .l70.chain_blocked_reason // "none") == "peer_owned"' "$RECEIPT")"
peer_route="$(jq -r '(.peer_blocker_routed // .flywheel_blocker_routed // .flywheel_blocker_dispatched_to // "none") | tostring' "$RECEIPT")"
if [[ "$peer_owned" == "true" ]]; then
  if [[ ! -f "$PEER_LEDGER" ]] || ! jq -e --arg route "$peer_route" '
      [.[]? | select(type=="object") | select((.peer_blocker_routed // .routed_to // .requested_owner // "") == $route)] | length > 0
    ' "$PEER_LEDGER" >/dev/null 2>&1; then
    record_failure "probe8_peer_route_ledger_row_exists"
  fi
fi

round_cap="$(jq -r '((.tick_loop_round_count // .round_count // 0) | tonumber? // 0) >= 5 or (.round_cap_reached // false) == true' "$RECEIPT")"
if [[ "$round_cap" == "true" ]]; then
  if [[ ! -f "$FUCKUP_LOG" ]] || ! grep -q 'tick_loop_round_cap' "$FUCKUP_LOG"; then
    record_failure "probe9_round_cap_creates_fuckup_row"
  fi
fi

gate_out="$tmp/gate.json"
gate_err="$tmp/gate.err"
gate_rc=0
"$HOOK" --repo "$REPO" --session "$SESSION" --receipt "$RECEIPT" --strict-receipt --json >"$gate_out" 2>"$gate_err" || gate_rc=$?
if [[ "$gate_rc" -eq 2 ]]; then
  record_failure "idle_pane_mechanical_gate:$(jq -r '.reason // "blocked"' "$gate_out" 2>/dev/null || printf blocked)"
elif [[ "$gate_rc" -ne 0 ]]; then
  record_failure "idle_pane_mechanical_gate_error_rc_$gate_rc"
fi

failure_count="$(wc -l <"$failures" | tr -d ' ')"
status="pass"
[[ "$failure_count" -eq 0 ]] || status="fail"

payload="$(
  jq -Rn \
    --arg schema "$VERSION" \
    --arg status "$status" \
    --arg repo "$REPO" \
    --arg session "$SESSION" \
    --arg receipt "$RECEIPT" \
    --arg hook "$HOOK" \
    --argjson gate "$(cat "$gate_out" 2>/dev/null || printf '{}')" \
    '{
      schema_version:$schema,
      status:$status,
      decision:(if $status == "pass" then "accept" else "refuse" end),
      repo:$repo,
      session:$session,
      receipt:$receipt,
      hook:$hook,
      l70_probe_count:9,
      failures:[inputs | select(length > 0)],
      idle_gate:$gate
    }' <"$failures"
)"

if [[ "$JSON_OUT" -eq 1 ]]; then
  printf '%s\n' "$payload"
fi

if [[ "$status" != "pass" ]]; then
  jq -r '"TICK RECEIPT REFUSED: " + (.failures | join(", "))' <<<"$payload" >&2
  exit 2
fi

exit 0
