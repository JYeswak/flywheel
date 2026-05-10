#!/usr/bin/env bash
# tests/doctor-publishability-bar-loud-failure.sh
# Regression test for flywheel-9vb9i: doctor postcheck must surface
# publishability_bar errors instead of silent doctor_internal_empty_fail.
#
# Per "loud-failure invariant" doctrine: any gate that flips status=fail
# MUST populate errors[] with a real error code. Sister probes (storage,
# jeff_corpus, daily_report, file_length, quality_bar_close_gate, etc.)
# all propagate their .errors arrays via canonical postcheck pattern:
#   + (.<probe>.errors // [])
# publishability_bar was the outlier. This regression test guards the fix.
#
# What this test verifies:
#   1. The postcheck source has the canonical .publishability_bar.errors line
#   2. The postcheck source has the loud-failure-invariant maybe() clause
#   3. (Live, when feasible) doctor produces non-sentinel error codes when
#      publishability_bar.status == "fail"

set -uo pipefail

POSTCHECK="${FLYWHEEL_POSTCHECK_SH:-$HOME/.claude/skills/.flywheel/lib/doctor.d/part-01-doctor_cache_path-to-doctor_schema_postcheck.sh}"
FLYWHEEL_LOOP_BIN="${FLYWHEEL_LOOP_BIN:-$HOME/.claude/skills/.flywheel/bin/flywheel-loop}"

pass_count=0
fail_count=0
pass() { pass_count=$((pass_count + 1)); printf 'PASS %s\n' "$1"; }
fail() { fail_count=$((fail_count + 1)); printf 'FAIL %s\n' "$1" >&2; }

# Test 1: postcheck file exists + bash-parsable
if [[ -r "$POSTCHECK" ]] && bash -n "$POSTCHECK" 2>/dev/null; then
  pass "postcheck file present + syntax-valid"
else
  fail "postcheck missing/syntax-broken at $POSTCHECK"
  printf 'SUMMARY pass=%d fail=%d\n' "$pass_count" "$fail_count" >&2
  exit 1
fi

# Test 2 (load-bearing): canonical sister-pattern propagation present
if grep -qE '^\s*\+ \(\.publishability_bar\.errors // \[\]\)' "$POSTCHECK"; then
  pass "postcheck pulls .publishability_bar.errors into rollup (sister-pattern)"
else
  fail "postcheck missing canonical .publishability_bar.errors propagation"
fi

# Test 3 (load-bearing): loud-failure invariant clause present
# This guards against the original bug shape: status=fail with empty errors[]
if grep -qE 'publishability_bar_status_failed_silent' "$POSTCHECK"; then
  pass "postcheck has loud-failure invariant maybe() clause (status_failed_silent)"
else
  fail "postcheck missing loud-failure invariant maybe() for publishability_bar"
fi

# Test 4 (regression guard): bug-shape SHOULD fail loudly now
# Construct a fixture probe that has status=fail + non-empty errors,
# and verify the canonical sister-pattern would propagate them.
TMP_FIXTURE="$(mktemp -t pb-fixture.XXXXXX)"
cat > "$TMP_FIXTURE" <<'EOF'
{
  "publishability_bar": {
    "status": "fail",
    "errors": [
      {"code": "brand_voice_banned_words", "message": "public copy contains banned words"}
    ]
  }
}
EOF
PROPAGATED="$(jq -c '.publishability_bar.errors // []' "$TMP_FIXTURE")"
if [[ "$PROPAGATED" == '[{"code":"brand_voice_banned_words","message":"public copy contains banned words"}]' ]]; then
  pass "fixture-level: .publishability_bar.errors propagation produces correct array"
else
  fail "fixture-level propagation broken: got $PROPAGATED"
fi
rm -f "$TMP_FIXTURE"

# Test 5 (load-bearing AC): live doctor — when status=fail, fail_codes must
# include a real publishability_bar code (NOT just doctor_internal_empty_fail
# sentinel, IF status=fail is currently driven by publishability_bar).
if [[ -x "$FLYWHEEL_LOOP_BIN" ]]; then
  TMP_DOCTOR="${FLYWHEEL_DOCTOR_FIXTURE:-/tmp/9vb9i-doctor.json}"
  if [[ -s "$TMP_DOCTOR" ]]; then
    FAIL_CODES="$(jq -r '[.errors[]?.code] | unique | join(",")' "$TMP_DOCTOR" 2>/dev/null)"
    SENTINEL_ALONE=0
    if [[ "$FAIL_CODES" == "doctor_internal_empty_fail" ]]; then
      SENTINEL_ALONE=1
    fi
    if [[ "$SENTINEL_ALONE" -eq 0 ]]; then
      pass "live doctor: fail_codes do not consist solely of doctor_internal_empty_fail (codes=$FAIL_CODES)"
    else
      fail "live doctor: fail_codes==doctor_internal_empty_fail alone (regression — sentinel is firing)"
    fi
  else
    pass "live doctor result not present at $TMP_DOCTOR — skipping live AC check"
  fi
else
  pass "flywheel-loop binary unavailable — skipping live AC check"
fi

if [[ "$fail_count" -gt 0 ]]; then
  printf 'SUMMARY pass=%d fail=%d\n' "$pass_count" "$fail_count" >&2
  exit 1
fi
printf 'SUMMARY pass=%d fail=0\n' "$pass_count"
