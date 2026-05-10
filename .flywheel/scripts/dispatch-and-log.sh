#!/usr/bin/env bash
set -uo pipefail

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

SCAFFOLD_SCHEMA_VERSION="dispatch-and-log/v1"
SCAFFOLD_AUDIT_LOG="${SCAFFOLD_AUDIT_LOG:-$HOME/.local/state/flywheel/dispatch-and-log-runs.jsonl}"

scaffold_usage() {
  cat <<'USG'
usage: dispatch-and-log.sh [SUBCOMMAND] [OPTIONS]

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
    jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" --arg name "dispatch-and-log.sh" \
      '{schema_version:$sv,command:"info",name:$name,helper_lib_missing:true}'
    return 0
  fi
  cli_emit_info \
    "dispatch-and-log.sh" \
    "scaffolded-v0" \
    "$SCAFFOLD_SCHEMA_VERSION" \
    "doctor,health,repair,validate,audit,why,quickstart,help,completion" \
    "SCAFFOLD_AUDIT_LOG" \
    '{}'
}

scaffold_emit_examples() {
  local jsonl
  jsonl="$(jq -nc '{name:"default run",invocation:"dispatch-and-log.sh",purpose:"backward-compatible original behavior"}'
)"$'\n'"$(jq -nc '{name:"doctor",invocation:"dispatch-and-log.sh doctor --json",purpose:"probe substrate health"}'
)"
  if command -v cli_emit_examples >/dev/null; then
    cli_emit_examples "$SCAFFOLD_SCHEMA_VERSION" "$jsonl"
  else
    jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" '{schema_version:$sv,command:"examples",helper_lib_missing:true}'
  fi
}

scaffold_emit_quickstart() {
  local steps
  steps="$(jq -nc '{step:1,action:"probe doctor",command:"dispatch-and-log.sh doctor --json"}'
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
            && cli_emit_completion_bash "dispatch-and-log" "doctor,health,repair,validate,audit,why,quickstart,help,completion" "--json,--apply,--dry-run,--idempotency-key,--info,--schema,--examples" \
            || printf '# helper lib missing — completion unavailable\n' ;;
    zsh)  command -v cli_emit_completion_zsh >/dev/null \
            && cli_emit_completion_zsh "dispatch-and-log" "doctor,health,repair,validate,audit,why,quickstart,help,completion" \
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
SESSION="${SESSION:-flywheel}"
LOG="${FLYWHEEL_DISPATCH_LOG:-/Users/josh/Developer/flywheel/.flywheel/dispatch-log.jsonl}"
NTM="${FLYWHEEL_NTM_BIN:-${NTM:-/Users/josh/.local/bin/ntm}}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO="${FLYWHEEL_REPO:-$(cd "$SCRIPT_DIR/../.." && pwd -P)}"
BUILD_DISPATCH_PACKET="${BUILD_DISPATCH_PACKET:-$SCRIPT_DIR/build-dispatch-packet.sh}"
PANE=""; TASK_FILE=""; TASK_ID=""; BEAD=""; CALLBACK_BY=""; PIPELINE=""; LANE=""
iso_from_epoch() {
  date -u -r "$1" +%Y-%m-%dT%H:%M:%SZ 2>/dev/null ||
    date -u -d "@$1" +%Y-%m-%dT%H:%M:%SZ 2>/dev/null
}
callback_expected_json() {
  local raw="$1" base_epoch="$2" amount unit seconds deadline
  if [[ -z "$raw" ]]; then
    jq -nc '{value:null,input:null,legacy_duration:null,parse_status:"empty"}'; return
  fi
  if [[ "$raw" =~ ^\+([0-9]+)(s|sec|secs|second|seconds|m|min|mins|minute|minutes|h|hr|hrs|hour|hours)$ ]]; then
    amount="${BASH_REMATCH[1]}"; unit="${BASH_REMATCH[2]}"
    case "$unit" in
      s|sec|secs|second|seconds) seconds="$amount" ;;
      m|min|mins|minute|minutes) seconds=$((amount * 60)) ;;
      h|hr|hrs|hour|hours) seconds=$((amount * 3600)) ;;
    esac
    if deadline="$(iso_from_epoch "$((base_epoch + seconds))")"; then
      jq -nc --arg value "$deadline" --arg input "$raw" '{value:$value,input:$input,legacy_duration:$input,parse_status:"duration"}'
    else
      jq -nc --arg input "$raw" '{value:null,input:$input,legacy_duration:$input,parse_status:"unknown"}'
    fi; return
  fi
  if [[ "$raw" =~ ^[0-9]{4}-[0-9]{2}-[0-9]{2}T[0-9]{2}:[0-9]{2}:[0-9]{2}Z$ ]]; then
    jq -nc --arg value "$raw" '{value:$value,input:$value,legacy_duration:null,parse_status:"absolute"}'; return
  fi
  jq -nc --arg input "$raw" '{value:null,input:$input,legacy_duration:null,parse_status:"unknown"}'
}
json_attempt() {
  local label="$1"; shift
  local out rc
  out="$("$@" 2>&1)"; rc=$?
  if [[ $rc -eq 0 ]] && jq -e . >/dev/null 2>&1 <<<"$out"; then
    jq -nc --arg label "$label" --argjson data "$(jq -c . <<<"$out")" '{command:$label,success:true,json:$data,raw:null,rc:0}'
  elif [[ $rc -eq 0 ]]; then
    jq -nc --arg label "$label" --arg raw "$out" '{command:$label,success:true,json:null,raw:$raw,rc:0}'
  else
    jq -nc --arg label "$label" --arg raw "$out" --argjson rc "$rc" '{command:$label,success:false,json:null,raw:$raw,rc:$rc}'
  fi
}
while [[ $# -gt 0 ]]; do
  case "$1" in
    --pane=*) PANE="${1#*=}" ;;
    --task-file=*) TASK_FILE="${1#*=}" ;;
    --task-id=*) TASK_ID="${1#*=}" ;;
    --bead=*) BEAD="${1#*=}" ;;
    --callback-by=*) CALLBACK_BY="${1#*=}" ;;
    --pipeline=*) PIPELINE="${1#*=}" ;;
    --lane=*) LANE="${1#*=}" ;;
    --session=*) SESSION="${1#*=}" ;;
    *) echo "unknown arg: $1" >&2; exit 2 ;;
  esac; shift
done
if [[ -z "$PANE" || -z "$TASK_FILE" || -z "$TASK_ID" ]]; then
  echo "required: --pane=N --task-file=PATH --task-id=ID" >&2
  exit 2
fi
[[ -f "$TASK_FILE" ]] || { echo "task file does not exist: $TASK_FILE" >&2; exit 3; }
TS_EPOCH="${FLYWHEEL_DISPATCH_AND_LOG_NOW_EPOCH:-$(date -u +%s)}"
TS="$(iso_from_epoch "$TS_EPOCH")" || { echo "could not compute dispatch timestamp" >&2; exit 5; }
CALLBACK_EXPECTED="$(callback_expected_json "$CALLBACK_BY" "$TS_EPOCH")"
SEND_FILE="$TASK_FILE"
PACKET_JSON="$(jq -nc '{status:"not_applicable",packet_path:null,packet_sha256:null,validation_status:null}')"
if [[ -n "$BEAD" ]]; then
  PACKET_OUT="$("$BUILD_DISPATCH_PACKET" --bead-id "$BEAD" --target-pane "$PANE" --target-session "$SESSION" --task-id "$TASK_ID" --apply --json 2>&1)"
  PACKET_RC=$?
  [[ $PACKET_RC -eq 0 ]] || { echo "build-dispatch-packet failed (rc=$PACKET_RC): $PACKET_OUT" >&2; exit 6; }
  jq -e '.validation_status == "pass" and (.packet_path | type == "string")' >/dev/null 2>&1 <<<"$PACKET_OUT" ||
    { echo "build-dispatch-packet returned invalid packet json: $PACKET_OUT" >&2; exit 7; }
  PACKET_JSON="$(jq -c . <<<"$PACKET_OUT")"
  SEND_FILE="$(jq -r '.packet_path' <<<"$PACKET_JSON")"
fi
if [[ -n "$BEAD" ]]; then
  ASSIGN_JSON="$(json_attempt "ntm assign" "$NTM" assign "$SESSION" --repo "$REPO" --pane="$PANE" --beads="$BEAD" --prompt="$TASK_ID" --dry-run --json)"
else
  ASSIGN_JSON="$(json_attempt "ntm assign" "$NTM" assign "$SESSION" --repo "$REPO" --dry-run --limit=1 --json)"
fi
SEND_JSON="$(json_attempt "ntm send" "$NTM" send "$SESSION" --pane="$PANE" --no-cass-check --file="$SEND_FILE" --json)"
if ! jq -e '.success == true' >/dev/null <<<"$SEND_JSON"; then
  echo "ntm send failed: $(jq -r '.raw' <<<"$SEND_JSON")" >&2
  exit 4
fi
HISTORY_JSON="$(json_attempt "ntm history" "$NTM" history --session="$SESSION" --search="$TASK_ID" --limit=5 --json)"
HISTORY_COUNT="$(jq -r 'if .success and (.json|type) == "array" then (.json|length) elif .success then 1 else 0 end' <<<"$HISTORY_JSON")"
ROW="$(jq -nc \
  --arg ts "$TS" --arg session "$SESSION" --arg task_id "$TASK_ID" --arg pane "$PANE" \
  --arg task_file "$TASK_FILE" --arg bead "$BEAD" --arg pipeline "$PIPELINE" --arg lane "$LANE" \
  --argjson callback "$CALLBACK_EXPECTED" --argjson packet "$PACKET_JSON" \
  --argjson assign "$ASSIGN_JSON" --argjson send "$SEND_JSON" --argjson history "$HISTORY_JSON" --argjson history_count "$HISTORY_COUNT" \
  '{ts:$ts,session:$session,task_id:$task_id,pane:($pane|tonumber),task_file:$task_file,channel:"ntm",pane_state_source:"ntm_send",pane_state:"sent",native_assignment:$assign,native_send:$send,native_history:$history,history_entry_count:$history_count,canonical_packet:$packet,packet_path:$packet.packet_path,packet_sha256:$packet.packet_sha256,packet_validation_status:$packet.validation_status,bead:(if $bead == "" then null else $bead end),callback_expected_by:$callback.value,callback_expected_by_input:$callback.input,callback_expected_by_legacy_duration:$callback.legacy_duration,callback_expected_by_parse_status:$callback.parse_status,pipeline_slug:(if $pipeline == "" then null else $pipeline end),lane:(if $lane == "" then null else $lane end)}')"
printf '%s\n' "$ROW" >>"$LOG"
BEAD_RESULT="skipped"
if [[ -n "$BEAD" ]]; then
  br update "$BEAD" --status=in_progress >/dev/null 2>&1 && BEAD_RESULT="in_progress" || BEAD_RESULT="claim_blocked"
fi
jq -nc \
  --arg ts "$TS" --arg task_id "$TASK_ID" --arg pane "$PANE" --arg bead_status "$BEAD_RESULT" \
  --argjson packet "$PACKET_JSON" --argjson assign "$ASSIGN_JSON" --argjson send "$SEND_JSON" \
  --argjson history "$HISTORY_JSON" --argjson history_count "$HISTORY_COUNT" \
  '{ts:$ts,task_id:$task_id,pane:($pane|tonumber),ntm_sent:($send.success == true),log_appended:true,bead_status:$bead_status,packet_path:$packet.packet_path,packet_validation_status:$packet.validation_status,native_assign_success:($assign.success == true),native_send_success:($send.success == true),native_history_success:($history.success == true),history_entry_count:$history_count}'
