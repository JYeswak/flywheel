#!/usr/bin/env bash
set -euo pipefail


# ====== BEGIN canonical-cli scaffold (bead flywheel-ws02m) ======
# flywheel-cli-surface: true
# canonical-cli-scoping: passing (TODO markers in stubs need fill-in)
# doctor-mode-tier: scaffolded (bead flywheel-ws02m)
#
# This block is APPENDED by scaffold-canonical-cli.sh. The original
# top-level dispatch is preserved as `cmd_run` (the new main routes
# default invocation through cmd_run for backward compat). Surface-
# specific logic stays as TODO markers — see grep '# TODO(canonical-cli-scaffold)'.

_SCAFFOLD_REPO_ROOT="${_SCAFFOLD_REPO_ROOT:-$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd -P)}"
_SCAFFOLD_HELPER_LIB="${_SCAFFOLD_HELPER_LIB:-$_SCAFFOLD_REPO_ROOT/.flywheel/lib/canonical-cli-helpers.sh}"
if [[ -r "$_SCAFFOLD_HELPER_LIB" ]]; then
  # shellcheck source=/dev/null
  source "$_SCAFFOLD_HELPER_LIB"
fi

SCAFFOLD_SCHEMA_VERSION="agent-mail-send-redacted/v1"
SCAFFOLD_AUDIT_LOG="${SCAFFOLD_AUDIT_LOG:-$HOME/.local/state/flywheel/agent-mail-send-redacted-runs.jsonl}"

scaffold_usage() {
  cat <<'USG'
usage: agent-mail-send-redacted.sh [SUBCOMMAND] [OPTIONS]

Backward-compatible run mode: default invocation routes to the original
top-level logic (now exposed as `cmd_run`).

Canonical CLI surfaces:
  doctor [--json]          probe substrate health
  health [--json]          last-run status
  repair --scope <s>       repair misconfigured state
                            Default: --dry-run; mutate with --apply --idempotency-key KEY
  validate <subject> [...] validate per-subject contract (TODO: define subjects)
  audit [--json]           recent run history
  why <id>                 explain provenance for a given id (TODO: id semantics)
  quickstart [--json]      operator orientation
  help <topic>             topic help (run | doctor | health | repair | validate)
  completion <shell>       emit bash or zsh completion

Introspection:
  --info --json            version, paths, env vars, dependencies, sha256
  --schema [<surface>]     JSON Schema for output envelopes
  --examples --json        curated workflow examples
  --help / -h              this help
USG
}

scaffold_emit_info() {
  if ! command -v cli_emit_info >/dev/null; then
    jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" --arg name "agent-mail-send-redacted.sh" \
      '{schema_version:$sv,command:"info",name:$name,helper_lib_missing:true}'
    return 0
  fi
  cli_emit_info \
    "agent-mail-send-redacted.sh" \
    "scaffolded-v0" \
    "$SCAFFOLD_SCHEMA_VERSION" \
    "doctor,health,repair,validate,audit,why,quickstart,help,completion" \
    "SCAFFOLD_AUDIT_LOG" \
    '{}'
}

scaffold_emit_examples() {
  local jsonl
  jsonl="$(jq -nc '{name:"default run",invocation:"agent-mail-send-redacted.sh",purpose:"backward-compatible original behavior"}'
)"$'\n'"$(jq -nc '{name:"doctor",invocation:"agent-mail-send-redacted.sh doctor --json",purpose:"probe substrate health"}'
)"
  if command -v cli_emit_examples >/dev/null; then
    cli_emit_examples "$SCAFFOLD_SCHEMA_VERSION" "$jsonl"
  else
    jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" '{schema_version:$sv,command:"examples",helper_lib_missing:true}'
  fi
}

scaffold_emit_quickstart() {
  local steps
  steps="$(jq -nc '{step:1,action:"probe doctor",command:"agent-mail-send-redacted.sh doctor --json"}'
)"
  if command -v cli_emit_quickstart >/dev/null; then
    cli_emit_quickstart "$SCAFFOLD_SCHEMA_VERSION" "$steps" "doctor,health,repair"
  else
    jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" '{schema_version:$sv,command:"quickstart",helper_lib_missing:true}'
  fi
}

scaffold_emit_schema() {
  local surface="${1:-default}"
  jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" --arg surface "$surface" \
    '{schema_version:$sv,command:"schema",surface:$surface,note:"TODO(canonical-cli-scaffold): per-surface schema fill-in"}'
}

scaffold_emit_topic_help() {
  local topic="${1:-}"
  case "$topic" in
    run)      printf 'topic: run — default backward-compatible invocation routes to cmd_run.\n' ;;
    doctor)   printf 'topic: doctor — TODO(canonical-cli-scaffold): document doctor checks specific to this surface.\n' ;;
    health)   printf 'topic: health — TODO(canonical-cli-scaffold): document health probes specific to this surface.\n' ;;
    repair)   printf 'topic: repair — TODO(canonical-cli-scaffold): document repair scopes + idempotency contract.\n' ;;
    validate) printf 'topic: validate — TODO(canonical-cli-scaffold): document validation subjects + contracts.\n' ;;
    *)        printf 'topics: run | doctor | health | repair | validate\n' ;;
  esac
}

scaffold_emit_completion() {
  local shell="${1:-bash}"
  case "$shell" in
    -h|--help) scaffold_emit_topic_help completion 2>/dev/null \
                 || printf 'topic: completion <bash|zsh> — emit shell completion script\n'
               return 0 ;;
    bash) command -v cli_emit_completion_bash >/dev/null \
            && cli_emit_completion_bash "agent-mail-send-redacted" "doctor,health,repair,validate,audit,why,quickstart,help,completion" "--json,--apply,--dry-run,--idempotency-key,--info,--schema,--examples" \
            || printf '# helper lib missing — completion unavailable\n' ;;
    zsh)  command -v cli_emit_completion_zsh >/dev/null \
            && cli_emit_completion_zsh "agent-mail-send-redacted" "doctor,health,repair,validate,audit,why,quickstart,help,completion" \
            || printf '# helper lib missing — completion unavailable\n' ;;
    *) printf 'ERR: unknown shell %s (use bash|zsh)\n' "$shell" >&2; return 64 ;;
  esac
}

# ---------- canonical-cli stubs (TODO markers preserved) ----------

scaffold_cmd_doctor() {
  # TODO(canonical-cli-scaffold): probe substrate this script depends on
  # (env vars, paths, external tools) and emit per-check status.
  jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" --arg ts "$(iso_now 2>/dev/null || date -u +%Y-%m-%dT%H:%M:%SZ)" \
    '{schema_version:$sv,command:"doctor",ts:$ts,status:"todo",checks:[],note:"TODO(canonical-cli-scaffold): fill in doctor checks"}'
}

scaffold_cmd_health() {
  # TODO(canonical-cli-scaffold): summarize last-run state from audit log.
  jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" --arg ts "$(iso_now 2>/dev/null || date -u +%Y-%m-%dT%H:%M:%SZ)" \
    '{schema_version:$sv,command:"health",ts:$ts,status:"todo",note:"TODO(canonical-cli-scaffold): fill in health probe from audit log"}'
}

scaffold_cmd_repair() {
  local scope="" mode="dry_run" idem_key=""
  while [[ $# -gt 0 ]]; do
    case "$1" in
      -h|--help) scaffold_emit_topic_help repair; return 0 ;;
      --scope) scope="${2:-}"; shift 2 ;;
      --dry-run) mode="dry_run"; shift ;;
      --apply) mode="apply"; shift ;;
      --idempotency-key) idem_key="${2:-}"; shift 2 ;;
      --idempotency-key=*) idem_key="${1#--idempotency-key=}"; shift ;;
      --json) shift ;;
      *) printf 'ERR: unknown repair arg %s\n' "$1" >&2; return 64 ;;
    esac
  done
  if [[ "$mode" == "apply" && -z "$idem_key" ]]; then
    if command -v cli_refuse_apply_without_idem_key >/dev/null; then
      cli_refuse_apply_without_idem_key "$SCAFFOLD_SCHEMA_VERSION" "repair" "$scope"
    else
      jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" --arg scope "$scope" \
        '{schema_version:$sv,command:"repair",status:"refused",mode:"apply",scope:$scope,reason:"--apply requires --idempotency-key"}'
      exit 3
    fi
  fi
  # TODO(canonical-cli-scaffold): per-scope repair actions go here.
  jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" --arg scope "$scope" --arg mode "$mode" --arg idem "$idem_key" \
    '{schema_version:$sv,command:"repair",status:"todo",mode:$mode,scope:$scope,idempotency_key:$idem,note:"TODO(canonical-cli-scaffold): fill in repair scope actions"}'
}

scaffold_cmd_validate() {
  # TODO(canonical-cli-scaffold): document validation subjects + contracts.
  jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" \
    '{schema_version:$sv,command:"validate",status:"todo",note:"TODO(canonical-cli-scaffold): fill in per-subject validation"}'
}

scaffold_cmd_audit() {
  # TODO(canonical-cli-scaffold): tail audit log; emit recent rows.
  jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" --arg log "$SCAFFOLD_AUDIT_LOG" \
    '{schema_version:$sv,command:"audit",audit_log:$log,status:"todo",note:"TODO(canonical-cli-scaffold): fill in audit tail"}'
}

scaffold_cmd_why() {
  local id="${1:-}"
  if [[ -z "$id" ]]; then
    printf 'ERR: why requires <id> argument\n' >&2; return 64
  fi
  # TODO(canonical-cli-scaffold): explain why <id> is/isn't in scope.
  jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" --arg id "$id" \
    '{schema_version:$sv,command:"why",id:$id,status:"todo",note:"TODO(canonical-cli-scaffold): fill in why-id semantics"}'
}

# ---------- scaffolded main dispatcher ----------

# When the scaffolder appends this block, it expects the target's original
# top-level main is renamed to `cmd_run` (or the original final
# `main "$@"` line is replaced with this dispatcher). Default invocation
# falls through to the original logic for backward compat.
scaffold_main() {
  if [[ $# -eq 0 ]]; then
    scaffold_usage; exit 0
  fi
  case "$1" in
    -h|--help)    scaffold_usage; exit 0 ;;
    --info)       shift; scaffold_emit_info "$@"; exit 0 ;;
    --schema)     shift; scaffold_emit_schema "${1:-default}"; exit 0 ;;
    --examples)   shift; scaffold_emit_examples "$@"; exit 0 ;;
    doctor)       shift; scaffold_cmd_doctor "$@"; exit $? ;;
    health)       shift; scaffold_cmd_health "$@"; exit $? ;;
    repair)       shift; scaffold_cmd_repair "$@"; exit $? ;;
    validate)     shift; scaffold_cmd_validate "$@"; exit $? ;;
    audit)        shift; scaffold_cmd_audit "$@"; exit $? ;;
    why)          shift; scaffold_cmd_why "$@"; exit $? ;;
    quickstart)   shift; scaffold_emit_quickstart "$@"; exit 0 ;;
    help)         shift; scaffold_emit_topic_help "${1:-}"; exit 0 ;;
    completion)   shift; scaffold_emit_completion "${1:-bash}"; exit $? ;;
    *)
      printf 'ERR: unknown canonical subcommand: %s\n' "$1" >&2
      scaffold_usage >&2
      exit 64 ;;
  esac
}

# Early-dispatch intercept: if argv[0] looks like a canonical subcommand
# or introspection flag, run the canonical surface and exit BEFORE the
# target's original arg parser sees the args. Works for both `main "$@"`
# style and inline `while [[ $# -gt 0 ]]` style targets.
_scaffold_is_canonical_arg() {
  case "${1:-}" in
    doctor|health|repair|validate|audit|why|quickstart|completion) return 0 ;;
    --info|--schema|--examples) return 0 ;;
    -h|--help) return 0 ;;
    help)
      # Intercept `help <topic>` and `help --help`; bare `help` could be
      # a legacy subcommand of the target so it falls through.
      case "${2:-}" in run|doctor|health|repair|validate|audit|why|-h|--help) return 0 ;; esac
      return 1 ;;
    *) return 1 ;;
  esac
}

if [[ $# -gt 0 ]] && _scaffold_is_canonical_arg "$@"; then
  scaffold_main "$@"
  exit $?
fi
# ====== END canonical-cli scaffold ======
NTM="${AGENT_MAIL_SEND_REDACTED_NTM_BIN:-/Users/josh/.local/bin/ntm}"
AGENT_MAIL_REDACT_TMP_FILES=()

cleanup_redact_tmp_files(){
  local tmp_file
  for tmp_file in "${AGENT_MAIL_REDACT_TMP_FILES[@]}"; do
    [[ -n "$tmp_file" ]] && rm -f "$tmp_file"
  done
}
trap cleanup_redact_tmp_files EXIT ERR

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
  tmp="$(mktemp "${TMPDIR:-/tmp}/agent-mail-redact-input.XXXXXX")"
  AGENT_MAIL_REDACT_TMP_FILES+=("$tmp")
  chmod 600 "$tmp"
  printf '%s' "$text" >"$tmp"
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
