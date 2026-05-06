#!/usr/bin/env bash
set -euo pipefail

VERSION="peer-orch-recovery-permit.v1.0.0"
SCHEMA_VERSION="peer-orch-recovery-permit"
CONTRACT_SCHEMA_VERSION="substrate-loop-contract.v1"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd -P)"
LEDGER="${PEER_ORCH_RECOVERY_LEDGER:-$HOME/.local/state/flywheel/peer-orch-recovery.jsonl}"
CONTRACT_LEDGER="${PEER_ORCH_RECOVERY_CONTRACT_LEDGER:-$HOME/.local/state/flywheel/substrate-loop-contract.jsonl}"
TOPOLOGY="${PEER_ORCH_RECOVERY_TOPOLOGY:-${FLYWHEEL_SESSION_TOPOLOGY:-$HOME/.local/state/flywheel/session-topology.jsonl}}"
JSONL_APPEND_LIB="${PEER_ORCH_RECOVERY_JSONL_APPEND_LIB:-${FLYWHEEL_JSONL_APPEND_LIB:-$HOME/.local/share/flywheel-watchers/lib/jsonl-append.sh}}"
KILL_RECOVER_DRILL="${PEER_ORCH_RECOVERY_KILL_RECOVER_DRILL:-$HOME/.claude/skills/.flywheel/scripts/kill-recover-drill.sh}"
NTM_BIN="${PEER_ORCH_RECOVERY_NTM_BIN:-ntm}"

MODE="decide"
JSON_OUT=0
APPLY=0
DRY_RUN=1
WATCH=0
WATCH_INTERVAL=30
REPAIR_SCOPE="substrate-contract"
VALIDATE_TARGET="ledger"
SCHEMA_TOPIC="decision"
HELP_TOPIC="overview"
WHY_ID=""
COMPLETION_SHELL=""
TARGET_SESSION=""
TARGET_PANE=""
ACTOR_SESSION="${PEER_ORCH_RECOVERY_ACTOR_SESSION:-flywheel}"
ACTOR_PANE="${PEER_ORCH_RECOVERY_ACTOR_PANE:-1}"
REASON="${PEER_ORCH_RECOVERY_REASON:-manual peer-orch recovery permit check}"
HASH_WINDOW_SEC="${PEER_ORCH_RECOVERY_HASH_WINDOW_SEC:-6}"
SAMPLE_LINES="${PEER_ORCH_RECOVERY_SAMPLE_LINES:-200}"

usage() {
  cat <<'EOF'
usage:
  peer-orch-respawn-permit.sh --target-session NAME --target-pane N [--dry-run|--apply] [--json]
  peer-orch-respawn-permit.sh --doctor [--json]
  peer-orch-respawn-permit.sh health [--watch] [-i N] [--json]
  peer-orch-respawn-permit.sh repair --scope ledger|substrate-contract|all [--dry-run|--apply] [--json]
  peer-orch-respawn-permit.sh validate ledger [--json]
  peer-orch-respawn-permit.sh audit [--json]
  peer-orch-respawn-permit.sh why ID [--json]
  peer-orch-respawn-permit.sh schema decision|doctor|ledger|contract [--json]
  peer-orch-respawn-permit.sh --info|--examples|quickstart|help TOPIC|completion bash|zsh

Exit codes: 0=permit/pass, 1=domain failure, 2=usage, 3=transient, 4=blocked by gate.
EOF
}

now_iso() {
  printf '%s\n' "${PEER_ORCH_RECOVERY_NOW:-$(date -u +%Y-%m-%dT%H:%M:%SZ)}"
}

json_bool() {
  if [[ "$1" == "1" ]]; then printf true; else printf false; fi
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
  [[ -r "$JSONL_APPEND_LIB" ]] || { echo "ERR: JSONL append primitive missing: $JSONL_APPEND_LIB" >&2; return 3; }
  # shellcheck source=/dev/null
  source "$JSONL_APPEND_LIB"
  fw_jsonl_append_validated "$path" "$row"
}

rows_json() {
  if [[ -s "$LEDGER" ]]; then
    jq -s -c 'map(select(type == "object"))' "$LEDGER" 2>/dev/null || printf '[]\n'
  else
    printf '[]\n'
  fi
}

contract_rows_json() {
  if [[ -s "$CONTRACT_LEDGER" ]]; then
    jq -s -c 'map(select(type == "object"))' "$CONTRACT_LEDGER" 2>/dev/null || printf '[]\n'
  else
    printf '[]\n'
  fi
}

latest_topology_row() {
  local session="$1"
  [[ -s "$TOPOLOGY" ]] || { printf '{}\n'; return 0; }
  jq -s -c --arg session "$session" \
    'map(select(type == "object" and .session == $session)) | sort_by(.effective_at // "") | last // {}' \
    "$TOPOLOGY" 2>/dev/null || printf '{}\n'
}

protected_sessions_json() {
  local raw
  raw="$(sed -n 's/^PROTECTED_SESSIONS=(\(.*\))$/\1/p' "$KILL_RECOVER_DRILL" 2>/dev/null | head -1 || true)"
  if [[ -z "$raw" ]]; then
    jq -nc '["alpsinsurance","picoz","skillos"]'
    return 0
  fi
  PROTECTED_RAW="$raw" python3 - <<'PY'
import json, os, shlex
print(json.dumps([p for p in shlex.split(os.environ["PROTECTED_RAW"]) if p]))
PY
}

is_protected_session() {
  local session="$1"
  protected_sessions_json | jq -e --arg session "$session" 'index($session) != null' >/dev/null
}

sample_buffer() {
  local index="$1" file_var text_var
  file_var="PEER_ORCH_RECOVERY_SAMPLE${index}_FILE"
  text_var="PEER_ORCH_RECOVERY_SAMPLE${index}_TEXT"
  if [[ -n "${!file_var:-}" ]]; then
    cat "${!file_var}"
    return 0
  fi
  if [[ -n "${!text_var:-}" ]]; then
    printf '%s\n' "${!text_var}"
    return 0
  fi
  if command -v "$NTM_BIN" >/dev/null 2>&1; then
    "$NTM_BIN" copy "${TARGET_SESSION}:${TARGET_PANE}" -l "$SAMPLE_LINES" 2>/dev/null || true
  fi
}

activity_state() {
  local activity
  if [[ -n "${PEER_ORCH_RECOVERY_ACTIVITY_FILE:-}" && -s "$PEER_ORCH_RECOVERY_ACTIVITY_FILE" ]]; then
    activity="$(cat "$PEER_ORCH_RECOVERY_ACTIVITY_FILE")"
  elif [[ -n "${PEER_ORCH_RECOVERY_ACTIVITY_JSON:-}" ]]; then
    activity="$PEER_ORCH_RECOVERY_ACTIVITY_JSON"
  elif command -v "$NTM_BIN" >/dev/null 2>&1; then
    activity="$("$NTM_BIN" activity "$TARGET_SESSION" --json 2>/dev/null || true)"
  else
    activity=""
  fi
  [[ -n "$activity" ]] || { printf '\n'; return 0; }
  jq -r --argjson pane "$TARGET_PANE" '
    first(
      .agents[]? | select((.pane_idx // .pane // .index) == $pane) | (.state // .status // .activity_state // "")
    ) // (.state // .status // "")
  ' <<<"$activity" 2>/dev/null || printf '\n'
}

freeze_evidence_json() {
  local state upper sample1 sample2 hash1 hash2 confirmed=false reason="no_freeze_evidence"
  state="$(activity_state)"
  upper="$(tr '[:lower:]' '[:upper:]' <<<"$state")"
  case "$upper" in
    ERROR|UNKNOWN|DEAF)
      jq -nc --arg state "$state" '{freeze_confirmed:true,method:"robot_activity_state",state:$state,hash_diff_window_sec:0,reason:"state_allows_recovery"}'
      return 0
      ;;
  esac
  sample1="$(sample_buffer 1)"
  if [[ "$HASH_WINDOW_SEC" != "0" ]]; then
    sleep "$HASH_WINDOW_SEC"
  fi
  sample2="$(sample_buffer 2)"
  hash1="$(printf '%s' "$sample1" | shasum -a 256 | awk '{print $1}')"
  hash2="$(printf '%s' "$sample2" | shasum -a 256 | awk '{print $1}')"
  if [[ -n "$sample1" && "$hash1" == "$hash2" ]]; then
    confirmed=true
    reason="hash_identical"
  fi
  jq -nc \
    --argjson freeze_confirmed "$confirmed" \
    --arg reason "$reason" \
    --arg hash1 "$hash1" \
    --arg hash2 "$hash2" \
    --argjson window "$HASH_WINDOW_SEC" \
    '{freeze_confirmed:$freeze_confirmed,method:"hash_diff",hash_diff_window_sec:$window,hash1:$hash1,hash2:$hash2,reason:$reason}'
}

decision_payload() {
  local ts actor_row flywheel_row target_row flywheel_orch target_orch target_human target_callback decision decision_reason freeze_json freeze_confirmed success=false rc=0 protected=false
  ts="$(now_iso)"
  actor_row="$(latest_topology_row "$ACTOR_SESSION")"
  flywheel_row="$(latest_topology_row "flywheel")"
  target_row="$(latest_topology_row "$TARGET_SESSION")"
  flywheel_orch="$(jq -r '.orchestrator_pane // 1' <<<"$flywheel_row")"
  target_orch="$(jq -r '.orchestrator_pane // empty' <<<"$target_row")"
  target_human="$(jq -r '.human_pane // empty' <<<"$target_row")"
  target_callback="$(jq -r '.callback_pane // empty' <<<"$target_row")"
  freeze_json='{"freeze_confirmed":false,"method":"not_checked","hash_diff_window_sec":0,"reason":"not_checked"}'

  if [[ -z "$TARGET_SESSION" || -z "$TARGET_PANE" ]]; then
    echo "ERR: --target-session and --target-pane are required" >&2
    return 2
  fi
  if [[ "$(jq -r 'type' <<<"$target_row")" != "object" || "$target_row" == "{}" ]]; then
    decision="refuse"; decision_reason="target_topology_missing"; rc=4
  elif [[ "$ACTOR_SESSION" != "flywheel" || "$ACTOR_PANE" != "$flywheel_orch" ]]; then
    decision="refuse"; decision_reason="actor_not_flywheel_orchestrator"; rc=4
  elif [[ "$TARGET_SESSION" == "flywheel" && "$TARGET_PANE" == "$target_orch" ]]; then
    decision="refuse"; decision_reason="self_orch_respawn_refused"; rc=4
  elif [[ -n "$target_human" && "$TARGET_PANE" == "$target_human" ]]; then
    decision="refuse"; decision_reason="human_pane_refused"; rc=4
  elif [[ -n "$target_callback" && "$TARGET_PANE" == "$target_callback" && "$target_callback" != "$target_orch" ]]; then
    decision="refuse"; decision_reason="callback_pane_refused"; rc=4
  elif is_protected_session "$TARGET_SESSION" && [[ "$TARGET_SESSION" != "skillos" ]]; then
    protected=true
    decision="refuse"; decision_reason="protected_session_refused"; rc=4
  elif [[ "$TARGET_PANE" != "$target_orch" ]]; then
    decision="defer"; decision_reason="target_is_not_orchestrator_pane_use_worker_respawn_path"; rc=4
  else
    freeze_json="$(freeze_evidence_json)"
    freeze_confirmed="$(jq -r '.freeze_confirmed' <<<"$freeze_json")"
    if [[ "$freeze_confirmed" == "true" ]]; then
      decision="permit"; decision_reason="peer_orch_freeze_confirmed"; success=true; rc=0
    else
      decision="refuse"; decision_reason="no_freeze_evidence"; rc=4
    fi
  fi

  jq -nc \
    --arg schema_version "$SCHEMA_VERSION.decision.v1" \
    --arg version "$VERSION" \
    --arg ts "$ts" \
    --arg actor_session "$ACTOR_SESSION" \
    --argjson actor_pane "$ACTOR_PANE" \
    --arg target_session "$TARGET_SESSION" \
    --argjson target_pane "$TARGET_PANE" \
    --arg decision "$decision" \
    --arg decision_reason "$decision_reason" \
    --arg reason "$REASON" \
    --argjson dry_run "$(json_bool "$DRY_RUN")" \
    --argjson apply "$(json_bool "$APPLY")" \
    --argjson success "$success" \
    --argjson protected "$protected" \
    --argjson target_topology "$target_row" \
    --argjson freeze "$freeze_json" \
    '{schema_version:$schema_version,version:$version,ts:$ts,actor_session:$actor_session,actor_pane:$actor_pane,target_session:$target_session,target_pane:$target_pane,decision:$decision,decision_reason:$decision_reason,reason:$reason,dry_run:$dry_run,apply:$apply,success:$success,protected_session:$protected,target_topology:$target_topology,freeze_confirmed:($freeze.freeze_confirmed // false),hash_diff_window_sec:($freeze.hash_diff_window_sec // 0),freeze_evidence:$freeze,ledger_path:null}' >"${TMPDIR:-/tmp}/peer-orch-permit-payload.$$"
  cat "${TMPDIR:-/tmp}/peer-orch-permit-payload.$$"
  rm -f "${TMPDIR:-/tmp}/peer-orch-permit-payload.$$"
  return "$rc"
}

ledger_row_for_payload() {
  jq -c '{
    schema_version:"peer-orch-recovery.ledger.v1",
    ts,
    actor_session,
    actor_pane,
    target_session,
    target_pane,
    freeze_confirmed,
    hash_diff_window_sec,
    reason,
    decision,
    decision_reason,
    success
  }' <<<"$1"
}

contract_self_row_json() {
  jq -nc --arg ts "$(now_iso)" --arg schema "$CONTRACT_SCHEMA_VERSION" '{
    primitive_name:"peer-orch-respawn-permit",
    declares_loop:"yes",
    self_repair_action:"peer-orch-respawn-permit.sh repair --scope substrate-contract --apply",
    measurement_field:"peer_orch_recovery_count_24h",
    escalation_path:"doctor scope peer-orch-recovery warn->fuckup-log:class=peer-orch-recovery-spike error->self-respawn-attempt",
    schema_version:$schema,
    bootstrap_seed_v1:"flywheel-3rxt3 L115 peer-orch recovery permit gate",
    ts:$ts
  }'
}

contract_self_row_present() {
  contract_rows_json | jq -e --arg schema "$CONTRACT_SCHEMA_VERSION" '
    [ .[]? | select(type == "object" and .primitive_name == "peer-orch-respawn-permit") ] | last
    | type == "object"
      and .declares_loop == "yes"
      and (.measurement_field // "") == "peer_orch_recovery_count_24h"
      and (.self_repair_action // "") != ""
      and (.escalation_path // "") != ""
      and .schema_version == $schema
  ' >/dev/null
}

ensure_contract_self_row() {
  if contract_self_row_present; then
    printf 'present\n'
    return 0
  fi
  append_validated "$CONTRACT_LEDGER" "$(contract_self_row_json)"
  printf 'appended\n'
}

doctor_json() {
  local rows contract_action
  contract_action="$(ensure_contract_self_row)"
  rows="$(rows_json)"
  jq -nc \
    --arg schema_version "$SCHEMA_VERSION.doctor.v1" \
    --arg version "$VERSION" \
    --arg ts "$(now_iso)" \
    --arg ledger "$LEDGER" \
    --arg contract_ledger "$CONTRACT_LEDGER" \
    --arg contract_action "$contract_action" \
    --argjson rows "$rows" '
    def epoch($x): ($x | fromdateiso8601? // 0);
    (epoch($ts)) as $now
    | ($rows | map(select((epoch(.ts // "") >= ($now - 86400))))) as $recent
    | ($recent | map(select(.decision == "permit")) | length) as $permits
    | ($recent | map(select(.decision_reason == "self_orch_respawn_refused")) | length) as $self_refuses
    | ($recent | map(select(.decision == "permit")) | sort_by(.ts) | last | .ts // null) as $last_permit
    | ($recent | map(select(.decision == "permit")) | group_by(.target_session) | map({session:.[0].target_session,count:length}) | sort_by(-.count, .session)[:5]) as $top
    | {
        schema_version:$schema_version,
        version:$version,
        status:(if $self_refuses > 0 then "fail" elif $permits > 5 then "warn" else "pass" end),
        ts:$ts,
        ledger_path:$ledger,
        substrate_loop_contract_ledger:$contract_ledger,
        substrate_loop_contract_self_row_action:$contract_action,
        peer_orch_recovery_count_24h:$permits,
        last_peer_orch_recovery_ts:$last_permit,
        peer_orch_recovery_targets_top:$top,
        peer_orch_recovery_self_refuse_count_24h:$self_refuses,
        peer_orch_recovery_warn_threshold_24h:5,
        peer_orch_recovery_self_refuse_error_threshold_24h:0
      }'
}

run_decision() {
  local payload rc row
  set +e
  payload="$(decision_payload)"
  rc=$?
  set -e
  if [[ "$APPLY" -eq 1 && "$rc" != "2" ]]; then
    row="$(ledger_row_for_payload "$payload")"
    append_validated "$LEDGER" "$row"
    payload="$(jq -c --arg ledger "$LEDGER" '.ledger_path=$ledger | .ledger_written=true' <<<"$payload")"
  else
    payload="$(jq -c '.ledger_written=false' <<<"$payload")"
  fi
  emit "$payload" "$(jq -r '"decision=\(.decision) reason=\(.decision_reason) target=\(.target_session):\(.target_pane)"' <<<"$payload")" "$rc"
}

run_health() {
  local payload rc
  while :; do
    payload="$(doctor_json | jq -c '.schema_version="peer-orch-recovery-permit.health.v1" | .command="health"')"
    rc=0
    case "$(jq -r '.status' <<<"$payload")" in
      warn) rc=1 ;;
      fail) rc=3 ;;
    esac
    emit "$payload" "$(jq -r '"status=\(.status) peer_orch_recovery_count_24h=\(.peer_orch_recovery_count_24h)"' <<<"$payload")" "$rc" || true
    [[ "$WATCH" -eq 1 ]] || return "$rc"
    sleep "$WATCH_INTERVAL"
  done
}

run_repair() {
  local planned actual contract_action="not_requested"
  case "$REPAIR_SCOPE" in ledger|substrate-contract|all) ;; *) echo "ERR: unsupported repair scope: $REPAIR_SCOPE" >&2; return 2 ;; esac
  planned="$(jq -nc --arg ledger "$LEDGER" --arg contract "$CONTRACT_LEDGER" --arg scope "$REPAIR_SCOPE" '{scope:$scope,would_write:[($ledger|split("/")[:-1]|join("/")),$contract],would_delete:[],would_call_external:[],blocked_by:[]}' )"
  actual='[]'
  if [[ "$APPLY" -eq 1 ]]; then
    mkdir -p "$(dirname "$LEDGER")" "$(dirname "$CONTRACT_LEDGER")"
    actual="$(jq -nc --arg ledger_dir "$(dirname "$LEDGER")" '[{action:"ensure_dir",path:$ledger_dir,status:"applied"}]')"
    if [[ "$REPAIR_SCOPE" == "substrate-contract" || "$REPAIR_SCOPE" == "all" ]]; then
      contract_action="$(ensure_contract_self_row)"
    fi
  fi
  jq -nc --arg schema_version "$SCHEMA_VERSION.repair.v1" --arg scope "$REPAIR_SCOPE" --argjson dry_run "$(json_bool "$DRY_RUN")" --argjson apply "$(json_bool "$APPLY")" --argjson planned "$planned" --argjson actual "$actual" --arg contract_action "$contract_action" \
    '{schema_version:$schema_version,status:"pass",scope:$scope,dry_run:$dry_run,apply:$apply,planned_actions:[$planned],actual_actions:$actual,contract_self_row_action:$contract_action}'
}

validate_json() {
  rows_json | jq -c --arg schema_version "$SCHEMA_VERSION.validate.v1" --arg target "$VALIDATE_TARGET" '
    map(select((.ts // "") == "" or (.decision // "" | IN("permit","refuse","defer") | not) or (.target_session // "") == "")) as $bad
    | {schema_version:$schema_version,status:(if ($bad|length)==0 then "pass" else "fail" end),target:$target,rows_checked:length,invalid_rows:($bad|length)}
  '
}

info_json() {
  jq -nc --arg version "$VERSION" --arg schema "$SCHEMA_VERSION.v1" --arg repo "$REPO_ROOT" --arg ledger "$LEDGER" --arg contract "$CONTRACT_LEDGER" --arg topology "$TOPOLOGY" --arg jsonl "$JSONL_APPEND_LIB" --arg kill "$KILL_RECOVER_DRILL" \
    '{name:"peer-orch-respawn-permit.sh",version:$version,schema_version:$schema,repo:$repo,paths:{ledger:$ledger,contract_ledger:$contract,topology:$topology,jsonl_append_lib:$jsonl,kill_recover_drill:$kill},defaults:{dry_run:true,hash_diff_window_sec:6},exit_codes:{"0":"permit/pass","1":"domain failure","2":"usage","3":"transient substrate failure","4":"blocked by gate"}}'
}

examples_json() {
  jq -nc '{schema_version:"peer-orch-recovery-permit.examples.v1",examples:[
    {name:"dry-run peer orch permit",command:"peer-orch-respawn-permit.sh --target-session skillos --target-pane 1 --dry-run --json"},
    {name:"apply permit receipt",command:"peer-orch-respawn-permit.sh --target-session skillos --target-pane 1 --apply --json"},
    {name:"doctor scope payload",command:"peer-orch-respawn-permit.sh --doctor --json"},
    {name:"audit ledger",command:"peer-orch-respawn-permit.sh audit --json"},
    {name:"repair contract self-row",command:"peer-orch-respawn-permit.sh repair --scope substrate-contract --apply --json"}
  ]}'
}

quickstart_json() {
  jq -nc '{schema_version:"peer-orch-recovery-permit.quickstart.v1",command:"quickstart",status:"ok",steps:["Confirm latest session-topology has target orchestrator_pane.","Run dry-run against target peer orch.","Require freeze evidence from hash-diff or robot activity state.","Run --apply to write permit/refuse receipt.","Only then call /flywheel:respawn for the peer orchestrator."]}'
}

schema_json() {
  case "$SCHEMA_TOPIC" in
    doctor) jq -nc '{schema_version:"peer-orch-recovery-permit.schema.v1",command:"doctor",required:["peer_orch_recovery_count_24h","last_peer_orch_recovery_ts","peer_orch_recovery_targets_top","peer_orch_recovery_self_refuse_count_24h"]}' ;;
    ledger) jq -nc '{schema_version:"peer-orch-recovery.ledger.schema.v1",required:["ts","actor_session","actor_pane","target_session","target_pane","freeze_confirmed","hash_diff_window_sec","reason","decision","decision_reason","success"]}' ;;
    contract) jq -nc '{schema_version:"substrate-loop-contract.v1",required:["primitive_name","declares_loop","self_repair_action","measurement_field","escalation_path","schema_version"]}' ;;
    *) jq -nc '{schema_version:"peer-orch-recovery-permit.schema.v1",command:"decision",required:["actor_session","actor_pane","target_session","target_pane","decision","decision_reason","freeze_confirmed"]}' ;;
  esac
}

help_json() {
  jq -nc --arg topic "$HELP_TOPIC" '{schema_version:"peer-orch-recovery-permit.help.v1",topic:$topic,text:"Topics: decision, freeze-evidence, protected-sessions, doctor, repair. flywheel:1 may recover peer orchestrator panes after this permit gate; self-orch respawn remains refused."}'
}

completion() {
  case "$COMPLETION_SHELL" in
    ""|--help|-h) printf 'usage: peer-orch-respawn-permit.sh completion <bash|zsh>\n' ;;
    bash) printf 'complete -W "--target-session --target-pane --actor-session --actor-pane --reason --dry-run --apply --doctor --json --info --examples quickstart help completion schema health repair validate audit why" peer-orch-respawn-permit.sh\n' ;;
    zsh) printf 'compadd -- --target-session --target-pane --actor-session --actor-pane --reason --dry-run --apply --doctor --json --info --examples quickstart help completion schema health repair validate audit why\n' ;;
    *) echo "ERR: unsupported completion shell: $COMPLETION_SHELL" >&2; return 2 ;;
  esac
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --target-session) TARGET_SESSION="${2:-}"; shift 2 ;;
    --target-session=*) TARGET_SESSION="${1#*=}"; shift ;;
    --target-pane) TARGET_PANE="${2:-}"; shift 2 ;;
    --target-pane=*) TARGET_PANE="${1#*=}"; shift ;;
    --actor-session) ACTOR_SESSION="${2:-}"; shift 2 ;;
    --actor-session=*) ACTOR_SESSION="${1#*=}"; shift ;;
    --actor-pane) ACTOR_PANE="${2:-}"; shift 2 ;;
    --actor-pane=*) ACTOR_PANE="${1#*=}"; shift ;;
    --reason) REASON="${2:-}"; shift 2 ;;
    --reason=*) REASON="${1#*=}"; shift ;;
    --hash-window-sec) HASH_WINDOW_SEC="${2:-}"; shift 2 ;;
    --hash-window-sec=*) HASH_WINDOW_SEC="${1#*=}"; shift ;;
    --repo) shift 2 ;;
    --repo=*) shift ;;
    --json) JSON_OUT=1; shift ;;
    --dry-run) DRY_RUN=1; APPLY=0; shift ;;
    --apply) APPLY=1; DRY_RUN=0; shift ;;
    --doctor|doctor) MODE="doctor"; shift ;;
    health) MODE="health"; shift ;;
    repair) MODE="repair"; shift ;;
    validate) MODE="validate"; VALIDATE_TARGET="${2:-ledger}"; shift $(( $# > 1 ? 2 : 1 )) ;;
    audit) MODE="audit"; shift ;;
    why) MODE="why"; WHY_ID="${2:-}"; shift $(( $# > 1 ? 2 : 1 )) ;;
    schema|--schema) MODE="schema"; SCHEMA_TOPIC="${2:-decision}"; shift $(( $# > 1 ? 2 : 1 )) ;;
    --info) MODE="info"; shift ;;
    --examples|examples) MODE="examples"; shift ;;
    quickstart) MODE="quickstart"; shift ;;
    help) MODE="help"; HELP_TOPIC="${2:-overview}"; shift $(( $# > 1 ? 2 : 1 )) ;;
    completion) MODE="completion"; COMPLETION_SHELL="${2:-}"; shift $(( $# > 1 ? 2 : 1 )) ;;
    --scope) REPAIR_SCOPE="${2:-}"; VALIDATE_TARGET="$REPAIR_SCOPE"; shift 2 ;;
    --scope=*) REPAIR_SCOPE="${1#*=}"; VALIDATE_TARGET="$REPAIR_SCOPE"; shift ;;
    --watch) WATCH=1; shift ;;
    -i|--interval) WATCH_INTERVAL="${2:-30}"; shift 2 ;;
    -i=*|--interval=*) WATCH_INTERVAL="${1#*=}"; shift ;;
    -h|--help) usage; exit 0 ;;
    *) echo "ERR: unknown argument: $1" >&2; usage >&2; exit 2 ;;
  esac
done

case "$MODE" in
  decide) run_decision ;;
  doctor) emit "$(doctor_json)" "$(doctor_json | jq -r '"status=\(.status) peer_orch_recovery_count_24h=\(.peer_orch_recovery_count_24h)"')" ;;
  health) run_health ;;
  repair) emit "$(run_repair)" "repair scope=$REPAIR_SCOPE apply=$APPLY" ;;
  validate) emit "$(validate_json)" "$(validate_json | jq -r '"status=\(.status) rows_checked=\(.rows_checked)"')" ;;
  audit) emit "$(doctor_json | jq -c --argjson rows "$(rows_json)" '.schema_version="peer-orch-recovery-permit.audit.v1" | .latest_rows=($rows[-5:])')" "audit ledger=$LEDGER" ;;
  why) emit "$(jq -nc --arg id "$WHY_ID" '{schema_version:"peer-orch-recovery-permit.why.v1",id:$id,reason:(if $id=="self_orch_respawn_refused" then "flywheel:1 cannot respawn its own orchestrator pane; peer sessions own that recovery." elif $id=="protected_session_refused" then "kill-recover-drill protected session hard-refusal is respected outside the skillos peer-orch recovery exception." else "unknown id" end)}')" "why=$WHY_ID" ;;
  schema) emit "$(schema_json)" "schema=$SCHEMA_TOPIC" ;;
  info) emit "$(info_json)" "$VERSION" ;;
  examples) emit "$(examples_json)" "examples" ;;
  quickstart) emit "$(quickstart_json)" "quickstart" ;;
  help) emit "$(help_json)" "help $HELP_TOPIC" ;;
  completion) completion ;;
  *) echo "ERR: unknown mode: $MODE" >&2; exit 2 ;;
esac
