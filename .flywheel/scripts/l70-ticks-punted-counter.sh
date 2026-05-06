#!/usr/bin/env bash
# canonical-cli-scoping-allow-large: gqoz keeps classify, doctor, repair, contract, and fixture-facing CLI in one portable shell entrypoint.
set -euo pipefail

VERSION="l70-ticks-punted-counter.v1.0.0"
SCHEMA_VERSION="l70-ticks-punted/v1"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)"
REPO_ROOT_DEFAULT="$(cd "$SCRIPT_DIR/../.." && pwd -P)"
REPO_ROOT="${L70_TICKS_PUNTED_REPO:-$REPO_ROOT_DEFAULT}"
LEDGER="${L70_TICKS_PUNTED_LEDGER:-$HOME/.local/state/flywheel/l70-ticks-punted.jsonl}"
CONTRACT_LEDGER="${L70_TICKS_PUNTED_CONTRACT_LEDGER:-$HOME/.local/state/flywheel/substrate-loop-contract.jsonl}"
DISPATCH_LOG="${L70_TICKS_PUNTED_DISPATCH_LOG:-$REPO_ROOT/.flywheel/dispatch-log.jsonl}"
JSONL_APPEND_LIB="${FLYWHEEL_JSONL_APPEND_LIB:-$HOME/.local/share/flywheel-watchers/lib/jsonl-append.sh}"
NTM_BIN="${L70_TICKS_PUNTED_NTM_BIN:-$HOME/.local/bin/ntm}"
BR_BIN="${L70_TICKS_PUNTED_BR_BIN:-br}"
SESSION="${SESSION:-flywheel}"
TICK_ID=""
MODE="classify"
JSON_OUT=0
APPLY=0
DRY_RUN=1
WATCH=0
WATCH_INTERVAL=5
REPAIR_SCOPE="ledger"
VALIDATE_TARGET="ledger"
WHY_ID=""
SCHEMA_TOPIC="classification"
HELP_TOPIC=""
COMPLETION_SHELL=""
TAIL_LINES="${L70_TICKS_PUNTED_TAIL_LINES:-120}"
WIDTH=100
EXPLAIN=0
IDEMPOTENCY_KEY=""
ROBOT_ACTIVITY_FILE="${L70_TICKS_PUNTED_ROBOT_ACTIVITY_FILE:-}"
READY_FILE="${L70_TICKS_PUNTED_READY_FILE:-}"

usage() {
  cat <<'EOF'
usage:
  l70-ticks-punted-counter.sh --tick-id ID [--session NAME] [--apply|--dry-run] [--json]
  l70-ticks-punted-counter.sh --doctor [--json]
  l70-ticks-punted-counter.sh health [--watch] [--interval N] [--json]
  l70-ticks-punted-counter.sh repair --scope ledger|substrate-contract|all [--dry-run|--apply] [--json]
  l70-ticks-punted-counter.sh validate ledger [--json]
  l70-ticks-punted-counter.sh audit [--json]
  l70-ticks-punted-counter.sh why ID [--json]
  l70-ticks-punted-counter.sh schema classification|doctor|ledger|contract [--json]
  l70-ticks-punted-counter.sh backfill [--json]
  l70-ticks-punted-counter.sh --info|--examples|quickstart|help TOPIC|completion bash|zsh
EOF
}

json_bool() {
  if [[ "$1" == "1" ]]; then printf true; else printf false; fi
}

now_iso() {
  printf '%s\n' "${L70_TICKS_PUNTED_NOW:-$(date -u +%Y-%m-%dT%H:%M:%SZ)}"
}

emit() {
  local payload="$1" text="$2" rc="${3:-0}"
  if [[ "$JSON_OUT" -eq 1 ]]; then
    printf '%s\n' "$payload"
  else
    printf '%s\n' "$text"
  fi
  return "$rc"
}

append_validated() {
  local path="$1" row="$2"
  if [[ ! -r "$JSONL_APPEND_LIB" ]]; then
    echo "ERR: JSONL append primitive missing: $JSONL_APPEND_LIB" >&2
    return 3
  fi
  # shellcheck source=/dev/null
  source "$JSONL_APPEND_LIB"
  fw_jsonl_append_validated "$path" "$row"
}

read_json_file_or_empty() {
  local path="$1"
  if [[ -n "$path" && -s "$path" ]]; then
    jq -c '.' "$path" 2>/dev/null || printf '{}\n'
  else
    printf '{}\n'
  fi
}

robot_activity_json() {
  if [[ -n "$ROBOT_ACTIVITY_FILE" ]]; then
    read_json_file_or_empty "$ROBOT_ACTIVITY_FILE"
    return 0
  fi
  if [[ -x "$NTM_BIN" ]]; then
    "$NTM_BIN" --robot-activity="$SESSION" --activity-type=codex,claude 2>/dev/null || printf '{}\n'
    return 0
  fi
  printf '{}\n'
}

ready_queue_json() {
  if [[ -n "$READY_FILE" ]]; then
    read_json_file_or_empty "$READY_FILE"
    return 0
  fi
  if command -v "$BR_BIN" >/dev/null 2>&1; then
    "$BR_BIN" ready --json 2>/dev/null || printf '{"issues":[]}\n'
    return 0
  fi
  printf '{"issues":[]}\n'
}

activity_counts_json() {
  local payload="$1"
  jq -nc --argjson payload "$payload" '
    def rows:
      [ $payload.agents[]?, $payload.panes[]?, $payload.workers[]?, $payload.rows[]?
        | select(type == "object") ];
    ([($payload.summary.by_state.WAITING? // empty), ($payload.by_state.WAITING? // empty)]
      | map(tonumber? // empty) | max) as $summary_waiting
    | (rows | map(select(((.state // .robot_state // .activity_state // "") | tostring | ascii_upcase) == "WAITING")) | length) as $row_waiting
    | {idle_panes:($summary_waiting // $row_waiting), worker_rows:(rows | length)}
  '
}

ready_counts_json() {
  local payload="$1"
  jq -nc --argjson payload "$payload" '
    def items:
      if ($payload | type) == "array" then $payload
      elif ($payload | type) == "object" then ($payload.issues // $payload.items // $payload.beads // $payload.rows // [])
      else [] end;
    (items
      | map(select(((.status // "open") | tostring | ascii_downcase) == "open"))
      | map({priority:((.priority // .prio // 999) | tonumber? // 999)})) as $ready
    | {
        ready_p0_count:($ready | map(select(.priority <= 0)) | length),
        ready_p1_count:($ready | map(select(.priority == 1)) | length),
        ready_priority_le_1_count:($ready | map(select(.priority <= 1)) | length)
      }
  '
}

dispatch_rows_json() {
  local tick="$1"
  if [[ ! -s "$DISPATCH_LOG" ]]; then
    printf '[]\n'
    return 0
  fi
  jq -R -s -c --arg tick "$tick" --argjson tail "$TAIL_LINES" '
    split("\n")
    | map(select(length > 0) | try fromjson catch empty | select(type == "object")) as $rows
    | ($rows | map(select(((.tick_id // .tick // .task_id // "") | tostring) == $tick))) as $tick_rows
    | if ($tick_rows | length) > 0 then $tick_rows else ($rows | .[-$tail:]) end
  ' "$DISPATCH_LOG" 2>/dev/null || printf '[]\n'
}

dispatch_signal_json() {
  local rows="$1"
  jq -nc --argjson rows "$rows" '
    def s:
      if . == null then ""
      elif type == "string" then .
      else tojson end;
    def text($r):
      [$r.message, $r.body, $r.body_md, $r.callback_text, $r.reason, $r.question, $r.raw, $r.ntm_send_output, $r.result]
      | map(s)
      | join(" ");
    ($rows | map(select(
      (((.event // "") | tostring | test("dispatch"; "i"))
       or ((.action // "") | tostring | test("dispatch"; "i"))
       or ((.delivery_receipt.transport_accepted // false) == true)
       or ((.result.delivery_receipt.transport_accepted // false) == true))
      and (((.event // "") | tostring | test("no_bead"; "i")) | not)
    )) | length) as $dispatched
    | ($rows | map(select(
      (((.no_bead_reason // "") | tostring | length) > 0)
      or (((.event // "") | tostring | test("no[-_]?bead"; "i")))
    )) | length) as $no_bead
    | ($rows | map(select(
      ((.true_joshua_blocker // false) == true)
      or ((.joshua_blocker // false) == true)
      or (((.blocker_class // .chain_blocked_reason // .idle_reason_class // "") | tostring) | test("true[-_ ]?josh|joshua[-_ ]?blocker|hard[-_ ]?blocker"; "i"))
    )) | length) as $blockers
    | ($rows | map(select(text(.) | test("want me to dispatch|do you want me to dispatch|should i dispatch"; "i")))) as $want
    | ($rows | map(select(text(.) | test("ask joshua|asked joshua|should i ask|idle question|\\?$"; "i")))) as $ask
    | ($rows | map(select(
      ((((.event // "") | tostring | test("callback|DONE|BLOCKED"; "i")) or (text(.) | test("\\b(DONE|BLOCKED)\\b|callback received"; "i")))
       and ((.chain_dispatch // .same_tick_chain_attempted // .chained // false) != true))
    ))) as $callback_without_chain
    | {
        dispatched:$dispatched,
        no_bead_receipts:$no_bead,
        true_joshua_blockers:$blockers,
        orch_turn_signal:(if ($want | length) > 0 then "want_me_to_dispatch" elif ($ask | length) > 0 then "asked_joshua" else "no_signal" end),
        signal_detail:(if ($want | length) > 0 then "want_me_to_dispatch" elif ($ask | length) > 0 then "asked_joshua" elif ($callback_without_chain | length) > 0 then "callback_without_chain_dispatch" else "none" end),
        punt_signal_present:((($want | length) + ($ask | length) + ($callback_without_chain | length)) > 0)
      }
  '
}

classification_json() {
  local tick="$1" ts robot ready rows activity ready_counts signal
  ts="$(now_iso)"
  robot="$(robot_activity_json)"
  ready="$(ready_queue_json)"
  rows="$(dispatch_rows_json "$tick")"
  activity="$(activity_counts_json "$robot")"
  ready_counts="$(ready_counts_json "$ready")"
  signal="$(dispatch_signal_json "$rows")"
  jq -nc \
    --arg schema_version "$SCHEMA_VERSION" \
    --arg version "$VERSION" \
    --arg ts "$ts" \
    --arg tick_id "$tick" \
    --arg session "$SESSION" \
    --arg repo "$REPO_ROOT" \
    --arg ledger_path "$LEDGER" \
    --arg dispatch_log "$DISPATCH_LOG" \
    --argjson dry_run "$(json_bool "$DRY_RUN")" \
    --argjson apply "$(json_bool "$APPLY")" \
    --argjson activity "$activity" \
    --argjson ready "$ready_counts" \
    --argjson signal "$signal" '
      ($activity.idle_panes // 0) as $idle
      | (($ready.ready_p0_count // 0) + ($ready.ready_p1_count // 0)) as $ready_le_1
      | ($signal.dispatched // 0) as $dispatched
      | ($signal.no_bead_receipts // 0) as $no_bead
      | ($signal.true_joshua_blockers // 0) as $blockers
      | ($signal.punt_signal_present // false) as $has_signal
      | (($idle >= 1) and ($ready_le_1 >= 1) and ($dispatched == 0) and ($no_bead == 0) and ($blockers == 0) and $has_signal) as $punted
      | {
          schema_version:$schema_version,
          version:$version,
          ts:$ts,
          tick_id:$tick_id,
          session:$session,
          repo:$repo,
          punted:$punted,
          reason:(if $punted then "idle_worker_ready_p0_p1_no_dispatch_no_receipt_with_signal"
            elif $idle < 1 then "no_idle_worker_capacity"
            elif $ready_le_1 < 1 then "no_ready_p0_p1_work"
            elif $dispatched > 0 then "dispatch_recorded"
            elif $no_bead > 0 then "no_bead_receipt_recorded"
            elif $blockers > 0 then "true_joshua_blocker_recorded"
            else "no_punt_signal" end),
          idle_panes:$idle,
          ready_p0_count:($ready.ready_p0_count // 0),
          ready_p1_count:($ready.ready_p1_count // 0),
          dispatched:$dispatched,
          orch_turn_signal:($signal.orch_turn_signal // "no_signal"),
          signal_detail:($signal.signal_detail // "none"),
          dry_run:$dry_run,
          apply:$apply,
          ledger_path:$ledger_path,
          dispatch_log:$dispatch_log
        }
    '
}

run_classify() {
  [[ -n "$TICK_ID" ]] || TICK_ID="manual-$(date -u +%Y%m%dT%H%M%SZ)"
  local row output
  row="$(classification_json "$TICK_ID")"
  if [[ "$APPLY" -eq 1 ]]; then
    append_validated "$LEDGER" "$row"
    output="$(jq -c '. + {ledger_written:true}' <<<"$row")"
  else
    output="$(jq -c '. + {ledger_written:false}' <<<"$row")"
  fi
  emit "$output" "tick_id=$(jq -r '.tick_id' <<<"$output") punted=$(jq -r '.punted' <<<"$output") reason=$(jq -r '.reason' <<<"$output") dry_run=$(jq -r '.dry_run' <<<"$output")" 0
}

ledger_rows_json() {
  if [[ -s "$LEDGER" ]]; then
    jq -s -c 'map(select(type == "object"))' "$LEDGER" 2>/dev/null || printf '[]\n'
  else
    printf '[]\n'
  fi
}

doctor_json() {
  local rows
  rows="$(ledger_rows_json)"
  jq -nc --arg schema_version "$SCHEMA_VERSION.doctor" --arg ledger "$LEDGER" --arg contract_ledger "$CONTRACT_LEDGER" --argjson rows "$rows" '
    def epoch: ((.ts // "") | fromdateiso8601? // 0);
    ($rows | map(select(((.ts // "") | tostring | length) > 0)) | sort_by(.ts) | last | .ts // null) as $last_fired
    |
    ($rows | map(select(epoch >= (now - 86400)))) as $recent
    | ($recent | map(select(.punted == true))) as $punted
    | (($recent | length) as $total | if $total == 0 then 0 else (($punted | length) * 100 / $total | floor) end) as $rate
    | (if ($punted | length) == 0 then "none"
       else ($punted
         | group_by(.orch_turn_signal // "no_signal")
         | map({signal:(.[0].orch_turn_signal // "no_signal"), count:length})
         | sort_by(-.count, .signal)
         | .[0].signal) end) as $top_signal
    | (if (($punted | length) >= 10 or $rate >= 25) then "error"
       elif ($last_fired == null) then "warn"
       elif (($punted | length) >= 3 or $rate >= 10) then "warn"
       else "pass" end) as $status
    | {
        schema_version:$schema_version,
        status:$status,
        ledger_path:$ledger,
        contract_ledger_path:$contract_ledger,
        l70_counter_last_fired_ts:$last_fired,
        l70_ticks_punted_24h:($punted | length),
        l70_ticks_total_24h:($recent | length),
        l70_ticks_punted_rate_pct:$rate,
        l70_ticks_punted_top_signal:$top_signal,
        thresholds:{count_24h:{warn:3,error:10},rate_pct:{warn:10,error:25}},
        recent_punted:($punted[-10:])
      }
  '
}

run_doctor() {
  local payload rc=0
  payload="$(doctor_json)"
  if [[ "$(jq -r '.status' <<<"$payload")" == "error" ]]; then rc=1; fi
  emit "$payload" "status=$(jq -r '.status' <<<"$payload") l70_ticks_punted_24h=$(jq -r '.l70_ticks_punted_24h' <<<"$payload") rate_pct=$(jq -r '.l70_ticks_punted_rate_pct' <<<"$payload")" "$rc"
}

health_json() {
  local doctor
  doctor="$(doctor_json)"
  jq -c --arg schema_version "$SCHEMA_VERSION.health" '
    {
      schema_version:$schema_version,
      status:(if .status == "error" then "critical" elif .status == "warn" then "degraded" else "green" end),
      l70_ticks_punted_24h,
      l70_ticks_punted_rate_pct,
      l70_ticks_punted_top_signal,
      ledger_path
    }
  ' <<<"$doctor"
}

run_health() {
  local payload rc
  while :; do
    payload="$(health_json)"
    rc=0
    case "$(jq -r '.status' <<<"$payload")" in
      degraded) rc=1 ;;
      critical) rc=3 ;;
    esac
    emit "$payload" "status=$(jq -r '.status' <<<"$payload") l70_ticks_punted_24h=$(jq -r '.l70_ticks_punted_24h' <<<"$payload")" "$rc" || true
    [[ "$WATCH" -eq 1 ]] || return "$rc"
    sleep "$WATCH_INTERVAL"
  done
}

contract_self_row_json() {
  jq -nc --arg ts "$(now_iso)" --arg schema "substrate-loop-contract.v1" '
    {
      primitive_name:"l70-ticks-punted-counter",
      declares_loop:"yes",
      self_repair_action:"counter --apply at tick close",
      measurement_field:"l70_ticks_punted_24h",
      escalation_path:"doctor scope l70-ticks-punted error->fuckup-log:class=l70-punt-rate-exceeded",
      schema_version:$schema,
      bootstrap_seed_v1:"gqoz wires L70 tick-end punt measurement into doctor thresholds",
      ts:$ts
    }
  '
}

contract_self_row_present() {
  [[ -s "$CONTRACT_LEDGER" ]] || return 1
  jq -s -e '
    [ .[]? | select(type == "object" and .primitive_name == "l70-ticks-punted-counter") ] | last
    | type == "object"
      and .declares_loop == "yes"
      and (.self_repair_action // "") == "counter --apply at tick close"
      and (.measurement_field // "") == "l70_ticks_punted_24h"
      and (.escalation_path // "") != ""
      and .schema_version == "substrate-loop-contract.v1"
  ' "$CONTRACT_LEDGER" >/dev/null 2>&1
}

ensure_contract_self_row() {
  if contract_self_row_present; then
    printf 'present\n'
    return 0
  fi
  append_validated "$CONTRACT_LEDGER" "$(contract_self_row_json)"
  printf 'appended\n'
}

run_repair() {
  local planned actual contract_action="not_requested" payload rc=0
  planned="$(jq -nc --arg scope "$REPAIR_SCOPE" --arg ledger "$LEDGER" --arg contract_ledger "$CONTRACT_LEDGER" --argjson explain "$(json_bool "$EXPLAIN")" --arg idempotency_key "$IDEMPOTENCY_KEY" '{scope:$scope,would_write:[($ledger|split("/")[:-1]|join("/")),$contract_ledger],would_delete:[],would_call_external:[],blocked_by:[],explain:$explain,idempotency_key:(if $idempotency_key == "" then null else $idempotency_key end)}')"
  actual='[]'
  case "$REPAIR_SCOPE" in
    ledger|substrate-contract|all) ;;
    *) echo "ERR: unsupported repair scope: $REPAIR_SCOPE" >&2; return 2 ;;
  esac
  if [[ "$APPLY" -eq 1 ]]; then
    mkdir -p "$(dirname "$LEDGER")" "$(dirname "$CONTRACT_LEDGER")"
    actual="$(jq -nc --arg path "$(dirname "$LEDGER")" '[{action:"ensure_dir",path:$path,status:"applied"}]')"
    if [[ "$REPAIR_SCOPE" == "substrate-contract" || "$REPAIR_SCOPE" == "all" ]]; then
      contract_action="$(ensure_contract_self_row)"
    fi
  fi
  payload="$(jq -nc \
    --arg schema_version "$SCHEMA_VERSION.repair" \
    --arg scope "$REPAIR_SCOPE" \
    --argjson dry_run "$(json_bool "$DRY_RUN")" \
    --argjson apply "$(json_bool "$APPLY")" \
    --argjson planned "$planned" \
    --argjson actual "$actual" \
    --arg contract_action "$contract_action" \
    '{schema_version:$schema_version,scope:$scope,status:"pass",dry_run:$dry_run,apply:$apply,planned_actions:[$planned],actual_actions:$actual,contract_self_row_action:$contract_action}')"
  emit "$payload" "repair scope=$REPAIR_SCOPE apply=$APPLY contract_self_row_action=$contract_action" "$rc"
}

validate_ledger_json() {
  local rows
  rows="$(ledger_rows_json)"
  jq -nc --arg schema_version "$SCHEMA_VERSION.validate" --arg target "$VALIDATE_TARGET" --argjson rows "$rows" '
    ($rows | map(select(
      (.tick_id // "") == ""
      or (.punted | type) != "boolean"
      or (.idle_panes | type) != "number"
      or (.ready_p0_count | type) != "number"
      or (.ready_p1_count | type) != "number"
      or (.dispatched | type) != "number"
      or ((.orch_turn_signal // "") | IN("want_me_to_dispatch","asked_joshua","no_signal") | not)
    ))) as $bad
    | {schema_version:$schema_version,target:$target,status:(if ($bad | length) == 0 then "pass" else "fail" end),rows_checked:($rows | length),invalid_rows:($bad | length)}
  '
}

run_validate() {
  local payload rc=0
  [[ "$VALIDATE_TARGET" == "ledger" ]] || { echo "ERR: unsupported validate target: $VALIDATE_TARGET" >&2; return 2; }
  payload="$(validate_ledger_json)"
  [[ "$(jq -r '.status' <<<"$payload")" == "pass" ]] || rc=1
  emit "$payload" "validate target=$VALIDATE_TARGET status=$(jq -r '.status' <<<"$payload") rows_checked=$(jq -r '.rows_checked' <<<"$payload")" "$rc"
}

run_audit() {
  local rows contract_present
  rows="$(ledger_rows_json)"
  if contract_self_row_present; then contract_present=true; else contract_present=false; fi
  jq -nc --arg schema_version "$SCHEMA_VERSION.audit" --arg ledger "$LEDGER" --argjson rows "$rows" --argjson contract_present "$contract_present" \
    '{schema_version:$schema_version,ledger_path:$ledger,rows_total:($rows|length),recent_rows:($rows[-10:]),contract_self_row_present:$contract_present}' |
    while IFS= read -r payload; do
      emit "$payload" "audit rows_total=$(jq -r '.rows_total' <<<"$payload") contract_self_row_present=$(jq -r '.contract_self_row_present' <<<"$payload")" 0
    done
}

run_why() {
  [[ -n "$WHY_ID" ]] || { echo "ERR: why requires ID" >&2; return 2; }
  local rows
  rows="$(ledger_rows_json)"
  jq -nc --arg schema_version "$SCHEMA_VERSION.why" --arg id "$WHY_ID" --argjson rows "$rows" '
    {schema_version:$schema_version,id:$id,match:($rows | map(select((.tick_id // "") == $id)) | last // null)}
  ' | while IFS= read -r payload; do
    emit "$payload" "why id=$WHY_ID match=$(jq -r '.match != null' <<<"$payload")" 0
  done
}

run_schema() {
  case "$SCHEMA_TOPIC" in
    classification)
      jq -nc --arg schema_version "$SCHEMA_VERSION" '{schema_version:$schema_version,required:["ts","tick_id","punted","reason","idle_panes","ready_p0_count","ready_p1_count","dispatched","orch_turn_signal"]}' ;;
    doctor)
      jq -nc --arg schema_version "$SCHEMA_VERSION.doctor" '{schema_version:$schema_version,required:["l70_counter_last_fired_ts","l70_ticks_punted_24h","l70_ticks_punted_rate_pct","l70_ticks_punted_top_signal"]}' ;;
    ledger)
      jq -nc --arg schema_version "$SCHEMA_VERSION.ledger" '{schema_version:$schema_version,append:"fw_jsonl_append_validated",path_env:"L70_TICKS_PUNTED_LEDGER"}' ;;
    contract)
      contract_self_row_json ;;
    *)
      echo "ERR: unknown schema topic: $SCHEMA_TOPIC" >&2
      return 2 ;;
  esac
}

backfill_json() {
  if [[ ! -s "$DISPATCH_LOG" ]]; then
    jq -nc --arg schema_version "$SCHEMA_VERSION.backfill" --arg log "$DISPATCH_LOG" '{schema_version:$schema_version,dispatch_log:$log,baseline_24h_punt_count:0,rows_checked:0,backfill_rows:[]}'
    return 0
  fi
  jq -R -s -c --arg schema_version "$SCHEMA_VERSION.backfill" --arg row_schema "$SCHEMA_VERSION" --arg version "$VERSION" --arg log "$DISPATCH_LOG" --arg repo "$REPO_ROOT" --arg ledger "$LEDGER" --arg session "$SESSION" '
    def s:
      if . == null then ""
      elif type == "string" then .
      else tojson end;
    def text($r):
      [$r.message, $r.body, $r.body_md, $r.callback_text, $r.reason, $r.question, $r.raw, $r.ntm_send_output, $r.result]
      | map(s)
      | join(" ");
    split("\n")
    | map(select(length > 0) | try fromjson catch empty | select(type == "object")) as $rows
    | ($rows | map(select(((.ts // "") | fromdateiso8601? // 0) >= (now - 86400)))) as $recent
    | ($recent | map(select(
      ((((.event // "") == "l70_chain_decision") and ((.chain_required // false) == true) and ((.chained // false) != true) and (((.chain_blocked_reason // "") | tostring | length) == 0))
      or (text(.) | test("want me to dispatch|do you want me to dispatch|should i dispatch"; "i")))
    ))) as $punted
    | ($punted | to_entries | map(.value as $r | {
        schema_version:$row_schema,
        version:$version,
        ts:($r.ts // $r.callback_received_at // (now | todateiso8601)),
        tick_id:("backfill-" + (($r.task_id // $r.tick_id // $r.ts // (.key|tostring)) | tostring | gsub("[^A-Za-z0-9_.:-]";"_"))),
        session:$session,
        repo:$repo,
        punted:true,
        reason:"backfill_tick_end_idle_workers_signature",
        idle_panes:(($r.idle_panes // 1) | tonumber? // 1),
        ready_p0_count:(($r.ready_p0_count // 0) | tonumber? // 0),
        ready_p1_count:(($r.ready_p1_count // 1) | tonumber? // 1),
        dispatched:0,
        orch_turn_signal:"want_me_to_dispatch",
        signal_detail:"backfill_dispatch_log_signature",
        dry_run:false,
        apply:true,
        ledger_path:$ledger,
        dispatch_log:$log,
        backfill:true
      })) as $backfill_rows
    | {schema_version:$schema_version,dispatch_log:$log,baseline_24h_punt_count:($punted | length),rows_checked:($recent | length),examples:($punted[-5:]),backfill_rows:$backfill_rows}
  ' "$DISPATCH_LOG" 2>/dev/null || jq -nc --arg schema_version "$SCHEMA_VERSION.backfill" --arg log "$DISPATCH_LOG" '{schema_version:$schema_version,dispatch_log:$log,baseline_24h_punt_count:0,rows_checked:0,backfill_rows:[],error:"parse_failed"}'
}

run_backfill() {
  local payload row written=0
  payload="$(backfill_json)"
  if [[ "$APPLY" -eq 1 ]]; then
    while IFS= read -r row; do
      [[ -n "$row" ]] || continue
      append_validated "$LEDGER" "$row"
      written=$((written + 1))
    done < <(jq -c '.backfill_rows[]?' <<<"$payload")
    payload="$(jq -c --argjson written "$written" '. + {ledger_rows_written:$written}' <<<"$payload")"
  fi
  emit "$payload" "baseline_24h_punt_count=$(jq -r '.baseline_24h_punt_count' <<<"$payload") rows_checked=$(jq -r '.rows_checked' <<<"$payload")" 0
}

info_json() {
  jq -nc --arg version "$VERSION" --arg schema_version "$SCHEMA_VERSION" --arg repo "$REPO_ROOT" --arg ledger "$LEDGER" --arg dispatch_log "$DISPATCH_LOG" --arg ntm "$NTM_BIN" --arg br "$BR_BIN" --arg jsonl_append_lib "$JSONL_APPEND_LIB" \
    '{name:"l70-ticks-punted-counter.sh",version:$version,schema_version:$schema_version,repo:$repo,ledger:$ledger,dispatch_log:$dispatch_log,ntm_bin:$ntm,br_bin:$br,jsonl_append_lib:$jsonl_append_lib,exit_codes:{"0":"pass/no threshold error","1":"doctor threshold error or validation failure","2":"usage error","3":"append primitive missing or failed"}}'
}

examples_json() {
  jq -nc '{
    examples:[
      "l70-ticks-punted-counter.sh --tick-id tick-20260505T0400Z --json",
      "l70-ticks-punted-counter.sh --tick-id tick-20260505T0400Z --apply --json",
      "l70-ticks-punted-counter.sh --doctor --json",
      "l70-ticks-punted-counter.sh repair --scope substrate-contract --apply --json",
      "l70-ticks-punted-counter.sh backfill --json"
    ]
  }'
}

quickstart_json() {
  jq -nc '{
    steps:[
      "Run --tick-id ID --json at tick close to preview classification.",
      "Add --apply only from the tick-close hook to append the JSONL ledger row.",
      "Run --doctor --json or flywheel-loop doctor --scope l70-ticks-punted --json for thresholds.",
      "Run repair --scope substrate-contract --apply --json once to emit the substrate-loop contract self-row."
    ]
  }'
}

help_topic() {
  case "$HELP_TOPIC" in
    doctor) printf 'doctor: reads the l70 tick ledger and emits count/rate/top-signal thresholds.\n' ;;
    repair) printf 'repair: default dry-run; --apply can ensure dirs and emit the substrate-contract self-row.\n' ;;
    classify|"") printf 'classify: combines ntm robot activity, br ready, and dispatch-log tail to classify one tick.\n' ;;
    *) printf 'unknown topic: %s\n' "$HELP_TOPIC"; return 2 ;;
  esac
}

completion() {
  case "$COMPLETION_SHELL" in
    bash)
      cat <<'EOF'
_l70_ticks_punted_counter_completion() {
  local cur="${COMP_WORDS[COMP_CWORD]}"
  COMPREPLY=( $(compgen -W "--tick-id --session --doctor health repair validate audit why schema backfill --dry-run --apply --json --info --examples quickstart help completion --scope --watch --interval --robot-activity-file --ready-file --dispatch-log" -- "$cur") )
}
complete -F _l70_ticks_punted_counter_completion l70-ticks-punted-counter.sh
EOF
      ;;
    zsh)
      printf 'compadd -- --tick-id --session --doctor health repair validate audit why schema backfill --dry-run --apply --json --info --examples quickstart help completion --scope --watch --interval --robot-activity-file --ready-file --dispatch-log\n'
      ;;
    *)
      echo "ERR: completion shell must be bash or zsh" >&2
      return 2 ;;
  esac
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --tick-id) TICK_ID="${2:?}"; MODE="classify"; shift 2 ;;
    --tick-id=*) TICK_ID="${1#*=}"; MODE="classify"; shift ;;
    --session) SESSION="${2:?}"; shift 2 ;;
    --session=*) SESSION="${1#*=}"; shift ;;
    --doctor|doctor) MODE="doctor"; shift ;;
    health) MODE="health"; shift ;;
    repair|--repair) MODE="repair"; shift ;;
    validate) MODE="validate"; VALIDATE_TARGET="${2:-ledger}"; shift $(( $# > 1 ? 2 : 1 )) ;;
    audit) MODE="audit"; shift ;;
    why) MODE="why"; WHY_ID="${2:-}"; shift $(( $# > 1 ? 2 : 1 )) ;;
    schema) MODE="schema"; SCHEMA_TOPIC="${2:-classification}"; shift $(( $# > 1 ? 2 : 1 )) ;;
    backfill|--backfill) MODE="backfill"; shift ;;
    --apply) APPLY=1; DRY_RUN=0; shift ;;
    --dry-run) APPLY=0; DRY_RUN=1; shift ;;
    --json) JSON_OUT=1; shift ;;
    --watch) WATCH=1; shift ;;
    --interval) WATCH_INTERVAL="${2:?}"; shift 2 ;;
    --interval=*) WATCH_INTERVAL="${1#*=}"; shift ;;
    --scope) REPAIR_SCOPE="${2:?}"; shift 2 ;;
    --scope=*) REPAIR_SCOPE="${1#*=}"; shift ;;
    --robot-activity-file) ROBOT_ACTIVITY_FILE="${2:?}"; shift 2 ;;
    --robot-activity-file=*) ROBOT_ACTIVITY_FILE="${1#*=}"; shift ;;
    --ready-file) READY_FILE="${2:?}"; shift 2 ;;
    --ready-file=*) READY_FILE="${1#*=}"; shift ;;
    --dispatch-log) DISPATCH_LOG="${2:?}"; shift 2 ;;
    --dispatch-log=*) DISPATCH_LOG="${1#*=}"; shift ;;
    --repo) REPO_ROOT="${2:?}"; shift 2 ;;
    --repo=*) REPO_ROOT="${1#*=}"; shift ;;
    --ledger) LEDGER="${2:?}"; shift 2 ;;
    --ledger=*) LEDGER="${1#*=}"; shift ;;
    --contract-ledger) CONTRACT_LEDGER="${2:?}"; shift 2 ;;
    --contract-ledger=*) CONTRACT_LEDGER="${1#*=}"; shift ;;
    --width) WIDTH="${2:?}"; shift 2 ;;
    --width=*) WIDTH="${1#*=}"; shift ;;
    --no-color|--no-emoji) shift ;;
    --explain) EXPLAIN=1; shift ;;
    --idempotency-key) IDEMPOTENCY_KEY="${2:?}"; shift 2 ;;
    --idempotency-key=*) IDEMPOTENCY_KEY="${1#*=}"; shift ;;
    --info) MODE="info"; shift ;;
    --examples|examples) MODE="examples"; shift ;;
    quickstart) MODE="quickstart"; shift ;;
    help) MODE="help"; HELP_TOPIC="${2:-classify}"; shift $(( $# > 1 ? 2 : 1 )) ;;
    completion)
      if [[ "${2:-}" == "--help" || "${2:-}" == "-h" || -z "${2:-}" ]]; then
        usage
        exit 0
      fi
      MODE="completion"; COMPLETION_SHELL="${2:-}"; shift 2 ;;
    -h|--help) usage; exit 0 ;;
    *) echo "ERR: unknown argument: $1" >&2; usage >&2; exit 2 ;;
  esac
done

case "$MODE" in
  classify) run_classify ;;
  doctor) run_doctor ;;
  health) run_health ;;
  repair) run_repair ;;
  validate) run_validate ;;
  audit) run_audit ;;
  why) run_why ;;
  schema) run_schema ;;
  backfill) run_backfill ;;
  info) info_json ;;
  examples) examples_json ;;
  quickstart) quickstart_json ;;
  help) help_topic ;;
  completion) completion ;;
  *) echo "ERR: unsupported mode: $MODE" >&2; exit 2 ;;
esac
