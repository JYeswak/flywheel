#!/usr/bin/env bash
# flywheel-cli-surface: true
#
# Ensure the current orchestrator pane has an Agent Mail registration token in
# the canonical local identity registry. Output never includes the token value.

set -euo pipefail

VERSION="orch-agent-mail-session-register.v0.1.0"
SCHEMA_VERSION="flywheel.orch_agent_mail_session_register.v1"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)"
ROOT="$(cd "$SCRIPT_DIR/../.." && pwd -P)"

SESSION="${FLYWHEEL_ORCH_AM_SESSION:-flywheel}"
PANE="${FLYWHEEL_ORCH_AM_PANE:-1}"
PROJECT_KEY="${FLYWHEEL_ORCH_AM_PROJECT_KEY:-$ROOT}"
ROLE="${FLYWHEEL_ORCH_AM_ROLE:-orch}"
PROGRAM="${FLYWHEEL_ORCH_AM_PROGRAM:-codex-cli}"
MODEL="${FLYWHEEL_ORCH_AM_MODEL:-gpt-5.5}"
TASK_DESCRIPTION="${FLYWHEEL_ORCH_AM_TASK_DESCRIPTION:-Flywheel orchestrator AgentMail session registration}"
STATE_DIR="${FLYWHEEL_AGENT_MAIL_STATE_DIR:-$HOME/.local/state/flywheel/agent-mail}"
TOKEN_DIR="${FLYWHEEL_AGENT_MAIL_TOKEN_DIR:-$STATE_DIR/tokens}"
COMPAT_INDEX="${FLYWHEEL_AGENT_MAIL_TOKEN_INDEX:-$HOME/.local/state/flywheel/agent-mail-tokens.json}"
LOOP_BIN="${FLYWHEEL_LOOP_BIN:-$HOME/.claude/skills/.flywheel/bin/flywheel-loop}"
MCP_URL="${FLYWHEEL_ORCH_AM_MCP_URL:-http://127.0.0.1:8765/api/}"
MCP_CONFIG="${FLYWHEEL_ORCH_AM_MCP_CONFIG:-$HOME/.config/mcp/agent-mail.json}"
CURL_BIN="${FLYWHEEL_ORCH_AM_CURL:-curl}"
APPLY=0
IDENTITY="${FLYWHEEL_ORCH_AM_IDENTITY:-}"

usage() {
  cat <<EOF
usage:
  orch-agent-mail-session-register.sh [--apply] [--dry-run] [--json]
      [--session NAME] [--pane N] [--project-key PATH] [--identity NAME]
  orch-agent-mail-session-register.sh doctor|health [--json]
  orch-agent-mail-session-register.sh --info|--schema|--examples [--json]

Ensures an orchestrator session has an Agent Mail sender token in the canonical
mode-600 token vault. Default is dry-run. Mutating registration requires
--apply and can be disabled with FLYWHEEL_ORCH_AM_REGISTER=0.
EOF
}

json_string() {
  jq -Rn --arg v "$1" '$v'
}

sanitize_identity() {
  local value="$1"
  value="$(printf '%s' "$value" | tr -c 'A-Za-z0-9._-' '-')"
  value="${value#-}"
  value="${value%-}"
  printf '%s\n' "${value:-flywheel-orch}"
}

default_identity() {
  sanitize_identity "${SESSION}-${PANE}-orch"
}

emit_info() {
  jq -nc \
    --arg schema "$SCHEMA_VERSION" \
    --arg version "$VERSION" \
    --arg token_dir "$TOKEN_DIR" \
    --arg compat_index "$COMPAT_INDEX" \
    '{schema_version:$schema,name:"orch-agent-mail-session-register",version:$version,mutates_only_with:"--apply",token_dir:$token_dir,compat_index:$compat_index,raw_token_in_output:false}'
}

emit_schema() {
  jq -nc --arg schema "$SCHEMA_VERSION" '{
    schema_version:$schema,
    required:["schema_version","status","session","pane","project_key","identity_name"],
    statuses:["already_registered","planned","registered","disabled","fail"]
  }'
}

emit_examples() {
  jq -nc '{examples:[
    ".flywheel/scripts/orch-agent-mail-session-register.sh --json",
    ".flywheel/scripts/orch-agent-mail-session-register.sh --apply --session flywheel --pane 1 --json"
  ]}'
}

bearer_token() {
  if [[ -n "${AGENTMAIL_HTTP_BEARER_TOKEN:-}" ]]; then
    printf '%s\n' "$AGENTMAIL_HTTP_BEARER_TOKEN"
  elif [[ -f "$MCP_CONFIG" ]]; then
    jq -r '.auth_token // empty' "$MCP_CONFIG"
  fi
}

current_identity_json() {
  if [[ -x "$LOOP_BIN" ]]; then
    "$LOOP_BIN" identity --session "$SESSION" --pane "$PANE" --json 2>/dev/null || true
  fi
}

emit_current_if_registered() {
  local current="$1"
  if jq -e '.status == "active" and (.token_path // "") != ""' <<<"$current" >/dev/null 2>&1; then
    local token_path
    token_path="$(jq -r '.token_path' <<<"$current")"
    if [[ -f "$token_path" ]]; then
      jq -c --arg schema "$SCHEMA_VERSION" --arg status "already_registered" \
        '. + {schema_version:$schema,status:$status,raw_token_in_output:false}' <<<"$current"
      return 0
    fi
  fi
  return 1
}

register_via_mcp() {
  local identity="$1" bearer payload response text token returned_name token_path token_sha
  bearer="$(bearer_token)"
  [[ -n "$bearer" ]] || { jq -nc --arg schema "$SCHEMA_VERSION" '{schema_version:$schema,status:"fail",reason:"agent_mail_bearer_missing"}'; return 1; }
  payload="$(jq -nc \
    --arg project_key "$PROJECT_KEY" \
    --arg program "$PROGRAM" \
    --arg model "$MODEL" \
    --arg name "$identity" \
    --arg task_description "$TASK_DESCRIPTION" \
    '{jsonrpc:"2.0",id:1,method:"tools/call",params:{name:"register_agent",arguments:{project_key:$project_key,program:$program,model:$model,name:$name,task_description:$task_description}}}')"
  response="$("$CURL_BIN" -fsS "$MCP_URL" -H "Authorization: Bearer $bearer" -H "Content-Type: application/json" -d "$payload")" || {
    jq -nc --arg schema "$SCHEMA_VERSION" '{schema_version:$schema,status:"fail",reason:"register_agent_http_failed"}'
    return 1
  }
  if jq -e '.error? // .result.isError == true' <<<"$response" >/dev/null; then
    jq -nc --arg schema "$SCHEMA_VERSION" --arg reason "$(jq -c '.error' <<<"$response")" '{schema_version:$schema,status:"fail",reason:"register_agent_error",error:$reason}'
    return 1
  fi
  text="$(jq -r '.result.content[0].text // empty' <<<"$response")"
  token="$(jq -r '.registration_token // empty' <<<"$text" 2>/dev/null || true)"
  returned_name="$(jq -r '.name // empty' <<<"$text" 2>/dev/null || true)"
  [[ -n "$token" && -n "$returned_name" ]] || {
    jq -nc --arg schema "$SCHEMA_VERSION" '{schema_version:$schema,status:"fail",reason:"registration_token_missing"}'
    return 1
  }

  mkdir -p "$TOKEN_DIR"
  chmod 700 "$TOKEN_DIR"
  token_path="$TOKEN_DIR/$returned_name.token"
  printf '%s' "$token" >"$token_path"
  chmod 600 "$token_path"
  token_sha="$(shasum -a 256 "$token_path" | awk '{print $1}')"

  if [[ -x "$LOOP_BIN" ]]; then
    "$LOOP_BIN" identity \
      --session "$SESSION" \
      --pane "$PANE" \
      --register \
      --identity "$returned_name" \
      --token-path "$token_path" \
      --project-key "$PROJECT_KEY" \
      --role "$ROLE" \
      --json >/dev/null
  fi

  write_compat_index "$returned_name" "$token_path" "$token_sha"
  jq -nc \
    --arg schema "$SCHEMA_VERSION" \
    --arg session "$SESSION" \
    --argjson pane "$PANE" \
    --arg project_key "$PROJECT_KEY" \
    --arg identity_name "$returned_name" \
    --arg token_path "$token_path" \
    --arg token_sha256 "$token_sha" \
    '{schema_version:$schema,status:"registered",session:$session,pane:$pane,project_key:$project_key,identity_name:$identity_name,token_path:$token_path,token_sha256:$token_sha256,raw_token_in_output:false}'
}

write_compat_index() {
  local identity="$1" token_path="$2" token_sha="$3" tmp
  mkdir -p "$(dirname "$COMPAT_INDEX")"
  tmp="$(mktemp "${COMPAT_INDEX}.XXXXXX")"
  if [[ -f "$COMPAT_INDEX" ]]; then
    jq \
      --arg key "$SESSION:$PANE:$PROJECT_KEY" \
      --arg session "$SESSION" \
      --argjson pane "$PANE" \
      --arg project_key "$PROJECT_KEY" \
      --arg identity_name "$identity" \
      --arg token_path "$token_path" \
      --arg token_sha256 "$token_sha" \
      '. + {($key): {session:$session,pane:$pane,project_key:$project_key,identity_name:$identity_name,token_path:$token_path,token_sha256:$token_sha256,raw_token_stored:false}}' \
      "$COMPAT_INDEX" >"$tmp"
  else
    jq -n \
      --arg key "$SESSION:$PANE:$PROJECT_KEY" \
      --arg session "$SESSION" \
      --argjson pane "$PANE" \
      --arg project_key "$PROJECT_KEY" \
      --arg identity_name "$identity" \
      --arg token_path "$token_path" \
      --arg token_sha256 "$token_sha" \
      '{($key): {session:$session,pane:$pane,project_key:$project_key,identity_name:$identity_name,token_path:$token_path,token_sha256:$token_sha256,raw_token_stored:false}}' >"$tmp"
  fi
  mv "$tmp" "$COMPAT_INDEX"
  chmod 600 "$COMPAT_INDEX"
}

cmd_doctor() {
  local current status="ok"
  current="$(current_identity_json)"
  if [[ -z "$current" ]] || ! jq -e '.status == "active" and (.token_path // "") != ""' <<<"$current" >/dev/null 2>&1; then
    status="fail"
  elif [[ ! -f "$(jq -r '.token_path' <<<"$current")" ]]; then
    status="fail"
  fi
  jq -nc \
    --arg schema "$SCHEMA_VERSION" \
    --arg status "$status" \
    --arg session "$SESSION" \
    --argjson pane "$PANE" \
    --arg project_key "$PROJECT_KEY" \
    '{schema_version:$schema,command:"doctor",status:$status,session:$session,pane:$pane,project_key:$project_key}'
  [[ "$status" == "ok" ]]
}

cmd_run() {
  [[ "$PANE" =~ ^[0-9]+$ ]] || { printf 'pane must be numeric: %s\n' "$PANE" >&2; return 64; }
  if [[ "${FLYWHEEL_ORCH_AM_REGISTER:-1}" == "0" ]]; then
    jq -nc --arg schema "$SCHEMA_VERSION" '{schema_version:$schema,status:"disabled",reason:"FLYWHEEL_ORCH_AM_REGISTER=0"}'
    return 3
  fi
  local current identity
  current="$(current_identity_json)"
  if [[ -n "$current" ]] && emit_current_if_registered "$current"; then
    return 0
  fi
  identity="${IDENTITY:-$(default_identity)}"
  local token_path="$TOKEN_DIR/$identity.token"
  if [[ -f "$token_path" ]]; then
    local token_sha
    token_sha="$(shasum -a 256 "$token_path" | awk '{print $1}')"
    jq -nc \
      --arg schema "$SCHEMA_VERSION" \
      --arg session "$SESSION" \
      --argjson pane "$PANE" \
      --arg project_key "$PROJECT_KEY" \
      --arg identity_name "$identity" \
      --arg token_path "$token_path" \
      --arg token_sha256 "$token_sha" \
      '{schema_version:$schema,status:"already_registered",session:$session,pane:$pane,project_key:$project_key,identity_name:$identity_name,token_path:$token_path,token_sha256:$token_sha256,raw_token_in_output:false}'
    return 0
  fi
  if [[ "$APPLY" -ne 1 ]]; then
    jq -nc \
      --arg schema "$SCHEMA_VERSION" \
      --arg session "$SESSION" \
      --argjson pane "$PANE" \
      --arg project_key "$PROJECT_KEY" \
      --arg identity_name "$identity" \
      '{schema_version:$schema,status:"planned",session:$session,pane:$pane,project_key:$project_key,identity_name:$identity_name,apply_required:true,raw_token_in_output:false}'
    return 0
  fi
  register_via_mcp "$identity"
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --info) emit_info; exit 0 ;;
    --schema) emit_schema; exit 0 ;;
    --examples) emit_examples; exit 0 ;;
    --help|-h) usage; exit 0 ;;
    doctor|health) shift; cmd_doctor; exit $? ;;
    --apply) APPLY=1; shift ;;
    --dry-run) APPLY=0; shift ;;
    --json) shift ;;
    --session) SESSION="$2"; shift 2 ;;
    --pane) PANE="$2"; shift 2 ;;
    --project-key) PROJECT_KEY="$2"; shift 2 ;;
    --identity) IDENTITY="$2"; shift 2 ;;
    *) printf 'unknown arg: %s\n' "$1" >&2; usage >&2; exit 64 ;;
  esac
done

cmd_run

# Meta-Learning Cross-References (2026-05-19)
# Batch-16 comment backfill; citations are documentation-only and do not alter runtime behavior.
# Related: `/Users/josh/Developer/skillos/.flywheel/doctrine/meta-learnings/MP-20-cross-orch-handoff.md`
# Related: `/Users/josh/Developer/skillos/.flywheel/doctrine/meta-learnings/MP-100-contention-shaped-state-owner.md`
