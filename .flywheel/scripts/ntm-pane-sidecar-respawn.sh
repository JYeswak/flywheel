#!/usr/bin/env bash
set -euo pipefail

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
