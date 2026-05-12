#!/usr/bin/env bash
# test-validate-callback-info-flag.sh
#
# flywheel-4x6pu regression: assert validate-callback.py exposes the
# canonical-cli-scoping introspection triad uniformly:
#   --help     (argparse default)
#   --info     (NEW: descriptive metadata)
#   --schema   (existing: output JSON schema)
#   --examples (existing: paste-able invocations)
#
# Per agent-ergonomics-cli-max R001 (close-validation gate, very high
# blast radius): the --info endpoint must be present and emit
# parseable JSON with stable schema_version + canonical_surfaces fields.

set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd -P)"
TOOL="${VALIDATE_CALLBACK_BIN:-$ROOT/.flywheel/scripts/validate-callback.py}"

pass_count=0
fail_count=0
pass() { printf 'PASS %s\n' "$1"; pass_count=$((pass_count + 1)); }
fail() { printf 'FAIL %s\n' "$1" >&2; fail_count=$((fail_count + 1)); }

if [[ ! -f "$TOOL" ]]; then
  printf 'SKIP validate-callback.py missing at %s\n' "$TOOL"
  exit 77
fi

# T1: --info exits 0
T1_RC=0
T1_OUT=$(python3 "$TOOL" --info 2>&1) || T1_RC=$?
if [[ "$T1_RC" -eq 0 ]]; then
  pass "T1 --info exits 0"
else
  fail "T1 --info failed (rc=$T1_RC)"
fi

# T2: --info --json emits parseable JSON
T2_OUT=$(python3 "$TOOL" --info --json 2>&1)
if printf '%s' "$T2_OUT" | jq -e '.tool == "validate-callback"' >/dev/null 2>&1; then
  pass "T2a --info --json emits parseable JSON with tool=validate-callback"
else
  fail "T2a --info --json output is not JSON or missing tool field"
fi
if printf '%s' "$T2_OUT" | jq -e '.schema_version' >/dev/null 2>&1; then
  pass "T2b --info --json includes schema_version field"
else
  fail "T2b --info --json missing schema_version"
fi
if printf '%s' "$T2_OUT" | jq -e '.canonical_surfaces.introspection | type == "array" and length >= 4' >/dev/null 2>&1; then
  pass "T2c --info --json lists 4+ introspection surfaces"
else
  fail "T2c --info --json canonical_surfaces.introspection not a 4+ array"
fi

# T3: --schema still works (no regression)
T3_RC=0
python3 "$TOOL" --schema --json 2>&1 | jq -e '.' >/dev/null 2>&1 || T3_RC=$?
if [[ "$T3_RC" -eq 0 ]]; then
  pass "T3 --schema still emits parseable JSON (no regression)"
else
  fail "T3 --schema regressed (rc=$T3_RC)"
fi

# T4: --examples still works (no regression)
T4_RC=0
python3 "$TOOL" --examples --json 2>&1 | jq -e '.examples | type == "array"' >/dev/null 2>&1 || T4_RC=$?
if [[ "$T4_RC" -eq 0 ]]; then
  pass "T4 --examples still emits parseable JSON with examples array (no regression)"
else
  fail "T4 --examples regressed (rc=$T4_RC)"
fi

# T5: --help still works (no regression)
T5_RC=0
python3 "$TOOL" --help >/dev/null 2>&1 || T5_RC=$?
if [[ "$T5_RC" -eq 0 ]]; then
  pass "T5 --help still exits 0"
else
  fail "T5 --help regressed (rc=$T5_RC)"
fi

# T6: --info --json includes doctrine pointer to flywheel-62mf9 audit
if python3 "$TOOL" --info --json 2>&1 | jq -e '.doctrine_pointers.agent_ergonomics_cli_max_audit | contains("flywheel-62mf9")' >/dev/null 2>&1; then
  pass "T6 --info --json includes doctrine pointer to flywheel-62mf9 audit"
else
  fail "T6 --info --json missing doctrine pointer"
fi

printf '\n=== test-validate-callback-info-flag.sh ===\n'
printf 'pass=%d fail=%d\n' "$pass_count" "$fail_count"
[[ "$fail_count" -eq 0 ]] && exit 0 || exit 1
