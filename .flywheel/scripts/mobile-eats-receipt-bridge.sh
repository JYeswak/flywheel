#!/usr/bin/env bash
set -uo pipefail

VERSION="mobile-eats-receipt-bridge.v1"
SCRIPT_VERSION="2026-05-03.2"
PROJECT="mobile-eats"
TIER="active_high"
REPO="${MOBILE_EATS_REPO:-/Users/josh/Developer/mobile-eats}"
STATE_DIR="${MOBILE_EATS_LOOP_STATE_DIR:-$HOME/.local/state/mobile-eats-flywheel-loop}"
LAST_RUN="${MOBILE_EATS_LAST_RUN:-$STATE_DIR/last_run.json}"
TICKS_DIR="${MOBILE_EATS_TICKS_DIR:-$REPO/.flywheel/ticks}"
LOG_FILE="${MOBILE_EATS_LOOP_LOG:-$HOME/.local/logs/mobile-eats-flywheel-loop.jsonl}"
BR_BIN="${MOBILE_EATS_BR_BIN:-$HOME/.cargo/bin/br}"
SINCE_DEFAULT="$(date -u -v-1d '+%Y-%m-%dT00:00:00Z' 2>/dev/null || date -u -d 'yesterday' '+%Y-%m-%dT00:00:00Z' 2>/dev/null || printf '%s' '2026-05-02T00:00:00Z')"
COMMITS_SINCE="${MOBILE_EATS_COMMITS_SINCE:-$SINCE_DEFAULT}"
MODE="probe"
JSON=0
QUIET=0
DRY_RUN=0

usage() {
  cat <<'USAGE'
Usage:
  mobile-eats-receipt-bridge.sh [--json] [--quiet] [--dry-run]
  mobile-eats-receipt-bridge.sh --doctor [--json] [--quiet]
  mobile-eats-receipt-bridge.sh --info [--json]
  mobile-eats-receipt-bridge.sh --schema
  mobile-eats-receipt-bridge.sh --examples
  mobile-eats-receipt-bridge.sh --help

Read-only bridge from mobile-eats product loop receipts to canonical flywheel tick-shaped JSON.
USAGE
}

examples() {
  cat <<'EXAMPLES'
Examples:
  .flywheel/scripts/mobile-eats-receipt-bridge.sh --json
  .flywheel/scripts/mobile-eats-receipt-bridge.sh --doctor --json
  MOBILE_EATS_COMMITS_SINCE=2026-05-02T00:00:00-06:00 .flywheel/scripts/mobile-eats-receipt-bridge.sh --quiet --json
EXAMPLES
}

schema_json() {
  jq -nc --arg version "$VERSION" '{
    version:$version,
    schema:"flywheel.mobile_eats_receipt_bridge.v1",
    canonical_shape:"~/.local/state/flywheel-loop/last_tick_<project>.json compatible",
    required_fields:["task_id","ts","exit_code","session","pane","project","tier","decision","autoloop_receipts_read","dispatches_sent","warnings","closed_beads_since_yesterday","commits_since","mobile_eats","dashboard_line"],
    mobile_eats_fields:["repo","run_id","session","pane","exit_code","last_run_ts","last_run_status","run_count","dispatch_count","tick_count","latest_tick_file","latest_tick_decision","closed_beads_since","commits_since","driver_unchanged"]
  }'
}

now_iso() {
  date -u +%Y-%m-%dT%H:%M:%SZ
}

json_string() {
  jq -Rn --arg v "$1" '$v'
}

append_warning() {
  WARNINGS_JSON="$(printf '%s' "$WARNINGS_JSON" | jq -c --arg msg "$1" '. + [$msg]' 2>/dev/null || printf '["warning-json-append-failed"]')"
}

jq_file() {
  local filter="$1"
  local file="$2"
  jq -r "$filter" "$file" 2>/dev/null || printf '%s\n' ""
}

file_mtime_iso() {
  local file="$1"
  date -u -r "$file" +%Y-%m-%dT%H:%M:%SZ 2>/dev/null || printf '%s\n' ""
}

count_log_event() {
  local event="$1"
  if [ ! -f "$LOG_FILE" ]; then
    printf '0\n'
    return
  fi
  jq -r --arg e "$event" 'select(.event == $e) | 1' "$LOG_FILE" 2>/dev/null | awk 'END { print NR + 0 }'
}

closed_beads_count() {
  if [ ! -x "$BR_BIN" ]; then
    append_warning "br unavailable at $BR_BIN"
    printf 'null\n'
    return
  fi
  (cd "$REPO" && "$BR_BIN" list --status closed --json 2>/dev/null) | jq 'if type == "array" then length else (.issues // [] | length) end' 2>/dev/null || {
    append_warning "closed bead count unavailable"
    printf 'null\n'
  }
}

commit_count_since() {
  (cd "$REPO" && git log --since="$COMMITS_SINCE" --pretty=format:'%h' 2>/dev/null | awk 'END { print NR + 0 }') || {
    append_warning "git commit count unavailable"
    printf 'null\n'
  }
}

latest_tick_file() {
  if [ ! -d "$TICKS_DIR" ]; then
    printf '%s\n' ""
    return
  fi
  find "$TICKS_DIR" -name '*.json' -type f 2>/dev/null | sort | tail -1
}

tick_count() {
  if [ ! -d "$TICKS_DIR" ]; then
    printf '0\n'
    return
  fi
  find "$TICKS_DIR" -name '*.json' -type f 2>/dev/null | awk 'END { print NR + 0 }'
}

info_json() {
  jq -nc \
    --arg version "$VERSION" \
    --arg script_version "$SCRIPT_VERSION" \
    --arg repo "$REPO" \
    --arg state_dir "$STATE_DIR" \
    --arg last_run "$LAST_RUN" \
    --arg ticks_dir "$TICKS_DIR" \
    --arg log_file "$LOG_FILE" \
    --arg br_bin "$BR_BIN" \
    --arg commits_since "$COMMITS_SINCE" \
    '{success:true, mode:"info", version:$version, script_version:$script_version, repo:$repo, state_dir:$state_dir, last_run:$last_run, ticks_dir:$ticks_dir, log_file:$log_file, br_bin:$br_bin, commits_since:$commits_since, read_only:true, driver_mutation:false}'
}

run_probe() {
  WARNINGS_JSON='[]'

  local ts task_id exit_code session pane pane_json last_run_ts last_run_status last_run_prompt latest_tick latest_tick_base
  local latest_tick_decision latest_tick_action latest_tick_status latest_tick_mtime
  local ticks runs dispatches closed commits decision dashboard_line status

  ts="$(now_iso)"
  if [ -f "$LAST_RUN" ]; then
    task_id="$(jq_file '.task_id // .run_id // empty' "$LAST_RUN")"
    exit_code="$(jq_file '.exit_code // 0' "$LAST_RUN")"
    session="$(jq_file '.session // empty' "$LAST_RUN")"
    pane="$(jq_file '.pane // empty' "$LAST_RUN")"
    last_run_ts="$(jq_file '.ts // empty' "$LAST_RUN")"
    last_run_status="$(jq_file '.status // .dispatch_status // empty' "$LAST_RUN")"
    last_run_prompt="$(jq_file '.prompt_file // empty' "$LAST_RUN")"
  else
    task_id=""
    exit_code="0"
    session=""
    pane=""
    last_run_ts=""
    last_run_status=""
    last_run_prompt=""
    append_warning "missing last_run: $LAST_RUN"
  fi

  task_id="${task_id:-mobile-eats:${last_run_ts:-$ts}}"
  exit_code="${exit_code:-0}"
  session="${session:-mobile-eats}"
  pane="${pane:-1}"
  case "$exit_code" in ''|*[!0-9-]*) exit_code=0 ;; esac
  case "$pane" in ''|*[!0-9]*) pane_json=1 ;; *) pane_json="$pane" ;; esac

  ticks="$(tick_count)"
  if [ "$ticks" = "0" ]; then
    append_warning "no repo-local tick receipts found in $TICKS_DIR"
  fi

  latest_tick="$(latest_tick_file)"
  if [ -n "$latest_tick" ] && [ -f "$latest_tick" ]; then
    latest_tick_base="${latest_tick##*/}"
    latest_tick_decision="$(jq_file '.decision // empty' "$latest_tick")"
    latest_tick_action="$(jq_file '.action // empty' "$latest_tick")"
    latest_tick_status="$(jq_file '.status // empty' "$latest_tick")"
    latest_tick_mtime="$(file_mtime_iso "$latest_tick")"
  else
    latest_tick_base=""
    latest_tick_decision=""
    latest_tick_action=""
    latest_tick_status=""
    latest_tick_mtime=""
  fi

  if [ ! -f "$LOG_FILE" ]; then
    append_warning "missing driver log: $LOG_FILE"
  fi
  runs="$(count_log_event "run_start")"
  dispatches="$(count_log_event "ntm_dispatch_sent")"
  closed="$(closed_beads_count)"
  commits="$(commit_count_since)"

  decision="${latest_tick_decision:-${last_run_status:-UNKNOWN}}"
  status="ok"
  if [ "$(printf '%s' "$WARNINGS_JSON" | jq 'length')" -gt 0 ]; then
    status="warn"
  fi

  dashboard_line="📱 Mobile-eats: ${closed} closed beads/${commits} commits since ${COMMITS_SINCE}, last tick ${last_run_ts:-unknown}, decision=${decision}"

  jq -nc \
    --arg version "$VERSION" \
    --arg mode "$MODE" \
    --arg task_id "$task_id" \
    --arg ts "$ts" \
    --arg session "$session" \
    --arg project "$PROJECT" \
    --arg tier "$TIER" \
    --arg decision "$decision" \
    --arg action "${latest_tick_action:-}" \
    --arg next_tick_at "" \
    --arg dashboard_line "$dashboard_line" \
    --arg status "$status" \
    --arg repo "$REPO" \
    --arg last_run "$LAST_RUN" \
    --arg last_run_ts "$last_run_ts" \
    --arg last_run_status "$last_run_status" \
    --arg last_run_prompt "$last_run_prompt" \
    --arg ticks_dir "$TICKS_DIR" \
    --arg latest_tick_file "$latest_tick" \
    --arg latest_tick_base "$latest_tick_base" \
    --arg latest_tick_status "$latest_tick_status" \
    --arg latest_tick_decision "$latest_tick_decision" \
    --arg latest_tick_mtime "$latest_tick_mtime" \
    --arg log_file "$LOG_FILE" \
    --arg commits_since "$COMMITS_SINCE" \
    --argjson exit_code "$exit_code" \
    --argjson pane "$pane_json" \
    --argjson autoloop_receipts_read "${runs:-0}" \
    --argjson dispatches_sent "${dispatches:-0}" \
    --argjson tick_count "${ticks:-0}" \
    --argjson closed_beads_since "$closed" \
    --argjson commits_since_count "$commits" \
    --argjson warnings "$WARNINGS_JSON" \
    --argjson dry_run "$([ "$DRY_RUN" -eq 1 ] && printf 'true' || printf 'false')" \
    '{
      version:$version,
      mode:$mode,
      task_id:$task_id,
      ts:$ts,
      exit_code:$exit_code,
      session:$session,
      pane:$pane,
      project:$project,
      tier:$tier,
      decision:$decision,
      autoloop_receipts_read:$autoloop_receipts_read,
      fuckup_events_unprocessed:null,
      panes_checked:false,
      fleet_flags:[],
      dispatches_sent:$dispatches_sent,
      callbacks_reaped:null,
      refilled_beads:[],
      refill_deferred_reason:null,
      deferred_beads:[],
      awareness_check:{mission_anchor_read:null, goal_state:null, state_freshness_hours:null, last_3_receipts_read:3, delta_flags:[]},
      inbox_messages_handled:null,
      beads_filed_from_inbox:null,
      dispatches_from_inbox:null,
      inbox_skipped_reason:null,
      fuckups_to_beads:null,
      fuckups_no_bead_reason:null,
      fuckups_skipped:null,
      skillos_routed_count:null,
      skillos_routed_decisions:[],
      pagerank_top_5_blockers:[],
      dispatched_from_pagerank:null,
      dual_channel_pct:null,
      l61_counter_examples:[],
      vc_status:null,
      vc_alerts_count:null,
      vc_digest_summary:null,
      mission_lock_age_hours:null,
      mission_lock_status:null,
      mission_lock_id:null,
      lock_hash_matches_lock_log:null,
      leverage_ceiling_score:null,
      leverage_ceiling_binding_constraint:null,
      leverage_ceiling_warnings:[],
      gaps_total:null,
      gaps_new_this_tick:null,
      gap_class_distribution:{},
      gap_warnings:[],
      violations:[],
      action_taken:$action,
      next_tick_at:(if $next_tick_at == "" then null else $next_tick_at end),
      warnings:$warnings,
      status:$status,
      dry_run:$dry_run,
      closed_beads_since_yesterday:$closed_beads_since,
      commits_since:$commits_since_count,
      commits_since_start:$commits_since,
      dashboard_line:$dashboard_line,
      mobile_eats:{
        repo:$repo,
        run_id:$task_id,
        session:$session,
        pane:$pane,
        exit_code:$exit_code,
        last_run_path:$last_run,
        last_run_ts:$last_run_ts,
        last_run_status:$last_run_status,
        prompt_file:$last_run_prompt,
        ticks_dir:$ticks_dir,
        tick_count:$tick_count,
        latest_tick_path:$latest_tick_file,
        latest_tick_file:$latest_tick_base,
        latest_tick_status:$latest_tick_status,
        latest_tick_decision:$latest_tick_decision,
        latest_tick_mtime:$latest_tick_mtime,
        log_file:$log_file,
        run_count:$autoloop_receipts_read,
        dispatch_count:$dispatches_sent,
        closed_beads_since:$closed_beads_since,
        commits_since:$commits_since_count,
        commits_since_start:$commits_since,
        driver_unchanged:true,
        bridge_option:"A"
      }
    }'
}

while [ "$#" -gt 0 ]; do
  case "$1" in
    --help|-h) MODE="help" ;;
    --info) MODE="info" ;;
    --schema) MODE="schema" ;;
    --examples) MODE="examples" ;;
    --doctor|doctor) MODE="doctor" ;;
    --health|health) MODE="doctor" ;;
    --json) JSON=1 ;;
    --quiet) QUIET=1 ;;
    --dry-run) DRY_RUN=1 ;;
    completion) printf 'complete -W "--doctor doctor --health health --json --quiet --dry-run --info --schema --examples completion --help" mobile-eats-receipt-bridge.sh\n'; exit 0 ;;
    *) printf 'Unknown argument: %s\n' "$1" >&2; usage >&2; exit 2 ;;
  esac
  shift
done

case "$MODE" in
  help)
    usage
    ;;
  examples)
    examples
    ;;
  schema)
    schema_json
    ;;
  info)
    if [ "$JSON" -eq 1 ]; then
      info_json
    else
      usage
      printf '\nVersion: %s\nRepo: %s\nLast run: %s\nTicks: %s\n' "$VERSION" "$REPO" "$LAST_RUN" "$TICKS_DIR"
    fi
    ;;
  doctor|probe)
    output="$(run_probe)"
    if [ "$JSON" -eq 1 ]; then
      printf '%s\n' "$output"
    elif [ "$QUIET" -eq 0 ]; then
      printf '%s\n' "$output" | jq -r '.dashboard_line'
    fi
    ;;
esac

# Meta-Learning Cross-References (2026-05-19)
# Batch-16 comment backfill; citations are documentation-only and do not alter runtime behavior.
# Related: `/Users/josh/Developer/skillos/.flywheel/doctrine/meta-learnings/MP-04-receipt-callback-envelope.md`
# Related: `/Users/josh/Developer/skillos/.flywheel/doctrine/meta-learnings/MP-88-content-addressed-evidence-pack.md`
