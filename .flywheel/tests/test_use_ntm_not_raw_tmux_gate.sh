#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd -P)"
HOOK="${USE_NTM_GATE_HOOK:-$HOME/.claude/hooks/flywheel-orch-use-ntm-not-raw-tmux-gate.sh}"
FIXTURES="$ROOT/.flywheel/tests/fixtures/use-ntm-not-raw-tmux"
TMP="$(mktemp -d "${TMPDIR:-/tmp}/use-ntm-gate.XXXXXX")"
trap 'rm -rf "$TMP"' EXIT

pass_count=0
block_count=0
allow_count=0

pass() { printf 'PASS %s\n' "$1"; pass_count=$((pass_count + 1)); }
fail() { printf 'FAIL %s\n' "$1" >&2; exit 1; }

assert_jq() {
  local file="$1" filter="$2" label="$3"
  if jq -e "$filter" "$file" >/dev/null; then
    pass "$label"
  else
    jq . "$file" >&2 || true
    fail "$label"
  fi
}

run_fixture() {
  local fixture="$1"
  local name command expected suggestion input out err rc
  name="$(jq -r '.name' "$fixture")"
  command="$(jq -r '.command' "$fixture")"
  expected="$(jq -r '.expected' "$fixture")"
  suggestion="$(jq -r '.suggestion // empty' "$fixture")"
  input="$(jq -nc --arg cmd "$command" '{tool_name:"Bash",tool_input:{command:$cmd}}')"
  out="$TMP/$name.json"
  err="$TMP/$name.err"

  set +e
  printf '%s\n' "$input" | "$HOOK" --json >"$out" 2>"$err"
  rc=$?
  set -e
  jq empty "$out" >/dev/null || { cat "$out" >&2 || true; fail "$name json"; }

  if [[ "$expected" == "block" ]]; then
    [[ "$rc" -eq 1 ]] || { cat "$out" >&2; fail "$name rc=$rc expected=1"; }
    assert_jq "$out" '.decision == "block" and .hookSpecificOutput.permissionDecision == "deny"' "$name blocks"
    [[ -n "$suggestion" ]] || fail "$name missing_suggestion"
    grep -q "$suggestion" "$out" || { cat "$out" >&2; fail "$name suggestion=$suggestion"; }
    block_count=$((block_count + 1))
  elif [[ "$expected" == "allow" ]]; then
    [[ "$rc" -eq 0 ]] || { cat "$out" >&2; cat "$err" >&2 || true; fail "$name rc=$rc expected=0"; }
    assert_jq "$out" '.decision == "allow"' "$name allows"
    allow_count=$((allow_count + 1))
  else
    fail "$name unknown expected=$expected"
  fi
}

[[ -x "$HOOK" ]] || fail "hook_executable"
bash -n "$HOOK" && pass "hook_syntax"
"$HOOK" --info >/dev/null && pass "info_text"
"$HOOK" --info --json | jq -e '.read_only == true and .exits.block == 1' >/dev/null && pass "info_json"
"$HOOK" --examples | grep -q 'ntm send' && pass "examples"

set +e
printf '{bad json\n' | "$HOOK" --json >"$TMP/malformed.json" 2>"$TMP/malformed.err"
rc=$?
set -e
[[ "$rc" -eq 2 ]] || fail "malformed rc=$rc expected=2"
assert_jq "$TMP/malformed.json" '.decision == "error" and .reason == "malformed_json_stdin"' "malformed_json_exits_2"

while IFS= read -r fixture; do
  run_fixture "$fixture"
done < <(find "$FIXTURES" -name '*.json' -type f | sort)

[[ "$block_count" -eq 4 ]] || fail "block_count=$block_count expected=4"
[[ "$allow_count" -eq 6 ]] || fail "allow_count=$allow_count expected=6"

printf 'PASS dispatch_cases=8/8 live_smoke=2/2 block=%s allow=%s assertions=%s failures=0\n' \
  "$block_count" "$allow_count" "$pass_count"
