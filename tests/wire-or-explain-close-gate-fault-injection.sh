#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd -P)"
BIN="$ROOT/.flywheel/scripts/wire-or-explain-close-gate.py"
CHAIN_VERIFIER="$ROOT/.flywheel/scripts/wire-or-explain-chain-verifier.sh"
FIXTURES="$ROOT/tests/fixtures/wire-or-explain/fault-injection"
TMP="$(mktemp -d "${TMPDIR:-/tmp}/wire-or-explain-close-gate-fault.XXXXXX")"
trap 'rm -rf "$TMP"' EXIT

pass_count=0
fail_count=0

pass() { printf 'PASS %s\n' "$1"; pass_count=$((pass_count + 1)); }
fail() { printf 'FAIL %s\n' "$1" >&2; fail_count=$((fail_count + 1)); exit 1; }

assert_jq() {
  local file="$1" filter="$2" label="$3"
  if jq -e "$filter" "$file" >/dev/null; then
    pass "$label"
  else
    cat "$file" >&2 || true
    fail "$label"
  fi
}

emit_ledger() {
  local fixture="$1" ledger="$2"
  jq -c --arg root "$ROOT" 'map(.ship_repo = (if .ship_repo == "__ROOT__" then $root else .ship_repo end))[]' \
    "$FIXTURES/$fixture/rows.json" >"$ledger"
}

run_gate() {
  local name="$1" fixture="$2" want_rc="$3" mode="$4"
  shift 4
  local ledger="$TMP/$name.jsonl"
  emit_ledger "$fixture" "$ledger"
  set +e
  python3 "$BIN" --repo "$ROOT" --ledger "$ledger" --mode "$mode" \
    --receipt-dir "$TMP/receipts-$name" \
    --override-receipt-dir "$TMP/override-receipts-$name" \
    --verification-probe-command "bash tests/wire-or-explain-close-gate-fault-injection.sh" \
    --now "2026-05-05T12:00:00Z" --json "$@" >"$TMP/$name.json" 2>"$TMP/$name.err"
  local got_rc=$?
  set -e
  if [[ "$got_rc" == "$want_rc" ]]; then
    pass "${name}_rc"
  else
    cat "$TMP/$name.json" >&2 || true
    cat "$TMP/$name.err" >&2 || true
    fail "${name}_rc expected=$want_rc got=$got_rc"
  fi
  python3 "$BIN" --why --repo "$ROOT" --ledger "$ledger" --mode "$mode" \
    --now "2026-05-05T12:00:00Z" --json "$@" >"$TMP/$name.why.json"
}

write_override() {
  local path="$1" affected="$2" bootstrap="$3"
  jq -nc \
    --arg affected "$affected" \
    --argjson bootstrap "$bootstrap" \
    '{
      reason:"fault injection fixture override with bounded evidence",
      owner:"StormyBay",
      expires_at:"2026-05-05T13:00:00Z",
      affected_rows:[$affected],
      bootstrap:$bootstrap
    } + (if $bootstrap then {bootstrap_proof:"B8 dogfood self-test proof from fault injection fixture"} else {} end)' \
    >"$path"
}

assert_surfaces() {
  local name="$1" row_id="$2"
  if jq -e --arg id "$row_id" 'any(.top_actions[]; .identity_key == $id)' "$TMP/$name.json" >/dev/null; then
    pass "${name}_top_action"
  else
    cat "$TMP/$name.json" >&2 || true
    fail "${name}_top_action"
  fi
  if jq -e --arg id "$row_id" '.rows | has($id)' "$TMP/$name.why.json" >/dev/null; then
    pass "${name}_why_row"
  else
    cat "$TMP/$name.why.json" >&2 || true
    fail "${name}_why_row"
  fi
}

bash -n "$0" && pass "test_syntax"
python3 -m py_compile "$BIN" && pass "python_syntax"
test -d "$FIXTURES" && pass "fixture_dir_exists"

run_gate fm1 fm-1 1 enforce
assert_jq "$TMP/fm1.json" '.allowed == false and .reason_code == "unresolved_local_rows" and .local_unresolved_count == 1' "fm1_blocks_timeout"
assert_surfaces fm1 fm1-slow-consumer-timeout

fm2_override="$TMP/fm2-override.json"
write_override "$fm2_override" fm2-false-positive-wired-artifact false
run_gate fm2 fm-2 0 enforce --override "$fm2_override"
assert_jq "$TMP/fm2.json" '.allowed == true and .reason_code == "override_active" and .override_state.active == true' "fm2_manual_resolution_override"
assert_jq "$TMP/fm2.why.json" '.rows["fm2-false-positive-wired-artifact"].decision == "overridden"' "fm2_why_overridden"

run_gate fm3 fm-3 1 enforce
assert_jq "$TMP/fm3.json" '.allowed == false and any(.top_actions[]; .predicate == "ship_event_unclassified_count_24h")' "fm3_unclassified_ship_event"
assert_surfaces fm3 fm3-collector-missed-ship-event

run_gate fm4 fm-4 0 shadow
assert_jq "$TMP/fm4.json" '.allowed == true and .would_block == true and .reason_code == "shadow_unresolved_local_rows" and any(.top_actions[]; .predicate == "gate_p95_latency_exceeded")' "fm4_latency_visible_shadow"
assert_surfaces fm4 fm4-gate-latency-p95

fm5_override="$TMP/fm5-bootstrap-override.json"
write_override "$fm5_override" fm5-bootstrap-recursion true
run_gate fm5 fm-5 0 bootstrap --override "$fm5_override"
assert_jq "$TMP/fm5.json" '.allowed == true and .reason_code == "bootstrap_override_active" and .override_state.bootstrap == true' "fm5_bootstrap_recursion_closes_with_proof"
assert_jq "$TMP/fm5.why.json" '.rows["fm5-bootstrap-recursion"].decision == "overridden"' "fm5_why_overridden"

run_gate fm6 fm-6 4 enforce
assert_jq "$TMP/fm6.json" '.allowed == false and .reason_code == "fleet_owned_unresolved_rows" and .exit_code == 4' "fm6_cross_repo_pending_expires_hard"
assert_surfaces fm6 fm6-cross-repo-pending-expired

run_gate fm7 fm-7 1 enforce
assert_jq "$TMP/fm7.json" '.allowed == false and any(.top_actions[]; .identity_key == "fm7-stale-consumer-superseded" and .consumer == "removed-consumer")' "fm7_stale_consumer_superseded"
assert_surfaces fm7 fm7-stale-consumer-superseded

run_gate relay_missing missing-relay 0 shadow
assert_jq "$TMP/relay_missing.json" '.skill_candidate_count == 1 and any(.top_actions[]; .route.action == "route_to_{capability-control-plane}" and .next_action == "route_skill_candidate_rows_to_{capability-control-plane}_or_record_deferral")' "relay_missing_routes_to_{capability-control-plane}"
assert_surfaces relay_missing relay-missing-skill-candidate

run_gate relay_duplicate duplicate-relay 0 shadow
assert_jq "$TMP/relay_duplicate.json" '.row_count == 2 and .skill_candidate_count == 2' "relay_duplicate_rows_visible"
assert_jq "$TMP/relay_duplicate.why.json" '(.rows | keys | map(select(. == "relay-duplicate-skill-candidate")) | length) == 1' "relay_duplicate_dedupes_by_row_identity"
jq -n --arg identity "relay-duplicate-skill-candidate" \
  --argjson groups "$(jq '[.[].identity_key] | group_by(.) | map(select(length > 1)) | length' "$FIXTURES/duplicate-relay/rows.json")" \
  '{status:"duplicate", duplicate_identity_key:$identity, duplicate_group_count:$groups}' >"$TMP/relay-duplicate-receipt.json"
assert_jq "$TMP/relay-duplicate-receipt.json" '.status == "duplicate" and .duplicate_group_count == 1' "relay_duplicate_receipt"

run_gate relay_stale stale-relay 0 shadow
assert_jq "$TMP/relay_stale.json" 'any(.top_actions[]; .identity_key == "relay-stale-overdue-skill-candidate" and .age_hours > 24)' "relay_stale_overdue_action"
assert_jq "$FIXTURES/stale-relay/rows.json" '.[0].metadata.expires_at < "2026-05-05T12:00:00Z"' "relay_stale_fixture_expired"

run_gate {capability-control-plane}_unavailable {capability-control-plane}-unavailable 1 enforce
assert_jq "$TMP/{capability-control-plane}_unavailable.json" '.allowed == false and .reason_code == "unresolved_local_rows" and any(.top_actions[]; .route.target == "{capability-control-plane}" and .predicate == "{capability-control-plane}_unavailable")' "relay_{capability-control-plane}_unavailable_not_silent"
assert_surfaces {capability-control-plane}_unavailable relay-{capability-control-plane}-unavailable

run_gate ntm_chain ntm-chain-break 1 enforce
set +e
"$CHAIN_VERIFIER" verify --ledger "$TMP/ntm_chain.jsonl" --json >"$TMP/ntm-chain-verify.json" 2>"$TMP/ntm-chain-verify.err"
chain_rc=$?
set -e
if [[ "$chain_rc" == "1" ]]; then
  pass "ntm_chain_break_verifier_rc"
else
  cat "$TMP/ntm-chain-verify.json" >&2 || true
  cat "$TMP/ntm-chain-verify.err" >&2 || true
  fail "ntm_chain_break_verifier_rc expected=1 got=$chain_rc"
fi
assert_jq "$TMP/ntm-chain-verify.json" '.status == "fail" and .tampered_count >= 1 and any(.tampered_rows[]; (.reason | contains("prev_hash")) or (.reason | contains("checksum")))' "ntm_chain_break_detected"
assert_surfaces ntm_chain ntm-chain-break

run_gate secret_evidence secret-evidence 1 enforce
assert_jq "$TMP/secret_evidence.json" '.allowed == false and any(.top_actions[]; .identity_key == "secret-evidence-scrubbed")' "secret_evidence_blocks_without_payload"
if grep -R -q 'sk_live_FAKE_DO_NOT_USE_1234567890' "$TMP/secret_evidence.json" "$TMP/secret_evidence.why.json"; then
  fail "secret_evidence_scrubbed_output"
else
  pass "secret_evidence_scrubbed_output"
fi
assert_surfaces secret_evidence secret-evidence-scrubbed

printf 'PASS wire-or-explain-close-gate-fault-injection %s checks\n' "$pass_count"
