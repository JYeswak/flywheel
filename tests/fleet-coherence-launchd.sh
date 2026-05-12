#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd -P)"
SCRIPT="$ROOT/.flywheel/scripts/fleet-coherence-launchd.sh"
SOURCE_PLIST="$ROOT/launchd/ai.zeststream.fleet-coherence.plist"
TMP="$(mktemp -d "${TMPDIR:-/tmp}/fleet-coherence-launchd.XXXXXX")"
trap 'rm -rf "$TMP"' EXIT

pass_count=0
fail_count=0

pass() { printf 'PASS %s\n' "$1"; pass_count=$((pass_count + 1)); }
fail() { printf 'FAIL %s\n' "$1" >&2; fail_count=$((fail_count + 1)); }

assert_jq() {
  local file="$1" filter="$2" label="$3"
  if jq -e "$filter" "$file" >/dev/null; then
    pass "$label"
  else
    fail "$label"
    jq . "$file" >&2 || true
  fi
}

write_fake_launchctl() {
  cat >"$TMP/launchctl" <<'SH'
#!/usr/bin/env bash
set -euo pipefail
state="${FAKE_LAUNCHCTL_STATE:?}"
log="${FAKE_LAUNCHCTL_LOG:?}"
cmd="${1:-}"
shift || true
case "$cmd" in
  print)
    printf 'print %s\n' "$*" >>"$log"
    label="${1##*/}"
    if grep -Fqx "$label" "$state" 2>/dev/null; then
      printf '%s = {\n  state = running\n}\n' "$1"
      exit 0
    fi
    exit 3
    ;;
  bootstrap)
    printf 'bootstrap %s\n' "$*" >>"$log"
    plist="${2:?plist required}"
    label="$(python3 - "$plist" <<'PY'
import plistlib, sys
with open(sys.argv[1], "rb") as fh:
    print(plistlib.load(fh).get("Label", ""))
PY
)"
    grep -Fqx "$label" "$state" 2>/dev/null || printf '%s\n' "$label" >>"$state"
    ;;
  bootout)
    printf 'bootout %s\n' "$*" >>"$log"
    label="${1##*/}"
    if [[ -f "$state" ]]; then
      grep -Fvx "$label" "$state" >"$state.tmp" || true
      mv "$state.tmp" "$state"
    fi
    ;;
  kickstart)
    printf 'kickstart %s\n' "$*" >>"$log"
    ;;
  *)
    printf 'unsupported fake launchctl: %s\n' "$cmd" >&2
    exit 9
    ;;
esac
SH
  chmod +x "$TMP/launchctl"
}

write_fake_scanner() {
  cat >"$TMP/scanner" <<'SH'
#!/usr/bin/env bash
set -euo pipefail
printf '%s\n' "$*" >>"${FAKE_SCANNER_LOG:?}"
if [[ "${FAKE_SCANNER_SLEEP:-0}" != "0" ]]; then
  sleep "$FAKE_SCANNER_SLEEP"
fi
jq -nc '{status:"ok",l112_observed:"OK_phase1a_scanner",appended:true}'
SH
  chmod +x "$TMP/scanner"
}

write_fake_launchctl
write_fake_scanner
: >"$TMP/launchctl-state"
: >"$TMP/launchctl.log"
: >"$TMP/scanner.log"

env_base=(
  "FLEET_COHERENCE_SOURCE_PLIST=$TMP/source.plist"
  "FLEET_COHERENCE_INSTALL_PLIST=$TMP/home/Library/LaunchAgents/com.zeststream.flywheel.fleet-coherence.plist"
  "FLEET_COHERENCE_LAUNCHCTL=$TMP/launchctl"
  "FLEET_COHERENCE_SCANNER=$TMP/scanner"
  "FLEET_COHERENCE_STATE_DIR=$TMP/state"
  "FLEET_COHERENCE_EVENTS=$TMP/state/fleet-coherence-events-v2.jsonl"
  "FLEET_COHERENCE_LATEST=$TMP/state/fleet-coherence-latest.json"
  "FLEET_COHERENCE_LIFECYCLE_LEDGER=$TMP/state/fleet-coherence-launchd.jsonl"
  "FLEET_COHERENCE_LIFECYCLE_LATEST=$TMP/state/fleet-coherence-launchd-latest.json"
  "FLEET_COHERENCE_STDOUT_PATH=$TMP/logs/out.log"
  "FLEET_COHERENCE_STDERR_PATH=$TMP/logs/err.log"
  "FLEET_COHERENCE_STOP_FILE=$TMP/STOP-fleet-coherence"
  "FLEET_COHERENCE_GLOBAL_STOP_FILE=$TMP/STOP-ALL"
  "FLEET_COHERENCE_STALE_LOCK_SECONDS=0"
  "FAKE_LAUNCHCTL_STATE=$TMP/launchctl-state"
  "FAKE_LAUNCHCTL_LOG=$TMP/launchctl.log"
  "FAKE_SCANNER_LOG=$TMP/scanner.log"
)

bash -n "$SCRIPT" && pass "script_syntax" || fail "script_syntax"
plutil -lint "$SOURCE_PLIST" >/dev/null && pass "source_fixture_plist_lint" || fail "source_fixture_plist_lint"
if grep -q 'install --dry-run|--apply' <("$SCRIPT" --help) \
  && grep -q 'load --dry-run|--apply' <("$SCRIPT" --help) \
  && grep -q 'unload --dry-run|--apply' <("$SCRIPT" --help) \
  && grep -q 'status' <("$SCRIPT" --help); then
  pass "help_documents_lifecycle_commands"
else
  fail "help_documents_lifecycle_commands"
fi

env "${env_base[@]}" "$SCRIPT" status --json >"$TMP/status-missing.json"
assert_jq "$TMP/status-missing.json" '.status == "warn" and .source_plist_exists == false and .install_plist_exists == false' "status_reports_missing_plists"

env "${env_base[@]}" "$SCRIPT" install --dry-run --json >"$TMP/install-dry.json"
assert_jq "$TMP/install-dry.json" '.dry_run == true and .installed == false and any(.planned_actions[]?; .action == "install_launchagent")' "install_dry_run_plans"

env "${env_base[@]}" "$SCRIPT" install --apply --json >"$TMP/install.json"
assert_jq "$TMP/install.json" '.applied == true and .installed == true and .label == "com.zeststream.flywheel.fleet-coherence"' "install_apply_writes_plists"
plutil -lint "$TMP/source.plist" >/dev/null && pass "rendered_source_plist_lint" || fail "rendered_source_plist_lint"
plutil -lint "$TMP/home/Library/LaunchAgents/com.zeststream.flywheel.fleet-coherence.plist" >/dev/null && pass "installed_plist_lint" || fail "installed_plist_lint"
if plutil -extract Label raw "$TMP/source.plist" | grep -qx 'com.zeststream.flywheel.fleet-coherence' \
  && plutil -extract StartInterval raw "$TMP/source.plist" | grep -qx '60' \
  && plutil -extract StandardOutPath raw "$TMP/source.plist" | grep -qx "$TMP/logs/out.log" \
  && plutil -p "$TMP/source.plist" | grep -Fq 'fleet-coherence-launchd.sh run --json'; then
  pass "plist_label_cadence_logs_command"
else
  fail "plist_label_cadence_logs_command"
fi

env "${env_base[@]}" "$SCRIPT" validate plist --json >"$TMP/validate.json"
assert_jq "$TMP/validate.json" '.status == "pass" and .label_ok == true and .cadence_ok == true and .helper_command_ok == true' "validate_plist_contract"

env "${env_base[@]}" "$SCRIPT" load --apply --json >"$TMP/load.json"
assert_jq "$TMP/load.json" '.applied == true and .loaded == true and .launchctl_print_exit == 0' "load_bootstraps_and_kickstarts"
grep -q '^bootstrap ' "$TMP/launchctl.log" && grep -q '^kickstart ' "$TMP/launchctl.log" && pass "load_calls_bootstrap_and_kickstart" || fail "load_calls_bootstrap_and_kickstart"

env "${env_base[@]}" "$SCRIPT" run --json >"$TMP/run.json"
assert_jq "$TMP/run.json" '.status == "pass" and .decision == "scanner_completed" and .scanner_rc == 0 and .scanner_status == "ok"' "run_invokes_scanner"
grep -q -- '--once --json' "$TMP/scanner.log" && pass "run_passes_once_json_to_scanner" || fail "run_passes_once_json_to_scanner"

touch "$TMP/STOP-fleet-coherence"
env "${env_base[@]}" "$SCRIPT" run --json >"$TMP/stop.json"
assert_jq "$TMP/stop.json" '.status == "stopped" and .decision == "stop_file_present"' "stop_file_blocks_run"
rm "$TMP/STOP-fleet-coherence"

mkdir -p "$TMP/state/fleet-coherence-scan.lock"
env "${env_base[@]}" "$SCRIPT" run --json >"$TMP/stale.json"
assert_jq "$TMP/stale.json" '.status == "stale_lock" and .decision == "detector_runtime_drift_emitted" and .drift_event_written == true and .write_receipt.l112_observed == "OK_fleet_coherence_writer"' "stale_lock_emits_runtime_drift"
assert_jq "$TMP/state/fleet-coherence-events-v2.jsonl" 'select(.class == "detector_runtime_drift" and .evidence.drift_class == "stale_scan_lock")' "stale_lock_event_jsonl_written"
rm -rf "$TMP/state/fleet-coherence-scan.lock"

FAKE_SCANNER_SLEEP=5 env "${env_base[@]}" "$SCRIPT" run --json >"$TMP/hup.json" &
run_pid=$!
sleep 0.5
kill -HUP "$run_pid"
wait "$run_pid" || true
assert_jq "$TMP/hup.json" '.status == "signaled" and .signal == "HUP" and .graceful_cleanup == true' "hup_signal_emits_receipt"

env "${env_base[@]}" "$SCRIPT" unload --apply --json >"$TMP/unload.json"
assert_jq "$TMP/unload.json" '.applied == true and .loaded == false and .status == "pass"' "unload_bootouts_cleanly"

printf 'OK_phase1b_launchd\n'
printf 'SUMMARY pass=%d fail=%d\n' "$pass_count" "$fail_count"
[[ "$fail_count" -eq 0 && "$pass_count" -ge 19 ]]
