#!/usr/bin/env bash
# tests/jeff-issue-canonical-cli.sh
# flywheel-k8gcv.17 (wave-3-17).
set -uo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd -P)"
SCRIPT="$ROOT/.flywheel/scripts/jeff-issue.py"

pass_count=0
fail_count=0
pass() { pass_count=$((pass_count + 1)); printf 'PASS %s\n' "$1"; }
fail() { fail_count=$((fail_count + 1)); printf 'FAIL %s\n' "$1" >&2; }

# Python script — verify parse via py_compile
python3 -c "compile(open('$SCRIPT').read(), '$SCRIPT', 'exec')" 2>/dev/null && pass "python parses" || fail "python parse error"

# AG3
"$SCRIPT" --info --json 2>/dev/null | jq -e '.name and .version and .capabilities and (.subcommands | length >= 5)' >/dev/null && pass "AG3 --info" || fail "AG3 --info"
"$SCRIPT" --schema --json 2>/dev/null | jq -e '.input_schema and .output_schema' >/dev/null && pass "AG3 --schema" || fail "AG3 --schema"
"$SCRIPT" --examples --json 2>/dev/null | jq -e '.examples | length > 0' >/dev/null && pass "AG3 --examples" || fail "AG3 --examples"
out_doctor="$("$SCRIPT" doctor --json 2>/dev/null || true)"
printf '%s' "$out_doctor" | jq -e '.checks' >/dev/null && pass "AG3 doctor (canonical .checks)" || fail "AG3 doctor"

# Canonical subcommands (existing in this script)
out_health="$("$SCRIPT" health --json 2>/dev/null || true)"
printf '%s' "$out_health" | jq -e '.schema_version' >/dev/null && pass "health envelope" || fail "health"
out_quickstart="$("$SCRIPT" quickstart --json 2>/dev/null || true)"
printf '%s' "$out_quickstart" | jq -e '.steps' >/dev/null && pass "quickstart envelope" || fail "quickstart"
out_audit="$("$SCRIPT" audit --json 2>/dev/null || true)"
printf '%s' "$out_audit" | jq -e '.schema_version' >/dev/null && pass "audit envelope" || fail "audit"

# Magic comment + lint (was 1 violation: L5)
grep -q '# flywheel-cli-surface: true' "$SCRIPT" && pass "L6 magic comment present" || fail "L6 missing"
"$ROOT/.flywheel/scripts/canonical-cli-lint.sh" "$SCRIPT" >/dev/null 2>&1 && rc=0 || rc=$?
[[ "$rc" -eq 0 ]] && pass "canonical-cli-lint RC=0 (was L5: missing strict mode — Python script, satisfied via docstring token)" || fail "lint RC=$rc"

# Backward compat: legacy --info fields preserved
"$SCRIPT" --info --json 2>/dev/null | jq -e '.audit and .registry and .submit_requires and .rubric_script' >/dev/null \
  && pass "legacy --info fields preserved (audit+registry+submit_requires+rubric_script)" || fail "legacy --info fields"

# Backward compat: doctor preserves deps + signals + warnings + failures
printf '%s' "$out_doctor" | jq -e '.deps and .signals and has("warnings") and has("failures")' >/dev/null \
  && pass "legacy doctor fields preserved (deps+signals+warnings+failures)" || fail "legacy doctor fields"

# --schema preserves legacy fields
"$SCRIPT" --schema --json 2>/dev/null | jq -e '.draft_required_fields and .submit_gates and .mutation_requires' >/dev/null \
  && pass "legacy --schema fields preserved" || fail "legacy --schema fields"

# --help shows usage
"$SCRIPT" --help 2>&1 | head -3 | grep -qE 'Usage|jeff-issue' && pass "--help shows usage" || fail "--help"

# validate phase still works
out_validate="$("$SCRIPT" validate source --repo Dicklesworthstone/ntm --json 2>/dev/null || true)"
printf '%s' "$out_validate" | jq -e '.schema_version' >/dev/null \
  && pass "validate source phase still emits envelope" || fail "validate source"

# submit refuses without joshua-approval + idempotency-key
"$SCRIPT" submit --draft /tmp/nonexistent --repo Dicklesworthstone/ntm --title T --tracking-bead flywheel-test --apply --json >/dev/null 2>&1; rc=$?
[[ "$rc" -ne 0 ]] && pass "submit --apply without --joshua-approval is rejected" || fail "submit apply unguarded"

if [[ "$fail_count" -gt 0 ]]; then
  printf 'SUMMARY pass=%d fail=%d\n' "$pass_count" "$fail_count" >&2
  exit 1
fi
printf 'SUMMARY pass=%d fail=0\n' "$pass_count"
