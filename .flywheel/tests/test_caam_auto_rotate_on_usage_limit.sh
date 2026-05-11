#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
SCRIPT="$ROOT/.flywheel/scripts/caam-auto-rotate-on-usage-limit.py"
FIX="$ROOT/.flywheel/tests/fixtures/caam-auto-rotate"
FAKE_CAAM="$FIX/fake-caam"
FAKE_NTM="$FIX/fake-ntm"
TEST_SCRIPT="${BASH_SOURCE[0]}"
TMP="$(mktemp -d)"
AUTH="$TMP/fake-auth"
AUTH_LOG="$TMP/auth.log"
PASS=0
FAIL=0
LAST_OUT=
LAST_RC=0

trap 'rm -rf "$TMP"' EXIT

cat >"$AUTH" <<'SH'
#!/usr/bin/env bash
set -euo pipefail
recovery=""
session=""
pane=""
while [[ $# -gt 0 ]]; do
  case "$1" in
    --recovery-class) recovery="$2"; shift 2 ;;
    --session) session="$2"; shift 2 ;;
    --pane) pane="$2"; shift 2 ;;
    --tool) shift 2 ;;
    --json) shift ;;
    *) shift ;;
  esac
done
if [[ "$recovery" == "credential_rotation" ]]; then
  printf '{"authorized":true,"status":"authorized","stale_topology_allowed":true,"session":"%s","pane":"%s"}\n' "$session" "$pane"
  exit 0
fi
printf '{"authorized":false,"status":"stale_topology_refused"}\n'
exit 7
SH
chmod +x "$AUTH"

ok() { printf 'ok %02d - %s\n' "$((PASS+FAIL+1))" "$1"; PASS=$((PASS+1)); }
bad() { printf 'not ok %02d - %s\n' "$((PASS+FAIL+1))" "$1"; FAIL=$((FAIL+1)); }
check() { local name="$1"; shift; if "$@"; then ok "$name"; else bad "$name"; fi; }
jq_ok() { jq -e "$1" "$LAST_OUT" >/dev/null; }
log_count() { [[ ! -s "$1" ]] && echo 0 || rg -c '^rotate ' "$1"; }
export -f jq_ok log_count
export SCRIPT FIX FAKE_CAAM FAKE_NTM TEST_SCRIPT

run_case() {
  local caam_mode="$1" ntm_mode="$2" digest="$3"; shift 3
  local caam_log="$TMP/caam-$digest.log" ntm_log="$TMP/ntm-$digest.log" state="$TMP/caam-$digest.state" ledger="$TMP/ledger-$digest.jsonl" rec="$TMP/recovery-$digest.jsonl"
  LAST_OUT="$TMP/out-$digest.json"
  : >"$caam_log"; : >"$ntm_log"
  set +e
  FAKE_CAAM_FIXTURE_DIR="$FIX" FAKE_CAAM_MODE="$caam_mode" FAKE_CAAM_LOG="$caam_log" FAKE_CAAM_STATE="$state" FAKE_NTM_MODE="$ntm_mode" FAKE_NTM_LOG="$ntm_log" AUTH_LOG="$AUTH_LOG" \
    "$SCRIPT" --tool codex --session flywheel --pane 2 --digest "$digest" --json --caam-bin "$FAKE_CAAM" --ntm-bin "$FAKE_NTM" --auth-bin "$AUTH" --ledger "$ledger" --recovery-ledger "$rec" "$@" >"$LAST_OUT"
  LAST_RC=$?
  set -e
  export LAST_OUT LAST_RC CASE_CAAM_LOG="$caam_log" CASE_NTM_LOG="$ntm_log" CASE_LEDGER="$ledger" CASE_RECOVERY="$rec"
}

check "01 python syntax" python3 -m py_compile "$SCRIPT"
# Test 02 calibration (flywheel-vzrs6): asserts wrapper-result-schema fields
# emit()-side. Previously called `$SCRIPT --schema --json`, but the canonical-
# CLI scaffolder (flywheel-0pkcf) repurposed --schema to emit canonical-CLI
# introspection (command/schema_version/stable_exit_codes/surface/surfaces).
# Sister calibration to flywheel-bgtv8; META-RULE 2026-05-09 (calibrate-test-
# to-actual-contract-before-filing-upstream). The wrapper-result envelope is
# the correct surface for these field assertions — sourced from a real
# rotate run via run_case (same pattern as tests 03/04).
run_case current-alt ok d02
check "02 wrapper-result schema fields (caam-auto-rotate-on-usage-limit.result.v1)" bash -c 'jq_ok ".schema==\"caam-auto-rotate-on-usage-limit.result.v1\" and .native_surface==\"ntm rotate\" and .caam_vault_only==true and .ttl_native==\"3600s\" and .ttl_wrapper==\"24h_historical_receipt\" and (.native_wrapper_delta|test(\"native_ntm_rotate_owns_account_swap\")) and (.authorized_operations|index(\"ntm_rotate_preserve_context\"))"'
run_case current-alt ok d03
check "03 default dry-run delegates to ntm rotate without mutation" bash -c '[[ "$LAST_RC" == 0 ]] && jq -e ".status==\"dry_run\" and .would_rotate==true and .selected_profile==\"codex-backup\" and .ntm_rotate_subprocess_rc==0 and .native_surface==\"ntm rotate\" and .caam_vault_only==true and .ttl_decision==\"native_lease_for_active_operation_wrapper_receipt_records_prior_next_selector\"" "$LAST_OUT" >/dev/null && rg -- "--dry-run" "$CASE_NTM_LOG" >/dev/null && [[ "$(log_count "$CASE_NTM_LOG")" == 1 ]]'
run_case current-alt ok d04 --apply
check "04 apply delegates account swap to ntm rotate" bash -c '[[ "$LAST_RC" == 0 ]] && jq -e ".status==\"rotated\" and .post_check_active_profile==\"codex-backup\" and .ttl_native==\"3600s\" and .ttl_wrapper==\"24h_historical_receipt\" and (.native_wrapper_delta|test(\"wrapper_owns_caam_profile_selection\"))" "$LAST_OUT" >/dev/null && rg -- "--account=codex-backup" "$CASE_NTM_LOG" >/dev/null && rg -- "--preserve-context" "$CASE_NTM_LOG" >/dev/null && ! rg -- "--dry-run" "$CASE_NTM_LOG" >/dev/null'
run_case no-alternate ok d05
check "05 no alternate profile refuses before ntm" bash -c '[[ "$LAST_RC" == 4 ]] && jq -e ".status==\"no_alternate_profile\"" "$LAST_OUT" >/dev/null && [[ "$(log_count "$CASE_NTM_LOG")" == 0 ]]'
run_case list-fails-ls-succeeds ok d06
check "06 caam list fallback to ls" bash -c '[[ "$LAST_RC" == 0 ]] && jq -e ".caam_profile_source==\"ls\"" "$LAST_OUT" >/dev/null'
run_case current-alt rotate-fails d07 --apply
check "07 ntm rotate failure is contained" bash -c '[[ "$LAST_RC" == 2 ]] && jq -e ".status==\"ntm_rotate_failed\" and .ntm_rotate_subprocess_rc==8" "$LAST_OUT" >/dev/null'
run_case current-alt ok d08
check "08 account target is selected CAAM profile" bash -c 'jq -e ".post_check_active_profile==\"codex-backup\"" "$LAST_OUT" >/dev/null && rg -- "--account=codex-backup" "$CASE_NTM_LOG" >/dev/null'
LED="$TMP/dup-ledger.jsonl"; REC="$TMP/dup-rec.jsonl"; NTM_LOG="$TMP/dup-ntm.log"; STATE="$TMP/dup.state"; : >"$NTM_LOG"
FAKE_CAAM_FIXTURE_DIR="$FIX" FAKE_CAAM_MODE=current-alt FAKE_CAAM_STATE="$STATE" FAKE_NTM_MODE=ok FAKE_NTM_LOG="$NTM_LOG" "$SCRIPT" --tool codex --session flywheel --pane 2 --digest dup --json --apply --caam-bin "$FAKE_CAAM" --ntm-bin "$FAKE_NTM" --auth-bin "$AUTH" --ledger "$LED" --recovery-ledger "$REC" >"$TMP/dup1.json"
FAKE_CAAM_FIXTURE_DIR="$FIX" FAKE_CAAM_MODE=current-alt FAKE_CAAM_STATE="$STATE" FAKE_NTM_MODE=ok FAKE_NTM_LOG="$NTM_LOG" "$SCRIPT" --tool codex --session flywheel --pane 2 --digest dup --json --apply --caam-bin "$FAKE_CAAM" --ntm-bin "$FAKE_NTM" --auth-bin "$AUTH" --ledger "$LED" --recovery-ledger "$REC" >"$TMP/dup2.json"
LAST_OUT="$TMP/dup2.json"; export LAST_OUT NTM_LOG
check "09 duplicate signal is idempotent" bash -c 'jq -e ".status==\"already_rotated_for_signal\"" "$LAST_OUT" >/dev/null && [[ "$(log_count "$NTM_LOG")" == 1 ]]'
FAKE_CAAM_FIXTURE_DIR="$FIX" FAKE_CAAM_MODE=current-alt FAKE_CAAM_FORCE_CURRENT=codex-backup FAKE_NTM_MODE=ok FAKE_NTM_LOG="$NTM_LOG" "$SCRIPT" --tool codex --session flywheel --pane 2 --digest dup --json --apply --caam-bin "$FAKE_CAAM" --ntm-bin "$FAKE_NTM" --auth-bin "$AUTH" --ledger "$LED" --recovery-ledger "$REC" >"$TMP/dup3.json"
LAST_OUT="$TMP/dup3.json"; export LAST_OUT
check "10 active-profile change breaks duplicate match" bash -c 'jq -e ".status==\"rotated\" and .selected_profile==\"codex-main\"" "$LAST_OUT" >/dev/null && [[ "$(log_count "$NTM_LOG")" == 2 ]]'
run_case current-alt ok d11
check "11 credential_rotation authorization scopes wrapper operations" bash -c 'jq -e ".authorization_status==\"authorized\" and .stale_topology_allowed==true and (.authorized_operations|index(\"caam_select_existing_profile\")) and (.authorized_operations|index(\"ntm_rotate_preserve_context\")) and (.forbidden_operations|index(\"launchctl\"))" "$LAST_OUT" >/dev/null'
set +e; "$AUTH" --session flywheel --pane 2 --json >"$TMP/auth-default.json"; AUTH_RC=$?; set -e
LAST_OUT="$TMP/auth-default.json"; export LAST_OUT AUTH_RC
check "12 stale topology default remains refused in auth fixture" bash -c '[[ "$AUTH_RC" == 7 ]] && jq -e ".authorized==false" "$LAST_OUT" >/dev/null'
run_case critical-alt ok d13 --auto-recover --allow-unhealthy
check "13 allow-unhealthy auto-recover requires operator ack" bash -c '[[ "$LAST_RC" == 4 ]] && jq -e ".status==\"refused_allow_unhealthy_requires_operator_ack\"" "$LAST_OUT" >/dev/null && [[ "$(log_count "$CASE_NTM_LOG")" == 0 ]]'
run_case critical-alt ok d14 --auto-recover --allow-unhealthy --operator-ack maintenance
check "14 operator ack permits unhealthy candidate wrapper" bash -c '[[ "$LAST_RC" == 0 ]] && jq -e ".selected_profile==\"codex-expired\"" "$LAST_OUT" >/dev/null && rg -- "--account=codex-expired" "$CASE_NTM_LOG" >/dev/null'
run_case unknown-fields ok d15
check "15 unknown caam fields are redacted from result" bash -c '! rg -i "access_token|refresh_token|bearer|auth_url" "$LAST_OUT" >/dev/null'
set +e; "$SCRIPT" --tool claude --session flywheel --pane 2 --digest d16 --json --caam-bin "$FAKE_CAAM" --ntm-bin "$FAKE_NTM" --auth-bin "$AUTH" >"$TMP/d16.json"; RC16=$?; set -e
LAST_OUT="$TMP/d16.json"; export LAST_OUT RC16
check "16 unsupported tool is malformed" bash -c '[[ "$RC16" == 3 ]] && jq -e ".failure_class==\"unsupported_tool\"" "$LAST_OUT" >/dev/null'
run_case current-alt ok d17 --apply
check "17 attempt and recovery ledgers written" bash -c 'jq -e ".schema==\"caam-auto-rotate-on-usage-limit.result.v1\" and .ntm_rotate_subprocess_rc==0" "$CASE_LEDGER" >/dev/null && jq -e ".event==\"credential_rotation\" and .wrapper_invoked==true and .ntm_rotate_subprocess_rc==0" "$CASE_RECOVERY" >/dev/null'
check "18 secret-value scan is clean" bash -c '! rg -n "(sk-[A-Za-z0-9]{20,}|Bearer [A-Za-z0-9._-]{20,}|refresh_token\"[[:space:]]*:[[:space:]]*\"[^\"]{8,})" "$SCRIPT" "$TEST_SCRIPT" "$FIX" >/dev/null'

printf 'caam_auto_rotate_wrapper_tests pass=%d fail=%d total=%d\n' "$PASS" "$FAIL" "$((PASS+FAIL))"
[[ "$FAIL" == 0 ]]
