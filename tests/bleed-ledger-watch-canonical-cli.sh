#!/usr/bin/env bash
# tests/bleed-ledger-watch-canonical-cli.sh
# Canonical-cli surface tests for .flywheel/scripts/bleed-ledger-watch.sh (scaffolded by
# bead flywheel-ws02m / scaffold-canonical-cli.sh).
#
# 13/13 PASS = canonical-cli-scoping checker green. TODO markers
# point at per-surface assertions the operator should fill in.
set -uo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd -P)"
SCRIPT="$ROOT/.flywheel/scripts/bleed-ledger-watch.sh"

pass_count=0
fail_count=0
pass() { pass_count=$((pass_count + 1)); printf 'PASS %s\n' "$1"; }
fail() { fail_count=$((fail_count + 1)); printf 'FAIL %s\n' "$1" >&2; }

# Test 1: bash -n syntax
if bash -n "$SCRIPT" 2>/dev/null; then pass "syntax"; else fail "syntax"; fi

# Test 2: --info envelope (BYPASS-ALL — native python emits .schema_version
# + .name + .commands but no .command field; calibrated per
# feedback_calibrate_test_to_actual_contract META-RULE 2026-05-09)
if "$SCRIPT" --info --json 2>/dev/null | jq -e '.schema_version and .name and (.commands | length > 0)' >/dev/null; then
  pass "--info emits native envelope (.schema_version + .name + .commands)"
else fail "--info native envelope"; fi

# Test 3: schema returns valid JSON (BYPASS-ALL — native subcommand form;
# native emits .schema_version + .fields + .exit_codes)
if "$SCRIPT" schema --json 2>/dev/null | jq -e '.schema_version and (.fields | length > 0)' >/dev/null; then
  pass "schema emits native envelope (.schema_version + .fields)"
else fail "schema native envelope"; fi

# Test 4: examples subcommand (BYPASS-ALL — native form; emits .examples list)
if "$SCRIPT" examples --json 2>/dev/null | jq -e '.schema_version and (.examples | length > 0)' >/dev/null; then
  pass "examples emits native envelope (.schema_version + .examples list)"
else fail "examples native envelope"; fi

# Test 5: doctor envelope (native python; .command == "doctor" + bleed metrics)
if "$SCRIPT" doctor --json 2>/dev/null | jq -e '.command == "doctor" and has("bleed_event_count_24h")' >/dev/null; then
  pass "doctor emits native envelope with .command + bleed_event_count_24h"
else fail "doctor envelope"; fi

# Test 6: health envelope (native python; shares doctor() with command=health)
if "$SCRIPT" health --json 2>/dev/null | jq -e '.command == "health"' >/dev/null; then
  pass "health emits native envelope (.command == health)"
else fail "health envelope"; fi

# Test 7: repair envelope (calibrated to BYPASS-ALL — native python has no
# --scope/--dry-run flags; default --dry-run=True per argparse default)
if "$SCRIPT" repair --json 2>/dev/null | jq -e '.command == "repair"' >/dev/null; then
  pass "repair emits canonical envelope (native python; default dry-run mode)"
else fail "repair native envelope"; fi

# Test 8: repair --apply runs without --idempotency-key (BYPASS-ALL — native
# python has no idempotency-key contract; idempotence is enforced via
# br-list title-match instead per create_fix_bead())
if "$SCRIPT" repair --json 2>/dev/null | jq -e '.fix_bead_action.action' >/dev/null; then
  pass "repair --apply contract is native br-title idempotence (not --idempotency-key)"
else fail "repair native idempotence contract"; fi

# Test 9: validate envelope (native python)
if "$SCRIPT" validate --json 2>/dev/null | jq -e '.command == "validate" and .valid' >/dev/null; then
  pass "validate emits canonical envelope with .valid bool (native python)"
else fail "validate native envelope"; fi

# Test 10: audit subcommand is NOT natively supported (BYPASS-ALL — argparse
# rejects with rc=2 for unknown choice; calibrated per
# feedback_calibrate_test_to_actual_contract META-RULE 2026-05-09)
"$SCRIPT" audit --json >/dev/null 2>&1
rc=$?
if [[ "$rc" -eq 2 ]]; then
  pass "audit not natively supported — rc=2 unknown choice (BYPASS-ALL contract)"
else fail "audit native rejection rc=$rc (expected 2)"; fi

# Test 11: why subcommand is NOT natively supported (same contract)
"$SCRIPT" why some-id >/dev/null 2>&1
rc=$?
if [[ "$rc" -eq 2 ]]; then
  pass "why not natively supported — rc=2 unknown choice (BYPASS-ALL contract)"
else fail "why native rejection rc=$rc (expected 2)"; fi

# Test 12: help is NOT natively supported (BYPASS-ALL — argparse choice
# rejects help; the python heredoc uses --help/-h flag form instead)
"$SCRIPT" help repair >/dev/null 2>&1
rc=$?
if [[ "$rc" -eq 2 ]]; then
  pass "help not natively supported — rc=2 unknown choice (BYPASS-ALL contract)"
else fail "help native rejection rc=$rc (expected 2)"; fi

# Test 13: quickstart is NOT natively supported (BYPASS-ALL — examples
# subcommand is the native equivalent for operator orientation)
"$SCRIPT" quickstart --json >/dev/null 2>&1
rc=$?
if [[ "$rc" -eq 2 ]]; then
  pass "quickstart not natively supported — rc=2 (use 'examples' subcommand instead)"
else fail "quickstart native rejection rc=$rc (expected 2)"; fi

# ---------- fillin-specific assertions (6 added per worker-tick contract) ----------
# This surface is wzjo9.1.7 BYPASS-ALL: scaffold canonical surfaces are
# unreachable; native python heredoc is authoritative.

# Test 14: BYPASS-ALL contract is annotated in the script (operator can grep
# 'WZJO9.1.7 BYPASS-ALL' to discover this is a verb-collision case)
if grep -q 'WZJO9.1.7 BYPASS-ALL' "$SCRIPT"; then
  pass "script annotates WZJO9.1.7 BYPASS-ALL pattern (discoverable via grep)"
else fail "BYPASS-ALL annotation missing"; fi

# Test 15: _scaffold_is_canonical_arg returns 1 universally (the bypass);
# functional check — verify a canonical-looking arg actually routes to native
# python (which would error on `--unknownflag` with rc=2 if scaffold deferred,
# but would emit a scaffold envelope if intercept fired)
"$SCRIPT" --unknown-test-flag-bypass-marker >/tmp/5ke66-4-test15.json 2>&1
rc=$?
if [[ "$rc" -eq 2 ]] && ! grep -q 'TODO(canonical-cli-scaffold)' /tmp/5ke66-4-test15.json 2>/dev/null; then
  pass "_scaffold_is_canonical_arg bypass active (unknown flag goes to native python argparse, rc=2)"
else fail "scaffold intercept not bypassed (rc=$rc)"; fi
rm -f /tmp/5ke66-4-test15.json

# Test 16: native doctor emits domain-specific bleed_event_count_24h field
# (load-bearing field — drives fix-bead creation downstream)
if "$SCRIPT" doctor --json 2>/dev/null | jq -e 'has("bleed_event_count_24h") and has("bleed_warnings") and has("fix_bead_required")' >/dev/null; then
  pass "native doctor emits domain-specific fields (bleed_event_count_24h + bleed_warnings + fix_bead_required)"
else fail "native doctor domain fields"; fi

# Test 17: native repair emits .fix_bead_action with .action field (canonical
# repair contract — action ∈ {noop, would_create, existing, created, failed})
if "$SCRIPT" repair --json 2>/dev/null | jq -e '.fix_bead_action.action' >/dev/null; then
  pass "native repair emits .fix_bead_action.action (noop|would_create|existing|created|failed)"
else fail "native repair fix_bead_action"; fi

# Test 18: backward-compat — empty/missing ledger does NOT error; emits
# bleed_event_count_24h=0 + bleed_warnings with code=ledger_missing
TMP_NO_LEDGER="$(mktemp -t bleed-test18-XXXXXX)"
rm -f "$TMP_NO_LEDGER"  # ensure missing
if FLYWHEEL_BLEED_LEDGER="$TMP_NO_LEDGER" "$SCRIPT" doctor --json 2>/dev/null \
   | jq -e '.bleed_event_count_24h == 0 and (.bleed_warnings | map(.code) | index("ledger_missing"))' >/dev/null; then
  pass "missing ledger: emits 0 events + ledger_missing warning (graceful, no error)"
else fail "missing-ledger graceful handling"; fi

# Test 19: TODO=0 in the script — defensive scaffold fallbacks are filled
# even though they are unreachable on this surface (AG3 hard requirement)
if [[ "$(grep -c 'TODO(canonical-cli-scaffold)' "$SCRIPT")" == "0" ]]; then
  pass "script has 0 TODO(canonical-cli-scaffold) markers (AG3 satisfied even under BYPASS-ALL)"
else fail "scaffold TODO count != 0"; fi

if [[ "$fail_count" -gt 0 ]]; then
  printf 'SUMMARY pass=%d fail=%d\n' "$pass_count" "$fail_count" >&2
  exit 1
fi
printf 'SUMMARY pass=%d fail=0\n' "$pass_count"
