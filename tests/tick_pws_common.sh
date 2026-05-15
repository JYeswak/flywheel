#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd -P)"
TICK="$ROOT/.flywheel/flywheel-loop-tick"

tick_pws_make_repo() {
  local repo="$1"
  mkdir -p "$repo/.flywheel/scripts" "$repo/.flywheel/runtime/flywheel-loop" \
    "$repo/.flywheel/prompts" "$repo/.flywheel/validation-schema/v1" \
    "$repo/.flywheel/tick-contract-registry/v1" "$repo/.beads"
  printf 'status: ready\n' >"$repo/.flywheel/MISSION.md"
  printf 'status: ready\n' >"$repo/.flywheel/GOAL.md"
  printf 'status: ready\n' >"$repo/.flywheel/STATE.md"
  : >"$repo/.beads/issues.jsonl"
  jq -nc '{phase:"DISPATCH"}' >"$repo/.flywheel/next_tick_override.json"

  cp "$ROOT/.flywheel/scripts/dispatch-capacity-gate.sh" "$repo/.flywheel/scripts/dispatch-capacity-gate.sh"
  cp "$ROOT/.flywheel/scripts/pane-work-signal.sh" "$repo/.flywheel/scripts/pane-work-signal.sh"
  cp "$ROOT/.flywheel/scripts/validate-callback.py" "$repo/.flywheel/scripts/validate-callback.py"
  cp "$ROOT/.flywheel/validation-schema/v1/schema.json" "$repo/.flywheel/validation-schema/v1/schema.json"
  cp "$ROOT/.flywheel/validation-schema/v1/parse.sh" "$repo/.flywheel/validation-schema/v1/parse.sh"
  cp "$ROOT/.flywheel/tick-contract-registry/v1/registry.json" "$repo/.flywheel/tick-contract-registry/v1/registry.json"
  chmod +x "$repo/.flywheel/scripts/dispatch-capacity-gate.sh" "$repo/.flywheel/scripts/pane-work-signal.sh" "$repo/.flywheel/validation-schema/v1/parse.sh"

  tick_pws_stub "$repo/.flywheel/scripts/frozen-pane-detector.sh" '{"schema_version":"frozen-pane-detector.v2","success":true,"source_health":{"status":"healthy"},"frozen_panes_detected":0,"unknown_panes_detected":0,"template_stub_prompt_count":0,"queued_not_submitted_count":0,"respawn_suppressed_count":0,"recovery_suppressed_count":0,"l60_signals_present":{"no_silent_darkness":true,"live_truth_delta":true,"unknown_separated":true,"recovery_budget":true,"recovery_lease":true},"soft_violations":[],"durable_receipts":[],"silent_dark_minutes":0,"blackout_detection_latency_p95":0,"false_recovery_count":0,"unknown_auto_recovery_count":0}'
  tick_pws_stub "$repo/.flywheel/scripts/inbox-check-tick-step.sh" '{"action":"skipped","identity":"fixture"}'
  tick_pws_stub "$repo/.flywheel/scripts/agent-mail-fd-doctor.sh" '{"status":"ok","total_fds":0,"lock_fd_count":0,"warnings":[]}'
  tick_pws_stub "$repo/.flywheel/scripts/leverage-ceiling-probe.sh" '{"success":true,"status":"ok","leverage_ceiling_score":900,"binding_constraint":"none","binding_evidence":"fixture","warnings":[],"accounts_active":1,"worker_panes_total":1,"worker_panes_working_count":0}'
  tick_pws_stub "$repo/.flywheel/scripts/ntm-surface-validation-driver.sh" '{"schema_version":"ntm-surface-validation-driver.v1","status":"ok","status_counts":{"FAIL":0,"UNVERIFIED":0},"ntm_surface_coverage_avg":1}'
  tick_pws_stub "$repo/.flywheel/scripts/topology-tick-refresh.sh" '{"schema_version":"topology-tick-refresh.result.v1","status":"ok","timeout_sec":30,"post_check":{"ledger_row_written":true}}'
  tick_pws_stub "$repo/.flywheel/scripts/value-gap-probe.sh" '{"success":true,"mode":"run","value_gap_dimension_scanned":null,"value_gap_finding":null,"bead_filed_id":null}'
  tick_pws_stub "$repo/.flywheel/scripts/jeff-issues-status-probe.sh" '{"stale_open_count":0,"tracked_count":0}'
  tick_pws_stub "$repo/.flywheel/scripts/jeff-fixes-pull-probe.sh" '{"status":"ok"}'
  tick_pws_stub "$repo/.flywheel/scripts/jeff-issue-response-poll.sh" '{"action":"test"}'
  tick_pws_stub "$repo/.flywheel/scripts/jeff-intel-network.sh" '{"action":"test"}'
  tick_pws_stub "$repo/.flywheel/scripts/jeff-philosophy-mine.sh" '{"status":"ok","pattern_count":0,"complete_pattern_count":0,"latest_snapshot_path":null,"checks":{"patterns_jsonl_exists":true}}'
  tick_pws_stub "$repo/.flywheel/scripts/jeff-binary-version-watchtower.sh" '{"status":"ok","stale_count":0,"highest_priority":null,"stale":[]}'
  tick_pws_stub "$repo/.flywheel/scripts/{proof-product}-receipt-bridge.sh" '{"status":"ok","mobile_eats":{},"warnings":[]}'
  tick_pws_stub "$repo/.flywheel/scripts/flywheel-onboard.sh" '{"status":"ok","checked_repos":0,"limping_repos":[],"missing_repos":[],"warnings":[]}'
  tick_pws_stub "$repo/.flywheel/scripts/josh-request-tick-promote.sh" '{"action":"test"}'
  tick_pws_stub "$repo/.flywheel/scripts/doctor-signal-bead-promotion.sh" '{"action":"test"}'
  tick_pws_stub "$repo/.flywheel/scripts/doctrine-ladder-promote.sh" '{"action":"test"}'
}

tick_pws_stub() {
  local path="$1" json="$2"
  cat >"$path" <<SH
#!/usr/bin/env bash
set -euo pipefail
printf '%s\n' '$json'
SH
  chmod +x "$path"
}

tick_pws_fake_ntm() {
  local path="$1" agent_type="$2" activity="$3" status="${4:-ok}" process="${5:-running}"
  cat >"$path" <<SH
#!/usr/bin/env bash
set -euo pipefail
case "\${1:-}" in
  assign)
    jq -nc '{data:{summary:{idle_agent_count:1},assignments:[{pane:2}]}}'
    ;;
  health)
    jq -nc --arg agent_type "$agent_type" --arg activity "$activity" --arg status "$status" --arg process "$process" '{agents:[{pane:2,pane_idx:2,agent_type:\$agent_type,activity:\$activity,state:\$activity,status:\$status,process_status:\$process,health_score:100,local_state:{is_idle:(\$activity=="idle" or \$activity=="WAITING")}}]}'
    ;;
  activity)
    jq -nc --arg agent_type "$agent_type" --arg activity "$activity" '{agents:[{session:"flywheel",pane:2,pane_idx:2,agent_type:\$agent_type,state:\$activity,activity:\$activity,idle_seconds:1}]}'
    ;;
  history)
    jq -nc '{entries:[]}'
    ;;
  send)
    jq -nc '{status:"dry_run_fixture"}'
    ;;
  *)
    jq -nc '{}'
    ;;
esac
SH
  chmod +x "$path"
}

tick_pws_seed_working() {
  local state_dir="$1" session="${2:-flywheel}" pane="${3:-2}"
  mkdir -p "$state_dir"
  jq -nc --arg ts "$(date -u +%Y-%m-%dT%H:%M:%SZ)" --arg session "$session" --argjson pane "$pane" \
    '{ts:$ts,session:$session,pane:$pane,hash:"fixturehash",lines:1,bytes:1,agent_kind:"codex",ntm_activity:"idle",ntm_stage:"idle",ntm_idle_s:1,foreground_working_state:true,foreground_working_evidence:"Working (47s) | fixture",truth_state:"working",truth_source:"pane_work_signal",truth_reason:"foreground_working_structured_row",classification:"working"}' \
    >"$state_dir/pane-work-signal.jsonl"
}

tick_pws_run() {
  local tmp="$1" agent_type="$2" activity="$3" extra_env="${4:-}"
  local repo state prompt log
  repo="$tmp/repo"
  state="$repo/.flywheel/runtime/flywheel-loop"
  prompt="$repo/.flywheel/prompts"
  log="$repo/.flywheel/dispatch-log.jsonl"
  tick_pws_make_repo "$repo"
  tick_pws_fake_ntm "$tmp/ntm" "$agent_type" "$activity"
  tick_pws_seed_working "$tmp/pws"
  set +e
  eval "$extra_env REPO=\"$repo\" SESSION=\"flywheel\" TARGET_PANE=\"1\" STATE_DIR=\"$state\" PROMPT_DIR=\"$prompt\" LOG=\"$log\" NTM=\"$tmp/ntm\" PANE_WORK_SIGNAL_STATE_DIR=\"$tmp/pws\" DISPATCH_CAPACITY_PANES=\"2\" FLYWHEEL_LOOP_TICK_DRY_RUN=1 bash \"$TICK\" >\"$tmp/tick.out\" 2>\"$tmp/tick.err\""
  local rc=$?
  set -e
  printf '%s\n' "$rc" >"$tmp/tick.rc"
  return "$rc"
}
