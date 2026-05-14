#!/usr/bin/env bash
# tests/customer-facing-observability-probe-canonical-cli.sh
# Canonical-cli surface tests for .flywheel/scripts/customer-facing-observability-probe.sh (scaffolded by
# bead flywheel-ws02m / scaffold-canonical-cli.sh).
#
# 13/13 PASS = canonical-cli-scoping checker green. TODO markers
# point at per-surface assertions the operator should fill in.
set -uo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd -P)"
SCRIPT="$ROOT/.flywheel/scripts/customer-facing-observability-probe.sh"

pass_count=0
fail_count=0
pass() { pass_count=$((pass_count + 1)); printf 'PASS %s\n' "$1"; }
fail() { fail_count=$((fail_count + 1)); printf 'FAIL %s\n' "$1" >&2; }

# Test 1: bash -n syntax
if bash -n "$SCRIPT" 2>/dev/null; then pass "syntax"; else fail "syntax"; fi

# Test 2: --info envelope is valid JSON with schema_version (native uses .mode field)
if "$SCRIPT" --info --json 2>/dev/null | jq -e '.schema_version and .mode == "info"' >/dev/null; then
  pass "--info emits canonical envelope (native .mode shape, NUANCED-PARTIAL-BYPASS)"
else fail "--info envelope"; fi

# Test 3: --schema returns valid JSON (native uses .mode field)
if "$SCRIPT" --schema 2>/dev/null | jq -e '.schema_version and .mode == "schema"' >/dev/null; then
  pass "--schema emits canonical envelope (native .mode shape, NUANCED-PARTIAL-BYPASS)"
else fail "--schema envelope"; fi

# Test 4: --examples returns valid JSON
if "$SCRIPT" --examples --json 2>/dev/null | jq -e '.command == "examples"' >/dev/null; then
  pass "--examples emits canonical envelope"
else fail "--examples envelope"; fi

# Test 5: doctor returns valid envelope (even pre-fill-in stub is valid JSON)
if "$SCRIPT" doctor --json 2>/dev/null | jq -e '.command == "doctor"' >/dev/null; then
  pass "doctor emits canonical envelope"
else fail "doctor envelope"; fi

# Test 6: health envelope
if "$SCRIPT" health --json 2>/dev/null | jq -e '.command == "health"' >/dev/null; then
  pass "health emits canonical envelope"
else fail "health envelope"; fi

# Test 7: repair --dry-run envelope (real scope per fillin contract)
if "$SCRIPT" repair --scope ledger_dir --dry-run --json 2>/dev/null | jq -e '.command == "repair" and .mode == "dry_run" and .status == "ok"' >/dev/null; then
  pass "repair --dry-run emits canonical envelope (real scope ledger_dir)"
else fail "repair --dry-run envelope"; fi

# Test 8: repair --apply without --idempotency-key REFUSES (rc=3)
"$SCRIPT" repair --scope ledger_dir --apply --json >/dev/null 2>&1
rc=$?
if [[ "$rc" -eq 3 ]]; then
  pass "repair --apply without --idempotency-key returns rc=3 (canonical refusal)"
else
  fail "repair --apply rc=$rc (expected 3)"
fi

# Test 9: validate (bare) refuses with rc=64 + missing_subject envelope
"$SCRIPT" validate >/tmp/1hshd-24-test9.json 2>&1
rc=$?
if [[ "$rc" -eq 64 ]] && jq -e '.command == "validate" and .status == "refused" and .reason == "missing_subject"' /tmp/1hshd-24-test9.json >/dev/null 2>&1; then
  pass "validate (bare) refuses with rc=64 + missing_subject envelope"
else fail "validate bare-refusal contract rc=$rc"; fi
rm -f /tmp/1hshd-24-test9.json

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

# Test 14: doctor probes load-bearing dev_root + ledger + per-client/product repos
if "$SCRIPT" doctor --json 2>/dev/null \
   | jq -e '[.checks[].name] | contains(["dev_root_exists","ledger_dir_writable","audit_log_dir_writable","client_repos_resolvable","product_repos_resolvable"])' >/dev/null; then
  pass "doctor probes dev_root + ledger + per-client/product repos (load-bearing for value-gap aggregation)"
else fail "doctor missing load-bearing probes"; fi

# Test 15: validate observability-state full-enum sweep — accept 3/3 valid + reject 1 invalid
sweep_pass=0
for state in no_aggregation_pipeline_yet draft wired; do
  if "$SCRIPT" validate observability-state "$state" 2>/dev/null | jq -e '.status == "ok"' >/dev/null; then
    sweep_pass=$((sweep_pass + 1))
  fi
done
"$SCRIPT" validate observability-state "phantom_state" >/tmp/1hshd-24-test15.json 2>&1
rc=$?
if [[ "$sweep_pass" -eq 3 ]] && [[ "$rc" -eq 1 ]] \
   && jq -e '.status == "reject" and .reason == "not_in_enum"' /tmp/1hshd-24-test15.json >/dev/null 2>&1; then
  pass "validate observability-state full-enum sweep (3 accept + 1 reject; cross-source with --schema)"
else fail "validate observability-state sweep accept=$sweep_pass/3 reject_rc=$rc"; fi
rm -f /tmp/1hshd-24-test15.json

# Test 16: validate client-slug accepts canonical client ({session})
if "$SCRIPT" validate client-slug "{session}" 2>/dev/null \
   | jq -e '.subject == "client-slug" and .status == "ok"' >/dev/null; then
  pass "validate client-slug accepts canonical client ({session})"
else fail "validate client-slug accept"; fi

# Test 17: validate client-slug REJECTS non-canonical with rc=1 + not_in_canonical_set
"$SCRIPT" validate client-slug "phantom_client" >/tmp/1hshd-24-test17.json 2>&1
rc=$?
if [[ "$rc" -eq 1 ]] && jq -e '.status == "reject" and .reason == "not_in_canonical_set"' /tmp/1hshd-24-test17.json >/dev/null 2>&1; then
  pass "validate client-slug rejects non-canonical with rc=1 + not_in_canonical_set"
else fail "validate client-slug reject rc=$rc"; fi
rm -f /tmp/1hshd-24-test17.json

# Test 18: validate freshness-hours accepts default 72 (matches CUSTOMER_OBS_FRESHNESS_HOURS default)
if "$SCRIPT" validate freshness-hours "72" 2>/dev/null \
   | jq -e '.subject == "freshness-hours" and .status == "ok" and .default == 72' >/dev/null; then
  pass "validate freshness-hours accepts default 72 (matches CUSTOMER_OBS_FRESHNESS_HOURS)"
else fail "validate freshness-hours 72 accept"; fi

# Test 19: 4-direction fidelity — native owns --info/--schema/--doctor flag; scaffold owns doctor verb
# (NUANCED-PARTIAL-BYPASS variant: scaffold-verb-first, then per-flag bypass for native)
native_info_ok="false"; native_doctor_flag_ok="false"; scaffold_doctor_verb_ok="false"
"$SCRIPT" --info --json 2>/dev/null | jq -e '.mode == "info" and .customer_observability_state' >/dev/null \
  && native_info_ok="true"
"$SCRIPT" --doctor --json 2>/dev/null | jq -e '.mode == "doctor"' >/dev/null \
  && native_doctor_flag_ok="true"
"$SCRIPT" doctor --json 2>/dev/null | jq -e '.command == "doctor" and (.checks | length) >= 5' >/dev/null \
  && scaffold_doctor_verb_ok="true"
if [[ "$native_info_ok" == "true" && "$native_doctor_flag_ok" == "true" && "$scaffold_doctor_verb_ok" == "true" ]]; then
  pass "4-direction fidelity (native --info/--doctor flag bypassed; scaffold doctor verb active) — NUANCED-PARTIAL-BYPASS"
else fail "4-direction fidelity native_info=$native_info_ok native_doctor_flag=$native_doctor_flag_ok scaffold_doctor_verb=$scaffold_doctor_verb_ok"; fi

if [[ "$fail_count" -gt 0 ]]; then
  printf 'SUMMARY pass=%d fail=%d\n' "$pass_count" "$fail_count" >&2
  exit 1
fi
printf 'SUMMARY pass=%d fail=0\n' "$pass_count"
