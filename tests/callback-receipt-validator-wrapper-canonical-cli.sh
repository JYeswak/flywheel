#!/usr/bin/env bash
# tests/callback-receipt-validator-wrapper-canonical-cli.sh
# flywheel-1hshd.8 (wave-4-general-8). Surface is at
# ~/.claude/commands/flywheel/_shared/callback-receipt-validator-wrapper.sh
# (OUTSIDE this repo).
set -uo pipefail

SCRIPT="/Users/josh/.claude/commands/flywheel/_shared/callback-receipt-validator-wrapper.sh"
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd -P)"

pass_count=0
fail_count=0
pass() { pass_count=$((pass_count + 1)); printf 'PASS %s\n' "$1"; }
fail() { fail_count=$((fail_count + 1)); printf 'FAIL %s\n' "$1" >&2; }

if bash -n "$SCRIPT" 2>/dev/null; then pass "syntax"; else fail "syntax"; fi

# Canonical surfaces (all NEW — script had zero canonical-CLI surfaces pre-scaffold)
"$SCRIPT" --info --json 2>/dev/null | jq -e '.name and .version and (.subcommands | length >= 5)' >/dev/null && pass "--info AG3 fields" || fail "--info"
"$SCRIPT" --schema --json 2>/dev/null | jq -e '.command == "schema"' >/dev/null && pass "--schema envelope" || fail "--schema"
"$SCRIPT" --examples --json 2>/dev/null | jq -e '.examples | length > 0' >/dev/null && pass "--examples non-empty" || fail "--examples"
"$SCRIPT" doctor --json 2>/dev/null | jq -e '.command == "doctor" and (.checks | length >= 5)' >/dev/null && pass "doctor 5+ probes" || fail "doctor"
"$SCRIPT" health --json 2>/dev/null | jq -e '.command == "health"' >/dev/null && pass "health envelope" || fail "health"
"$SCRIPT" repair --scope none --dry-run --json 2>/dev/null | jq -e '.command == "repair" and .mode == "dry_run"' >/dev/null && pass "repair --dry-run" || fail "repair --dry-run"
"$SCRIPT" repair --scope none --apply --json >/dev/null 2>&1; rc=$?
[[ "$rc" -eq 3 ]] && pass "repair --apply rc=3" || fail "repair rc=$rc"
"$SCRIPT" validate --json 2>/dev/null | jq -e '.command == "validate"' >/dev/null && pass "validate envelope" || fail "validate"
"$SCRIPT" audit --json 2>/dev/null | jq -e '.command == "audit"' >/dev/null && pass "audit envelope" || fail "audit"
"$SCRIPT" why some-id 2>/dev/null | jq -e '.command == "why"' >/dev/null && pass "why envelope" || fail "why"
"$SCRIPT" help repair 2>/dev/null | grep -q 'topic:' && pass "help repair" || fail "help"
"$SCRIPT" quickstart 2>/dev/null | jq -e '.command == "quickstart"' >/dev/null && pass "quickstart" || fail "quickstart"

# Fillin-specific
"$SCRIPT" doctor --json 2>/dev/null | jq -e '(.checks[] | select(.name == "validator_executable")) and (.checks[] | select(.name == "audit_log_writable"))' >/dev/null && pass "doctor: validator_executable + audit_log_writable probes" || fail "doctor probes"
"$SCRIPT" repair --scope validator-prime --dry-run --json 2>/dev/null | jq -e '.scope == "validator-prime" and has("validator")' >/dev/null && pass "repair validator-prime non-stub" || fail "repair scope-specific"
"$SCRIPT" validate --validator 2>/dev/null | jq -e '.subject == "validator" and has("validator")' >/dev/null && pass "validate --validator subject" || fail "validate validator"
"$SCRIPT" validate --row-json='{"schema_version":"x","command":"info","status":"pass"}' 2>/dev/null | jq -e '.valid == true' >/dev/null && pass "validate --row-json schema" || fail "validate row"

# Backward-compat: original wrapper still works (stdin → VALIDATOR delegation)
echo "DONE flywheel-test malformed" | "$SCRIPT" --dispatch-file /tmp/dispatch_test.md >/dev/null 2>&1
rc=$?
# Wrapper exits 0/1/2 depending on validator response. We're piping a malformed
# callback so we expect non-zero (1 BLOCK or 2 UNVERIFIABLE). Either is OK —
# what matters is the wrapper dispatched to the validator.
[[ "$rc" -eq 1 || "$rc" -eq 2 ]] && pass "BACKWARD-COMPAT wrapper delegates to validator (rc=1 BLOCK or rc=2 UNVERIFIABLE)" || fail "wrapper delegation rc=$rc"

# Wrapper rejects missing --dispatch-file
"$SCRIPT" --json >/dev/null 2>&1; rc=$?
[[ "$rc" -eq 2 ]] && pass "wrapper rejects missing --dispatch-file (rc=2 usage error)" || fail "missing dispatch-file rc=$rc"

# Magic comment + lint
grep -q '# flywheel-cli-surface: true' "$SCRIPT" && pass "L6 magic comment present" || fail "L6 missing"
"$ROOT/.flywheel/scripts/canonical-cli-lint.sh" "$SCRIPT" >/dev/null 2>&1 && rc=0 || rc=$?
[[ "$rc" -eq 0 ]] && pass "canonical-cli-lint RC=0" || fail "lint RC=$rc"

# --help shows usage
"$SCRIPT" --help 2>&1 | head -3 | grep -qE 'usage:|callback-receipt-validator-wrapper' && pass "--help shows usage" || fail "--help"


if [[ "$fail_count" -gt 0 ]]; then
  printf 'SUMMARY pass=%d fail=%d\n' "$pass_count" "$fail_count" >&2
  exit 1
fi
printf 'SUMMARY pass=%d fail=0\n' "$pass_count"
