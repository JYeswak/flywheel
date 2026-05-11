#!/usr/bin/env bash
# tests/public-artifact-pipeline-probe-canonical-cli.sh
#
# Regression test for flywheel-2xdi.92: receiver wire-in for
# public-artifact-pipeline-probe.sh. Sister to 2xdi.90 (operator-fatigue-probe).
#
# Asserts the probe's canonical-cli surface (--info / --schema / --doctor /
# --dry-run / --apply / --json) returns stable JSON with
# schema_version=public-artifact-pipeline/v1.

set -uo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd -P)"
SCRIPT="$ROOT/.flywheel/scripts/public-artifact-pipeline-probe.sh"

pass_count=0
fail_count=0
pass() { pass_count=$((pass_count + 1)); printf 'PASS %s\n' "$1"; }
fail() { fail_count=$((fail_count + 1)); printf 'FAIL %s\n' "$1" >&2; }

# Test 1: syntax
if bash -n "$SCRIPT" 2>/dev/null; then pass "syntax"; else fail "syntax"; fi

# Test 2: --info
if "$SCRIPT" --info --json 2>/dev/null | jq -e '.schema_version == "public-artifact-pipeline/v1"' >/dev/null; then
  pass "--info emits public-artifact-pipeline/v1 envelope"
else fail "--info envelope"; fi

# Test 3: --schema
if "$SCRIPT" --schema --json 2>/dev/null | jq -e '.schema_version == "public-artifact-pipeline/v1"' >/dev/null; then
  pass "--schema emits public-artifact-pipeline/v1 envelope"
else fail "--schema envelope"; fi

# Test 4: --doctor (canonical-cli triad)
if "$SCRIPT" --doctor --json 2>/dev/null | jq -e '.schema_version == "public-artifact-pipeline/v1"' >/dev/null; then
  pass "--doctor emits envelope (triad)"
else fail "--doctor envelope"; fi

# Test 5: default --json run emits measurement
if "$SCRIPT" --json 2>/dev/null | jq -e '.schema_version == "public-artifact-pipeline/v1"' >/dev/null; then
  pass "default --json run mode emits public-artifact-pipeline/v1 measurement"
else fail "default --json run mode"; fi

# Test 6: --dry-run emits envelope (mutation discipline)
if "$SCRIPT" --dry-run --json 2>/dev/null | jq -e '.schema_version == "public-artifact-pipeline/v1"' >/dev/null; then
  pass "--dry-run emits envelope (mutation discipline)"
else fail "--dry-run envelope"; fi

# Test 7: --apply emits envelope with mode=apply (mutation discipline)
out="$("$SCRIPT" --apply --json 2>/dev/null)"
if printf '%s' "$out" | jq -e '.schema_version == "public-artifact-pipeline/v1" and .mode == "apply"' >/dev/null; then
  pass "--apply emits envelope with mode=apply (mutation discipline)"
else fail "--apply envelope"; fi

# Test 8: --min-score arg accepted (per-call tuning)
if "$SCRIPT" --min-score 800 --json 2>/dev/null | jq -e '.schema_version == "public-artifact-pipeline/v1"' >/dev/null; then
  pass "--min-score accepted (per-call tuning)"
else fail "--min-score arg"; fi

# Test 9: probe is READ-ONLY measurement (no notification call sites)
if grep -qE '^[[:space:]]*(curl[[:space:]]+[^#]*pushover|/usr/bin/sendmail|osascript[[:space:]]+-e[[:space:]]+["'"'"']display|notify-send[[:space:]])' "$SCRIPT"; then
  fail "anti-pattern: probe contains notification call site"
else
  pass "probe is READ-ONLY measurement (no notification call sites)"
fi

# Test 10: schema field present in --schema output (canonical-cli-scoping)
if "$SCRIPT" --schema --json 2>/dev/null | jq -e 'has("schema_version")' >/dev/null; then
  pass "--schema output has schema_version field"
else fail "--schema schema_version field"; fi

if [[ "$fail_count" -gt 0 ]]; then
  printf 'SUMMARY pass=%d fail=%d\n' "$pass_count" "$fail_count" >&2
  exit 1
fi
printf 'SUMMARY pass=%d fail=0\n' "$pass_count"
