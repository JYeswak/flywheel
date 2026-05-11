#!/usr/bin/env bash
# tests/fleet-coherence-launchd-canonical-cli.sh
# Canonical-cli surface tests for .flywheel/scripts/fleet-coherence-launchd.sh (scaffolded by
# bead flywheel-ws02m / scaffold-canonical-cli.sh).
#
# 13/13 PASS = canonical-cli-scoping checker green. TODO markers
# point at per-surface assertions the operator should fill in.
set -uo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd -P)"
SCRIPT="$ROOT/.flywheel/scripts/fleet-coherence-launchd.sh"

pass_count=0
fail_count=0
pass() { pass_count=$((pass_count + 1)); printf 'PASS %s\n' "$1"; }
fail() { fail_count=$((fail_count + 1)); printf 'FAIL %s\n' "$1" >&2; }

# Test 1: bash -n syntax
if bash -n "$SCRIPT" 2>/dev/null; then pass "syntax"; else fail "syntax"; fi

# Test 2: --info envelope is valid JSON with schema_version
if "$SCRIPT" --info --json 2>/dev/null | jq -e '.schema_version and .command == "info"' >/dev/null; then
  pass "--info emits canonical envelope"
else fail "--info envelope"; fi

# Test 3: --schema returns valid JSON
if "$SCRIPT" --schema 2>/dev/null | jq -e '.schema_version and .command == "schema"' >/dev/null; then
  pass "--schema emits canonical envelope"
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
if "$SCRIPT" repair --scope state_dir --dry-run --json 2>/dev/null | jq -e '.command == "repair" and .mode == "dry_run" and .status == "ok"' >/dev/null; then
  pass "repair --dry-run emits canonical envelope (real scope state_dir)"
else fail "repair --dry-run envelope"; fi

# Test 8: repair --apply without --idempotency-key REFUSES (rc=3)
"$SCRIPT" repair --scope state_dir --apply --json >/dev/null 2>&1
rc=$?
if [[ "$rc" -eq 3 ]]; then
  pass "repair --apply without --idempotency-key returns rc=3 (canonical refusal)"
else
  fail "repair --apply rc=$rc (expected 3)"
fi

# Test 9: validate (bare) refuses rc=64 + missing_subject
"$SCRIPT" validate >/tmp/1hshd-27-test9.json 2>&1
rc=$?
if [[ "$rc" -eq 64 ]] && jq -e '.command == "validate" and .status == "refused" and .reason == "missing_subject"' /tmp/1hshd-27-test9.json >/dev/null 2>&1; then
  pass "validate (bare) refuses with rc=64 + missing_subject envelope"
else fail "validate bare-refusal contract rc=$rc"; fi
rm -f /tmp/1hshd-27-test9.json

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

# Test 14: doctor probes load-bearing launchctl/plutil + state_dir + install_plist + launchagents_dir
if "$SCRIPT" doctor --json 2>/dev/null \
   | jq -e '[.checks[].name] | contains(["launchctl_available","plutil_available","state_dir_writable","install_plist_present","launchagents_dir_present"])' >/dev/null; then
  pass "doctor probes launchctl/plutil + state_dir + install_plist + launchagents_dir (load-bearing for LaunchAgent lifecycle)"
else fail "doctor missing load-bearing probes"; fi

# Test 15: validate label accepts canonical com.zeststream.flywheel namespace
if "$SCRIPT" validate label "com.zeststream.flywheel.fleet-coherence" 2>/dev/null \
   | jq -e '.subject == "label" and .status == "ok"' >/dev/null; then
  pass "validate label accepts canonical com.zeststream.flywheel namespace"
else fail "validate label accept"; fi

# Test 16: validate label REJECTS non-canonical label
"$SCRIPT" validate label "com.example.foo" >/tmp/1hshd-27-test16.json 2>&1
rc=$?
if [[ "$rc" -eq 1 ]] && jq -e '.status == "reject" and .reason == "pattern_mismatch"' /tmp/1hshd-27-test16.json >/dev/null 2>&1; then
  pass "validate label rejects non-canonical namespace with rc=1 + pattern_mismatch"
else fail "validate label reject rc=$rc"; fi
rm -f /tmp/1hshd-27-test16.json

# Test 17: validate cadence-seconds accepts default 60 + rejects out-of-range
ok="false"; bad_rc=0
"$SCRIPT" validate cadence-seconds "60" 2>/dev/null | jq -e '.status == "ok" and .default == 60' >/dev/null && ok="true"
"$SCRIPT" validate cadence-seconds "5" >/tmp/1hshd-27-test17.json 2>&1; bad_rc=$?
if [[ "$ok" == "true" && "$bad_rc" -eq 1 ]] && jq -e '.status == "reject" and .reason == "out_of_range_or_not_integer"' /tmp/1hshd-27-test17.json >/dev/null 2>&1; then
  pass "validate cadence-seconds accepts 60 + rejects 5 (out-of-range; matches launchd StartInterval contract)"
else fail "validate cadence-seconds ok=$ok bad_rc=$bad_rc"; fi
rm -f /tmp/1hshd-27-test17.json

# Test 18: SELECTIVE-VERB-BYPASS — `validate plist` bypasses to NATIVE (legacy contract preserved)
# Native emits cadence_ok / helper_command_ok / install_plist / install_plist_lint keys
if "$SCRIPT" validate plist --json 2>/dev/null \
   | jq -e '.cadence_ok != null and .install_plist != null' >/dev/null; then
  pass "validate plist bypasses to NATIVE (SELECTIVE-VERB-BYPASS — legacy contract preserved)"
else fail "validate plist native bypass broken"; fi

# Test 19: 4-direction fidelity — scaffold owns --info/doctor verb; native owns `validate plist` + status + bare invocation
scaffold_info_ok="false"; native_status_ok="false"; native_bare_ok="false"; scaffold_doctor_verb_ok="false"
"$SCRIPT" --info --json 2>/dev/null | jq -e '.command == "info"' >/dev/null && scaffold_info_ok="true"
"$SCRIPT" status --json 2>/dev/null | jq -e '.contract == "fleet-coherence-launchd/v1"' >/dev/null && native_status_ok="true"
"$SCRIPT" 2>/dev/null | jq -e '.contract == "fleet-coherence-launchd/v1"' >/dev/null && native_bare_ok="true"
"$SCRIPT" doctor --json 2>/dev/null | jq -e '.command == "doctor" and (.checks | length) >= 5' >/dev/null && scaffold_doctor_verb_ok="true"
if [[ "$scaffold_info_ok" == "true" && "$native_status_ok" == "true" && "$native_bare_ok" == "true" && "$scaffold_doctor_verb_ok" == "true" ]]; then
  pass "4-direction fidelity (scaffold --info/doctor + native status/bare/validate plist preserved) — SELECTIVE-VERB-BYPASS"
else fail "4-direction fidelity scaffold_info=$scaffold_info_ok native_status=$native_status_ok native_bare=$native_bare_ok scaffold_doctor=$scaffold_doctor_verb_ok"; fi

if [[ "$fail_count" -gt 0 ]]; then
  printf 'SUMMARY pass=%d fail=%d\n' "$pass_count" "$fail_count" >&2
  exit 1
fi
printf 'SUMMARY pass=%d fail=0\n' "$pass_count"
