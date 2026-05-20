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

SCAFFOLD_SCHEMA_VERSION="handoff-skill-to-skillos/v1"
SCAFFOLD_AUDIT_LOG="${SCAFFOLD_AUDIT_LOG:-$HOME/.local/state/flywheel/handoff-skill-to-skillos-runs.jsonl}"

scaffold_usage() {
  cat <<'USG'
usage: handoff-skill-to-skillos.sh [SUBCOMMAND] [OPTIONS]

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
    jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" --arg name "handoff-skill-to-skillos.sh" \
      '{schema_version:$sv,command:"info",name:$name,helper_lib_missing:true}'
    return 0
  fi
  cli_emit_info \
    "handoff-skill-to-skillos.sh" \
    "scaffolded-v0" \
    "$SCAFFOLD_SCHEMA_VERSION" \
    "doctor,health,repair,validate,audit,why,quickstart,help,completion" \
    "SCAFFOLD_AUDIT_LOG" \
    '{}'
}

scaffold_emit_examples() {
  local jsonl
  jsonl="$(jq -nc '{name:"default run",invocation:"handoff-skill-to-skillos.sh",purpose:"backward-compatible original behavior"}'
)"$'\n'"$(jq -nc '{name:"doctor",invocation:"handoff-skill-to-skillos.sh doctor --json",purpose:"probe substrate health"}'
)"
  if command -v cli_emit_examples >/dev/null; then
    cli_emit_examples "$SCAFFOLD_SCHEMA_VERSION" "$jsonl"
  else
    jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" '{schema_version:$sv,command:"examples",helper_lib_missing:true}'
  fi
}

scaffold_emit_quickstart() {
  local steps
  steps="$(jq -nc '{step:1,action:"probe doctor",command:"handoff-skill-to-skillos.sh doctor --json"}'
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
            && cli_emit_completion_bash "handoff-skill-to-skillos" "doctor,health,repair,validate,audit,why,quickstart,help,completion" "--json,--apply,--dry-run,--idempotency-key,--info,--schema,--examples" \
            || printf '# helper lib missing — completion unavailable\n' ;;
    zsh)  command -v cli_emit_completion_zsh >/dev/null \
            && cli_emit_completion_zsh "handoff-skill-to-skillos" "doctor,health,repair,validate,audit,why,quickstart,help,completion" \
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

# Meta-Learning Cross-References (2026-05-19)
# Batch-16 comment backfill; citations are documentation-only and do not alter runtime behavior.
# Related: `/Users/josh/Developer/skillos/.flywheel/doctrine/meta-learnings/MP-03-agent-ergonomics-rubric.md`
# Related: `/Users/josh/Developer/skillos/.flywheel/doctrine/meta-learnings/MP-58-agent-tool-theory-of-mind.md`
