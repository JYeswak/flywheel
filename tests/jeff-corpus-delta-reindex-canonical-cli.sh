#!/usr/bin/env bash
# tests/jeff-corpus-delta-reindex-canonical-cli.sh
# flywheel-k8gcv.13 (wave-3-13).
set -uo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd -P)"
SCRIPT="$ROOT/.flywheel/scripts/jeff-corpus-delta-reindex.sh"

pass_count=0
fail_count=0
pass() { pass_count=$((pass_count + 1)); printf 'PASS %s\n' "$1"; }
fail() { fail_count=$((fail_count + 1)); printf 'FAIL %s\n' "$1" >&2; }

if bash -n "$SCRIPT" 2>/dev/null; then pass "syntax"; else fail "syntax"; fi

# AG3
"$SCRIPT" --info --json 2>/dev/null | jq -e '.name and .version and .capabilities and (.subcommands | length >= 5)' >/dev/null && pass "AG3 --info" || fail "AG3 --info"
"$SCRIPT" --schema --json 2>/dev/null | jq -e '.input_schema and .output_schema' >/dev/null && pass "AG3 --schema" || fail "AG3 --schema"
"$SCRIPT" --examples --json 2>/dev/null | jq -e '.examples | length > 0' >/dev/null && pass "AG3 --examples" || fail "AG3 --examples"
"$SCRIPT" doctor --json 2>/dev/null | jq -e '.checks' >/dev/null && pass "AG3 doctor" || fail "AG3 doctor"

# Canonical subcommands
"$SCRIPT" health --json 2>/dev/null | jq -e '.command == "health"' >/dev/null && pass "health envelope" || fail "health"
"$SCRIPT" validate --json 2>/dev/null | jq -e '.command == "validate"' >/dev/null && pass "validate envelope" || fail "validate"
"$SCRIPT" audit --json 2>/dev/null | jq -e '.command == "audit" and has("recent")' >/dev/null && pass "audit envelope" || fail "audit"
"$SCRIPT" why --json 2>/dev/null | jq -e '.command == "why" and has("body")' >/dev/null && pass "why default" || fail "why default"
"$SCRIPT" why git-diff-name-only --json 2>/dev/null | jq -e '.topic == "git-diff-name-only"' >/dev/null && pass "why git-diff-name-only" || fail "why git-diff-name-only"
"$SCRIPT" quickstart 2>/dev/null | jq -e '.command == "quickstart"' >/dev/null && pass "quickstart envelope" || fail "quickstart"

# Apply contract
"$SCRIPT" --apply --json >/dev/null 2>&1; rc=$?
[[ "$rc" -eq 3 ]] && pass "main --apply without --idempotency-key rc=3" || fail "main apply rc=$rc"
"$SCRIPT" repair --scope ledger-prime --apply --json >/dev/null 2>&1; rc=$?
[[ "$rc" -eq 3 ]] && pass "repair --apply without --idempotency-key rc=3" || fail "repair apply rc=$rc"

# Magic comment + lint (was 2 violations: L6 + L7)
grep -q '# flywheel-cli-surface: true' "$SCRIPT" && pass "L6 magic comment present" || fail "L6 missing"
"$ROOT/.flywheel/scripts/canonical-cli-lint.sh" "$SCRIPT" >/dev/null 2>&1 && rc=0 || rc=$?
[[ "$rc" -eq 0 ]] && pass "canonical-cli-lint RC=0 (was L6+L7 violations)" || fail "lint RC=$rc"

# Backward compat
"$SCRIPT" >/dev/null 2>&1; rc=$?
[[ "$rc" -eq 2 ]] && pass "legacy 'must choose --dry-run or --apply' returns rc=2" || fail "legacy rc=$rc"

"$SCRIPT" --help 2>&1 | head -3 | grep -qE 'Usage|jeff-corpus' && pass "--help shows usage" || fail "--help"

"$SCRIPT" --examples 2>&1 | grep -q 'jeff-corpus-delta-reindex' && pass "--examples text-mode preserved" || fail "--examples text"

# Backward compat: --dry-run with synthetic empty manifest+pending should run
TMP_MANIFEST="$(mktemp -t jcdr-manifest.XXXXXX).json"
TMP_PENDING="$(mktemp -t jcdr-pending.XXXXXX).jsonl"
TMP_DELTA="$(mktemp -t jcdr-delta.XXXXXX).jsonl"
echo '{"version":"v1","repos":[]}' > "$TMP_MANIFEST"
: > "$TMP_PENDING"
out="$("$SCRIPT" --manifest "$TMP_MANIFEST" --pending "$TMP_PENDING" --delta "$TMP_DELTA" --dry-run --json 2>&1 || true)"
printf '%s' "$out" | jq -e '.' >/dev/null \
  && pass "legacy --dry-run with synthetic fixtures emits JSON" || fail "legacy dry-run fixtures (out=${out:0:120})"

# --dry-run does not require idem-key (only --apply does)
"$SCRIPT" --manifest "$TMP_MANIFEST" --pending "$TMP_PENDING" --delta "$TMP_DELTA" --dry-run --json >/dev/null 2>&1; rc=$?
[[ "$rc" -eq 0 ]] && pass "--dry-run does NOT require --idempotency-key" || fail "dry-run rc=$rc"

rm -f "$TMP_MANIFEST" "$TMP_PENDING" "$TMP_DELTA"

if [[ "$fail_count" -gt 0 ]]; then
  printf 'SUMMARY pass=%d fail=%d\n' "$pass_count" "$fail_count" >&2
  exit 1
fi
printf 'SUMMARY pass=%d fail=0\n' "$pass_count"
