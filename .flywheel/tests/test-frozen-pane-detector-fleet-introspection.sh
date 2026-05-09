#!/usr/bin/env bash
# test-frozen-pane-detector-fleet-introspection.sh
#
# flywheel-ecujm regression: assert frozen-pane-detector-fleet.sh
# exposes the canonical-cli-scoping introspection triad+1 uniformly:
#   --help     (existing)
#   --info     (existing)
#   --schema   (NEW: was only `schema` subcommand pre-fix)
#   --examples (existing)
#
# Per agent-ergonomics-cli-max R001, this 492-line fleet liveness
# watchdog needed --schema flag parity with the schema subcommand.
# Audit was stale (claimed --examples missing too; --examples actually
# works as flag).

set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd -P)"
TOOL="${FROZEN_PANE_DETECTOR_FLEET_BIN:-$ROOT/.flywheel/scripts/frozen-pane-detector-fleet.sh}"

pass_count=0
fail_count=0
pass() { printf 'PASS %s\n' "$1"; pass_count=$((pass_count + 1)); }
fail() { printf 'FAIL %s\n' "$1" >&2; fail_count=$((fail_count + 1)); }

if [[ ! -f "$TOOL" ]]; then
  printf 'SKIP frozen-pane-detector-fleet.sh missing at %s\n' "$TOOL"
  exit 77
fi

# T1: --help still works
T1_RC=0
"$TOOL" --help >/dev/null 2>&1 || T1_RC=$?
[[ "$T1_RC" -eq 0 ]] && pass "T1 --help exits 0" || fail "T1 --help failed (rc=$T1_RC)"

# T2: --info emits parseable JSON
T2_OUT=$("$TOOL" --info 2>&1)
if printf '%s' "$T2_OUT" | jq -e '.schema_version' >/dev/null 2>&1; then
  pass "T2 --info emits JSON with schema_version"
else
  fail "T2 --info missing schema_version"
fi

# T3: --schema flag works (the actual fix)
T3_OUT=$("$TOOL" --schema 2>&1)
T3_RC=$?
if [[ "$T3_RC" -eq 0 ]]; then
  pass "T3a --schema flag exits 0 (was failing pre-fix)"
else
  fail "T3a --schema flag failed (rc=$T3_RC)"
fi
if printf '%s' "$T3_OUT" | jq -e '.schema_version == "frozen-pane-detector-fleet.v1"' >/dev/null 2>&1; then
  pass "T3b --schema emits canonical schema_version"
else
  fail "T3b --schema schema_version mismatch"
fi

# T4: --schema flag and `schema` subcommand parity
T4_FLAG=$("$TOOL" --schema 2>&1 | jq -r '.schema_version' 2>/dev/null)
T4_SUB=$("$TOOL" schema 2>&1 | jq -r '.schema_version' 2>/dev/null)
if [[ "$T4_FLAG" == "$T4_SUB" ]] && [[ -n "$T4_FLAG" ]]; then
  pass "T4 --schema flag and schema subcommand parity (both emit $T4_FLAG)"
else
  fail "T4 flag/subcommand parity broken: flag=$T4_FLAG sub=$T4_SUB"
fi

# T5: --examples still works (no regression)
T5_RC=0
"$TOOL" --examples >/dev/null 2>&1 || T5_RC=$?
[[ "$T5_RC" -eq 0 ]] && pass "T5 --examples still exits 0 (no regression)" || fail "T5 --examples regressed (rc=$T5_RC)"

# T6: --doctor still works (operational mode no-regression)
T6_RC=0
"$TOOL" --doctor --json >/dev/null 2>&1 || T6_RC=$?
[[ "$T6_RC" -eq 0 ]] && pass "T6 --doctor --json still exits 0 (no regression)" || fail "T6 --doctor regressed (rc=$T6_RC)"

printf '\n=== test-frozen-pane-detector-fleet-introspection.sh ===\n'
printf 'pass=%d fail=%d\n' "$pass_count" "$fail_count"
[[ "$fail_count" -eq 0 ]] && exit 0 || exit 1
