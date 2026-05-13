#!/usr/bin/env bash
# tests/doctor-status-fail-non-empty-errors.sh
# Bead flywheel-q53pp: regression coverage for the diagnostic-opacity
# invariant on flywheel-loop doctor.
#
# Trauma class research-health-prelude-fail (4 events on 2026-05-02,
# all {proof-product}:0.1) recorded "status=fail with empty errors/warnings",
# meaning the RESEARCH worker correctly aborted the tick but had nothing
# to route to an owner. Filed flywheel-q53pp (P3) for the doctor-emit
# substrate fix.
#
# The fix lives in doctor_schema_postcheck() at
# ~/.claude/skills/.flywheel/lib/doctor.d/part-01-doctor_cache_path-to-doctor_schema_postcheck.sh
# lines 400-408. When status=fail and errors=[], the postcheck inserts
# a sentinel error row with code=doctor_internal_empty_fail. This test
# exercises the live invariant + the sentinel jq filter directly.
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd -P)"
DOCTOR_LIB="${DOCTOR_POSTCHECK_LIB:-$HOME/.claude/skills/.flywheel/lib/doctor.d/part-01-doctor_cache_path-to-doctor_schema_postcheck.sh}"
FLYWHEEL_LOOP="${FLYWHEEL_LOOP_BIN:-$HOME/.claude/skills/.flywheel/bin/flywheel-loop}"

pass_count=0
fail_count=0
pass() { pass_count=$((pass_count + 1)); printf 'PASS %s\n' "$1"; }
fail() { fail_count=$((fail_count + 1)); printf 'FAIL %s\n' "$1" >&2; }

# Test 1: doctor postcheck file exists with the sentinel block at expected lines
if [[ -f "$DOCTOR_LIB" ]] \
  && grep -q "doctor_internal_empty_fail" "$DOCTOR_LIB" \
  && grep -q "postcheck inserted sentinel" "$DOCTOR_LIB" \
  && grep -qE 'if \(\.status == "fail" and \(\(\.errors // \[\]\) \| length\) == 0\)' "$DOCTOR_LIB"; then
  pass "doctor postcheck file present with status=fail+empty-errors sentinel"
else
  fail "doctor postcheck sentinel missing or moved at $DOCTOR_LIB"
  printf 'SUMMARY pass=%d fail=%d\n' "$pass_count" "$fail_count" >&2
  exit 1
fi

# Extract the sentinel jq filter directly so we can unit-test it without
# depending on doctor_ntm_health_json() / command_help_parity_doctor_json().
SENTINEL_FILTER='
  if (.status == "fail" and ((.errors // []) | length) == 0) then
    .errors = [{
      code:"doctor_internal_empty_fail",
      message:"doctor emitted status=fail without a captured cause; postcheck inserted sentinel",
      action:(.action // null),
      mode:(.mode // null),
      repo:(.repo // null)
    }]
  else . end
'

# Test 2: synthetic status=fail with empty errors → sentinel fires
SYNTHETIC_FAIL='{"status":"fail","errors":[],"warnings":[],"action":"unknown","mode":"doctor","repo":"/test/repo"}'
RESULT="$(jq -c "$SENTINEL_FILTER" <<<"$SYNTHETIC_FAIL")"
if jq -e '
  .status == "fail"
  and ((.errors // []) | length) == 1
  and .errors[0].code == "doctor_internal_empty_fail"
  and .errors[0].action == "unknown"
  and .errors[0].mode == "doctor"
  and .errors[0].repo == "/test/repo"
' >/dev/null 2>&1 <<<"$RESULT"; then
  pass "sentinel fires on synthetic status=fail with empty errors"
else
  fail "sentinel did not fire on synthetic status=fail; got: $RESULT"
fi

# Test 3: synthetic status=fail with non-empty errors → passthrough (no double-sentinel)
SYNTHETIC_FAIL_WITH_ERRORS='{"status":"fail","errors":[{"code":"real_failure","message":"the real cause"}],"warnings":[]}'
RESULT="$(jq -c "$SENTINEL_FILTER" <<<"$SYNTHETIC_FAIL_WITH_ERRORS")"
if jq -e '
  .status == "fail"
  and ((.errors // []) | length) == 1
  and .errors[0].code == "real_failure"
' >/dev/null 2>&1 <<<"$RESULT"; then
  pass "non-empty errors[] preserved (no double-sentinel)"
else
  fail "passthrough broke; got: $RESULT"
fi

# Test 4: synthetic status=ok with empty errors → no sentinel inserted
SYNTHETIC_OK='{"status":"ok","errors":[],"warnings":[]}'
RESULT="$(jq -c "$SENTINEL_FILTER" <<<"$SYNTHETIC_OK")"
if jq -e '
  .status == "ok"
  and ((.errors // []) | length) == 0
' >/dev/null 2>&1 <<<"$RESULT"; then
  pass "status=ok with empty errors[] left untouched"
else
  fail "non-fail passthrough broke; got: $RESULT"
fi

# Test 5: synthetic status=warn with empty errors → no sentinel
SYNTHETIC_WARN='{"status":"warn","errors":[],"warnings":[{"code":"some_warning"}]}'
RESULT="$(jq -c "$SENTINEL_FILTER" <<<"$SYNTHETIC_WARN")"
if jq -e '
  .status == "warn"
  and ((.errors // []) | length) == 0
  and ((.warnings // []) | length) == 1
' >/dev/null 2>&1 <<<"$RESULT"; then
  pass "status=warn with empty errors[] left untouched"
else
  fail "warn passthrough broke; got: $RESULT"
fi

# Test 6: live doctor invariant — when the live doctor returns
# status=fail, errors must be non-empty (post-sentinel guarantee).
# This exercises the production path end-to-end.
if [[ -x "$FLYWHEEL_LOOP" ]]; then
  LIVE_PACKET="$("$FLYWHEEL_LOOP" doctor --repo "$ROOT" --json 2>/dev/null || true)"
  if [[ -n "$LIVE_PACKET" ]]; then
    LIVE_STATUS="$(jq -r '.status // ""' <<<"$LIVE_PACKET")"
    if [[ "$LIVE_STATUS" == "fail" ]]; then
      ERR_LEN="$(jq -r '(.errors // []) | length' <<<"$LIVE_PACKET")"
      if [[ "$ERR_LEN" -gt 0 ]]; then
        pass "live doctor: status=fail with errors[] non-empty (length=$ERR_LEN)"
      else
        fail "live doctor: status=fail but errors[] empty — sentinel did not fire on production path"
      fi
    else
      pass "live doctor: status=$LIVE_STATUS (sentinel invariant n/a; no fail to gate)"
    fi
  else
    fail "live doctor produced empty output"
  fi
else
  fail "flywheel-loop binary not found at $FLYWHEEL_LOOP"
fi

if [[ "$fail_count" -gt 0 ]]; then
  printf 'SUMMARY pass=%d fail=%d\n' "$pass_count" "$fail_count" >&2
  exit 1
fi
printf 'SUMMARY pass=%d fail=0\n' "$pass_count"
