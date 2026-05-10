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

SCAFFOLD_SCHEMA_VERSION="dispatch-delivery-verify/v1"
SCAFFOLD_AUDIT_LOG="${SCAFFOLD_AUDIT_LOG:-$HOME/.local/state/flywheel/dispatch-delivery-verify-runs.jsonl}"

scaffold_usage() {
  cat <<'USG'
usage: dispatch-delivery-verify.sh [SUBCOMMAND] [OPTIONS]

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
    jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" --arg name "dispatch-delivery-verify.sh" \
      '{schema_version:$sv,command:"info",name:$name,helper_lib_missing:true}'
    return 0
  fi
  cli_emit_info \
    "dispatch-delivery-verify.sh" \
    "scaffolded-v0" \
    "$SCAFFOLD_SCHEMA_VERSION" \
    "doctor,health,repair,validate,audit,why,quickstart,help,completion" \
    "SCAFFOLD_AUDIT_LOG" \
    '{}'
}

scaffold_emit_examples() {
  local jsonl
  jsonl="$(jq -nc '{name:"default run",invocation:"dispatch-delivery-verify.sh",purpose:"backward-compatible original behavior"}'
)"$'\n'"$(jq -nc '{name:"doctor",invocation:"dispatch-delivery-verify.sh doctor --json",purpose:"probe substrate health"}'
)"
  if command -v cli_emit_examples >/dev/null; then
    cli_emit_examples "$SCAFFOLD_SCHEMA_VERSION" "$jsonl"
  else
    jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" '{schema_version:$sv,command:"examples",helper_lib_missing:true}'
  fi
}

scaffold_emit_quickstart() {
  local steps
  steps="$(jq -nc '{step:1,action:"probe doctor",command:"dispatch-delivery-verify.sh doctor --json"}'
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
            && cli_emit_completion_bash "dispatch-delivery-verify" "doctor,health,repair,validate,audit,why,quickstart,help,completion" "--json,--apply,--dry-run,--idempotency-key,--info,--schema,--examples" \
            || printf '# helper lib missing — completion unavailable\n' ;;
    zsh)  command -v cli_emit_completion_zsh >/dev/null \
            && cli_emit_completion_zsh "dispatch-delivery-verify" "doctor,health,repair,validate,audit,why,quickstart,help,completion" \
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
VERSION="dispatch-delivery-verify/v1"
NTM="${DISPATCH_DELIVERY_VERIFY_NTM:-/Users/josh/.local/bin/ntm}"
LEDGER="${DISPATCH_DELIVERY_VERIFY_LEDGER:-$HOME/.local/state/flywheel/dispatch-delivery-verify-ledger.jsonl}"
FUCKUP_LOG="${DISPATCH_DELIVERY_VERIFY_FUCKUP_LOG:-$HOME/.local/state/flywheel/fuckup-log.jsonl}"
SESSION=""; PANE=""; TASK_ID=""; TIMEOUT_SEC=10; JSON_OUT=0

usage(){ printf '%s\n' \
  'Usage: dispatch-delivery-verify.sh --session NAME --pane N --task-id ID [--timeout-sec 10] [--json]' \
  'Verifies L91 delivery via ntm history + ntm activity; no scrollback capture.'; }
examples(){ printf '%s\n' 'dispatch-delivery-verify.sh --session flywheel --pane 2 --task-id ntm-wire-in-123 --json'; }
now_iso(){ date -u +%Y-%m-%dT%H:%M:%SZ; }
tail_text(){ printf '%s' "$1" | tail -c 2000; }

info(){
  jq -nc --arg schema "$VERSION" --arg ntm "$NTM" --arg ledger "$LEDGER" \
    '{schema_version:$schema,command:"dispatch-delivery-verify.sh",ntm:$ntm,ledger:$ledger,native_surfaces:["ntm changes --json","ntm conflicts --json","ntm history --json","ntm activity --json"],output_schema:".flywheel/validation-schema/v1/dispatch-delivery-verify.schema.json",exit_codes:{"0":"verified","1":"not verified / fail closed","2":"usage"}}'
}

append_jsonl(){ local path="$1" row="$2"; mkdir -p "$(dirname "$path")"; jq -e -c . <<<"$row" >>"$path"; }

log_fuckup_row(){
  local reason="$1" stderr="$2" row
  row="$(jq -nc --arg ts "$(now_iso)" --arg session "$SESSION" --argjson pane "$PANE" --arg task_id "$TASK_ID" --arg reason "$reason" --arg stderr "$stderr" \
    '{ts:$ts,trauma_class:"dispatch-delivery-verify-native-probe-failed",class:"dispatch-delivery-verify-native-probe-failed",severity:"high",session:$session,pane:$pane,task_id:$task_id,reason:$reason,what_happened:"dispatch delivery verification failed closed before native prompt visibility proof",stderr:$stderr}')"
  append_jsonl "$FUCKUP_LOG" "$row" 2>/dev/null || true
}

history_probe(){
  local out rc
  set +e; out="$("$NTM" history --session "$SESSION" --search "$TASK_ID" --json --limit 20 2>&1)"; rc=$?; set -e
  if [[ "$rc" -ne 0 ]]; then jq -nc --arg stderr "$out" --argjson rc "$rc" '{ok:false,reason:"history_failed",stderr:$stderr,ntm_rc:$rc}'; return; fi
  jq -c --arg task "$TASK_ID" --arg pane "$PANE" '
    def entries: if type=="array" then . elif (.entries? | type)=="array" then .entries else [] end;
    def body: .prompt // .text // .message // .body // "";
    def target_hit: ((.targets // .target_panes // [] | map(tostring) | index($pane)) != null) or ((.pane // null | tostring) == $pane);
    [entries[] | select((body | contains($task)))] as $hits
    | ($hits[0] // null) as $hit
    | if $hit == null then {ok:true,found:false,target_hit:false,transport_accepted:false,prompt:"",matched_at_line:null}
      else {ok:true,found:true,target_hit:($hit|target_hit),transport_accepted:(if ($hit|has("success")) then ($hit.success == true) else true end),prompt:($hit|body),matched_at_line:1} end
  ' <<<"$out" 2>/dev/null || jq -nc '{ok:false,reason:"history_parse_failed",stderr:"invalid history json",ntm_rc:0}'
}

activity_probe(){
  local out rc
  set +e; out="$("$NTM" activity "$SESSION" --pane "$PANE" --json 2>&1)"; rc=$?; set -e
  if [[ "$rc" -ne 0 ]]; then jq -nc --arg stderr "$out" --argjson rc "$rc" '{ok:false,reason:"activity_failed",stderr:$stderr,ntm_rc:$rc,state:"UNKNOWN",work_started:false}'; return; fi
  jq -c --arg pane "$PANE" '
    def agents: if (.agents? | type)=="array" then .agents elif type=="array" then . else [] end;
    [agents[] | select(((.pane // .pane_idx // .id // "") | tostring) == $pane)] as $hits
    | ($hits[0] // null) as $hit
    | ($hit.state // $hit.status // "UNKNOWN" | tostring | ascii_upcase) as $state
    | {ok:($hit != null),reason:(if $hit == null then "pane_not_found" else null end),stderr:null,ntm_rc:0,state:$state,work_started:($state | test("THINKING|GENERATING|RUNNING|WORKING"))}
  ' <<<"$out" 2>/dev/null || jq -nc '{ok:false,reason:"activity_parse_failed",stderr:"invalid activity json",ntm_rc:0,state:"UNKNOWN",work_started:false}'
}

changes_probe(){ "$NTM" changes "$SESSION" --json 2>/dev/null || printf 'null\n'; }
conflicts_probe(){ "$NTM" conflicts "$SESSION" --json --limit 50 2>/dev/null || printf 'null\n'; }

build_row(){
  local verified="$1" reason="$2" matched="$3" text="$4" attempts="$5" ntm_rc="$6" stderr="$7"
  local changes conflicts
  changes="$(changes_probe)"
  conflicts="$(conflicts_probe)"
  jq -nc --arg schema "$VERSION" --arg ts "$(now_iso)" --arg session "$SESSION" --arg task_id "$TASK_ID" --argjson pane "$PANE" \
    --argjson verified "$verified" --argjson matched_at_line "$matched" --argjson buffer_len "${#text}" --arg reason "$reason" \
    --arg buffer_tail "$(tail_text "$text")" --argjson timeout_sec "$TIMEOUT_SEC" --argjson attempts "$attempts" --argjson ntm_rc "$ntm_rc" --arg stderr "$stderr" \
    --argjson changes "$changes" --argjson conflicts "$conflicts" \
    '{schema_version:$schema,ts:$ts,session:$session,pane:$pane,task_id:$task_id,verified:$verified,matched_at_line:$matched_at_line,buffer_len:$buffer_len,reason:(if $reason=="" then null else $reason end),buffer_tail:(if $buffer_tail=="" then null else $buffer_tail end),timeout_sec:$timeout_sec,attempts:$attempts,ntm_rc:$ntm_rc,stderr:(if $stderr=="" then null else $stderr end),ntm_changes:$changes,ntm_conflicts:$conflicts}'
}

emit(){ [[ "$JSON_OUT" -eq 1 ]] && printf '%s\n' "$1" || jq -r '"verified=\(.verified) task_id=\(.task_id) session=\(.session) pane=\(.pane) reason=\(.reason // "none") matched_at_line=\(.matched_at_line // "none")"' <<<"$1"; }

verify(){
  local deadline attempts h a reason row prompt matched ntm_rc stderr
  deadline=$((SECONDS + TIMEOUT_SEC)); attempts=0
  while :; do
    attempts=$((attempts + 1)); h="$(history_probe)"; a="$(activity_probe)"
    if [[ "$(jq -r '.ok' <<<"$h")" != "true" ]]; then reason="$(jq -r '.reason' <<<"$h")"; ntm_rc="$(jq -r '.ntm_rc // 0' <<<"$h")"; stderr="$(jq -r '.stderr // ""' <<<"$h")"; row="$(build_row false "$reason" null "" "$attempts" "$ntm_rc" "$stderr")"; append_jsonl "$LEDGER" "$row"; log_fuckup_row "$reason" "$stderr"; emit "$row"; return 1; fi
    if [[ "$(jq -r '.ok' <<<"$a")" != "true" ]]; then reason="$(jq -r '.reason' <<<"$a")"; ntm_rc="$(jq -r '.ntm_rc // 0' <<<"$a")"; stderr="$(jq -r '.stderr // ""' <<<"$a")"; row="$(build_row false "$reason" null "$(jq -r '.prompt // ""' <<<"$h")" "$attempts" "$ntm_rc" "$stderr")"; append_jsonl "$LEDGER" "$row"; log_fuckup_row "$reason" "$stderr"; emit "$row"; return 1; fi
    prompt="$(jq -r '.prompt // ""' <<<"$h")"; matched="$(jq -r '.matched_at_line // "null"' <<<"$h")"
    if [[ "$(jq -r '.found' <<<"$h")" != "true" ]]; then reason="task_id_not_observed"
    elif [[ "$(jq -r '.transport_accepted' <<<"$h")" != "true" ]]; then reason="transport_not_accepted"
    elif [[ "$(jq -r '.target_hit' <<<"$h")" != "true" ]]; then reason="prompt_not_targeted_to_pane"
    elif [[ "$(jq -r '.work_started' <<<"$a")" != "true" ]]; then reason="work_not_started"
    else row="$(build_row true "" "$matched" "$prompt" "$attempts" 0 "")"; append_jsonl "$LEDGER" "$row"; emit "$row"; return 0; fi
    if [[ "$SECONDS" -ge "$deadline" ]]; then row="$(build_row false "$reason" "$matched" "$prompt" "$attempts" 0 "")"; append_jsonl "$LEDGER" "$row"; emit "$row"; return 1; fi
    sleep 1
  done
  return 0
}

while [[ $# -gt 0 ]]; do case "$1" in
  --session) SESSION="${2:-}"; shift 2;; --session=*) SESSION="${1#*=}"; shift;; --pane) PANE="${2:-}"; shift 2;; --pane=*) PANE="${1#*=}"; shift;;
  --task-id) TASK_ID="${2:-}"; shift 2;; --task-id=*) TASK_ID="${1#*=}"; shift;; --timeout-sec) TIMEOUT_SEC="${2:-}"; shift 2;; --timeout-sec=*) TIMEOUT_SEC="${1#*=}"; shift;;
  --ntm) NTM="${2:-}"; shift 2;; --ntm=*) NTM="${1#*=}"; shift;; --ledger) LEDGER="${2:-}"; shift 2;; --ledger=*) LEDGER="${1#*=}"; shift;; --json) JSON_OUT=1; shift;;
  --help|-h) usage; exit 0;; --examples) examples; exit 0;; --info) info; exit 0;; *) echo "ERR: unknown argument: $1" >&2; usage >&2; exit 2;;
esac; done

[[ -n "$SESSION" && -n "$PANE" && -n "$TASK_ID" ]] || { usage >&2; exit 2; }
[[ "$PANE" =~ ^[0-9]+$ && "$TIMEOUT_SEC" =~ ^[0-9]+$ ]] || { echo "ERR: --pane and --timeout-sec must be integers" >&2; exit 2; }
verify
