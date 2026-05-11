#!/usr/bin/env bash
# tests/callback-spool-reap-canonical-cli.sh
# flywheel-1hshd.10 (wave-4-general-10).
set -uo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd -P)"
SCRIPT="$ROOT/.flywheel/scripts/callback-spool-reap.sh"

pass_count=0
fail_count=0
pass() { pass_count=$((pass_count + 1)); printf 'PASS %s\n' "$1"; }
fail() { fail_count=$((fail_count + 1)); printf 'FAIL %s\n' "$1" >&2; }

if bash -n "$SCRIPT" 2>/dev/null; then pass "syntax"; else fail "syntax"; fi

# NEW canonical surfaces
"$SCRIPT" --schema --json 2>/dev/null | jq -e '.schema_version' >/dev/null && pass "--schema --json NEW dash flag" || fail "--schema"
"$SCRIPT" --info --json 2>/dev/null | jq -e '.name == "callback-spool-reap.sh" and .version and (.subcommands | length >= 5) and .idempotency_key_required_for_apply == true' >/dev/null && pass "--info AG3 fields + apply contract field" || fail "--info AG3"
"$SCRIPT" health --json 2>/dev/null | jq -e '.command == "health" and has("pending") and has("archived")' >/dev/null && pass "health NEW: pending+archived counts" || fail "health"
"$SCRIPT" repair --scope archive-rotate --dry-run --json 2>/dev/null | jq -e '.command == "repair" and .scope == "archive-rotate"' >/dev/null && pass "repair archive-rotate NEW" || fail "repair archive-rotate"
"$SCRIPT" repair --scope spool-prime --dry-run --json 2>/dev/null | jq -e '.scope == "spool-prime" and has("spool_dir")' >/dev/null && pass "repair spool-prime NEW" || fail "repair spool-prime"
"$SCRIPT" repair --scope none --apply --json >/dev/null 2>&1; rc=$?
[[ "$rc" -eq 3 ]] && pass "repair --apply without --idempotency-key returns rc=3" || fail "repair rc=$rc"
"$SCRIPT" --apply --json >/dev/null 2>&1; rc=$?
[[ "$rc" -eq 3 ]] && pass "default-mode --apply without --idempotency-key returns rc=3" || fail "default --apply rc=$rc"
"$SCRIPT" why some-id 2>/dev/null | jq -e '.command == "why"' >/dev/null && pass "why envelope NEW" || fail "why"
"$SCRIPT" quickstart 2>/dev/null | jq -e '.command == "quickstart" and (.steps | length >= 3)' >/dev/null && pass "quickstart NEW" || fail "quickstart"
"$SCRIPT" --examples --json 2>/dev/null | jq -e '.examples | length > 0' >/dev/null && pass "--examples" || fail "--examples"

# Existing surfaces
"$SCRIPT" doctor --json 2>/dev/null | jq -e '.status' >/dev/null && pass "doctor (existing) reachable" || fail "doctor"
"$SCRIPT" validate --json 2>/dev/null | jq -e '.schema_version' >/dev/null && pass "validate (existing) reachable" || fail "validate"
# audit emits an array (not envelope) — verify it's a valid JSON array
"$SCRIPT" audit --json 2>/dev/null | jq -e 'type == "array" or has("schema_version")' >/dev/null && pass "audit (existing) reachable" || fail "audit"
"$SCRIPT" schema --json 2>/dev/null | jq -e '.schema_version' >/dev/null && pass "positional schema (existing) reachable" || fail "positional schema"

# Backward-compat: --dry-run mode default flow (no idempotency needed)
out="$("$SCRIPT" --dry-run --json 2>&1 || true)"
printf '%s' "$out" | jq -e 'has("schema_version") or has("status")' >/dev/null && pass "--dry-run flow preserved" || fail "--dry-run"

# Backward-compat: --apply --idempotency-key flow dispatches
"$SCRIPT" --apply --idempotency-key test-key-1hshd10 --json 2>&1 | head -1 | jq -e 'has("schema_version") or has("status")' >/dev/null && pass "--apply --idempotency-key flow dispatches" || fail "--apply with idem-key"

# Magic comment + lint
grep -q '# flywheel-cli-surface: true' "$SCRIPT" && pass "L6 magic comment present" || fail "L6 missing"
"$ROOT/.flywheel/scripts/canonical-cli-lint.sh" "$SCRIPT" >/dev/null 2>&1 && rc=0 || rc=$?
[[ "$rc" -eq 0 ]] && pass "canonical-cli-lint RC=0 (was RC=1 with 4 violations)" || fail "lint RC=$rc"

# --help shows usage
"$SCRIPT" --help 2>&1 | head -3 | grep -qE 'Usage|callback-spool-reap' && pass "--help shows usage" || fail "--help"


if [[ "$fail_count" -gt 0 ]]; then
  printf 'SUMMARY pass=%d fail=%d\n' "$pass_count" "$fail_count" >&2
  exit 1
fi
printf 'SUMMARY pass=%d fail=0\n' "$pass_count"
