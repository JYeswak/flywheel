#!/usr/bin/env bash
# Regression test for flywheel-2xdi.170:
# feedback_verify_ntm_send.md must stay cited by a repo-local doctrine surface
# so gap-hunt-probe no longer reports it as memory-without-cross-link.
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd -P)"
PROBE="$ROOT/.flywheel/scripts/gap-hunt-probe.sh"
DOCTRINE="$ROOT/.flywheel/doctrine/dispatch-post-send-verification-silent-deaf.md"
MEMORY_NAME="feedback_verify_ntm_send.md"
TMP="$(mktemp -d "${TMPDIR:-/tmp}/gap-hunt-verify-ntm-send.XXXXXX")"
trap 'rm -rf "$TMP"' EXIT

pass=0
fail=0
p() { pass=$((pass + 1)); printf 'PASS %s\n' "$1"; }
f() { fail=$((fail + 1)); printf 'FAIL %s\n' "$1" >&2; }

if [[ -f "$DOCTRINE" ]]; then
  p "doctrine anchor exists"
else
  f "doctrine anchor missing"
fi

if grep -Fq "$MEMORY_NAME" "$DOCTRINE"; then
  p "doctrine anchor cites memory filename"
else
  f "doctrine anchor does not cite memory filename"
fi

if timeout 180 "$PROBE" --json --dry-run >"$TMP/gaps.json" 2>"$TMP/gaps.err"; then
  p "gap-hunt-probe dry-run emitted JSON"
else
  f "gap-hunt-probe dry-run failed"
  cat "$TMP/gaps.err" >&2
fi

memory_count="$(
  jq -r --arg name "$MEMORY_NAME" \
    '[.gap_ids[]? | select(startswith("memory-without-cross-link:") and contains($name))] | length' \
    "$TMP/gaps.json"
)"
if [[ "$memory_count" == "0" ]]; then
  p "memory rule no longer emitted as memory-without-cross-link"
else
  f "memory rule still emitted as memory-without-cross-link ($memory_count)"
fi

if [[ "$fail" -gt 0 ]]; then
  printf 'SUMMARY pass=%d fail=%d\n' "$pass" "$fail" >&2
  exit 1
fi
printf 'SUMMARY pass=%d fail=0\n' "$pass"
