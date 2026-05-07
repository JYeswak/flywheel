#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd -P)"
SCRIPT="$ROOT/.flywheel/scripts/team-pulse-heartbeat.sh"
PLIST="$ROOT/.flywheel/launchd/ai.zeststream.team-pulse-heartbeat.plist"
TMP="$(mktemp -d "${TMPDIR:-/tmp}/team-pulse-heartbeat.XXXXXX")"
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

write_fake_ntm() {
  cat >"$TMP/ntm" <<'SH'
#!/usr/bin/env bash
set -euo pipefail
if [[ "${1:-}" != "health" ]]; then
  printf 'unsupported fake ntm: %s\n' "$*" >&2
  exit 2
fi
case "${2:-}" in
  alpha)
    jq -nc '{status:"ok",panes:[
      {pane:1,status:"ok",process_status:"running",agent_type:"codex"},
      {pane:2,status:"ok",process_status:"running",agent_type:"codex"},
      {pane:3,status:"error",process_status:"exited",agent_type:"codex"}
    ]}'
    ;;
  gamma)
    jq -nc '{status:"ok",panes:[
      {pane:1,status:"ok",process_status:"running",agent_type:"claude"}
    ]}'
    ;;
  *)
    jq -nc '{status:"missing",panes:[]}'
    exit 1
    ;;
esac
SH
  chmod +x "$TMP/ntm"
}

write_inputs() {
  mkdir -p "$TMP/repo-alpha/.flywheel/runtime/flywheel-loop" "$TMP/repo-gamma/.flywheel/runtime/flywheel-loop"
  jq -nc '{ts:"2026-05-07T00:00:00Z",dispatch_status:"sent"}' >"$TMP/repo-alpha/.flywheel/runtime/flywheel-loop/last_run.json"
  jq -nc '{ts:"2026-05-07T00:01:00Z",event:"dispatch_sent"}' >"$TMP/repo-alpha/.flywheel/dispatch-log.jsonl"
  {
    jq -nc --arg repo "$TMP/repo-alpha" '{ts:"2026-05-07T00:00:00Z",event:"session_active",session:"alpha",repo_path:$repo,orchestrator:{pane:1,kind:"codex"},workers:[{pane:2,kind:"codex"},{pane:3,kind:"codex"}],registered_by:"fixture",available_for_borrow:false}'
    jq -nc '{ts:"2026-05-07T00:00:00Z",event:"session_dormant",session:"beta",orchestrator:{pane:1,kind:"codex"},workers:[{pane:2,kind:"codex"}],registered_by:"fixture"}'
    jq -nc --arg repo "$TMP/repo-gamma" '{ts:"2026-05-07T00:00:00Z",event:"session_active",session:"gamma",repo_path:$repo,orchestrator:{pane:1,kind:"claude"},worker_panes:[],registered_by:"fixture",available_for_borrow:false}'
  } >"$TMP/roster.jsonl"
  {
    jq -nc --arg repo "$TMP/repo-alpha" '{session:"alpha",effective_at:"2026-05-07T00:00:00Z",repo_path:$repo,orchestrator_pane:1,worker_panes:[2,3],worker_kinds:{"2":"codex","3":"codex"}}'
    jq -nc --arg repo "$TMP/repo-gamma" '{session:"gamma",effective_at:"2026-05-07T00:00:00Z",repo_path:$repo,orchestrator_pane:1,worker_panes:[],worker_kinds:{}}'
  } >"$TMP/topology.jsonl"
}

write_fake_ntm
write_inputs

bash -n "$SCRIPT" && pass "script_syntax" || fail "script_syntax"
plutil -lint "$PLIST" >/dev/null && pass "source_plist_lint" || fail "source_plist_lint"

"$SCRIPT" schema pulse --json >"$TMP/schema.json"
assert_jq "$TMP/schema.json" '(.required | index("orch_pane_alive")) and (.required | index("worker_panes_dead")) and .stale_after_seconds == 900' "schema_documents_pulse_contract"

"$SCRIPT" validate plist --json >"$TMP/validate.json"
assert_jq "$TMP/validate.json" '.status == "pass" and .label_ok == true and .cadence_ok == true and .helper_command_ok == true' "validate_plist_contract"

"$SCRIPT" run --json \
  --now 2026-05-07T00:05:00Z \
  --roster "$TMP/roster.jsonl" \
  --topology "$TMP/topology.jsonl" \
  --pulse "$TMP/team-pulse.jsonl" \
  --lock-file "$TMP/team-pulse.lock" \
  --ntm-bin "$TMP/ntm" >"$TMP/run.json"

assert_jq "$TMP/run.json" '.status == "pass" and .active_confirmed_session_count == 2 and .append.rows_appended == 2' "run_writes_per_active_confirmed_session"
assert_jq "$TMP/team-pulse.jsonl" 'select(.session == "alpha" and .orch_pane_alive == true and (.worker_panes_alive == [2]) and (.worker_panes_dead == [3]) and .last_tick_age_seconds == 300 and .last_dispatch_age_seconds == 240)' "alpha_pulse_fields"
if jq -e 'select(.session == "beta")' "$TMP/team-pulse.jsonl" >/dev/null; then
  fail "unconfirmed_or_dormant_sessions_not_mutated"
else
  pass "unconfirmed_or_dormant_sessions_not_mutated"
fi

jq -s 'group_by(.session) | map(max_by(.ts)) | map({session,orch_pane_alive,worker_panes_alive,worker_panes_dead,last_tick_age_seconds,last_dispatch_age_seconds})' "$TMP/team-pulse.jsonl" >"$TMP/latest.json"
assert_jq "$TMP/latest.json" 'length == 2 and all(.[]; has("orch_pane_alive") and has("worker_panes_dead") and has("last_tick_age_seconds"))' "latest_per_session_query_has_freshness_fields"

"$SCRIPT" doctor --json \
  --now 2026-05-07T00:10:00Z \
  --roster "$TMP/roster.jsonl" \
  --pulse "$TMP/team-pulse.jsonl" >"$TMP/doctor-fresh.json"
assert_jq "$TMP/doctor-fresh.json" '.status == "warn" and .team_pulse_dead_session_count == 0 and any(.pulse_session_status[]; .session == "alpha" and .status == "DEGRADED" and .reason == "worker_panes_dead")' "doctor_reports_fresh_degraded_not_dead"

jq -nc '{schema_version:"team-pulse/v1",ts:"2026-05-07T00:00:00Z",event:"team_pulse",session:"alpha",orch_pane_alive:true,worker_panes_alive:[2],worker_panes_dead:[]}' >"$TMP/stale-pulse.jsonl"
jq -nc '{schema_version:"team-pulse/v1",ts:"2026-05-07T00:00:00Z",event:"team_pulse",session:"gamma",orch_pane_alive:true,worker_panes_alive:[],worker_panes_dead:[]}' >>"$TMP/stale-pulse.jsonl"
"$SCRIPT" doctor --json \
  --now 2026-05-07T00:20:01Z \
  --roster "$TMP/roster.jsonl" \
  --pulse "$TMP/stale-pulse.jsonl" >"$TMP/doctor-stale.json"
assert_jq "$TMP/doctor-stale.json" '.status == "fail" and .team_pulse_dead_session_count == 2 and all(.pulse_session_status[]; .status == "DEAD" and .reason == "stale_pulse")' "doctor_reports_stale_pulse_dead"

"$SCRIPT" install --dry-run --json --source-plist "$PLIST" --install-plist "$TMP/home/Library/LaunchAgents/ai.zeststream.team-pulse-heartbeat.plist" >"$TMP/install-dry.json"
assert_jq "$TMP/install-dry.json" '.applied == false and .planned_actions[0].action == "install_launchagent"' "install_dry_run_plans"

printf 'RESULT pass=%s fail=%s\n' "$pass_count" "$fail_count"
[[ "$fail_count" -eq 0 ]]
