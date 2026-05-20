#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd -P)"
HOOK="${SLB_HOOK:-/Users/josh/.claude/hooks/PreToolUse-bash-slb.sh}"
ADD="$ROOT/.flywheel/scripts/slb-recipe-add.sh"
TAIL="$ROOT/.flywheel/scripts/slb-execution-audit-tail.sh"
TMP_ROOT="$(mktemp -d "${TMPDIR:-/tmp}/slb-smoke.XXXXXX")"
trap 'rm -rf "$TMP_ROOT"' EXIT

PASS=0
FAIL=0

record_pass() {
  PASS=$((PASS + 1))
  printf 'ok %d - %s\n' "$PASS" "$1"
}

record_fail() {
  FAIL=$((FAIL + 1))
  printf 'not ok %d - %s\n' "$((PASS + FAIL))" "$1" >&2
}

assert_jq() {
  local input="$1"
  local filter="$2"
  local label="$3"
  if printf '%s' "$input" | jq -e "$filter" >/dev/null; then
    record_pass "$label"
  else
    record_fail "$label"
    printf '%s\n' "$input" >&2
  fi
}

assert_file() {
  local path="$1"
  local label="$2"
  if [ -s "$path" ]; then
    record_pass "$label"
  else
    record_fail "$label"
  fi
}

input_for() {
  jq -nc --arg cwd "$TMP_ROOT/repo" --arg command "$1" '{tool_name:"Bash",cwd:$cwd,tool_input:{command:$command}}'
}

run_hook() {
  local command_json="$1"
  printf '%s' "$command_json" | \
    TMPDIR="$TMP_ROOT/tmp" \
    SLB_RECIPES_FILE="$RECIPES" \
    SLB_AUDIT_LOG="$AUDIT" \
    SLB_SNAPSHOT_DIR="$SNAPSHOTS" \
    SLB_EXISTING_DCG="$DCG_STUB" \
    "$HOOK"
}

mkdir -p "$TMP_ROOT/tmp" "$TMP_ROOT/repo" "$TMP_ROOT/state" "$TMP_ROOT/snapshots"
git -C "$TMP_ROOT/repo" init -q
RECIPES="$TMP_ROOT/slb-recipes.json"
AUDIT="$TMP_ROOT/state/slb-execution-audit.jsonl"
SNAPSHOTS="$TMP_ROOT/snapshots"
DCG_STUB="$TMP_ROOT/dcg-stub"
MARKER="$TMP_ROOT/marker"
STUB_LOG="$TMP_ROOT/dcg-stub.log"
# shellcheck disable=SC2016
LITERAL_TMPDIR='$TMPDIR'

cat >"$DCG_STUB" <<'SH'
#!/usr/bin/env bash
cat >/dev/null
printf 'stub\n' >>"${DCG_STUB_LOG:?}"
printf '%s\n' '{"stub":"fallthrough"}'
SH
chmod +x "$DCG_STUB"
export DCG_STUB_LOG="$STUB_LOG"
: >"$STUB_LOG"

jq -n --arg marker "$MARKER" '{
  schema_version:"flywheel.slb.recipes.v1",
  recipes:[
    {
      id:"rm-rf-tmpdir",
      description:"fixture tmp cleanup",
      command_pattern:"^rm -rf \\$TMPDIR/[A-Za-z0-9._/-]+$",
      safe_execution_protocol:{
        pre_snapshot:"du -sk <target>",
        execute:"rm -rf <target>",
        post_verify:"test ! -e <target>",
        audit_log_required:true
      },
      fallback_to_prompt_if:["target_resolves_outside_TMPDIR","pre_snapshot_fails","post_verify_fails"]
    },
    {
      id:"verify-fail-fixture",
      description:"fixture verify failure",
      command_pattern:"^echo verify-fail$",
      safe_execution_protocol:{
        pre_snapshot:"printf snapshot",
        execute:"true",
        post_verify:"false",
        audit_log_required:true
      },
      fallback_to_prompt_if:["post_verify_fails"]
    },
    {
      id:"idempotent-fixture",
      description:"fixture idempotent execution",
      command_pattern:"^echo idempotent$",
      safe_execution_protocol:{
        pre_snapshot:"printf snapshot",
        execute:("printf x >> " + ($marker|@sh)),
        post_verify:("test -s " + ($marker|@sh)),
        audit_log_required:true
      },
      fallback_to_prompt_if:["post_verify_fails"]
    }
  ]
}' >"$RECIPES"

mkdir -p "$TMP_ROOT/tmp/slb-target"
printf 'payload\n' >"$TMP_ROOT/tmp/slb-target/file.txt"
before_stub_count="$(wc -l <"$STUB_LOG" | tr -d ' ')"
output="$(run_hook "$(input_for "rm -rf ${LITERAL_TMPDIR}/slb-target")")"
assert_jq "$output" '.hookSpecificOutput.permissionDecision == "allow" and (.hookSpecificOutput.updatedInput.command | contains("SLB already executed"))' "recipe match executes and returns allow no-op"
if [ ! -e "$TMP_ROOT/tmp/slb-target" ]; then
  record_pass "safe execute removed tmp target"
else
  record_fail "safe execute removed tmp target"
fi
after_stub_count="$(wc -l <"$STUB_LOG" | tr -d ' ')"
if [ "$before_stub_count" = "$after_stub_count" ]; then
  record_pass "successful SLB path did not prompt DCG"
else
  record_fail "successful SLB path did not prompt DCG"
fi

output="$(run_hook "$(input_for "rm -rf ${LITERAL_TMPDIR}/slb-missing")")"
assert_jq "$output" '.stub == "fallthrough"' "snapshot failure falls through to DCG"

output="$(run_hook "$(input_for 'echo verify-fail')")"
assert_jq "$output" '.stub == "fallthrough"' "verify failure falls through to DCG"
if jq -e 'select(.recipe_id == "verify-fail-fixture" and .outcome == "verify_failed")' "$AUDIT" >/dev/null; then
  record_pass "verify failure writes audit row"
else
  record_fail "verify failure writes audit row"
fi

output="$(run_hook "$(input_for 'echo harmless')")"
assert_jq "$output" '.stub == "fallthrough"' "no recipe match falls through to DCG"

success_count="$(jq -s '[.[] | select(.outcome == "success")] | length' "$AUDIT")"
failure_count="$(jq -s '[.[] | select(.outcome | test("failed$"))] | length' "$AUDIT")"
if [ "$success_count" -ge 1 ] && [ "$failure_count" -ge 2 ]; then
  record_pass "audit rows written for success and failures"
else
  record_fail "audit rows written for success and failures"
fi

snapshot_path="$(jq -r 'select(.recipe_id == "rm-rf-tmpdir" and .outcome == "success") | .snapshot_path' "$AUDIT" | head -1)"
assert_file "$snapshot_path" "pre-snapshot artifact saved"

output="$(run_hook "$(input_for 'echo idempotent')")"
assert_jq "$output" '.hookSpecificOutput.permissionDecision == "allow"' "idempotent fixture first run allowed"
output="$(run_hook "$(input_for 'echo idempotent')")"
assert_jq "$output" '.hookSpecificOutput.permissionDecision == "allow"' "idempotent fixture second run allowed"
idempotent_rows="$(jq -s '[.[] | select(.recipe_id == "idempotent-fixture" and .outcome == "success")] | length' "$AUDIT")"
marker_bytes="$(wc -c <"$MARKER" | tr -d ' ')"
if [ "$idempotent_rows" = "1" ] && [ "$marker_bytes" = "1" ]; then
  record_pass "idempotent re-run produces no double audit rows or execution"
else
  record_fail "idempotent re-run produces no double audit rows or execution"
fi

ADD_RECIPES="$TMP_ROOT/add-recipes.json"
"$ADD" --recipes-file "$ADD_RECIPES" --id echo-ok --pattern '^echo ok$' \
  --description 'test add' --pre-snapshot 'printf pre' --execute 'printf run' \
  --post-verify 'true' --fallback-if pre_snapshot_fails --apply --json >"$TMP_ROOT/add.json"
"$ADD" --recipes-file "$ADD_RECIPES" --id echo-ok --pattern '^echo ok$' \
  --description 'test add' --pre-snapshot 'printf pre' --execute 'printf run' \
  --post-verify 'true' --fallback-if pre_snapshot_fails --apply --json >/dev/null
assert_jq "$(cat "$TMP_ROOT/add.json")" '.applied == true and .recipe_count == 1' "recipe add validates and writes idempotently"

if "$ADD" --recipes-file "$TMP_ROOT/reject.json" --id bad --pattern '[' \
  --description 'bad' --pre-snapshot true --execute true --post-verify true \
  --fallback-if pre_snapshot_fails --apply >/dev/null 2>&1; then
  record_fail "schema validation rejects malformed recipe regex"
else
  record_pass "schema validation rejects malformed recipe regex"
fi

"$TAIL" --audit-log "$AUDIT" --limit 5 --json >"$TMP_ROOT/tail.json"
assert_jq "$(cat "$TMP_ROOT/tail.json")" '.schema_version == "flywheel.slb.audit_tail.v1" and .status == "ok" and (.rows | length) >= 1' "audit tail JSON envelope parseable"

assert_jq "$output" '.hookSpecificOutput.hookEventName == "PreToolUse"' "hook JSON envelope parseable"

printf 'SUMMARY pass=%s fail=%s\n' "$PASS" "$FAIL"
test "$FAIL" -eq 0
test "$PASS" -ge 12
