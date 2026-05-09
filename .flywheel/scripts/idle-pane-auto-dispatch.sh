#!/usr/bin/env bash
set -euo pipefail

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
