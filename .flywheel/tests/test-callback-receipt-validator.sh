#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd -P)"
VALIDATOR="$ROOT/.flywheel/scripts/callback-receipt-validator.sh"
OPENER="$ROOT/.flywheel/scripts/callback-fix-bead-opener.sh"
WRAPPER="/Users/josh/.claude/commands/flywheel/_shared/callback-receipt-validator-wrapper.sh"
SCHEMA="$ROOT/.flywheel/validation-schema/v1/callback-receipt-decision.schema.json"
TMP="$(mktemp -d "${TMPDIR:-/tmp}/callback-receipt-validator.XXXXXX")"
trap 'rm -rf "$TMP"' EXIT

pass_count=0

pass() {
  printf 'PASS %s\n' "$1"
  pass_count=$((pass_count + 1))
}

fail() {
  printf 'FAIL %s\n' "$1" >&2
  exit 1
}

expect_rc() {
  local name="$1" want="$2"
  shift 2
  set +e
  "$@" >"$TMP/$name.out" 2>"$TMP/$name.err"
  local got=$?
  set -e
  [[ "$got" -eq "$want" ]] || {
    printf 'expected rc=%s got=%s for %s\n' "$want" "$got" "$name" >&2
    cat "$TMP/$name.out" >&2 || true
    cat "$TMP/$name.err" >&2 || true
    exit 1
  }
}

assert_jq() {
  local file="$1" expr="$2" label="$3"
  jq -e "$expr" "$file" >/dev/null || {
    jq . "$file" >&2 || cat "$file" >&2
    fail "$label"
  }
  pass "$label"
}

validate_payload() {
  python3 - "$SCHEMA" "$1" <<'PY'
import json
import sys
from pathlib import Path
from jsonschema import Draft202012Validator

schema = json.loads(Path(sys.argv[1]).read_text(encoding="utf-8"))
payload = json.loads(Path(sys.argv[2]).read_text(encoding="utf-8"))
Draft202012Validator(schema).validate(payload)
PY
}

write_dispatch() {
  local file="$1" body="$2" timeout="${3:-5}"
  cat >"$file" <<EOF
# Fixture Dispatch

## L112 verify

\`\`\`bash
$body
\`\`\`

Expected: fixture
Timeout: $timeout
EOF
}

mkdir -p "$TMP/bin" "$TMP/repo/.beads"
git -C "$TMP/repo" init -q
printf '# fixture\n' >"$TMP/repo/README.md"
printf '' >"$TMP/repo/.beads/issues.jsonl"

cat >"$TMP/bin/br" <<'SH'
#!/usr/bin/env bash
set -euo pipefail
printf '%s\n' "$*" >>"${FAKE_BR_LOG:?}"
if [[ "${1:-}" == "create" ]]; then
  printf '{"id":"flywheel-fixmock-%s"}\n' "$(wc -l <"${FAKE_BR_LOG}" | tr -d ' ')"
else
  printf '{}\n'
fi
SH
chmod +x "$TMP/bin/br"
export FAKE_BR_LOG="$TMP/br.log"
touch "$FAKE_BR_LOG"

export CALLBACK_RECEIPT_FIX_BEAD_OPENER="$OPENER"
export CALLBACK_RECEIPT_VALIDATOR_LEDGER="$TMP/validator-ledger.jsonl"
export CALLBACK_FIX_BEAD_LEDGER="$TMP/fix-ledger.jsonl"
export CALLBACK_FIX_BEAD_BR_BIN="$TMP/bin/br"

write_dispatch "$TMP/pass.md" "printf 'OK_fixture_pass\n'"
write_dispatch "$TMP/fail.md" "printf 'NO_fixture_fail\n'; exit 7"
write_dispatch "$TMP/mismatch.md" "printf 'ACTUAL_fixture_mismatch\n'"

bash -n "$VALIDATOR" && pass "validator_shell_syntax"
bash -n "$OPENER" && pass "opener_shell_syntax"
bash -n "$WRAPPER" && pass "wrapper_shell_syntax"
jq empty "$SCHEMA" && pass "schema_json_parses"
"$VALIDATOR" --help >/dev/null && "$VALIDATOR" --examples >/dev/null && pass "validator_help_examples"
"$OPENER" --help >/dev/null && "$OPENER" --examples >/dev/null && pass "opener_help_examples"

expect_rc pass 0 "$VALIDATOR" check --callback-text "DONE task-pass bead=flywheel-parent evidence=$TMP/evidence.md l112_observed=OK_fixture_pass" --dispatch-file "$TMP/pass.md" --repo "$TMP/repo" --json
assert_jq "$TMP/pass.out" '.decision == "PASS" and .reason == "pass" and .actual_l112 == "OK_fixture_pass"' "valid_callback_l112_pass_allows"

expect_rc fail 1 "$VALIDATOR" check --callback-text "DONE task-fail bead=flywheel-parent evidence=$TMP/evidence.md l112_observed=OK_fixture_fail" --dispatch-file "$TMP/fail.md" --repo "$TMP/repo" --json
assert_jq "$TMP/fail.out" '.decision == "REFUSE" and .reason == "l112_verify_failed" and (.fix_bead_id | startswith("flywheel-fixmock-"))' "l112_verify_failure_refuses_and_files_fix"

expect_rc mismatch 1 "$VALIDATOR" check --callback-text "DONE task-mismatch bead=flywheel-parent evidence=$TMP/evidence.md l112_observed=OK_reported" --dispatch-file "$TMP/mismatch.md" --repo "$TMP/repo" --json
assert_jq "$TMP/mismatch.out" '.decision == "REFUSE" and .reason == "l112_output_mismatch" and .actual_l112 == "ACTUAL_fixture_mismatch"' "l112_output_mismatch_refuses"

expect_rc missing 1 "$VALIDATOR" check --callback-text "DONE task-missing bead=flywheel-parent evidence=$TMP/evidence.md l112_observed=OK_missing" --dispatch-file "$TMP/no-such-dispatch.md" --repo "$TMP/repo" --json
assert_jq "$TMP/missing.out" '.decision == "REFUSE" and .reason == "dispatch_file_missing"' "missing_dispatch_refuses"

expect_rc malformed 2 "$VALIDATOR" check --callback-text "BLOCKED malformed l112_observed=OK" --dispatch-file "$TMP/pass.md" --repo "$TMP/repo" --json
assert_jq "$TMP/malformed.out" '.decision == "UNVERIFIABLE" and .reason == "callback_malformed" and .exit_code == 2' "malformed_callback_fail_open_exit_2"

expect_rc no_task_dispatch 1 "$VALIDATOR" check --callback-text "DONE task-no-such bead=flywheel-parent evidence=$TMP/evidence.md l112_observed=OK" --dispatch-file "$TMP/dispatch_task-no-such.md" --repo "$TMP/repo" --json
assert_jq "$TMP/no_task_dispatch.out" '.decision == "REFUSE" and .reason == "dispatch_file_missing"' "nonexistent_task_dispatch_refuses"

for file in "$TMP/pass.out" "$TMP/fail.out" "$TMP/mismatch.out" "$TMP/missing.out" "$TMP/malformed.out" "$TMP/no_task_dispatch.out"; do
  validate_payload "$file"
done
pass "json_shape_validates_against_schema"

ledger_count="$(wc -l <"$CALLBACK_RECEIPT_VALIDATOR_LEDGER" | tr -d ' ')"
[[ "$ledger_count" -eq 6 ]] || fail "ledger row count expected 6 got $ledger_count"
jq empty "$CALLBACK_RECEIPT_VALIDATOR_LEDGER" && pass "ledger_row_appended_on_every_decision"

before_br_lines="$(wc -l <"$FAKE_BR_LOG" | tr -d ' ')"
"$OPENER" --repo "$TMP/repo" --task-id idem-task --bead flywheel-parent --reason l112_output_mismatch --expected OK --actual NO --json >"$TMP/idem1.json"
"$OPENER" --repo "$TMP/repo" --task-id idem-task --bead flywheel-parent --reason l112_output_mismatch --expected OK --actual NO --json >"$TMP/idem2.json"
after_br_lines="$(wc -l <"$FAKE_BR_LOG" | tr -d ' ')"
[[ "$((after_br_lines - before_br_lines))" -eq 1 ]] || fail "idempotent opener called br more than once"
assert_jq "$TMP/idem2.json" '.action == "reused" and .fix_bead_id == "flywheel-fixmock-'$after_br_lines'"' "fix_bead_opener_idempotent"

expect_rc wrapper_pass 0 env CALLBACK_RECEIPT_DISPATCH_FILE="$TMP/pass.md" CALLBACK_RECEIPT_VALIDATOR_LEDGER="$TMP/wrapper-ledger.jsonl" CALLBACK_FIX_BEAD_LEDGER="$TMP/wrapper-fix-ledger.jsonl" CALLBACK_FIX_BEAD_BR_BIN="$TMP/bin/br" "$WRAPPER" --repo "$TMP/repo" <<<"DONE task-wrapper bead=flywheel-parent evidence=$TMP/evidence.md l112_observed=OK_fixture_pass"
pass "wrapper_callable_pass_silent"

printf 'PASS cases=9 assertions=%s failures=0\n' "$pass_count"
