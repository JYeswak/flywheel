#!/usr/bin/env bash
# test-flywheel-loop-introspection-triad.sh
#
# flywheel-ss1bq regression: assert all three canonical introspection
# flags work uniformly on flywheel-loop:
#   --info     (descriptive, env vars + paths)
#   --schema   (machine-readable JSON schema for outputs)
#   --examples (paste-able invocation examples)
#
# Pre-fix: --schema flag returned "ERR: unknown argument" while
# `schema` subcommand worked. Per agent-ergonomics-cli-max R002,
# the canonical introspection triad MUST be uniformly accessible
# as flags.

set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd -P)"
TOOL="${FLYWHEEL_LOOP_BIN:-$HOME/.claude/skills/.flywheel/bin/flywheel-loop}"

pass_count=0
fail_count=0
pass() { printf 'PASS %s\n' "$1"; pass_count=$((pass_count + 1)); }
fail() { printf 'FAIL %s\n' "$1" >&2; fail_count=$((fail_count + 1)); }

if [[ ! -x "$TOOL" ]]; then
  printf 'SKIP flywheel-loop binary missing at %s\n' "$TOOL"
  exit 77
fi

# T1: --info flag works and emits non-empty output
T1_OUT=$("$TOOL" --info 2>&1)
T1_RC=$?
if [[ "$T1_RC" -eq 0 ]] && [[ -n "$T1_OUT" ]]; then
  pass "T1 --info exits 0 with non-empty output"
else
  fail "T1 --info failed (rc=$T1_RC, out_len=${#T1_OUT})"
fi

# T2: --schema flag works and emits parseable JSON
T2_OUT=$("$TOOL" --schema 2>&1)
T2_RC=$?
if [[ "$T2_RC" -eq 0 ]]; then
  pass "T2a --schema exits 0"
else
  fail "T2a --schema failed (rc=$T2_RC)"
fi
if printf '%s' "$T2_OUT" | jq -e '.schema_version' >/dev/null 2>&1; then
  pass "T2b --schema emits parseable JSON with schema_version field"
else
  fail "T2b --schema output is not JSON or missing schema_version"
fi

# T3: --examples flag works and emits non-empty output
T3_OUT=$("$TOOL" --examples 2>&1)
T3_RC=$?
if [[ "$T3_RC" -eq 0 ]] && [[ -n "$T3_OUT" ]]; then
  pass "T3 --examples exits 0 with non-empty output"
else
  fail "T3 --examples failed (rc=$T3_RC, out_len=${#T3_OUT})"
fi

# T4: --schema flag and `schema` subcommand emit equivalent output
# (parity check — they should both delegate to portable_schema)
T4_FLAG=$("$TOOL" --schema 2>&1 | jq -c '.schema_version' 2>/dev/null)
T4_SUB=$("$TOOL" schema 2>&1 | jq -c '.schema_version' 2>/dev/null)
if [[ "$T4_FLAG" == "$T4_SUB" ]] && [[ -n "$T4_FLAG" ]]; then
  pass "T4 --schema flag and schema subcommand emit equivalent schema_version"
else
  fail "T4 flag/subcommand parity broken: flag=$T4_FLAG sub=$T4_SUB"
fi

# T5: --help still works (no regression)
T5_RC=0
"$TOOL" --help >/dev/null 2>&1 || T5_RC=$?
if [[ "$T5_RC" -eq 0 ]]; then
  pass "T5 --help still exits 0 (no regression)"
else
  fail "T5 --help regressed (rc=$T5_RC)"
fi

printf '\n=== test-flywheel-loop-introspection-triad.sh ===\n'
printf 'pass=%d fail=%d\n' "$pass_count" "$fail_count"
[[ "$fail_count" -eq 0 ]] && exit 0 || exit 1
