#!/usr/bin/env bash
# tests/frozen-pane-backtest-canonical-cli.sh
# Canonical-cli surface tests for .flywheel/scripts/frozen-pane-backtest.sh (scaffolded by
# bead flywheel-ws02m / scaffold-canonical-cli.sh).
#
# 13/13 PASS = canonical-cli-scoping checker green. TODO markers
# point at per-surface assertions the operator should fill in.
set -uo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd -P)"
SCRIPT="$ROOT/.flywheel/scripts/frozen-pane-backtest.sh"

pass_count=0
fail_count=0
pass() { pass_count=$((pass_count + 1)); printf 'PASS %s\n' "$1"; }
fail() { fail_count=$((fail_count + 1)); printf 'FAIL %s\n' "$1" >&2; }

# Test 1: bash -n syntax
if bash -n "$SCRIPT" 2>/dev/null; then pass "syntax"; else fail "syntax"; fi

# Test 2: --info envelope (PARTIAL-BYPASS — native v1 envelope with fixtures + goal_metrics)
if "$SCRIPT" --info --json 2>/dev/null | jq -e '.schema_version == "frozen-pane-backtest.v1" and .fixtures and .goal_metrics' >/dev/null; then
  pass "--info emits canonical envelope (native PARTIAL-BYPASS — v1 + fixtures + goal_metrics)"
else fail "--info envelope"; fi

# Test 3: --schema returns valid JSON (PARTIAL-BYPASS — native v1 with properties shape)
if "$SCRIPT" --schema 2>/dev/null | jq -e '.schema_version == "frozen-pane-backtest.v1" and .properties' >/dev/null; then
  pass "--schema emits canonical envelope (native PARTIAL-BYPASS — v1 + properties)"
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

# Test 7: repair --dry-run envelope (real scope per fillin)
if "$SCRIPT" repair --scope audit_log_dir --dry-run --json 2>/dev/null | jq -e '.command == "repair" and .mode == "dry_run" and .status == "ok"' >/dev/null; then
  pass "repair --dry-run emits canonical envelope (real scope audit_log_dir)"
else fail "repair --dry-run envelope"; fi

# Test 8: repair --apply without --idempotency-key REFUSES (rc=3)
"$SCRIPT" repair --scope audit_log_dir --apply --json >/dev/null 2>&1
rc=$?
if [[ "$rc" -eq 3 ]]; then
  pass "repair --apply without --idempotency-key returns rc=3 (canonical refusal)"
else
  fail "repair --apply rc=$rc (expected 3)"
fi

# Test 9: validate (bare) refuses rc=64 + missing_subject
"$SCRIPT" validate >/tmp/k8gcv-27-test9.json 2>&1
rc=$?
if [[ "$rc" -eq 64 ]] && jq -e '.command == "validate" and .status == "refused" and .reason == "missing_subject"' /tmp/k8gcv-27-test9.json >/dev/null 2>&1; then
  pass "validate (bare) refuses with rc=64 + missing_subject envelope"
else fail "validate bare-refusal contract rc=$rc"; fi
rm -f /tmp/k8gcv-27-test9.json

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

# Test 14: doctor probes load-bearing detector script
if "$SCRIPT" doctor --json 2>/dev/null \
   | jq -e '[.checks[].name] | contains(["detector_script_present","fixture_set","audit_log_dir_writable"])' >/dev/null; then
  pass "doctor probes detector_script (load-bearing) + fixture_set + audit_log_dir"
else fail "doctor missing load-bearing probes"; fi

# Test 15: validate fixture-name full-enum sweep (7 fixtures cross-source native --info .fixtures[])
sweep_pass=0
for f in frozen-1 frozen-2 frozen-3 frozen-4 frozen-5 healthy false-error; do
  if "$SCRIPT" validate fixture-name "$f" 2>/dev/null | jq -e '.status == "ok"' >/dev/null; then
    sweep_pass=$((sweep_pass + 1))
  fi
done
"$SCRIPT" validate fixture-name "phantom_fixture" >/tmp/k8gcv-27-test15.json 2>&1
rc=$?
if [[ "$sweep_pass" -eq 7 ]] && [[ "$rc" -eq 1 ]] \
   && jq -e '.status == "reject" and .reason == "not_in_enum"' /tmp/k8gcv-27-test15.json >/dev/null 2>&1; then
  pass "validate fixture-name full-enum sweep (7 accept + 1 reject; cross-source native --info .fixtures[])"
else fail "validate fixture-name sweep accept=$sweep_pass/7 reject_rc=$rc"; fi
rm -f /tmp/k8gcv-27-test15.json

# Test 16: validate metric-name full-enum sweep (6 metrics cross-source native --info .goal_metrics[])
sweep_pass2=0
for m in true_freezes_caught known_false_error_suppressed detection_latency_p95_seconds false_recovery_count unknown_auto_recovery_count l60_signals_present_count; do
  if "$SCRIPT" validate metric-name "$m" 2>/dev/null | jq -e '.status == "ok"' >/dev/null; then
    sweep_pass2=$((sweep_pass2 + 1))
  fi
done
if [[ "$sweep_pass2" -eq 6 ]]; then
  pass "validate metric-name full-enum sweep (6 accept; cross-source native --info .goal_metrics[])"
else fail "validate metric-name sweep accept=$sweep_pass2/6"; fi

# Test 17: validate run-mode full-enum sweep (cross-source native --apply/--dry-run)
sweep_pass3=0
for r in dry_run apply; do
  if "$SCRIPT" validate run-mode "$r" 2>/dev/null | jq -e '.status == "ok"' >/dev/null; then
    sweep_pass3=$((sweep_pass3 + 1))
  fi
done
if [[ "$sweep_pass3" -eq 2 ]]; then
  pass "validate run-mode full-enum sweep (2 accept; cross-source native --apply/--dry-run)"
else fail "validate run-mode sweep accept=$sweep_pass3/2"; fi

# Test 18: PARTIAL-BYPASS — native --doctor and --health both preserved (legacy v1 envelopes)
native_doctor_ok="false"; native_health_ok="false"
"$SCRIPT" --doctor --json 2>/dev/null | jq -e '.schema_version == "frozen-pane-backtest.v1" and .mode == "doctor" and .detector_present != null' >/dev/null && native_doctor_ok="true"
"$SCRIPT" --health 2>/dev/null | jq -e '.schema_version == "frozen-pane-backtest.v1" and .mode == "doctor"' >/dev/null && native_health_ok="true"
if [[ "$native_doctor_ok" == "true" && "$native_health_ok" == "true" ]]; then
  pass "PARTIAL-BYPASS: native --doctor + --health both preserved (legacy v1 envelopes)"
else fail "PARTIAL-BYPASS native_doctor=$native_doctor_ok native_health=$native_health_ok"; fi

# Test 19: 4-direction fidelity — native --info/--schema/--doctor/--health + scaffold --examples/doctor verb
native_info_ok="false"; native_schema_ok="false"; scaffold_examples_ok="false"; scaffold_doctor_verb_ok="false"
"$SCRIPT" --info --json 2>/dev/null | jq -e '.fixtures and .goal_metrics' >/dev/null && native_info_ok="true"
"$SCRIPT" --schema 2>/dev/null | jq -e '.properties' >/dev/null && native_schema_ok="true"
"$SCRIPT" --examples --json 2>/dev/null | jq -e '.command == "examples"' >/dev/null && scaffold_examples_ok="true"
"$SCRIPT" doctor --json 2>/dev/null | jq -e '.command == "doctor" and (.checks | length) >= 5' >/dev/null && scaffold_doctor_verb_ok="true"
if [[ "$native_info_ok" == "true" && "$native_schema_ok" == "true" && "$scaffold_examples_ok" == "true" && "$scaffold_doctor_verb_ok" == "true" ]]; then
  pass "4-direction fidelity (native --info/--schema bypassed; scaffold --examples + doctor verb active) — PARTIAL-BYPASS intact"
else fail "4-direction fidelity native_info=$native_info_ok native_schema=$native_schema_ok scaffold_examples=$scaffold_examples_ok scaffold_doctor=$scaffold_doctor_verb_ok"; fi

if [[ "$fail_count" -gt 0 ]]; then
  printf 'SUMMARY pass=%d fail=%d\n' "$pass_count" "$fail_count" >&2
  exit 1
fi
printf 'SUMMARY pass=%d fail=0\n' "$pass_count"
