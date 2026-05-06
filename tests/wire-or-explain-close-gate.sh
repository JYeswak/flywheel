#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd -P)"
BIN="$ROOT/.flywheel/scripts/wire-or-explain-close-gate.py"
SCHEMA="$ROOT/.flywheel/validation-schema/v1/tick-close-receipt.schema.json"
OVERRIDE_SCHEMA="$ROOT/.flywheel/validation-schema/v1/override-receipt.schema.json"
TMP="$(mktemp -d "${TMPDIR:-/tmp}/wire-or-explain-close-gate.XXXXXX")"
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
    fail "$label"
  fi
}

write_row() {
  local ledger="$1" id="$2" state="$3" session="$4" owning="$5" repo="$6" scope="$7" artifact="$8" consumer="$9"
  jq -nc \
    --arg id "$id" \
    --arg state "$state" \
    --arg session "$session" \
    --arg owning "$owning" \
    --arg repo "$repo" \
    --arg scope "$scope" \
    --arg artifact "$artifact" \
    --arg consumer "$consumer" \
    '{
      schema_name:"flywheel.wire-or-explain.v1",
      schema_version:"wire-or-explain-ledger/v1",
      identity_key:$id,
      timestamp:"2026-05-05T00:00:00Z",
      session_id:$session,
      event_type:"fixture",
      actor:"fixture",
      target:$id,
      payload:{dependency_count:2,ship_cost:3,downstream_cost:5},
      metadata:{fixture:true},
      state:$state,
      producer:"fixture",
      owner:(if $artifact == "skill_candidate" then "skillos" else $owning end),
      consumer:$consumer,
      blocking_scope:$scope,
      owning_orch:$owning,
      ship_repo:$repo,
      ship_actor:"fixture",
      artifact_class:$artifact,
      subject:$id,
      predicate:"fixture_predicate",
      auto_fire_trigger:"on_tick",
      drain_receipt_shape:"fixture_receipt",
      verification_probe:"bash tests/wire-or-explain-close-gate.sh",
      tick_status_consequence:"fixture consequence",
      stock:"wire-or-explain",
      inflow:"fixture",
      action_ledger:"fixture"
    }' >>"$ledger"
}

run_gate() {
  local name="$1" want_rc="$2"
  shift 2
  set +e
  python3 "$BIN" --repo "$ROOT" --receipt-dir "$TMP/receipts-$name" --override-receipt-dir "$TMP/override-receipts-$name" --verification-probe-command "bash tests/wire-or-explain-close-gate.sh" --json "$@" >"$TMP/$name.json" 2>"$TMP/$name.err"
  local got_rc=$?
  set -e
  if [[ "$got_rc" == "$want_rc" ]]; then
    pass "${name}_rc"
  else
    cat "$TMP/$name.json" >&2 || true
    cat "$TMP/$name.err" >&2 || true
    fail "${name}_rc expected=$want_rc got=$got_rc"
  fi
}

write_override() {
  local path="$1" expires="$2" reason="$3" bootstrap="$4" proof="$5" consumed="$6"
  jq -nc \
    --arg expires "$expires" \
    --arg reason "$reason" \
    --arg owner "CloudyMill" \
    --arg proof "$proof" \
    --argjson bootstrap "$bootstrap" \
    --argjson consumed "$consumed" \
    '{
      reason:$reason,
      owner:$owner,
      expires_at:$expires,
      affected_rows:["local-hard"],
      bootstrap:$bootstrap
    }
    + (if $proof == "" then {} else {bootstrap_proof:$proof} end)
    + (if $consumed then {bootstrap_consumed:true, consumed_at:"2026-05-05T00:05:00Z"} else {} end)' >"$path"
}

bash -n "$0" && pass "test_syntax"
python3 -m py_compile "$BIN" && pass "python_syntax"
bash -n "$ROOT/.flywheel/scripts/wire-or-explain-close-gate.sh" && pass "shim_syntax"
jq empty "$SCHEMA" && pass "schema_json"
jq -e '.title == "Wire Or Explain Override Receipt"' "$OVERRIDE_SCHEMA" >/dev/null && pass "override_schema_json"
python3 "$BIN" --help >/dev/null && pass "help_exits"
python3 "$BIN" --info --json | jq -e '.surface == "Tick Close Permit Gate" and .exit_codes["1"]' >/dev/null && pass "info_json"
python3 "$BIN" --examples --json | jq -e '(.examples | length) >= 5' >/dev/null && pass "examples_json"
python3 "$BIN" quickstart --json | jq -e '(.steps | length) >= 5' >/dev/null && pass "quickstart_json"
python3 "$BIN" completion bash | rg -q 'wire-or-explain-close-gate.py' && pass "completion_bash"
python3 "$BIN" --schema | jq -e '.title == "Tick Close Permit Gate Receipt"' >/dev/null && pass "schema_cli"

green="$TMP/green.jsonl"
write_row "$green" wired-ok wired flywheel flywheel:pane-1 "$ROOT" tick finding doctor
run_gate green 0 --ledger "$green" --mode enforce
assert_jq "$TMP/green.json" '.allowed == true and .would_block == false and .row_count == 1 and .receipt_written == true' "green_allowed_receipt"
test -f "$(jq -r '.receipt_path' "$TMP/green.json")" && pass "green_receipt_exists"

shadow="$TMP/shadow.jsonl"
write_row "$shadow" local-hard unwired flywheel flywheel:pane-1 "$ROOT" tick finding doctor
run_gate shadow 0 --ledger "$shadow" --mode shadow
assert_jq "$TMP/shadow.json" '.allowed == true and .would_block == true and .reason_code == "shadow_unresolved_local_rows" and (.top_actions | length) >= 1' "shadow_would_block"
pass "fixture_1_shadow_would_block"

enforce="$TMP/enforce.jsonl"
write_row "$enforce" local-hard unwired flywheel flywheel:pane-1 "$ROOT" tick finding doctor
run_gate enforce 1 --ledger "$enforce" --mode enforce
assert_jq "$TMP/enforce.json" '.allowed == false and .exit_code == 1 and .receipt_written == true and .local_unresolved_count == 1' "enforce_blocks_with_receipt"
test -f "$(jq -r '.receipt_path' "$TMP/enforce.json")" && pass "enforce_receipt_exists"
pass "fixture_2_enforce_blocks"

valid_override="$TMP/valid-override.json"
write_override "$valid_override" "2026-05-05T01:00:00Z" "bounded override ghp_aaaaaaaaaaaaaaaaaaaa for local-hard" false "" false
run_gate override 0 --ledger "$enforce" --mode enforce --override "$valid_override" --now "2026-05-05T00:10:00Z"
assert_jq "$TMP/override.json" '.allowed == true and .reason_code == "override_active" and .override_state.active == true and .override_state.owner == "CloudyMill"' "override_allows_with_context"
override_receipt="$(jq -r '.override_state.receipt_path' "$TMP/override.json")"
test -f "$override_receipt" && pass "override_receipt_exists"
assert_jq "$override_receipt" '.raw_evidence_included == false and .secret_scrubbed == true and .row_decisions["local-hard"].decision == "overridden"' "override_receipt_safe_shape"
if grep -q 'ghp_' "$override_receipt"; then
  fail "override_receipt_secret_scrubbed"
else
  pass "override_receipt_secret_scrubbed"
fi
pass "fixture_3_override_valid_receipt_scrubbed"

expired_override="$TMP/expired-override.json"
write_override "$expired_override" "2026-05-04T23:00:00Z" "expired override for local-hard" false "" false
run_gate expired 1 --ledger "$enforce" --mode enforce --override "$expired_override" --now "2026-05-05T00:10:00Z"
assert_jq "$TMP/expired.json" '.allowed == false and .reason_code == "override_expired" and any(.top_actions[]; .identity_key == "override:override_expired" and .state == "unwired")' "expired_override_rejected_with_action"
pass "fixture_4_expired_override_rejected"

bootstrap_override="$TMP/bootstrap-override.json"
write_override "$bootstrap_override" "2026-05-05T01:00:00Z" "B8 dogfood bootstrap override for local-hard" true "B8 dogfood self-test proof fixture" false
run_gate bootstrap 0 --ledger "$enforce" --mode bootstrap --override "$bootstrap_override" --now "2026-05-05T00:10:00Z"
assert_jq "$TMP/bootstrap.json" '.allowed == true and .reason_code == "bootstrap_override_active" and .override_state.bootstrap == true' "bootstrap_override_active"
bootstrap_receipt="$(jq -r '.override_state.receipt_path' "$TMP/bootstrap.json")"
assert_jq "$bootstrap_receipt" '.bootstrap == true and .bootstrap_consumed == true' "bootstrap_override_consumed_receipt"
consumed_override="$TMP/bootstrap-consumed-override.json"
write_override "$consumed_override" "2026-05-05T01:00:00Z" "already consumed bootstrap override for local-hard" true "B8 dogfood self-test proof fixture" true
run_gate bootstrap_consumed 1 --ledger "$enforce" --mode bootstrap --override "$consumed_override" --now "2026-05-05T00:10:00Z"
assert_jq "$TMP/bootstrap_consumed.json" '.allowed == false and .reason_code == "bootstrap_override_consumed" and any(.top_actions[]; .identity_key == "override:bootstrap_override_consumed")' "bootstrap_override_one_shot_rejected"
pass "fixture_5_bootstrap_one_shot"

cross="$TMP/cross.jsonl"
write_row "$cross" cross-row unwired alpsinsurance alpsinsurance:pane-1 /Users/josh/Developer/alpsinsurance fleet finding peer-orch
run_gate cross 0 --ledger "$cross" --mode enforce
assert_jq "$TMP/cross.json" '.allowed == true and .cross_orch_unresolved_count == 1 and any(.warnings[]; .code == "cross_orch_unresolved_rows")' "cross_orch_warn_only"

skill="$TMP/skill.jsonl"
write_row "$skill" skill-backlog unwired flywheel flywheel:pane-1 "$ROOT" skill_triage skill_candidate skillos
run_gate skill 0 --ledger "$skill" --mode shadow
assert_jq "$TMP/skill.json" '.skill_candidate_count == 1 and any(.top_actions[]; .route.action == "route_to_skillos" and .next_action == "route_skill_candidate_rows_to_skillos_or_record_deferral")' "skill_candidate_routes_to_skillos"

python3 "$BIN" why skill-backlog --ledger "$skill" --repo "$ROOT" --json | jq -e '.command == "why" and .found.route.action == "route_to_skillos" and (.rows | has("skill-backlog"))' >/dev/null && pass "why_json"
python3 "$BIN" --why --ledger "$skill" --repo "$ROOT" --json | jq -e '.command == "why" and (.rows | has("skill-backlog"))' >/dev/null && pass "why_flag_json"
python3 "$BIN" repair --ledger "$skill" --repo "$ROOT" --dry-run --json | jq -e '.planned_actions | length >= 2' >/dev/null && pass "repair_dry_run"

tail -n 1 "$ROOT/.flywheel/wire-or-explain-close-gate/README.md" | grep -qx 'Part of the Yuzu Method framework by ZestStream.' \
  && pass "readme_yuzu_footer" || fail "readme_yuzu_footer"

printf 'PASS wire-or-explain-close-gate %s checks\n' "$pass_count"
