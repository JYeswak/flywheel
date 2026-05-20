#!/usr/bin/env bash
set -euo pipefail

VERSION="install-coordinator-daemon.v0.1.0"
SCHEMA_VERSION="flywheel.coordinator-daemon.install.v1"
SOURCE_ROOT="${FLYWHEEL_COORDINATOR_DAEMON_SOURCE_ROOT:-/Users/josh/Developer/flywheel}"
SOURCE_DIR="${FLYWHEEL_COORDINATOR_DAEMON_SOURCE_DIR:-$SOURCE_ROOT/templates/flywheel-install/launchd}"
LAUNCH_AGENTS_DIR="${FLYWHEEL_COORDINATOR_DAEMON_LAUNCH_AGENTS_DIR:-$HOME/Library/LaunchAgents}"
LAUNCHCTL="${FLYWHEEL_COORDINATOR_DAEMON_LAUNCHCTL:-launchctl}"
PLUTIL="${FLYWHEEL_COORDINATOR_DAEMON_PLUTIL:-plutil}"
WATCHERS_BIN="${FLYWHEEL_COORDINATOR_DAEMON_WATCHERS_BIN:-$HOME/.local/bin/flywheel-watchers}"
BOOTSTRAP_DOMAIN="${FLYWHEEL_COORDINATOR_DAEMON_BOOTSTRAP_DOMAIN:-gui/$UID}"
DRY_RUN_MARKER="${FLYWHEEL_COORDINATOR_DAEMON_DRY_RUN_MARKER:-/tmp/install-coordinator-daemon-dryrun.$USER}"
INSTALL_LOG="${FLYWHEEL_COORDINATOR_DAEMON_INSTALL_LOG:-$HOME/.local/state/flywheel/coordinator-daemon-install.jsonl}"
CANONICAL_SESSIONS=(flywheel mobile-eats skillos alpsinsurance vrtx picoz)

usage() {
  cat <<'USAGE'
Usage:
  install-coordinator-daemon.sh [doctor|health|repair|validate|audit] [--session NAME|--all-sessions] [--json]
  install-coordinator-daemon.sh [--session NAME|--all-sessions] --dry-run|--apply [--json]
  install-coordinator-daemon.sh --info|--schema|--examples|--why

Default is --dry-run and flywheel only. Mutating install/reload requires
--apply and a prior dry-run marker from this script.
USAGE
}

schema_json() {
  jq -nc --arg schema "$SCHEMA_VERSION" '{
    "$schema":"https://json-schema.org/draft/2020-12/schema",
    "$id":"https://zeststream.ai/schemas/flywheel/coordinator-daemon-install.schema.json",
    type:"object",
    required:["schema_version","version","mode","dry_run","apply","sessions","fleet_coordinator_daemon_coverage","rows"],
    properties:{
      schema_version:{const:$schema}, version:{type:"string"}, mode:{type:"string"},
      dry_run:{type:"boolean"}, apply:{type:"boolean"}, sessions:{type:"array",items:{type:"string"}},
      fleet_coordinator_daemon_coverage:{type:"string"}, fleet_coordinator_daemon_coverage_count:{type:"integer"},
      fleet_coordinator_daemon_coverage_total:{type:"integer"}, rows:{type:"array"}
    }
  }'
}

examples() {
  cat <<'EXAMPLES'
.flywheel/scripts/install-coordinator-daemon.sh --all-sessions --dry-run --json
.flywheel/scripts/install-coordinator-daemon.sh --all-sessions --apply --json
.flywheel/scripts/install-coordinator-daemon.sh doctor --all-sessions --json
EXAMPLES
}

label_for_session() {
  printf 'ai.zeststream.%s-coordinator-daemon\n' "$1"
}

source_for_session() {
  printf '%s/%s.plist\n' "$SOURCE_DIR" "$(label_for_session "$1")"
}

target_for_label() {
  printf '%s/%s.plist\n' "$LAUNCH_AGENTS_DIR" "$1"
}

loaded_label() {
  "$LAUNCHCTL" print "$BOOTSTRAP_DOMAIN/$1" >/dev/null 2>&1
}

coordinator_pids_json() {
  local session="$1"
  ps -axo pid=,command= | awk -v needle="ntm-coordinator-pinned" -v session_arg="--session=${session}" '
    index($0, needle) && index($0, session_arg) {
      print $1
    }
  ' | jq -R 'select(length > 0) | tonumber' | jq -sc .
}

plist_lint_ok() {
  [[ -f "$1" ]] && "$PLUTIL" -lint "$1" >/dev/null 2>&1
}

ensure_registered() {
  local label="$1"
  [[ -x "$WATCHERS_BIN" ]] || return 0
  if "$WATCHERS_BIN" registry --json 2>/dev/null | jq -e --arg label "$label" '.active[]? | select(.label == $label and (.active // true))' >/dev/null; then
    return 0
  fi
  "$WATCHERS_BIN" register \
    --label "$label" \
    --owner flywheel-orch \
    --reason "coordinator daemon fleet propagation" \
    --bead flywheel-jb3j \
    --apply \
    --idempotency-key "coordinator-daemon-${label}" \
    --json >/dev/null
}

append_json_line() {
  local file="$1"
  shift
  jq -nc "$@" >>"$file"
}

emit_message() {
  local mode="$1" status="$2" message="$3"
  jq -nc --arg version "$VERSION" --arg mode "$mode" --arg status "$status" --arg message "$message" \
    '{success:($status=="ok"),schema_version:"flywheel.coordinator-daemon.message.v1",version:$version,mode:$mode,status:$status,message:$message}'
}

write_install_log() {
  local session="$1" label="$2" source="$3" target="$4" action="$5" loaded="$6"
  mkdir -p "$(dirname "$INSTALL_LOG")"
  jq -nc \
    --arg ts "$(date -u +%Y-%m-%dT%H:%M:%SZ)" \
    --arg session "$session" \
    --arg label "$label" \
    --arg source_plist "$source" \
    --arg target_plist "$target" \
    --arg action "$action" \
    --arg bootstrap_domain "$BOOTSTRAP_DOMAIN" \
    --argjson loaded "$loaded" \
    '{ts:$ts,session:$session,label:$label,source_plist:$source_plist,target_plist:$target_plist,action:$action,bootstrap_domain:$bootstrap_domain,loaded:$loaded,rollback:"launchctl bootout \($bootstrap_domain)/\($label); rm -f \($target_plist)"}' >>"$INSTALL_LOG"
}

inspect_or_apply_one() {
  local session="$1" rows_file="$2"
  local label source target source_lint target_exists target_lint changed loaded before_loaded action copied=false bootout=false bootstrapped=false pids_json ps_pid_count
  label="$(label_for_session "$session")"
  source="$(source_for_session "$session")"
  target="$(target_for_label "$label")"

  source_lint=false
  plist_lint_ok "$source" && source_lint=true
  target_exists=false
  [[ -f "$target" ]] && target_exists=true
  target_lint=false
  [[ -f "$target" ]] && plist_lint_ok "$target" && target_lint=true
  changed=true
  [[ -f "$source" && -f "$target" ]] && cmp -s "$source" "$target" && changed=false
  loaded=false
  loaded_label "$label" && loaded=true
  before_loaded="$loaded"
  pids_json="$(coordinator_pids_json "$session")"
  ps_pid_count="$(jq 'length' <<<"$pids_json")"

  action="none"
  if [[ "$source_lint" != true ]]; then
    action="missing_or_invalid_source"
  elif [[ "$APPLY" -eq 1 ]]; then
    mkdir -p "$LAUNCH_AGENTS_DIR" "$(dirname "$INSTALL_LOG")"
    if [[ "$changed" == true ]]; then
      cp "$source" "$target"
      copied=true
      action="copied"
    fi
    ensure_registered "$label"
    if [[ "$loaded" == true && ( "$changed" == true || "$MODE" == "repair" ) ]]; then
      "$LAUNCHCTL" bootout "$BOOTSTRAP_DOMAIN/$label" >/dev/null 2>&1 || true
      bootout=true
      loaded=false
    fi
    if [[ "$loaded" != true ]]; then
      "$LAUNCHCTL" bootstrap "$BOOTSTRAP_DOMAIN" "$target"
      bootstrapped=true
    fi
    loaded=false
    loaded_label "$label" && loaded=true
    pids_json="$(coordinator_pids_json "$session")"
    ps_pid_count="$(jq 'length' <<<"$pids_json")"
    [[ "$copied" == false && "$bootstrapped" == false ]] && action="already_current"
    write_install_log "$session" "$label" "$source" "$target" "$action" "$loaded"
  elif [[ "$DRY_RUN" -eq 1 ]]; then
    if [[ "$target_exists" != true ]]; then
      action="would_copy_and_bootstrap"
    elif [[ "$changed" == true ]]; then
      action="would_replace_and_reload"
    elif [[ "$loaded" != true ]]; then
      action="would_bootstrap"
    else
      action="already_current"
    fi
  fi

  target_exists=false
  [[ -f "$target" ]] && target_exists=true
  target_lint=false
  [[ -f "$target" ]] && plist_lint_ok "$target" && target_lint=true

  append_json_line "$rows_file" \
    --arg session "$session" \
    --arg label "$label" \
    --arg source_plist "$source" \
    --arg target_plist "$target" \
    --arg bootstrap_domain "$BOOTSTRAP_DOMAIN" \
    --arg action "$action" \
    --argjson source_plist_lint "$source_lint" \
    --argjson target_exists "$target_exists" \
    --argjson target_plist_lint "$target_lint" \
    --argjson source_differs_from_target "$changed" \
    --argjson loaded_before "$before_loaded" \
    --argjson loaded "$loaded" \
    --argjson coordinator_pids "$pids_json" \
    --argjson ps_pid_count "$ps_pid_count" \
    --argjson copied "$copied" \
    --argjson bootout "$bootout" \
    --argjson bootstrapped "$bootstrapped" \
    '{session:$session,label:$label,source_plist:$source_plist,target_plist:$target_plist,bootstrap_domain:$bootstrap_domain,source_plist_lint:$source_plist_lint,target_exists:$target_exists,target_plist_lint:$target_plist_lint,source_differs_from_target:$source_differs_from_target,loaded_before:$loaded_before,loaded:$loaded,coordinator_pids:$coordinator_pids,ps_pid_count:$ps_pid_count,copied:$copied,bootout:$bootout,bootstrapped:$bootstrapped,action:$action,rollback:"launchctl bootout \($bootstrap_domain)/\($label); rm -f \($target_plist)"}'
}

emit_payload() {
  local rows_file="$1" rows_json loaded_count total coverage success
  rows_json="$(jq -sc '.' "$rows_file")"
  loaded_count="$(jq '[.[] | select(.loaded == true)] | length' <<<"$rows_json")"
  total="$(jq 'length' <<<"$rows_json")"
  coverage="${loaded_count}/${total}"
  success=true
  if [[ "$MODE" == "validate" ]]; then
    jq -e 'all(.[]; .source_plist_lint == true)' <<<"$rows_json" >/dev/null || success=false
  elif [[ "$MODE" == "doctor" || "$MODE" == "health" || "$MODE" == "audit" ]]; then
    jq -e 'all(.[]; .source_plist_lint == true and .target_exists == true and .target_plist_lint == true and .loaded == true and .ps_pid_count > 0)' <<<"$rows_json" >/dev/null || success=false
  elif [[ "$APPLY" -eq 1 ]]; then
    jq -e 'all(.[]; .source_plist_lint == true and .target_exists == true and .target_plist_lint == true and .loaded == true and .ps_pid_count > 0)' <<<"$rows_json" >/dev/null || success=false
  else
    jq -e 'all(.[]; .source_plist_lint == true)' <<<"$rows_json" >/dev/null || success=false
  fi

  jq -nc \
    --arg schema "$SCHEMA_VERSION" \
    --arg version "$VERSION" \
    --arg mode "$MODE" \
    --arg source_dir "$SOURCE_DIR" \
    --arg launch_agents_dir "$LAUNCH_AGENTS_DIR" \
    --arg bootstrap_domain "$BOOTSTRAP_DOMAIN" \
    --arg install_log "$INSTALL_LOG" \
    --arg dry_run_marker "$DRY_RUN_MARKER" \
    --arg coverage "$coverage" \
    --argjson dry_run "$DRY_RUN" \
    --argjson apply "$APPLY" \
    --argjson success "$success" \
    --argjson rows "$rows_json" \
    --argjson coverage_count "$loaded_count" \
    --argjson coverage_total "$total" \
    '{
      success:$success,
      schema_version:$schema,
      version:$version,
      mode:$mode,
      dry_run:($dry_run == 1),
      apply:($apply == 1),
      source_dir:$source_dir,
      launch_agents_dir:$launch_agents_dir,
      bootstrap_domain:$bootstrap_domain,
      install_log:$install_log,
      dry_run_marker:$dry_run_marker,
      sessions:($rows | map(.session)),
      fleet_coordinator_daemon_coverage:$coverage,
      fleet_coordinator_daemon_coverage_count:$coverage_count,
      fleet_coordinator_daemon_coverage_total:$coverage_total,
      loaded_count:$coverage_count,
      coverage:$coverage,
      rows:$rows,
      rollback_posture:"per-row rollback uses launchctl bootout then removes the installed LaunchAgent plist"
    }'
}

MODE="install"
SESSION=""
ALL_SESSIONS=0
JSON_OUT=0
DRY_RUN=1
APPLY=0
EXPLAIN=0
WHY_ID="coordinator-daemon"

if [[ $# -gt 0 ]]; then
  case "$1" in
    install|doctor|health|repair|validate|audit|why|schema|examples|quickstart|completion|help|info)
      MODE="$1"; shift ;;
  esac
fi

while [[ $# -gt 0 ]]; do
  case "$1" in
    --session)
      [[ -n "${2:-}" ]] || { echo "ERR: --session requires NAME" >&2; exit 2; }
      SESSION="$2"; shift 2 ;;
    --all-sessions)
      ALL_SESSIONS=1; shift ;;
    --dry-run)
      DRY_RUN=1; APPLY=0; shift ;;
    --apply)
      DRY_RUN=0; APPLY=1; shift ;;
    --json)
      JSON_OUT=1; shift ;;
    --doctor)
      MODE="doctor"; shift ;;
    --health)
      MODE="health"; shift ;;
    --validate)
      MODE="validate"; shift ;;
    --audit)
      MODE="audit"; shift ;;
    --repair)
      MODE="repair"; shift ;;
    --schema)
      MODE="schema"; shift ;;
    --info)
      MODE="info"; shift ;;
    --examples)
      MODE="examples"; shift ;;
    --why)
      MODE="why"; shift ;;
    --explain)
      EXPLAIN=1; shift ;;
    --id)
      [[ -n "${2:-}" ]] || { echo "ERR: --id requires ID" >&2; exit 2; }
      WHY_ID="$2"; shift 2 ;;
    --help|-h)
      usage; exit 0 ;;
    --version)
      printf '%s\n' "$VERSION"; exit 0 ;;
    *)
      echo "ERR: unknown argument: $1" >&2; exit 2 ;;
  esac
done

case "$MODE" in
  help)
    usage; exit 0 ;;
  schema)
    schema_json; exit 0 ;;
  examples|quickstart)
    examples; exit 0 ;;
  completion)
    printf '%s\n' '--session --all-sessions --dry-run --apply --json --schema --info --examples --why --doctor --health --validate --audit --repair'
    exit 0 ;;
  info)
    jq -nc --arg version "$VERSION" --arg schema "$SCHEMA_VERSION" --arg source_dir "$SOURCE_DIR" --arg launch_agents_dir "$LAUNCH_AGENTS_DIR" \
      --argjson sessions "$(printf '%s\n' "${CANONICAL_SESSIONS[@]}" | jq -R . | jq -sc .)" \
      '{success:true,schema_version:"flywheel.coordinator-daemon.info.v1",version:$version,contract_schema:$schema,source_dir:$source_dir,launch_agents_dir:$launch_agents_dir,canonical_sessions:$sessions,default_dry_run:true,mutation_requires_apply:true}'
    exit 0 ;;
  why)
    jq -nc --arg id "$WHY_ID" '{success:true,schema_version:"flywheel.coordinator-daemon.why.v1",id:$id,explanation:"Per-session LaunchAgents keep each NTM orchestrator coordinator alive with the same daemon shape and a session-specific --session flag."}'
    exit 0 ;;
esac

if [[ "$MODE" == "doctor" || "$MODE" == "health" || "$MODE" == "validate" || "$MODE" == "audit" ]]; then
  DRY_RUN=1
  APPLY=0
fi

sessions=()
if [[ "$ALL_SESSIONS" -eq 1 ]]; then
  sessions=("${CANONICAL_SESSIONS[@]}")
elif [[ -n "$SESSION" ]]; then
  sessions=("$SESSION")
else
  sessions=(flywheel)
fi

if [[ "$APPLY" -eq 1 && ! -f "$DRY_RUN_MARKER" ]]; then
  [[ "$JSON_OUT" -eq 1 ]] && emit_message "$MODE" fail "run --dry-run before --apply; missing marker $DRY_RUN_MARKER" || echo "ERR: run --dry-run before --apply; missing marker $DRY_RUN_MARKER" >&2
  exit 3
fi

rows_file="$(mktemp "${TMPDIR:-/tmp}/coordinator-daemon-install.XXXXXX")"
trap 'rm -f "$rows_file"' EXIT

for session in "${sessions[@]}"; do
  inspect_or_apply_one "$session" "$rows_file"
done

if [[ "$DRY_RUN" -eq 1 && ( "$MODE" == "install" || "$MODE" == "repair" ) ]]; then
  : >"$DRY_RUN_MARKER"
fi

payload="$(emit_payload "$rows_file")"
if [[ "$EXPLAIN" -eq 1 ]]; then
  payload="$(jq '.explanation=["Dry-run lints source plists and reports launchd state without bootout/bootstrap.","Apply copies source plists into ~/Library/LaunchAgents, reloads changed or missing labels, then verifies launchctl print.","Rollback is launchctl bootout for the label plus removal of the installed plist path."]' <<<"$payload")"
fi

if [[ "$JSON_OUT" -eq 1 ]]; then
  jq -c . <<<"$payload"
else
  jq -r '"coordinator_daemons coverage=\(.fleet_coordinator_daemon_coverage) success=\(.success) mode=\(.mode) dry_run=\(.dry_run)"' <<<"$payload"
fi

jq -e '.success == true' <<<"$payload" >/dev/null || exit 4
exit 0

# Meta-Learning Cross-References (2026-05-19)
# Batch-16 comment backfill; citations are documentation-only and do not alter runtime behavior.
# Related: `/Users/josh/Developer/skillos/.flywheel/doctrine/meta-learnings/MP-75-actionable-slo-burn-alert-contract.md`
# Related: `/Users/josh/Developer/skillos/.flywheel/doctrine/meta-learnings/MP-120-runtime-boundary-health-contract.md`
