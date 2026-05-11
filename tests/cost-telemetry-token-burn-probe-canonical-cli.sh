#!/usr/bin/env bash
# tests/cost-telemetry-token-burn-probe-canonical-cli.sh
# Canonical-cli surface tests for .flywheel/scripts/cost-telemetry-token-burn-probe.sh (scaffolded by
# bead flywheel-ws02m / scaffold-canonical-cli.sh).
#
# 13/13 PASS = canonical-cli-scoping checker green. TODO markers
# point at per-surface assertions the operator should fill in.
set -uo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd -P)"
SCRIPT="$ROOT/.flywheel/scripts/cost-telemetry-token-burn-probe.sh"

pass_count=0
fail_count=0
pass() { pass_count=$((pass_count + 1)); printf 'PASS %s\n' "$1"; }
fail() { fail_count=$((fail_count + 1)); printf 'FAIL %s\n' "$1" >&2; }

# Test 1: bash -n syntax
if bash -n "$SCRIPT" 2>/dev/null; then pass "syntax"; else fail "syntax"; fi

# Test 2: --info native PASSTHRU (NUANCED-PARTIAL-BYPASS)
if "$SCRIPT" --info 2>/dev/null | jq -e '.schema_version == "cost-telemetry-token-burn/v1"' >/dev/null; then
  pass "--info emits native PASSTHRU envelope (cost-telemetry-token-burn/v1)"
else fail "--info native envelope"; fi

# Test 3: --schema native PASSTHRU (with .ledger_row_required_fields)
if "$SCRIPT" --schema 2>/dev/null | jq -e '.schema_version == "cost-telemetry-token-burn/v1" and .ledger_row_required_fields' >/dev/null; then
  pass "--schema emits native PASSTHRU with .ledger_row_required_fields"
else fail "--schema native envelope"; fi

# Test 4: --examples scaffold envelope (NOT bypassed — native errors)
if "$SCRIPT" --examples --json 2>/dev/null | jq -e '.command == "examples"' >/dev/null; then
  pass "--examples emits scaffold envelope (NOT bypassed — native errors)"
else fail "--examples scaffold envelope"; fi

# Test 5: doctor scaffold envelope (>=5 named probes)
if "$SCRIPT" doctor --json 2>/dev/null | jq -e '.command == "doctor" and (.checks | length >= 5)' >/dev/null; then
  pass "doctor emits scaffold envelope with >=5 checks"
else fail "doctor envelope"; fi

# Test 6: health envelope (scaffold)
if "$SCRIPT" health --json 2>/dev/null | jq -e '.command == "health"' >/dev/null; then
  pass "health emits scaffold envelope"
else fail "health envelope"; fi

# Test 7: repair --dry-run envelope (real scope)
if "$SCRIPT" repair --scope ledger_dir --dry-run --json 2>/dev/null | jq -e '.command == "repair" and .mode == "dry_run" and .status == "ok"' >/dev/null; then
  pass "repair --dry-run emits scaffold envelope (real scope ledger_dir)"
else fail "repair --dry-run envelope"; fi

# Test 8: repair --apply without --idempotency-key REFUSES (rc=3)
"$SCRIPT" repair --scope ledger_dir --apply --json >/dev/null 2>&1
rc=$?
if [[ "$rc" -eq 3 ]]; then
  pass "repair --apply without --idempotency-key returns rc=3 (canonical refusal)"
else
  fail "repair --apply rc=$rc (expected 3)"
fi

# Test 9: validate envelope (bare validate refuses with rc=64; calibrated)
"$SCRIPT" validate >/tmp/1hshd-20-test9.json 2>&1
rc=$?
if [[ "$rc" -eq 64 ]] && jq -e '.command == "validate" and .status == "refused" and .reason == "missing_subject"' /tmp/1hshd-20-test9.json >/dev/null 2>&1; then
  pass "validate (bare) refuses with rc=64 + missing_subject envelope"
else fail "validate bare-refusal contract rc=$rc"; fi
rm -f /tmp/1hshd-20-test9.json

# Test 10: audit envelope
if "$SCRIPT" audit --json 2>/dev/null | jq -e '.command == "audit"' >/dev/null; then
  pass "audit emits canonical envelope"
else fail "audit envelope"; fi

# Test 11: why with id
if "$SCRIPT" why some-id 2>/dev/null | jq -e '.command == "why"' >/dev/null; then
  pass "why <id> emits canonical envelope"
else fail "why envelope"; fi

# Test 12: help <topic> returns text (intercepted only with topic arg)
if "$SCRIPT" help repair 2>/dev/null | grep -q 'topic:'; then
  pass "help repair returns topic header"
else fail "help topic"; fi

# Test 13: quickstart envelope
if "$SCRIPT" quickstart 2>/dev/null | jq -e '.command == "quickstart"' >/dev/null; then
  pass "quickstart emits canonical envelope"
else fail "quickstart envelope"; fi

# ---------- fillin-specific assertions (6 added per worker-tick contract) ----------

# Test 14: NUANCED-PARTIAL-BYPASS contract is annotated (5th application now)
if grep -q 'NUANCED-PARTIAL-BYPASS' "$SCRIPT"; then
  pass "script annotates NUANCED-PARTIAL-BYPASS variant (5th application)"
else fail "NUANCED-PARTIAL-BYPASS annotation missing"; fi

# Test 15: native --doctor FLAG (NOT scaffold doctor verb) routes correctly
# via the scaffolder's pre-bypass for native flags. Emits mode=doctor envelope.
if "$SCRIPT" --doctor --json 2>/dev/null | jq -e '.mode == "doctor" and .schema_version == "cost-telemetry-token-burn/v1"' >/dev/null; then
  pass "native --doctor FLAG bypassed (mode=doctor + cost-telemetry-token-burn/v1)"
else fail "native --doctor flag bypass"; fi

# Test 16: validate hours-back accepts default 24 + boundary 1/168
ALL_OK=1
for V in 1 24 168; do
  if ! "$SCRIPT" validate hours-back "$V" 2>/dev/null \
       | jq -e --argjson v "$V" '.status == "ok" and .value == $v' >/dev/null; then
    ALL_OK=0; break
  fi
done
if [[ "$ALL_OK" -eq 1 ]]; then
  pass "validate hours-back accepts boundary + default (1/24/168 — 1h to 1wk window)"
else fail "validate hours-back boundary accept"; fi

# Test 17: validate hours-back REJECTS 200 (out of [1,168] range; rc=1)
"$SCRIPT" validate hours-back "200" >/tmp/1hshd-20-test17.json 2>&1
rc=$?
if [[ "$rc" -eq 1 ]] && jq -e '.status == "reject" and .reason == "out_of_range_or_not_integer"' /tmp/1hshd-20-test17.json >/dev/null 2>&1; then
  pass "validate hours-back rejects 200 (above [1,168] week-cap) with rc=1"
else fail "validate hours-back range reject rc=$rc"; fi
rm -f /tmp/1hshd-20-test17.json

# Test 18: lint-idiom-fix preserved (3rd application — sister to 5ke66.15 + 1hshd.14)
if grep -E '^set -euo pipefail$' "$SCRIPT" >/dev/null \
   && grep -E '^set \+e' "$SCRIPT" >/dev/null; then
  pass "lint-idiom-fix preserved (3rd application — sister to 5ke66.15 + 1hshd.14)"
else fail "lint-idiom-fix idiom missing"; fi

# Test 19: 4-DIRECTION fidelity check (native --info + native --schema +
# scaffold --examples + scaffold doctor verb all routing correctly).
# Sister to 1hshd.13 SELECTIVE 4-direction pattern. Catches accidental
# bypass list changes that would shadow either native or scaffold side.
NATIVE_INFO=0; NATIVE_SCHEMA=0; SCAFFOLD_EXAMPLES=0; SCAFFOLD_DOCTOR=0
if "$SCRIPT" --info 2>/dev/null | jq -e '.schema_version == "cost-telemetry-token-burn/v1" and (has("command") | not)' >/dev/null; then
  NATIVE_INFO=1
fi
if "$SCRIPT" --schema 2>/dev/null | jq -e '.ledger_row_required_fields' >/dev/null; then
  NATIVE_SCHEMA=1
fi
if "$SCRIPT" --examples --json 2>/dev/null | jq -e '.command == "examples" and .schema_version == "cost-telemetry-token-burn-probe/v1"' >/dev/null; then
  SCAFFOLD_EXAMPLES=1
fi
if "$SCRIPT" doctor --json 2>/dev/null | jq -e '.command == "doctor" and .schema_version == "cost-telemetry-token-burn-probe/v1"' >/dev/null; then
  SCAFFOLD_DOCTOR=1
fi
if [[ "$NATIVE_INFO" -eq 1 && "$NATIVE_SCHEMA" -eq 1 && "$SCAFFOLD_EXAMPLES" -eq 1 && "$SCAFFOLD_DOCTOR" -eq 1 ]]; then
  pass "4-DIRECTION routing: native --info + native --schema + scaffold --examples + scaffold doctor (sister to 1hshd.13 pattern)"
else fail "4-direction routing (info=$NATIVE_INFO schema=$NATIVE_SCHEMA examples=$SCAFFOLD_EXAMPLES doctor=$SCAFFOLD_DOCTOR)"; fi

if [[ "$fail_count" -gt 0 ]]; then
  printf 'SUMMARY pass=%d fail=%d\n' "$pass_count" "$fail_count" >&2
  exit 1
fi
printf 'SUMMARY pass=%d fail=0\n' "$pass_count"
