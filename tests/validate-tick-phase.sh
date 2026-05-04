#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd -P)"
TICK="$ROOT/.flywheel/flywheel-loop-tick"
TICK_SCHEMA="$ROOT/.flywheel/validation-schema/v1/tick-receipt.schema.json"
TMP="$(mktemp -d "${TMPDIR:-/tmp}/validate-tick-phase.XXXXXX")"
trap 'rm -rf "$TMP"' EXIT

pass_count=0
fail_count=0

pass() { printf 'PASS %s\n' "$1"; pass_count=$((pass_count + 1)); }
fail() { printf 'FAIL %s\n' "$1"; fail_count=$((fail_count + 1)); }

make_repo() {
  local repo="$TMP/repo"
  rm -rf "$repo"
  mkdir -p "$repo/.flywheel/scripts" "$repo/.flywheel/runtime/flywheel-loop" \
    "$repo/.flywheel/prompts" "$repo/.flywheel/validation-schema/v1" "$repo/.beads"
  printf 'status: ready\n' >"$repo/.flywheel/MISSION.md"
  printf 'status: ready\n' >"$repo/.flywheel/GOAL.md"
  printf 'status: ready\n' >"$repo/.flywheel/STATE.md"
  : >"$repo/.beads/issues.jsonl"
  cp "$ROOT/.flywheel/scripts/validate-callback.py" "$repo/.flywheel/scripts/validate-callback.py"
  cp "$ROOT/.flywheel/validation-schema/v1/schema.json" "$repo/.flywheel/validation-schema/v1/schema.json"
  cp "$ROOT/.flywheel/validation-schema/v1/parse.sh" "$repo/.flywheel/validation-schema/v1/parse.sh"
  chmod +x "$repo/.flywheel/validation-schema/v1/parse.sh"
  for script in josh-request-tick-promote.sh doctor-signal-bead-promotion.sh doctrine-ladder-promote.sh jeff-issue-response-poll.sh inbox-check-tick-step.sh; do
    printf '#!/usr/bin/env bash\nprintf '"'"'%%s\\n'"'"' '"'"'{"action":"test"}'"'"'\n' >"$repo/.flywheel/scripts/$script"
    chmod +x "$repo/.flywheel/scripts/$script"
  done
  cat >"$repo/.flywheel/scripts/frozen-pane-detector.sh" <<'SH'
#!/usr/bin/env bash
set -euo pipefail
if [[ -n "${FAKE_FROZEN_DETECTOR_JSON:-}" ]]; then
  printf '%s\n' "$FAKE_FROZEN_DETECTOR_JSON"
else
  jq -nc '{schema_version:"frozen-pane-detector.v2",success:true,source_health:{status:"healthy"},frozen_panes_detected:0,unknown_panes_detected:0,template_stub_prompt_count:0,queued_not_submitted_count:0,respawn_suppressed_count:0,recovery_suppressed_count:0,l60_signals_present:{no_silent_darkness:true,live_truth_delta:true,unknown_separated:true,recovery_budget:true,recovery_lease:true},soft_violations:[],durable_receipts:[]}'
fi
SH
  chmod +x "$repo/.flywheel/scripts/frozen-pane-detector.sh"
  printf '#!/usr/bin/env bash\nprintf '"'"'%%s\\n'"'"' '"'"'{"verdict":"blocked","reason":"test"}'"'"'\n' >"$repo/.flywheel/scripts/dispatch-capacity-gate.sh"
  chmod +x "$repo/.flywheel/scripts/dispatch-capacity-gate.sh"
  printf '%s\n' "$repo"
}

make_fake_ntm() {
  local ntm="$TMP/ntm"
  cat >"$ntm" <<'SH'
#!/usr/bin/env bash
set -euo pipefail
if [[ "${1:-}" == "copy" ]]; then
  out=""
  while [[ $# -gt 0 ]]; do
    if [[ "$1" == "--output" ]]; then
      out="$2"
      shift 2
    else
      shift
    fi
  done
  printf '%s\n' "${FAKE_NTM_COPY_TEXT:-}" >"$out"
  exit 0
fi
if [[ "${1:-}" == "send" ]]; then
  printf '{"ok":true,"transport":"fake"}\n'
  exit 0
fi
printf '{"ok":true}\n'
SH
  chmod +x "$ntm"
  printf '%s\n' "$ntm"
}

run_case() {
  local label="$1" copy_text="$2" expected_phase="$3" jq_filter="$4" detector_json="${5:-}"
  local repo ntm state prompt log last
  if [[ -z "$detector_json" ]]; then
    detector_json="$(jq -nc '{schema_version:"frozen-pane-detector.v2",success:true,source_health:{status:"healthy"},frozen_panes_detected:0,unknown_panes_detected:0,template_stub_prompt_count:0,queued_not_submitted_count:0,respawn_suppressed_count:0,recovery_suppressed_count:0,l60_signals_present:{no_silent_darkness:true,live_truth_delta:true,unknown_separated:true,recovery_budget:true,recovery_lease:true},soft_violations:[],durable_receipts:[],silent_dark_minutes:0,blackout_detection_latency_p95:0,false_recovery_count:0,unknown_auto_recovery_count:0}')"
  fi
  repo="$(make_repo)"
  ntm="$(make_fake_ntm)"
  state="$repo/.flywheel/runtime/flywheel-loop"
  prompt="$repo/.flywheel/prompts"
  log="$repo/.flywheel/dispatch-log.jsonl"
  last="$state/last_run.json"
  printf 'proof\n' >"$repo/evidence.md"
  jq -nc '{task_id:"task-pending"}' >"$last"
  jq -nc '{event:"ntm_dispatch_sent",task_id:"task-pending",dispatch_status:"sent",callback_received_at:null}' >"$log"
  local tick_rc
  set +e
  FAKE_NTM_COPY_TEXT="$copy_text" \
  FAKE_FROZEN_DETECTOR_JSON="$detector_json" \
  REPO="$repo" SESSION="flywheel" TARGET_PANE="1" STATE_DIR="$state" PROMPT_DIR="$prompt" LOG="$log" NTM="$ntm" FLYWHEEL_LOOP_TICK_DRY_RUN=1 \
    bash "$TICK" >/tmp/validate-tick-phase-run.out 2>/tmp/validate-tick-phase-run.err
  tick_rc=$?
  set -e
  if [[ "$tick_rc" -eq 0 ]] && jq -e --arg phase "$expected_phase" '.phase == $phase' "$last" >/dev/null && jq -e "$jq_filter" "$last" >/dev/null; then
    pass "$label"
  else
    fail "$label"
    printf 'tick_rc=%s\n' "$tick_rc"
    cat /tmp/validate-tick-phase-run.out || true
    cat /tmp/validate-tick-phase-run.err || true
    jq . "$last" || true
  fi
}

bash -n "$TICK" && pass "B05_AG1 tick script syntax includes VALIDATE" || fail "B05_AG1 tick script syntax includes VALIDATE"
grep -q 'VALIDATE' "$TICK" && pass "B05_AG1 phase order includes VALIDATE" || fail "B05_AG1 phase order includes VALIDATE"
jq -e '.properties.dispatch_status.enum | index("blocked_frozen_detector")' "$TICK_SCHEMA" >/dev/null \
  && jq -e '.properties.frozen_detector and .properties.frozen_detector_unknown_panes_detected and .properties.frozen_detector_respawn_suppressed_count and .properties.frozen_detector_l60_all_present' "$TICK_SCHEMA" >/dev/null \
  && pass "i8rd tick schema exposes detector v2 consumer fields" || fail "i8rd tick schema exposes detector v2 consumer fields"

run_case "B05_AG2 pending callback routes to VALIDATE and counts unvalidated" "" "VALIDATE" \
  '(.phase_reason | test("callback_pending_unvalidated")) and .validation_summary.callbacks_unvalidated_count == 1'

run_case "B05_AG3 failed validation blocks INTEGRATE without remediation" "DONE task-pending evidence=missing.md" "VALIDATE" \
  '.validation_summary.status == "fail" and .validation_summary.integration_allowed == false and (.validation_summary.failure_classes | index("artifact_missing"))'

run_case "B05_AG4 runtime timeout maps to VALIDATE unknown" "TIMEOUT task-pending" "VALIDATE" \
  '.validation_summary.status == "unknown" and .validation_summary.unknown_count == 1'

run_case "B05_AG5 clean validation proceeds to INTEGRATE with receipt ref" "DONE task-pending evidence=evidence.md" "INTEGRATE" \
  '.validation_summary.status == "pass" and .validation_summary.integration_allowed == true and (.validation_summary.receipt_path | type) == "string"'

run_case "B05_AG6 dry-run records planned VALIDATE action without live send" "" "VALIDATE" \
  '.dispatch_status == "dry_run" and (.prompt_file | test("flywheel-tick-"))'

run_case "B05_AG7 tick receipt includes doctor/learn validation summary fields" "DONE task-pending evidence=evidence.md" "INTEGRATE" \
  '.validation_summary | has("callbacks_unvalidated_count") and has("failure_classes") and has("receipt_path") and has("integration_allowed")'

run_case "vnsw tick receipt includes scheduled probe fields" "DONE task-pending evidence=evidence.md" "INTEGRATE" \
  'has("jeff_status") and has("jeff_fixes") and has("agent_mail_fd") and has("mobile_eats_receipt") and has("skillos_loop") and has("daily_jeff_ingest") and has("fleet_onboard") and has("agent_mail_fd_status") and has("mobile_eats_receipt_status") and has("daily_jeff_ingest_status") and has("fleet_onboard_status")'

run_case "i8rd tick receipt includes detector v2 stale/unknown/recovery-suppressed counts and L60 5-signal check" "DONE task-pending evidence=evidence.md" "INTEGRATE" \
  'has("frozen_detector") and .frozen_detector_source_health_status == "healthy" and .frozen_detector_frozen_panes_detected == 0 and .frozen_detector_unknown_panes_detected == 0 and .frozen_detector_stale_template_prompt_count == 0 and .frozen_detector_respawn_suppressed_count == 0 and .frozen_detector_l60_signal_present_count == 5 and .frozen_detector_l60_signal_expected_count == 5 and .frozen_detector_l60_all_present == true and (.frozen_detector_l60_signal_missing | length) == 0 and .frozen_detector_dispatch_block_reason == "none"'

frozen_detector_fixture="$(jq -nc '{schema_version:"frozen-pane-detector.v2",success:true,source_health:{status:"healthy"},frozen_panes_detected:1,unknown_panes_detected:0,template_stub_prompt_count:2,queued_not_submitted_count:0,respawn_suppressed_count:1,recovery_suppressed_count:0,l60_signals_present:{no_silent_darkness:true,live_truth_delta:true,unknown_separated:true,recovery_budget:true,recovery_lease:true},soft_violations:[],durable_receipts:[],silent_dark_minutes:12,blackout_detection_latency_p95:300,false_recovery_count:0,unknown_auto_recovery_count:0}')"
run_case "i8rd frozen detector blocks dispatch while preserving detector counts" "DONE task-pending evidence=evidence.md" "INTEGRATE" \
  '.dispatch_status == "blocked_frozen_detector" and .frozen_detector_dispatch_block_reason == "frozen_panes_detected" and .frozen_detector_frozen_panes_detected == 1 and .frozen_detector_stale_template_prompt_count == 2 and .frozen_detector_respawn_suppressed_count == 1' \
  "$frozen_detector_fixture"

unknown_l60_fixture="$(jq -nc '{schema_version:"frozen-pane-detector.v2",success:true,source_health:{status:"healthy"},frozen_panes_detected:0,unknown_panes_detected:1,template_stub_prompt_count:0,queued_not_submitted_count:0,respawn_suppressed_count:0,recovery_suppressed_count:0,l60_signals_present:{no_silent_darkness:true,live_truth_delta:false,unknown_separated:true,recovery_budget:true,recovery_lease:true},soft_violations:[{class:"unknown_truth_not_recovered"}],durable_receipts:[{status:"UNKNOWN"}],silent_dark_minutes:5,blackout_detection_latency_p95:0,false_recovery_count:0,unknown_auto_recovery_count:0}')"
run_case "i8rd unknown detector state blocks dispatch and surfaces missing L60 signal" "DONE task-pending evidence=evidence.md" "INTEGRATE" \
  '.dispatch_status == "blocked_frozen_detector" and .frozen_detector_dispatch_block_reason == "unknown_panes_detected" and .frozen_detector_unknown_panes_detected == 1 and .frozen_detector_l60_signal_present_count == 4 and .frozen_detector_l60_all_present == false and (.frozen_detector_l60_signal_missing | index("live_truth_delta"))' \
  "$unknown_l60_fixture"

printf '\nSummary: %s passed, %s failed\n' "$pass_count" "$fail_count"
[[ "$fail_count" -eq 0 ]]
