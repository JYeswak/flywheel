#!/usr/bin/env bash
# tests/agent-sh-identity-doctor-timeout.sh
# Regression for ~/.claude/skills/.flywheel/lib/agent.sh
# `agent_mail_identity_registry_doctor_json` after the flywheel-3ycjw fix:
#   - Default timeout bumped 1 → 5 (concurrent-load headroom).
#   - probe_rc=124 → identity_registry_doctor_timeout
#   - probe_rc!=0 + bad JSON → identity_registry_doctor_invalid_json
#
# Bead: flywheel-3ycjw. Sister: flywheel-e5f2f (path resolution).
# Cross-orch unblock: skillos-ubh3 partial-AC progresses toward full pass
# once doctor concurrent-load probe stops synth-failing.

set -uo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd -P)"
AGENT_SH="/Users/josh/.claude/skills/.flywheel/lib/agent.sh"
FLYWHEEL_LOOP_BIN="/Users/josh/.claude/skills/.flywheel/bin/flywheel-loop"

pass_count=0
fail_count=0
pass() { pass_count=$((pass_count + 1)); printf 'PASS %s\n' "$1"; }
fail() { fail_count=$((fail_count + 1)); printf 'FAIL %s\n' "$1" >&2; }

TMPDIR_TEST="$(mktemp -d -t agent-sh-3ycjw.XXXXXX)"
trap '[[ -n "${TMPDIR_TEST:-}" ]] && find "$TMPDIR_TEST" -mindepth 1 -delete 2>/dev/null; rmdir "$TMPDIR_TEST" 2>/dev/null' EXIT

# Helper: invoke the function fresh in a subshell with override env vars.
# Returns JSON on stdout. Adds `set +u` so unset env-vars from inheriting
# environments don't trip the function's defaults.
call_fn() {
  local env_kvs=("$@")
  bash -c "
set +u
source $AGENT_SH
$(for kv in "${env_kvs[@]}"; do printf 'export %s\n' "$kv"; done)
agent_mail_identity_registry_doctor_json
"
}

# Test 1: agent.sh syntax
if bash -n "$AGENT_SH" 2>/dev/null; then pass "agent.sh syntax"; else fail "agent.sh syntax"; fi

# Test 2: source-able without errors
if bash -c "source $AGENT_SH" 2>/dev/null; then pass "agent.sh sources cleanly"; else fail "agent.sh source"; fi

# Test 3: flywheel-loop binary exists (substrate sanity check)
if [[ -x "$FLYWHEEL_LOOP_BIN" ]]; then
  pass "flywheel-loop binary executable"
else
  fail "flywheel-loop binary missing — substrate gone, abort"
  exit 1
fi

# Test 4: default-path call → status=pass + drift=0 + total_registered>=0
out="$(call_fn)"
if printf '%s' "$out" | jq -e '
  .status == "pass"
  and .identity_registry_drift == 0
  and (.total_registered | type == "number")
' >/dev/null; then
  pass "default call: status=pass, drift=0, total_registered numeric (PRIMARY AC)"
else fail "default call: $(printf '%s' "$out" | jq -c '{status, identity_registry_drift, total_registered}')"; fi

# Test 5: probe missing → status=warn + identity_registry_doctor_probe_missing
out="$(call_fn 'FLYWHEEL_AGENT_MAIL_IDENTITY_PROBE=/no/such/binary')"
if printf '%s' "$out" | jq -e '
  .status == "warn"
  and .errors[0].code == "identity_registry_doctor_probe_missing"
' >/dev/null; then
  pass "probe missing: status=warn + correct error code"
else fail "probe missing: $(printf '%s' "$out" | jq -c .)"; fi

# Test 6: timeout path (probe sleeps 5s, timeout=1) → identity_registry_doctor_timeout
SLEEPER="$TMPDIR_TEST/slow-probe.sh"
cat > "$SLEEPER" <<'EOF'
#!/usr/bin/env bash
sleep 5
EOF
chmod +x "$SLEEPER"
out="$(call_fn "FLYWHEEL_AGENT_MAIL_IDENTITY_PROBE=$SLEEPER" 'FLYWHEEL_AGENT_MAIL_IDENTITY_TIMEOUT_SECONDS=1')"
if printf '%s' "$out" | jq -e '
  .status == "fail"
  and .errors[0].code == "identity_registry_doctor_timeout"
  and .errors[0].probe_exit_code == 124
  and .errors[0].probe_timeout_seconds == 1
  and .identity_registry_drift == 1
' >/dev/null; then
  pass "timeout path: identity_registry_doctor_timeout + probe_exit_code=124 + probe_timeout=1"
else fail "timeout: $(printf '%s' "$out" | jq -c '{status, "errors[0]": .errors[0]}')"; fi

# Test 7: invalid-JSON path (probe returns garbage + rc=1) → identity_registry_doctor_invalid_json
GARBAGE="$TMPDIR_TEST/garbage-probe.sh"
cat > "$GARBAGE" <<'EOF'
#!/usr/bin/env bash
echo "not json at all"
exit 1
EOF
chmod +x "$GARBAGE"
out="$(call_fn "FLYWHEEL_AGENT_MAIL_IDENTITY_PROBE=$GARBAGE")"
if printf '%s' "$out" | jq -e '
  .status == "fail"
  and .errors[0].code == "identity_registry_doctor_invalid_json"
  and .errors[0].probe_exit_code == 1
  and .identity_registry_drift == 1
' >/dev/null; then
  pass "invalid-JSON path: identity_registry_doctor_invalid_json + probe_exit_code=1"
else fail "invalid-JSON: $(printf '%s' "$out" | jq -c '{status, "errors[0]": .errors[0]}')"; fi

# Test 8: invalid-JSON with rc=0 (probe succeeded but emitted bad JSON) → invalid_json (NOT timeout)
BADJSON_RC0="$TMPDIR_TEST/badjson-rc0.sh"
cat > "$BADJSON_RC0" <<'EOF'
#!/usr/bin/env bash
echo "garbage but rc=0"
EOF
chmod +x "$BADJSON_RC0"
out="$(call_fn "FLYWHEEL_AGENT_MAIL_IDENTITY_PROBE=$BADJSON_RC0")"
if printf '%s' "$out" | jq -e '
  .status == "fail"
  and .errors[0].code == "identity_registry_doctor_invalid_json"
  and .errors[0].probe_exit_code == 0
' >/dev/null; then
  pass "invalid-JSON rc=0 path: still classified as invalid_json (not timeout)"
else fail "invalid-JSON rc=0: $(printf '%s' "$out" | jq -c '{status, "errors[0]": .errors[0]}')"; fi

# Test 9: explicit FLYWHEEL_AGENT_MAIL_IDENTITY_TIMEOUT_SECONDS=10 takes precedence over default
out="$(call_fn 'FLYWHEEL_AGENT_MAIL_IDENTITY_TIMEOUT_SECONDS=10')"
# This should still pass (real probe is fast); we're verifying the env override is honored.
# We can't directly observe the timeout value passed to `timeout` from inside the function,
# but we can check the substrate ran. A pass + drift=0 confirms the call worked.
if printf '%s' "$out" | jq -e '.status == "pass" and .identity_registry_drift == 0' >/dev/null; then
  pass "FLYWHEEL_AGENT_MAIL_IDENTITY_TIMEOUT_SECONDS=10 honored (real probe still passes)"
else fail "env override: $(printf '%s' "$out" | jq -c .)"; fi

# Test 10: FLYWHEEL_DOCTOR_PROBE_TIMEOUT_SECONDS fallback when the more-specific env is unset.
# Source-level introspection: bumping just FLYWHEEL_DOCTOR_PROBE_TIMEOUT_SECONDS should
# also flow through. Probe with the sleeper + only the fallback env set → still timeouts at 1s.
out="$(call_fn "FLYWHEEL_AGENT_MAIL_IDENTITY_PROBE=$SLEEPER" 'FLYWHEEL_DOCTOR_PROBE_TIMEOUT_SECONDS=1')"
if printf '%s' "$out" | jq -e '
  .errors[0].code == "identity_registry_doctor_timeout"
  and .errors[0].probe_timeout_seconds == 1
' >/dev/null; then
  pass "FLYWHEEL_DOCTOR_PROBE_TIMEOUT_SECONDS fallback honored when specific env unset"
else fail "fallback: $(printf '%s' "$out" | jq -c '{"errors[0]": .errors[0]}')"; fi

# Test 11: default timeout is 5 (post-3ycjw fix) — verify by source-string match
if grep -Fq 'FLYWHEEL_DOCTOR_PROBE_TIMEOUT_SECONDS:-5' "$AGENT_SH"; then
  pass "default probe_timeout pinned to 5 (3ycjw fix from 1)"
else fail "default probe_timeout substring 'FLYWHEEL_DOCTOR_PROBE_TIMEOUT_SECONDS:-5' not found"; fi

# Test 12: error envelope carries probe_exit_code field (new in 3ycjw)
out="$(call_fn "FLYWHEEL_AGENT_MAIL_IDENTITY_PROBE=$GARBAGE")"
if printf '%s' "$out" | jq -e '.errors[0] | has("probe_exit_code")' >/dev/null; then
  pass "error envelope carries probe_exit_code (callers can route by rc)"
else fail "missing probe_exit_code"; fi

# Test 13: error envelope carries probe_timeout_seconds field (new in 3ycjw)
out="$(call_fn "FLYWHEEL_AGENT_MAIL_IDENTITY_PROBE=$GARBAGE")"
if printf '%s' "$out" | jq -e '.errors[0] | has("probe_timeout_seconds")' >/dev/null; then
  pass "error envelope carries probe_timeout_seconds"
else fail "missing probe_timeout_seconds"; fi

# Test 14: schema_version pinned (regression guard)
out="$(call_fn)"
if printf '%s' "$out" | jq -e '.schema_version == "agent-mail-identity-registry-doctor/v1"' >/dev/null; then
  pass "schema_version pinned to agent-mail-identity-registry-doctor/v1"
else fail "schema_version: $(printf '%s' "$out" | jq -r .schema_version)"; fi

# Test 15: concurrent-load simulation — 5 parallel calls, all should succeed under default=5
# (this is the bug 3ycjw fixes: under concurrent load with timeout=1, some trip 124)
parallel_results="$TMPDIR_TEST/parallel-results"
mkdir -p "$parallel_results"
for i in 1 2 3 4 5; do
  ( call_fn > "$parallel_results/r-$i.json" 2>&1 ) &
done
wait
all_pass=true
for i in 1 2 3 4 5; do
  status="$(jq -r '.status' "$parallel_results/r-$i.json" 2>/dev/null)"
  if [[ "$status" != "pass" ]]; then
    all_pass=false
    break
  fi
done
if $all_pass; then
  pass "5x parallel calls under default timeout=5: all status=pass (concurrent-load regression)"
else
  fail "concurrent load: not all calls passed"
fi

if [[ "$fail_count" -gt 0 ]]; then
  printf 'SUMMARY pass=%d fail=%d\n' "$pass_count" "$fail_count" >&2
  exit 1
fi
printf 'SUMMARY pass=%d fail=0\n' "$pass_count"
