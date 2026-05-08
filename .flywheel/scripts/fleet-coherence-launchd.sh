#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd -P)"
LIB="$ROOT/.flywheel/scripts/fleet-coherence-lib.sh"
# shellcheck source=.flywheel/scripts/fleet-coherence-lib.sh
source "$LIB"

CONTRACT="fleet-coherence-launchd/v1"
LABEL="${FLEET_COHERENCE_LAUNCHD_LABEL:-com.zeststream.flywheel.fleet-coherence}"
SOURCE_PLIST="${FLEET_COHERENCE_SOURCE_PLIST:-$ROOT/launchd/ai.zeststream.fleet-coherence.plist}"
INSTALL_PLIST="${FLEET_COHERENCE_INSTALL_PLIST:-$HOME/Library/LaunchAgents/${LABEL}.plist}"
DOMAIN="${FLEET_COHERENCE_LAUNCHD_DOMAIN:-gui/$(id -u)}"
TARGET="$DOMAIN/$LABEL"
LAUNCHCTL="${FLEET_COHERENCE_LAUNCHCTL:-launchctl}"
PLUTIL="${FLEET_COHERENCE_PLUTIL:-plutil}"
SCANNER="${FLEET_COHERENCE_SCANNER:-$ROOT/.flywheel/scripts/fleet-coherence-scan.sh}"
STATE_DIR="${FLEET_COHERENCE_STATE_DIR:-$(fc_state_dir)}"
EVENTS="${FLEET_COHERENCE_EVENTS:-$(fc_events_path)}"
LATEST="${FLEET_COHERENCE_LATEST:-$(fc_latest_path)}"
LIFECYCLE_LEDGER="${FLEET_COHERENCE_LIFECYCLE_LEDGER:-$STATE_DIR/fleet-coherence-launchd.jsonl}"
LIFECYCLE_LATEST="${FLEET_COHERENCE_LIFECYCLE_LATEST:-$STATE_DIR/fleet-coherence-launchd-latest.json}"
RUN_LOCK="${FLEET_COHERENCE_RUN_LOCK:-$STATE_DIR/fleet-coherence-launchd.lock}"
SCANNER_LOCK="${FLEET_COHERENCE_SCANNER_LOCK:-$STATE_DIR/fleet-coherence-scan.lock}"
STOP_FILE="${FLEET_COHERENCE_STOP_FILE:-$HOME/.flywheel/STOP-fleet-coherence}"
GLOBAL_STOP_FILE="${FLEET_COHERENCE_GLOBAL_STOP_FILE:-$HOME/.flywheel/STOP-ALL}"
STDOUT_PATH="${FLEET_COHERENCE_STDOUT_PATH:-$HOME/.local/logs/fleet-coherence-launchd.out.log}"
STDERR_PATH="${FLEET_COHERENCE_STDERR_PATH:-$HOME/.local/logs/fleet-coherence-launchd.err.log}"
CADENCE_SECONDS="${FLEET_COHERENCE_CADENCE_SECONDS:-60}"
STALE_LOCK_SECONDS="${FLEET_COHERENCE_STALE_LOCK_SECONDS:-180}"
SAFE_PATH="${FLEET_COHERENCE_SAFE_PATH:-/Users/josh/.cargo/bin:/Users/josh/.local/bin:/opt/homebrew/bin:/usr/local/bin:/usr/bin:/bin}"
MODE="status"
APPLY=0
JSON_OUT=0
RUN_LOCK_ACQUIRED=0
CHILD_PID=0

usage() {
  cat <<'EOF'
Usage:
  fleet-coherence-launchd.sh install --dry-run|--apply [--json]
  fleet-coherence-launchd.sh load --dry-run|--apply [--json]
  fleet-coherence-launchd.sh unload --dry-run|--apply [--json]
  fleet-coherence-launchd.sh status [--json]
  fleet-coherence-launchd.sh run [--json]
  fleet-coherence-launchd.sh validate plist [--json]

Installs and controls the fleet-coherence scanner LaunchAgent.
STOP files: ~/.flywheel/STOP-fleet-coherence and ~/.flywheel/STOP-ALL.
HUP/TERM/INT during run emit lifecycle receipts and clean wrapper locks.
EOF
}

now_iso() { fc_now; }

ensure_dirs() {
  mkdir -p "$STATE_DIR" "$(dirname "$EVENTS")" "$(dirname "$LATEST")" \
    "$(dirname "$LIFECYCLE_LEDGER")" "$(dirname "$LIFECYCLE_LATEST")" \
    "$(dirname "$SOURCE_PLIST")" "$(dirname "$INSTALL_PLIST")" \
    "$(dirname "$STDOUT_PATH")" "$(dirname "$STDERR_PATH")"
}

emit() {
  if [[ "$JSON_OUT" -eq 1 ]]; then
    jq -cS .
  else
    jq .
  fi
}

bool_json() {
  if [[ "$1" == "true" ]]; then
    printf 'true\n'
  else
    printf 'false\n'
  fi
}

is_uint() {
  [[ "${1:-}" =~ ^[0-9]+$ ]]
}

require_uint() {
  local name="$1" value="$2"
  if ! is_uint "$value"; then
    printf '%s must be an unsigned integer, got %s\n' "$name" "$value" >&2
    exit 64
  fi
}

write_lifecycle_row() {
  local row="$1"
  mkdir -p "$(dirname "$LIFECYCLE_LEDGER")" "$(dirname "$LIFECYCLE_LATEST")"
  printf '%s\n' "$row" | jq -cS . >>"$LIFECYCLE_LEDGER"
  printf '%s\n' "$row" | jq -cS . >"$LIFECYCLE_LATEST"
}

lifecycle_row() {
  local status="$1" decision="$2" scanner_rc="${3:-null}" scanner_status="${4:-null}" extra="${5:-{}}"
  scanner_rc="$(jq -ncS --arg v "$scanner_rc" 'try ($v | fromjson) catch null')"
  scanner_status="$(jq -ncS --arg v "$scanner_status" 'try ($v | fromjson) catch null')"
  extra="$(jq -ncS --arg v "$extra" 'try (($v | fromjson) | if type == "object" then . else {} end) catch {}')"
  jq -ncS \
    --arg ts "$(now_iso)" \
    --arg contract "$CONTRACT" \
    --arg status "$status" \
    --arg decision "$decision" \
    --arg label "$LABEL" \
    --arg target "$TARGET" \
    --arg source_plist "$SOURCE_PLIST" \
    --arg install_plist "$INSTALL_PLIST" \
    --arg scanner "$SCANNER" \
    --arg state_dir "$STATE_DIR" \
    --arg events "$EVENTS" \
    --arg latest "$LATEST" \
    --arg run_lock "$RUN_LOCK" \
    --arg scanner_lock "$SCANNER_LOCK" \
    --arg stop_file "$STOP_FILE" \
    --arg global_stop_file "$GLOBAL_STOP_FILE" \
    --argjson scanner_rc "$scanner_rc" \
    --argjson scanner_status "$scanner_status" \
    --argjson extra "$extra" \
    '{
      schema_version: "fleet-coherence-launchd-lifecycle/v1",
      ts: $ts,
      status: $status,
      decision: $decision,
      contract: $contract,
      l112_observed: "OK_phase1b_launchd",
      label: $label,
      target: $target,
      source_plist: $source_plist,
      install_plist: $install_plist,
      scanner: $scanner,
      state_dir: $state_dir,
      events_path: $events,
      latest_path: $latest,
      run_lock: $run_lock,
      scanner_lock: $scanner_lock,
      stop_files: [$stop_file, $global_stop_file],
      scanner_rc: $scanner_rc,
      scanner_status: $scanner_status
    } + $extra'
}

cleanup_run_lock() {
  if [[ "$RUN_LOCK_ACQUIRED" -eq 1 ]]; then
    rm -rf "$RUN_LOCK" 2>/dev/null || true
    RUN_LOCK_ACQUIRED=0
  fi
}

signal_handler() {
  local signal="$1" row
  if [[ "$CHILD_PID" -gt 0 ]]; then
    kill "$CHILD_PID" >/dev/null 2>&1 || true
  fi
  row="$(lifecycle_row "signaled" "signal_${signal}")"
  row="$(printf '%s\n' "$row" | jq -cS --arg signal "$signal" '. + {signal:$signal, graceful_cleanup:true}')"
  write_lifecycle_row "$row"
  cleanup_run_lock
  printf '%s\n' "$row" | emit
  exit 0
}

trap_cleanup() {
  cleanup_run_lock
}
trap trap_cleanup EXIT

plist_path_for_write() {
  local which="$1"
  case "$which" in
    source) printf '%s\n' "$SOURCE_PLIST" ;;
    install) printf '%s\n' "$INSTALL_PLIST" ;;
    *) return 64 ;;
  esac
}

write_plist_file() {
  local path="$1" tmp helper_cmd
  ensure_dirs
  tmp="${path}.$$.$RANDOM.tmp"
  helper_cmd="exec $ROOT/.flywheel/scripts/fleet-coherence-launchd.sh run --json"
  python3 - "$tmp" "$LABEL" "$helper_cmd" "$STDOUT_PATH" "$STDERR_PATH" "$CADENCE_SECONDS" "$SAFE_PATH" "$HOME" <<'PY'
import plistlib
import sys

target, label, command, stdout, stderr, cadence, safe_path, home = sys.argv[1:9]
payload = {
    "Label": label,
    "ProgramArguments": ["/bin/bash", "-lc", command],
    "StartInterval": int(cadence),
    "RunAtLoad": True,
    "StandardOutPath": stdout,
    "StandardErrorPath": stderr,
    "EnvironmentVariables": {
        "HOME": home,
        "PATH": safe_path,
    },
}
with open(target, "wb") as handle:
    plistlib.dump(payload, handle, sort_keys=False)
PY
  "$PLUTIL" -lint "$tmp" >/dev/null
  mv "$tmp" "$path"
}

plist_value() {
  local path="$1" key="$2"
  [[ -f "$path" ]] || return 1
  "$PLUTIL" -extract "$key" raw "$path" 2>/dev/null
}

loaded() {
  "$LAUNCHCTL" print "$TARGET" >/dev/null 2>&1
}

lock_age_s() {
  local path="$1" mtime now
  [[ -e "$path" ]] || { printf '0\n'; return 0; }
  if mtime="$(stat -f %m "$path" 2>/dev/null)"; then
    :
  elif mtime="$(stat -c %Y "$path" 2>/dev/null)"; then
    :
  else
    printf '0\n'
    return 0
  fi
  now="$(date -u +%s)"
  printf '%s\n' "$((now - mtime))"
}

status_json() {
  local source_exists install_exists loaded_state scanner_ok stop_active global_stop_active stale_lock age cadence stdout stderr status warnings
  source_exists=false
  install_exists=false
  loaded_state=false
  scanner_ok=false
  stop_active=false
  global_stop_active=false
  stale_lock=false
  [[ -f "$SOURCE_PLIST" ]] && source_exists=true
  [[ -f "$INSTALL_PLIST" ]] && install_exists=true
  [[ -x "$SCANNER" ]] && scanner_ok=true
  [[ -f "$STOP_FILE" ]] && stop_active=true
  [[ -f "$GLOBAL_STOP_FILE" ]] && global_stop_active=true
  loaded && loaded_state=true
  age="$(lock_age_s "$SCANNER_LOCK")"
  if [[ -e "$SCANNER_LOCK" && "$age" -ge "$STALE_LOCK_SECONDS" ]]; then
    stale_lock=true
  fi
  cadence="$(plist_value "$INSTALL_PLIST" StartInterval || plist_value "$SOURCE_PLIST" StartInterval || printf 'null')"
  stdout="$(plist_value "$INSTALL_PLIST" StandardOutPath || plist_value "$SOURCE_PLIST" StandardOutPath || printf '')"
  stderr="$(plist_value "$INSTALL_PLIST" StandardErrorPath || plist_value "$SOURCE_PLIST" StandardErrorPath || printf '')"
  status="pass"
  warnings="[]"
  if [[ "$source_exists" != true || "$install_exists" != true || "$scanner_ok" != true ]]; then
    status="warn"
    warnings="$(jq -nc \
      --argjson source "$(bool_json "$source_exists")" \
      --argjson install "$(bool_json "$install_exists")" \
      --argjson scanner "$(bool_json "$scanner_ok")" \
      '[]
       + (if $source then [] else [{code:"source_plist_missing"}] end)
       + (if $install then [] else [{code:"install_plist_missing"}] end)
       + (if $scanner then [] else [{code:"scanner_missing"}] end)')"
  fi
  jq -ncS \
    --arg contract "$CONTRACT" \
    --arg status "$status" \
    --arg label "$LABEL" \
    --arg target "$TARGET" \
    --arg source_plist "$SOURCE_PLIST" \
    --arg install_plist "$INSTALL_PLIST" \
    --arg scanner "$SCANNER" \
    --arg stdout "$stdout" \
    --arg stderr "$stderr" \
    --arg state_dir "$STATE_DIR" \
    --arg events "$EVENTS" \
    --arg latest "$LATEST" \
    --arg run_lock "$RUN_LOCK" \
    --arg scanner_lock "$SCANNER_LOCK" \
    --argjson cadence "${cadence:-null}" \
    --argjson age "$age" \
    --argjson source_exists "$(bool_json "$source_exists")" \
    --argjson install_exists "$(bool_json "$install_exists")" \
    --argjson loaded_state "$(bool_json "$loaded_state")" \
    --argjson scanner_ok "$(bool_json "$scanner_ok")" \
    --argjson stop_active "$(bool_json "$stop_active")" \
    --argjson global_stop_active "$(bool_json "$global_stop_active")" \
    --argjson stale_lock "$(bool_json "$stale_lock")" \
    --argjson warnings "$warnings" \
    '{
      schema_version: "fleet-coherence-launchd-status/v1",
      status: $status,
      contract: $contract,
      l112_observed: "OK_phase1b_launchd",
      label: $label,
      target: $target,
      source_plist: $source_plist,
      install_plist: $install_plist,
      source_plist_exists: $source_exists,
      install_plist_exists: $install_exists,
      loaded: $loaded_state,
      scanner: $scanner,
      scanner_executable: $scanner_ok,
      cadence_seconds: $cadence,
      stdout_path: $stdout,
      stderr_path: $stderr,
      state_dir: $state_dir,
      events_path: $events,
      latest_path: $latest,
      run_lock: $run_lock,
      scanner_lock: $scanner_lock,
      scanner_lock_age_s: $age,
      stale_lock: $stale_lock,
      stop_active: $stop_active,
      global_stop_active: $global_stop_active,
      warnings: $warnings
    }'
}

install_json() {
  local actions installed
  actions="$(jq -ncS --arg source "$SOURCE_PLIST" --arg target "$INSTALL_PLIST" --argjson cadence "$CADENCE_SECONDS" \
    '[{action:"render_source_plist",path:$source},{action:"install_launchagent",path:$target},{action:"set_start_interval",seconds:$cadence},{action:"ensure_log_paths"}]')"
  if [[ "$APPLY" -eq 1 ]]; then
    write_plist_file "$SOURCE_PLIST"
    write_plist_file "$INSTALL_PLIST"
    installed=true
  else
    installed=false
  fi
  jq -ncS \
    --arg contract "$CONTRACT" \
    --arg source "$SOURCE_PLIST" \
    --arg target "$INSTALL_PLIST" \
    --arg label "$LABEL" \
    --argjson actions "$actions" \
    --argjson apply "$APPLY" \
    --argjson installed "$(bool_json "$installed")" \
    '{schema_version:"fleet-coherence-launchd-install/v1",status:"pass",contract:$contract,l112_observed:"OK_phase1b_launchd",label:$label,source_plist:$source,install_plist:$target,applied:($apply == 1),dry_run:($apply != 1),installed:$installed,planned_actions:$actions}'
}

load_json() {
  local actions loaded_state print_exit=1
  actions="$(jq -ncS --arg target "$TARGET" --arg plist "$INSTALL_PLIST" '[{action:"bootstrap",target:$target,plist:$plist},{action:"kickstart",target:$target}]')"
  if [[ "$APPLY" -eq 1 ]]; then
    [[ -f "$INSTALL_PLIST" ]] || write_plist_file "$INSTALL_PLIST"
    if loaded; then
      "$LAUNCHCTL" bootout "$TARGET" >/dev/null 2>&1 || true
    fi
    "$LAUNCHCTL" bootstrap "$DOMAIN" "$INSTALL_PLIST"
    "$LAUNCHCTL" kickstart -k "$TARGET" >/dev/null 2>&1 || true
  fi
  loaded_state=false
  if loaded; then
    loaded_state=true
    print_exit=0
  fi
  jq -ncS \
    --arg contract "$CONTRACT" \
    --arg label "$LABEL" \
    --arg target "$TARGET" \
    --arg plist "$INSTALL_PLIST" \
    --argjson apply "$APPLY" \
    --argjson loaded "$(bool_json "$loaded_state")" \
    --argjson print_exit "$print_exit" \
    --argjson actions "$actions" \
    '{schema_version:"fleet-coherence-launchd-load/v1",status:(if $loaded or ($apply != 1) then "pass" else "warn" end),contract:$contract,l112_observed:"OK_phase1b_launchd",label:$label,target:$target,install_plist:$plist,applied:($apply == 1),dry_run:($apply != 1),loaded:$loaded,launchctl_print_exit:$print_exit,planned_actions:$actions}'
}

unload_json() {
  local actions loaded_state print_exit=1
  actions="$(jq -ncS --arg target "$TARGET" '[{action:"bootout_if_loaded",target:$target}]')"
  if [[ "$APPLY" -eq 1 ]] && loaded; then
    "$LAUNCHCTL" bootout "$TARGET" >/dev/null 2>&1 || true
  fi
  loaded_state=false
  if loaded; then
    loaded_state=true
    print_exit=0
  fi
  jq -ncS \
    --arg contract "$CONTRACT" \
    --arg label "$LABEL" \
    --arg target "$TARGET" \
    --argjson apply "$APPLY" \
    --argjson loaded "$(bool_json "$loaded_state")" \
    --argjson print_exit "$print_exit" \
    --argjson actions "$actions" \
    '{schema_version:"fleet-coherence-launchd-unload/v1",status:(if ($loaded == false) then "pass" else "warn" end),contract:$contract,l112_observed:"OK_phase1b_launchd",label:$label,target:$target,applied:($apply == 1),dry_run:($apply != 1),loaded:$loaded,launchctl_print_exit:$print_exit,planned_actions:$actions}'
}

emit_runtime_drift_event() {
  local age="$1" now row
  now="$(now_iso)"
  row="$(jq -ncS \
    --arg now "$now" \
    --arg lock "$SCANNER_LOCK" \
    --arg contract "$CONTRACT" \
    --argjson age "$age" \
    '{
      actions: {
        bead_id: null,
        no_bead_reason: "phase 1b lifecycle surfaced stale scanner lock as detector_runtime_drift",
        receipt_required: false,
        shadow_mode: true,
        would_bead: false,
        would_l61: false,
        would_no_bead_reason: "phase 1b lifecycle surfaced stale scanner lock as detector_runtime_drift"
      },
      class: "detector_runtime_drift",
      confidence: 1,
      dedupe_key: "detector_runtime_drift:fleet-coherence:stale_scan_lock",
      detector: "fleet-coherence",
      detector_git_sha: "runtime",
      detector_version: $contract,
      event_id: ("fc_runtime_drift_stale_scan_lock_" + ($now | gsub("[^0-9A-Za-z]"; ""))),
      evidence: {
        drift_class: "stale_scan_lock",
        lock_path: $lock,
        stale_lock_age_s: $age,
        surfaced_as: "detector_runtime_drift"
      },
      first_seen_ts: $now,
      l61: {
        agent_mail_attempted: false,
        agent_mail_from: null,
        agent_mail_message_id: null,
        agent_mail_sent_at: null,
        agent_mail_to: null,
        degraded_reason: null,
        fleet_mail_identity_source: "not_applicable",
        l61_pairing_status: "not_attempted",
        ntm_attempted: false,
        ntm_pane: null,
        ntm_result: null,
        ntm_sent_at: null,
        ntm_session: null,
        project_key: null,
        vault_token_validated: false
      },
      l62: {repair_callback_required: false, sd_count: 0, sd_ids: []},
      l63: {recovery_action_requires_drill: false, recovery_drill_ids: []},
      last_seen_ts: $now,
      pane: null,
      raw_source_refs: [{path: $lock, source: "scanner-overlap-lock"}],
      record_type: "event",
      resend_after_ts: null,
      sample_count: 1,
      sample_window_s: 0,
      schema_version: 2,
      seen_count: 1,
      session: "fleet-coherence",
      severity: "warning",
      source_age_s: 0,
      source_ts: $now,
      state: "open",
      suppression_id: null,
      ts: $now
    }')"
  fc_append_event "$row" "$EVENTS" "$LATEST"
}

run_json() {
  local row age scanner_out scanner_err scanner_rc scanner_status extra receipt lock_status
  ensure_dirs
  trap 'signal_handler HUP' HUP
  trap 'signal_handler TERM' TERM
  trap 'signal_handler INT' INT

  if ! mkdir "$RUN_LOCK" 2>/dev/null; then
    row="$(lifecycle_row "skipped_lock" "wrapper_lock_held")"
    write_lifecycle_row "$row"
    printf '%s\n' "$row"
    return 0
  fi
  RUN_LOCK_ACQUIRED=1

  if [[ -f "$STOP_FILE" || -f "$GLOBAL_STOP_FILE" ]]; then
    row="$(lifecycle_row "stopped" "stop_file_present")"
    write_lifecycle_row "$row"
    cleanup_run_lock
    printf '%s\n' "$row"
    return 0
  fi

  age="$(lock_age_s "$SCANNER_LOCK")"
  if [[ -e "$SCANNER_LOCK" && "$age" -ge "$STALE_LOCK_SECONDS" ]]; then
    receipt="$(emit_runtime_drift_event "$age")"
    row="$(lifecycle_row "stale_lock" "detector_runtime_drift_emitted")"
    row="$(printf '%s\n' "$row" | jq -cS --argjson age "$age" --argjson receipt "$receipt" '. + {stale_lock_age_s:$age, drift_event_written:true, write_receipt:$receipt}')"
    write_lifecycle_row "$row"
    cleanup_run_lock
    printf '%s\n' "$row"
    return 0
  fi

  scanner_out="$(mktemp "${TMPDIR:-/tmp}/fleet-coherence-scanner.out.XXXXXX")"
  scanner_err="$(mktemp "${TMPDIR:-/tmp}/fleet-coherence-scanner.err.XXXXXX")"
  set +e
  "$SCANNER" --state-dir "$STATE_DIR" --events "$EVENTS" --latest "$LATEST" --once --json >"$scanner_out" 2>"$scanner_err" &
  CHILD_PID=$!
  while kill -0 "$CHILD_PID" >/dev/null 2>&1; do
    sleep 0.1
  done
  wait "$CHILD_PID"
  scanner_rc=$?
  set -e
  CHILD_PID=0

  scanner_status="null"
  if jq empty "$scanner_out" >/dev/null 2>&1; then
    scanner_status="$(jq -cS '.status // "unknown"' "$scanner_out")"
  fi
  lock_status="scanner_completed"
  if [[ "$scanner_rc" -ne 0 ]]; then
    lock_status="scanner_error"
  fi
  extra="$(jq -nc --arg out "$scanner_out" --arg err "$scanner_err" --rawfile stderr "$scanner_err" '{scanner_stdout_path:$out,scanner_stderr_path:$err,scanner_stderr_sample:($stderr | .[0:1000])}')"
  row="$(lifecycle_row "$(if [[ "$scanner_rc" -eq 0 ]]; then printf 'pass'; else printf 'warn'; fi)" "$lock_status" "$scanner_rc" "$scanner_status" "$extra")"
  write_lifecycle_row "$row"
  rm -f "$scanner_out" "$scanner_err"
  cleanup_run_lock
  printf '%s\n' "$row"
}

validate_plist_json() {
  local source_ok install_ok label_ok cadence_ok helper_ok status
  source_ok=false
  install_ok=false
  label_ok=false
  cadence_ok=false
  helper_ok=false
  [[ -f "$SOURCE_PLIST" ]] && "$PLUTIL" -lint "$SOURCE_PLIST" >/dev/null && source_ok=true
  [[ -f "$INSTALL_PLIST" ]] && "$PLUTIL" -lint "$INSTALL_PLIST" >/dev/null && install_ok=true
  if [[ -f "$SOURCE_PLIST" ]] && [[ "$(plist_value "$SOURCE_PLIST" Label || true)" == "$LABEL" ]]; then
    label_ok=true
  fi
  if [[ -f "$SOURCE_PLIST" ]] && [[ "$(plist_value "$SOURCE_PLIST" StartInterval || true)" == "$CADENCE_SECONDS" ]]; then
    cadence_ok=true
  fi
  if [[ -f "$SOURCE_PLIST" ]] && "$PLUTIL" -p "$SOURCE_PLIST" 2>/dev/null | grep -F 'fleet-coherence-launchd.sh run --json' >/dev/null; then
    helper_ok=true
  fi
  status="pass"
  if [[ "$source_ok" != true || "$label_ok" != true || "$cadence_ok" != true || "$helper_ok" != true ]]; then
    status="fail"
  fi
  jq -ncS \
    --arg status "$status" \
    --arg label "$LABEL" \
    --arg source "$SOURCE_PLIST" \
    --arg install "$INSTALL_PLIST" \
    --argjson source_ok "$(bool_json "$source_ok")" \
    --argjson install_ok "$(bool_json "$install_ok")" \
    --argjson label_ok "$(bool_json "$label_ok")" \
    --argjson cadence_ok "$(bool_json "$cadence_ok")" \
    --argjson helper_ok "$(bool_json "$helper_ok")" \
    '{schema_version:"fleet-coherence-launchd-validate/v1",status:$status,l112_observed:"OK_phase1b_launchd",label:$label,source_plist:$source,install_plist:$install,source_plist_lint:$source_ok,install_plist_lint:$install_ok,label_ok:$label_ok,cadence_ok:$cadence_ok,helper_command_ok:$helper_ok}'
}

if [[ $# -gt 0 ]]; then
  case "$1" in
    install|load|unload|status|run|validate)
      MODE="$1"
      shift
      ;;
    --help|-h)
      usage
      exit 0
      ;;
  esac
fi

VALIDATE_THING=""
while [[ $# -gt 0 ]]; do
  case "$1" in
    --json) JSON_OUT=1; shift ;;
    --apply) APPLY=1; shift ;;
    --dry-run) APPLY=0; shift ;;
    plist)
      VALIDATE_THING="plist"
      shift
      ;;
    --help|-h)
      usage
      exit 0
      ;;
    *)
      printf 'unknown option: %s\n' "$1" >&2
      usage >&2
      exit 64
      ;;
  esac
done

fc_require_jq || exit 127
require_uint FLEET_COHERENCE_CADENCE_SECONDS "$CADENCE_SECONDS"
require_uint FLEET_COHERENCE_STALE_LOCK_SECONDS "$STALE_LOCK_SECONDS"

case "$MODE" in
  install) install_json | emit ;;
  load) load_json | emit ;;
  unload) unload_json | emit ;;
  status) status_json | emit ;;
  run) run_json ;;
  validate)
    [[ "$VALIDATE_THING" == "plist" ]] || { printf 'validate requires plist\n' >&2; exit 64; }
    validate_plist_json | emit
    ;;
  *)
    usage >&2
    exit 64
    ;;
esac
