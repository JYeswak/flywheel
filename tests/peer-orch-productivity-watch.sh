#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd -P)"
SCRIPT="$ROOT/.flywheel/scripts/peer-orch-productivity-watch.sh"
TMP="$(mktemp -d "${TMPDIR:-/tmp}/peer-orch-productivity-watch-test.XXXXXX")"
trap 'rm -rf "$TMP"' EXIT

pass_count=0
fail_count=0

pass() { printf 'PASS %s\n' "$1"; pass_count=$((pass_count + 1)); }
fail() { printf 'FAIL %s\n' "$1" >&2; fail_count=$((fail_count + 1)); }

assert_jq() {
  local file="$1" expr="$2" label="$3"
  if jq -e "$expr" "$file" >/dev/null; then
    pass "$label"
  else
    fail "$label"
    jq . "$file" >&2 || true
  fi
}

mkdir -p "$TMP/loops" "$TMP/activity" "$TMP/ready" "$TMP/doctor" "$TMP/capture" "$TMP/state"
chmod +x "$SCRIPT"
bash -n "$SCRIPT" && pass "script syntax" || fail "script syntax"
grep -F -- "f\"--pane={row['orchestrator_pane']}\", \"--no-cass-check\", row[\"escalation_packet\"]" "$SCRIPT" >/dev/null \
  && pass "productivity_escalation_no_cass_check_argv_order" || fail "productivity_escalation_no_cass_check_argv_order"

cat >"$TMP/loops/{capability-control-plane}.json" <<'JSON'
{"session":"{capability-control-plane}","active":true,"repo":"/tmp/{capability-control-plane}","orchestrator_pane":1}
JSON
cat >"$TMP/loops/{proof-product}.json" <<'JSON'
{"session":"{proof-product}","active":true,"repo":"/tmp/{proof-product}","orchestrator_pane":1}
JSON
cat >"$TMP/loops/{session}.json" <<'JSON'
{"session":"{session}","active":true,"repo":"/tmp/{session}","orchestrator_pane":1}
JSON
cat >"$TMP/topology.jsonl" <<'JSONL'
{"session":"{capability-control-plane}","effective_at":"2026-05-04T20:00:00Z","orchestrator_pane":1,"worker_panes":[2,3]}
{"session":"{proof-product}","effective_at":"2026-05-04T20:00:00Z","orchestrator_pane":1,"worker_panes":[2,3]}
{"session":"{session}","effective_at":"2026-05-04T20:00:00Z","orchestrator_pane":1,"worker_panes":[2]}
JSONL

cat >"$TMP/activity/{capability-control-plane}.json" <<'JSON'
{"agents":[
  {"pane_idx":2,"state":"WAITING","capture_provenance":"live","state_since_epoch":100},
  {"pane_idx":3,"state":"WAITING","capture_provenance":"live","state_since_epoch":100}
]}
JSON
cat >"$TMP/ready/{capability-control-plane}.json" <<'JSON'
[]
JSON
cat >"$TMP/doctor/{capability-control-plane}.json" <<'JSON'
{"fuckup_triage":{"candidates":[{"trauma_class":"audit-findings-unfiled"}]},"closed_bead_audit_pending_count":2}
JSON
printf 'orch is quiet\n' >"$TMP/capture/{capability-control-plane}.txt"

cat >"$TMP/activity/{proof-product}.json" <<'JSON'
{"agents":[{"pane_idx":2,"state":"THINKING","capture_provenance":"live","state_since_epoch":1000}]}
JSON
cat >"$TMP/ready/{proof-product}.json" <<'JSON'
[{"id":"me-a","priority":1,"title":"Ready work"}]
JSON
cat >"$TMP/doctor/{proof-product}.json" <<'JSON'
{}
JSON
printf 'dispatching\n' >"$TMP/capture/{proof-product}.txt"

cat >"$TMP/activity/{session}.json" <<'JSON'
{"agents":[{"pane_idx":2,"state":"WAITING","capture_provenance":"live","state_since_epoch":100}]}
JSON
cat >"$TMP/ready/{session}.json" <<'JSON'
[]
JSON
cat >"$TMP/doctor/{session}.json" <<'JSON'
{"errors":[{"code":"joshua_required_security_decision","message":"TRUE Josh-blocker requires {operator} action"}]}
JSON
printf 'TRUE Josh-blocker requires {operator} action\n' >"$TMP/capture/{session}.txt"

cat >"$TMP/ntm-coordinator-pinned" <<'SH'
#!/usr/bin/env bash
session=""
for arg in "$@"; do
  case "$arg" in
    --session=*) session="${arg#--session=}" ;;
  esac
done
case "$session" in
  {capability-control-plane})
    printf '{"work_summary":{"pending_tasks":2,"in_progress_tasks":1,"completed_today":0,"blocked_tasks":1}}\n'
    ;;
  {proof-product})
    printf '{"work_summary":{"pending_tasks":0,"in_progress_tasks":1,"completed_today":0,"blocked_tasks":0}}\n'
    ;;
  {session})
    exit 3
    ;;
  *)
    printf '{"work_summary":{"pending_tasks":0,"in_progress_tasks":0,"completed_today":0,"blocked_tasks":0}}\n'
    ;;
esac
SH
chmod +x "$TMP/ntm-coordinator-pinned"

base_args=(
  --fleet
  --loops-dir "$TMP/loops"
  --topology "$TMP/topology.jsonl"
  --activity-dir "$TMP/activity"
  --ready-dir "$TMP/ready"
  --doctor-dir "$TMP/doctor"
  --capture-dir "$TMP/capture"
  --coordinator-bin "$TMP/ntm-coordinator-pinned"
  --ledger "$TMP/state/productivity.jsonl"
  --now 2026-05-04T20:10:00Z
  --now-epoch 1000
)

"$SCRIPT" --info --json >"$TMP/info.json"
assert_jq "$TMP/info.json" '.mutates_only_with == "--apply" and (.donella_leverage_points | index(6))' "info exposes leverage and apply gate"

"$SCRIPT" --schema --json >"$TMP/schema.json"
assert_jq "$TMP/schema.json" '(.canonical_cli_flags | index("--session=<name>")) and (.canonical_cli_flags | index("--coordinator-bin=<path>")) and (.output_fields | index("peer_orch_idle_with_work_available_count")) and (.output_fields | index("sessions[].coordinator_pending_tasks"))' "schema exposes canonical flags and doctor fields"

"$SCRIPT" "${base_args[@]}" --json >"$TMP/report.json"
assert_jq "$TMP/report.json" '.peer_orch_idle_with_work_available_count == 1 and .true_josh_blocker_count == 1 and .productive_count == 1' "fleet counts productivity states"
assert_jq "$TMP/report.json" '.sessions[] | select(.session == "{capability-control-plane}") | .productivity_state == "idle_with_work_available" and (.escalation_packet | contains("audit-findings-unfiled"))' "idle session gets escalation packet"
assert_jq "$TMP/report.json" '.sessions[] | select(.session == "{capability-control-plane}") | .coordinator_pending_tasks == 2 and .coordinator_in_progress == 1 and .coordinator_blocked == 1 and (.work_sources[] | select(.source | contains("Coordinator digest work_summary")))' "coordinator digest drives work summary"
assert_jq "$TMP/report.json" '.sessions[] | select(.session == "{session}") | .productivity_state == "true_josh_blocker"' "explicit Josh blocker classified"
assert_jq "$TMP/report.json" '.sessions[] | select(.session == "{session}") | .coordinator_digest_available == false and .coordinator_digest_error == "coordinator_nonzero"' "coordinator failure is fail-open"
[[ ! -f "$TMP/state/productivity.jsonl" ]] && pass "dry-run writes no ledger" || fail "dry-run writes no ledger"

cat >"$TMP/ntm" <<'SH'
#!/usr/bin/env bash
printf '%s\n' "$*" >>"$NTM_LOG"
exit 0
SH
chmod +x "$TMP/ntm"
NTM_LOG="$TMP/ntm.log" "$SCRIPT" "${base_args[@]}" --apply --no-notify --json --ntm "$TMP/ntm" >"$TMP/apply.json"
assert_jq "$TMP/apply.json" '(.actual_actions | map(.type) | index("xpane_productivity_escalation"))' "apply sends productivity escalation"
assert_jq "$TMP/apply.json" '(.actual_actions | map(.type) | index("josh_notify_true_blocker"))' "apply records true blocker notify action"
grep -q '{capability-control-plane}' "$TMP/ntm.log" && pass "fake ntm received {capability-control-plane} send" || fail "fake ntm received {capability-control-plane} send"
grep -F -- '--no-cass-check' "$TMP/ntm.log" >/dev/null && pass "fake ntm productivity escalation bypasses cass" || fail "fake ntm productivity escalation bypasses cass"
assert_jq "$TMP/state/productivity.jsonl" 'select(.event == "productivity_escalation_sent" and .session == "{capability-control-plane}")' "apply writes cross-orch ledger row"

if [[ "$fail_count" -gt 0 ]]; then
  printf 'SUMMARY pass=%d fail=%d\n' "$pass_count" "$fail_count" >&2
  exit 1
fi
printf 'SUMMARY pass=%d fail=0\n' "$pass_count"
