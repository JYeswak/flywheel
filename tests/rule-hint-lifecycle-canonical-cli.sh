#!/usr/bin/env bash
# tests/rule-hint-lifecycle-canonical-cli.sh
# Canonical-cli surface tests for .flywheel/scripts/rule-hint-lifecycle.sh
# (surgical scaffold filled-in by bead flywheel-5ke66.17 — wave-2-general-17).
#
# This bead's scaffold adds ONLY dash-flag introspection (python rejects today).
# Positional subcommands (doctor / health / repair / validate / audit / why /
# schema / examples / quickstart / completion) remain python-implemented;
# tests/rule-hint-lifecycle.sh covers their shapes.
set -uo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd -P)"
SCRIPT="$ROOT/.flywheel/scripts/rule-hint-lifecycle.sh"

pass_count=0
fail_count=0
pass() { pass_count=$((pass_count + 1)); printf 'PASS %s\n' "$1"; }
fail() { fail_count=$((fail_count + 1)); printf 'FAIL %s\n' "$1" >&2; }

# Test 1: bash -n syntax
if bash -n "$SCRIPT" 2>/dev/null; then pass "syntax"; else fail "syntax"; fi

# ========= bash scaffold (dash-flag introspection) =========

# Test 2: --info envelope (NEW — python rejected this flag pre-scaffold)
if "$SCRIPT" --info --json 2>/dev/null | jq -e '.schema_version and .command == "info"' >/dev/null; then
  pass "--info emits canonical envelope (bash scaffold)"
else fail "--info envelope"; fi

# Test 3: --info exposes .name + .version + .subcommands (AG3)
if "$SCRIPT" --info --json 2>/dev/null | jq -e '.name == "rule-hint-lifecycle.sh" and .version and (.subcommands | length >= 5)' >/dev/null; then
  pass "--info exposes name + version + subcommands"
else fail "--info AG3 shape"; fi

# Test 4: --schema envelope (NEW)
if "$SCRIPT" --schema --json 2>/dev/null | jq -e '.command == "schema" and .surface == "default"' >/dev/null; then
  pass "--schema emits canonical envelope (bash scaffold)"
else fail "--schema envelope"; fi

# Test 5: --schema schema_version matches surface
if "$SCRIPT" --schema --json 2>/dev/null | jq -e '.schema_version | test("^rule-hint-lifecycle/v[0-9]+$")' >/dev/null; then
  pass "--schema schema_version matches rule-hint-lifecycle/v1 pattern"
else fail "--schema schema_version"; fi

# Test 6: --schema doctor surface
if "$SCRIPT" --schema doctor 2>/dev/null | jq -e '.command == "schema" and .surface == "doctor"' >/dev/null; then
  pass "--schema doctor emits surface-specific envelope"
else fail "--schema doctor"; fi

# Test 7: --examples envelope (NEW)
if "$SCRIPT" --examples --json 2>/dev/null | jq -e '.command == "examples" and (.examples | length > 0)' >/dev/null; then
  pass "--examples emits canonical envelope"
else fail "--examples envelope"; fi

# Test 8: --examples lists 5 (3 canonical + 2 python-positional)
if "$SCRIPT" --examples --json 2>/dev/null | jq -e '.examples | length >= 5' >/dev/null; then
  pass "--examples length >= 5"
else fail "--examples length"; fi

# Test 9: help <topic> for analyze
if "$SCRIPT" help analyze 2>/dev/null | grep -q 'topic: analyze'; then
  pass "help analyze returns topic header"
else fail "help analyze"; fi

# Test 10: help <topic> for schema (clarifies positional vs dash-flag)
if "$SCRIPT" help schema 2>/dev/null | grep -q 'topic: schema'; then
  pass "help schema returns topic header"
else fail "help schema"; fi

# Test 11: -h / --help shows merged usage
if "$SCRIPT" --help 2>/dev/null | grep -q 'rule-hint-lifecycle.sh'; then
  pass "--help shows usage"
else fail "--help usage"; fi

# Test 12: unknown canonical flag returns 64
"$SCRIPT" --bogus-canonical-flag-zzz --json >/dev/null 2>&1
rc=$?
if [[ "$rc" -ne 0 ]]; then
  pass "unknown canonical flag exits non-zero"
else
  fail "unknown canonical flag rc=$rc (expected non-zero)"
fi

# ========= python heredoc pass-through (positional subcommands) =========

# Test 13: positional `schema --json` STILL works (python; backward-compat for existing test:67)
if "$SCRIPT" schema --json 2>/dev/null | jq -e '(.commands | index("doctor")) and (.commands | index("repair")) and (.commands | index("why"))' >/dev/null; then
  pass "positional schema --json: .commands array preserved (python pass-through)"
else fail "positional schema pass-through"; fi

# Test 14: positional `examples --json` STILL works (python pass-through)
if "$SCRIPT" examples --json 2>/dev/null | jq -e '.' >/dev/null; then
  pass "positional examples --json reaches python"
else fail "positional examples pass-through"; fi

# Test 15: positional `doctor --json` STILL works (python pass-through)
if "$SCRIPT" doctor --json 2>/dev/null | jq -e '.action == "doctor" and has("candidates") and has("candidate_count")' >/dev/null; then
  pass "positional doctor --json: action + candidates + candidate_count preserved"
else fail "positional doctor pass-through"; fi

# Test 16: positional `quickstart --json` STILL works
if "$SCRIPT" quickstart --json 2>/dev/null | jq -e '.' >/dev/null; then
  pass "positional quickstart --json reaches python"
else fail "positional quickstart pass-through"; fi

# Test 17: positional `completion` reaches python (python's argparse doesn't
# accept extra positionals so we just check the subcommand routes through).
"$SCRIPT" completion 2>&1 | head -1 | grep -qE 'usage:|completion|action' && pass "positional completion reaches python" || fail "positional completion pass-through"

# Test 18: default action (no positional) reaches python analyzer
if "$SCRIPT" --json --window-days 1 2>/dev/null | jq -e '.' >/dev/null; then
  pass "default action (no positional) reaches python analyzer"
else fail "default action pass-through"; fi

# Test 19: dash flags do NOT collide with python's --repo / --rule-id flags
# (verifies --info early-dispatch fires before python sees --repo)
if "$SCRIPT" --info --json --repo /tmp/nonexistent 2>/dev/null | jq -e '.command == "info"' >/dev/null; then
  pass "--info wins over --repo arg (early-dispatch precedes python)"
else fail "early-dispatch ordering"; fi

# Test 20: --schema preserves AG3 fields (subcommands + intro_flags)
if "$SCRIPT" --schema --json 2>/dev/null \
  | jq -e '(.subcommands | index("analyze")) and (.subcommands | index("doctor")) and (.intro_flags | index("--info"))' >/dev/null; then
  pass "--schema default exposes subcommands + intro_flags"
else fail "--schema AG3 shape"; fi


if [[ "$fail_count" -gt 0 ]]; then
  printf 'SUMMARY pass=%d fail=%d\n' "$pass_count" "$fail_count" >&2
  exit 1
fi
printf 'SUMMARY pass=%d fail=0\n' "$pass_count"
