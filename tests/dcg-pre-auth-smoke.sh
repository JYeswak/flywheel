#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
HOOK="${DCG_PRE_AUTH_HOOK:-/Users/josh/.claude/hooks/pretooluse-bash-dcg-with-pre-auth.sh}"
HELPER="$ROOT/.flywheel/scripts/dcg-pre-auth-add-scope.sh"
TMP_ROOT="$(mktemp -d)"
trap 'rm -rf "$TMP_ROOT"' EXIT

PASS=0
FAIL=0

record_pass() {
  PASS=$((PASS + 1))
  printf 'ok - %s\n' "$1"
}

record_fail() {
  FAIL=$((FAIL + 1))
  printf 'not ok - %s\n' "$1"
}

assert_jq() {
  local input="$1"
  local filter="$2"
  local label="$3"
  if printf '%s' "$input" | jq -e "$filter" >/dev/null; then
    record_pass "$label"
  else
    record_fail "$label"
  fi
}

assert_eq() {
  local actual="$1"
  local expected="$2"
  local label="$3"
  if [ "$actual" = "$expected" ]; then
    record_pass "$label"
  else
    record_fail "$label"
  fi
}

input_for() {
  jq -nc --arg command "$1" '{tool_name:"Bash",tool_input:{command:$command}}'
}

input_with_context() {
  jq -nc --arg command "$1" --arg context "$2" '{tool_name:"Bash",tool_input:{command:$command},dcg_pre_auth_context:[$context]}'
}

run_hook() {
  local scopes_file="$1"
  local audit_log="$2"
  local command_json="$3"
  printf '%s' "$command_json" | \
    DCG_PRE_AUTH_SCOPES_FILE="$scopes_file" \
    DCG_PRE_AUTH_AUDIT_LOG="$audit_log" \
    DCG_PRE_AUTH_EXISTING_DCG="$TMP_ROOT/dcg-stub" \
    "$HOOK"
}

write_scopes() {
  local path="$1"
  cat > "$path" <<'JSON'
{
  "schema_version": "dcg-pre-authorized-scopes/v1",
  "scopes": [
    {
      "id": "always-hit",
      "command_pattern": "^rm -rf \\$TMPDIR/.+",
      "rationale": "test tmp cleanup",
      "auto_approve": "always",
      "audit_log": true
    },
    {
      "id": "context-hit",
      "command_pattern": "^git branch -D scratch-[0-9a-f]{7}$",
      "rationale": "test context gate",
      "auto_approve": "always",
      "requires_context": "pr_merged_recently",
      "audit_log": true
    }
  ]
}
JSON
}

cat > "$TMP_ROOT/dcg-stub" <<'SH'
#!/usr/bin/env bash
cat >/dev/null
printf '%s\n' '{"stub":"fallthrough"}'
SH
chmod +x "$TMP_ROOT/dcg-stub"

EMPTY_SCOPES="$TMP_ROOT/empty.json"
SCOPES="$TMP_ROOT/scopes.json"
AUDIT="$TMP_ROOT/audit.jsonl"
ADD_SCOPES="$TMP_ROOT/add-scopes.json"
printf '%s\n' '{"schema_version":"dcg-pre-authorized-scopes/v1","scopes":[]}' > "$EMPTY_SCOPES"
write_scopes "$SCOPES"

output="$(run_hook "$EMPTY_SCOPES" "$AUDIT" "$(input_for 'git reset --hard HEAD')")"
assert_jq "$output" '.stub == "fallthrough"' "empty scopes fall through"

output="$(run_hook "$SCOPES" "$AUDIT" "$(input_for "rm -rf \$TMPDIR/flywheel-stale-test")")"
assert_jq "$output" '.hookSpecificOutput.permissionDecision == "allow"' "always auto-approve match allows"

output="$(run_hook "$SCOPES" "$AUDIT" "$(input_for 'git branch -D scratch-deadbee')")"
assert_jq "$output" '.stub == "fallthrough"' "context-unsatisfied match falls through"

output="$(run_hook "$SCOPES" "$AUDIT" "$(input_with_context 'git branch -D scratch-deadbee' 'pr_merged_recently')")"
assert_jq "$output" '.hookSpecificOutput.permissionDecision == "allow"' "context-satisfied match allows"

output="$(run_hook "$SCOPES" "$AUDIT" "$(input_for 'echo harmless')")"
assert_jq "$output" '.stub == "fallthrough"' "nonmatch falls through"

audit_count="$(grep -c '"outcome":"auto_approved"' "$AUDIT")"
if [ "$audit_count" -ge 2 ]; then
  record_pass "auto-approved commands write audit rows"
else
  record_fail "auto-approved commands write audit rows"
fi

printf '%s\n' '{not-json' > "$TMP_ROOT/invalid.json"
output="$(run_hook "$TMP_ROOT/invalid.json" "$AUDIT" "$(input_for "rm -rf \$TMPDIR/flywheel-stale-test")")"
assert_jq "$output" '.stub == "fallthrough"' "invalid scopes JSON falls through"

"$HELPER" --scopes-file "$ADD_SCOPES" --pattern '^echo ok$' --rationale 'test scope' --auto-approve always --apply --json >/dev/null
"$HELPER" --scopes-file "$ADD_SCOPES" --pattern '^echo ok$' --rationale 'test scope' --auto-approve always --apply --json >/dev/null
scope_count="$(jq '.scopes | length' "$ADD_SCOPES")"
assert_eq "$scope_count" "1" "add-scope apply is idempotent"

if "$HELPER" --scopes-file "$TMP_ROOT/reject.json" --pattern '[' --rationale 'bad regex' --auto-approve always --apply >/dev/null 2>&1; then
  record_fail "schema rejects malformed regex"
else
  record_pass "schema rejects malformed regex"
fi

if "$HELPER" --scopes-file "$TMP_ROOT/reject.json" --pattern '^echo nope$' --rationale 'bad auto' --auto-approve maybe --apply >/dev/null 2>&1; then
  record_fail "schema rejects malformed auto-approve"
else
  record_pass "schema rejects malformed auto-approve"
fi

printf 'SUMMARY pass=%s fail=%s\n' "$PASS" "$FAIL"
test "$FAIL" -eq 0
test "$PASS" -ge 8
