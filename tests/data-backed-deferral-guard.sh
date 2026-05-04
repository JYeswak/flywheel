#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd -P)"
FLYWHEEL_LOOP_BIN="${FLYWHEEL_LOOP_BIN:-$HOME/.claude/skills/.flywheel/bin/flywheel-loop}"
FIXTURES="$ROOT/tests/fixtures/data-backed-deferral"

pass_count=0
check_count=0

pass() {
  check_count=$((check_count + 1))
  pass_count=$((pass_count + 1))
  printf 'PASS %s\n' "$1"
}

fail() {
  check_count=$((check_count + 1))
  printf 'FAIL %s\n' "$1" >&2
  printf '  - %s\n' "$2" >&2
  exit 1
}

json_get() {
  jq -r "$2" <<<"$1"
}

expect_violation() {
  local label="$1" fixture="$2" out rc=0 class
  out="$("$FLYWHEEL_LOOP_BIN" data-backed-deferral-check --signals "$fixture" --json 2>/dev/null)" || rc=$?
  class="$(json_get "$out" '.class')"
  if [[ "$rc" -ne 1 ]]; then
    fail "$label" "expected exit 1 for violation, got $rc; output=$out"
  fi
  if [[ "$class" != "orch_meat_puppet_question_with_sufficient_data" ]]; then
    fail "$label" "expected L66 sufficient-data class, got $class; output=$out"
  fi
  if [[ "$(json_get "$out" '.gate.passes')" != "true" ]]; then
    fail "$label" "expected gate.passes=true; output=$out"
  fi
  pass "$label"
}

expect_allow() {
  local label="$1" fixture="$2" expected_reason="$3" out rc=0
  out="$("$FLYWHEEL_LOOP_BIN" data-backed-deferral-check --signals "$fixture" --json 2>/dev/null)" || rc=$?
  if [[ "$rc" -ne 0 ]]; then
    fail "$label" "expected exit 0 for allowed question, got $rc; output=$out"
  fi
  if [[ "$(json_get "$out" '.status')" != "ok" ]]; then
    fail "$label" "expected status=ok; output=$out"
  fi
  if [[ "$(json_get "$out" '.allowed_reason')" != "$expected_reason" ]]; then
    fail "$label" "expected allowed_reason=$expected_reason; output=$out"
  fi
  pass "$label"
}

command -v jq >/dev/null 2>&1 || { echo "missing jq" >&2; exit 69; }
[[ -x "$FLYWHEEL_LOOP_BIN" ]] || { echo "not executable: $FLYWHEEL_LOOP_BIN" >&2; exit 69; }

expect_violation "L66 catches fuckup-log row 185 blanket approval ask" "$FIXTURES/row185-catch.json"
expect_violation "L66 catches ntm#116 ask instead of adversarial validation" "$FIXTURES/ntm116-catch.json"
expect_allow "L66 allows named true tie" "$FIXTURES/ambiguous-tie-allow.json" "tie_between"
expect_allow "L66 allows named missing datum" "$FIXTURES/missing-datum-allow.json" "evidence_missing"

save_log="$(mktemp "${TMPDIR:-/tmp}/data-backed-deferral-save.XXXXXX")"
rm -f "$save_log"
"$FLYWHEEL_LOOP_BIN" data-backed-deferral-check \
  --signals "$FIXTURES/row185-catch.json" \
  --json \
  --record-save \
  --save-log "$save_log" >/dev/null 2>&1 && {
    fail "L66 save log writes on caught deferral" "expected guard to exit nonzero while writing save log"
  }
if [[ "$(wc -l <"$save_log" | tr -d ' ')" != "1" ]]; then
  fail "L66 save log writes on caught deferral" "expected one save-log row at $save_log"
fi
if [[ "$(jq -r '.event' "$save_log")" != "data_backed_deferral_prevented" ]]; then
  fail "L66 save log writes on caught deferral" "unexpected save-log row: $(cat "$save_log")"
fi
rm -f "$save_log"
pass "L66 save log writes on caught deferral"

printf '\nSummary: %s/%s passed\n' "$pass_count" "$check_count"
