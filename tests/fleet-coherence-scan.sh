#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd -P)"
SCANNER="$ROOT/.flywheel/scripts/fleet-coherence-scan.sh"
FIXTURE="$ROOT/.flywheel/fixtures/fleet-coherence-scan-sample.json"
TMP="$(mktemp -d "${TMPDIR:-/tmp}/fleet-coherence-scan.XXXXXX")"
trap 'rm -rf "$TMP"' EXIT

pass_count=0
fail_count=0

pass() { printf 'PASS %s\n' "$1"; pass_count=$((pass_count + 1)); }
fail() { printf 'FAIL %s\n' "$1" >&2; fail_count=$((fail_count + 1)); }

line_count() {
  [[ -f "$1" ]] || { printf '0'; return 0; }
  wc -l <"$1" | tr -d ' '
}

assert_jq() {
  local file="$1" filter="$2" label="$3"
  if jq -e "$filter" "$file" >/dev/null; then
    pass "$label"
  else
    fail "$label"
    jq . "$file" >&2 || true
  fi
}

make_fake_ntm() {
  cat >"$TMP/ntm" <<'EOF'
#!/usr/bin/env bash
set -euo pipefail
mode="${FAKE_NTM_MODE:-ok}"

if [[ "${1:-}" == "list" && "${2:-}" == "--json" ]]; then
  case "$mode" in
    timeout)
      printf '{"sessions":[{"name":"slow"}]}\n'
      ;;
    *)
      printf '{"sessions":[{"name":"alpha"},{"name":"beta"}]}\n'
      ;;
  esac
  exit 0
fi

if [[ "${1:-}" == "health" && "${3:-}" == "--json" ]]; then
  session="$2"
  case "$mode:$session" in
    disappearing:beta)
      printf 'session disappeared\n' >&2
      exit 7
      ;;
    timeout:slow)
      sleep 3
      printf '{"status":"ok","panes":[{"pane":0}]}\n'
      exit 0
      ;;
    *)
      if [[ "$session" == "alpha" ]]; then
        printf '{"status":"ok","panes":[{"pane":0},{"pane":1}]}\n'
      else
        printf '{"status":"ok","panes":[{"pane":0}]}\n'
      fi
      exit 0
      ;;
  esac
fi

printf 'unsupported fake ntm args: %s\n' "$*" >&2
exit 64
EOF
  chmod +x "$TMP/ntm"
}

make_inputs() {
  local dir="$1"
  mkdir -p "$dir"
  cat >"$dir/topology.jsonl" <<'EOF'
{"ts":"2026-05-07T00:00:00Z","session":"alpha","pane":0,"role":"orchestrator","expected_pane_count":2}
{"ts":"2026-05-07T00:00:01Z","session":"beta","pane":0,"role":"worker","expected_pane_count":1}
EOF
  cat >"$dir/roster.json" <<'EOF'
{"members":[{"session":"alpha","pane":0,"role":"orchestrator"},{"session":"beta","pane":0,"role":"worker"}]}
EOF
  cat >"$dir/pane-work-signal.jsonl" <<'EOF'
{"ts":"2026-05-07T00:00:02Z","session":"alpha","pane":0,"classification":"working"}
{"ts":"2026-05-07T00:00:03Z","session":"beta","pane":0,"classification":"idle"}
EOF
}

run_scan() {
  local name="$1" mode="$2" topology="$3" health_timeout="${4:-2}" lock_timeout="${5:-1}"
  local state="$TMP/state-$name"
  mkdir -p "$state"
  FLYWHEEL_FLEET_COHERENCE_NOW="2026-05-07T00:00:00Z" \
  FAKE_NTM_MODE="$mode" \
    "$SCANNER" --once --json \
      --state-dir "$state" \
      --topology-file "$topology" \
      --roster-file "$TMP/inputs/roster.json" \
      --pane-work-signal-file "$TMP/inputs/pane-work-signal.jsonl" \
      --ntm-bin "$TMP/ntm" \
      --health-timeout-sec "$health_timeout" \
      --pane-timeout-sec 1 \
      --total-timeout-sec 10 \
      --lock-timeout-sec "$lock_timeout" \
      >"$TMP/$name.json"
}

make_fake_ntm
make_inputs "$TMP/inputs"

bash -n "$SCANNER" && pass "scanner_syntax" || fail "scanner_syntax"
jq empty "$FIXTURE" && pass "sample_fixture_json_valid" || fail "sample_fixture_json_valid"
assert_jq "$FIXTURE" \
  '.schema_version == "fleet-coherence-scan-sample/v1" and .l112_observed == "OK_phase1a_scanner" and .event.class == "fleet_scan_heartbeat"' \
  "sample_fixture_contract"

"$SCANNER" --state-dir "$TMP/info-state" --info --json >"$TMP/info.json"
assert_jq "$TMP/info.json" \
  '.status == "ok" and .scanner_contract == "fleet-coherence-scanner/v1" and .writes_via == "fleet-coherence-lib.sh fc_append_event" and .p95_targets_sec.sessions_8 == 10' \
  "info_reports_phase_1a_contract"
"$SCANNER" --schema --json >"$TMP/schema.json"
assert_jq "$TMP/schema.json" \
  '.schema_version == "fleet-coherence-scanner/schema/v1" and .emitted_event.class == "fleet_scan_heartbeat" and .drift_classification == "out_of_scope_phase_1a"' \
  "schema_reports_neutral_heartbeat"

run_scan ok ok "$TMP/inputs/topology.jsonl"
assert_jq "$TMP/ok.json" \
  '.status == "ok" and .appended == true and .l112_observed == "OK_phase1a_scanner" and .write_receipt.l112_observed == "OK_fleet_coherence_writer"' \
  "ok_scan_appends_via_writer"
jq empty "$TMP/state-ok/fleet-coherence-events-v2.jsonl" && pass "ok_events_jsonl_valid" || fail "ok_events_jsonl_valid"
[[ "$(line_count "$TMP/state-ok/fleet-coherence-events-v2.jsonl")" == "1" ]] && pass "ok_scan_writes_one_row" || fail "ok_scan_writes_one_row"
assert_jq "$TMP/state-ok/fleet-coherence-latest.json" \
  '.schema_version == "fleet-coherence-latest/v1" and .latest_event.class == "fleet_scan_heartbeat"' \
  "ok_scan_updates_latest_snapshot"
assert_jq "$TMP/state-ok/fleet-coherence-events-v2.jsonl" \
  'select(.class == "fleet_scan_heartbeat" and .actions.shadow_mode == true and (.evidence.phase_scope | contains("no drift classification")))' \
  "event_row_is_neutral_heartbeat"

run_scan missing-topology ok "$TMP/inputs/missing-topology.jsonl"
assert_jq "$TMP/missing-topology.json" \
  '.status == "warn" and (.warnings | index("topology_missing")) and .evidence.sources.topology.status == "missing"' \
  "missing_topology_warns_nonfatal"

run_scan disappearing disappearing "$TMP/inputs/topology.jsonl"
assert_jq "$TMP/disappearing.json" \
  '.status == "warn" and .evidence.sources.ntm.health.failed_count == 1 and (.evidence.sources.ntm.health.sessions[] | select(.session == "beta" and .status == "error"))' \
  "disappearing_session_warns_nonfatal"

run_scan timeout timeout "$TMP/inputs/topology.jsonl" 1
assert_jq "$TMP/timeout.json" \
  '.status == "warn" and .evidence.sources.ntm.health.timeout_count == 1 and (.warnings | index("ntm_health_timeout"))' \
  "command_timeout_warns_nonfatal"

mkdir -p "$TMP/state-lock/fleet-coherence-scan.lock"
FAKE_NTM_MODE=ok "$SCANNER" --once --json \
  --state-dir "$TMP/state-lock" \
  --topology-file "$TMP/inputs/topology.jsonl" \
  --roster-file "$TMP/inputs/roster.json" \
  --pane-work-signal-file "$TMP/inputs/pane-work-signal.jsonl" \
  --ntm-bin "$TMP/ntm" \
  --lock-timeout-sec 0 \
  >"$TMP/lock.json"
assert_jq "$TMP/lock.json" '.status == "skipped_lock" and .appended == false' "overlap_lock_skips_without_append"
[[ ! -f "$TMP/state-lock/fleet-coherence-events-v2.jsonl" ]] && pass "overlap_lock_does_not_write_events" || fail "overlap_lock_does_not_write_events"

mkdir -p "$TMP/nojq-bin"
ln -s /usr/bin/dirname "$TMP/nojq-bin/dirname"
set +e
env -i HOME="$HOME" PATH="$TMP/nojq-bin" /bin/bash "$SCANNER" --info --json >"$TMP/nojq.out" 2>"$TMP/nojq.err"
no_jq_rc=$?
set -e
[[ "$no_jq_rc" -eq 127 ]] && pass "missing_jq_returns_127" || fail "missing_jq_returns_127"
grep -q 'requires jq' "$TMP/nojq.err" && pass "missing_jq_reports_clear_error" || fail "missing_jq_reports_clear_error"

printf 'OK_phase1a_scanner\n'
printf 'SUMMARY pass=%d fail=%d\n' "$pass_count" "$fail_count"
[[ "$fail_count" -eq 0 && "$pass_count" -ge 17 ]]
