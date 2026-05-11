#!/usr/bin/env bash
# tests/shared-surface-reservation-check-canonical-cli.sh
# Canonical-cli surface tests for .flywheel/scripts/shared-surface-reservation-check.sh
# (CRITICAL — this is the L107 reservation tool used by every other wave-2 surface)
# (filled-in by bead flywheel-5ke66.18 — wave-2-general-18).
set -uo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd -P)"
SCRIPT="$ROOT/.flywheel/scripts/shared-surface-reservation-check.sh"

pass_count=0
fail_count=0
pass() { pass_count=$((pass_count + 1)); printf 'PASS %s\n' "$1"; }
fail() { fail_count=$((fail_count + 1)); printf 'FAIL %s\n' "$1" >&2; }

if bash -n "$SCRIPT" 2>/dev/null; then pass "syntax"; else fail "syntax"; fi

# ===== Bash canonical surfaces (NEW; no-dash subcommands) =====

"$SCRIPT" doctor --json 2>/dev/null | jq -e '.command == "doctor"' >/dev/null && pass "doctor emits canonical envelope" || fail "doctor envelope"
"$SCRIPT" health --json 2>/dev/null | jq -e '.command == "health"' >/dev/null && pass "health emits canonical envelope" || fail "health envelope"
"$SCRIPT" repair --scope none --dry-run --json 2>/dev/null | jq -e '.command == "repair" and .mode == "dry_run"' >/dev/null && pass "repair --dry-run emits canonical envelope" || fail "repair --dry-run envelope"
"$SCRIPT" repair --scope none --apply --json >/dev/null 2>&1; rc=$?
if [[ "$rc" -eq 3 ]]; then pass "repair --apply without --idempotency-key returns rc=3"; else fail "repair --apply rc=$rc (expected 3)"; fi
"$SCRIPT" validate --json 2>/dev/null | jq -e '.command == "validate"' >/dev/null && pass "validate emits canonical envelope" || fail "validate envelope"
"$SCRIPT" audit --json 2>/dev/null | jq -e '.command == "audit"' >/dev/null && pass "audit emits canonical envelope" || fail "audit envelope"
"$SCRIPT" why some-id 2>/dev/null | jq -e '.command == "why"' >/dev/null && pass "why <id> emits canonical envelope" || fail "why envelope"
"$SCRIPT" help repair 2>/dev/null | grep -q 'topic:' && pass "help repair returns topic header" || fail "help topic"
"$SCRIPT" quickstart 2>/dev/null | jq -e '.command == "quickstart"' >/dev/null && pass "quickstart emits canonical envelope" || fail "quickstart envelope"
"$SCRIPT" --examples --json 2>/dev/null | jq -e '.command == "examples" and (.examples | length > 0)' >/dev/null && pass "--examples emits canonical envelope (NEW)" || fail "--examples envelope"

# ===== BACKWARD-COMPAT — python dash-flag forms unchanged =====

# Test 12: BACKWARD-COMPAT — python --info still has its existing shape
# (existing tests/shared-surface-reservation-check.sh:33 assertion)
if "$SCRIPT" --info --json 2>/dev/null \
  | jq -e '.schema_version == "shared-surface-reservation/v1" and (.mutating_commands | index("--reserve"))' >/dev/null; then
  pass "BACKWARD-COMPAT --info: .schema_version + .mutating_commands intact"
else fail "--info backward-compat shape (LOAD-BEARING for existing test)"; fi

# Test 13: BACKWARD-COMPAT — python --schema still has its existing shape
# (existing tests/shared-surface-reservation-check.sh:36 assertion)
if "$SCRIPT" --schema --json 2>/dev/null \
  | jq -e '.exit_codes."1" == "reserved by another pane" and (.commands | index("--check <path>"))' >/dev/null; then
  pass "BACKWARD-COMPAT --schema: .exit_codes + .commands intact"
else fail "--schema backward-compat shape (LOAD-BEARING for existing test)"; fi

# ===== fillin-specific (flywheel-5ke66.18) =====

if "$SCRIPT" doctor --json 2>/dev/null \
  | jq -e '.checks | length >= 5 and (any(.name == "python3_on_path")) and (any(.name == "jq_on_path")) and (any(.name == "ledger_writable")) and (any(.name == "fuckup_log_present"))' >/dev/null; then
  pass "doctor: 5+ probes incl. python3 + jq + ledger + fuckup_log"
else fail "doctor substrate probes"; fi

if "$SCRIPT" repair --scope ledger-prime --dry-run --json 2>/dev/null \
  | jq -e '.command == "repair" and .scope == "ledger-prime" and (.status != "todo") and has("ledger") and has("present") and has("row_count")' >/dev/null; then
  pass "repair --scope ledger-prime emits non-stub envelope"
else fail "repair scope-specific"; fi

if "$SCRIPT" validate --row-json='{"action":"reserve","pane":"3","path":"/p","session":"flywheel","task_id":"t1","ts":"2026-05-11T00:00:00Z"}' 2>/dev/null \
  | jq -e '.command == "validate" and .subject == "row" and .status == "pass" and (.valid == true)' >/dev/null; then
  pass "validate --row-json enforces reservation row schema (6 required fields)"
else fail "validate row schema"; fi

if "$SCRIPT" validate --ledger 2>/dev/null \
  | jq -e '.command == "validate" and .subject == "ledger" and has("ledger") and has("present") and has("row_count") and has("reserve_count")' >/dev/null; then
  pass "validate --ledger probes file-reservations.jsonl (surface-specific)"
else fail "validate ledger subject"; fi

if "$SCRIPT" validate --fuckup-log 2>/dev/null \
  | jq -e '.command == "validate" and .subject == "fuckup-log" and has("fuckup_log") and has("present") and has("collision_count")' >/dev/null; then
  pass "validate --fuckup-log probes coordination-collision rows (surface-specific)"
else fail "validate fuckup-log subject"; fi

# ===== CRITICAL L107 functional regression — --check / --reserve / --release work =====

# Test 18: --check fall-through to python (no scaffold interference)
if "$SCRIPT" --check "$SCRIPT" --pane=3 --json 2>/dev/null \
  | jq -e '.schema_version == "shared-surface-reservation/v1" and has("status")' >/dev/null; then
  pass "L107 --check operational path unaffected by scaffold"
else fail "L107 --check broken"; fi

# Test 19: --list fall-through to python
if "$SCRIPT" --list --json 2>/dev/null \
  | jq -e 'has("active_count") and has("reservations")' >/dev/null; then
  pass "L107 --list operational path unaffected by scaffold"
else fail "L107 --list broken"; fi

# Test 20: --info and --schema dash-flag forms still routed to python (not bash)
# (Different from bash --examples which IS intercepted.)
if "$SCRIPT" --info --json 2>/dev/null | jq -e '.command == "shared-surface-reservation-check.sh"' >/dev/null; then
  pass "L107 --info STILL routes to python (not bash intercept)"
else fail "L107 --info routing"; fi


if [[ "$fail_count" -gt 0 ]]; then
  printf 'SUMMARY pass=%d fail=%d\n' "$pass_count" "$fail_count" >&2
  exit 1
fi
printf 'SUMMARY pass=%d fail=0\n' "$pass_count"
