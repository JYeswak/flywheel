#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd -P)"
ROTATE="$ROOT/.flywheel/scripts/caam-rotate-and-respawn.sh"
DETECTOR="$ROOT/.flywheel/scripts/codex-template-stuck-detector.sh"
TMP="$(mktemp -d "${TMPDIR:-/tmp}/caam-rotate-and-respawn.XXXXXX")"
trap 'rm -rf "$TMP"' EXIT

pass_count=0
fail_count=0
pass(){ printf 'PASS %s\n' "$1"; pass_count=$((pass_count + 1)); }
fail(){ printf 'FAIL %s\n' "$1" >&2; fail_count=$((fail_count + 1)); }
assert_jq(){ local file="$1" filter="$2" label="$3"; if jq -e "$filter" "$file" >/dev/null; then pass "$label"; else fail "$label"; jq . "$file" >&2 || true; fi; }

cat >"$TMP/caam" <<'SH'
#!/usr/bin/env bash
case "${1:-} ${2:-}" in
  "profile current") printf 'codex/primary\n';;
  "status codex") printf 'TOOL PROFILE STATUS\ncodex primary active\n';;
  "ls codex") printf 'PROFILE EMAIL PLAN STATUS\n* primary primary@example.com pro active\n  spare spare@example.com pro ready\n';;
  "activate codex") printf 'activate:%s\n' "${3:-}" >>"${FAKE_CAAM_LOG:?}";;
  *) printf 'unexpected caam args: %s\n' "$*" >&2; exit 9;;
esac
SH
chmod +x "$TMP/caam"

cat >"$TMP/ntm" <<'SH'
#!/usr/bin/env bash
printf '%s\n' "$*" >>"${FAKE_NTM_LOG:?}"
case "${1:-}" in
  wait) jq -nc '{status:"ok"}';;
  respawn) jq -nc '{status:"ok",respawned:true}';;
  *) :;;
esac
SH
chmod +x "$TMP/ntm"

task_file="$TMP/dispatch.md"
printf 'dispatch body\n' >"$task_file"
dispatch_log="$TMP/dispatch-log.jsonl"
jq -nc --arg s fixture --argjson p 2 --arg f "$task_file" '{session:$s,pane:$p,task_file:$f,callback_received_at:null}' >"$dispatch_log"

FAKE_CAAM_LOG="$TMP/caam.log" FAKE_NTM_LOG="$TMP/ntm.log" \
  "$ROTATE" --session fixture --pane 2 --caam-bin "$TMP/caam" --ntm-bin "$TMP/ntm" --dispatch-log "$dispatch_log" --ledger "$TMP/rotate.jsonl" --dry-run --json >"$TMP/dry.json"
assert_jq "$TMP/dry.json" '.status=="dry_run" and .recovered==true and .current_profile=="primary" and .next_profile=="spare" and .redispatch_task_file != null' "dry_run_selects_next_profile"
[[ ! -e "$TMP/caam.log" && ! -e "$TMP/ntm.log" && ! -e "$TMP/rotate.jsonl" ]] && pass "dry_run_has_no_side_effects" || fail "dry_run_has_no_side_effects"

FAKE_CAAM_LOG="$TMP/caam.log" FAKE_NTM_LOG="$TMP/ntm.log" \
  "$ROTATE" --session fixture --pane 2 --caam-bin "$TMP/caam" --ntm-bin "$TMP/ntm" --dispatch-log "$dispatch_log" --ledger "$TMP/rotate.jsonl" --digest abc --apply --json >"$TMP/apply.json"
assert_jq "$TMP/apply.json" '.status=="rotated" and .recovered==true and .applied==true and .next_profile=="spare"' "apply_reports_rotation"
grep -q '^activate:spare$' "$TMP/caam.log" && pass "apply_activates_next_profile" || fail "apply_activates_next_profile"
grep -q '^send fixture --pane=2 --no-cass-check' "$TMP/ntm.log" && pass "apply_interrupts_worker_pane" || fail "apply_interrupts_worker_pane"
grep -q '^respawn fixture --panes=2 --json$' "$TMP/ntm.log" && pass "apply_respawns_pane" || fail "apply_respawns_pane"
grep -q "^send fixture --pane=2 --file $task_file --no-cass-check$" "$TMP/ntm.log" && pass "apply_redispatches_inflight_task" || fail "apply_redispatches_inflight_task"
assert_jq "$TMP/rotate.jsonl" '.event=="caam_rotate_and_respawn" and .digest=="abc" and .applied==true' "ledger_records_rotation"

background_fixture="$TMP/background.json"
jq -nc --arg t0 'Waiting for background terminal (5m 01s - esc to interrupt)' --arg t1 'Waiting for background terminal (6m 01s - esc to interrupt)' '{session:"fixture",pane:2,t0:$t0,t1:$t1}' >"$background_fixture"
set +e
CODEX_STUCK_DETECTOR_LEDGER="$TMP/detector.jsonl" \
CODEX_STUCK_DETECTOR_CAAM_ROTATE="$ROTATE" \
CAAM_ROTATE_RESPAWN_CAAM_BIN="$TMP/caam" \
CAAM_ROTATE_RESPAWN_NTM_BIN="$TMP/ntm" \
CAAM_ROTATE_RESPAWN_DISPATCH_LOG="$dispatch_log" \
CAAM_ROTATE_RESPAWN_LEDGER="$TMP/detector-rotate.jsonl" \
FAKE_CAAM_LOG="$TMP/detector.caam.log" \
FAKE_NTM_LOG="$TMP/detector.ntm.log" \
  "$DETECTOR" --fixture "$background_fixture" --auto-recover --apply --json >"$TMP/background.out"
detector_rc=$?
set -e
[[ "$detector_rc" -eq 1 ]] && pass "background_terminal_returns_stuck" || fail "background_terminal_returns_stuck"
assert_jq "$TMP/background.out" '.panes[0].subclass=="background_terminal_stuck" and .panes[0].hash_stable==true and .panes[0].recommended_recovery=="caam_rotate_and_respawn" and .panes[0].recovery_attempted=="caam_rotate_and_respawn" and .panes[0].recovery_succeeded==true' "background_terminal_auto_recovers_via_caam"

cap_fixture="$TMP/capacity.json"
jq -nc --arg t 'Selected model is at capacity. Please try a different model.' '{session:"fixture",pane:2,t0:$t,t1:$t}' >"$cap_fixture"
set +e
CODEX_STUCK_DETECTOR_LEDGER="$TMP/capacity-detector.jsonl" \
CODEX_STUCK_DETECTOR_CAAM_ROTATE="$ROTATE" \
CAAM_ROTATE_RESPAWN_CAAM_BIN="$TMP/caam" \
CAAM_ROTATE_RESPAWN_NTM_BIN="$TMP/ntm" \
CAAM_ROTATE_RESPAWN_DISPATCH_LOG="$dispatch_log" \
CAAM_ROTATE_RESPAWN_LEDGER="$TMP/capacity-rotate.jsonl" \
FAKE_CAAM_LOG="$TMP/capacity.caam.log" \
FAKE_NTM_LOG="$TMP/capacity.ntm.log" \
  "$DETECTOR" --fixture "$cap_fixture" --auto-recover --apply --json >"$TMP/capacity.out"
cap_rc=$?
set -e
[[ "$cap_rc" -eq 1 ]] && pass "capacity_terminal_returns_stuck" || fail "capacity_terminal_returns_stuck"
assert_jq "$TMP/capacity.out" '.panes[0].subclass=="model_at_capacity_halt" and .panes[0].recommended_recovery=="caam_rotate_and_respawn" and .panes[0].recovery_attempted=="caam_rotate_and_respawn"' "capacity_halt_uses_caam_rotation"

jq -nc '{subclass:"model_at_capacity_halt",recovery_attempted:"caam_rotate_and_respawn",recovery_succeeded:false,session:"fixture"}' >"$TMP/doctor-detector.jsonl"
jq -nc '{subclass:"background_terminal_stuck",recovery_attempted:"caam_rotate_and_respawn",recovery_succeeded:false,session:"fixture"}' >>"$TMP/doctor-detector.jsonl"
jq -nc '{subclass:"background_terminal_stuck",recovery_attempted:"caam_rotate_and_respawn",recovery_succeeded:true,session:"fixture"}' >>"$TMP/doctor-detector.jsonl"
jq -nc '{event:"caam_rotate_and_respawn",applied:true}' >"$TMP/doctor-caam.jsonl"
CODEX_STUCK_DETECTOR_LEDGER="$TMP/doctor-detector.jsonl" \
CODEX_STUCK_DETECTOR_CAAM_LEDGER="$TMP/doctor-caam.jsonl" \
CODEX_STUCK_DETECTOR_CONTRACT_LEDGER="$TMP/contract.jsonl" \
CODEX_STUCK_DETECTOR_CAAM_BIN="$TMP/caam" \
  "$DETECTOR" --doctor --json >"$TMP/doctor.json"
assert_jq "$TMP/doctor.json" '.status=="warn" and .codex_freeze_recovery_attempted_24h==3 and .codex_freeze_recovery_succeeded_24h==1 and .codex_freeze_recovery_success_pct_24h < 0.5 and .caam_rotation_count_24h==1 and .caam_active_profile=="primary" and .caam_profiles_available==2' "doctor_exposes_caam_freeze_metrics"

cat >"$TMP/caam-empty" <<'SH'
#!/usr/bin/env bash
case "${1:-} ${2:-}" in
  "status codex") printf 'TOOL PROFILE STATUS\n';;
  "ls codex") printf 'PROFILE EMAIL PLAN STATUS\n';;
esac
SH
chmod +x "$TMP/caam-empty"
CODEX_STUCK_DETECTOR_LEDGER="$TMP/empty-detector.jsonl" \
CODEX_STUCK_DETECTOR_CAAM_LEDGER="$TMP/empty-caam.jsonl" \
CODEX_STUCK_DETECTOR_CONTRACT_LEDGER="$TMP/empty-contract.jsonl" \
CODEX_STUCK_DETECTOR_CAAM_BIN="$TMP/caam-empty" \
  "$DETECTOR" --doctor --json >"$TMP/doctor-empty.json"
assert_jq "$TMP/doctor-empty.json" '.status=="fail" and .caam_profiles_available==0' "doctor_fails_without_caam_profiles"

printf 'CAAM rotate and respawn summary: %s passed, %s failed\n' "$pass_count" "$fail_count"
[[ "$fail_count" -eq 0 ]]
