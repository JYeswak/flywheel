#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd -P)"
FIXTURES="$ROOT/tests/fixtures/pane-work-signal"

pass=0
fail=0

check() {
  local label="$1"
  local result="$2"
  if [[ "$result" == "ok" ]]; then
    printf 'PASS: %s\n' "$label"
    pass=$((pass+1))
  else
    printf 'FAIL: %s\n' "$label"
    fail=$((fail+1))
  fi
}

# Gate 1: directory exists
if test -d "$FIXTURES"; then
  check "fixture directory exists" "ok"
else
  check "fixture directory exists" "fail"
fi

# Gate 2: at least 6 files
count=$(find "$FIXTURES" -type f | wc -l | tr -d ' ')
[[ "$count" -ge 6 ]] && check "at least 6 fixture files (got $count)" "ok" || check "at least 6 fixture files (got $count)" "fail"

# Gate 3: each fixture has expected truth state metadata
for f in "$FIXTURES"/*.txt; do
  fname=$(basename "$f")
  if grep -q "^# truth_state:" "$f" && grep -q "^# ntm_health:" "$f" && grep -q "^# pws_truth:" "$f"; then
    check "fixture $fname has truth metadata" "ok"
  else
    check "fixture $fname has truth metadata" "fail"
  fi
done

# Gate 4: Working (...) appears in a fixture
rg -q "Working \\(" "$FIXTURES" && check "Working (...) appears in corpus" "ok" || check "Working (...) appears in corpus" "fail"

# Gate 5: false-idle case represented
if grep -rq "ntm_health: idle" "$FIXTURES" && grep -rq "pws_truth: working" "$FIXTURES"; then
  check "false-idle case (ntm_health=idle + pws_truth=working) present" "ok"
else
  check "false-idle case present" "fail"
fi

# Gate 5 alt: file-level check on fixture 03
if grep -q "ntm_health: idle" "$FIXTURES/03-false-idle-ntm-idle-pws-working.txt" && \
   grep -q "pws_truth: working" "$FIXTURES/03-false-idle-ntm-idle-pws-working.txt"; then
  check "fixture 03 encodes false-idle case" "ok"
else
  check "fixture 03 encodes false-idle case" "fail"
fi

# Stale case represented
grep -q "truth_state: stale" "$FIXTURES/05-stale-sample.txt" && check "stale case represented" "ok" || check "stale case represented" "fail"

# Non-Codex advisory case represented
grep -q "is_codex: false" "$FIXTURES/06-non-codex-ntm-canonical.txt" && check "non-codex advisory case represented" "ok" || check "non-codex advisory case represented" "fail"

printf '\nSummary: %d pass, %d fail\n' "$pass" "$fail"
[[ "$fail" -eq 0 ]]
