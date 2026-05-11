#!/usr/bin/env bash
# tests/callback-envelope-schema-validator-canonical-cli.sh
# flywheel-1hshd.7 (wave-4-general-7): --schema dash flag + magic comment.
set -uo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd -P)"
SCRIPT="$ROOT/.flywheel/scripts/callback-envelope-schema-validator.sh"

pass_count=0
fail_count=0
pass() { pass_count=$((pass_count + 1)); printf 'PASS %s\n' "$1"; }
fail() { fail_count=$((fail_count + 1)); printf 'FAIL %s\n' "$1" >&2; }

if bash -n "$SCRIPT" 2>/dev/null; then pass "syntax"; else fail "syntax"; fi

# NEW --schema dash flag — gap closed by 1hshd.7
"$SCRIPT" --schema --json 2>/dev/null | jq -e '.schema_version' >/dev/null && pass "--schema --json NEW dash flag" || fail "--schema dash flag"
"$SCRIPT" --schema envelope --json 2>/dev/null | jq -e '.schema_version' >/dev/null && pass "--schema envelope topic" || fail "--schema envelope"
"$SCRIPT" --schema ledger --json 2>/dev/null | jq -e '.required_fields | length > 0' >/dev/null && pass "--schema ledger emits ledger-specific fields" || fail "--schema ledger"
"$SCRIPT" --schema=doctor --json 2>/dev/null | jq -e '.schema_version' >/dev/null && pass "--schema=doctor= form" || fail "--schema= form"

# Legacy positional schema preserved
"$SCRIPT" schema envelope --json 2>/dev/null | jq -e '.schema_version' >/dev/null && pass "BACKWARD-COMPAT positional schema envelope" || fail "positional schema"
"$SCRIPT" schema ledger --json 2>/dev/null | jq -e '.required_fields' >/dev/null && pass "BACKWARD-COMPAT positional schema ledger" || fail "positional schema ledger"

# Existing canonical surfaces unchanged
"$SCRIPT" --info --json 2>/dev/null | jq -e '.name and .version' >/dev/null && pass "--info AG3 fields" || fail "--info"
"$SCRIPT" --examples --json 2>/dev/null | jq -e '.examples // .' >/dev/null && pass "--examples reachable" || fail "--examples"
# Wrap in command substitution to escape pipefail; doctor/health may return
# non-zero exit when substrate has violations (status: "error" by design).
out="$("$SCRIPT" doctor --json 2>/dev/null || true)"
printf '%s' "$out" | jq -e 'has("status") and has("schema_version")' >/dev/null && pass "doctor --json envelope" || fail "doctor"
out="$("$SCRIPT" --doctor --json 2>/dev/null || true)"
printf '%s' "$out" | jq -e 'has("status")' >/dev/null && pass "--doctor (legacy dash) still works" || fail "--doctor"
out="$("$SCRIPT" health --json 2>/dev/null || true)"
printf '%s' "$out" | jq -e 'has("schema_version")' >/dev/null && pass "health envelope" || fail "health"
"$SCRIPT" repair --scope ledger --dry-run --json 2>/dev/null | jq -e 'has("schema_version") or has("planned_actions")' >/dev/null && pass "repair --dry-run reachable" || fail "repair --dry-run"
"$SCRIPT" audit --json 2>/dev/null | jq -e 'has("schema_version")' >/dev/null && pass "audit reachable" || fail "audit"
"$SCRIPT" why composite_score --json 2>/dev/null | jq -e 'has("schema_version") or has("explanation")' >/dev/null && pass "why <field> reachable" || fail "why"
"$SCRIPT" quickstart --json 2>/dev/null | jq -e 'has("steps") or has("mode")' >/dev/null && pass "quickstart reachable" || fail "quickstart"
# validate envelope returns rc=1 on invalid envelope (by design); escape pipefail
out="$("$SCRIPT" validate envelope --callback-envelope 'quality_bar_passed=yes composite_score=9 jeff_score=9 donella_score=9 joshua_score=9 rust/python_clean=n/a cli_canonical=yes readme_quality=n/a' --json 2>/dev/null || true)"
printf '%s' "$out" | jq -e 'has("schema_version") or has("valid")' >/dev/null && pass "validate envelope --callback-envelope dispatched" || fail "validate envelope"

# Magic comment + lint
grep -q '# flywheel-cli-surface: true' "$SCRIPT" && pass "L6 magic comment present" || fail "L6 missing"
"$ROOT/.flywheel/scripts/canonical-cli-lint.sh" "$SCRIPT" >/dev/null 2>&1 && rc=0 || rc=$?
[[ "$rc" -eq 0 ]] && pass "canonical-cli-lint RC=0" || fail "lint RC=$rc"

# repair --apply reachable (this script's repair path executes immediately on --apply
# without the rc=3 idempotency-key gate that wave-2 surfaces have — that gate exists
# on validate envelope --apply path here instead). Test that repair dispatches.
"$SCRIPT" repair --scope ledger --apply --json 2>/dev/null | jq -e 'has("schema_version") and .scope == "ledger"' >/dev/null && pass "repair --scope ledger --apply reachable" || fail "repair --apply dispatch"

# --help shows usage
"$SCRIPT" --help 2>&1 | head -3 | grep -qE 'usage:|callback-envelope-schema' && pass "--help shows usage" || fail "--help"


if [[ "$fail_count" -gt 0 ]]; then
  printf 'SUMMARY pass=%d fail=%d\n' "$pass_count" "$fail_count" >&2
  exit 1
fi
printf 'SUMMARY pass=%d fail=0\n' "$pass_count"
