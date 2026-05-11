#!/usr/bin/env bash
# tests/callback-fix-bead-opener-canonical-cli.sh
# flywheel-k8gcv.1 (wave-3-01).
set -uo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd -P)"
SCRIPT="$ROOT/.flywheel/scripts/callback-fix-bead-opener.sh"

pass_count=0
fail_count=0
pass() { pass_count=$((pass_count + 1)); printf 'PASS %s\n' "$1"; }
fail() { fail_count=$((fail_count + 1)); printf 'FAIL %s\n' "$1" >&2; }

if bash -n "$SCRIPT" 2>/dev/null; then pass "syntax"; else fail "syntax"; fi

# AG3 — wave-3 acceptance gate (.name and .version and .capabilities)
"$SCRIPT" --info --json 2>/dev/null | jq -e '.name and .version and .capabilities and (.subcommands | length >= 5)' >/dev/null && pass "AG3 --info (name+version+capabilities+subcommands)" || fail "AG3 --info"
"$SCRIPT" --schema --json 2>/dev/null | jq -e '.input_schema and .output_schema' >/dev/null && pass "AG3 --schema (input_schema+output_schema)" || fail "AG3 --schema"
"$SCRIPT" --examples --json 2>/dev/null | jq -e '.examples | length > 0' >/dev/null && pass "AG3 --examples (length>0)" || fail "AG3 --examples"
"$SCRIPT" doctor --json 2>/dev/null | jq -e '.checks' >/dev/null && pass "AG3 doctor (mutates_state=yes → required)" || fail "AG3 doctor"

# Canonical subcommands
"$SCRIPT" health --json 2>/dev/null | jq -e '.command == "health" and has("ledger_row_count")' >/dev/null && pass "health envelope" || fail "health"
"$SCRIPT" validate --json 2>/dev/null | jq -e '.command == "validate" and has("ledger_row_count")' >/dev/null && pass "validate envelope" || fail "validate"
"$SCRIPT" audit --json 2>/dev/null | jq -e '.command == "audit" and has("row_count") and has("recent")' >/dev/null && pass "audit envelope" || fail "audit"
"$SCRIPT" why --json 2>/dev/null | jq -e '.command == "why" and has("body")' >/dev/null && pass "why envelope (default topic)" || fail "why default"
"$SCRIPT" why dedupe-key --json 2>/dev/null | jq -e '.command == "why" and .topic == "dedupe-key"' >/dev/null && pass "why dedupe-key topic" || fail "why dedupe-key"
"$SCRIPT" quickstart 2>/dev/null | jq -e '.command == "quickstart" and (.steps | length >= 3)' >/dev/null && pass "quickstart envelope" || fail "quickstart"

# repair dry-run + apply contract
"$SCRIPT" repair --scope ledger-prime --dry-run --json 2>/dev/null | jq -e '.command == "repair" and .scope == "ledger-prime" and .mode == "dry_run"' >/dev/null && pass "repair --dry-run" || fail "repair --dry-run"
"$SCRIPT" repair --scope stale-dedupe --dry-run --json 2>/dev/null | jq -e '.scope == "stale-dedupe" and has("stale_dedupe_rows")' >/dev/null && pass "repair stale-dedupe" || fail "repair stale-dedupe"
"$SCRIPT" repair --scope ledger-prime --apply --json >/dev/null 2>&1; rc=$?
[[ "$rc" -eq 3 ]] && pass "repair --apply without --idempotency-key returns rc=3" || fail "repair apply rc=$rc"

# Magic comment + lint
grep -q '# flywheel-cli-surface: true' "$SCRIPT" && pass "L6 magic comment present" || fail "L6 missing"
"$ROOT/.flywheel/scripts/canonical-cli-lint.sh" "$SCRIPT" >/dev/null 2>&1 && rc=0 || rc=$?
[[ "$rc" -eq 0 ]] && pass "canonical-cli-lint RC=0" || fail "lint RC=$rc"

# --help shows usage
"$SCRIPT" --help 2>&1 | head -3 | grep -qE 'usage|callback-fix-bead-opener' && pass "--help shows usage" || fail "--help"

# Backward compat: --examples text mode preserved
"$SCRIPT" --examples 2>&1 | grep -q "callback-fix-bead-opener.sh --task-id" && pass "--examples text-mode preserved" || fail "--examples text"

# Backward compat: legacy run_open shape (idempotent dedupe)
TMP_LEDGER="$(mktemp -t fix-bead-opener-canonical.XXXXXX)"
TMP_REPO="$(mktemp -d -t fix-bead-opener-repo.XXXXXX)"
mkdir -p "$TMP_REPO/.beads"
: >"$TMP_REPO/.beads/issues.jsonl"
mkdir -p "$TMP_REPO/bin"
cat >"$TMP_REPO/bin/fake-br" <<'SH'
#!/usr/bin/env bash
echo '{"id":"flywheel-fixmock-1"}'
SH
chmod +x "$TMP_REPO/bin/fake-br"

CALLBACK_FIX_BEAD_LEDGER="$TMP_LEDGER" CALLBACK_FIX_BEAD_BR_BIN="$TMP_REPO/bin/fake-br" \
  "$SCRIPT" --repo "$TMP_REPO" --task-id legacy-shape --bead flywheel-x --reason l112_verify_failed --json 2>/dev/null \
  | jq -e '.status == "pass" and .action == "created" and (.fix_bead_id | startswith("flywheel"))' >/dev/null \
  && pass "legacy run_open creates fix bead" || fail "legacy run_open"

CALLBACK_FIX_BEAD_LEDGER="$TMP_LEDGER" CALLBACK_FIX_BEAD_BR_BIN="$TMP_REPO/bin/fake-br" \
  "$SCRIPT" --repo "$TMP_REPO" --task-id legacy-shape --bead flywheel-x --reason l112_verify_failed --json 2>/dev/null \
  | jq -e '.action == "reused"' >/dev/null \
  && pass "legacy run_open idempotent on second call (action=reused)" || fail "legacy idempotent"

rm -rf "$TMP_LEDGER" "$TMP_REPO"

if [[ "$fail_count" -gt 0 ]]; then
  printf 'SUMMARY pass=%d fail=%d\n' "$pass_count" "$fail_count" >&2
  exit 1
fi
printf 'SUMMARY pass=%d fail=0\n' "$pass_count"
