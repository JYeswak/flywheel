#!/usr/bin/env bash
# tests/jeff-intel-network-canonical-cli.sh
# flywheel-k8gcv.15 (wave-3-15).
set -uo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd -P)"
SCRIPT="$ROOT/.flywheel/scripts/jeff-intel-network.sh"

pass_count=0
fail_count=0
pass() { pass_count=$((pass_count + 1)); printf 'PASS %s\n' "$1"; }
fail() { fail_count=$((fail_count + 1)); printf 'FAIL %s\n' "$1" >&2; }

if bash -n "$SCRIPT" 2>/dev/null; then pass "syntax"; else fail "syntax"; fi

# AG3
"$SCRIPT" --info --json 2>/dev/null | jq -e '.name and .version and .capabilities and (.subcommands | length >= 5)' >/dev/null && pass "AG3 --info" || fail "AG3 --info"
"$SCRIPT" --schema --json 2>/dev/null | jq -e '.input_schema and .output_schema' >/dev/null && pass "AG3 --schema" || fail "AG3 --schema"
"$SCRIPT" --examples --json 2>/dev/null | jq -e '.examples | length > 0' >/dev/null && pass "AG3 --examples" || fail "AG3 --examples"
out_doctor="$("$SCRIPT" doctor --json 2>/dev/null || true)"
printf '%s' "$out_doctor" | jq -e '.checks' >/dev/null && pass "AG3 doctor (.checks)" || fail "AG3 doctor"

# Existing canonical subcommands
out_health="$("$SCRIPT" health --json 2>/dev/null || true)"
printf '%s' "$out_health" | jq -e 'has("schema_version")' >/dev/null && pass "health envelope" || fail "health"
out_validate="$("$SCRIPT" validate --json 2>/dev/null || true)"
printf '%s' "$out_validate" | jq -e 'has("schema_version")' >/dev/null && pass "validate envelope" || fail "validate"
out_audit="$("$SCRIPT" audit --json 2>/dev/null || true)"
printf '%s' "$out_audit" | jq -e 'has("schema_version")' >/dev/null && pass "audit envelope" || fail "audit"

# Magic comment + lint (was 1 violation: L6)
grep -q '# flywheel-cli-surface: true' "$SCRIPT" && pass "L6 magic comment present" || fail "L6 missing"
"$ROOT/.flywheel/scripts/canonical-cli-lint.sh" "$SCRIPT" >/dev/null 2>&1 && rc=0 || rc=$?
[[ "$rc" -eq 0 ]] && pass "canonical-cli-lint RC=0 (was L6 violation)" || fail "lint RC=$rc"

# Backward compat: legacy doctor body preserves deps + scheduled_runner + daily_ingest
out="$("$SCRIPT" doctor --json 2>/dev/null || true)"
printf '%s' "$out" | jq -e '.deps and .scheduled_runner and .daily_ingest and .paths and .exit_codes' >/dev/null \
  && pass "legacy doctor envelope fields preserved (deps + scheduled_runner + daily_ingest + paths + exit_codes)" || fail "legacy doctor fields"

# Legacy --doctor flag also routes to canonical doctor
out2="$("$SCRIPT" --doctor --json 2>/dev/null || true)"
printf '%s' "$out2" | jq -e '.checks' >/dev/null && pass "legacy --doctor flag emits .checks" || fail "legacy --doctor flag"

# --help shows usage
"$SCRIPT" --help 2>&1 | head -3 | grep -qE 'Usage|jeff-intel' && pass "--help shows usage" || fail "--help"

# completion still works
"$SCRIPT" completion 2>&1 | grep -q 'complete -W' && pass "completion preserved" || fail "completion"

# repair dry-run + apply paths preserved
"$SCRIPT" repair --scope state --dry-run --json 2>/dev/null | jq -e '.status == "dry_run"' >/dev/null \
  && pass "repair --dry-run preserved" || fail "repair dry-run"

# x-poll fixture mode (offline test) — exit may be non-zero, capture stdout first
out_x="$(JEFF_INTEL_X_FIXTURE=/dev/null "$SCRIPT" x-poll --dry-run --json 2>&1 || true)"
printf '%s' "$out_x" | head -1 | jq -e '.' >/dev/null 2>&1 \
  && pass "x-poll --dry-run emits JSON" || fail "x-poll dry-run"

if [[ "$fail_count" -gt 0 ]]; then
  printf 'SUMMARY pass=%d fail=%d\n' "$pass_count" "$fail_count" >&2
  exit 1
fi
printf 'SUMMARY pass=%d fail=0\n' "$pass_count"
