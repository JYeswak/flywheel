#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd -P)"
SCRIPT="$ROOT/.flywheel/scripts/close-validator-contract-probe.sh"
CONTRACT="$ROOT/.flywheel/doctrine/close-validator-receipt-contract.md"
TMP="$(mktemp -d "${TMPDIR:-/tmp}/close-validator-contract.XXXXXX")"
trap 'rm -rf "$TMP"' EXIT

pass_count=0
fail_count=0

pass() { printf 'PASS %s\n' "$1"; pass_count=$((pass_count + 1)); }
fail() { printf 'FAIL %s\n' "$1" >&2; fail_count=$((fail_count + 1)); }
sha256_text() { printf '%s' "$1" | shasum -a 256 | awk '{print "sha256:" $1}'; }

assert_jq() {
  local file="$1" expr="$2" label="$3"
  if jq -e "$expr" "$file" >/dev/null; then
    pass "$label"
  else
    fail "$label"
    jq . "$file" >&2 || true
  fi
}

run_probe() {
  local name="$1" fixture="$2" ledger="${3:-}" out rc
  out="$TMP/$name.json"
  set +e
  if [[ -n "$ledger" ]]; then
    "$SCRIPT" --callback-file "$fixture" --close-ledger "$ledger" --json >"$out"
  else
    "$SCRIPT" --callback-file "$fixture" --json >"$out"
  fi
  rc=$?
  set -e
  printf '%s %s\n' "$out" "$rc"
}

assert_golden() {
  local file="$1" status="$2" valid="$3" count="$4" duplicate="$5" failures="$6" warnings="$7" label="$8"
  local actual="$TMP/$label.actual" golden="$TMP/$label.golden"
  jq -S '{status,valid,skill_receipts_count,duplicate_close_reconciled,failures:(.failures|map(.code)),warnings:(.warnings|map(.code))}' "$file" >"$actual"
  jq -n -S \
    --arg status "$status" \
    --argjson valid "$valid" \
    --argjson count "$count" \
    --argjson duplicate "$duplicate" \
    --argjson failures "$failures" \
    --argjson warnings "$warnings" \
    '{status:$status,valid:$valid,skill_receipts_count:$count,duplicate_close_reconciled:$duplicate,failures:$failures,warnings:$warnings}' >"$golden"
  if diff -u "$golden" "$actual" >/dev/null; then
    pass "$label"
  else
    fail "$label"
    diff -u "$golden" "$actual" >&2 || true
  fi
}

write_good() {
  local path="$1" observed="OK_wave2_close_validator_contract_shipped" command="bash fixture-l112"
  jq -n \
    --arg ref "flywheel-close-validator-receipt-contract-2026-05-06" \
    --arg close_key "close-key-1" \
    --arg observed "$observed" \
    --arg command "$command" \
    --arg output_hash "$(sha256_text "$observed")" \
    --arg command_hash "$(sha256_text "$command")" \
    '{
      status:"DONE",
      ref_id:$ref,
      task_id:"wave2-close-validator-receipt-contract-2026-05-06",
      close_identity_key:$close_key,
      dedupe_policy:"latest-row-by-ref_id-event",
      skill_receipts:[{
        schema_version:"skill-receipt/v1",
        receipt_identity_key:"skill-receipt:fixture",
        skill:"socraticode",
        resolved_to:"socraticode",
        source:"local-skill-root",
        path:"/Users/josh/.claude/skills/socraticode/SKILL.md",
        sha:"sha256:aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa",
        version:"2026-05-06",
        freshness_status:"fresh",
        route_allowed:true,
        checked_at:"2026-05-06T16:00:00Z",
        action_taken:"applied",
        policy_version:"close-validator-receipt-contract/v1",
        credential_touch:false,
        secret_value_allowed:false,
        safe_wrapper:"n/a"
      }],
      l112:{command:$command,command_hash:$command_hash,observed:$observed,expected:$observed,output_hash:$output_hash,timeout_sec:5400},
      evidence:[{type:"path",value:".flywheel/doctrine/close-validator-receipt-contract.md"},{type:"log_excerpt",value:"RESULT pass=9 fail=0 [SCRUBBED:github_token]"}]
    }' >"$path"
}

bash -n "$SCRIPT" && pass "probe_syntax" || fail "probe_syntax"
[[ "$(rg -c '^## ' "$CONTRACT")" == "9" ]] && pass "contract_has_9_sections" || fail "contract_has_9_sections"
"$SCRIPT" --help >/dev/null && pass "help_exits" || fail "help_exits"
"$SCRIPT" --info --json | jq -e '(.canonical_cli_flags | length) == 5 and (.canonical_cli_flags | index("--quiet"))' >/dev/null && pass "info_lists_canonical_verbs" || fail "info_lists_canonical_verbs"
"$SCRIPT" --examples --json | jq -e '(.examples | length) >= 3' >/dev/null && pass "examples_json" || fail "examples_json"

good="$TMP/good.json"
write_good "$good"
"$SCRIPT" --quiet --callback-file "$good" >/dev/null && pass "quiet_passes" || fail "quiet_passes"

read -r out rc < <(run_probe compliant "$good")
[[ "$rc" == "0" ]] && pass "compliant_rc" || fail "compliant_rc"
assert_golden "$out" "pass" true 1 false '[]' '[]' "golden_compliant_pass"

missing="$TMP/missing-skills.json"
jq 'del(.skill_receipts)' "$good" >"$missing"
read -r out rc < <(run_probe missing_skills "$missing")
[[ "$rc" == "1" ]] && pass "missing_skill_receipts_rc" || fail "missing_skill_receipts_rc"
assert_golden "$out" "fail" false 0 false '["missing_skill_receipts"]' '[]' "golden_missing_skill_receipts"

stale="$TMP/stale-skill.json"
jq '.skill_receipts[0].freshness_status="stale"' "$good" >"$stale"
read -r out rc < <(run_probe stale_skill "$stale")
[[ "$rc" == "1" ]] && pass "stale_skill_rc" || fail "stale_skill_rc"
assert_golden "$out" "fail" false 1 false '["stale_or_blocked_skill_route"]' '[]' "golden_stale_skill"

secret="$TMP/secret.json"
jq '.evidence[1].value="Authorization: Bearer abcdefghijklmnopqrstuvwxyz123456"' "$good" >"$secret"
read -r out rc < <(run_probe secret_value "$secret")
[[ "$rc" == "1" ]] && pass "secret_value_rc" || fail "secret_value_rc"
assert_golden "$out" "fail" false 1 false '["secret_value_present"]' '[]' "golden_secret_value"

ledger="$TMP/close-ledger.jsonl"
printf '%s\n' '{"event":"close","ref_id":"flywheel-close-validator-receipt-contract-2026-05-06","close_identity_key":"close-key-1"}' >"$ledger"
duplicate="$TMP/duplicate.json"
jq '.previous_close_row=".beads/issues.jsonl#L1"' "$good" >"$duplicate"
read -r out rc < <(run_probe duplicate_case "$duplicate" "$ledger")
[[ "$rc" == "0" ]] && pass "duplicate_reconciled_rc" || fail "duplicate_reconciled_rc"
assert_golden "$out" "duplicate_reconciled" true 1 true '[]' '["duplicate_close_reconciled"]' "golden_duplicate_reconciled"

l112_bad="$TMP/l112-bad.json"
jq '.l112.output_hash="sha256:bad"' "$good" >"$l112_bad"
read -r out rc < <(run_probe l112_bad "$l112_bad")
[[ "$rc" == "1" ]] && pass "l112_hash_mismatch_rc" || fail "l112_hash_mismatch_rc"
assert_golden "$out" "fail" false 1 false '["l112_output_hash_mismatch"]' '[]' "golden_l112_hash_mismatch"

log_bad="$TMP/log-bad.json"
jq '.evidence[1].value="build log token=abcdefghijklmnopqrstuvwxyz1234567890"' "$good" >"$log_bad"
read -r out rc < <(run_probe log_bad "$log_bad")
[[ "$rc" == "1" ]] && pass "unsanitized_log_rc" || fail "unsanitized_log_rc"
assert_golden "$out" "fail" false 1 false '["secret_value_present"]' '[]' "golden_unsanitized_log"

text="$TMP/text.json"
"$SCRIPT" --callback-text "DONE wave2 evidence=/tmp/x.md" --json >"$text" && text_rc=0 || text_rc=$?
[[ "$text_rc" == "1" ]] && pass "done_text_requires_structured_receipt" || fail "done_text_requires_structured_receipt"
assert_jq "$text" '(.failures | map(.code) | index("structured_receipt_required"))' "done_text_failure_code"

printf 'RESULT pass=%s fail=%s\n' "$pass_count" "$fail_count"
[[ "$pass_count" -ge 18 && "$fail_count" == "0" ]]
