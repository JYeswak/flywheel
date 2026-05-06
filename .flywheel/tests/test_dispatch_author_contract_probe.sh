#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd -P)"
BIN="$ROOT/.flywheel/scripts/dispatch-author-contract-probe.sh"
TMP="$(mktemp -d "${TMPDIR:-/tmp}/dispatch-author-contract-test.XXXXXX")"
trap 'rm -rf "$TMP"' EXIT

pass_count=0
fail_count=0

pass() { printf 'PASS %s\n' "$1"; pass_count=$((pass_count + 1)); }
fail() { printf 'FAIL %s\n' "$1"; fail_count=$((fail_count + 1)); }

assert_jq() {
  local file="$1" expr="$2" label="$3"
  if jq -e "$expr" "$file" >/dev/null; then
    pass "$label"
  else
    fail "$label"
    jq . "$file" >&2 || true
  fi
}

write_packet() {
  local path="$1" overrides="${2:-}"
  cat >"$path" <<'PACKET'
# Dispatch fixture
dispatch_class_merge_order: bead_labels,touched_files,mission_surfaces,socraticode,override
strictest_invariant_wins=true
collision_policy=resolved
discovery_precedence: exact:get_skill > local:SKILL.md-readable > semantic:socraticode > external:npx-skills-find-installable-only > fallback:rg-filesystem
required_overlays: canonical-cli-scoping, readme-writing, de-slopify, simplify, socraticode, agent-mail, agent-monitoring, cost-attribution, search-tool-routing-doctrine
secret_values_allowed=false
route_receipt_schema_version=dispatch-author-route-receipt/v1
skill_routing: present
skill_receipts[] required_fields: receipt_identity_key, skill, source, action_taken, policy_version, evidence, alias_of, not_applicable_reason
dispatch_receipt required_fields: idempotency_key, replay_detection_hash, transaction_boundary, receipt_completeness
selected_skill_count: 9
prompt_budget_policy: names-plus-one-line-why; excerpts <= 25 percent or 1200 tokens
PACKET
  if [[ -n "$overrides" ]]; then
    printf '%s\n' "$overrides" >>"$path"
  fi
}

run_expect_rc() {
  local name="$1" expected="$2" path="$3" rc out
  out="$TMP/$name.json"
  set +e
  "$BIN" --json "$path" >"$out"
  rc=$?
  set -e
  if [[ "$rc" == "$expected" ]]; then
    pass "$name rc=$expected"
  else
    fail "$name expected_rc=$expected actual_rc=$rc"
    cat "$out" >&2 || true
  fi
}

replace_text() {
  local path="$1" old="$2" new="$3"
  OLD_TEXT="$old" NEW_TEXT="$new" perl -0pi -e 's/\Q$ENV{OLD_TEXT}\E/$ENV{NEW_TEXT}/g' "$path"
}

bash -n "$BIN" && pass "probe_syntax" || fail "probe_syntax"
"$BIN" --info --json >"$TMP/info.json"
assert_jq "$TMP/info.json" '.name == "dispatch-author-contract-probe" and (.canonical_cli_flags | index("--quiet"))' "info_json_names_cli_flags"

compliant="$TMP/compliant.md"
write_packet "$compliant"
run_expect_rc compliant_pass 0 "$compliant"
assert_jq "$TMP/compliant_pass.json" '.verdict == "pass" and all(.checks[]; .status == "pass") and (.violations | length == 0)' "compliant verdict pass"

missing_overlay="$TMP/missing-overlay.md"
write_packet "$missing_overlay"
replace_text "$missing_overlay" "de-slopify, " ""
run_expect_rc missing_universal_overlay_fail 1 "$missing_overlay"
assert_jq "$TMP/missing_universal_overlay_fail.json" '.verdict == "fail" and any(.violations[]; .code == "required_overlay_missing")' "missing universal overlay fails"

collision="$TMP/collision.md"
write_packet "$collision"
replace_text "$collision" "collision_policy=resolved" "collision_policy=unresolved"
run_expect_rc class_collision_unresolved_fail 1 "$collision"
assert_jq "$TMP/class_collision_unresolved_fail.json" '.verdict == "fail" and any(.violations[]; .code == "class_collision_unresolved")' "unresolved collision fails"

secret="$TMP/secret.md"
write_packet "$secret" "example_raw_value: Bearer synthetic-token-fragment-1234567890"
run_expect_rc secret_value_present_fail 1 "$secret"
assert_jq "$TMP/secret_value_present_fail.json" '.verdict == "fail" and any(.violations[]; .code == "secret_value_literal_present")' "secret-shaped value fails"

precedence="$TMP/precedence.md"
write_packet "$precedence"
replace_text "$precedence" "exact:get_skill > local:SKILL.md-readable > semantic:socraticode > external:npx-skills-find-installable-only > fallback:rg-filesystem" "fallback:rg-filesystem > external:npx-skills-find-installable-only > semantic:socraticode > local:SKILL.md-readable > exact:get_skill"
run_expect_rc discovery_precedence_reversed_fail 1 "$precedence"
assert_jq "$TMP/discovery_precedence_reversed_fail.json" '.verdict == "fail" and any(.violations[]; .code == "discovery_precedence_invalid")' "reversed precedence fails"

receipt="$TMP/receipt.md"
write_packet "$receipt"
replace_text "$receipt" "receipt_identity_key, " ""
run_expect_rc receipt_schema_malformed_fail 1 "$receipt"
assert_jq "$TMP/receipt_schema_malformed_fail.json" '.verdict == "fail" and any(.violations[]; .code == "route_receipt_schema_malformed")' "malformed receipt schema fails"

budget="$TMP/budget.md"
write_packet "$budget"
replace_text "$budget" "selected_skill_count: 9" "selected_skill_count: 14"
run_expect_rc prompt_budget_exceeded_partial 0 "$budget"
assert_jq "$TMP/prompt_budget_exceeded_partial.json" '.verdict == "partial" and .checks.prompt_budget_within_limit.status == "fail" and any(.violations[]; .code == "prompt_budget_exceeded" and .severity == "warn")' "budget overage is partial with recommendation"

printf 'RESULT pass=%s fail=%s\n' "$pass_count" "$fail_count"
[[ "$pass_count" -ge 16 && "$fail_count" == "0" ]]
