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

SCAFFOLD_SCHEMA_VERSION="ntm-fleet-health/v1"
SCAFFOLD_AUDIT_LOG="${SCAFFOLD_AUDIT_LOG:-$HOME/.local/state/flywheel/ntm-fleet-health-runs.jsonl}"

scaffold_usage() {
  cat <<'USG'
usage: ntm-fleet-health.sh [SUBCOMMAND] [OPTIONS]

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
    jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" --arg name "ntm-fleet-health.sh" \
      '{schema_version:$sv,command:"info",name:$name,helper_lib_missing:true}'
    return 0
  fi
  cli_emit_info \
    "ntm-fleet-health.sh" \
    "scaffolded-v0" \
    "$SCAFFOLD_SCHEMA_VERSION" \
    "doctor,health,repair,validate,audit,why,quickstart,help,completion" \
    "SCAFFOLD_AUDIT_LOG" \
    '{}'
}

scaffold_emit_examples() {
  local jsonl
  jsonl="$(jq -nc '{name:"default run",invocation:"ntm-fleet-health.sh",purpose:"backward-compatible original behavior"}'
)"$'\n'"$(jq -nc '{name:"doctor",invocation:"ntm-fleet-health.sh doctor --json",purpose:"probe substrate health"}'
)"
  if command -v cli_emit_examples >/dev/null; then
    cli_emit_examples "$SCAFFOLD_SCHEMA_VERSION" "$jsonl"
  else
    jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" '{schema_version:$sv,command:"examples",helper_lib_missing:true}'
  fi
}

scaffold_emit_quickstart() {
  local steps
  steps="$(jq -nc '{step:1,action:"probe doctor",command:"ntm-fleet-health.sh doctor --json"}'
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
            && cli_emit_completion_bash "ntm-fleet-health" "doctor,health,repair,validate,audit,why,quickstart,help,completion" "--json,--apply,--dry-run,--idempotency-key,--info,--schema,--examples" \
            || printf '# helper lib missing — completion unavailable\n' ;;
    zsh)  command -v cli_emit_completion_zsh >/dev/null \
            && cli_emit_completion_zsh "ntm-fleet-health" "doctor,health,repair,validate,audit,why,quickstart,help,completion" \
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
NTM_BIN="${NTM_BIN:-/Users/josh/.local/bin/ntm}"
OUT_FILE="${NTM_FLEET_HEALTH_OUT:-$HOME/.local/state/flywheel/ntm-fleet-health.jsonl}"
LOCK_FILE="${NTM_FLEET_HEALTH_LOCK:-$HOME/.local/state/flywheel/ntm-fleet-health.lock}"
JSONL_APPEND_LIB="${FLYWHEEL_JSONL_APPEND_LIB:-$HOME/.local/share/flywheel-watchers/lib/jsonl-append.sh}"
TOPOLOGY_FILE="${NTM_SESSION_TOPOLOGY:-$HOME/.local/state/flywheel/session-topology.jsonl}"
THRESHOLD="${NTM_HEALTH_THRESHOLD:-10m}"
AUTO_RESTART_STUCK=0; APPLY=0; JSON_OUT=0

usage(){ printf '%s\n' \
  'Usage: ntm-fleet-health.sh [--auto-restart-stuck] [--apply] [--json]' \
  'Delegates to ntm health. Restart behavior is preview-only unless --apply is passed.'; }

while [[ $# -gt 0 ]]; do case "$1" in
  --auto-restart-stuck) AUTO_RESTART_STUCK=1; shift;; --apply) APPLY=1; shift;; --json) JSON_OUT=1; shift;;
  --threshold) THRESHOLD="${2:?--threshold requires value}"; shift 2;; --threshold=*) THRESHOLD="${1#*=}"; shift;;
  --out-file) OUT_FILE="${2:?--out-file requires path}"; shift 2;; --out-file=*) OUT_FILE="${1#*=}"; shift;;
  --ntm-bin) NTM_BIN="${2:?--ntm-bin requires path}"; shift 2;; --ntm-bin=*) NTM_BIN="${1#*=}"; shift;;
  --topology-file) TOPOLOGY_FILE="${2:?--topology-file requires path}"; shift 2;; --topology-file=*) TOPOLOGY_FILE="${1#*=}"; shift;;
  --help|-h) usage; exit 0;; *) printf 'ERR: unknown argument: %s\n' "$1" >&2; usage >&2; exit 64;;
esac; done

[[ "$AUTO_RESTART_STUCK" -eq 1 && "$APPLY" -ne 1 ]] && printf 'WARNING: --auto-restart-stuck is preview-only; pass --apply to execute ntm health mutations.\n' >&2

wrap_json(){ local raw="$1" rc="$2"; if jq -ce . >/dev/null 2>&1 <<<"$raw"; then jq -c . <<<"$raw"; else jq -cn --arg raw "$raw" --argjson exit_code "$rc" '{success:false,parse_error:true,exit_code:$exit_code,raw:$raw}'; fi; }

append_row(){
  local row="$1" label="$2" rc; [[ "${NTM_FLEET_HEALTH_FORCE_EMPTY_ROW:-0}" == "1" ]] && row=""
  if [[ ! -f "$JSONL_APPEND_LIB" ]]; then printf 'WARN: skipped %s append; JSONL primitive unavailable: %s\n' "$label" "$JSONL_APPEND_LIB" >&2; return 0; fi
  # shellcheck source=/dev/null
  source "$JSONL_APPEND_LIB"; set +e; fw_jsonl_append_validated "$OUT_FILE" "$row"; rc=$?; set -e
  [[ "$rc" -eq 0 ]] || printf 'WARN: failed to append %s row to %s rc=%s\n' "$label" "$OUT_FILE" "$rc" >&2
}

emit(){ [[ "$JSON_OUT" -eq 1 ]] && jq -cn --argjson row "$1" --argjson auto_restart "$2" '{schema_version:"ntm-fleet-health/result/v1",ledger_row:$row,auto_restart:$auto_restart}'; }

auto_preview(){
  local session="$1" health="$2"
  if [[ "$AUTO_RESTART_STUCK" -ne 1 ]]; then jq -cn '{enabled:false,apply:false,action:"none"}'
  elif [[ "$APPLY" -eq 1 ]]; then jq -cn --arg session "$session" '{enabled:true,apply:true,action:"restart_invoked",session:$session}'
  else jq -cn --arg session "$session" --argjson health "$health" '[($health.stuck_panes // $health.stuck // [])[]? | select((.stuck // .needs_restart // false) == true) | (.pane // .pane_idx // .id)] as $panes | {enabled:true,apply:false,action:"would_restart",session:$session,pane:($panes[0] // null),panes:$panes,reason:"pass --apply to run ntm health --auto-restart-stuck"}'
  fi
}

role_split(){
  jq -cn --argjson t "$1" --argjson h "$2" 'def panes:$h.panes//$h.agents//[]; def pid:.pane//.pane_idx//.id//null; def bad:((.status//.process_status//"unknown")|tostring|ascii_downcase|test("error|exited|failed|dead|stuck|unhealthy")); def role:(pid|tostring) as $p | ((.agent_type//.type//"")|tostring|ascii_downcase) as $k | if (($t.human_pane//null)!=null and $p==($t.human_pane|tostring)) or $k=="user" then "user" elif (($t.orchestrator_pane//null)!=null and $p==($t.orchestrator_pane|tostring)) or (($t.callback_pane//null)!=null and $p==($t.callback_pane|tostring)) or (($t.worker_panes//[]|map(tostring)|index($p))!=null) or ($k|test("^(cod|codex|cc|claude)$")) then "agent" else "other" end; def source:(pid|tostring) as $p | ((.agent_type//.type//"")|tostring|ascii_downcase) as $k | if (($t.human_pane//null)!=null and $p==($t.human_pane|tostring)) then "topology.human_pane" elif $k=="user" then "ntm.agent_type" elif (($t.orchestrator_pane//null)!=null and $p==($t.orchestrator_pane|tostring)) then "topology.orchestrator_pane" elif (($t.callback_pane//null)!=null and $p==($t.callback_pane|tostring)) then "topology.callback_pane" elif (($t.worker_panes//[]|map(tostring)|index($p))!=null) then "topology.worker_panes" elif ($k|test("^(cod|codex|cc|claude)$")) then "ntm.agent_type" else "unknown" end; def deco:panes[]|{pane:pid,role:role,role_source:source,status:(.status//.process_status//"unknown"),process_status:(.process_status//null),agent_type:(.agent_type//.type//null),activity:(.activity//.state//null),unhealthy:bad}; def summary($r):[deco|select(.role==$r)] as $rows|($rows|map(select(.unhealthy))) as $bad|{status:(if ($rows|length)==0 then "unknown" elif ($bad|length)>0 then "error" else "ok" end),total:($rows|length),unhealthy_count:($bad|length),panes:$rows}; {schema_version:"ntm-health-role-split/v1",agent_pane_health:summary("agent"),user_pane_health:summary("user"),other_pane_health:summary("other")}'
}

mkdir -p "$(dirname "$OUT_FILE")" "$(dirname "$LOCK_FILE")"
if command -v flock >/dev/null 2>&1; then exec 9>"$LOCK_FILE"; flock -n 9 || { echo "another instance running"; exit 0; }
else if ! mkdir "$LOCK_FILE" 2>/dev/null; then echo "another instance running"; exit 0; fi; trap 'rmdir "$LOCK_FILE" 2>/dev/null || true' EXIT INT TERM; fi
NOW="$(date -u +%Y-%m-%dT%H:%M:%SZ)"

set +e; LIST_OUT="$("$NTM_BIN" list --json 2>&1)"; LIST_RC=$?; set -e
if [[ "$LIST_RC" -ne 0 ]]; then LIST_JSON="$(wrap_json "$LIST_OUT" "$LIST_RC")"; ROW="$(jq -cn --arg ts "$NOW" --argjson list "$LIST_JSON" '{ts:$ts,event:"session_discovery_failed",list:$list}')"; append_row "$ROW" "session_discovery_failed"; emit "$ROW" "$(jq -cn '{enabled:false,apply:false,action:"none"}')"; exit 0; fi

SESSIONS="$(jq -r 'if type=="array" then .[]? | (.name // .session // empty) elif (.sessions? | type)=="array" then .sessions[]? | (.name // .session // empty) else .name // .session // empty end' <<<"$LIST_OUT" 2>/dev/null || true)"
if [[ -z "$SESSIONS" ]]; then ROW="$(jq -cn --arg ts "$NOW" '{ts:$ts,event:"no_sessions_discovered"}')"; append_row "$ROW" "no_sessions_discovered"; emit "$ROW" "$(jq -cn '{enabled:false,apply:false,action:"none"}')"; exit 0; fi

while IFS= read -r SESSION; do
  [[ -z "$SESSION" ]] && continue
  TOPO="null"; [[ -r "$TOPOLOGY_FILE" ]] && TOPO="$(jq -sc --arg s "$SESSION" 'map(select(.session == $s)) | sort_by(.effective_at // "") | last // null' "$TOPOLOGY_FILE" 2>/dev/null || printf 'null')"
  HEALTH_ARGS=(health "$SESSION" --json --threshold "$THRESHOLD"); [[ "$AUTO_RESTART_STUCK" -eq 1 && "$APPLY" -eq 1 ]] && HEALTH_ARGS+=(--auto-restart-stuck)
  set +e; HEALTH_OUT="$("$NTM_BIN" "${HEALTH_ARGS[@]}" 2>&1)"; HEALTH_RC=$?; set -e
  HEALTH="$(wrap_json "$HEALTH_OUT" "$HEALTH_RC")"; ROLE_SPLIT="$(role_split "$TOPO" "$HEALTH")"
  ROW="$(jq -cn --arg ts "$NOW" --arg session "$SESSION" --arg threshold "$THRESHOLD" --argjson health "$HEALTH" --argjson role "$ROLE_SPLIT" '{ts:$ts,session:$session,threshold:$threshold,health:$health,agent_pane_health:$role.agent_pane_health,user_pane_health:$role.user_pane_health,other_pane_health:$role.other_pane_health,health_role_split:$role}')"
  AUTO="$(auto_preview "$SESSION" "$HEALTH")"; append_row "$ROW" "health"; emit "$ROW" "$AUTO"
done <<<"$SESSIONS"
