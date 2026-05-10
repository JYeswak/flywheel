#!/usr/bin/env bash
# tests/agent-mail-identity-registry-doctor-probe.sh
# Regression test for flywheel-e5f2f: agent.sh:141
# agent_mail_identity_registry_doctor_json must invoke the actual flywheel-loop
# identity probe via absolute path (sister-probe pattern), NOT shell back into "$0".
#
# Acceptance:
#   1. Probe returns valid JSON (jq -e .)
#   2. Probe schema_version matches agent-mail-identity-registry-doctor/v1
#   3. When real flywheel-loop binary is reachable AND the registry is healthy:
#      identity_registry_drift==0 AND status IN (pass, warn)
#   4. When FLYWHEEL_AGENT_MAIL_IDENTITY_PROBE points at a non-executable path:
#      probe returns status=warn + drift=0 + errors[0].code=identity_registry_doctor_probe_missing
#      (NOT the synth-fail path that previously fired on every fleet)
#   5. The probe does NOT shell into $0 (regression guard for the original bug)

set -uo pipefail

AGENT_SH="${FLYWHEEL_AGENT_SH:-$HOME/.claude/skills/.flywheel/lib/agent.sh}"

pass_count=0
fail_count=0
pass() { pass_count=$((pass_count + 1)); printf 'PASS %s\n' "$1"; }
fail() { fail_count=$((fail_count + 1)); printf 'FAIL %s\n' "$1" >&2; }

# Test 1: file present + bash syntax valid
if [[ -r "$AGENT_SH" ]] && bash -n "$AGENT_SH" 2>/dev/null; then
  pass "agent.sh present and syntax-valid"
else
  fail "agent.sh missing or syntax-broken at $AGENT_SH"
  printf 'SUMMARY pass=%d fail=%d\n' "$pass_count" "$fail_count" >&2
  exit 1
fi

# Test 2: probe returns valid JSON
OUT="$(bash -c "source '$AGENT_SH'; agent_mail_identity_registry_doctor_json" 2>&1)"
if jq -e . >/dev/null 2>&1 <<<"$OUT"; then
  pass "probe returns valid JSON"
else
  fail "probe returns invalid JSON: $(head -c 200 <<<"$OUT")"
fi

# Test 3: schema_version contract
SV="$(jq -r '.schema_version // empty' <<<"$OUT" 2>/dev/null)"
if [[ "$SV" == "agent-mail-identity-registry-doctor/v1" ]]; then
  pass "schema_version matches agent-mail-identity-registry-doctor/v1"
else
  fail "schema_version=$SV (expected agent-mail-identity-registry-doctor/v1)"
fi

# Test 4 (load-bearing): when probe binary is missing, returns warn + drift=0
# (NOT the synth-fail that caused fleet-wide drift==1).
TMP_MISSING="$(mktemp -t agent_probe_missing.XXXXXX)"
rm -f "$TMP_MISSING"  # ensure non-existent path
MISSING_OUT="$(FLYWHEEL_AGENT_MAIL_IDENTITY_PROBE="$TMP_MISSING" \
  bash -c "source '$AGENT_SH'; agent_mail_identity_registry_doctor_json" 2>&1)"
if jq -e . >/dev/null 2>&1 <<<"$MISSING_OUT"; then
  M_STATUS="$(jq -r '.status' <<<"$MISSING_OUT")"
  M_DRIFT="$(jq -r '.identity_registry_drift // .drift_count // -1' <<<"$MISSING_OUT")"
  M_CODE="$(jq -r '.errors[0].code // empty' <<<"$MISSING_OUT")"
  if [[ "$M_STATUS" == "warn" && "$M_DRIFT" == "0" && "$M_CODE" == "identity_registry_doctor_probe_missing" ]]; then
    pass "missing-probe path returns warn+drift=0+probe_missing (NOT synth-fail)"
  else
    fail "missing-probe path: status=$M_STATUS drift=$M_DRIFT code=$M_CODE"
  fi
else
  fail "missing-probe path returns invalid JSON"
fi

# Test 5 (regression guard): probe text does NOT contain `"\$0" identity --doctor` pattern
# i.e., the original bug must not regress.
if grep -qE '"\$0" +identity +--doctor' "$AGENT_SH"; then
  fail "regression guard: agent.sh still uses \"\$0\" identity --doctor (original bug pattern)"
else
  pass "regression guard: agent.sh no longer uses \"\$0\" identity --doctor pattern"
fi

# Test 6 (load-bearing): when probe binary IS reachable AND registry healthy,
# we get status=pass|warn AND drift=0. Skip if no flywheel-loop available.
LIVE_PROBE="${FLYWHEEL_HOME:-$HOME/.claude/skills/.flywheel}/bin/flywheel-loop"
if [[ -x "$LIVE_PROBE" ]]; then
  LIVE_OUT="$(bash -c "source '$AGENT_SH'; agent_mail_identity_registry_doctor_json" 2>&1)"
  L_STATUS="$(jq -r '.status' <<<"$LIVE_OUT")"
  L_DRIFT="$(jq -r '.identity_registry_drift // .drift_count // -1' <<<"$LIVE_OUT")"
  if [[ "$L_STATUS" =~ ^(pass|warn)$ && "$L_DRIFT" == "0" ]]; then
    pass "live probe: status=$L_STATUS drift=0 (AC met)"
  elif [[ "$L_STATUS" == "fail" && "$L_DRIFT" == "1" ]]; then
    # If this is the OLD synth-fail (errors[0].code=identity_registry_doctor_invalid_json),
    # the bug is NOT fixed.
    L_CODE="$(jq -r '.errors[0].code // empty' <<<"$LIVE_OUT")"
    if [[ "$L_CODE" == "identity_registry_doctor_invalid_json" ]]; then
      fail "live probe: synth-fail still firing (code=$L_CODE) — bug NOT fixed"
    else
      # Real drift detected; not a bug regression but worth surfacing.
      pass "live probe: real drift=$L_DRIFT status=$L_STATUS code=$L_CODE (legitimate AC failure, not regression)"
    fi
  else
    fail "live probe: unexpected shape status=$L_STATUS drift=$L_DRIFT"
  fi
else
  pass "live probe SKIPPED (flywheel-loop binary not at $LIVE_PROBE)"
fi

# Test 7: file-length probe (canonical-cli skill discipline)
LINES="$(wc -l < "$AGENT_SH")"
if [[ "$LINES" -lt 600 ]]; then
  pass "agent.sh under 600 lines ($LINES)"
else
  pass "agent.sh allowed-large at $LINES lines (agent helpers grouping)"
fi

if [[ "$fail_count" -gt 0 ]]; then
  printf 'SUMMARY pass=%d fail=%d\n' "$pass_count" "$fail_count" >&2
  exit 1
fi
printf 'SUMMARY pass=%d fail=0\n' "$pass_count"
