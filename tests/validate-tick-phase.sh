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
    "$repo/.flywheel/prompts" "$repo/.flywheel/validation-schema/v1" \
    "$repo/.flywheel/tick-contract-registry/v1/fixtures" "$repo/.beads"
  printf 'status: ready\n' >"$repo/.flywheel/MISSION.md"
  printf 'status: ready\n' >"$repo/.flywheel/GOAL.md"
  printf 'status: ready\n' >"$repo/.flywheel/STATE.md"
  : >"$repo/.beads/issues.jsonl"
  cp "$ROOT/.flywheel/scripts/validate-callback.py" "$repo/.flywheel/scripts/validate-callback.py"
  cp "$ROOT/.flywheel/validation-schema/v1/schema.json" "$repo/.flywheel/validation-schema/v1/schema.json"
  cp "$ROOT/.flywheel/validation-schema/v1/parse.sh" "$repo/.flywheel/validation-schema/v1/parse.sh"
  cp "$ROOT/.flywheel/tick-contract-registry/v1/registry.json" "$repo/.flywheel/tick-contract-registry/v1/registry.json"
  chmod +x "$repo/.flywheel/validation-schema/v1/parse.sh"
  for script in josh-request-tick-promote.sh doctor-signal-bead-promotion.sh doctrine-ladder-promote.sh jeff-issue-response-poll.sh inbox-check-tick-step.sh; do
    printf '#!/usr/bin/env bash\nprintf '"'"'%%s\\n'"'"' '"'"'{"action":"test"}'"'"'\n' >"$repo/.flywheel/scripts/$script"
    chmod +x "$repo/.flywheel/scripts/$script"
  done
  cat >"$repo/.flywheel/scripts/leverage-ceiling-probe.sh" <<'SH'
#!/usr/bin/env bash
set -euo pipefail
jq -nc '{
  version:"leverage-ceiling-probe.v1",
  success:true,
  status:"ok",
  leverage_ceiling_score:800,
  binding_constraint:"tokens",
  binding_evidence:"accounts_norm=100% machines_norm=100% tokens_norm=80%",
  warnings:["fixture-token-budget-low"],
  accounts_active:2,
  worker_panes_total:5,
  worker_panes_working_count:4
}'
SH
  chmod +x "$repo/.flywheel/scripts/leverage-ceiling-probe.sh"
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
  local contract_log="${6:-}"
  local repo ntm state prompt log last phase_a_log processed_log
  if [[ -z "$detector_json" ]]; then
    detector_json="$(jq -nc '{schema_version:"frozen-pane-detector.v2",success:true,source_health:{status:"healthy"},frozen_panes_detected:0,unknown_panes_detected:0,template_stub_prompt_count:0,queued_not_submitted_count:0,respawn_suppressed_count:0,recovery_suppressed_count:0,l60_signals_present:{no_silent_darkness:true,live_truth_delta:true,unknown_separated:true,recovery_budget:true,recovery_lease:true},soft_violations:[],durable_receipts:[],silent_dark_minutes:0,blackout_detection_latency_p95:0,false_recovery_count:0,unknown_auto_recovery_count:0}')"
  fi
  repo="$(make_repo)"
  ntm="$(make_fake_ntm)"
  state="$repo/.flywheel/runtime/flywheel-loop"
  prompt="$repo/.flywheel/prompts"
  log="$repo/.flywheel/dispatch-log.jsonl"
  last="$state/last_run.json"
  if [[ -z "$contract_log" ]]; then
    contract_log="$TMP/no-fuckups.jsonl"
    : >"$contract_log"
  fi
  phase_a_log="${RUN_CASE_PHASE_A_LOG:-}"
  if [[ -z "$phase_a_log" ]]; then
    phase_a_log="$(mktemp "$TMP/phase-a.XXXXXX")"
    : >"$phase_a_log"
  fi
  processed_log="${RUN_CASE_PROCESSED_LOG:-$TMP/no-processed-fuckups.jsonl}"
  if [[ -z "${RUN_CASE_PROCESSED_LOG:-}" ]]; then
    : >"$processed_log"
  fi
  printf 'proof\n' >"$repo/evidence.md"
  jq -nc '{task_id:"task-pending"}' >"$last"
  jq -nc '{event:"ntm_dispatch_sent",task_id:"task-pending",dispatch_status:"sent",callback_received_at:null}' >"$log"
  local tick_rc
  set +e
  FAKE_NTM_COPY_TEXT="$copy_text" \
  FAKE_FROZEN_DETECTOR_JSON="$detector_json" \
  FLYWHEEL_TICK_CONTRACT_FUCKUP_LOG="$contract_log" \
  FLYWHEEL_TICK_CONTRACT_NOW="2026-05-07T00:10:00Z" \
  FLYWHEEL_TICK_PHASE_A_FUCKUP_LOG="$phase_a_log" \
  FLYWHEEL_TICK_FUCKUP_PROCESSED_LOG="$processed_log" \
  FLYWHEEL_TICK_AUTOLOOP_LOG="${FLYWHEEL_TICK_AUTOLOOP_LOG:-}" \
  FLYWHEEL_TICK_TRANSPORT_EVIDENCE_LOG="${FLYWHEEL_TICK_TRANSPORT_EVIDENCE_LOG:-}" \
  FLYWHEEL_TICK_BUDGET_SECONDS="${FLYWHEEL_TICK_BUDGET_SECONDS:-0}" \
  FLYWHEEL_TICK_LEARN_REVIEW_RAN="${FLYWHEEL_TICK_LEARN_REVIEW_RAN:-0}" \
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
jq -e '.properties.tick_contract and .properties.tick_contract_checks and .properties.tick_contract_graduation' "$TICK_SCHEMA" >/dev/null \
  && pass "3mmp tick schema exposes contract registry fields" || fail "3mmp tick schema exposes contract registry fields"
jq -e '.properties.phase_a and .properties.checks_run and .properties.violations and .properties.mode and .properties.hold_reason' "$TICK_SCHEMA" >/dev/null \
  && pass "kaqr tick schema exposes Phase A receipt fields" || fail "kaqr tick schema exposes Phase A receipt fields"
jq -e '.properties.fuckup_to_bead_pipeline.properties.required_steps.items.enum | index("planning-workflow") and index("jeff-convergence-audit") and index("beads-workflow")' "$TICK_SCHEMA" >/dev/null \
  && pass "2ha tick schema exposes fuckup planning pipeline fields" || fail "2ha tick schema exposes fuckup planning pipeline fields"

run_case "B05_AG2 pending callback routes to VALIDATE and counts unvalidated" "" "VALIDATE" \
  '(.phase_reason | test("callback_pending_unvalidated")) and .validation_summary.callbacks_unvalidated_count == 1'

run_case "B05_AG3 failed validation blocks INTEGRATE without remediation" "DONE task-pending evidence=missing.md evidence_redacted=n/a" "VALIDATE" \
  '.validation_summary.status == "fail" and .validation_summary.integration_allowed == false and (.validation_summary.failure_classes | index("artifact_missing"))'

run_case "B05_AG4 runtime timeout maps to VALIDATE unknown" "TIMEOUT task-pending" "VALIDATE" \
  '.validation_summary.status == "unknown" and .validation_summary.unknown_count == 1'

run_case "B05_AG5 clean validation proceeds to INTEGRATE with receipt ref" "DONE task-pending evidence=evidence.md evidence_redacted=n/a beads_updated=task-pending" "INTEGRATE" \
  '.validation_summary.status == "pass" and .validation_summary.integration_allowed == true and (.validation_summary.receipt_path | type) == "string"'

run_case "B05_AG6 dry-run records planned VALIDATE action without live send" "" "VALIDATE" \
  '.dispatch_status == "dry_run" and (.prompt_file | test("flywheel-tick-"))'

run_case "B05_AG7 tick receipt includes doctor/learn validation summary fields" "DONE task-pending evidence=evidence.md evidence_redacted=n/a beads_updated=task-pending" "INTEGRATE" \
  '.validation_summary | has("callbacks_unvalidated_count") and has("failure_classes") and has("receipt_path") and has("integration_allowed")'

run_case "vnsw tick receipt includes scheduled probe fields" "DONE task-pending evidence=evidence.md evidence_redacted=n/a beads_updated=task-pending" "INTEGRATE" \
  'has("jeff_status") and has("jeff_fixes") and has("agent_mail_fd") and has("mobile_eats_receipt") and has("skillos_loop") and has("daily_jeff_ingest") and has("fleet_onboard") and has("fleet_stash_bloat") and has("fleet_stash_bloat_detected") and has("fleet_stash_bloat_repo_count") and has("agent_mail_fd_status") and has("mobile_eats_receipt_status") and has("daily_jeff_ingest_status") and has("fleet_onboard_status")'

run_case "3mmp tick receipt includes tick-contract registry fields" "DONE task-pending evidence=evidence.md evidence_redacted=n/a beads_updated=task-pending" "INTEGRATE" \
  'has("tick_contract") and has("tick_contract_checks") and has("tick_contract_graduation") and .tick_contract.contract_id == "tick-contract-core" and (.tick_contract.receipt_fields | index("tick_contract_graduation")) and (.tick_contract_checks | length) >= 16'

run_case "kaqr tick receipt includes Phase A checks, SOFT mode, and hold reason" "DONE task-pending evidence=evidence.md evidence_redacted=n/a beads_updated=task-pending" "INTEGRATE" \
  'has("phase_a") and .mode == "SOFT" and (.checks_run | index("autoloop-receipts-read")) and (.checks_run | index("learn-review-when-unprocessed")) and (.checks_run | index("worker-pane-state-verified")) and (.checks_run | index("ntm-dispatch-discipline")) and .hold_reason == "phase_integrate_no_worker_dispatch"'

autoloop_unread_log="$TMP/autoloop-unread.jsonl"
jq -nc '{event:"tick_complete",status:"unread",unread:true}' >"$autoloop_unread_log"
FLYWHEEL_TICK_AUTOLOOP_LOG="$autoloop_unread_log" \
run_case "kaqr unread autoloop receipt emits substrate-read SOFT violation" "DONE task-pending evidence=evidence.md evidence_redacted=n/a beads_updated=task-pending" "INTEGRATE" \
  '.phase_a.violations[] | select(.failure_class == "orch_skipped_substrate_read" and .mode == "SOFT" and .logged_to_fuckup_log == true)'
unset FLYWHEEL_TICK_AUTOLOOP_LOG

learn_log="$TMP/phase-a-learn.jsonl"
for i in 1 2 3; do
  jq -nc --arg i "$i" '{ts:"2026-05-07T00:00:00Z",trauma_class:("fixture_" + $i),severity:"medium"}' >>"$learn_log"
done
RUN_CASE_PHASE_A_LOG="$learn_log" \
run_case "kaqr three unprocessed fuckups without review emits learn-review violation" "DONE task-pending evidence=evidence.md evidence_redacted=n/a beads_updated=task-pending" "INTEGRATE" \
  '.phase_a.violations[] | select(.failure_class == "orch_skipped_learn_review" and .detail.unprocessed_fuckup_events >= 3 and .logged_to_fuckup_log == true)'
unset RUN_CASE_PHASE_A_LOG

pipeline_log="$TMP/pipeline-fuckup.jsonl"
jq -nc '{ts:"2026-05-07T00:00:00Z",id:"fu-1",class:"fixture_plan_required"}' >"$pipeline_log"
RUN_CASE_PHASE_A_LOG="$pipeline_log" \
run_case "2ha unprocessed fuckup requires planning/convergence/beads pipeline" "DONE task-pending evidence=evidence.md evidence_redacted=n/a beads_updated=task-pending" "INTEGRATE" \
  '.fuckup_to_bead_pipeline.status == "pending"
    and .fuckup_to_bead_pipeline.unprocessed_count == 1
    and (.fuckup_to_bead_pipeline.required_steps | index("planning-workflow"))
    and (.fuckup_to_bead_pipeline.required_steps | index("jeff-convergence-audit"))
    and (.fuckup_to_bead_pipeline.required_steps | index("beads-workflow"))
    and (.fuckup_to_bead_pipeline.next_action | test("planning-workflow.*jeff-convergence-audit.*beads-workflow"))'
unset RUN_CASE_PHASE_A_LOG

pipeline_empty="$TMP/pipeline-empty.jsonl"
pipeline_processed="$TMP/pipeline-processed.jsonl"
: >"$pipeline_empty"
jq -nc '{ts:"2026-05-07T00:00:00Z",fuckup_log_id:"fu-2",beads_filed:"flywheel-fixture"}' >"$pipeline_processed"
RUN_CASE_PROCESSED_LOG="$pipeline_processed" RUN_CASE_PHASE_A_LOG="$pipeline_empty" \
run_case "2ha direct bead without plan/audit is visible drift" "DONE task-pending evidence=evidence.md evidence_redacted=n/a beads_updated=task-pending" "INTEGRATE" \
  '.fuckup_to_bead_pipeline.status == "warn"
    and .fuckup_to_bead_pipeline.direct_bead_without_pipeline_count == 1
    and (.fuckup_to_bead_pipeline.missing_pipeline_reasons | index("planning_workflow_ref_missing"))
    and (.fuckup_to_bead_pipeline.missing_pipeline_reasons | index("jeff_convergence_audit_ref_missing"))'
unset RUN_CASE_PROCESSED_LOG RUN_CASE_PHASE_A_LOG

raw_transport_log="$TMP/raw-transport.log"
printf 'fixture: tmux send-keys flywheel:1 prompt\n' >"$raw_transport_log"
FLYWHEEL_TICK_TRANSPORT_EVIDENCE_LOG="$raw_transport_log" \
run_case "kaqr raw transport evidence emits NTM discipline violation class" "DONE task-pending evidence=evidence.md evidence_redacted=n/a beads_updated=task-pending" "INTEGRATE" \
  '.phase_a.violations[] | select(.failure_class == "orch_used_raw_tmux" and .detail.raw_transport_evidence_count == 1)'
unset FLYWHEEL_TICK_TRANSPORT_EVIDENCE_LOG

FLYWHEEL_TICK_BUDGET_SECONDS=1 \
run_case "kaqr bounded runtime reports tick budget exceeded with handoff receipt" "DONE task-pending evidence=evidence.md evidence_redacted=n/a beads_updated=task-pending" "INTEGRATE" \
  '.phase_a.violations[] | select(.failure_class == "tick_budget_exceeded" and .detail.handoff_receipt.required == true)'
unset FLYWHEEL_TICK_BUDGET_SECONDS

run_case "3mmp graduation fixture 0 rows computes SOFT" "DONE task-pending evidence=evidence.md evidence_redacted=n/a beads_updated=task-pending" "INTEGRATE" \
  '.tick_contract_checks[] | select(.failure_class == "worker_low_socraticode_K" and .event_count_7d == 0 and .computed_mode == "SOFT" and .mode == "SOFT")' \
  "" "$ROOT/.flywheel/tick-contract-registry/v1/fixtures/graduation-soft.jsonl"

run_case "3mmp graduation fixture 3 rows computes WARN" "DONE task-pending evidence=evidence.md evidence_redacted=n/a beads_updated=task-pending" "INTEGRATE" \
  '.tick_contract_checks[] | select(.failure_class == "worker_low_socraticode_K" and .event_count_7d == 3 and .computed_mode == "WARN" and .mode == "WARN")' \
  "" "$ROOT/.flywheel/tick-contract-registry/v1/fixtures/graduation-warn.jsonl"

run_case "3mmp graduation fixture 6 rows computes HALT" "DONE task-pending evidence=evidence.md evidence_redacted=n/a beads_updated=task-pending" "INTEGRATE" \
  '.tick_contract_checks[] | select(.failure_class == "worker_low_socraticode_K" and .event_count_7d == 6 and .computed_mode == "HALT" and .mode == "HALT")' \
  "" "$ROOT/.flywheel/tick-contract-registry/v1/fixtures/graduation-halt.jsonl"

run_case "wxth tick receipt includes leverage ceiling measurement fields" "DONE task-pending evidence=evidence.md evidence_redacted=n/a beads_updated=task-pending" "INTEGRATE" \
  'has("leverage_ceiling") and .leverage_ceiling_score == 800 and .leverage_ceiling_binding_constraint == "tokens" and (.leverage_ceiling_warnings | index("fixture-token-budget-low")) and .leverage_ceiling_accounts_active == 2 and .leverage_ceiling_worker_panes_total == 5 and .leverage_ceiling_worker_panes_working_count == 4'

run_case "i8rd tick receipt includes detector v2 stale/unknown/recovery-suppressed counts and L60 5-signal check" "DONE task-pending evidence=evidence.md evidence_redacted=n/a beads_updated=task-pending" "INTEGRATE" \
  'has("frozen_detector") and .frozen_detector_source_health_status == "healthy" and .frozen_detector_frozen_panes_detected == 0 and .frozen_detector_unknown_panes_detected == 0 and .frozen_detector_stale_template_prompt_count == 0 and .frozen_detector_respawn_suppressed_count == 0 and .frozen_detector_l60_signal_present_count == 5 and .frozen_detector_l60_signal_expected_count == 5 and .frozen_detector_l60_all_present == true and (.frozen_detector_l60_signal_missing | length) == 0 and .frozen_detector_dispatch_block_reason == "none"'

frozen_detector_fixture="$(jq -nc '{schema_version:"frozen-pane-detector.v2",success:true,source_health:{status:"healthy"},frozen_panes_detected:1,unknown_panes_detected:0,template_stub_prompt_count:2,queued_not_submitted_count:0,respawn_suppressed_count:1,recovery_suppressed_count:0,l60_signals_present:{no_silent_darkness:true,live_truth_delta:true,unknown_separated:true,recovery_budget:true,recovery_lease:true},soft_violations:[],durable_receipts:[],silent_dark_minutes:12,blackout_detection_latency_p95:300,false_recovery_count:0,unknown_auto_recovery_count:0}')"
run_case "i8rd frozen detector blocks dispatch while preserving detector counts" "DONE task-pending evidence=evidence.md evidence_redacted=n/a beads_updated=task-pending" "INTEGRATE" \
  '.dispatch_status == "blocked_frozen_detector" and .frozen_detector_dispatch_block_reason == "frozen_panes_detected" and .frozen_detector_frozen_panes_detected == 1 and .frozen_detector_stale_template_prompt_count == 2 and .frozen_detector_respawn_suppressed_count == 1' \
  "$frozen_detector_fixture"

unknown_l60_fixture="$(jq -nc '{schema_version:"frozen-pane-detector.v2",success:true,source_health:{status:"healthy"},frozen_panes_detected:0,unknown_panes_detected:1,template_stub_prompt_count:0,queued_not_submitted_count:0,respawn_suppressed_count:0,recovery_suppressed_count:0,l60_signals_present:{no_silent_darkness:true,live_truth_delta:false,unknown_separated:true,recovery_budget:true,recovery_lease:true},soft_violations:[{class:"unknown_truth_not_recovered"}],durable_receipts:[{status:"UNKNOWN"}],silent_dark_minutes:5,blackout_detection_latency_p95:0,false_recovery_count:0,unknown_auto_recovery_count:0}')"
run_case "i8rd unknown detector state blocks dispatch and surfaces missing L60 signal" "DONE task-pending evidence=evidence.md evidence_redacted=n/a beads_updated=task-pending" "INTEGRATE" \
  '.dispatch_status == "blocked_frozen_detector" and .frozen_detector_dispatch_block_reason == "unknown_panes_detected" and .frozen_detector_unknown_panes_detected == 1 and .frozen_detector_l60_signal_present_count == 4 and .frozen_detector_l60_all_present == false and (.frozen_detector_l60_signal_missing | index("live_truth_delta"))' \
  "$unknown_l60_fixture"

printf '\nSummary: %s passed, %s failed\n' "$pass_count" "$fail_count"
[[ "$fail_count" -eq 0 ]]
