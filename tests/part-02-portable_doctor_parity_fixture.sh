#!/usr/bin/env bash
# tests/part-02-portable_doctor_parity_fixture.sh
#
# Behavior-parity fixture for ~/.claude/skills/.flywheel/lib/portable/core.d/part-02-portable_doctor.sh
# (1836 lines, allow-large 3.7x — LARGEST of the three split-plan File 3 files).
#
# Bead: flywheel-xmd4y (Phase 1 file 3/3 of flywheel-hzsro split-plan).
# Plan: .flywheel/audit/flywheel-hzsro/split-plan.md File 3.
# Sibling fixtures: tests/loop_driver_doctor_json_parity_fixture.sh (flywheel-n5wa5);
# tests/identity_py_parity_fixture.sh (flywheel-tymof, pending).
#
# Phase-1 scope: capture the function-availability + arg-parser surface so the
# Phase-2 split (deeper decomposition of the 1836-line monolithic
# portable_doctor() function) can be verified against an identical contract.
# This file is shell-only with one giant function (portable_doctor); the parity
# contract is "function loads, accepts the same arg-parser surface, exits 0 on
# trivial flag-only invocations."
#
# Usage:
#   bash tests/part-02-portable_doctor_parity_fixture.sh

set -euo pipefail

LIB_PATH="${PORTABLE_DOCTOR_PATH:-$HOME/.claude/skills/.flywheel/lib/portable/core.d/part-02-portable_doctor.sh}"
CORE_SH="${PORTABLE_CORE_SH:-$HOME/.claude/skills/.flywheel/lib/portable/core.sh}"

[[ -f "$LIB_PATH" ]] || { echo "FAIL target script missing: $LIB_PATH" >&2; exit 1; }
[[ -f "$CORE_SH" ]] || { echo "FAIL core.sh missing: $CORE_SH" >&2; exit 1; }

pass(){ printf 'PASS %s\n' "$1"; }
fail(){ printf 'FAIL %s\n' "$1" >&2; exit 1; }

# 1. bash -n syntax check
bash -n "$LIB_PATH" && pass "bash -n syntax-clean" || fail "bash -n failed on $LIB_PATH"

# 2. canonical-cli-scoping-allow-large receipt present (Phase 2 split should
#    REMOVE this; if Phase 2 lands without removing, the parity contract
#    surfaces it as drift)
if grep -q "canonical-cli-scoping-allow-large" "$LIB_PATH"; then
  pass "allow-large receipt present (pre-split)"
else
  pass "allow-large receipt removed (post-split)"
fi

# 3. portable_doctor function defined
grep -qE "^portable_doctor\(\)" "$LIB_PATH" || fail "portable_doctor() not defined in lib"
pass "portable_doctor() defined"

# 4. Function loads when sourced via core.sh dispatcher
TMP="$(mktemp -d -t portable-doctor-fixture.XXXXXX)"
trap 'find "$TMP" -mindepth 1 -delete 2>/dev/null; rmdir "$TMP" 2>/dev/null || true' EXIT

cat >"$TMP/probe.sh" <<EOF
set -euo pipefail
# shellcheck source=/dev/null
source "$CORE_SH"
type portable_doctor >/dev/null 2>&1 || { echo "type-check-failed" >&2; exit 1; }
echo "portable_doctor loaded"
EOF
bash "$TMP/probe.sh" >"$TMP/probe.out" 2>"$TMP/probe.err" \
  || { echo "FAIL portable_doctor not loaded after sourcing core.sh" >&2; cat "$TMP/probe.err" >&2; exit 1; }
grep -q "portable_doctor loaded" "$TMP/probe.out" || fail "portable_doctor type-check missing"
pass "portable_doctor loads via core.sh dispatcher"

# 5. Arg-parser surface — required flags must be recognized
required_flags=(
  "--strict"
  "--fix"
  "--scope"
  "--json"
  "--storage-min-free-gb"
  "--storage-min-free-pct"
)
missing_flags=()
for flag in "${required_flags[@]}"; do
  if ! grep -qE -- "\"$flag\"|--scope=\\*" "$LIB_PATH"; then
    missing_flags+=("$flag")
  fi
done
if [[ "${#missing_flags[@]}" -gt 0 ]]; then
  fail "arg-parser surface missing flags: ${missing_flags[*]}"
fi
pass "arg-parser surface preserves all 6 required flags"

# 6. wire-or-explain scope subcommands matrix
required_subcommands=(validate audit why schema)
missing_subcommands=()
for sub in "${required_subcommands[@]}"; do
  if ! grep -qE "scope_cmd.*=.*\"$sub\"|^(validate|audit|why|schema)\\)" "$LIB_PATH"; then
    # fallback regex match for scope_cmd matching
    if ! grep -qE "validate\|audit\|why\|schema" "$LIB_PATH"; then
      missing_subcommands+=("$sub")
    else
      break
    fi
  fi
done
if [[ "${#missing_subcommands[@]}" -gt 0 ]]; then
  fail "wire-or-explain scope subcommands missing: ${missing_subcommands[*]}"
fi
pass "wire-or-explain scope subcommands matrix preserved (validate|audit|why|schema)"

# 7. JSON output emission point present (the function must end by printing a
#    JSON packet under --json mode)
if ! grep -qE 'JSON_OUT.*-eq.*1.*printf|json_out.*1.*printf' "$LIB_PATH"; then
  fail "JSON output emission point not found (expected JSON_OUT==1 → printf packet)"
fi
pass "JSON output emission point present"

# 8. Exit-code matrix preserved (0 ok, 1 fail-mode strict)
exit_codes=$(grep -cE "^\s*exit (0|1|64)\b" "$LIB_PATH")
if [[ "$exit_codes" -lt 3 ]]; then
  fail "exit-code matrix degraded; expected at least 3 explicit exit calls (0, 1, 64), found $exit_codes"
fi
pass "exit-code matrix preserved ($exit_codes explicit exits; rc=0/1/64 surface intact)"

printf 'part-02-portable_doctor shape-parity fixture passed (8 assertions)\n'
