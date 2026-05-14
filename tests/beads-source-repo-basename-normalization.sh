#!/usr/bin/env bash
# tests/beads-source-repo-basename-normalization.sh
# Regression test for flywheel-wz5rh: source_repo basename normalization.
#
# What this test verifies:
#   1. JSONL has zero rows with source_repo='flywheel' (basename, the bug shape)
#   2. JSONL has all 1644 rows with source_repo='<flywheel-repo>' (canonical)
#   3. DB matches JSONL (leakage_count = 0)
#   4. The bug-shape regex doesn't appear in JSONL (regression guard)

set -uo pipefail

REPO="${FLYWHEEL_REPO:-$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd -P)}"
CANONICAL_REPO="$(cd "$REPO" && pwd -P)"
JSONL="$REPO/.beads/issues.jsonl"
DB="$REPO/.beads/beads.db"

pass_count=0
fail_count=0
pass() { pass_count=$((pass_count + 1)); printf 'PASS %s\n' "$1"; }
fail() { fail_count=$((fail_count + 1)); printf 'FAIL %s\n' "$1" >&2; }

# Test 1: JSONL exists + readable
if [[ -r "$JSONL" ]]; then
  pass "JSONL exists at $JSONL"
else
  fail "JSONL missing at $JSONL"
  printf 'SUMMARY pass=%d fail=%d\n' "$pass_count" "$fail_count" >&2
  exit 1
fi

# Test 2 (load-bearing): zero basename-source_repo rows in JSONL
BASENAME_COUNT="$(jq -c 'select(.source_repo == "flywheel")' "$JSONL" | wc -l | tr -d ' ')"
if [[ "$BASENAME_COUNT" == "0" ]]; then
  pass "JSONL has 0 basename-source_repo rows (was 291 before fix)"
else
  fail "JSONL has $BASENAME_COUNT rows with source_repo='flywheel' (regression)"
fi

# Test 3 (load-bearing): all rows have canonical source_repo
TOTAL_ROWS="$(wc -l < "$JSONL" | tr -d ' ')"
CANONICAL_COUNT="$(jq -c --arg repo "$CANONICAL_REPO" 'select(.source_repo == $repo)' "$JSONL" | wc -l | tr -d ' ')"
if [[ "$CANONICAL_COUNT" == "$TOTAL_ROWS" ]]; then
  pass "JSONL all $TOTAL_ROWS rows have canonical source_repo"
else
  fail "JSONL canonical=$CANONICAL_COUNT total=$TOTAL_ROWS (mismatch)"
fi

# Test 4: no other source_repo values exist (regression guard)
DISTINCT_VALUES="$(jq -r '.source_repo // "NULL"' "$JSONL" | sort -u | wc -l | tr -d ' ')"
if [[ "$DISTINCT_VALUES" == "1" ]]; then
  pass "JSONL has exactly 1 distinct source_repo value (canonical only)"
else
  jq -r '.source_repo // "NULL"' "$JSONL" | sort -u >&2
  fail "JSONL has $DISTINCT_VALUES distinct source_repo values (expected 1)"
fi

# Test 5 (load-bearing AC): DB leakage_count == 0
if [[ -r "$DB" ]] && command -v sqlite3 >/dev/null 2>&1; then
  canonical_sql="$(printf '%s' "$CANONICAL_REPO" | sed "s/'/''/g")"
  DB_LEAKAGE="$(sqlite3 "$DB" "SELECT COUNT(*) FROM issues WHERE source_repo IS NULL OR source_repo != '$canonical_sql';" 2>/dev/null)"
  if [[ "$DB_LEAKAGE" == "0" ]]; then
    pass "DB leakage_count=0 (was 253 before fix; matches gate at lib/doctor.d/part-02-check_beads_db_health-to-detect_tests_json.sh:87)"
  else
    fail "DB leakage_count=$DB_LEAKAGE (expected 0)"
  fi
else
  pass "DB or sqlite3 unavailable — skipping DB-layer verification"
fi

# Test 6: regression guard — bug-shape literal absent in JSONL
if grep -qE '"source_repo":"flywheel"[,}]' "$JSONL"; then
  fail "regression guard: bug-shape \"source_repo\":\"flywheel\" still present in JSONL"
else
  pass "regression guard: bug-shape \"source_repo\":\"flywheel\" absent in JSONL"
fi

if [[ "$fail_count" -gt 0 ]]; then
  printf 'SUMMARY pass=%d fail=%d\n' "$pass_count" "$fail_count" >&2
  exit 1
fi
printf 'SUMMARY pass=%d fail=0\n' "$pass_count"
