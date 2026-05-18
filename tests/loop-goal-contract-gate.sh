#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd -P)"
GATE="$ROOT/.flywheel/scripts/loop-goal-contract-gate.sh"
PACKET="$ROOT/.flywheel/scripts/build-dispatch-packet.sh"
TMP="$(mktemp -d "${TMPDIR:-/tmp}/loop-goal-contract-gate.XXXXXX")"
trap 'rm -rf "$TMP"' EXIT

pass_count=0
fail_count=0
pass() { pass_count=$((pass_count + 1)); printf 'PASS %s\n' "$1"; }
fail() { fail_count=$((fail_count + 1)); printf 'FAIL %s\n' "$1" >&2; }

log="$TMP/dispatch-log.jsonl"
missing_out="$TMP/missing.json"
"$GATE" validate --repo "$TMP" --decision DISPATCH_BEAD --task-id tick-missing --dispatch-log "$log" --json >"$missing_out"
jq -e '.status == "no_dispatch" and .reason == "missing_goal_contract" and (.missing_fields | index("contract_path"))' "$missing_out" >/dev/null \
  && jq -e '.event == "NO_DISPATCH" and .status == "missing_goal_contract" and .mode == "loop" and .tick_id == "tick-missing"' "$log" >/dev/null \
  && ! jq -e 'select(.event == "ntm_dispatch_sent")' "$log" >/dev/null \
  && pass "missing contract refuses dispatch" || fail "missing contract refuses dispatch"

contract="$TMP/contract.json"
jq -nc '{
  goal_id:"goal-fixture",
  hard_bars:["bar1"],
  forbid_clauses:["no stale state fallback"],
  target_beads:["flywheel-fixture"],
  out_of_scope_lanes:["Track 1","Track 2"],
  callback_envelope:{required:["did","gaps","br_close_executed"]},
  stop_conditions:["missing contract"]
}' >"$contract"

valid_out="$TMP/valid.json"
"$GATE" validate --repo "$TMP" --decision DISPATCH_BEAD --task-id tick-valid --contract "$contract" --dispatch-log "$log" --json >"$valid_out"
jq -e '.status == "dispatch_allowed" and .contract.goal_id == "goal-fixture" and .mode == "loop"' "$valid_out" >/dev/null \
  && pass "valid contract allows dispatch" || fail "valid contract allows dispatch"

cat >"$TMP/br" <<'SH'
#!/usr/bin/env bash
set -euo pipefail
case "${1:-}" in
  show)
    jq -nc '[{id:"flywheel-fixture",title:"Fixture dispatch",description:"Acceptance: prove contract block",priority:1}]'
    ;;
  dep)
    jq -nc '{}'
    ;;
  *)
    jq -nc '{}'
    ;;
esac
SH
chmod +x "$TMP/br"

cat >"$TMP/ntm" <<'SH'
#!/usr/bin/env bash
set -euo pipefail
case "${1:-} ${2:-}" in
  "context build")
    jq -nc '{id:"ctx-fixture",repo_rev:"fixture-rev"}'
    ;;
  "template show")
    jq -nc '{name:"marching_orders",source:"fixture"}'
    ;;
  *)
    jq -nc '{}'
    ;;
esac
SH
chmod +x "$TMP/ntm"

topology="$TMP/topology.jsonl"
jq -nc '{session:"fixture",orchestrator_pane:1,callback_pane:1,worker_panes:[2],effective_at:"2026-05-18T00:00:00Z"}' >"$topology"

PATH="$TMP:$PATH" \
FLYWHEEL_NTM_BIN="$TMP/ntm" \
FLYWHEEL_TOPOLOGY="$topology" \
  "$PACKET" --bead-id flywheel-fixture --target-pane 2 --target-session fixture --task-id tick-valid --goal-contract "$contract" --output-dir "$TMP" --apply --json >"$TMP/packet.json"

packet_path="$(jq -r '.packet_path' "$TMP/packet.json")"
jq -e '.fields_resolved.goal_contract.goal_id == "goal-fixture" and (.validation_blocks_present | index("LOOP GOAL CONTRACT BLOCK"))' "$TMP/packet.json" >/dev/null \
  && grep -q '^## LOOP GOAL CONTRACT BLOCK' "$packet_path" \
  && grep -q '"goal_id":"goal-fixture"' "$packet_path" \
  && pass "dispatch packet carries contract verbatim" || fail "dispatch packet carries contract verbatim"

printf 'Summary: %d passed, %d failed\n' "$pass_count" "$fail_count"
[[ "$fail_count" -eq 0 ]]
