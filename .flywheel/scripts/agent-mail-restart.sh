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

SCAFFOLD_SCHEMA_VERSION="agent-mail-restart/v1"
SCAFFOLD_AUDIT_LOG="${SCAFFOLD_AUDIT_LOG:-$HOME/.local/state/flywheel/agent-mail-restart-runs.jsonl}"

scaffold_usage() {
  cat <<'USG'
usage: agent-mail-restart.sh [SUBCOMMAND] [OPTIONS]

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
  local label domain target plist
  label="${AGENT_MAIL_LABEL:-ai.zeststream.mcp-agent-mail-local}"
  domain="${AGENT_MAIL_DOMAIN:-gui/$UID}"
  target="$domain/$label"
  plist="${AGENT_MAIL_PLIST:-$HOME/Library/LaunchAgents/${label}.plist}"
  if ! command -v cli_emit_info >/dev/null; then
    jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" --arg name "agent-mail-restart.sh" \
      --arg label "$label" --arg target "$target" --arg plist "$plist" \
      '{schema_version:$sv,command:"info",name:$name,helper_lib_missing:true,label:$label,target:$target,plist:$plist,mutates_with_apply:true,dry_run_default:true}'
    return 0
  fi
  cli_emit_info \
    "agent-mail-restart.sh" \
    "scaffolded-v0" \
    "$SCAFFOLD_SCHEMA_VERSION" \
    "doctor,health,repair,validate,audit,why,quickstart,help,completion" \
    "SCAFFOLD_AUDIT_LOG" \
    '{}' \
    | jq --arg label "$label" --arg target "$target" --arg plist "$plist" \
      '. + {label:$label,target:$target,plist:$plist,mutates_with_apply:true,dry_run_default:true}'
}

scaffold_emit_examples() {
  local jsonl
  jsonl="$(jq -nc '{name:"default run",invocation:"agent-mail-restart.sh",purpose:"backward-compatible original behavior"}'
)"$'\n'"$(jq -nc '{name:"doctor",invocation:"agent-mail-restart.sh doctor --json",purpose:"probe substrate health"}'
)"
  if command -v cli_emit_examples >/dev/null; then
    cli_emit_examples "$SCAFFOLD_SCHEMA_VERSION" "$jsonl"
  else
    jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" '{schema_version:$sv,command:"examples",helper_lib_missing:true}'
  fi
}

scaffold_emit_quickstart() {
  local steps
  steps="$(jq -nc '{step:1,action:"probe doctor",command:"agent-mail-restart.sh doctor --json"}'
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
            && cli_emit_completion_bash "agent-mail-restart" "doctor,health,repair,validate,audit,why,quickstart,help,completion" "--json,--apply,--dry-run,--idempotency-key,--info,--schema,--examples" \
            || printf '# helper lib missing — completion unavailable\n' ;;
    zsh)  command -v cli_emit_completion_zsh >/dev/null \
            && cli_emit_completion_zsh "agent-mail-restart" "doctor,health,repair,validate,audit,why,quickstart,help,completion" \
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
  # shellcheck disable=SC2317 # ShellCheck cannot follow the scaffold intercept path.
  exit $?
fi
# ====== END canonical-cli scaffold ======
SCRIPT_VERSION="2026-05-03.1"
LABEL="${AGENT_MAIL_LABEL:-ai.zeststream.mcp-agent-mail-local}"
DOMAIN="${AGENT_MAIL_DOMAIN:-gui/$UID}"
TARGET="$DOMAIN/$LABEL"
PLIST="${AGENT_MAIL_PLIST:-$HOME/Library/LaunchAgents/${LABEL}.plist}"
LAUNCHCTL_BIN="${AGENT_MAIL_RESTART_LAUNCHCTL:-launchctl}"
PLUTIL_BIN="${AGENT_MAIL_RESTART_PLUTIL:-plutil}"
PGREP_BIN="${AGENT_MAIL_RESTART_PGREP:-pgrep}"
SLEEP_BIN="${AGENT_MAIL_RESTART_SLEEP_BIN:-sleep}"
APPLY=0
EXPLAIN=0
JSON=0
MODE="run"
AGENT_MAIL_RESTART_TMPFILES=()

track_tmp_file() {
  AGENT_MAIL_RESTART_TMPFILES+=("$1")
  printf '%s\n' "$1"
}

# shellcheck disable=SC2329 # Invoked by the EXIT trap.
cleanup_tmp_files() {
  local path
  for path in "${AGENT_MAIL_RESTART_TMPFILES[@]:-}"; do
    [[ -n "$path" ]] && rm -f "$path"
  done
}
trap cleanup_tmp_files EXIT

usage() {
  cat <<'USAGE'
Usage:
  agent-mail-restart.sh --dry-run [--explain] [--json]
  agent-mail-restart.sh --apply [--explain] [--json]
  agent-mail-restart.sh --info [--json]
  agent-mail-restart.sh --help

Reload Agent Mail LaunchAgent using modern launchctl bootout/bootstrap/kickstart
and verify that the Python child process starts. Default is dry-run.
USAGE
}

for arg in "$@"; do
  case "$arg" in
    --dry-run) APPLY=0 ;;
    --apply) APPLY=1 ;;
    --explain) EXPLAIN=1 ;;
    --json) JSON=1 ;;
    --info) MODE="info" ;;
    --help|-h) usage; exit 0 ;;
    *) usage >&2; exit 2 ;;
  esac
done

if [ "$MODE" = "info" ]; then
  if [ "$JSON" -eq 1 ]; then
    jq -n --arg version "$SCRIPT_VERSION" --arg label "$LABEL" --arg target "$TARGET" --arg plist "$PLIST" \
      '{script_version:$version,label:$label,target:$target,plist:$plist,mutates_with_apply:true,dry_run_default:true}'
  else
    printf 'script_version=%s label=%s target=%s plist=%s\n' "$SCRIPT_VERSION" "$LABEL" "$TARGET" "$PLIST"
  fi
  exit 0
fi

loaded() {
  "$LAUNCHCTL_BIN" print "$TARGET" >/dev/null 2>&1
}

child_pid() {
  local launch_pid="$1"
  [ -n "$launch_pid" ] || return 0
  {
    "$PGREP_BIN" -P "$launch_pid" -f 'mcp_agent_mail\.cli serve-http' 2>/dev/null | head -1 \
      || "$PGREP_BIN" -f '/python3 -m mcp_agent_mail\.cli serve-http' 2>/dev/null | head -1 \
      || true
  }
}

launch_pid() {
  "$LAUNCHCTL_BIN" print "$TARGET" 2>/dev/null | awk '/^[[:space:]]*pid =/ {print $3; exit}'
}

say() {
  if [ "$JSON" -eq 0 ]; then
    printf '%s\n' "$*"
  fi
}

json_event() {
  if [ "$JSON" -eq 1 ]; then
    jq -nc --arg event "$1" --arg detail "$2" --arg target "$TARGET" \
      '{event:$event,detail:$detail,target:$target,ts:(now|todateiso8601)}'
  fi
}

bootstrap_with_retry() {
  local attempt err rc
  err="$(track_tmp_file "$(mktemp "${TMPDIR:-/tmp}/agent-mail-bootstrap.XXXXXX")")"
  for attempt in 1 2 3; do
    rc=0
    "$LAUNCHCTL_BIN" bootstrap "$DOMAIN" "$PLIST" 2>"$err" || rc=$?
    "$SLEEP_BIN" 1
    if loaded; then
      rm -f "$err"
      if [[ "$rc" -eq 0 ]]; then
        json_event applied "bootstrap succeeded attempt=$attempt"
      else
        json_event applied "bootstrap reported rc=$rc but target verified loaded attempt=$attempt"
      fi
      return 0
    fi
    json_event retry "bootstrap failed rc=$rc attempt=$attempt: $(tr '\n' ' ' <"$err")"
    "$SLEEP_BIN" "$attempt"
  done
  cat "$err" >&2
  rm -f "$err"
  return 1
}

recover_bootstrap_after_bootout() {
  local attempt rc err
  err="$(track_tmp_file "$(mktemp "${TMPDIR:-/tmp}/agent-mail-bootstrap-recover.XXXXXX")")"
  json_event retry "bootstrap failed after bootout; attempting recovery bootstrap/kickstart"
  for attempt in 1 2 3; do
    rc=0
    "$LAUNCHCTL_BIN" bootstrap "$DOMAIN" "$PLIST" 2>"$err" || rc=$?
    if loaded; then
      json_event applied "recovery bootstrap verified loaded attempt=$attempt rc=$rc"
      "$LAUNCHCTL_BIN" kickstart -k "$TARGET" >/dev/null 2>&1 || true
      rm -f "$err"
      return 0
    fi
    json_event retry "recovery bootstrap failed rc=$rc attempt=$attempt: $(tr '\n' ' ' <"$err")"
    "$SLEEP_BIN" "$attempt"
  done
  cat "$err" >&2
  rm -f "$err"
  return 1
}

kickstart_with_retry() {
  local attempt rc err
  err="$(track_tmp_file "$(mktemp "${TMPDIR:-/tmp}/agent-mail-kickstart.XXXXXX")")"
  for attempt in 1 2 3; do
    rc=0
    "$LAUNCHCTL_BIN" kickstart -k "$TARGET" 2>"$err" || rc=$?
    if [[ "$rc" -eq 0 ]]; then
      rm -f "$err"
      json_event applied "kickstart succeeded attempt=$attempt"
      return 0
    fi
    if ! loaded; then
      json_event retry "kickstart target missing; re-bootstrap attempt=$attempt"
      bootstrap_with_retry || true
    else
      json_event retry "kickstart failed rc=$rc attempt=$attempt: $(tr '\n' ' ' <"$err")"
    fi
    "$SLEEP_BIN" "$attempt"
  done
  cat "$err" >&2
  rm -f "$err"
  return 1
}

[ -f "$PLIST" ] || { printf 'ERROR: missing plist %s\n' "$PLIST" >&2; exit 2; }
"$PLUTIL_BIN" -lint "$PLIST" >/dev/null

if [ "$EXPLAIN" -eq 1 ]; then
  say "Reload sequence: bootout loaded agent, bootstrap plist into $DOMAIN, kickstart $TARGET, verify child PID."
  json_event explain "bootout/bootstrap/kickstart with child PID verification"
fi

if [ "$APPLY" -eq 0 ]; then
  say "DRY-RUN: would reload $TARGET from $PLIST"
  if loaded; then
    say "DRY-RUN: would launchctl bootout $TARGET"
    json_event planned "bootout loaded target"
  fi
  say "DRY-RUN: would launchctl bootstrap $DOMAIN $PLIST"
  say "DRY-RUN: would launchctl kickstart -k $TARGET"
  say "DRY-RUN: would verify child PID within 10s"
  json_event completed "dry-run only; no launchd mutation"
  exit 0
fi

WAS_LOADED=0
if loaded; then
  WAS_LOADED=1
  say "Booting out $TARGET"
  json_event applying "bootout loaded target"
  bootout_rc=0
  "$LAUNCHCTL_BIN" bootout "$TARGET" || bootout_rc=$?
  if [[ "$bootout_rc" -ne 0 ]] && loaded; then
    printf 'ERROR: bootout failed rc=%s and target remains loaded\n' "$bootout_rc" >&2
    json_event failed "bootout failed rc=$bootout_rc target still loaded"
    exit 1
  fi
fi

say "Bootstrapping $PLIST into $DOMAIN"
json_event applying "bootstrap plist"
if ! bootstrap_with_retry; then
  if [[ "$WAS_LOADED" -eq 1 ]] && recover_bootstrap_after_bootout; then
    json_event applied "recovered from bootstrap failure after bootout"
  else
    json_event failed "bootstrap failed and recovery did not verify loaded"
    exit 1
  fi
fi

say "Kickstarting $TARGET"
json_event applying "kickstart target"
kickstart_with_retry

for _ in $(seq 1 30); do
  LAUNCH_PID="$(launch_pid)"
  CHILD_PID="$(child_pid "${LAUNCH_PID:-}")"
  if [ -n "${CHILD_PID:-}" ]; then
    say "OK: $LABEL child PID $CHILD_PID"
    json_event completed "child_pid=$CHILD_PID"
    DOCTOR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)/agent-mail-fd-doctor.sh"
    if [ -x "$DOCTOR" ]; then
      "$DOCTOR" --doctor --json || true
    fi
    exit 0
  fi
  "$SLEEP_BIN" 1
done

printf 'ERROR: %s did not expose child PID within 30s\n' "$LABEL" >&2
json_event failed "child PID missing after restart"
exit 1
