#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd -P)"
BIN="$ROOT/.flywheel/scripts/callback-envelope-schema-validator.sh"
CLOSE_BIN="$ROOT/.flywheel/scripts/br-close-with-gate.sh"
TMP="$(mktemp -d /tmp/callback-envelope-schema-test.XXXXXX)"
trap 'rm -rf "$TMP"' EXIT

export CALLBACK_ENVELOPE_SCHEMA_LEDGER="$TMP/callback-envelope-schema.jsonl"
export CALLBACK_ENVELOPE_SCHEMA_FUCKUP_LOG="$TMP/fuckup-log.jsonl"
export CALLBACK_ENVELOPE_SCHEMA_CONTRACT_LEDGER="$TMP/substrate-loop-contract.jsonl"
export CALLBACK_ENVELOPE_SCHEMA_DISPATCH_LOG="$TMP/dispatch-log.jsonl"

fixture_pass=0

full_env='DONE b56-fixture quality_bar_passed=yes composite_score=9.6 jeff_score=9.4 donella_score=9.5 joshua_score=9.6 rust/python_clean=n/a cli_canonical=n/a readme_quality=n/a'
missing_donella='DONE b56-fixture quality_bar_passed=yes composite_score=9.6 jeff_score=9.4 joshua_score=9.6 rust/python_clean=n/a cli_canonical=yes readme_quality=n/a'
low_composite='DONE b56-fixture quality_bar_passed=yes composite_score=8.5 jeff_score=9.4 donella_score=9.5 joshua_score=9.6 rust/python_clean=n/a cli_canonical=yes readme_quality=n/a'
low_joshua='DONE b56-fixture quality_bar_passed=yes composite_score=9.6 jeff_score=9.4 donella_score=9.5 joshua_score=8.5 rust/python_clean=n/a cli_canonical=yes readme_quality=n/a'
compact_env='DONE b56-fixture quality_bar_passed=yes composite=9.7 jeff_score=9.7 donella_score=9.6 joshua_score=9.5 rust_clean=yes/python=n/a/cli=yes/readme=n/a'

assert_pass() {
  local name="$1" envelope="$2" out
  out="$("$BIN" validate envelope --callback-envelope "$envelope" --json)"
  jq -e '.valid == true and .status == "pass"' >/dev/null <<<"$out"
  fixture_pass=$((fixture_pass + 1))
  printf 'PASS fixture=%s\n' "$name"
}

assert_fail_has() {
  local name="$1" envelope="$2" jq_expr="$3" out rc
  set +e
  out="$("$BIN" validate envelope --callback-envelope "$envelope" --json)"
  rc=$?
  set -e
  [[ "$rc" -ne 0 ]]
  jq -e "$jq_expr" >/dev/null <<<"$out"
  fixture_pass=$((fixture_pass + 1))
  printf 'PASS fixture=%s\n' "$name"
}

assert_pass full "$full_env"
assert_fail_has missing_donella "$missing_donella" '.missing_fields | index("donella_score")'
assert_fail_has low_composite "$low_composite" '.violations | index("composite_below_quality_bar") and index("quality_bar_passed_composite_mismatch")'
assert_fail_has low_joshua "$low_joshua" '.violations | index("joshua_score_below_9")'
assert_pass compact "$compact_env"

rm -f "$CALLBACK_ENVELOPE_SCHEMA_LEDGER"
"$BIN" validate envelope --callback-envelope "$full_env" --json >/dev/null
[[ ! -s "$CALLBACK_ENVELOPE_SCHEMA_LEDGER" ]]
"$BIN" validate envelope --callback-envelope "$full_env" --apply --json | jq -e '.ledger_written == true and .dry_run == false' >/dev/null
[[ "$(wc -l <"$CALLBACK_ENVELOPE_SCHEMA_LEDGER" | tr -d ' ')" == "1" ]]

"$BIN" repair --scope substrate-contract --apply --json | jq -e '.actual_actions[] | select(.action=="appended_substrate_loop_contract_self_row")' >/dev/null
jq -e 'select(.primitive_name=="callback-envelope-schema-validator" and .schema_version=="substrate-loop-contract.v1")' "$CALLBACK_ENVELOPE_SCHEMA_CONTRACT_LEDGER" >/dev/null

printf '{"task_id":"fixture-callback","callback_received_at":"%s","callback_grade":"9.6","bead_closed":"flywheel-fixture"}\n' "$(date -u +%Y-%m-%dT%H:%M:%SZ)" >"$CALLBACK_ENVELOPE_SCHEMA_DISPATCH_LOG"
set +e
doctor_out="$("$BIN" --doctor --json)"
doctor_rc=$?
set -e
[[ "$doctor_rc" -ne 2 ]]
jq -e 'has("callback_envelope_schema_compliance_24h_pct") and has("callback_envelope_schema_violations_24h") and has("callback_envelope_schema_top_missing_field")' >/dev/null <<<"$doctor_out"

bad_file="$TMP/bad-envelope.txt"
printf '%s\n' "$missing_donella" >"$bad_file"
fake_gate="$TMP/auto-l112-gate.sh"
fake_br="$TMP/br"
br_log="$TMP/br.log"
cat >"$fake_gate" <<'EOF'
#!/usr/bin/env bash
jq -nc '{schema_version:"auto-l112-gate/v1",status:"pass"}'
EOF
cat >"$fake_br" <<EOF
#!/usr/bin/env bash
echo called >"$br_log"
jq -nc '{id:"flywheel-fixture",status:"closed"}'
EOF
chmod +x "$fake_gate" "$fake_br"
set +e
AUTO_L112_GATE_BIN="$fake_gate" CALLBACK_ENVELOPE_SCHEMA_VALIDATOR_BIN="$BIN" AUTO_L112_GATE_BR_BIN="$fake_br" \
  "$CLOSE_BIN" --bead flywheel-fixture --task-id fixture --callback-envelope-file "$bad_file" --json >/tmp/callback-envelope-schema-close-test.out
close_rc=$?
set -e
[[ "$close_rc" -ne 0 ]]
jq -e '.failure_class == "callback_envelope_schema_failed"' /tmp/callback-envelope-schema-close-test.out >/dev/null
[[ ! -e "$br_log" ]]

printf 'OK callback-envelope-schema-validator test_fixture_pass=%s/5\n' "$fixture_pass"
