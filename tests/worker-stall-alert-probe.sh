#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd -P)"
SCRIPT="$ROOT/.flywheel/scripts/worker-stall-alert-probe.sh"
TMP="$(mktemp -d "${TMPDIR:-/tmp}/worker-stall-alert-test.XXXXXX")"
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

jq -nc '{
  session:"{session}",
  worker_panes:[2],
  orchestrator_pane:1,
  callback_pane:1,
  effective_at:"2026-05-04T19:00:00Z"
}' >"$TMP/topology.json"

jq -nc '{
  agents:[
    {pane_idx:2,agent_type:"codex",state:"THINKING",state_since:"2026-05-04T19:00:00Z",capture_provenance:"live",capture_collected_at:"2026-05-04T19:01:00Z",detected_patterns:["codex_working","codex_chevron_prompt"]}
  ]
}' >"$TMP/activity.json"

jq -nc '{
  panes:{
    "2":{type:"codex",state:"idle",capture_provenance:"live",capture_collected_at:"2026-05-04T19:01:00Z",lines:["Working for a long time","same visible output"]}
  }
}' >"$TMP/tail.json"

printf '%s\n' '{"ts":"2026-05-04T19:00:00Z","task_id":"p2-14wq","pane":2,"callback_received_at":null,"status":"dispatched"}' >"$TMP/dispatch-log.jsonl"

fake_ntm="$TMP/ntm"
cat >"$fake_ntm" <<'FAKE'
#!/usr/bin/env bash
set -euo pipefail
printf '%s\n' "$*" >>"${FAKE_NTM_SENDS:?}"
printf 'sent\n'
FAKE
chmod +x "$fake_ntm"

bash -n "$SCRIPT" && pass "script syntax" || fail "script syntax"
"$SCRIPT" --help | rg -q 'worker-stall-alert-probe.sh' && pass "help exposes surface" || fail "help exposes surface"
"$SCRIPT" --info --json >"$TMP/info.json"
assert_jq "$TMP/info.json" '.schema_version == "worker-stall-alert-probe/v1" and .mutation_default == "dry-run"' "info JSON"
"$SCRIPT" --schema --json >"$TMP/schema.json"
assert_jq "$TMP/schema.json" '.properties.worker_stall_candidate_count.type == "integer"' "schema JSON"

FAKE_NTM_SENDS="$TMP/sends.log" NTM_BIN="$fake_ntm" "$SCRIPT" \
  --session {session} \
  --repo "$TMP/repo" \
  --state-dir "$TMP/state" \
  --activity-fixture "$TMP/activity.json" \
  --tail-fixture "$TMP/tail.json" \
  --topology-fixture "$TMP/topology.json" \
  --dispatch-log-fixture "$TMP/dispatch-log.jsonl" \
  --min-age-seconds 0 \
  --apply --json >"$TMP/first.json"
assert_jq "$TMP/first.json" '.worker_stall_candidate_count == 0 and .alerts_sent_count == 0' "first tick only records observation"

FAKE_NTM_SENDS="$TMP/sends.log" NTM_BIN="$fake_ntm" "$SCRIPT" \
  --session {session} \
  --repo "$TMP/repo" \
  --state-dir "$TMP/state" \
  --activity-fixture "$TMP/activity.json" \
  --tail-fixture "$TMP/tail.json" \
  --topology-fixture "$TMP/topology.json" \
  --dispatch-log-fixture "$TMP/dispatch-log.jsonl" \
  --min-age-seconds 0 \
  --apply --json >"$TMP/second.json"
assert_jq "$TMP/second.json" '.worker_stall_candidate_count == 1 and .alerts_sent_count == 1 and .probe_sends_count == 1 and (.receipts[0].same_tick_count == 2) and (.receipts[0].resolution == "alerted")' "second unchanged tick alerts"

if [[ "$(wc -l <"$TMP/sends.log")" -eq 2 ]] && rg -q 'L95 stall probe' "$TMP/sends.log" && rg -q 'L95_STALL_ALERT' "$TMP/sends.log"; then
  pass "fake ntm recorded probe and alert"
else
  fail "fake ntm send log missing probe or alert"
fi

printf 'Summary: %d passed, %d failed\n' "$pass_count" "$fail_count"
[[ "$fail_count" -eq 0 ]]
