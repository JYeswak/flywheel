#!/usr/bin/env bash
# tests/flywheel-readme-canonical-cli-py.sh
# Canonical-cli surface tests for /Users/josh/.claude/skills/.flywheel/bin/flywheel-readme (scaffolded by
# bead flywheel-oozt3 / scaffold-canonical-cli-py.sh).
#
# Verifies the python shim exposes canonical introspection without breaking
# the target's existing argparse subcommands.
set -uo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd -P)"
SCRIPT="/Users/josh/.claude/skills/.flywheel/bin/flywheel-readme"

pass_count=0
fail_count=0
pass() { pass_count=$((pass_count + 1)); printf 'PASS %s\n' "$1"; }
fail() { fail_count=$((fail_count + 1)); printf 'FAIL %s\n' "$1" >&2; }

# Test 1: python ast parse (syntax)
if python3 -c "import ast,sys; ast.parse(open('$SCRIPT','r',encoding='utf-8').read())" 2>/dev/null; then
  pass "python ast parse (syntax)"
else fail "python ast parse"; fi

# Test 2: --info envelope
if "$SCRIPT" --info 2>/dev/null | python3 -c "import sys,json; d=json.load(sys.stdin); assert d['command']=='info' and d.get('schema_version')" 2>/dev/null; then
  pass "--info emits canonical envelope"
else fail "--info envelope"; fi

# Test 3: --schema doctor
if "$SCRIPT" --schema doctor 2>/dev/null | python3 -c "import sys,json; d=json.load(sys.stdin); assert d['command']=='schema' and d['surface']=='doctor'" 2>/dev/null; then
  pass "--schema doctor emits canonical envelope"
else fail "--schema doctor envelope"; fi

# Test 4: --schema default
if "$SCRIPT" --schema 2>/dev/null | python3 -c "import sys,json; d=json.load(sys.stdin); assert d['command']=='schema'" 2>/dev/null; then
  pass "--schema default emits canonical envelope"
else fail "--schema default envelope"; fi

# Test 5: --examples envelope
if "$SCRIPT" --examples 2>/dev/null | python3 -c "import sys,json; d=json.load(sys.stdin); assert d['command']=='examples'" 2>/dev/null; then
  pass "--examples emits canonical envelope"
else fail "--examples envelope"; fi

# Test 6: audit envelope (scaffold stub)
if "$SCRIPT" audit 2>/dev/null | python3 -c "import sys,json; d=json.load(sys.stdin); assert d['command']=='audit' and 'audit_log' in d" 2>/dev/null; then
  pass "audit emits canonical envelope"
else fail "audit envelope"; fi

# Test 7: why <id> envelope (scaffold stub)
if "$SCRIPT" why some-id 2>/dev/null | python3 -c "import sys,json; d=json.load(sys.stdin); assert d['command']=='why' and d['id']=='some-id'" 2>/dev/null; then
  pass "why <id> emits canonical envelope"
else fail "why <id> envelope"; fi

# Test 8: quickstart envelope (scaffold stub)
if "$SCRIPT" quickstart 2>/dev/null | python3 -c "import sys,json; d=json.load(sys.stdin); assert d['command']=='quickstart'" 2>/dev/null; then
  pass "quickstart emits canonical envelope"
else fail "quickstart envelope"; fi

# Test 9: schema_version is <surface>/v1
if "$SCRIPT" --info 2>/dev/null | python3 -c "import sys,json,re; d=json.load(sys.stdin); assert re.match(r'^[A-Za-z0-9_-]+/v1$', d['schema_version'])" 2>/dev/null; then
  pass "schema_version matches <surface>/v1 pattern"
else fail "schema_version pattern"; fi

# Test 10: target's existing argparse still works (no canonical arg)
# A target without canonical args must still emit *something*. We probe
# stderr/exit-code only — semantics belong to the target.
"$SCRIPT" 2>/dev/null >/dev/null; rc=$?
if [[ "$rc" -le 2 ]]; then
  pass "target default invocation rc <= 2 (no shim breakage)"
else fail "target default invocation rc=$rc (shim may have broken target)"; fi

if [[ "$fail_count" -gt 0 ]]; then
  printf 'SUMMARY pass=%d fail=%d\n' "$pass_count" "$fail_count" >&2
  exit 1
fi
printf 'SUMMARY pass=%d fail=0\n' "$pass_count"
