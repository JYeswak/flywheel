#!/usr/bin/env bash
# tests/jeff-corpus-compact-canonical-cli.sh
# flywheel-k8gcv.12 (wave-3-12).
set -uo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd -P)"
SCRIPT="$ROOT/.flywheel/scripts/jeff-corpus-compact.sh"

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
"$SCRIPT" health --json 2>/dev/null | jq -e '.command == "health" and has("receipt_count")' >/dev/null && pass "health envelope" || fail "health"
"$SCRIPT" validate --json 2>/dev/null | jq -e '.command == "validate"' >/dev/null && pass "validate envelope" || fail "validate"
"$SCRIPT" audit --json 2>/dev/null | jq -e '.command == "audit" and has("recent")' >/dev/null && pass "audit envelope" || fail "audit"
"$SCRIPT" why --json 2>/dev/null | jq -e '.command == "why" and has("body")' >/dev/null && pass "why default" || fail "why default"
"$SCRIPT" why idempotent-replay --json 2>/dev/null | jq -e '.topic == "idempotent-replay"' >/dev/null && pass "why idempotent-replay" || fail "why idempotent-replay"
"$SCRIPT" quickstart 2>/dev/null | jq -e '.command == "quickstart"' >/dev/null && pass "quickstart envelope" || fail "quickstart"

# Apply contract: main and repair paths both refuse without idem-key
"$SCRIPT" --apply --json >/dev/null 2>&1; rc=$?
[[ "$rc" -eq 3 ]] && pass "main --apply without --idempotency-key rc=3" || fail "main apply rc=$rc"
"$SCRIPT" repair --scope ledger-prime --apply --json >/dev/null 2>&1; rc=$?
[[ "$rc" -eq 3 ]] && pass "repair --apply without --idempotency-key rc=3" || fail "repair apply rc=$rc"

# Magic comment + lint (was 1 violation: L6)
grep -q '# flywheel-cli-surface: true' "$SCRIPT" && pass "L6 magic comment present" || fail "L6 missing"
"$ROOT/.flywheel/scripts/canonical-cli-lint.sh" "$SCRIPT" >/dev/null 2>&1 && rc=0 || rc=$?
[[ "$rc" -eq 0 ]] && pass "canonical-cli-lint RC=0 (was L6 violation)" || fail "lint RC=$rc"

# Backward compat: neither --dry-run nor --apply still rejects with rc=2 (ERROR text-mode legacy)
"$SCRIPT" >/dev/null 2>&1; rc=$?
[[ "$rc" -eq 2 ]] && pass "legacy 'must choose --dry-run or --apply' returns rc=2" || fail "legacy choose-mode rc=$rc"

# Backward compat: --help shows usage
"$SCRIPT" --help 2>&1 | head -3 | grep -qE 'Usage|jeff-corpus' && pass "--help shows usage" || fail "--help"

# Backward compat: --examples text-mode
"$SCRIPT" --examples 2>&1 | grep -q 'jeff-corpus-compact' && pass "--examples text-mode preserved" || fail "--examples text"

# Backward compat: --dry-run + fixture inputs still runs without idem-key (no apply)
TMP_MANIFEST="$(mktemp -t jcc-manifest.XXXXXX).json"
TMP_DELTA="$(mktemp -t jcc-delta.XXXXXX).jsonl"
TMP_OUT="$(mktemp -t jcc-out.XXXXXX).json"
TMP_RECEIPT_DIR="$(mktemp -d -t jcc-receipt.XXXXXX)"
cat > "$TMP_MANIFEST" <<EOF
{"version":"v1","repos":[{"repo":"ntm","chunks":["chunk1"],"latest_commit":"abc"}],"qdrant_url":"http://localhost:16333"}
EOF
: > "$TMP_DELTA"
out="$("$SCRIPT" --manifest "$TMP_MANIFEST" --delta "$TMP_DELTA" --out "$TMP_OUT" --receipt-dir "$TMP_RECEIPT_DIR" --dry-run --json 2>&1 || true)"
printf '%s' "$out" | jq -e '.' >/dev/null \
  && pass "legacy --dry-run with fixtures emits JSON" || fail "legacy dry-run fixtures (out=${out:0:120})"

# --dry-run does not require idem-key (only --apply does)
"$SCRIPT" --manifest "$TMP_MANIFEST" --delta "$TMP_DELTA" --out "$TMP_OUT" --receipt-dir "$TMP_RECEIPT_DIR" --dry-run --json >/dev/null 2>&1; rc=$?
[[ "$rc" -eq 0 ]] && pass "--dry-run does NOT require --idempotency-key" || fail "dry-run rc=$rc"

rm -f "$TMP_MANIFEST" "$TMP_DELTA" "$TMP_OUT"
rmdir "$TMP_RECEIPT_DIR" 2>/dev/null || true

if [[ "$fail_count" -gt 0 ]]; then
  printf 'SUMMARY pass=%d fail=%d\n' "$pass_count" "$fail_count" >&2
  exit 1
fi
printf 'SUMMARY pass=%d fail=0\n' "$pass_count"
