#!/usr/bin/env bash
# tests/bcv-task-harness-canonical-cli.sh — flywheel-1hshd.6 (wave-4-general-6)
set -uo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd -P)"
SCRIPT="$ROOT/.flywheel/scripts/bcv-task-harness.sh"

pass_count=0
fail_count=0
pass() { pass_count=$((pass_count + 1)); printf 'PASS %s\n' "$1"; }
fail() { fail_count=$((fail_count + 1)); printf 'FAIL %s\n' "$1" >&2; }

if bash -n "$SCRIPT" 2>/dev/null; then pass "syntax"; else fail "syntax"; fi

# NEW no-dash subcommands
"$SCRIPT" doctor --json 2>/dev/null | jq -e '.command == "doctor" and (.checks | length >= 5)' >/dev/null && pass "doctor 5+ probes" || fail "doctor"
"$SCRIPT" health --json 2>/dev/null | jq -e '.command == "health"' >/dev/null && pass "health envelope" || fail "health"
"$SCRIPT" repair --scope none --dry-run --json 2>/dev/null | jq -e '.command == "repair" and .mode == "dry_run"' >/dev/null && pass "repair --dry-run" || fail "repair --dry-run"
"$SCRIPT" repair --scope none --apply --json >/dev/null 2>&1; rc=$?
[[ "$rc" -eq 3 ]] && pass "repair --apply rc=3" || fail "repair rc=$rc"
"$SCRIPT" validate --json 2>/dev/null | jq -e '.command == "validate"' >/dev/null && pass "validate envelope" || fail "validate"
"$SCRIPT" audit --json 2>/dev/null | jq -e '.command == "audit"' >/dev/null && pass "audit envelope" || fail "audit"
"$SCRIPT" why some-id 2>/dev/null | jq -e '.command == "why"' >/dev/null && pass "why envelope" || fail "why"
"$SCRIPT" help repair 2>/dev/null | grep -q 'topic:' && pass "help repair" || fail "help"

# Fillin-specific
"$SCRIPT" doctor --json 2>/dev/null | jq -e '(.checks | any(.name == "jq_on_path")) and (any(.checks[]; .name == "shasum_on_path")) and (any(.checks[]; .name == "bcv_skill_dir_present"))' >/dev/null && pass "doctor: jq + shasum + bcv_skill_dir probes" || fail "doctor substrate"
"$SCRIPT" repair --scope skill-dir-prime --dry-run --json 2>/dev/null | jq -e '.scope == "skill-dir-prime" and has("skill_dir")' >/dev/null && pass "repair skill-dir-prime non-stub" || fail "repair scope-specific"
"$SCRIPT" validate --row-json='{"tool":"bcv","version":"v1","status":"ok"}' 2>/dev/null | jq -e '.valid == true' >/dev/null && pass "validate --row-json schema" || fail "validate row"
"$SCRIPT" validate --audit-log 2>/dev/null | jq -e '.subject == "audit-log" and has("audit_log")' >/dev/null && pass "validate --audit-log probe" || fail "validate audit-log"

# Legacy backward-compat
"$SCRIPT" --info --json 2>/dev/null | jq -e '.tool == "bcv-task-harness.sh" and has("exit_codes")' >/dev/null && pass "BACKWARD-COMPAT --info preserved" || fail "--info backward-compat"
"$SCRIPT" --schema --json 2>/dev/null | jq -e '.tool == "bcv-task-harness.sh" and has("validation_passed")' >/dev/null && pass "BACKWARD-COMPAT --schema preserved" || fail "--schema backward-compat"
"$SCRIPT" --examples --json 2>/dev/null | head -1 | grep -qE '\{|#|bcv-task' && pass "BACKWARD-COMPAT --examples reachable" || fail "--examples"

# Legacy --apply rc=3 (escape pipefail — script returns 3 by design)
out="$("$SCRIPT" --apply --beads abc 2>&1 || true)"
printf '%s' "$out" | head -1 | jq -e '.status == "refused"' >/dev/null && pass "BACKWARD-COMPAT legacy --apply rc=3 envelope" || fail "legacy --apply gate"
"$SCRIPT" --apply --beads abc >/dev/null 2>&1; rc=$?
[[ "$rc" -eq 3 ]] && pass "BACKWARD-COMPAT legacy --apply exit rc=3" || fail "legacy --apply rc=$rc"

# Magic comment + lint
grep -q '# flywheel-cli-surface: true' "$SCRIPT" && pass "L6 magic comment present" || fail "L6 missing"
"$ROOT/.flywheel/scripts/canonical-cli-lint.sh" "$SCRIPT" >/dev/null 2>&1 && rc=0 || rc=$?
[[ "$rc" -eq 0 ]] && pass "canonical-cli-lint RC=0 (was RC=1)" || fail "lint RC=$rc"

# --help shows usage
"$SCRIPT" --help 2>&1 | head -3 | grep -qE 'Usage|bcv-task' && pass "--help shows usage" || fail "--help"

if [[ "$fail_count" -gt 0 ]]; then
  printf 'SUMMARY pass=%d fail=%d\n' "$pass_count" "$fail_count" >&2
  exit 1
fi
printf 'SUMMARY pass=%d fail=0\n' "$pass_count"
