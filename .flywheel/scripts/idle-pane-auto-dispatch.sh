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

SCAFFOLD_SCHEMA_VERSION="idle-pane-auto-dispatch/v1"
SCAFFOLD_AUDIT_LOG="${SCAFFOLD_AUDIT_LOG:-$HOME/.local/state/flywheel/idle-pane-auto-dispatch-runs.jsonl}"

scaffold_usage() {
  cat <<'USG'
usage: idle-pane-auto-dispatch.sh [SUBCOMMAND] [OPTIONS]

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
    jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" --arg name "idle-pane-auto-dispatch.sh" \
      '{schema_version:$sv,command:"info",name:$name,helper_lib_missing:true}'
    return 0
  fi
  cli_emit_info \
    "idle-pane-auto-dispatch.sh" \
    "scaffolded-v0" \
    "$SCAFFOLD_SCHEMA_VERSION" \
    "doctor,health,repair,validate,audit,why,quickstart,help,completion" \
    "SCAFFOLD_AUDIT_LOG" \
    '{}'
}

scaffold_emit_examples() {
  local jsonl
  jsonl="$(jq -nc '{name:"default run",invocation:"idle-pane-auto-dispatch.sh",purpose:"backward-compatible original behavior"}'
)"$'\n'"$(jq -nc '{name:"doctor",invocation:"idle-pane-auto-dispatch.sh doctor --json",purpose:"probe substrate health"}'
)"
  if command -v cli_emit_examples >/dev/null; then
    cli_emit_examples "$SCAFFOLD_SCHEMA_VERSION" "$jsonl"
  else
    jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" '{schema_version:$sv,command:"examples",helper_lib_missing:true}'
  fi
}

scaffold_emit_quickstart() {
  local steps
  steps="$(jq -nc '{step:1,action:"probe doctor",command:"idle-pane-auto-dispatch.sh doctor --json"}'
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
            && cli_emit_completion_bash "idle-pane-auto-dispatch" "doctor,health,repair,validate,audit,why,quickstart,help,completion" "--json,--apply,--dry-run,--idempotency-key,--info,--schema,--examples" \
            || printf '# helper lib missing — completion unavailable\n' ;;
    zsh)  command -v cli_emit_completion_zsh >/dev/null \
            && cli_emit_completion_zsh "idle-pane-auto-dispatch" "doctor,health,repair,validate,audit,why,quickstart,help,completion" \
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
VERSION="idle-pane-auto-dispatch/v3"
SURFACE_PROBE="${FLYWHEEL_SURFACE_PROBE:-/Users/josh/Developer/flywheel/.flywheel/scripts/dispatch-surface-conflict-probe.sh}"
SURFACE_LOOKBACK_MIN="${FLYWHEEL_SURFACE_LOOKBACK_MIN:-30}"
NTM_BIN="${NTM_BIN:-/Users/josh/.local/bin/ntm}"
SESSION="flywheel"
REPO=""
JSON_OUT=0
APPLY=0
DRY_RUN=1
WATCH=0
WAIT_TIMEOUT="${FLYWHEEL_IDLE_WAIT_TIMEOUT:-1s}"
WATCH_INTERVAL="${FLYWHEEL_IDLE_WATCH_INTERVAL:-30s}"
LIMIT="${FLYWHEEL_IDLE_ASSIGN_LIMIT:-1}"
NTM_124_STATUS="${FLYWHEEL_NTM_124_STATUS:-closed}"

usage() {
  cat <<'USAGE'
Usage:
  idle-pane-auto-dispatch.sh --session NAME [--repo PATH] [--dry-run|--apply] [--watch] [--json]
  idle-pane-auto-dispatch.sh --info [--json]
  idle-pane-auto-dispatch.sh --examples [--json]
  idle-pane-auto-dispatch.sh --schema [--json]
  idle-pane-auto-dispatch.sh --help

Thin wrapper around native NTM:
  1. ntm wait <session> --until=idle --any --timeout=<duration> --json
  2. ntm assign <session> --repo <path> --dry-run|--auto [--watch] --json

Default is dry-run. --apply mutates only through ntm assign.
USAGE
}

session_repo() {
  case "$1" in
    flywheel) printf '%s\n' "/Users/josh/Developer/flywheel" ;;
    alpsinsurance|alps) printf '%s\n' "/Users/josh/Developer/alpsinsurance" ;;
    skillos) printf '%s\n' "/Users/josh/Developer/skillos" ;;
    mobile-eats) printf '%s\n' "/Users/josh/Developer/mobile-eats" ;;
    vrtx) printf '%s\n' "/Users/josh/Developer/vrtx" ;;
    *) printf '%s\n' "" ;;
  esac
}

json_bool() {
  if [[ "$1" -eq 1 ]]; then printf 'true'; else printf 'false'; fi
}

emit_info() {
  if [[ "$JSON_OUT" -eq 1 ]]; then
    jq -nc --arg version "$VERSION" --arg ntm "$NTM_BIN" '{
      schema_version:$version,
      command:"idle-pane-auto-dispatch.sh",
      mutation_default:"dry-run",
      native_surface:["ntm wait <session> --until=idle --any --json","ntm assign <session> --repo <path> --dry-run|--auto --json","ntm assign <session> --watch --auto --json"],
      ntm:$ntm,
      canonical_flags:["--help","--info","--examples","--schema","--dry-run","--apply","--watch","--json","--session","--repo","--timeout","--limit"],
      dependency_status:{ntm_124:"closed"},
      blocked_native_dependency:null
    }'
  else
    printf '%s\n' "$VERSION"
    printf 'mutation_default=dry-run\n'
    printf 'native_surface=ntm wait + ntm assign\n'
  fi
}

emit_examples() {
  if [[ "$JSON_OUT" -eq 1 ]]; then
    jq -nc '{
      examples:[
        "idle-pane-auto-dispatch.sh --session flywheel --dry-run --json",
        "idle-pane-auto-dispatch.sh --session flywheel --apply --json",
        "idle-pane-auto-dispatch.sh --session flywheel --apply --watch --json"
      ]
    }'
  else
    printf '%s\n' \
      "idle-pane-auto-dispatch.sh --session flywheel --dry-run --json" \
      "idle-pane-auto-dispatch.sh --session flywheel --apply --json" \
      "idle-pane-auto-dispatch.sh --session flywheel --apply --watch --json"
  fi
}

emit_schema() {
  jq -nc --arg version "$VERSION" '{
    "$schema":"https://json-schema.org/draft/2020-12/schema",
    title:"idle-pane-auto-dispatch result",
    type:"object",
    required:["schema_version","session","repo","dry_run","apply","watch","status","wait","assign","blocked_native_dependency"],
    properties:{
      schema_version:{const:$version},
      session:{type:"string"},
      repo:{type:"string"},
      dry_run:{type:"boolean"},
      apply:{type:"boolean"},
      watch:{type:"boolean"},
      status:{type:"string"},
      wait:{type:"object"},
      assign:{type:["object","null"]},
      blocked_native_dependency:{type:["object","null"]}
    }
  }'
}

json_payload() {
  local status="$1" wait_json="$2" assign_json="$3" blocked_json="$4"
  jq -nc \
    --arg schema_version "$VERSION" \
    --arg session "$SESSION" \
    --arg repo "$REPO" \
    --arg status "$status" \
    --argjson dry_run "$(json_bool "$DRY_RUN")" \
    --argjson apply "$(json_bool "$APPLY")" \
    --argjson watch "$(json_bool "$WATCH")" \
    --argjson wait "$wait_json" \
    --argjson assign "$assign_json" \
    --argjson blocked "$blocked_json" \
    '{
      schema_version:$schema_version,
      session:$session,
      repo:$repo,
      dry_run:$dry_run,
      apply:$apply,
      watch:$watch,
      status:$status,
      wait:$wait,
      assign:$assign,
      blocked_native_dependency:$blocked
    }'
}

run_wait() {
  local output rc=0
  output="$("$NTM_BIN" wait "$SESSION" --until=idle --any --timeout="$WAIT_TIMEOUT" --json 2>&1)" || rc=$?
  if jq -e . >/dev/null 2>&1 <<<"$output"; then
    jq -c --argjson rc "$rc" '. + {exit_code:$rc, native_command:"ntm wait <session> --until=idle --any --timeout --json"}' <<<"$output"
  else
    jq -nc --arg output "$output" --argjson rc "$rc" '{exit_code:$rc,native_command:"ntm wait <session> --until=idle --any --timeout --json",raw:$output}'
  fi
  return "$rc"
}

run_assign() {
  local output rc=0
  local -a cmd=("$NTM_BIN" assign "$SESSION" --repo "$REPO" --json --limit="$LIMIT")
  if [[ "$WATCH" -eq 1 ]]; then
    cmd+=(--watch --stop-when-done --watch-interval="$WATCH_INTERVAL")
  fi
  if [[ "$APPLY" -eq 1 ]]; then
    cmd+=(--auto)
  else
    cmd+=(--dry-run)
  fi

  output="$("${cmd[@]}" 2>&1)" || rc=$?
  if jq -e . >/dev/null 2>&1 <<<"$output"; then
    jq -c --argjson rc "$rc" --arg command "${cmd[*]}" '. + {exit_code:$rc,native_command:$command}' <<<"$output"
  else
    jq -nc --arg output "$output" --argjson rc "$rc" --arg command "${cmd[*]}" '{exit_code:$rc,native_command:$command,raw:$output}'
  fi
  return "$rc"
}

run_dispatch() {
  local wait_json wait_rc assign_json assign_rc blocked
  REPO="${REPO:-$(session_repo "$SESSION")}"
  [[ -n "$REPO" ]] || { printf 'ERR: unknown session repo for %s; pass --repo\n' "$SESSION" >&2; exit 64; }

  if [[ "$WATCH" -eq 1 && "$NTM_124_STATUS" != "closed" ]]; then
    blocked="$(jq -nc --arg status "$NTM_124_STATUS" '{issue:"ntm#124",status:$status,reason:"refusing watch mode until native assign watch is verified closed"}')"
    json_payload "refused_watch_dependency_open" '{}' 'null' "$blocked"
    return 0
  fi

  set +e
  wait_json="$(run_wait)"
  wait_rc=$?
  set -e
  if [[ "$wait_rc" -eq 1 ]]; then
    json_payload "no_idle_wait_timeout" "$wait_json" 'null' 'null'
    return 0
  elif [[ "$wait_rc" -ne 0 ]]; then
    json_payload "wait_failed" "$wait_json" 'null' 'null'
    return 0
  fi

  # Surface-conflict pre-flight: dry-run assign first to peek at the candidate
  # bead's task_file, then probe for write-surface conflicts against in-flight
  # dispatches. If conflict, refuse to flip to --auto. (Closes flywheel-x6h.1.)
  local preview_json preview_rc dry_assign_rc
  if [[ "$APPLY" -eq 1 && -x "$SURFACE_PROBE" ]]; then
    set +e
    local apply_save="$APPLY"
    APPLY=0; DRY_RUN=1
    preview_json="$(run_assign)"
    preview_rc=$?
    APPLY="$apply_save"; DRY_RUN=$(( apply_save == 1 ? 0 : 1 ))
    set -e
    if [[ "$preview_rc" -eq 0 ]]; then
      local candidate_task_file
      candidate_task_file="$(jq -r '
        (.assignments // .planned_assignments // .preview // [])
        | map(.task_file // .dispatch_packet // .packet_path // empty)
        | first // empty' <<<"$preview_json" 2>/dev/null)"
      if [[ -n "$candidate_task_file" && -f "$candidate_task_file" ]]; then
        local probe_json probe_rc
        set +e
        probe_json="$("$SURFACE_PROBE" \
          --candidate-task-file "$candidate_task_file" \
          --lookback-minutes "$SURFACE_LOOKBACK_MIN" \
          --json 2>/dev/null)"
        probe_rc=$?
        set -e
        if [[ "$probe_rc" -eq 1 ]]; then
          local refused_json
          refused_json="$(jq -nc \
            --argjson probe "$probe_json" \
            '{reason:"surface_conflict_with_in_flight_dispatch", surface_probe:$probe}')"
          json_payload "refused_surface_conflict" "$wait_json" "$preview_json" "$refused_json"
          return 0
        fi
      fi
    fi
  fi

  set +e
  assign_json="$(run_assign)"
  assign_rc=$?
  set -e
  if [[ "$assign_rc" -eq 0 ]]; then
    json_payload "assigned" "$wait_json" "$assign_json" 'null'
  else
    json_payload "assign_failed" "$wait_json" "$assign_json" 'null'
  fi
}

for arg in "$@"; do
  [[ "$arg" == "--json" ]] && JSON_OUT=1
done

while [[ $# -gt 0 ]]; do
  case "$1" in
    --session) SESSION="${2:?--session requires NAME}"; shift 2 ;;
    --session=*) SESSION="${1#*=}"; shift ;;
    --repo) REPO="${2:?--repo requires PATH}"; shift 2 ;;
    --repo=*) REPO="${1#*=}"; shift ;;
    --ntm-bin) NTM_BIN="${2:?--ntm-bin requires PATH}"; shift 2 ;;
    --ntm-bin=*) NTM_BIN="${1#*=}"; shift ;;
    --timeout) WAIT_TIMEOUT="${2:?--timeout requires duration}"; shift 2 ;;
    --timeout=*) WAIT_TIMEOUT="${1#*=}"; shift ;;
    --limit) LIMIT="${2:?--limit requires N}"; shift 2 ;;
    --limit=*) LIMIT="${1#*=}"; shift ;;
    --watch-interval) WATCH_INTERVAL="${2:?--watch-interval requires duration}"; shift 2 ;;
    --watch-interval=*) WATCH_INTERVAL="${1#*=}"; shift ;;
    --dry-run) APPLY=0; DRY_RUN=1; shift ;;
    --apply) APPLY=1; DRY_RUN=0; shift ;;
    --watch) WATCH=1; shift ;;
    --json) JSON_OUT=1; shift ;;
    --help|-h) usage; exit 0 ;;
    --info) emit_info; exit 0 ;;
    --examples) emit_examples; exit 0 ;;
    --schema) emit_schema; exit 0 ;;
    --version) printf '%s\n' "$VERSION"; exit 0 ;;
    *) printf 'ERR: unknown argument: %s\n' "$1" >&2; usage >&2; exit 64 ;;
  esac
done

run_dispatch
