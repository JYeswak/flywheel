#!/usr/bin/env bash
# tests/caam-auto-rotate-on-usage-limit.py-canonical-cli-py.sh
# Canonical-cli surface tests for .flywheel/scripts/caam-auto-rotate-on-usage-limit.py (scaffolded by
# bead flywheel-oozt3 / scaffold-canonical-cli-py.sh; renamed .sh→.py by flywheel-eyqo7.1.1 2026-05-11).
#
# Verifies the python shim exposes canonical introspection without breaking
# the target's existing argparse subcommands.
set -uo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd -P)"
SCRIPT="$ROOT/.flywheel/scripts/caam-auto-rotate-on-usage-limit.py"

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
# flywheel-0pkcf calibration: caam-auto-rotate's argparse exits rc=3 when
# required args (--session/--pane/--digest) are missing — that's a native
# "missing_required" doctrinal exit code, not shim breakage. Accept rc<=3.
# Per feedback_calibrate_test_to_actual_contract META-RULE.
"$SCRIPT" 2>/dev/null >/dev/null; rc=$?
if [[ "$rc" -le 3 ]]; then
  pass "target default invocation rc <= 3 (no shim breakage; rc=3 is target's native missing_required)"
else fail "target default invocation rc=$rc (shim may have broken target)"; fi

# ---- Fillin-specific assertions (flywheel-0pkcf wave-1-agent-mail-1) ----

# Test 11 (load-bearing): doctor concrete checks (>=5 named substrate probes per AG5)
if "$SCRIPT" doctor --json 2>/dev/null \
    | python3 -c "import sys,json; d=json.load(sys.stdin); assert len(d['checks']) >= 5; assert all('name' in c and c['status'] in ('pass','warn','fail') for c in d['checks']); assert d['tool_focus'] == 'ntm'" 2>/dev/null; then
  pass "doctor returns >=5 named checks with tool_focus=ntm"
else fail "doctor concrete checks <5 or wrong shape"; fi

# Test 12 (load-bearing): doctor probes ntm_executable + python3_version_ok (load-bearing for rotate workflow)
if "$SCRIPT" doctor --json 2>/dev/null \
    | python3 -c "import sys,json; d=json.load(sys.stdin); names={c['name'] for c in d['checks']}; assert 'ntm_executable' in names; assert 'python3_version_ok' in names" 2>/dev/null; then
  pass "doctor probes ntm_executable + python3_version_ok (load-bearing for rotate)"
else fail "doctor missing load-bearing checks"; fi

# Test 13 (load-bearing): health binds audit log + reports total_runs + age_seconds
if "$SCRIPT" health --json 2>/dev/null \
    | python3 -c "import sys,json; d=json.load(sys.stdin); assert 'audit_log' in d; assert 'total_runs' in d; assert 'recent_runs' in d; assert d['status'] in ('pass','warn','fail')" 2>/dev/null; then
  pass "health binds audit_log + reports concrete totals"
else fail "health missing audit-log binding or totals"; fi

# Test 14 (load-bearing): why returns canonical state from {found, not_found, unavailable}
WHY_STATUS="$("$SCRIPT" why nonexistent-id-12345 2>/dev/null | python3 -c 'import sys,json; print(json.load(sys.stdin)["status"])' 2>/dev/null)"
case "$WHY_STATUS" in
  found|not_found|unavailable)
    pass "why returns canonical state ($WHY_STATUS)"
    ;;
  *)
    fail "why returned unexpected status: '$WHY_STATUS'"
    ;;
esac

if [[ "$fail_count" -gt 0 ]]; then
  printf 'SUMMARY pass=%d fail=%d\n' "$pass_count" "$fail_count" >&2
  exit 1
fi
printf 'SUMMARY pass=%d fail=0\n' "$pass_count"
