#!/usr/bin/env bash
# tests/fleet-conformance-probe-canonical-cli.sh
# Canonical-cli surface tests for .flywheel/scripts/fleet-conformance-probe.sh (scaffolded by
# bead flywheel-ws02m / scaffold-canonical-cli.sh).
#
# 13/13 PASS = canonical-cli-scoping checker green. TODO markers
# point at per-surface assertions the operator should fill in.
set -uo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd -P)"
SCRIPT="$ROOT/.flywheel/scripts/fleet-conformance-probe.sh"

pass_count=0
fail_count=0
pass() { pass_count=$((pass_count + 1)); printf 'PASS %s\n' "$1"; }
fail() { fail_count=$((fail_count + 1)); printf 'FAIL %s\n' "$1" >&2; }

# Test 1: bash -n syntax
if bash -n "$SCRIPT" 2>/dev/null; then pass "syntax"; else fail "syntax"; fi

# Test 2: --info native PASSTHRU envelope (PARTIAL-BYPASS — emits the
# fleet-conformance-observatory/v1 schema_version + .axes + .purpose)
if "$SCRIPT" --info 2>/dev/null | jq -e '.schema_version == "fleet-conformance-observatory/v1" and (.axes | length == 6)' >/dev/null; then
  pass "--info emits native PASSTHRU envelope (.schema_version observatory/v1 + 6 axes)"
else fail "--info native envelope"; fi

# Test 3: --schema native PASSTHRU (full JSON-Schema for fleet_conformance result)
if "$SCRIPT" --schema 2>/dev/null | jq -e '.type == "object" and .properties.fleet_conformance' >/dev/null; then
  pass "--schema emits native JSON-Schema (.type=object + .properties.fleet_conformance)"
else fail "--schema native envelope"; fi

# Test 4: --examples native PASSTHRU (text invocation lines, not canonical envelope)
if "$SCRIPT" --examples 2>/dev/null | grep -q 'fleet-conformance-probe.sh --fleet'; then
  pass "--examples emits native PASSTHRU example invocations"
else fail "--examples native envelope"; fi

# Test 5: doctor scaffold envelope (>=5 named probes per AG3)
if "$SCRIPT" doctor --json 2>/dev/null | jq -e '.command == "doctor" and (.checks | length >= 5)' >/dev/null; then
  pass "doctor emits scaffold envelope with >=5 checks"
else fail "doctor envelope"; fi

# Test 6: health envelope (scaffold)
if "$SCRIPT" health --json 2>/dev/null | jq -e '.command == "health"' >/dev/null; then
  pass "health emits scaffold envelope"
else fail "health envelope"; fi

# Test 7: repair --dry-run envelope (calibrated to real scope)
if "$SCRIPT" repair --scope cache_dir --dry-run --json 2>/dev/null | jq -e '.command == "repair" and .mode == "dry_run" and .status == "ok"' >/dev/null; then
  pass "repair --dry-run emits scaffold envelope (real scope cache_dir)"
else fail "repair --dry-run envelope"; fi

# Test 8: repair --apply without --idempotency-key REFUSES (rc=3)
"$SCRIPT" repair --scope cache_dir --apply --json >/dev/null 2>&1
rc=$?
if [[ "$rc" -eq 3 ]]; then
  pass "repair --apply without --idempotency-key returns rc=3 (canonical refusal)"
else
  fail "repair --apply rc=$rc (expected 3)"
fi

# Test 9: validate envelope (bare validate refuses with rc=64; calibrated)
"$SCRIPT" validate >/tmp/5ke66-11-test9.json 2>&1
rc=$?
if [[ "$rc" -eq 64 ]] && jq -e '.command == "validate" and .status == "refused" and .reason == "missing_subject"' /tmp/5ke66-11-test9.json >/dev/null 2>&1; then
  pass "validate (bare) refuses with rc=64 + missing_subject envelope"
else fail "validate bare-refusal contract rc=$rc"; fi
rm -f /tmp/5ke66-11-test9.json

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
# This surface is wzjo9.1.7 PARTIAL-BYPASS: --info/--schema/--examples flags
# route to native python heredoc; verb subcommands route to scaffold.
# (Sister to 5ke66.6 daily-report — same variant.)

# Test 14: PARTIAL-BYPASS contract is annotated in the script
if grep -q 'WZJO9.1.7 PARTIAL-BYPASS' "$SCRIPT"; then
  pass "script annotates WZJO9.1.7 PARTIAL-BYPASS variant (discoverable via grep)"
else fail "PARTIAL-BYPASS annotation missing"; fi

# Test 15: dual-direction fidelity — --info goes native (.schema_version
# observatory/v1) AND doctor goes scaffold (.command="doctor")
INFO_NATIVE=0; DOCTOR_SCAFFOLD=0
if "$SCRIPT" --info 2>/dev/null | jq -e '.schema_version == "fleet-conformance-observatory/v1"' >/dev/null; then
  INFO_NATIVE=1
fi
if "$SCRIPT" doctor --json 2>/dev/null | jq -e '.schema_version == "fleet-conformance-probe/v1" and .command == "doctor"' >/dev/null; then
  DOCTOR_SCAFFOLD=1
fi
if [[ "$INFO_NATIVE" -eq 1 && "$DOCTOR_SCAFFOLD" -eq 1 ]]; then
  pass "PARTIAL bypass dual-direction: --info goes native (observatory/v1), doctor goes scaffold (probe/v1)"
else fail "PARTIAL bypass dual-direction (info_native=$INFO_NATIVE doctor_scaffold=$DOCTOR_SCAFFOLD)"; fi

# Test 16: validate conformance-axis accepts each of the 6 native axes
ALL_OK=1
for AXIS in canonical_l_rule_coverage doctor_status identity_drift meta_rule_cache_freshness mission_lock_age agents_mtime_age; do
  if ! "$SCRIPT" validate conformance-axis "$AXIS" 2>/dev/null \
       | jq -e --arg v "$AXIS" '.subject == "conformance-axis" and .status == "ok" and .value == $v' >/dev/null; then
    ALL_OK=0; break
  fi
done
if [[ "$ALL_OK" -eq 1 ]]; then
  pass "validate conformance-axis accepts all 6 native axes (full-enum sweep)"
else fail "validate conformance-axis full-enum sweep"; fi

# Test 17: validate conformance-axis REJECTS unknown axis (rc=1 + valid_axes list)
"$SCRIPT" validate conformance-axis "unknown_axis" >/tmp/5ke66-11-test17.json 2>&1
rc=$?
if [[ "$rc" -eq 1 ]] && jq -e '.status == "reject" and .reason == "not_in_enum" and (.valid_axes | length == 6)' /tmp/5ke66-11-test17.json >/dev/null 2>&1; then
  pass "validate conformance-axis rejects unknown_axis with rc=1 + valid_axes enumeration"
else fail "validate conformance-axis reject rc=$rc"; fi
rm -f /tmp/5ke66-11-test17.json

# Test 18: doctor probes load-bearing python3 + loops_dir + canonical_agents
if "$SCRIPT" doctor --json 2>/dev/null \
   | jq -e '[.checks[].name] | contains(["python3_available","loops_dir_readable","canonical_agents_readable"])' >/dev/null; then
  pass "doctor probes python3 + loops_dir + canonical_agents (load-bearing for conformance scoring)"
else fail "doctor missing load-bearing probes"; fi

# Test 19: native --info envelope's axes field matches scaffold validator's
# valid_axes — cross-source consistency check (catches drift between native
# heredoc enum and scaffold validator enum). Uses validate-reject envelope
# to surface the scaffold's enum (since --schema validate would route to
# native PASSTHRU which doesn't understand the positional arg).
TMP_NATIVE_AXES="$(mktemp -t fleet-conf-test19-XXXXXX)"
"$SCRIPT" --info >"$TMP_NATIVE_AXES" 2>/dev/null
NATIVE_AXES_SORTED="$(jq -r '.axes | sort | join(",")' "$TMP_NATIVE_AXES" 2>/dev/null)"
SCAFFOLD_AXES_SORTED="$("$SCRIPT" validate conformance-axis "__probe_unknown__" 2>/dev/null | jq -r '.valid_axes | sort | join(",")' 2>/dev/null)"
if [[ -n "$NATIVE_AXES_SORTED" ]] && [[ "$NATIVE_AXES_SORTED" == "$SCAFFOLD_AXES_SORTED" ]]; then
  pass "cross-source consistency: native --info .axes == scaffold validate .valid_axes ($NATIVE_AXES_SORTED)"
else fail "axis enum drift: native='$NATIVE_AXES_SORTED' scaffold='$SCAFFOLD_AXES_SORTED'"; fi
rm -f "$TMP_NATIVE_AXES"

if [[ "$fail_count" -gt 0 ]]; then
  printf 'SUMMARY pass=%d fail=%d\n' "$pass_count" "$fail_count" >&2
  exit 1
fi
printf 'SUMMARY pass=%d fail=0\n' "$pass_count"
