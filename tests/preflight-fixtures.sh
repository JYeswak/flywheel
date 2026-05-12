#!/usr/bin/env bash
set -uo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd -P)"
SCRIPT="$ROOT/scripts/preflight.sh"
FIXTURES="$ROOT/fixtures/preflight"
PASS=0
FAIL=0

pass() { PASS=$((PASS + 1)); printf 'PASS %s\n' "$1"; }
fail() { FAIL=$((FAIL + 1)); printf 'FAIL %s\n' "$1" >&2; }

run_capture() {
  local out="$1" err="$2"
  shift 2
  set +e
  "$@" >"$out" 2>"$err"
  local rc=$?
  set +e
  return "$rc"
}

if bash -n "$SCRIPT" 2>/dev/null; then pass "syntax"; else fail "syntax"; fi

if "$SCRIPT" --schema | jq -e '.schema_version == "flywheel.preflight.v0" and .command == "schema"' >/dev/null; then
  pass "schema"
else
  fail "schema"
fi

for fixture in fresh partial existing reduced misconfigured; do
  if "$SCRIPT" validate --fixture "fixtures/preflight/${fixture}.json" --json \
    | jq -e '.command == "validate" and .status == "pass"' >/dev/null; then
    pass "validate ${fixture}"
  else
    fail "validate ${fixture}"
  fi
done

TMP="$(mktemp -d "${TMPDIR:-/tmp}/flywheel-preflight-test.XXXXXX")"
trap 'rm -rf "$TMP"' EXIT

check_mode() {
  local fixture="$1" expected_mode="$2" expected_exit="$3" out="$TMP/${fixture}.out" err="$TMP/${fixture}.err" rc
  run_capture "$out" "$err" "$SCRIPT" --fixture "fixtures/preflight/${fixture}.json" --json
  rc=$?
  if [[ "$rc" -eq "$expected_exit" ]] && jq -e --arg mode "$expected_mode" --argjson exit_code "$expected_exit" '.mode == $mode and .exit_code == $exit_code' "$out" >/dev/null; then
    pass "mode ${fixture}"
  else
    fail "mode ${fixture} rc=${rc}"
  fi
}

check_mode fresh blocked 30
check_mode partial reduced 20
check_mode existing full 0
check_mode reduced reduced 20
check_mode misconfigured blocked 30

run_capture "$TMP/malformed.out" "$TMP/malformed.err" "$SCRIPT" --fixture fixtures/preflight/malformed.json --json
malformed_rc=$?
if [[ "$malformed_rc" -eq 40 ]] && [[ ! -s "$TMP/malformed.out" ]] && rg -q '^ERROR: fixture schema invalid:' "$TMP/malformed.err" && rg -q '^Suggested action:' "$TMP/malformed.err"; then
  pass "malformed fixture stable error"
else
  fail "malformed fixture stable error rc=${malformed_rc}"
fi

run_capture "$TMP/partial-evidence.out" "$TMP/partial-evidence.err" "$SCRIPT" --fixture fixtures/preflight/partial.json --json
if jq -e '.dependencies[] | select(.id == "git") | .evidence.source == "fixture" and (.evidence.version | contains("2.45.0"))' "$TMP/partial-evidence.out" >/dev/null; then
  pass "fixture mode uses fixture evidence"
else
  fail "fixture mode uses fixture evidence"
fi

if "$SCRIPT" --examples --json | jq -e '.command == "examples" and ([.examples[].name] | index("docs-only")) and .exit_codes["20"]' >/dev/null; then
  pass "examples"
else
  fail "examples"
fi

if "$SCRIPT" help exit-codes | rg -q '20  reduced mode'; then
  pass "exit codes help"
else
  fail "exit codes help"
fi

if "$SCRIPT" doctor --json | jq -e '.command == "doctor" and .status == "pass" and (.checks[] | select(.name == "malformed_negative_fixture") | .status == "present")' >/dev/null; then
  pass "doctor reports fixture health"
else
  fail "doctor reports fixture health"
fi

if ! rg -n '/Users/josh|sk-[A-Za-z0-9_-]{12,}|ghp_[A-Za-z0-9_]{20,}' "$FIXTURES" "$TMP" >/dev/null; then
  pass "no private paths or secret-shaped fixture material"
else
  fail "private paths or secret-shaped fixture material"
fi

if [[ "$FAIL" -gt 0 ]]; then
  printf 'SUMMARY pass=%d fail=%d\n' "$PASS" "$FAIL" >&2
  exit 1
fi
printf 'SUMMARY pass=%d fail=0\n' "$PASS"
