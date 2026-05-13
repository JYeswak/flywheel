#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd -P)"
CHANGELOG="$ROOT/CHANGELOG.md"

pass_count=0
fail_count=0
pass() { pass_count=$((pass_count + 1)); printf 'PASS %s\n' "$1"; }
fail() { fail_count=$((fail_count + 1)); printf 'FAIL %s\n' "$1" >&2; }

if [[ -s "$CHANGELOG" ]]; then pass "exists"; else fail "exists"; fi

if grep -q '^# Changelog$' "$CHANGELOG"; then pass "title"; else fail "title"; fi

if grep -q '^## \[0\.2\.0\] - ' "$CHANGELOG"; then
  pass "0.2.0 section"
else
  fail "0.2.0 section"
fi

for heading in Added Changed Security Evidence; do
  if grep -q "^### $heading$" "$CHANGELOG"; then
    pass "$heading heading"
  else
    fail "$heading heading"
  fi
done

if grep -q 'Keep a Changelog' "$CHANGELOG" && grep -q 'semantic versioning' "$CHANGELOG"; then
  pass "changelog convention"
else
  fail "changelog convention"
fi

if grep -q 'reduced mode as the required public path' "$CHANGELOG" \
  && grep -q 'Claude, Codex, Gemini, and OpenClaw' "$CHANGELOG" \
  && grep -q 'strict agent-lane runtime receipt' "$CHANGELOG" \
  && grep -q 'private-state scan' "$CHANGELOG"; then
  pass "support-tier honesty"
else
  fail "support-tier honesty"
fi

if grep -q 'Public release cutover authorization runbook' "$CHANGELOG" \
  && grep -q 'live readiness codes' "$CHANGELOG" \
  && grep -q 'final signoff boundaries' "$CHANGELOG"; then
  pass "cutover authorization entry"
else
  fail "cutover authorization entry"
fi

if grep -q 'docs/evidence/publication-evidence.md' "$CHANGELOG" \
  && grep -q 'live evidence still required' "$CHANGELOG"; then
  pass "publication evidence index entry"
else
  fail "publication evidence index entry"
fi

if ! grep -Eq 'TODO|TBD' "$CHANGELOG"; then
  pass "no placeholders"
else
  fail "no placeholders"
fi

if python3 "$ROOT/scripts/depersonalize.py" --scan-table --root "$CHANGELOG" --json >/dev/null; then
  pass "depersonalization scan"
else
  fail "depersonalization scan"
fi

printf 'SUMMARY pass=%d fail=%d\n' "$pass_count" "$fail_count"
[[ "$fail_count" -eq 0 ]]
