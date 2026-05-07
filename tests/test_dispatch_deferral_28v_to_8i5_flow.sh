#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd -P)"
SCRIPT="$ROOT/.flywheel/scripts/dispatch-deferral-lint.sh"
TMP="$(mktemp -d -t deferral-lint-flow.XXXXXX)"
trap 'rm -r "$TMP"' EXIT

fail() {
  printf 'FAIL: %s\n' "$*" >&2
  exit 1
}

cat >"$TMP/ntm" <<'SH'
#!/usr/bin/env bash
set -euo pipefail
printf '%s\n' "$*" >>"$NTM_SEND_PIPE"
printf '{"ok":true,"transport_accepted":true}\n'
SH
chmod +x "$TMP/ntm"

jq -nc '{
  idle_worker_count: 1,
  ready_work_count: 3,
  pagerank_alignment: true,
  doctor_alignment: true,
  selected_action: "dispatch flywheel-8i5-selected-bead via canonical dispatch enforcement"
}' >"$TMP/signals.json"

cat >"$TMP/dispatch.md" <<'DRAFT'
# DISPATCH
# schema_version=2
dispatch_skill_version=flywheel-dispatch/v2
task_sha256=fixture
worker_substrate=codex-pane
agent_type=codex

## DATA-BACKED DEFERRAL
28v_selected_action=dispatch flywheel-8i5-selected-bead via canonical dispatch enforcement

## CALLBACK CONTRACT
DONE flywheel-8i5-selected-bead task_id=flow-fixture did=4/4 didnt=none gaps=none evidence=/tmp/flow tests=PASS mission_fitness=infrastructure callback_delivery_verified=true worker_substrate=codex-pane agent_type=codex socraticode_queries=6 indexed_chunks_observed=1289 files_reserved=tests/test_dispatch_deferral_28v_to_8i5_flow.sh files_released=tests/test_dispatch_deferral_28v_to_8i5_flow.sh no_bead_reason=fixture fuckups_logged=none

Action taken: dispatch flywheel-8i5-selected-bead via canonical dispatch enforcement.
DRAFT

"$SCRIPT" --draft "$TMP/dispatch.md" --signals "$TMP/signals.json" --require-canonical-dispatch --receipt "$TMP/lint-receipt.json" --json >"$TMP/lint.json"
jq -e '
  .status == "pass"
  and .data_answers == true
  and .flywheel_28v_selected_action == true
  and .flywheel_8i5_canonical_required == true
  and .canonical_dispatch_contract_ok == true
' "$TMP/lint.json" >/dev/null || fail "28v to 8i5 lint receipt mismatch"

NTM_SEND_PIPE="$TMP/ntm-send.log" FLYWHEEL_DISPATCH_WRAPPER=1 "$TMP/ntm" send flywheel --pane=3 "Read $TMP/dispatch.md and execute it as /flywheel:worker-tick parity." >"$TMP/ntm.json"

jq -e '.transport_accepted == true' "$TMP/ntm.json" >/dev/null || fail "mock ntm send did not accept transport"
grep -q -- '--pane=3' "$TMP/ntm-send.log" || fail "mock ntm send did not receive pane"

jq -n \
  --slurpfile lint "$TMP/lint-receipt.json" \
  --arg ntm_send_log "$TMP/ntm-send.log" \
  '{schema_version:"dispatch-deferral-28v-8i5-flow/v1", predicate_selected_action:$lint[0].flywheel_28v_selected_action, canonical_dispatch_passed:$lint[0].canonical_dispatch_contract_ok, ntm_dispatch_mocked:true, ntm_send_log:$ntm_send_log, callback_contract_enforced:true}' >"$TMP/flow-receipt.json"

jq -e '.predicate_selected_action == true and .canonical_dispatch_passed == true and .ntm_dispatch_mocked == true and .callback_contract_enforced == true' "$TMP/flow-receipt.json" >/dev/null || fail "flow receipt invalid"

printf 'PASS: dispatch deferral 28v to 8i5 flow\n'
