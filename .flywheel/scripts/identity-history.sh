#!/usr/bin/env bash
set -euo pipefail

STATE_DIR="${FLYWHEEL_AGENT_MAIL_STATE_DIR:-$HOME/.local/state/flywheel/agent-mail}"
SESSION_DIR="${FLYWHEEL_AGENT_MAIL_SESSION_DIR:-$STATE_DIR/sessions}"
LOOP_BIN="${FLYWHEEL_LOOP_BIN:-$HOME/.claude/skills/.flywheel/bin/flywheel-loop}"

usage() {
  cat <<'EOF'
identity-history.sh --session <name> --pane <n> [--json]
identity-history.sh doctor|health|validate|audit|why|repair|schema|quickstart|completion
EOF
}

json_string() {
  jq -Rn --arg v "$1" '$v'
}

emit_chain() {
  local session="$1" pane="$2" row_path
  row_path="$SESSION_DIR/$session:$pane.json"
  if [[ ! -f "$row_path" ]]; then
    jq -nc --arg session "$session" --argjson pane "$pane" \
      '{schema_version:"identity-history/v1",status:"missing",session:$session,pane:$pane,chain:[],chain_length:0}'
    return 1
  fi
  jq -c '
    (.predecessor_identity_chain // []) as $predecessors
    | ($predecessors + ([.identity_name] | map(select(. != null and . != "")))) as $chain
    | {
        schema_version:"identity-history/v1",
        status:"pass",
        identity_primary_key:(.identity_primary_key // {session:.session,pane:.pane,fleet_mail_project_key:.fleet_mail_project_key}),
        identity_primary_key_text:(.identity_primary_key_text // ((.session // "") + ":" + ((.pane // -1) | tostring) + ":" + (.fleet_mail_project_key // ""))),
        session:.session,
        pane:.pane,
        fleet_mail_project_key:.fleet_mail_project_key,
        current_identity:.identity_name,
        rotation_reason:.rotation_reason,
        rotation_reason_detail:(.rotation_reason_detail // null),
        predecessor_identity:.predecessor_identity,
        chain:$chain,
        chain_length:($chain | length),
        high_churn:(($chain | length) > 3)
      }
  ' "$row_path"
}

doctor() {
  "$LOOP_BIN" identity --doctor --json | jq -c '{
    schema_version:"identity-history-doctor/v1",
    status:(if (.identity_chain_max_length // 0) > 3 then "warn" else "pass" end),
    identity_rotation_count_24h:(.identity_rotation_count_24h // 0),
    identity_rotation_count_24h_by_session:(.identity_rotation_count_24h_by_session // {}),
    identity_chain_max_length:(.identity_chain_max_length // 0),
    orphan_tokens_unswept_count:(.orphan_tokens_unswept_count // 0),
    registry_status:(.status // "unknown")
  }'
}

schema() {
  jq -nc '{
    schema_version:"identity-history.schema/v1",
    command:"identity-history",
    required:["schema_version","status","identity_primary_key","chain","chain_length"],
    fields:{
      identity_primary_key:"object keyed by session,pane,fleet_mail_project_key",
      chain:"predecessor identities followed by current identity",
      high_churn:"true when chain_length > 3"
    }
  }'
}

quickstart() {
  jq -nc '{
    schema_version:"identity-history-quickstart/v1",
    status:"pass",
    examples:[
      ".flywheel/scripts/identity-history.sh --session flywheel --pane 2 --json",
      ".flywheel/scripts/identity-history.sh doctor --json",
      ".flywheel/scripts/identity-history.sh repair --dry-run --json"
    ]
  }'
}

completion() {
  printf 'complete -W "doctor health repair validate audit why schema quickstart completion --session --pane --json --dry-run" identity-history.sh\n'
}

command="${1:-}"
json=0
session=""
pane=""
dry_run=0
args=()
while [[ $# -gt 0 ]]; do
  case "$1" in
    --json) json=1; shift ;;
    --session=*) session="${1#--session=}"; shift ;;
    --session) session="${2:-}"; shift 2 ;;
    --pane=*) pane="${1#--pane=}"; shift ;;
    --pane) pane="${2:-}"; shift 2 ;;
    --dry-run) dry_run=1; shift ;;
    --info)
      jq -nc --arg state_dir "$STATE_DIR" --arg session_dir "$SESSION_DIR" --arg loop_bin "$LOOP_BIN" \
        '{name:"identity-history.sh",schema_version:"identity-history-info/v1",state_dir:$state_dir,session_dir:$session_dir,loop_bin:$loop_bin}'
      exit 0 ;;
    --examples) quickstart; exit 0 ;;
    --help|-h) usage; exit 0 ;;
    doctor|health|repair|validate|audit|why|schema|quickstart|completion|help)
      args+=("$1"); shift ;;
    *) args+=("$1"); shift ;;
  esac
done

command="${args[0]:-}"
case "$command" in
  doctor|health) doctor ;;
  validate) doctor | jq -c '. + {command:"validate"}' ;;
  audit) "$LOOP_BIN" identity --doctor --json | jq -c '{schema_version:"identity-history-audit/v1",status:"pass",recent_rotations:(.recent_rotations // [])}' ;;
  why)
    if [[ -z "$session" || -z "$pane" ]]; then
      jq -nc '{schema_version:"identity-history-why/v1",status:"usage_error",error:"why requires --session and --pane"}'
      exit 2
    fi
    emit_chain "$session" "$pane" | jq -c '. + {why:"identity is keyed by session,pane,fleet_mail_project_key; identity_name is only the current pointer"}'
    ;;
  repair)
    if [[ "$dry_run" -ne 1 ]]; then
      jq -nc '{schema_version:"identity-history-repair/v1",status:"blocked",blocked_by:"repair requires --dry-run; use flywheel-loop identity --sweep-orphan-tokens for apply"}'
      exit 4
    fi
    "$LOOP_BIN" identity --sweep-orphan-tokens --dry-run --json
    ;;
  schema) schema ;;
  quickstart|help) quickstart ;;
  completion) completion ;;
  "")
    if [[ -z "$session" || -z "$pane" ]]; then
      usage >&2
      exit 2
    fi
    emit_chain "$session" "$pane"
    ;;
  *)
    if [[ -n "$session" && -n "$pane" ]]; then
      emit_chain "$session" "$pane"
    else
      usage >&2
      exit 2
    fi
    ;;
esac
