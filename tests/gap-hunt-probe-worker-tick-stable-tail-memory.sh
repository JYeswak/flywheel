#!/usr/bin/env bash
# Regression test for flywheel-2xdi.163:
# feedback_worker_tick_shared_append_stable_tail_checklist.md must be anchored
# in repo-local doctrine so gap-hunt-probe no longer reports it as
# memory-without-cross-link.
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd -P)"
PROBE="$ROOT/.flywheel/scripts/gap-hunt-probe.sh"
DOCTRINE="$ROOT/.flywheel/doctrine/worker-tick-shared-append-stable-tail.md"
MEMORY_NAME="feedback_worker_tick_shared_append_stable_tail_checklist.md"
TMP="$(mktemp -d -t gap-hunt-worker-tail-memory.XXXXXX)"
trap 'rm -rf "$TMP"' EXIT

pass_count=0
fail_count=0
pass() { pass_count=$((pass_count + 1)); printf 'PASS %s\n' "$1"; }
fail() { fail_count=$((fail_count + 1)); printf 'FAIL %s\n' "$1" >&2; }

if [[ -f "$DOCTRINE" ]]; then
  pass "doctrine anchor exists"
else
  fail "doctrine anchor missing"
fi

if grep -Fq "$MEMORY_NAME" "$DOCTRINE"; then
  pass "doctrine anchor cites memory filename"
else
  fail "doctrine anchor does not cite memory filename"
fi

if "$PROBE" --json --dry-run >"$TMP/gaps.json" 2>"$TMP/gaps.err"; then
  pass "gap-hunt-probe dry-run emitted JSON"
else
  fail "gap-hunt-probe dry-run failed"
  cat "$TMP/gaps.err" >&2
fi

memory_count="$(
  jq -r --arg name "$MEMORY_NAME" \
    '[.gap_ids[]? | select(startswith("memory-without-cross-link:") and contains($name))] | length' \
    "$TMP/gaps.json"
)"
if [[ "$memory_count" == "0" ]]; then
  pass "memory rule no longer emitted as memory-without-cross-link"
else
  fail "memory rule still emitted as memory-without-cross-link ($memory_count)"
fi

printf 'PASS gap-hunt-probe-worker-tick-stable-tail-memory (%s/%s)\n' "$pass_count" "$fail_count"
[[ "$fail_count" -eq 0 ]]
