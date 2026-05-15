#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd -P)"
SCRIPT="$ROOT/scripts/validate_installed_binary_source.py"
MANIFEST="$ROOT/docs/evidence/installed-binary-source-manifest.json"

pass_count=0
fail_count=0
pass() { pass_count=$((pass_count + 1)); printf 'PASS %s\n' "$1"; }
fail() { fail_count=$((fail_count + 1)); printf 'FAIL %s\n' "$1" >&2; }

if python3 -m py_compile "$SCRIPT"; then
  pass "validator compiles"
else
  fail "validator compiles"
fi

if python3 -m json.tool "$MANIFEST" >/dev/null; then
  pass "manifest is valid json"
else
  fail "manifest is valid json"
fi

out="$(python3 "$SCRIPT")"
if jq -e '.status == "pass" and .binary_count == 4 and .failure_count == 0' <<<"$out" >/dev/null; then
  pass "source manifest validates"
else
  fail "source manifest validates"
  printf '%s\n' "$out" >&2
fi

if jq -e '[.rows[] | select(.tracked_in_flywheel_repo == false and .source_gap_bead == "flywheel-nkw4o")] | length == 4' <<<"$out" >/dev/null; then
  pass "untracked binary rows require source gap bead"
else
  fail "untracked binary rows require source gap bead"
fi

if jq -e '[.rows[] | select(.shipped_in_reduced_install == false)] | length == 4' <<<"$out" >/dev/null; then
  pass "full-substrate binaries excluded from reduced install"
else
  fail "full-substrate binaries excluded from reduced install"
fi

if grep -q 'bin/flywheel' "$MANIFEST" && ! grep -q 'flywheel-verdict.*bin/flywheel' "$MANIFEST"; then
  pass "manifest names reduced binary without promoting full substrate"
else
  fail "manifest names reduced binary without promoting full substrate"
fi

printf 'SUMMARY pass=%d fail=%d\n' "$pass_count" "$fail_count"
[[ "$fail_count" -eq 0 ]]
