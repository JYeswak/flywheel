#!/usr/bin/env bash
# tests/orchestrator-callback-artifact-fix-bead-canonical-cli.sh
# flywheel-k8gcv.24 (wave-3-24).
set -uo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd -P)"
SCRIPT="$ROOT/.flywheel/scripts/orchestrator-callback-artifact-fix-bead.sh"

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
"$SCRIPT" why dedupe-key-format --json 2>/dev/null | jq -e '.topic == "dedupe-key-format"' >/dev/null && pass "why dedupe-key-format" || fail "why dedupe-key-format"
"$SCRIPT" quickstart --json 2>/dev/null | jq -e '.command == "quickstart"' >/dev/null && pass "quickstart envelope" || fail "quickstart"

# Repair apply contract
"$SCRIPT" repair --scope ledger-prime --apply --json >/dev/null 2>&1; rc=$?
[[ "$rc" -eq 3 ]] && pass "repair --apply without --idempotency-key rc=3" || fail "repair apply rc=$rc"

# Magic comment + lint (was L5 violation)
grep -q '# flywheel-cli-surface: true' "$SCRIPT" && pass "L6 magic comment present" || fail "L6 missing"
"$ROOT/.flywheel/scripts/canonical-cli-lint.sh" "$SCRIPT" >/dev/null 2>&1 && rc=0 || rc=$?
[[ "$rc" -eq 0 ]] && pass "canonical-cli-lint RC=0 (was L5)" || fail "lint RC=$rc"

# Backward compat: legacy open-fix-bead flow + dedupe
TMP_REPO="$(mktemp -d -t k8gcv24-repo.XXXXXX)"
mkdir -p "$TMP_REPO/.beads"
: >"$TMP_REPO/.beads/issues.jsonl"
TMP_LEDGER="$(mktemp -t k8gcv24-led.XXXXXX)"

ORCH_CALLBACK_ARTIFACT_FIX_BEAD_LEDGER="$TMP_LEDGER" \
  "$SCRIPT" --repo "$TMP_REPO" --task-id task-x --reason artifact_missing --dispatch-file /tmp/d.md --artifact-list 'a.sh' --json 2>/dev/null \
  | jq -e '.action == "jsonl_fallback" and (.fix_bead_id | startswith("flywheel-fix-"))' >/dev/null \
  && pass "legacy: first call creates fix bead via jsonl_fallback" || fail "legacy first call"

ORCH_CALLBACK_ARTIFACT_FIX_BEAD_LEDGER="$TMP_LEDGER" \
  "$SCRIPT" --repo "$TMP_REPO" --task-id task-x --reason artifact_missing --dispatch-file /tmp/d.md --artifact-list 'a.sh' --json 2>/dev/null \
  | jq -e '.action == "reused"' >/dev/null \
  && pass "legacy: second call with same dedupe key returns action=reused" || fail "legacy idempotent"

rm -f "$TMP_LEDGER" "$TMP_REPO/.beads/issues.jsonl"
rmdir "$TMP_REPO/.beads" "$TMP_REPO" 2>/dev/null || true

# --help
"$SCRIPT" --help 2>&1 | head -3 | grep -qE 'usage|orchestrator-callback' && pass "--help shows usage" || fail "--help"

# --examples text-mode
"$SCRIPT" --examples 2>&1 | grep -q 'orchestrator-callback-artifact-fix-bead' && pass "--examples text-mode preserved" || fail "--examples text"

if [[ "$fail_count" -gt 0 ]]; then
  printf 'SUMMARY pass=%d fail=%d\n' "$pass_count" "$fail_count" >&2
  exit 1
fi
printf 'SUMMARY pass=%d fail=0\n' "$pass_count"
