#!/usr/bin/env bash
# tests/test-3bfgw-polish-coupling.sh
#
# Regression test for flywheel-3bfgw (lib/polish.sh not auto-sourced from core.sh).
# Asserts polish.sh's public functions are callable when core.sh is the entry
# point, AND when bin/flywheel-loop's module-list loop is the entry point.

set -euo pipefail

CORE_SH="${CORE_SH:-$HOME/.claude/skills/.flywheel/lib/portable/core.sh}"
LIB_DIR="${LIB_DIR:-$HOME/.claude/skills/.flywheel/lib}"

[[ -f "$CORE_SH" ]] || { echo "FAIL core.sh missing: $CORE_SH" >&2; exit 1; }
[[ -d "$LIB_DIR" ]] || { echo "FAIL lib dir missing: $LIB_DIR" >&2; exit 1; }

pass(){ printf 'PASS %s\n' "$1"; }
fail(){ printf 'FAIL %s\n' "$1" >&2; exit 1; }

# 1. bash -n syntax check
bash -n "$CORE_SH" && pass "core.sh syntax-clean" || fail "core.sh bash -n failed"
bash -n "$LIB_DIR/polish.sh" && pass "lib/polish.sh syntax-clean" || fail "lib/polish.sh bash -n failed"

# 2. core.sh as entry: polish.sh public functions must be defined
for fn in polish_gate_doctor_json quality_bar_close_gate_doctor_json publishability_bar_doctor_json; do
  result=$(bash -c "source '$CORE_SH' && type $fn 2>&1 | head -1")
  if [[ "$result" == *"is a function"* ]]; then
    pass "core.sh entry → $fn defined"
  else
    fail "core.sh entry → $fn NOT defined (regression of flywheel-3bfgw fix); got: $result"
  fi
done

# 3. core.sh entry: portable_doctor itself still defined
result=$(bash -c "source '$CORE_SH' && type portable_doctor 2>&1 | head -1")
[[ "$result" == *"is a function"* ]] || fail "core.sh entry → portable_doctor NOT defined; got: $result"
pass "core.sh entry → portable_doctor defined"

# 4. core.sh entry: 01-arg-parse + 02-doctor-field-aggregator + 02-scoped-probes-pre + 03-scoped-probes-mid still wired
for fn in _portable_doctor_parse_args _portable_doctor_apply_field_aggregator _scoped_probe_run _scoped_probe_tick_hook_firing; do
  result=$(bash -c "source '$CORE_SH' && type $fn 2>&1 | head -1")
  [[ "$result" == *"is a function"* ]] || fail "core.sh entry → $fn NOT defined (Phase 6 regression?); got: $result"
done
pass "core.sh entry → all Phase 6 helpers defined"

# 5. bin/flywheel-loop module-list loop entry: polish.sh public functions defined (no regression)
modules="misc parse repo canonical mission render reconcile bead wire fuckup memory tentacle loop storage jeff daily agent fleet callback polish recovery doctor session print portable skill-discovery"
result=$(bash -c "
  source '$LIB_DIR/common.sh' 2>/dev/null
  for module in $modules; do
    source '$LIB_DIR/'\$module'.sh' 2>/dev/null
  done
  type polish_gate_doctor_json 2>&1 | head -1
")
[[ "$result" == *"is a function"* ]] \
  || fail "bin/flywheel-loop entry path regression: polish_gate_doctor_json NOT defined; got: $result"
pass "bin/flywheel-loop module-list entry → polish_gate_doctor_json still defined (no regression)"

# 6. Idempotent double-source: sourcing polish.sh twice doesn't error
bash -c "
  source '$LIB_DIR/polish.sh' 2>/dev/null
  source '$LIB_DIR/polish.sh' 2>/dev/null
  type polish_gate_doctor_json >/dev/null 2>&1
" || fail "polish.sh is not idempotent under double-source"
pass "polish.sh idempotent under double-source"

printf 'flywheel-3bfgw polish-coupling test passed (8 assertions)\n'
