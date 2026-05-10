#!/usr/bin/env bash
# test-mobile-eats-path-a-validator.sh
#
# flywheel-dwmb.1 regression: assert that Path A validation is gated ONLY by
# the canonical receipt bridge, not by full repo doctor. Specifically:
#
#   T1. canonical-receipt-OK + global-doctor-FAIL/TIMEOUT must NOT mark
#       Path A rollback-worthy (the trauma class from flywheel-dwmb).
#   T2. canonical-receipt-FAIL must mark Path A rollback-worthy regardless
#       of global-doctor.
#   T3. JSON output exposes both surfaces: primary_gate (bridge) and
#       advisory (full doctor with bounded timeout).
#
# Test strategy: substitute MOBILE_EATS_RECEIPT_BRIDGE + FLYWHEEL_LOOP_BIN
# with synthetic stubs that emit known JSON shapes + exit codes, then
# assert the validator's response.

set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd -P)"
VALIDATOR="$ROOT/.flywheel/scripts/mobile-eats-path-a-validator.sh"
TMP="$(mktemp -d "${TMPDIR:-/tmp}/test-mobile-eats-path-a.XXXXXX")"
trap 'rm -rf "$TMP"' EXIT

pass_count=0
fail_count=0
pass() { printf 'PASS %s\n' "$1"; pass_count=$((pass_count + 1)); }
fail() { printf 'FAIL %s\n' "$1" >&2; fail_count=$((fail_count + 1)); }

if [[ ! -x "$VALIDATOR" ]] && [[ ! -f "$VALIDATOR" ]]; then
  printf 'SKIP validator missing at %s\n' "$VALIDATOR"
  exit 77
fi

# === Stub bridges ===

# Bridge stub: status=ok (canonical receipt healthy)
cat >"$TMP/bridge-ok.sh" <<'STUB'
#!/usr/bin/env bash
printf '{"status":"ok","ts":"2026-05-09T00:00:00Z","schema":"flywheel.mobile_eats_receipt_bridge.v1","mobile_eats":{"last_run_ts":"2026-05-09T00:00:00Z"}}\n'
exit 0
STUB
chmod +x "$TMP/bridge-ok.sh"

# Bridge stub: status=fail (canonical receipt failure — should rollback)
cat >"$TMP/bridge-fail.sh" <<'STUB'
#!/usr/bin/env bash
printf '{"status":"fail","ts":"2026-05-09T00:00:00Z","error":"receipt_missing"}\n'
exit 2
STUB
chmod +x "$TMP/bridge-fail.sh"

# === Stub loop bins ===

# Loop bin stub: doctor SUCCEEDS (rc=0)
cat >"$TMP/loop-bin-ok.sh" <<'STUB'
#!/usr/bin/env bash
[[ "$1" == "doctor" ]] || exit 64
printf '{"status":"ok"}\n'
exit 0
STUB
chmod +x "$TMP/loop-bin-ok.sh"

# Loop bin stub: doctor FAILS (rc=1)
cat >"$TMP/loop-bin-fail.sh" <<'STUB'
#!/usr/bin/env bash
[[ "$1" == "doctor" ]] || exit 64
printf '{"status":"fail","violations":[{"class":"beads_db_health_failed"}]}\n'
exit 1
STUB
chmod +x "$TMP/loop-bin-fail.sh"

# Loop bin stub: doctor HANGS (will be killed by gtimeout)
cat >"$TMP/loop-bin-hang.sh" <<'STUB'
#!/usr/bin/env bash
[[ "$1" == "doctor" ]] || exit 64
sleep 60
exit 0
STUB
chmod +x "$TMP/loop-bin-hang.sh"

# === T1: bridge OK + doctor FAIL → Path A pass, rollback=false ===
T1_OUT="$TMP/t1-bridge-ok-doctor-fail.json"
MOBILE_EATS_RECEIPT_BRIDGE="$TMP/bridge-ok.sh" \
  FLYWHEEL_LOOP_BIN="$TMP/loop-bin-fail.sh" \
  MOBILE_EATS_PATH_A_ADVISORY_TIMEOUT_SECONDS=5 \
  bash "$VALIDATOR" --json >"$T1_OUT" 2>&1
T1_RC=$?

if [[ "$T1_RC" -eq 0 ]]; then
  pass "T1a Path A passes (rc=0) when bridge ok + doctor fail"
else
  fail "T1a Path A unexpectedly failed (rc=$T1_RC) with bridge ok + doctor fail"
  cat "$T1_OUT" >&2
fi

if jq -e '.path_a_pass == true' "$T1_OUT" >/dev/null 2>&1; then
  pass "T1b path_a_pass=true with bridge ok + doctor fail"
else
  fail "T1b path_a_pass should be true"
  jq . "$T1_OUT" >&2
fi

if jq -e '.rollback_recommended == false' "$T1_OUT" >/dev/null 2>&1; then
  pass "T1c rollback_recommended=false (advisory failure does NOT trigger rollback)"
else
  fail "T1c rollback_recommended should be false"
fi

if jq -e '.advisory.full_doctor_status == "failed"' "$T1_OUT" >/dev/null 2>&1; then
  pass "T1d advisory.full_doctor_status=failed (captured separately)"
else
  fail "T1d advisory.full_doctor_status should be failed"
fi

# === T2: bridge OK + doctor TIMEOUT → Path A pass, rollback=false ===
T2_OUT="$TMP/t2-bridge-ok-doctor-timeout.json"
MOBILE_EATS_RECEIPT_BRIDGE="$TMP/bridge-ok.sh" \
  FLYWHEEL_LOOP_BIN="$TMP/loop-bin-hang.sh" \
  MOBILE_EATS_PATH_A_ADVISORY_TIMEOUT_SECONDS=2 \
  bash "$VALIDATOR" --json >"$T2_OUT" 2>&1
T2_RC=$?

if [[ "$T2_RC" -eq 0 ]] && jq -e '.path_a_pass == true and .rollback_recommended == false' "$T2_OUT" >/dev/null 2>&1; then
  pass "T2a Path A passes when bridge ok + doctor TIMEOUT (no rollback)"
else
  fail "T2a Path A should pass on doctor timeout (rc=$T2_RC)"
  jq . "$T2_OUT" >&2 || cat "$T2_OUT" >&2
fi

if jq -e '.advisory.full_doctor_status == "timeout"' "$T2_OUT" >/dev/null 2>&1; then
  pass "T2b advisory.full_doctor_status=timeout"
else
  fail "T2b advisory.full_doctor_status should be timeout"
fi

# === T3: bridge FAIL → Path A FAIL, rollback=true ===
T3_OUT="$TMP/t3-bridge-fail.json"
T3_RC=0
set +e
MOBILE_EATS_RECEIPT_BRIDGE="$TMP/bridge-fail.sh" \
  FLYWHEEL_LOOP_BIN="$TMP/loop-bin-ok.sh" \
  MOBILE_EATS_PATH_A_ADVISORY_TIMEOUT_SECONDS=5 \
  bash "$VALIDATOR" --json >"$T3_OUT" 2>&1
T3_RC=$?
set -e

if [[ "$T3_RC" -eq 2 ]]; then
  pass "T3a Path A fails (rc=2) when bridge fail (regardless of doctor)"
else
  fail "T3a Path A should fail with rc=2 (got rc=$T3_RC)"
fi

if jq -e '.path_a_pass == false and .rollback_recommended == true' "$T3_OUT" >/dev/null 2>&1; then
  pass "T3b path_a_pass=false + rollback_recommended=true on bridge fail"
else
  fail "T3b expected path_a_pass=false + rollback_recommended=true"
  jq . "$T3_OUT" >&2
fi

# === T4: schema/info surface stable ===
SCHEMA_OUT="$TMP/schema.json"
bash "$VALIDATOR" --schema --json >"$SCHEMA_OUT" 2>&1
if jq -e '.fields | type == "array" and length > 5' "$SCHEMA_OUT" >/dev/null 2>&1; then
  pass "T4 --schema --json returns canonical schema field array"
else
  fail "T4 --schema output is not canonical"
fi

printf '\n=== test-mobile-eats-path-a-validator.sh ===\n'
printf 'pass=%d fail=%d\n' "$pass_count" "$fail_count"
[[ "$fail_count" -eq 0 ]] && exit 0 || exit 1
