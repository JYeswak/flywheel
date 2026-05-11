#!/usr/bin/env bash
# tests/codex-pane-path-probe-canonical-cli.sh
#
# Regression test for flywheel-2xdi.146: receiver wire-in for
# codex-pane-path-probe.sh. Sister to 2xdi.90 (operator-fatigue-probe)
# and 2xdi.92 (public-artifact-pipeline-probe) — same recipe (test
# under canonical-cli naming convention = corpus #5 receiver).
#
# Asserts the probe's canonical-cli surface (--info / --schema /
# --doctor / --json / --help) returns stable JSON with
# schema_version=codex-pane-path-probe/v1.

set -uo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd -P)"
SCRIPT="$ROOT/.flywheel/scripts/codex-pane-path-probe.sh"

pass_count=0
fail_count=0
pass() { pass_count=$((pass_count + 1)); printf 'PASS %s\n' "$1"; }
fail() { fail_count=$((fail_count + 1)); printf 'FAIL %s\n' "$1" >&2; }

# Test 1: syntax
if bash -n "$SCRIPT" 2>/dev/null; then pass "syntax"; else fail "syntax"; fi

# Test 2: --info
if "$SCRIPT" --info --json 2>/dev/null | jq -e '.schema_version == "codex-pane-path-probe/v1"' >/dev/null; then
  pass "--info emits codex-pane-path-probe/v1 envelope"
else fail "--info envelope"; fi

# Test 3: --schema
if "$SCRIPT" --schema --json 2>/dev/null | jq -e '.schema_version == "codex-pane-path-probe/v1"' >/dev/null; then
  pass "--schema emits codex-pane-path-probe/v1 envelope"
else fail "--schema envelope"; fi

# Test 4: --doctor (canonical-cli triad)
if "$SCRIPT" --doctor --json 2>/dev/null | jq -e '.schema_version == "codex-pane-path-probe/v1"' >/dev/null; then
  pass "--doctor emits envelope (triad)"
else fail "--doctor envelope"; fi

# Test 5: default --json run mode emits structured probe output
out="$("$SCRIPT" --json 2>/dev/null)"
if printf '%s' "$out" | jq -e '.schema_version == "codex-pane-path-probe/v1"' >/dev/null; then
  pass "default --json run mode emits codex-pane-path-probe/v1 envelope"
else fail "default --json run mode"; fi

# Test 6: status field present + valid in default run
if printf '%s' "$out" | jq -e 'has("status") and (.status | type == "string")' >/dev/null; then
  pass "default run includes status field (string type)"
else fail "default run missing status field"; fi

# Test 7: --help shows usage with all 5 surface forms
help_out="$("$SCRIPT" --help 2>&1 | head -10)"
if printf '%s' "$help_out" | grep -qE -- "--json" \
  && printf '%s' "$help_out" | grep -qE -- "--doctor" \
  && printf '%s' "$help_out" | grep -qE -- "--info" \
  && printf '%s' "$help_out" | grep -qE -- "--schema"; then
  pass "--help enumerates all 4 canonical surfaces (--json/--doctor/--info/--schema)"
else fail "--help missing canonical surfaces"; fi

# Test 8: probe is READ-ONLY (no notification call sites)
# The probe per its design "probes deterministic sources, not pane env";
# it should not invoke any notification primitive.
if grep -qE '^[[:space:]]*(curl[[:space:]]+[^#]*pushover|/usr/bin/sendmail|osascript[[:space:]]+-e[[:space:]]+["'"'"']display|notify-send[[:space:]])' "$SCRIPT"; then
  fail "anti-pattern: probe contains notification call site"
else
  pass "probe is READ-ONLY (no notification call sites)"
fi

# Test 9: schema_version is stable across all surfaces (no version drift)
versions=$(
  for surface in --info --schema --doctor --json; do
    "$SCRIPT" "$surface" --json 2>/dev/null | jq -r '.schema_version' 2>/dev/null
  done | sort -u | wc -l | tr -d ' '
)
if [[ "$versions" == "1" ]]; then
  pass "schema_version stable across all 4 canonical surfaces"
else
  fail "schema_version drifts across surfaces ($versions distinct versions)"
fi

# Test 10: cites bead flywheel-orx1 (owner) in script header
if grep -q "flywheel-orx1" "$SCRIPT"; then
  pass "script header cites owning bead flywheel-orx1"
else fail "script doesn't cite owning bead"; fi

if [[ "$fail_count" -gt 0 ]]; then
  printf 'SUMMARY pass=%d fail=%d\n' "$pass_count" "$fail_count" >&2
  exit 1
fi
printf 'SUMMARY pass=%d fail=0\n' "$pass_count"
