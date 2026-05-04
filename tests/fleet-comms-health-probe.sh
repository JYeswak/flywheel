#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd -P)"
SCRIPT="$ROOT/.flywheel/scripts/fleet-comms-health-probe.sh"
TMP="$(mktemp -d "${TMPDIR:-/tmp}/fleet-comms-health-test.XXXXXX")"
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

mkdir -p "$TMP/loops" "$TMP/agent-mail/sessions" "$TMP/agent-mail/tokens" "$TMP/activity"
chmod +x "$SCRIPT"
bash -n "$SCRIPT" && pass "script syntax" || fail "script syntax"

NOW="2026-05-04T20:00:00Z"
NOW_EPOCH="$(date -u -j -f "%Y-%m-%dT%H:%M:%SZ" "$NOW" +%s)"

write_loop() {
  local session="$1" pane="${2:-1}"
  jq -n --arg session "$session" --argjson pane "$pane" '{session:$session,active:true,orchestrator_pane:$pane}' >"$TMP/loops/$session.json"
}

write_identity() {
  local session="$1" pane="$2" identity="$3"
  jq -n \
    --arg session "$session" \
    --argjson pane "$pane" \
    --arg identity "$identity" \
    --arg token "$TMP/agent-mail/tokens/$identity.token" \
    '{
      schema_version:"agent-mail-identity-registry/v1",
      session:$session,
      pane:$pane,
      identity_name:$identity,
      token_path:$token,
      status:"active",
      identity_resolved:true,
      fleet_mail_project_key:"/tmp/fleet-comms"
    }' >"$TMP/agent-mail/sessions/$session:$pane.json"
  : >"$TMP/agent-mail/tokens/$identity.token"
}

for session in healthy stale-token silent false-positive; do
  write_loop "$session" 1
done
write_identity healthy 1 HealthyPond
write_identity stale-token 1 StalePond
write_identity silent 1 SilentPond
write_identity false-positive 1 FalsePond

touch -t 202605041900 "$TMP/agent-mail/tokens/HealthyPond.token"
touch -t 202604010000 "$TMP/agent-mail/tokens/StalePond.token"
touch -t 202605041900 "$TMP/agent-mail/tokens/SilentPond.token"
touch -t 202605041900 "$TMP/agent-mail/tokens/FalsePond.token"

cat >"$TMP/cross-orch.jsonl" <<'JSONL'
{"ts":"2026-05-04T19:50:00Z","event":"coord","from":"flywheel:1","to":"healthy:1","session":"healthy"}
{"ts":"2026-05-04T19:51:00Z","event":"coord","from":"flywheel:1","to":"stale-token:1","session":"stale-token"}
{"ts":"2026-05-01T12:00:00Z","event":"coord","from":"flywheel:1","to":"silent:1","session":"silent"}
{"ts":"2026-05-04T19:52:00Z","event":"coord","from":"flywheel:1","to":"false-positive:1","session":"false-positive"}
{"ts":"2026-05-01T13:00:00Z","event":"blocked","blocker_type":"flywheel_class","from":"silent:1","to":"flywheel:1","session":"silent"}
JSONL

cat >"$TMP/productivity.jsonl" <<'JSONL'
{"ts":"2026-05-04T18:00:00Z","event":"productivity_escalation_sent","session":"silent"}
JSONL

for session in healthy stale-token silent false-positive; do
  cat >"$TMP/activity/$session.json" <<'JSON'
{"agents":[{"pane_idx":1,"state":"WAITING","capture_provenance":"live","process_status":"running"}]}
JSON
done

cat >"$TMP/broadcast.json" <<'JSON'
{
  "sessions": {
    "false-positive": {"session":"false-positive","action":"dead_session","dead":true},
    "healthy": {"session":"healthy","action":"sent","dead":false},
    "stale-token": {"session":"stale-token","action":"sent","dead":false},
    "silent": {"session":"silent","action":"sent","dead":false}
  }
}
JSON

base_args=(
  --fleet
  --loops-dir "$TMP/loops"
  --agent-mail-dir "$TMP/agent-mail"
  --token-json-dir "$TMP/agent-mail-tokens"
  --coordination-log "$TMP/cross-orch.jsonl"
  --peer-blocker-log "$TMP/peer-blocker.jsonl"
  --productivity-log "$TMP/productivity.jsonl"
  --topology "$TMP/topology.jsonl"
  --activity-dir "$TMP/activity"
  --broadcast-classifier "$TMP/broadcast.json"
  --ledger "$TMP/fleet-comms-ledger.jsonl"
  --now "$NOW"
  --now-epoch "$NOW_EPOCH"
)

"$SCRIPT" --info --json >"$TMP/info.json"
assert_jq "$TMP/info.json" '.mutates_only_with == "--apply" and (.axes | index("token_freshness")) and (.donella_leverage_points | index(6))' "info exposes axes and apply gate"

"$SCRIPT" --schema --json >"$TMP/schema.json"
assert_jq "$TMP/schema.json" '(.canonical_cli_flags | index("--session=<name>")) and (.output_fields | index("fleet_comms_min_score"))' "schema exposes canonical flags and doctor field"

"$SCRIPT" "${base_args[@]}" --json >"$TMP/report.json"
assert_jq "$TMP/report.json" '.schema_version == "fleet-comms-health/v1" and .total_count == 4 and .healthy_count == 1' "fleet counts sessions"
assert_jq "$TMP/report.json" '.fleet_comms_token_stale_count == 1 and .fleet_comms_silent_session_count == 1 and .fleet_comms_escalation_unread_count == 1' "fleet counts stale silent unread"
assert_jq "$TMP/report.json" '.sessions[] | select(.session == "stale-token") | .axes.token_freshness.status == "red" and .axes.token_freshness.score == 0' "stale token fails token axis"
assert_jq "$TMP/report.json" '.sessions[] | select(.session == "silent") | .axes.cross_orch_packet_age.status == "red" and .axes.cross_orch_packet_age.packet_age_seconds > 259200' "silent session fails packet age axis"
assert_jq "$TMP/report.json" '.sessions[] | select(.session == "false-positive") | .axes.multi_frame_liveness_classifier.false_positive_classifier == true and .axes.multi_frame_liveness_classifier.score == 0' "broadcast dead plus multi-frame alive catches false positive"
assert_jq "$TMP/report.json" '.sessions[] | select(.session == "stale-token") | .score == 83' "composite math uses six equal axes"
assert_jq "$TMP/report.json" '.fleet_comms_min_score == 67 and .fleet_comms_worst_session == "silent"' "min score and worst session surfaced"
[[ ! -f "$TMP/fleet-comms-ledger.jsonl" ]] && pass "dry run writes no ledger" || fail "dry run writes no ledger"

FAKE_NTM="$TMP/ntm"
cat >"$FAKE_NTM" <<'SH'
#!/usr/bin/env bash
printf '%s\n' "$*" >>"${NTM_LOG:?}"
exit 0
SH
chmod +x "$FAKE_NTM"

NTM_LOG="$TMP/ntm.log" "$SCRIPT" "${base_args[@]}" --apply --no-notify --json --ntm "$FAKE_NTM" >"$TMP/apply.json"
assert_jq "$TMP/apply.json" '(.planned_actions | map(.type) | index("xpane_comms_ping")) and (.planned_actions | map(.type) | index("log_false_positive_classifier"))' "apply dry-run packet shape exposes planned actions"
assert_jq "$TMP/apply.json" '(.actual_actions | map(.type) | index("xpane_comms_ping")) and (.actual_actions | map(.type) | index("log_false_positive_classifier"))' "apply records comms ping and false-positive log"
grep -q 'COMMS_HEALTH_PING' "$TMP/ntm.log" && pass "fake ntm received comms ping" || fail "fake ntm received comms ping"
assert_jq "$TMP/fleet-comms-ledger.jsonl" 'select(.event == "fleet_comms_false_positive_classifier" and .session == "false-positive")' "ledger records false positive classifier"

if [[ "$fail_count" -gt 0 ]]; then
  printf 'SUMMARY pass=%d fail=%d\n' "$pass_count" "$fail_count" >&2
  exit 1
fi
printf 'SUMMARY pass=%d fail=0\n' "$pass_count"
