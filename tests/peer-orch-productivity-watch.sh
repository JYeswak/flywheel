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

cat >"$TMP/loops/skillos.json" <<'JSON'
{"session":"skillos","active":true,"repo":"/tmp/skillos","orchestrator_pane":1}
JSON
cat >"$TMP/loops/mobile-eats.json" <<'JSON'
{"session":"mobile-eats","active":true,"repo":"/tmp/mobile-eats","orchestrator_pane":1}
JSON
cat >"$TMP/loops/alpsinsurance.json" <<'JSON'
{"session":"alpsinsurance","active":true,"repo":"/tmp/alpsinsurance","orchestrator_pane":1}
JSON
cat >"$TMP/topology.jsonl" <<'JSONL'
{"session":"skillos","effective_at":"2026-05-04T20:00:00Z","orchestrator_pane":1,"worker_panes":[2,3]}
{"session":"mobile-eats","effective_at":"2026-05-04T20:00:00Z","orchestrator_pane":1,"worker_panes":[2,3]}
{"session":"alpsinsurance","effective_at":"2026-05-04T20:00:00Z","orchestrator_pane":1,"worker_panes":[2]}
JSONL

cat >"$TMP/activity/skillos.json" <<'JSON'
{"agents":[
  {"pane_idx":2,"state":"WAITING","capture_provenance":"live","state_since_epoch":100},
  {"pane_idx":3,"state":"WAITING","capture_provenance":"live","state_since_epoch":100}
]}
JSON
cat >"$TMP/ready/skillos.json" <<'JSON'
[]
JSON
cat >"$TMP/doctor/skillos.json" <<'JSON'
{"fuckup_triage":{"candidates":[{"trauma_class":"audit-findings-unfiled"}]},"closed_bead_audit_pending_count":2}
JSON
printf 'orch is quiet\n' >"$TMP/capture/skillos.txt"

cat >"$TMP/activity/mobile-eats.json" <<'JSON'
{"agents":[{"pane_idx":2,"state":"THINKING","capture_provenance":"live","state_since_epoch":1000}]}
JSON
cat >"$TMP/ready/mobile-eats.json" <<'JSON'
[{"id":"me-a","priority":1,"title":"Ready work"}]
JSON
cat >"$TMP/doctor/mobile-eats.json" <<'JSON'
{}
JSON
printf 'dispatching\n' >"$TMP/capture/mobile-eats.txt"

cat >"$TMP/activity/alpsinsurance.json" <<'JSON'
{"agents":[{"pane_idx":2,"state":"WAITING","capture_provenance":"live","state_since_epoch":100}]}
JSON
cat >"$TMP/ready/alpsinsurance.json" <<'JSON'
[]
JSON
cat >"$TMP/doctor/alpsinsurance.json" <<'JSON'
{"errors":[{"code":"joshua_required_security_decision","message":"TRUE Josh-blocker requires Joshua action"}]}
JSON
printf 'TRUE Josh-blocker requires Joshua action\n' >"$TMP/capture/alpsinsurance.txt"

base_args=(
  --fleet
  --loops-dir "$TMP/loops"
  --topology "$TMP/topology.jsonl"
  --activity-dir "$TMP/activity"
  --ready-dir "$TMP/ready"
  --doctor-dir "$TMP/doctor"
  --capture-dir "$TMP/capture"
  --ledger "$TMP/state/productivity.jsonl"
  --now 2026-05-04T20:10:00Z
  --now-epoch 1000
)

"$SCRIPT" --info --json >"$TMP/info.json"
assert_jq "$TMP/info.json" '.mutates_only_with == "--apply" and (.donella_leverage_points | index(6))' "info exposes leverage and apply gate"

"$SCRIPT" --schema --json >"$TMP/schema.json"
assert_jq "$TMP/schema.json" '(.canonical_cli_flags | index("--session=<name>")) and (.output_fields | index("peer_orch_idle_with_work_available_count"))' "schema exposes canonical flags and doctor field"

"$SCRIPT" "${base_args[@]}" --json >"$TMP/report.json"
assert_jq "$TMP/report.json" '.peer_orch_idle_with_work_available_count == 1 and .true_josh_blocker_count == 1 and .productive_count == 1' "fleet counts productivity states"
assert_jq "$TMP/report.json" '.sessions[] | select(.session == "skillos") | .productivity_state == "idle_with_work_available" and (.escalation_packet | contains("audit-findings-unfiled"))' "idle session gets escalation packet"
assert_jq "$TMP/report.json" '.sessions[] | select(.session == "alpsinsurance") | .productivity_state == "true_josh_blocker"' "explicit Josh blocker classified"
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
grep -q 'skillos' "$TMP/ntm.log" && pass "fake ntm received skillos send" || fail "fake ntm received skillos send"
assert_jq "$TMP/state/productivity.jsonl" 'select(.event == "productivity_escalation_sent" and .session == "skillos")' "apply writes cross-orch ledger row"

if [[ "$fail_count" -gt 0 ]]; then
  printf 'SUMMARY pass=%d fail=%d\n' "$pass_count" "$fail_count" >&2
  exit 1
fi
printf 'SUMMARY pass=%d fail=0\n' "$pass_count"
