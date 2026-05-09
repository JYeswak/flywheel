#!/usr/bin/env bash
set -euo pipefail

NTM="${AGENT_MAIL_SEND_REDACTED_NTM_BIN:-/Users/josh/.local/bin/ntm}"

usage(){ printf '%s\n' \
  'Usage:' \
  '  agent-mail-send-redacted.sh send_message --project-key PATH --sender-name AGENT --to AGENT[,AGENT...] --subject TEXT (--body TEXT|--body-file PATH) [--sender-token-handle vault:AGENT|env:VAR|none] [--capture-dir DIR] [--dry-run]' \
  '  agent-mail-send-redacted.sh register_agent --project-key PATH --program PROGRAM --model MODEL [--agent-name AGENT] [--task-description TEXT] [--registration-token-handle vault:AGENT|env:VAR|none] [--capture-dir DIR] [--dry-run]'; }
die(){ printf 'ERROR: %s\n' "$*" >&2; exit 1; }
need(){ command -v "$1" >/dev/null 2>&1 || die "$1 is required"; }

reject_literal_token(){
  local label="$1" value="$2"
  case "$value" in
    FAKE_AGENT_MAIL_TOKEN_*|*registration_token=*|*sender_token=*|Bearer\ *) die "$label contains token-shaped text; pass a handle" ;;
  esac
  if printf '%s' "$value" | grep -Eq '^[A-Za-z0-9_=-]{32,}$'; then
    die "$label looks like token material; pass vault:<agent> or env:<VAR>"
  fi
}

resolve_handle(){
  local handle="${1:-none}" vault="${AGENT_MAIL_TOKEN_VAULT_DIR:-$HOME/.local/state/flywheel/fleet-mail-tokens}" name var file token
  reject_literal_token "token handle" "$handle"
  case "$handle" in
    none|"") return 0 ;;
    vault:*) name="${handle#vault:}"; name="${name%%:*}"; reject_literal_token "vault handle" "$name"; file="$vault/${name}.token"; [[ -f "$file" ]] || die "token handle not found"; token="$(<"$file")"; [[ -n "$token" ]] || die "token handle is empty" ;;
    env:*) var="${handle#env:}"; reject_literal_token "env handle" "$var"; [[ "$var" =~ ^[A-Za-z_][A-Za-z0-9_]*$ ]] || die "invalid env handle name"; token="${!var:-}"; [[ -n "$token" ]] || die "token handle env var is unset or empty" ;;
    *) die "unsupported token handle; use vault:<agent>, env:<VAR>, or none" ;;
  esac
}

scrub_text(){
  perl -0pe 's/FAKE_AGENT_MAIL_TOKEN_[A-Za-z0-9_=-]+/[REDACTED_TOKEN]/g; s/Bearer[[:space:]]+[A-Za-z0-9._=-]+/Bearer [REDACTED]/g; s/sk-ant-[A-Za-z0-9_-]+/[REDACTED_TOKEN]/g; s/sk-(proj-)?[A-Za-z0-9_-]{16,}/[REDACTED_TOKEN]/g; s/github_pat_[A-Za-z0-9_]+/[REDACTED_TOKEN]/g; s/gh[pousr]_[A-Za-z0-9_]{20,}/[REDACTED_TOKEN]/g; s/(AKIA|ASIA)[A-Z0-9]{16}/[REDACTED_TOKEN]/g; s/AIza[A-Za-z0-9_-]{35}/[REDACTED_TOKEN]/g; s/xox[abprs]-[A-Za-z0-9-]+/[REDACTED_TOKEN]/g; s/eyJ[A-Za-z0-9_-]+\.[A-Za-z0-9_-]+\.[A-Za-z0-9_-]+/[REDACTED_TOKEN]/g; s/((registration|sender)_token|token|secret|password|api[_-]?key)(["'\''[:space:]]*[:=]["'\''[:space:]]*)[A-Za-z0-9._\/+=:-]{8,}/$1$3[REDACTED_TOKEN]/gi; s/\b[A-Za-z0-9_=-]{40,}\b/[REDACTED_TOKEN]/g;'
}

redact_text(){
  local text="$1" tmp out
  need jq; need perl
  tmp="$(mktemp "${TMPDIR:-/tmp}/agent-mail-redact-input.XXXXXX")"; chmod 600 "$tmp"; printf '%s' "$text" >"$tmp"
  if ! out="$("$NTM" redact preview --json --file "$tmp" | jq -r '.output')"; then rm -f "$tmp"; return 1; fi
  rm -f "$tmp"
  printf '%s' "$out" | scrub_text
}

write_send_capture(){
  local dir="$1" project="$2" sender="$3" to="$4" subject="$5" body="$6" handle="$7" dry="$8" redacted_body
  redacted_body="$(redact_text "$body")"
  mkdir -p "$dir"; chmod 700 "$dir"
  redact_text "$(printf 'Agent Mail send_message prepared via ntm mail+redact\nproject_key=%s\nsender_name=%s\nto=%s\nsubject=%s\nsender_token_handle=%s\nsender_token_value=[REDACTED]\ndry_run=%s\n' "$project" "$sender" "$to" "$subject" "$handle" "$dry")" >"$dir/wrapper.log"
  redact_text "$(printf 'Use ntm mail send --json with this scrubbed body:\nproject_key: %s\nsender_name: %s\nto: %s\nsubject: %s\nbody: %s\nsender_token: [RESOLVED_OUT_OF_BAND_FROM_%s]\n' "$project" "$sender" "$to" "$subject" "$redacted_body" "$handle")" >"$dir/dispatch.txt"
  jq -n --arg project_key "$project" --arg sender_name "$sender" --arg to "$to" --arg subject "$subject" --arg body "$redacted_body" --arg handle "$handle" --arg dry_run "$dry" '{tool:"ntm mail send --json",project_key:$project_key,sender_name:$sender_name,to:$to,subject:$subject,body:$body,sender_token_handle:$handle,sender_token:"[REDACTED]",dry_run:$dry_run}' >"$dir/pane-visible-tool-call-args.json"
}

write_register_capture(){
  local dir="$1" project="$2" agent="$3" program="$4" model="$5" task="$6" handle="$7" dry="$8"
  mkdir -p "$dir"; chmod 700 "$dir"
  redact_text "$(printf 'Agent Mail register_agent prepared with redacted token handling\nproject_key=%s\nagent_name=%s\nprogram=%s\nmodel=%s\nregistration_token_handle=%s\nregistration_token_value=[REDACTED]\ndry_run=%s\n' "$project" "${agent:-<auto>}" "$program" "$model" "$handle" "$dry")" >"$dir/wrapper.log"
  redact_text "$(printf 'Use MCP Agent Mail register_agent with pane-safe arguments:\nproject_key: %s\nagent_name: %s\nprogram: %s\nmodel: %s\ntask_description: <provided, %s bytes>\nregistration_token: [RESOLVED_OUT_OF_BAND_FROM_%s]\n' "$project" "${agent:-<auto>}" "$program" "$model" "$(printf '%s' "$task" | wc -c | tr -d ' ')" "$handle")" >"$dir/dispatch.txt"
  jq -n --arg project_key "$project" --arg agent_name "$agent" --arg program "$program" --arg model "$model" --arg task_description "$task" --arg handle "$handle" --arg dry_run "$dry" '{tool:"mcp__mcp-agent-mail__register_agent",project_key:$project_key,agent_name:$agent_name,program:$program,model:$model,task_description:$task_description,registration_token_handle:$handle,registration_token:"[REDACTED]",dry_run:$dry_run}' >"$dir/pane-visible-tool-call-args.json"
}

send_live(){ local project="$1" to="$2" subject="$3" body="$4" recipients=() args=(); IFS=, read -ra recipients <<<"$to"; args=(mail send "$project" --json --subject "$subject"); for recipient in "${recipients[@]}"; do args+=(--to "$recipient"); done; "$NTM" "${args[@]}" "$body"; }

cmd="${1:-}"; shift || true
[[ "$cmd" == send_message || "$cmd" == register_agent || "$cmd" == -h || "$cmd" == --help ]] || { usage >&2; exit 2; }
[[ "$cmd" == -h || "$cmd" == --help ]] && { usage; exit 0; }
project=""; sender=""; to=""; subject=""; body=""; body_file=""; sender_handle="none"; reg_handle="none"; agent=""; program=""; model=""; task=""; capture=""; dry=0
while [[ $# -gt 0 ]]; do case "$1" in
  --project-key) project="${2:?}"; shift 2;; --sender-name) sender="${2:?}"; shift 2;; --to) to="${2:?}"; shift 2;; --subject) subject="${2:?}"; shift 2;;
  --body) body="${2:?}"; shift 2;; --body-file) body_file="${2:?}"; shift 2;; --sender-token-handle) sender_handle="${2:?}"; shift 2;;
  --registration-token-handle) reg_handle="${2:?}"; shift 2;; --agent-name) agent="${2:?}"; shift 2;; --program) program="${2:?}"; shift 2;; --model) model="${2:?}"; shift 2;;
  --task-description) task="${2:?}"; shift 2;; --capture-dir) capture="${2:?}"; shift 2;; --dry-run) dry=1; shift;; -h|--help) usage; exit 0;; *) die "unknown argument" ;;
esac; done

[[ -n "$project" ]] || die "--project-key required"
[[ -n "$capture" ]] || capture="$(mktemp -d "${TMPDIR:-/tmp}/agent-mail-redacted.XXXXXX")"

if [[ "$cmd" == send_message ]]; then
  [[ -n "$sender" && -n "$to" && -n "$subject" ]] || die "--sender-name, --to, and --subject required"
  [[ -z "$body" || -z "$body_file" ]] || die "use --body or --body-file, not both"
  [[ -n "$body_file" ]] && { [[ -f "$body_file" ]] || die "body file not found"; body="$(<"$body_file")"; }
  [[ -n "$body" ]] || die "--body or --body-file required"
  resolve_handle "$sender_handle"
  write_send_capture "$capture" "$project" "$sender" "$to" "$subject" "$body" "$sender_handle" "$dry"
  redact_text "$(printf 'Prepared redacted Agent Mail send_message capture: %s\n' "$capture")"
  [[ "$dry" == 1 ]] || send_live "$project" "$to" "$subject" "$(jq -r '.body' "$capture/pane-visible-tool-call-args.json")"
else
  [[ -n "$program" && -n "$model" ]] || die "--program and --model required"
  resolve_handle "$reg_handle"
  write_register_capture "$capture" "$project" "$agent" "$program" "$model" "$task" "$reg_handle" "$dry"
  redact_text "$(printf 'Prepared redacted Agent Mail register_agent capture: %s\n' "$capture")"
  [[ "$dry" == 1 ]] || { printf 'ERROR: ntm mail has no register_agent apply surface; use the captured MCP register_agent arguments.\n' >&2; exit 2; }
fi
