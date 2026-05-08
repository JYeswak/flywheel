#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd -P)"
LOOP_BIN="${FLYWHEEL_LOOP_BIN_UNDER_TEST:-$HOME/.claude/skills/.flywheel/bin/flywheel-loop}"
TMP="$(mktemp -d "${TMPDIR:-/tmp}/loop-driver-drain.XXXXXX")"
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
    jq . "$file" >&2 || cat "$file" >&2
  fi
}

repo="$TMP/repo"
loops="$TMP/loops"
launch_agents="$TMP/LaunchAgents"
logs="$TMP/logs"
state="$TMP/state"
mkdir -p "$repo/.flywheel" "$loops" "$launch_agents" "$logs" "$state" "$TMP/bin"

tick_script="$TMP/bin/drain-fixture-flywheel-loop-tick"
cat >"$tick_script" <<'EOF'
#!/usr/bin/env bash
set -euo pipefail
ntm send fixture --pane=1 --file /tmp/fixture --no-cass-check
EOF
chmod +x "$tick_script"

label="ai.zeststream.repo-flywheel-loop"
plist="$launch_agents/$label.plist"
cat >"$plist" <<XML
<?xml version="1.0" encoding="UTF-8"?>
<plist version="1.0"><dict>
<key>Label</key><string>$label</string>
<key>ProgramArguments</key><array><string>$tick_script</string></array>
<key>StartInterval</key><integer>60</integer>
</dict></plist>
XML

now="$(date -u +%Y-%m-%dT%H:%M:%SZ)"
cat >"$repo/.flywheel/dispatch-log.jsonl" <<JSONL
{"event":"ntm_dispatch_sent","ts":"$now","task_file":"/tmp/dispatch_fixture.md","pane":1}
JSONL
cat >"$loops/repo.json" <<JSON
{"active":true,"project":"repo","repo":"$repo","session":"repo","orchestrator_pane":1,"interval":"60s","dispatch_mode":"launchd_prompt","plist_label":"$label","plist":"$plist","tick_script":"$tick_script"}
JSON
printf -- '-\t0\t%s\n' "$label" >"$TMP/launchctl-list.txt"
topology="$TMP/topology.jsonl"
jq -nc '{session:"repo",orchestrator_pane:1,effective_at:"2026-05-08T00:00:00Z"}' >"$topology"
health='{"agents":[{"pane":1,"process_status":"running"}]}'
tail_json='{"panes":{"1":{"lines":["PHASE: fixture repo"]}}}'

env_base=(
  "FLYWHEEL_LOOP_MARKER_DIR=$loops"
  "FLYWHEEL_LOOP_LAUNCH_AGENTS_DIR=$launch_agents"
  "FLYWHEEL_LOOP_LOG_DIR=$logs"
  "FLYWHEEL_LOOP_LAUNCHCTL_LIST=$TMP/launchctl-list.txt"
  "FLYWHEEL_SESSION_TOPOLOGY=$topology"
  "FLYWHEEL_LOOP_NTM_HEALTH_JSON=$health"
  "FLYWHEEL_LOOP_ROBOT_TAIL_JSON=$tail_json"
)

missing_ledger="$state/missing-drain.jsonl"
env "${env_base[@]}" FLYWHEEL_LOOP_DRAIN_RECEIPT_LEDGER="$missing_ledger" "$LOOP_BIN" doctor --repo "$repo" --scope loop-driver --json >"$TMP/missing.json"
assert_jq "$TMP/missing.json" '.status == "warn" and .loop_driver.driver_status == "VERIFIED" and (.warnings[] | select(.code=="loop_driver_drain_receipt_missing")) and .loop_driver.drain_receipts.missing_receipt == true' "doctor_surfaces_missing_drain_receipt"

stale_ledger="$state/stale-drain.jsonl"
jq -nc '{schema_version:"loop-driver-drain-receipt.v1",ts:"2000-01-01T00:00:00Z",driver:"fixture",state:"graceful_drain",trigger:"SIGTERM",in_flight_tasks:1,drained_count:1,timed_out_count:0,next_start_policy:"resume_on_next_interval"}' >"$stale_ledger"
env "${env_base[@]}" FLYWHEEL_LOOP_DRAIN_RECEIPT_LEDGER="$stale_ledger" "$LOOP_BIN" doctor --repo "$repo" --scope loop-driver --json >"$TMP/stale.json"
assert_jq "$TMP/stale.json" '.status == "warn" and (.warnings[] | select(.code=="loop_driver_drain_receipt_stale")) and .loop_driver.drain_receipts.stale_receipt == true' "doctor_surfaces_stale_drain_receipt"

fresh_ledger="$state/fresh-drain.jsonl"
jq -nc --arg ts "$now" '{schema_version:"loop-driver-drain-receipt.v1",ts:$ts,driver:"fixture",state:"restart_handoff",trigger:"restart_after_drain",in_flight_tasks:0,drained_count:0,timed_out_count:0,next_start_policy:"restart_immediately"}' >"$fresh_ledger"
env "${env_base[@]}" FLYWHEEL_LOOP_DRAIN_RECEIPT_LEDGER="$fresh_ledger" "$LOOP_BIN" doctor --repo "$repo" --scope loop-driver --json >"$TMP/fresh.json"
assert_jq "$TMP/fresh.json" '.status == "pass" and .loop_driver.drain_receipts.latest_state == "restart_handoff" and .loop_driver.drain_receipts.missing_receipt == false and .loop_driver.drain_receipts.stale_receipt == false' "doctor_accepts_restart_handoff_receipt"

if [[ "$fail_count" -gt 0 ]]; then
  printf 'FAIL loop-driver-drain-receipts pass=%d fail=%d\n' "$pass_count" "$fail_count" >&2
  exit 1
fi
printf 'OK loop-driver-drain-receipts pass=%d\n' "$pass_count"
