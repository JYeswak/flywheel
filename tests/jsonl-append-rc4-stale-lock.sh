#!/usr/bin/env bash
# tests/jsonl-append-rc4-stale-lock.sh
# Bead flywheel-t38to: regression coverage for the rc=4 stale-lock path
# added by flywheel-xy71r.
#
# fw_jsonl__with_lock in $HOME/.local/share/flywheel-watchers/lib/jsonl-append.sh
# detects when a regular file (not a directory) exists at the mkdir-lock
# path and refuses with rc=4 + a structured WARN to stderr instead of
# looping for 5s and returning rc=2 (the pre-xy71r failure mode).
#
# This test exercises the rc=4 path deterministically by stubbing
# `command -v flock` to return failure (forces the mkdir branch on
# any platform, regardless of whether flock is actually installed).
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd -P)"
LIB="${JSONL_APPEND_LIB:-$HOME/.local/share/flywheel-watchers/lib/jsonl-append.sh}"

pass_count=0
fail_count=0
pass() { pass_count=$((pass_count + 1)); printf 'PASS %s\n' "$1"; }
fail() { fail_count=$((fail_count + 1)); printf 'FAIL %s\n' "$1" >&2; }

# Test 1: lib exists with the rc=4 stale-lock branch + flywheel-xy71r citation
if [[ -f "$LIB" ]] \
  && grep -q "flywheel-xy71r" "$LIB" \
  && grep -q "return 4" "$LIB" \
  && grep -qE 'if \[\[ -e "\$lock" && ! -d "\$lock" \]\]' "$LIB"; then
  pass "jsonl-append.sh exists with rc=4 stale-lock branch + flywheel-xy71r citation"
else
  fail "rc=4 branch missing or moved at $LIB"
  printf 'SUMMARY pass=%d fail=%d\n' "$pass_count" "$fail_count" >&2
  exit 1
fi

# Test 2: rc=4 propagation through fw_jsonl_append_validated case stmt
if grep -qE '4\) return 4 ;;' "$LIB"; then
  pass "rc=4 propagated through fw_jsonl_append_validated case statement"
else
  fail "rc=4 propagation missing in case stmt"
fi

# Build an isolated fixture directory.
FIXTURE="$(mktemp -d -t flywheel-t38to-fixture.XXXXXX)"
trap 'rm -rf "$FIXTURE"' EXIT
LEDGER="$FIXTURE/test-ledger.jsonl"
LOCK="${LEDGER}.lock"

# Pre-create a regular file at the lock path (the bug shape).
: > "$LOCK"
[[ -f "$LOCK" && ! -d "$LOCK" ]] || {
  fail "fixture setup: lock path is not a regular file"
  printf 'SUMMARY pass=%d fail=%d\n' "$pass_count" "$fail_count" >&2
  exit 1
}

# Test 3: with regular-file lock + mkdir branch forced, fw_jsonl_append_validated returns rc=4
# Shadow `command` to make `command -v flock` fail; this forces the mkdir branch
# regardless of whether flock is installed on the host.
RC=0
STDERR_CAPTURE="$(
  bash -c '
    command() {
      if [[ "$1" == "-v" && "$2" == "flock" ]]; then
        return 1
      fi
      builtin command "$@"
    }
    source "$0"
    fw_jsonl_append_validated "$1" "{\"k\":\"v\",\"ts\":\"2026-05-10T00:00:00Z\"}"
    exit $?
  ' "$LIB" "$LEDGER" 2>&1 1>/dev/null
)" || RC=$?

if [[ "$RC" -eq 4 ]]; then
  pass "fw_jsonl_append_validated returns rc=4 on stale-lock-file (was rc=2 silent stall pre-xy71r)"
else
  fail "expected rc=4, got rc=$RC; stderr: ${STDERR_CAPTURE:0:200}"
fi

# Test 4: stderr emits the structured WARN
if grep -qE 'WARN: jsonl-append lock path is a non-directory' <<<"$STDERR_CAPTURE"; then
  pass "stderr emits structured WARN on stale-lock-file"
else
  fail "stderr missing canonical WARN; got: ${STDERR_CAPTURE:0:200}"
fi

# Test 5: ledger was NOT mutated (no row appended on rc=4)
if [[ ! -f "$LEDGER" ]] || [[ "$(wc -l <"$LEDGER" | tr -d ' ')" == "0" ]]; then
  pass "ledger unmutated when rc=4 (no row appended)"
else
  fail "ledger mutated despite rc=4: $(cat "$LEDGER")"
fi

# Test 6: positive control — directory at lock path → mkdir branch succeeds
# (replace the regular file with a non-existent path; let the lib mkdir-create
# the lock dir, append, and clean up)
rm -f "$LOCK"
RC=0
bash -c '
    command() {
      if [[ "$1" == "-v" && "$2" == "flock" ]]; then
        return 1
      fi
      builtin command "$@"
    }
    source "$0"
    fw_jsonl_append_validated "$1" "{\"k\":\"positive_control\"}"
    exit $?
' "$LIB" "$LEDGER" >/dev/null 2>&1 || RC=$?

if [[ "$RC" -eq 0 ]] && [[ -f "$LEDGER" ]] && grep -q '"positive_control"' "$LEDGER"; then
  pass "positive control — mkdir branch succeeds + appends row when no stale lock present"
else
  fail "positive control failed; rc=$RC, ledger contents: $(cat "$LEDGER" 2>/dev/null || echo '<missing>')"
fi

# Test 7: no leftover lock dir/file after positive control (mkdir branch cleans up)
if [[ ! -e "$LOCK" ]]; then
  pass "mkdir branch cleans up lock directory after success"
else
  fail "mkdir branch left stale lock at $LOCK"
fi

if [[ "$fail_count" -gt 0 ]]; then
  printf 'SUMMARY pass=%d fail=%d\n' "$pass_count" "$fail_count" >&2
  exit 1
fi
printf 'SUMMARY pass=%d fail=0\n' "$pass_count"
