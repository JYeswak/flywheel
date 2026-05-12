#!/usr/bin/env bash
# test-tmp-aggressive-prune-introspection.sh
#
# flywheel-hzij2 regression: assert tmp-aggressive-prune.sh exposes
# the canonical-cli-scoping introspection triad uniformly:
#   --help     (existing, comment-block)
#   --info     (NEW: JSON metadata + canonical_surfaces taxonomy)
#   --schema   (NEW: output schema for both dry-run and apply modes)
#   --examples (NEW: paste-able invocations)
#
# Per agent-ergonomics-cli-max R001, this 189-line script needed full
# introspection triad. Audit was stale (claimed --examples already
# present); all three were actually missing.

set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd -P)"
TOOL="${TMP_AGGRESSIVE_PRUNE_BIN:-$ROOT/.flywheel/scripts/tmp-aggressive-prune.sh}"

pass_count=0
fail_count=0
pass() { printf 'PASS %s\n' "$1"; pass_count=$((pass_count + 1)); }
fail() { printf 'FAIL %s\n' "$1" >&2; fail_count=$((fail_count + 1)); }

if [[ ! -f "$TOOL" ]]; then
  printf 'SKIP tmp-aggressive-prune.sh missing at %s\n' "$TOOL"
  exit 77
fi

# T1: --help still works (no regression; existing surface)
T1_RC=0
"$TOOL" --help >/dev/null 2>&1 || T1_RC=$?
if [[ "$T1_RC" -eq 0 ]]; then
  pass "T1 --help exits 0"
else
  fail "T1 --help failed (rc=$T1_RC)"
fi

# T2: --info emits parseable JSON with required fields
T2_OUT=$("$TOOL" --info 2>&1)
if printf '%s' "$T2_OUT" | jq -e '.tool == "tmp-aggressive-prune"' >/dev/null 2>&1; then
  pass "T2a --info emits JSON with tool=tmp-aggressive-prune"
else
  fail "T2a --info output is not JSON or missing tool field"
fi
if printf '%s' "$T2_OUT" | jq -e '.schema_version' >/dev/null 2>&1; then
  pass "T2b --info includes schema_version field"
else
  fail "T2b --info missing schema_version"
fi
if printf '%s' "$T2_OUT" | jq -e '.canonical_surfaces.introspection | type == "array" and length >= 4' >/dev/null 2>&1; then
  pass "T2c --info lists 4+ introspection surfaces"
else
  fail "T2c --info canonical_surfaces.introspection not 4+ array"
fi
if printf '%s' "$T2_OUT" | jq -e '.safety_gates | type == "array" and length >= 1' >/dev/null 2>&1; then
  pass "T2d --info lists safety_gates (apply gating, mutex, deny-list)"
else
  fail "T2d --info missing safety_gates"
fi

# T3: --schema emits parseable JSON with output_modes for dry-run + apply
T3_OUT=$("$TOOL" --schema 2>&1)
if printf '%s' "$T3_OUT" | jq -e '.schema_version == "tmp-aggressive-prune.v1"' >/dev/null 2>&1; then
  pass "T3a --schema emits canonical schema_version"
else
  fail "T3a --schema schema_version mismatch"
fi
if printf '%s' "$T3_OUT" | jq -e '.output_modes | type == "array" and length == 2' >/dev/null 2>&1; then
  pass "T3b --schema describes both dry-run and apply output modes"
else
  fail "T3b --schema output_modes not 2-array"
fi
if printf '%s' "$T3_OUT" | jq -e '.exit_codes."0" == "success" and .exit_codes."1" == "lock_conflict" and .exit_codes."2" == "validation_failure"' >/dev/null 2>&1; then
  pass "T3c --schema documents stable exit codes 0/1/2"
else
  fail "T3c --schema exit_codes mismatch"
fi

# T4: --examples emits non-empty paste-able invocations
T4_OUT=$("$TOOL" --examples 2>&1)
if [[ -n "$T4_OUT" ]] && printf '%s' "$T4_OUT" | grep -q "tmp-aggressive-prune.sh"; then
  pass "T4 --examples emits non-empty output with tool name"
else
  fail "T4 --examples output empty or missing tool reference"
fi

# T5: --dry-run still works (no regression; the actual operational mode)
T5_RC=0
"$TOOL" --dry-run --root=/tmp >/dev/null 2>&1 || T5_RC=$?
if [[ "$T5_RC" -eq 0 ]]; then
  pass "T5 --dry-run --root=/tmp still exits 0 (no regression)"
else
  fail "T5 --dry-run regressed (rc=$T5_RC)"
fi

# T6: unknown args still error (no regression in arg parsing)
T6_RC=0
"$TOOL" --bogus-flag >/dev/null 2>&1 || T6_RC=$?
if [[ "$T6_RC" -eq 2 ]]; then
  pass "T6 unknown args still exit 2 (validation failure)"
else
  fail "T6 unknown arg behavior regressed (rc=$T6_RC)"
fi

printf '\n=== test-tmp-aggressive-prune-introspection.sh ===\n'
printf 'pass=%d fail=%d\n' "$pass_count" "$fail_count"
[[ "$fail_count" -eq 0 ]] && exit 0 || exit 1
