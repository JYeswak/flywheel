#!/usr/bin/env bash
# tests/cross-repo-fmh-probe-canonical-cli.sh
#
# Regression test for flywheel-2xdi.147: receiver wire-in for
# cross-repo-fmh-probe.sh. 4th instance of the test-receiver wire-in
# recipe (after 2xdi.90 operator-fatigue, 2xdi.92 public-artifact-
# pipeline, 2xdi.146 codex-pane-path; N=3 promoted at .146).
#
# Asserts the probe's canonical-cli surface returns stable JSON with
# schema_version=cross-repo-fmh-probe.v1.

set -uo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd -P)"
SCRIPT="$ROOT/.flywheel/scripts/cross-repo-fmh-probe.sh"

pass_count=0
fail_count=0
pass() { pass_count=$((pass_count + 1)); printf 'PASS %s\n' "$1"; }
fail() { fail_count=$((fail_count + 1)); printf 'FAIL %s\n' "$1" >&2; }

# Test 1: syntax
if bash -n "$SCRIPT" 2>/dev/null; then pass "syntax"; else fail "syntax"; fi

# Test 2: --info
if "$SCRIPT" --info --json 2>/dev/null | jq -e '.schema_version == "cross-repo-fmh-probe.v1"' >/dev/null; then
  pass "--info emits cross-repo-fmh-probe.v1 envelope"
else fail "--info envelope"; fi

# Test 3: --schema
if "$SCRIPT" --schema --json 2>/dev/null | jq -e '.schema_version == "cross-repo-fmh-probe.v1"' >/dev/null; then
  pass "--schema emits cross-repo-fmh-probe.v1 envelope"
else fail "--schema envelope"; fi

# Test 4: --doctor (canonical-cli triad)
if "$SCRIPT" --doctor --json 2>/dev/null | jq -e '.schema_version == "cross-repo-fmh-probe.v1"' >/dev/null; then
  pass "--doctor emits envelope (triad)"
else fail "--doctor envelope"; fi

# Test 5: --health (full triad)
if "$SCRIPT" --health --json 2>/dev/null | jq -e '.schema_version == "cross-repo-fmh-probe.v1"' >/dev/null; then
  pass "--health emits envelope (triad)"
else fail "--health envelope"; fi

# Test 6: default --json run mode emits structured probe output
out="$("$SCRIPT" --json 2>/dev/null)"
if printf '%s' "$out" | jq -e '.schema_version == "cross-repo-fmh-probe.v1"' >/dev/null; then
  pass "default --json run mode emits cross-repo-fmh-probe.v1 envelope"
else fail "default --json run mode"; fi

# Test 7: --lookback-days arg accepted (per-call tuning)
if "$SCRIPT" --lookback-days 7 --json 2>/dev/null | jq -e '.schema_version == "cross-repo-fmh-probe.v1"' >/dev/null; then
  pass "--lookback-days arg accepted (per-call tuning)"
else fail "--lookback-days arg"; fi

# Test 8: --min-repos arg accepted (per-call tuning)
if "$SCRIPT" --min-repos 3 --json 2>/dev/null | jq -e '.schema_version == "cross-repo-fmh-probe.v1"' >/dev/null; then
  pass "--min-repos arg accepted (per-call tuning)"
else fail "--min-repos arg"; fi

# Test 9: --top arg accepted (per-call tuning)
if "$SCRIPT" --top 5 --json 2>/dev/null | jq -e '.schema_version == "cross-repo-fmh-probe.v1"' >/dev/null; then
  pass "--top arg accepted (per-call tuning)"
else fail "--top arg"; fi

# Test 10: Step 4o READ-ONLY — no notification/mutating call sites
if grep -qE '^[[:space:]]*(curl[[:space:]]+[^#]*pushover|/usr/bin/sendmail|osascript[[:space:]]+-e[[:space:]]+["'"'"']display|notify-send[[:space:]]|br[[:space:]]+create|ntm[[:space:]]+send)' "$SCRIPT"; then
  fail "anti-pattern: probe contains notification or mutating call site"
else
  pass "probe is READ-ONLY (no notification/mutating call sites)"
fi

# Test 11: schema_version stable across all 5 surfaces
versions=$(
  for surface in --info --schema --doctor --health --json; do
    "$SCRIPT" "$surface" --json 2>/dev/null | jq -r '.schema_version' 2>/dev/null
  done | sort -u | wc -l | tr -d ' '
)
if [[ "$versions" == "1" ]]; then
  pass "schema_version stable across all 5 canonical surfaces"
else
  fail "schema_version drifts across surfaces ($versions distinct versions)"
fi

# Test 12: cites owning bead flywheel-1rmp.12 in script header
if grep -q "flywheel-1rmp.12" "$SCRIPT"; then
  pass "script header cites owning bead flywheel-1rmp.12"
else fail "script doesn't cite owning bead"; fi

if [[ "$fail_count" -gt 0 ]]; then
  printf 'SUMMARY pass=%d fail=%d\n' "$pass_count" "$fail_count" >&2
  exit 1
fi
printf 'SUMMARY pass=%d fail=0\n' "$pass_count"
