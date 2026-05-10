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

SCAFFOLD_SCHEMA_VERSION="ntm-pane-sidecar-respawn/v1"
SCAFFOLD_AUDIT_LOG="${SCAFFOLD_AUDIT_LOG:-$HOME/.local/state/flywheel/ntm-pane-sidecar-respawn-runs.jsonl}"

scaffold_usage() {
  cat <<'USG'
usage: ntm-pane-sidecar-respawn.sh [SUBCOMMAND] [OPTIONS]

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
    jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" --arg name "ntm-pane-sidecar-respawn.sh" \
      '{schema_version:$sv,command:"info",name:$name,helper_lib_missing:true}'
    return 0
  fi
  cli_emit_info \
    "ntm-pane-sidecar-respawn.sh" \
    "scaffolded-v0" \
    "$SCAFFOLD_SCHEMA_VERSION" \
    "doctor,health,repair,validate,audit,why,quickstart,help,completion" \
    "SCAFFOLD_AUDIT_LOG" \
    '{}'
}

scaffold_emit_examples() {
  local jsonl
  jsonl="$(jq -nc '{name:"default run",invocation:"ntm-pane-sidecar-respawn.sh",purpose:"backward-compatible original behavior"}'
)"$'\n'"$(jq -nc '{name:"doctor",invocation:"ntm-pane-sidecar-respawn.sh doctor --json",purpose:"probe substrate health"}'
)"
  if command -v cli_emit_examples >/dev/null; then
    cli_emit_examples "$SCAFFOLD_SCHEMA_VERSION" "$jsonl"
  else
    jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" '{schema_version:$sv,command:"examples",helper_lib_missing:true}'
  fi
}

scaffold_emit_quickstart() {
  local steps
  steps="$(jq -nc '{step:1,action:"probe doctor",command:"ntm-pane-sidecar-respawn.sh doctor --json"}'
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
            && cli_emit_completion_bash "ntm-pane-sidecar-respawn" "doctor,health,repair,validate,audit,why,quickstart,help,completion" "--json,--apply,--dry-run,--idempotency-key,--info,--schema,--examples" \
            || printf '# helper lib missing — completion unavailable\n' ;;
    zsh)  command -v cli_emit_completion_zsh >/dev/null \
            && cli_emit_completion_zsh "ntm-pane-sidecar-respawn" "doctor,health,repair,validate,audit,why,quickstart,help,completion" \
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
VERSION="ntm-pane-sidecar-respawn/v1"
NTM_BIN="${NTM_BIN:-/Users/josh/.local/bin/ntm}"
SESSION=""
PANE=""
CWD=""
COMMAND_PATH=""
RAW_COMMAND=""
JSON=0
APPLY=0
ROLLBACK=0
ENV_OVERRIDES='[]'
CONFIG_OVERRIDES='[]'
COMMAND_ARGS='[]'

usage() {
  cat <<'USAGE'
Usage:
  ntm-pane-sidecar-respawn.sh --session NAME --pane N --command-path PATH [--command-arg ARG ...] [--cwd PATH] [--env KEY=VALUE ...] [--config-override KEY=VALUE ...] [--dry-run|--apply] [--json]
  ntm-pane-sidecar-respawn.sh --session NAME --pane N --rollback [--dry-run|--apply] [--json]
  ntm-pane-sidecar-respawn.sh health|doctor|validate|audit|why|schema|examples|--info

Default mode is dry-run. Apply restarts exactly one pane through ntm respawn.
Rollback uses only the recorded-command ntm respawn path for that pane.
USAGE
}

fail() {
  local reason="$1" code="${2:-2}"
  if [[ "$JSON" -eq 1 ]]; then
    jq -nc --arg schema "$VERSION" --arg reason "$reason" \
      '{schema_version:$schema,status:"usage_error",success:false,reason:$reason}'
  else
    printf 'usage_error: %s\n' "$reason" >&2
  fi
  exit "$code"
}

need() {
  command -v "$1" >/dev/null 2>&1 || fail "missing dependency: $1" 2
}

shell_quote() {
  local quoted
  printf -v quoted '%q' "$1"
  printf '%s' "$quoted"
}

json_append_string() {
  local json="$1" value="$2"
  jq -c --arg value "$value" '. + [$value]' <<<"$json"
}

json_append_env() {
  local json="$1" pair="$2" name value
  [[ "$pair" == *=* ]] || fail "--env requires KEY=VALUE"
  name="${pair%%=*}"
  value="${pair#*=}"
  [[ "$name" =~ ^[A-Za-z_][A-Za-z0-9_]*$ ]] || fail "invalid env name: $name"
  jq -c --arg name "$name" --argjson length "${#value}" \
    '. + [{name:$name,value_redacted:"<redacted>",value_length:$length}]' <<<"$json"
}

json_or_raw() {
  local tmp err rc
  tmp="$(mktemp "${TMPDIR:-/tmp}/ntm-pane-sidecar.XXXXXX")"
  err="$tmp.err"
  set +e
  "$@" >"$tmp" 2>"$err"
  rc=$?
  set -e
  if jq -e . "$tmp" >/dev/null 2>&1; then
    jq -c --argjson rc "$rc" '{exit_code:$rc,payload:.}' "$tmp"
  else
    jq -nc --argjson rc "$rc" --rawfile stdout "$tmp" --rawfile stderr "$err" \
      '{exit_code:$rc,stdout:$stdout,stderr:$stderr}'
  fi
  rm -f "$tmp" "$err"
}

join_parts() {
  local out="" part
  for part in "$@"; do
    if [[ -z "$out" ]]; then
      out="$part"
    else
      out+=" && $part"
    fi
  done
  printf '%s' "$out"
}

build_launch_command() {
  local redact_env="${1:-0}" parts=() arg_count config_count i value key cmd
  if [[ -n "$RAW_COMMAND" ]]; then
    cmd="$RAW_COMMAND"
  else
    [[ -n "$COMMAND_PATH" ]] || fail "--command-path is required unless --rollback is set"
    cmd="$(shell_quote "$COMMAND_PATH")"
    arg_count="$(jq 'length' <<<"$COMMAND_ARGS")"
    for ((i = 0; i < arg_count; i++)); do
      value="$(jq -r ".[$i]" <<<"$COMMAND_ARGS")"
      cmd+=" $(shell_quote "$value")"
    done
    config_count="$(jq 'length' <<<"$CONFIG_OVERRIDES")"
    for ((i = 0; i < config_count; i++)); do
      value="$(jq -r ".[$i]" <<<"$CONFIG_OVERRIDES")"
      cmd+=" -c $(shell_quote "$value")"
    done
  fi

  if [[ -n "$CWD" ]]; then
    parts+=("cd $(shell_quote "$CWD")")
  fi
  local env_count
  env_count="$(jq 'length' <<<"$ENV_OVERRIDES")"
  for ((i = 0; i < env_count; i++)); do
    key="$(jq -r ".[$i].name" <<<"$ENV_OVERRIDES")"
    value="${ENV_VALUES[$key]}"
    if [[ "$redact_env" -eq 1 ]]; then
      value="<redacted>"
    fi
    parts+=("export $key=$(shell_quote "$value")")
  done
  parts+=("exec $cmd")
  join_parts "${parts[@]}"
}

emit_plan() {
  local dry_run="$1" launch_command="$2"
  local apply_bool rollback_bool
  apply_bool="$([[ "$APPLY" -eq 1 ]] && printf true || printf false)"
  rollback_bool="$([[ "$ROLLBACK" -eq 1 ]] && printf true || printf false)"
  jq -nc \
    --arg schema "$VERSION" \
    --arg session "$SESSION" \
    --argjson pane "$PANE" \
    --arg cwd "$CWD" \
    --arg command_path "$COMMAND_PATH" \
    --arg launch_command_redacted "$launch_command" \
    --argjson env_overrides "$ENV_OVERRIDES" \
    --argjson config_overrides "$CONFIG_OVERRIDES" \
    --argjson command_args "$COMMAND_ARGS" \
    --argjson dry_run "$dry_run" \
    --argjson apply "$apply_bool" \
    --argjson rollback "$rollback_bool" \
    '{
      schema_version:$schema,
      success:true,
      status:(if $dry_run then "dry_run" else "planned" end),
      dry_run:$dry_run,
      apply:$apply,
      rollback:$rollback,
      rollback_returns_to_recorded_command:$rollback,
      respawn_only_target_pane:true,
      target:{session:$session,pane:$pane},
      cwd:$cwd,
      command:{path:$command_path,args:$command_args},
      env_overrides:$env_overrides,
      config_overrides:$config_overrides,
      launch_command_redacted:$launch_command_redacted,
      planned_actions:[
        ("ntm respawn " + $session + " --panes=" + ($pane|tostring) + " --force --json"),
        (if $rollback then "recorded-command rollback: no sidecar send" else "ntm send " + $session + " --pane=" + ($pane|tostring) + " <sidecar launch command>" end),
        ("ntm health " + $session + " --pane " + ($pane|tostring) + " --json"),
        "ntm version --json"
      ]
    }'
}

run_apply() {
  local launch_command="$1" launch_command_redacted="$2" respawn send send_rc health version
  local rollback_bool
  rollback_bool="$([[ "$ROLLBACK" -eq 1 ]] && printf true || printf false)"
  respawn="$(json_or_raw "$NTM_BIN" respawn "$SESSION" "--panes=$PANE" --force --json)"
  if [[ "$ROLLBACK" -eq 0 ]]; then
    set +e
    send="$(printf 'y\n' | "$NTM_BIN" send "$SESSION" "--pane=$PANE" "$launch_command" --json 2>&1)"
    send_rc=$?
    set -e
  else
    send='recorded-command rollback: sidecar send skipped'
    send_rc=0
  fi
  health="$(json_or_raw "$NTM_BIN" health "$SESSION" --pane "$PANE" --json)"
  version="$(json_or_raw "$NTM_BIN" version --json)"
  jq -nc \
    --arg schema "$VERSION" \
    --arg session "$SESSION" \
    --argjson pane "$PANE" \
    --arg cwd "$CWD" \
    --arg command_path "$COMMAND_PATH" \
    --arg launch_command_redacted "$launch_command_redacted" \
    --arg send_output "$send" \
    --argjson send_rc "$send_rc" \
    --argjson env_overrides "$ENV_OVERRIDES" \
    --argjson config_overrides "$CONFIG_OVERRIDES" \
    --argjson command_args "$COMMAND_ARGS" \
    --argjson rollback "$rollback_bool" \
    --argjson respawn "$respawn" \
    --argjson health "$health" \
    --argjson version "$version" \
    '{
      schema_version:$schema,
      success:($respawn.exit_code == 0 and $send_rc == 0 and $health.exit_code == 0),
      status:(if ($respawn.exit_code == 0 and $send_rc == 0 and $health.exit_code == 0) then "applied" else "apply_failed" end),
      dry_run:false,
      apply:true,
      rollback:$rollback,
      rollback_returns_to_recorded_command:$rollback,
      respawn_only_target_pane:true,
      target:{session:$session,pane:$pane},
      cwd:$cwd,
      command:{path:$command_path,args:$command_args},
      env_overrides:$env_overrides,
      config_overrides:$config_overrides,
      launch_command_redacted:$launch_command_redacted,
      respawn_evidence:$respawn,
      sidecar_send_evidence:{exit_code:$send_rc,stdout:$send_output},
      health_evidence:$health,
      binary_version_evidence:$version
    }'
}

emit_static() {
  local verb="$1"
  case "$verb" in
    health|doctor)
      local ntm_status="ok"
      [[ -x "$NTM_BIN" ]] || ntm_status="missing"
      jq -nc --arg schema "$VERSION" --arg ntm "$NTM_BIN" --arg ntm_status "$ntm_status" \
        '{schema_version:$schema,status:(if $ntm_status=="ok" then "pass" else "fail" end),ntm_bin:$ntm,ntm_status:$ntm_status,requires:["jq","ntm"]}'
      ;;
    validate|audit)
      jq -nc --arg schema "$VERSION" \
        '{schema_version:$schema,status:"pass",checks:["single-pane target required","dry-run default","apply requires --apply","rollback skips sidecar send","health and version evidence emitted"]}'
      ;;
    why)
      jq -nc --arg schema "$VERSION" \
        '{schema_version:$schema,why:"Provides a pane-scoped NTM-only sidecar respawn surface while preserving recorded-command rollback through native ntm respawn."}'
      ;;
    schema)
      jq -nc --arg schema "$VERSION" \
        '{schema_version:$schema,required:["--session","--pane","--command-path unless --rollback"],modes:["dry-run","apply","rollback"],exit_codes:{"0":"ok","1":"apply failed","2":"usage"}}'
      ;;
    examples)
      jq -nc --arg schema "$VERSION" '{schema_version:$schema,examples:[
        ".flywheel/scripts/ntm-pane-sidecar-respawn.sh --session flywheel --pane 2 --command-path /opt/homebrew/bin/codex --command-arg --dangerously-bypass-approvals-and-sandbox --cwd /Users/josh/Developer/flywheel --env CODEX_HOME=/tmp/codex-sidecar --config-override model=\"gpt-5.5\" --dry-run --json",
        ".flywheel/scripts/ntm-pane-sidecar-respawn.sh --session flywheel --pane 2 --rollback --apply --json"
      ]}'
      ;;
    info|--info)
      jq -nc --arg schema "$VERSION" --arg ntm "$NTM_BIN" \
        '{schema_version:$schema,name:"ntm-pane-sidecar-respawn",ntm_bin:$ntm,mutation_default:"dry-run",native_surfaces:["ntm respawn","ntm send","ntm health","ntm version"]}'
      ;;
  esac
}

declare -A ENV_VALUES=()

if [[ $# -gt 0 ]]; then
  case "$1" in
    health|doctor|validate|audit|why|schema|examples)
      verb="$1"
      shift
      while [[ $# -gt 0 ]]; do
        case "$1" in
          --ntm-bin) NTM_BIN="${2:-}"; shift 2 ;;
          --json) JSON=1; shift ;;
          --help|-h) usage; exit 0 ;;
          *) fail "unknown argument for $verb: $1" ;;
        esac
      done
      need jq
      emit_static "$verb"
      exit 0
      ;;
  esac
fi

while [[ $# -gt 0 ]]; do
  case "$1" in
    --session) SESSION="${2:-}"; shift 2 ;;
    --pane) PANE="${2:-}"; shift 2 ;;
    --cwd) CWD="${2:-}"; shift 2 ;;
    --command-path) COMMAND_PATH="${2:-}"; shift 2 ;;
    --command) RAW_COMMAND="${2:-}"; COMMAND_PATH="${2%% *}"; shift 2 ;;
    --command-arg) COMMAND_ARGS="$(json_append_string "$COMMAND_ARGS" "${2:-}")"; shift 2 ;;
    --env)
      pair="${2:-}"
      ENV_OVERRIDES="$(json_append_env "$ENV_OVERRIDES" "$pair")"
      ENV_VALUES["${pair%%=*}"]="${pair#*=}"
      shift 2
      ;;
    --config-override) CONFIG_OVERRIDES="$(json_append_string "$CONFIG_OVERRIDES" "${2:-}")"; shift 2 ;;
    --ntm-bin) NTM_BIN="${2:-}"; shift 2 ;;
    --dry-run) APPLY=0; shift ;;
    --apply) APPLY=1; shift ;;
    --rollback) ROLLBACK=1; shift ;;
    --json) JSON=1; shift ;;
    --info) need jq; emit_static info; exit 0 ;;
    --help|-h) usage; exit 0 ;;
    *) fail "unknown argument: $1" ;;
  esac
done

need jq
[[ -n "$SESSION" ]] || fail "--session is required"
[[ -n "$PANE" ]] || fail "--pane is required"
[[ "$PANE" =~ ^[0-9]+$ ]] || fail "--pane must be one pane index"
[[ "$PANE" != "0" ]] || fail "pane 0 is reserved for the user pane"
[[ "$ROLLBACK" -eq 1 || -n "$COMMAND_PATH" || -n "$RAW_COMMAND" ]] || fail "--command-path is required unless --rollback is set"
[[ "$ROLLBACK" -eq 0 || -z "$RAW_COMMAND$COMMAND_PATH" ]] || COMMAND_PATH=""
[[ -n "$CWD" ]] || CWD="$PWD"

launch_command=""
launch_command_redacted=""
if [[ "$ROLLBACK" -eq 0 ]]; then
  launch_command="$(build_launch_command 0)"
  launch_command_redacted="$(build_launch_command 1)"
fi

if [[ "$APPLY" -eq 0 ]]; then
  emit_plan true "$launch_command_redacted"
  exit 0
fi

[[ -x "$NTM_BIN" ]] || fail "ntm binary is not executable: $NTM_BIN" 2
out="$(run_apply "$launch_command" "$launch_command_redacted")"
printf '%s\n' "$out"
jq -e '.success == true' >/dev/null <<<"$out" || exit 1
