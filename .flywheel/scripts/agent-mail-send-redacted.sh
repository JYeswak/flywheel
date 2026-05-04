#!/usr/bin/env bash
# Prepare an Agent Mail send_message call without rendering token values.
#
# Contract:
#   - callers pass --sender-token-handle vault:<agent>, env:<VAR>, or none
#   - literal token values are rejected before any capture/log output is written
#   - output artifacts contain only redacted token metadata
#
# The MCP Agent Mail server is not a shell CLI. This wrapper provides the
# pane-safe contract and dry-run/synthetic regression surface; token-bearing
# live MCP calls must use MCP-native session auth or a future non-rendering MCP
# bridge, not shell-visible token arguments.
set -euo pipefail

usage() {
  cat <<'USAGE'
Usage:
  agent-mail-send-redacted.sh send_message \
    --project-key <path> \
    --sender-name <agent> \
    --to <agent[,agent...]> \
    --subject <subject> \
    --body <text> | --body-file <path> \
    [--sender-token-handle vault:<agent>|env:<VAR>|none] \
    [--capture-dir <dir>] \
    [--dry-run]

  agent-mail-send-redacted.sh register_agent \
    --project-key <path> \
    --program <program> \
    --model <model> \
    [--agent-name <agent>] \
    [--task-description <text>] \
    [--registration-token-handle vault:<agent>|env:<VAR>|none] \
    [--capture-dir <dir>] \
    [--dry-run]

Token values must never be passed directly. Use a vault/env handle.
USAGE
}

die() {
  printf 'ERROR: %s\n' "$*" >&2
  exit 1
}

redact_stream() {
  sed -E \
    -e 's/(registration_token|sender_token)[=:][^[:space:]",}]*/\1=[REDACTED]/g' \
    -e 's/FAKE_AGENT_MAIL_TOKEN_[A-Za-z0-9_=-]+/[REDACTED_TOKEN]/g' \
    -e 's/[A-Za-z0-9_=-]{32,}/[REDACTED_TOKEN]/g'
}

json_escape() {
  python3 -c 'import json,sys; print(json.dumps(sys.stdin.read())[1:-1])'
}

require_no_literal_token() {
  local label="$1"
  local value="$2"

  case "$value" in
    FAKE_AGENT_MAIL_TOKEN_*|*registration_token=*|*sender_token=*)
      die "$label contains literal token-shaped text; pass a handle instead"
      ;;
  esac

  if printf '%s' "$value" | grep -Eq '^[A-Za-z0-9_=-]{32,}$'; then
    die "$label looks like token material; pass vault:<agent> or env:<VAR>"
  fi
}

resolve_token_handle() {
  local handle="$1"
  local vault_dir="${AGENT_MAIL_TOKEN_VAULT_DIR:-$HOME/.local/state/flywheel/fleet-mail-tokens}"
  local name var file token

  case "$handle" in
    none|"")
      return 0
      ;;
    vault:*)
      name="${handle#vault:}"
      name="${name%%:*}"
      require_no_literal_token "vault handle" "$name"
      file="$vault_dir/${name}.token"
      [[ -f "$file" ]] || die "token handle not found: vault:${name}"
      token="$(cat "$file")"
      [[ -n "$token" ]] || die "token handle is empty: vault:${name}"
      ;;
    env:*)
      var="${handle#env:}"
      require_no_literal_token "env handle" "$var"
      [[ "$var" =~ ^[A-Za-z_][A-Za-z0-9_]*$ ]] || die "invalid env handle name: $var"
      token="${!var:-}"
      [[ -n "$token" ]] || die "token handle env var is unset or empty: env:${var}"
      ;;
    *)
      die "unsupported token handle '$handle'; use vault:<agent>, env:<VAR>, or none"
      ;;
  esac

  # Deliberately do not print or export $token. Resolution proves the handle is
  # usable while keeping token material out of pane-visible arguments.
  return 0
}

write_capture_files() {
  local dir="$1"
  local project_key="$2"
  local sender_name="$3"
  local to="$4"
  local subject="$5"
  local body="$6"
  local sender_token_handle="$7"
  local dry_run="$8"
  local project_json sender_json to_json subject_json body_json handle_json mode_json

  mkdir -p "$dir"
  chmod 700 "$dir"

  project_json="$(printf '%s' "$project_key" | json_escape)"
  sender_json="$(printf '%s' "$sender_name" | json_escape)"
  to_json="$(printf '%s' "$to" | json_escape)"
  subject_json="$(printf '%s' "$subject" | json_escape)"
  body_json="$(printf '%s' "$body" | json_escape)"
  handle_json="$(printf '%s' "$sender_token_handle" | json_escape)"
  mode_json="$(printf '%s' "$dry_run" | json_escape)"

  {
    printf 'Agent Mail send_message prepared with redacted token handling\n'
    printf 'project_key=%s\n' "$project_key"
    printf 'sender_name=%s\n' "$sender_name"
    printf 'to=%s\n' "$to"
    printf 'subject=%s\n' "$subject"
    printf 'sender_token_handle=%s\n' "$sender_token_handle"
    printf 'sender_token_value=[REDACTED]\n'
    printf 'dry_run=%s\n' "$dry_run"
  } | redact_stream >"$dir/wrapper.log"

  {
    printf 'Use MCP Agent Mail send_message with these pane-safe arguments:\n'
    printf 'project_key: %s\n' "$project_key"
    printf 'sender_name: %s\n' "$sender_name"
    printf 'to: %s\n' "$to"
    printf 'subject: %s\n' "$subject"
    printf 'body: <provided, %s bytes>\n' "$(printf '%s' "$body" | wc -c | tr -d ' ')"
    printf 'sender_token: [RESOLVED_OUT_OF_BAND_FROM_%s]\n' "$sender_token_handle"
  } | redact_stream >"$dir/dispatch.txt"

  cat >"$dir/pane-visible-tool-call-args.json" <<JSON
{
  "tool": "mcp__mcp-agent-mail__send_message",
  "project_key": "$project_json",
  "sender_name": "$sender_json",
  "to": "$to_json",
  "subject": "$subject_json",
  "body": "$body_json",
  "sender_token_handle": "$handle_json",
  "sender_token": "[REDACTED]",
  "dry_run": "$mode_json"
}
JSON
}

write_register_capture_files() {
  local dir="$1"
  local project_key="$2"
  local agent_name="$3"
  local program="$4"
  local model="$5"
  local task_description="$6"
  local registration_token_handle="$7"
  local dry_run="$8"
  local project_json agent_json program_json model_json task_json handle_json mode_json

  mkdir -p "$dir"
  chmod 700 "$dir"

  project_json="$(printf '%s' "$project_key" | json_escape)"
  agent_json="$(printf '%s' "$agent_name" | json_escape)"
  program_json="$(printf '%s' "$program" | json_escape)"
  model_json="$(printf '%s' "$model" | json_escape)"
  task_json="$(printf '%s' "$task_description" | json_escape)"
  handle_json="$(printf '%s' "$registration_token_handle" | json_escape)"
  mode_json="$(printf '%s' "$dry_run" | json_escape)"

  {
    printf 'Agent Mail register_agent prepared with redacted token handling\n'
    printf 'project_key=%s\n' "$project_key"
    printf 'agent_name=%s\n' "${agent_name:-<auto>}"
    printf 'program=%s\n' "$program"
    printf 'model=%s\n' "$model"
    printf 'registration_token_handle=%s\n' "$registration_token_handle"
    printf 'registration_token_value=[REDACTED]\n'
    printf 'dry_run=%s\n' "$dry_run"
  } | redact_stream >"$dir/wrapper.log"

  {
    printf 'Use MCP Agent Mail register_agent with these pane-safe arguments:\n'
    printf 'project_key: %s\n' "$project_key"
    printf 'agent_name: %s\n' "${agent_name:-<auto>}"
    printf 'program: %s\n' "$program"
    printf 'model: %s\n' "$model"
    printf 'task_description: <provided, %s bytes>\n' "$(printf '%s' "$task_description" | wc -c | tr -d ' ')"
    printf 'registration_token: [RESOLVED_OUT_OF_BAND_FROM_%s]\n' "$registration_token_handle"
  } | redact_stream >"$dir/dispatch.txt"

  cat >"$dir/pane-visible-tool-call-args.json" <<JSON
{
  "tool": "mcp__mcp-agent-mail__register_agent",
  "project_key": "$project_json",
  "agent_name": "$agent_json",
  "program": "$program_json",
  "model": "$model_json",
  "task_description": "$task_json",
  "registration_token_handle": "$handle_json",
  "registration_token": "[REDACTED]",
  "dry_run": "$mode_json"
}
JSON
}

main() {
  local command="${1:-}"
  shift || true

  [[ "$command" == "send_message" || "$command" == "register_agent" ]] || {
    usage >&2
    exit 2
  }

  local project_key=""
  local sender_name=""
  local to=""
  local subject=""
  local body=""
  local body_file=""
  local sender_token_handle="none"
  local registration_token_handle="none"
  local agent_name=""
  local program=""
  local model=""
  local task_description=""
  local capture_dir=""
  local dry_run=0

  while [[ $# -gt 0 ]]; do
    case "$1" in
      --project-key) project_key="${2:?--project-key needs value}"; shift 2 ;;
      --sender-name) sender_name="${2:?--sender-name needs value}"; shift 2 ;;
      --to) to="${2:?--to needs value}"; shift 2 ;;
      --subject) subject="${2:?--subject needs value}"; shift 2 ;;
      --body) body="${2:?--body needs value}"; shift 2 ;;
      --body-file) body_file="${2:?--body-file needs value}"; shift 2 ;;
      --sender-token-handle) sender_token_handle="${2:?--sender-token-handle needs value}"; shift 2 ;;
      --registration-token-handle) registration_token_handle="${2:?--registration-token-handle needs value}"; shift 2 ;;
      --agent-name) agent_name="${2:?--agent-name needs value}"; shift 2 ;;
      --program) program="${2:?--program needs value}"; shift 2 ;;
      --model) model="${2:?--model needs value}"; shift 2 ;;
      --task-description) task_description="${2:?--task-description needs value}"; shift 2 ;;
      --capture-dir) capture_dir="${2:?--capture-dir needs value}"; shift 2 ;;
      --dry-run) dry_run=1; shift ;;
      -h|--help) usage; exit 0 ;;
      *) die "unknown argument: $1" ;;
    esac
  done

  [[ -n "$project_key" ]] || die "--project-key required"

  if [[ -z "$capture_dir" ]]; then
    capture_dir="$(mktemp -d "${TMPDIR:-/tmp}/agent-mail-redacted.XXXXXX")"
  fi

  if [[ "$command" == "send_message" ]]; then
    [[ -n "$sender_name" ]] || die "--sender-name required"
    [[ -n "$to" ]] || die "--to required"
    [[ -n "$subject" ]] || die "--subject required"
    [[ -z "$body" || -z "$body_file" ]] || die "use --body or --body-file, not both"
    if [[ -n "$body_file" ]]; then
      [[ -f "$body_file" ]] || die "body file not found: $body_file"
      body="$(cat "$body_file")"
    fi
    [[ -n "$body" ]] || die "--body or --body-file required"

    require_no_literal_token "sender token handle" "$sender_token_handle"
    resolve_token_handle "$sender_token_handle"

    write_capture_files \
      "$capture_dir" \
      "$project_key" \
      "$sender_name" \
      "$to" \
      "$subject" \
      "$body" \
      "$sender_token_handle" \
      "$dry_run"
  else
    [[ -n "$program" ]] || die "--program required"
    [[ -n "$model" ]] || die "--model required"
    require_no_literal_token "registration token handle" "$registration_token_handle"
    resolve_token_handle "$registration_token_handle"

    write_register_capture_files \
      "$capture_dir" \
      "$project_key" \
      "$agent_name" \
      "$program" \
      "$model" \
      "$task_description" \
      "$registration_token_handle" \
      "$dry_run"
  fi

  printf 'Prepared redacted Agent Mail %s capture: %s\n' "$command" "$capture_dir" | redact_stream

  if [[ "$dry_run" != "1" ]]; then
    printf 'ERROR: live token-bearing MCP invocation is intentionally not shell-rendered; use MCP session auth or future non-rendering bridge.\n' >&2
    exit 2
  fi
}

main "$@"
