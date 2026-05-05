#!/usr/bin/env bash
set -euo pipefail

VERSION="0.1.0"
SCHEMA_VERSION="handoff-skill-to-skillos/v1"
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd -P)"
TEMPLATE="${HANDOFF_SKILL_TO_SKILLOS_TEMPLATE:-$ROOT/.flywheel/templates/skill-handoff-to-skillos.md}"
SKILLOS_STATE_DIR="${HANDOFF_SKILL_TO_SKILLOS_SKILLOS_STATE_DIR:-$HOME/Developer/skillos/state}"
DISPATCH_LOG="${HANDOFF_SKILL_TO_SKILLOS_DISPATCH_LOG:-$ROOT/.flywheel/dispatch-log.jsonl}"
FLEET_MAIL_PROJECT="${HANDOFF_SKILL_TO_SKILLOS_FLEET_MAIL_PROJECT:-/Users/josh/.local/state/flywheel/fleet-mail-project}"
MCP_URL="${HANDOFF_SKILL_TO_SKILLOS_MCP_URL:-http://127.0.0.1:8765/api/}"
MCP_CONFIG="${HANDOFF_SKILL_TO_SKILLOS_MCP_CONFIG:-$HOME/.config/mcp/agent-mail.json}"
TOKEN_LOAD="${HANDOFF_SKILL_TO_SKILLOS_TOKEN_LOAD:-$ROOT/.flywheel/scripts/fleet-mail-token-load.sh}"
JSONL_APPEND_LIB="${FLYWHEEL_JSONL_APPEND_LIB:-$HOME/.local/share/flywheel-watchers/lib/jsonl-append.sh}"
CURL_BIN="${HANDOFF_SKILL_TO_SKILLOS_CURL:-curl}"
JSM_BIN="${HANDOFF_SKILL_TO_SKILLOS_JSM:-jsm}"

SENDER="${HANDOFF_SKILL_TO_SKILLOS_SENDER:-LavenderGlen}"
RECIPIENT="${HANDOFF_SKILL_TO_SKILLOS_RECIPIENT:-FoggyBear}"
ORIGIN_SESSION="${HANDOFF_SKILL_TO_SKILLOS_ORIGIN_SESSION:-flywheel:unknown}"
CREATION_BEAD_ID="${HANDOFF_SKILL_TO_SKILLOS_BEAD_ID:-unknown}"
DISPATCH_LOG_REF="${HANDOFF_SKILL_TO_SKILLOS_DISPATCH_LOG_REF:-$DISPATCH_LOG}"
DEFAULT_REQUESTS=$'  - Review skill for skillos hardening cycle.\n  - Add or refresh tests, examples, and sources as skillos judges appropriate.'

DRY_RUN=0
BATCH=0

usage() {
  cat <<'EOF'
usage: handoff-skill-to-skillos.sh [--dry-run] [--batch] <skill-name> [<version>]

Exit codes:
  0 sent or dry-run preview
  1 fleet-mail send or dispatch-log append failed
  2 skill not found
  3 ownership forbidden, no handoff needed
  4 already handed off for this major.minor version
EOF
}

json_emit() {
  local action="$1" message_id="$2" skill="$3" version="$4" ownership="$5" reason="${6:-}" subject="${7:-}" body="${8:-}"
  jq -nc \
    --arg action "$action" \
    --argjson message_id "$message_id" \
    --arg skill "$skill" \
    --arg version "$version" \
    --arg ownership "$ownership" \
    --arg reason "$reason" \
    --arg subject "$subject" \
    --arg body_md "$body" \
    '{
      action:$action,
      message_id:$message_id,
      skill:$skill,
      version:$version,
      ownership:$ownership
    }
    + (if $reason == "" then {} else {reason:$reason} end)
    + (if $subject == "" then {} else {subject:$subject} end)
    + (if $body_md == "" then {} else {body_md:$body_md} end)'
}

need() {
  command -v "$1" >/dev/null 2>&1 || {
    json_emit "skipped" "null" "${SKILL_NAME:-unknown}" "${SKILL_VERSION:-unknown}" "unknown" "missing_dependency:$1"
    exit 1
  }
}

skill_roots() {
  if [[ -n "${HANDOFF_SKILL_TO_SKILLOS_SKILL_ROOTS:-}" ]]; then
    tr ':' '\n' <<<"$HANDOFF_SKILL_TO_SKILLOS_SKILL_ROOTS"
  else
    printf '%s\n' "$HOME/.claude/skills" "$HOME/.codex/skills"
  fi
}

find_skill_path() {
  local skill="$1" root path
  while IFS= read -r root; do
    path="$root/$skill"
    [[ -d "$path" ]] && {
      printf '%s\n' "$path"
      return 0
    }
  done < <(skill_roots)
  return 1
}

version_from_skill_file() {
  local path="$1"
  awk -F': *' '/^version:[[:space:]]*/ {print $2; exit}' "$path/SKILL.md" 2>/dev/null || true
}

version_minor() {
  local version="$1"
  if [[ "$version" =~ ^([0-9]+)\.([0-9]+)\. ]]; then
    printf '%s.%s\n' "${BASH_REMATCH[1]}" "${BASH_REMATCH[2]}"
  else
    printf '%s\n' "$version"
  fi
}

jsm_json_for() {
  local skill="$1"
  "$JSM_BIN" show "$skill" --json 2>/dev/null || true
}

ownership_for() {
  local skill="$1" jsm_json="$2"
  jq -r '
    if (.skill? and (.skill.is_owner == false) and (.skill.distribution_policy == "forbidden" or .skill.is_jeffreys == true))
    then "upstream"
    else "local"
    end
  ' <<<"$jsm_json" 2>/dev/null || printf 'local\n'
}

is_forbidden() {
  local jsm_json="$1"
  jq -e '.skill? and (.skill.is_owner == false) and (.skill.distribution_policy == "forbidden" or .skill.is_jeffreys == true)' <<<"$jsm_json" >/dev/null 2>&1
}

duplicate_receipt() {
  local skill="$1" version="$2" minor
  minor="$(version_minor "$version")"
  compgen -G "$SKILLOS_STATE_DIR/$skill-v$minor-*.json" >/dev/null ||
    compgen -G "$SKILLOS_STATE_DIR/$skill-v$version-*.json" >/dev/null
}

hardening_requests() {
  local raw="${HANDOFF_SKILL_TO_SKILLOS_HARDENING_REQUESTS:-}"
  if [[ -z "$raw" ]]; then
    printf '%s\n' "$DEFAULT_REQUESTS"
  elif grep -q '^  - ' <<<"$raw"; then
    printf '%s\n' "$raw"
  else
    awk '{print "  - " $0}' <<<"$raw"
  fi
}

subject_for() {
  local skill="$1" version="$2" em_dash
  em_dash="$(printf '\342\200\224')"
  printf '[skill-handoff] %s v%s %s for skillos hardening cycle' "$skill" "$version" "$em_dash"
}

body_for() {
  local skill="$1" version="$2" path="$3" ownership="$4" requests="$5"
  cat <<EOF
# Skill Handoff: $skill v$version

source: fleet-mail-skill-handoff
schema_version: $SCHEMA_VERSION

## Ownership

- ownership: $ownership
- allowed values: local | upstream
- forbidden policy: if ownership is forbidden, this message should not be sent;
  create a local no-handoff receipt instead.

## Skill

- name: $skill
- path: $path
- current_version: $version
- requested_receiver: skillos
- requested_cycle: hardening

## Flywheel Provenance

- origin_session: $ORIGIN_SESSION
- creation_bead_id: $CREATION_BEAD_ID
- dispatch_log_ref: $DISPATCH_LOG_REF

## Hardening Requests

Sender-suggested improvements. Skillos owns acceptance, ordering, and versioning.

hardening_requests:
$requests

## Receipt Compatibility

- source: fleet-mail-skill-handoff
- fleet_mail.subject: $(subject_for "$skill" "$version")
- skill.name: $skill
- skill.path: $path
- skill.previous_version: $version
- skill.distribution: $ownership
- hardening_requests_from_message: $requests
EOF
}

bearer_token() {
  if [[ -n "${AGENTMAIL_HTTP_BEARER_TOKEN:-}" ]]; then
    printf '%s\n' "$AGENTMAIL_HTTP_BEARER_TOKEN"
  elif [[ -f "$MCP_CONFIG" ]]; then
    jq -r '.auth_token // empty' "$MCP_CONFIG"
  fi
}

sender_token() {
  if [[ -n "${HANDOFF_SKILL_TO_SKILLOS_SENDER_TOKEN:-}" ]]; then
    printf '%s\n' "$HANDOFF_SKILL_TO_SKILLOS_SENDER_TOKEN"
  elif [[ -x "$TOKEN_LOAD" ]]; then
    "$TOKEN_LOAD" "$SENDER"
  else
    printf ''
  fi
}

append_dispatch_log() {
  local row="$1"
  mkdir -p "$(dirname "$DISPATCH_LOG")"
  if [[ -f "$JSONL_APPEND_LIB" ]]; then
    # shellcheck disable=SC1090
    source "$JSONL_APPEND_LIB"
    fw_jsonl_append_validated "$DISPATCH_LOG" "$row"
  else
    printf '%s\n' "$row" >>"$DISPATCH_LOG"
    jq -e . "$DISPATCH_LOG" >/dev/null
  fi
}

send_message() {
  local subject="$1" body="$2" bearer reg_token payload response message_id
  bearer="$(bearer_token)"
  reg_token="$(sender_token)"
  [[ -n "$bearer" && -n "$reg_token" ]] || return 1
  payload="$(jq -nc \
    --arg project_key "$FLEET_MAIL_PROJECT" \
    --arg sender_name "$SENDER" \
    --arg sender_token "$reg_token" \
    --arg recipient "$RECIPIENT" \
    --arg subject "$subject" \
    --arg body_md "$body" \
    '{
      jsonrpc:"2.0",
      id:1,
      method:"tools/call",
      params:{
        name:"send_message",
        arguments:{
          project_key:$project_key,
          sender_name:$sender_name,
          sender_token:$sender_token,
          to:[$recipient],
          subject:$subject,
          body_md:$body_md,
          importance:"normal",
          ack_required:false,
          thread_id:"skill-handoff"
        }
      }
    }')"
  response="$("$CURL_BIN" -fsS "$MCP_URL" -H "Authorization: Bearer $bearer" -H "Content-Type: application/json" -d "$payload")" || return 1
  if jq -e '.error?' <<<"$response" >/dev/null; then
    return 1
  fi
  message_id="$(jq -r '
    .result.content[0].text as $text
    | ($text | fromjson? // {}) as $parsed
    | ($parsed.deliveries[0].payload.id // $parsed.deliveries[0].payload.message_id // $parsed.id // null)
  ' <<<"$response")"
  [[ "$message_id" =~ ^[0-9]+$ ]] || return 1
  printf '%s\n' "$message_id"
}

if [[ $# -eq 0 ]]; then
  usage
  exit 2
fi

while [[ $# -gt 0 ]]; do
  case "$1" in
    --dry-run) DRY_RUN=1; shift ;;
    --batch) BATCH=1; shift ;;
    --json|--no-color|--no-emoji) shift ;;
    --width) shift 2 ;;
    --help|-h|help) usage; exit 0 ;;
    --info)
      jq -nc --arg version "$VERSION" --arg root "$ROOT" --arg template "$TEMPLATE" --arg project "$FLEET_MAIL_PROJECT" \
        '{name:"handoff-skill-to-skillos",version:$version,root:$root,template:$template,fleet_mail_project:$project}'
      exit 0
      ;;
    --examples|examples)
      jq -nc '{examples:["handoff-skill-to-skillos.sh --dry-run my-skill 0.1.0","handoff-skill-to-skillos.sh my-skill","handoff-skill-to-skillos.sh --batch my-skill 0.1.0"]}'
      exit 0
      ;;
    --*) usage >&2; exit 2 ;;
    *) break ;;
  esac
done

SKILL_NAME="${1:-}"
SKILL_VERSION="${2:-}"
[[ -n "$SKILL_NAME" ]] || {
  usage >&2
  exit 2
}

need jq
[[ -f "$TEMPLATE" ]] || {
  json_emit "skipped" "null" "$SKILL_NAME" "${SKILL_VERSION:-unknown}" "unknown" "template_not_found"
  exit 1
}

JSM_JSON="$(jsm_json_for "$SKILL_NAME")"
OWNERSHIP="$(ownership_for "$SKILL_NAME" "$JSM_JSON")"

if is_forbidden "$JSM_JSON"; then
  row="$(jq -nc \
    --arg event "skillos_handoff_skipped" \
    --arg skill "$SKILL_NAME" \
    --arg ownership "$OWNERSHIP" \
    --arg reason "ownership_forbidden" \
    --argjson batch "$BATCH" \
    '{ts:(now|todateiso8601),event:$event,skill:$skill,ownership:$ownership,skillos_handoff_skipped_reason:$reason,batch:$batch}')"
  [[ "$DRY_RUN" -eq 1 ]] || append_dispatch_log "$row" || exit 1
  json_emit "forbidden" "null" "$SKILL_NAME" "${SKILL_VERSION:-unknown}" "$OWNERSHIP" "ownership_forbidden"
  exit 3
fi

SKILL_PATH="$(find_skill_path "$SKILL_NAME" || true)"
if [[ -z "$SKILL_PATH" ]]; then
  json_emit "skipped" "null" "$SKILL_NAME" "${SKILL_VERSION:-unknown}" "$OWNERSHIP" "skill_not_found"
  exit 2
fi

if [[ -z "$SKILL_VERSION" ]]; then
  SKILL_VERSION="$(version_from_skill_file "$SKILL_PATH")"
fi
if [[ -z "$SKILL_VERSION" ]]; then
  SKILL_VERSION="$(jq -r '.skill.version // empty' <<<"$JSM_JSON" 2>/dev/null || true)"
fi
[[ -n "$SKILL_VERSION" ]] || SKILL_VERSION="0.0.0"

REQUESTS="$(hardening_requests)"
SUBJECT="$(subject_for "$SKILL_NAME" "$SKILL_VERSION")"
BODY="$(body_for "$SKILL_NAME" "$SKILL_VERSION" "$SKILL_PATH" "$OWNERSHIP" "$REQUESTS")"

if duplicate_receipt "$SKILL_NAME" "$SKILL_VERSION"; then
  row="$(jq -nc \
    --arg event "skillos_handoff_skipped" \
    --arg skill "$SKILL_NAME" \
    --arg version "$SKILL_VERSION" \
    --arg ownership "$OWNERSHIP" \
    --arg reason "already_handed_off_this_version" \
    --argjson batch "$BATCH" \
    '{ts:(now|todateiso8601),event:$event,skill:$skill,version:$version,ownership:$ownership,skillos_handoff_skipped_reason:$reason,batch:$batch}')"
  [[ "$DRY_RUN" -eq 1 ]] || append_dispatch_log "$row" || exit 1
  json_emit "duplicate" "null" "$SKILL_NAME" "$SKILL_VERSION" "$OWNERSHIP" "already_handed_off_this_version"
  exit 4
fi

if [[ "$DRY_RUN" -eq 1 ]]; then
  json_emit "skipped" "null" "$SKILL_NAME" "$SKILL_VERSION" "$OWNERSHIP" "dry_run" "$SUBJECT" "$BODY"
  exit 0
fi

MESSAGE_ID="$(send_message "$SUBJECT" "$BODY")" || {
  json_emit "skipped" "null" "$SKILL_NAME" "$SKILL_VERSION" "$OWNERSHIP" "fleet_mail_send_failed"
  exit 1
}

ROW="$(jq -nc \
  --arg event "skillos_handoff_sent" \
  --arg skill "$SKILL_NAME" \
  --arg version "$SKILL_VERSION" \
  --arg ownership "$OWNERSHIP" \
  --argjson message_id "$MESSAGE_ID" \
  --arg subject "$SUBJECT" \
  --arg sender "$SENDER" \
  --arg recipient "$RECIPIENT" \
  --arg project_key "$FLEET_MAIL_PROJECT" \
  --arg origin_session "$ORIGIN_SESSION" \
  --arg creation_bead_id "$CREATION_BEAD_ID" \
  --arg dispatch_log_ref "$DISPATCH_LOG_REF" \
  --argjson batch "$BATCH" \
  '{ts:(now|todateiso8601),event:$event,skill:$skill,version:$version,ownership:$ownership,message_id:$message_id,subject:$subject,sender:$sender,recipient:$recipient,project_key:$project_key,origin_session:$origin_session,creation_bead_id:$creation_bead_id,dispatch_log_ref:$dispatch_log_ref,batch:$batch,skillos_handoff_skipped_reason:null}')"
append_dispatch_log "$ROW" || {
  json_emit "sent" "$MESSAGE_ID" "$SKILL_NAME" "$SKILL_VERSION" "$OWNERSHIP" "dispatch_log_append_failed"
  exit 1
}

json_emit "sent" "$MESSAGE_ID" "$SKILL_NAME" "$SKILL_VERSION" "$OWNERSHIP"
