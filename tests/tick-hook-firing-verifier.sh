#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd -P)"
SCRIPT="$ROOT/.flywheel/scripts/tick-hook-firing-verifier.sh"
TMP="$(mktemp -d "${TMPDIR:-/tmp}/tick-hook-firing-verifier.XXXXXX")"
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
    jq . "$file" >&2 || cat "$file" >&2
    fail "$label"
  fi
}

cat >"$TMP/jsonl-append.sh" <<'EOF'
#!/usr/bin/env bash
fw_jsonl_append_validated() {
  local path="$1" row="$2"
  [[ -n "$row" ]] || return 1
  jq -e 'type == "object"' >/dev/null <<<"$row" || return 1
  mkdir -p "$(dirname "$path")"
  jq -c '.' <<<"$row" >>"$path"
}
EOF
chmod +x "$TMP/jsonl-append.sh"

recent_ledger="$TMP/recent-ledger.jsonl"
stale_ledger="$TMP/stale-ledger.jsonl"
missing_ledger="$TMP/missing-ledger.jsonl"
suspicious_ledger="$TMP/suspicious-ledger.jsonl"
audit_ledger="$TMP/audit.jsonl"
fuckup_log="$TMP/fuckup.jsonl"
contract_ledger="$TMP/substrate-loop-contract.jsonl"
spec_file="$TMP/primitives.json"

jq -nc '{ts:"2026-05-05T04:55:00Z",event:"recent"}' >>"$recent_ledger"
jq -nc '{ts:"2026-05-03T04:55:00Z",event:"stale"}' >>"$stale_ledger"

cat >"$TMP/doctor-recent.sh" <<'EOF'
#!/usr/bin/env bash
printf '{"fixture_last_fired_ts":"2026-05-05T04:58:00Z"}\n'
EOF
chmod +x "$TMP/doctor-recent.sh"

jq -n \
  --arg recent "$recent_ledger" \
  --arg stale "$stale_ledger" \
  --arg missing "$missing_ledger" \
  --arg suspicious "$suspicious_ledger" \
  --arg doctor_cmd "bash $TMP/doctor-recent.sh" \
  '[
    {name:"fixture-recent-ledger", ledger_path:$recent},
    {name:"fixture-stale-ledger", ledger_path:$stale},
    {name:"fixture-missing-ledger", ledger_path:$missing},
    {name:"fixture-doctor-recent-no-ledger", ledger_path:$suspicious, doctor_command:$doctor_cmd, doctor_last_fired_field:"fixture_last_fired_ts"}
  ]' >"$spec_file"

export FLYWHEEL_JSONL_APPEND_LIB="$TMP/jsonl-append.sh"
export TICK_HOOK_FIRING_AUDIT_LEDGER="$audit_ledger"
export TICK_HOOK_FIRING_FUCKUP_LOG="$fuckup_log"
export TICK_HOOK_FIRING_CONTRACT_LEDGER="$contract_ledger"
export TICK_HOOK_FIRING_NOW="2026-05-05T05:00:00Z"

bash -n "$SCRIPT" && pass "script_syntax"

set +e
"$SCRIPT" --doctor --json --primitives-file "$spec_file" >"$TMP/doctor.json"
doctor_rc=$?
set -e
test "$doctor_rc" = "1" || fail "doctor_rc_error_on_invisibly_broken"
assert_jq "$TMP/doctor.json" '.tick_hook_primitives_audited == 4 and .tick_hook_primitives_firing == 1 and .tick_hook_primitives_invisibly_broken == 1 and .tick_hook_primitives_stale == 1 and .tick_hook_primitives_suspicious == 1' "doctor_counts_4_classes"
assert_jq "$TMP/doctor.json" '.primitive_rows | map({(.primitive): .classification}) | add == {"fixture-recent-ledger":"firing","fixture-stale-ledger":"stale","fixture-missing-ledger":"invisibly_broken","fixture-doctor-recent-no-ledger":"suspicious"}' "classifications_4_of_4"
assert_jq "$TMP/doctor.json" '.tick_hook_primitives_invisibly_broken_names == ["fixture-missing-ledger"]' "broken_names_only_missing"

set +e
"$SCRIPT" --doctor --apply --json --primitives-file "$spec_file" >"$TMP/doctor-apply.json"
apply_rc=$?
set -e
test "$apply_rc" = "1" || fail "apply_rc_preserves_error_status"
assert_jq "$TMP/doctor-apply.json" '.audit_rows_written == 4 and .dry_run == false and .apply == true' "audit_rows_written_4"
test "$(wc -l <"$audit_ledger" | tr -d ' ')" = "4" || fail "audit_ledger_row_count"
test "$(wc -l <"$fuckup_log" | tr -d ' ')" = "2" || fail "fuckup_row_count_stale_and_broken"
jq -e 'select(.primitive == "fixture-stale-ledger" and .class == "tick-hook-not-firing")' "$fuckup_log" >/dev/null || fail "stale_fuckup_logged"
jq -e 'select(.primitive == "fixture-missing-ledger" and .class == "tick-hook-not-firing")' "$fuckup_log" >/dev/null || fail "broken_fuckup_logged"
pass "fuckup_rows_for_stale_and_broken"

"$SCRIPT" repair --scope substrate-contract --apply --json >"$TMP/contract.json"
assert_jq "$TMP/contract.json" '.status == "pass" and .apply == true and (.actual_actions | length) == 1' "contract_repair_applied"
jq -e 'select(.primitive_name == "tick-hook-firing-verifier" and .measurement_field == "tick_hook_primitives_invisibly_broken")' "$contract_ledger" >/dev/null || fail "contract_self_row"
pass "contract_self_row"

"$SCRIPT" schema doctor --json >"$TMP/schema-doctor.json"
assert_jq "$TMP/schema-doctor.json" '.schema_version == "tick-hook-firing.doctor.v1" and (.required | length) == 4' "schema_doctor_required_fields"

printf 'OK tick-hook-firing-verifier test_fixture_pass=4/4 passes=%s failures=%s\n' "$pass_count" "$fail_count"
[[ "$fail_count" -eq 0 ]]
