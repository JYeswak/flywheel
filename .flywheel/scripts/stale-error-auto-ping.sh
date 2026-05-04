#!/usr/bin/env bash
set -euo pipefail

VERSION="stale-error-auto-ping.v1"
NTM_BIN="${NTM_BIN:-/Users/josh/.local/bin/ntm}"
SESSION="flywheel"
PANES="2,3,4"
JSON_OUT=0
APPLY=0
DRY_RUN=1
WATCH=0
INTERVAL_SECONDS=300
ACTIVITY_FILE=""
PING_TEXT="ping: stale-error auto-recovery probe -- reply alive if read this"

usage() {
  cat <<'USAGE'
Usage:
  stale-error-auto-ping.sh [--session NAME] [--panes 2,3,4] [--dry-run|--apply] [--json]
  stale-error-auto-ping.sh --watch [--interval-seconds 300] [--dry-run|--apply] [--json]
  stale-error-auto-ping.sh doctor|health|repair [options]
  stale-error-auto-ping.sh validate activity --activity-file PATH [--json]
  stale-error-auto-ping.sh --info [--json]
  stale-error-auto-ping.sh --examples [--json]
  stale-error-auto-ping.sh --version

Finds Codex panes classified ERROR only because stale failed_text/api_error
appears above a current codex_chevron_prompt, then optionally sends a no-op
ping and rechecks activity. Default is dry-run.
USAGE
}

examples() {
  cat <<'EXAMPLES'
Examples:
  .flywheel/scripts/stale-error-auto-ping.sh --json
  .flywheel/scripts/stale-error-auto-ping.sh --apply --json --session flywheel --panes 2,3,4
  .flywheel/scripts/stale-error-auto-ping.sh --watch --interval-seconds 300 --apply --json
  .flywheel/scripts/stale-error-auto-ping.sh validate activity --activity-file /tmp/activity.json --json
EXAMPLES
}

json_msg() {
  local status="$1" message="$2"
  jq -nc \
    --arg schema_version "$VERSION" \
    --arg status "$status" \
    --arg message "$message" \
    '{schema_version:$schema_version,status:$status,message:$message}'
}

emit_info() {
  if [[ "$JSON_OUT" -eq 1 ]] || [[ " $* " == *" --json "* ]]; then
    jq -nc \
      --arg schema_version "$VERSION" \
      --arg ntm "$NTM_BIN" \
      --arg default_session "$SESSION" \
      --arg default_panes "$PANES" \
      --argjson interval "$INTERVAL_SECONDS" \
      '{schema_version:$schema_version,mode:"info",ntm:$ntm,default_session:$default_session,default_panes:$default_panes,default_interval_seconds:$interval,mutation_default:"dry-run"}'
  else
    printf '%s\nntm=%s\ndefault_session=%s\ndefault_panes=%s\nmutation_default=dry-run\n' \
      "$VERSION" "$NTM_BIN" "$SESSION" "$PANES"
  fi
}

activity_json() {
  if [[ -n "$ACTIVITY_FILE" ]]; then
    cat "$ACTIVITY_FILE"
  else
    "$NTM_BIN" "--robot-activity=$SESSION" --activity-type=codex,claude --json
  fi
}

candidates_filter() {
  local panes_json="$1"
  jq --argjson panes "$panes_json" '
    def pats: (.detected_patterns // []);
    [
      (.agents // [])[]
      | select((.pane_idx // .pane) as $p | $panes | index($p))
      | select((.state // "") == "ERROR")
      | select((.capture_provenance // "") == "live")
      | select((pats | index("codex_chevron_prompt")) != null)
      | select(((pats | index("failed_text")) != null) or ((pats | index("api_error")) != null))
      | {
          pane_idx:(.pane_idx // .pane),
          agent_type:(.agent_type // "unknown"),
          state,
          detected_patterns:(.detected_patterns // []),
          capture_collected_at:(.capture_collected_at // null),
          capture_provenance:(.capture_provenance // null),
          state_since:(.state_since // null)
        }
    ]'
}

panes_to_json() {
  jq -nc --arg panes "$PANES" '$panes | split(",") | map(select(length > 0) | tonumber)'
}

run_once() {
  local started panes_json before_file after_file before_candidates after_candidates
  started="$(date -u +%Y-%m-%dT%H:%M:%SZ)"
  panes_json="$(panes_to_json)"
  before_file="$(mktemp "${TMPDIR:-/tmp}/stale-error-before.XXXXXX")"
  after_file="$(mktemp "${TMPDIR:-/tmp}/stale-error-after.XXXXXX")"

  activity_json >"$before_file"
  before_candidates="$(candidates_filter "$panes_json" <"$before_file")"

  local sends=0
  if [[ "$APPLY" -eq 1 ]]; then
    while IFS= read -r pane; do
      [[ -n "$pane" ]] || continue
      "$NTM_BIN" send "$SESSION" --pane="$pane" --no-cass-check "$PING_TEXT" >/dev/null
      sends=$((sends + 1))
    done < <(jq -r '.[].pane_idx' <<<"$before_candidates")
  fi

  activity_json >"$after_file"
  after_candidates="$(candidates_filter "$panes_json" <"$after_file")"

  local dry_bool apply_bool
  if [[ "$DRY_RUN" -eq 1 ]]; then dry_bool=true; else dry_bool=false; fi
  if [[ "$APPLY" -eq 1 ]]; then apply_bool=true; else apply_bool=false; fi

  jq -nc \
    --arg schema_version "$VERSION" \
    --arg ts "$started" \
    --arg session "$SESSION" \
    --argjson panes "$panes_json" \
    --argjson dry_run "$dry_bool" \
    --argjson apply "$apply_bool" \
    --arg ping_text "$PING_TEXT" \
    --argjson before "$before_candidates" \
    --argjson after "$after_candidates" \
    --argjson sends "$sends" \
    '{
      schema_version:$schema_version,
      ts:$ts,
      mode:"run",
      session:$session,
      panes:$panes,
      dry_run:$dry_run,
      apply:$apply,
      stale_error_candidate_count:($before | length),
      stale_error_candidates:$before,
      planned_actions:($before | map({action:"ntm_send_ping",pane:.pane_idx,text:$ping_text})),
      actual_actions:(if $apply then ($before | map({action:"ntm_send_ping",pane:.pane_idx,text:$ping_text})) else [] end),
      send_count:$sends,
      post_recheck_candidate_count:($after | length),
      post_recheck_candidates:$after,
      recovered_count:(($before | length) - ($after | length)),
      status:(if (($before | length) == 0) then "no_candidates" elif $apply and (($after | length) < ($before | length)) then "recovered_or_improved" elif $apply then "sent_recheck_still_candidate" else "dry_run_candidates" end)
    }'
  rm -f "$before_file" "$after_file"
}

main_loop() {
  while :; do
    run_once
    [[ "$WATCH" -eq 1 ]] || break
    sleep "$INTERVAL_SECONDS"
  done
}

for arg in "$@"; do
  [[ "$arg" == "--json" ]] && JSON_OUT=1
done

COMMAND="run"
if [[ $# -gt 0 ]]; then
  case "$1" in
    doctor|health|repair|validate)
      COMMAND="$1"
      shift
      ;;
  esac
fi

while [[ $# -gt 0 ]]; do
  case "$1" in
    --session)
      SESSION="${2:?--session requires NAME}"
      shift 2
      ;;
    --panes)
      PANES="${2:?--panes requires list}"
      shift 2
      ;;
    --activity-file)
      ACTIVITY_FILE="${2:?--activity-file requires PATH}"
      shift 2
      ;;
    --dry-run)
      APPLY=0
      DRY_RUN=1
      shift
      ;;
    --apply)
      APPLY=1
      DRY_RUN=0
      shift
      ;;
    --json)
      JSON_OUT=1
      shift
      ;;
    --watch)
      WATCH=1
      shift
      ;;
    --interval-seconds)
      INTERVAL_SECONDS="${2:?--interval-seconds requires N}"
      shift 2
      ;;
    --ping-text)
      PING_TEXT="${2:?--ping-text requires TEXT}"
      shift 2
      ;;
    --info)
      emit_info
      exit 0
      ;;
    --examples)
      examples
      exit 0
      ;;
    --version)
      printf '%s\n' "$VERSION"
      exit 0
      ;;
    --help|-h)
      usage
      exit 0
      ;;
    activity)
      shift
      ;;
    *)
      printf 'ERR: unknown argument: %s\n' "$1" >&2
      exit 2
      ;;
  esac
done

case "$COMMAND" in
  doctor|health)
    if command -v jq >/dev/null && [[ -x "$NTM_BIN" || -n "$ACTIVITY_FILE" ]]; then
      if [[ "$JSON_OUT" -eq 1 ]]; then
        jq -nc --arg schema_version "$VERSION" --arg mode "$COMMAND" '{schema_version:$schema_version,mode:$mode,status:"pass",checks:{jq:true,ntm:true}}'
      else
        printf '%s pass\n' "$COMMAND"
      fi
      exit 0
    fi
    [[ "$JSON_OUT" -eq 1 ]] && json_msg fail "missing jq or ntm" || printf '%s fail\n' "$COMMAND"
    exit 1
    ;;
  repair)
    main_loop
    ;;
  validate)
    activity_json | jq empty
    [[ "$JSON_OUT" -eq 1 ]] && json_msg pass "activity JSON valid" || printf 'activity JSON valid\n'
    ;;
  run)
    main_loop
    ;;
esac
