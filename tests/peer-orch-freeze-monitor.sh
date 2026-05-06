#!/usr/bin/env bash
set -Eeuo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SCRIPT="$ROOT/.flywheel/scripts/peer-orch-freeze-monitor.sh"
TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT

pass=0

ok() {
  local name="$1"
  pass=$((pass + 1))
  printf 'ok %d - %s\n' "$pass" "$name"
}

fail() {
  printf 'not ok - %s\n' "$1" >&2
  exit 1
}

cat > "$TMP/jsonl-append.sh" <<'SH'
fw_jsonl_append_validated() {
  local path="$1"
  local row="$2"
  mkdir -p "$(dirname "$path")"
  printf '%s\n' "$row" >> "$path"
}
SH

cat > "$TMP/kill-recover-drill.sh" <<'SH'
PROTECTED_SESSIONS=(alpsinsurance picoz terra-title)
SH

cat > "$TMP/fake-respawn.sh" <<'SH'
#!/usr/bin/env bash
printf '%s:%s\n' "$1" "$2" >> "${PEER_ORCH_MONITOR_RESPAWN_LOG:?}"
SH
chmod +x "$TMP/fake-respawn.sh"

mkdir -p "$TMP/fixtures"
cat > "$TMP/topology.jsonl" <<'JSONL'
{"session":"flywheel","orchestrator_pane":1,"human_pane":0,"callback_pane":4,"effective_at":"2026-05-05T00:00:00Z"}
{"session":"skillos","orchestrator_pane":1,"human_pane":0,"callback_pane":4,"effective_at":"2026-05-05T00:00:00Z"}
{"session":"alpsinsurance","orchestrator_pane":1,"human_pane":0,"callback_pane":4,"effective_at":"2026-05-05T00:00:00Z"}
{"session":"mobile-eats","orchestrator_pane":1,"human_pane":0,"callback_pane":4,"effective_at":"2026-05-05T00:00:00Z"}
JSONL

cat > "$TMP/fixtures/skillos-1.json" <<'JSON'
{"t0":"› Implement {feature}\n","t1":"› Implement {feature}\n","timestamp":"2026-05-05T00:00:01Z"}
JSON
cat > "$TMP/fixtures/alpsinsurance-1.json" <<'JSON'
{"t0":"› Implement {feature}\n","t1":"› Implement {feature}\n","timestamp":"2026-05-05T00:00:01Z"}
JSON
cat > "$TMP/fixtures/mobile-eats-1.json" <<'JSON'
{"t0":"thinking...\nline 1\n","t1":"thinking...\nline 2\n","timestamp":"2026-05-05T00:00:01Z"}
JSON

export PEER_ORCH_MONITOR_TOPOLOGY="$TMP/topology.jsonl"
export PEER_ORCH_MONITOR_LEDGER="$TMP/monitor.jsonl"
export PEER_ORCH_MONITOR_CONTRACT_LEDGER="$TMP/contract.jsonl"
export PEER_ORCH_MONITOR_FUCKUP_LOG="$TMP/fuckup.jsonl"
export PEER_ORCH_MONITOR_JSONL_APPEND_LIB="$TMP/jsonl-append.sh"
export PEER_ORCH_MONITOR_FIXTURE_DIR="$TMP/fixtures"
export PEER_ORCH_MONITOR_RESPAWN_CMD="$TMP/fake-respawn.sh"
export PEER_ORCH_MONITOR_RESPAWN_LOG="$TMP/respawn.log"
export PEER_ORCH_MONITOR_PLIST="$TMP/ai.zeststream.peer-orch-freeze-monitor.plist"
export PEER_ORCH_MONITOR_NOW="2026-05-05T00:02:00Z"
export PEER_ORCH_RECOVERY_KILL_RECOVER_DRILL="$TMP/kill-recover-drill.sh"
export PEER_ORCH_RECOVERY_LEDGER="$TMP/permit.jsonl"

bash -n "$SCRIPT"
"$SCRIPT" --info --json | jq -e '.primitive=="peer-orch-freeze-monitor" and .auto_respawn_default_enabled==false' >/dev/null || fail "info"
"$SCRIPT" --examples >/dev/null
"$SCRIPT" quickstart >/dev/null
"$SCRIPT" completion >/dev/null
printf 'preflight - canonical cli surfaces\n'

rm -f "$TMP/respawn.log" "$TMP/monitor.jsonl" "$TMP/permit.jsonl"
PEER_ORCH_AUTO_RESPAWN=1 "$SCRIPT" cycle --apply --json | jq -e '
  .recoveries_count==1 and
  any(.target_results[]; .session=="skillos" and .permit_decision=="permit" and .recovery_applied==true)
' >/dev/null || fail "permit grant recovery"
grep -q '^skillos:1$' "$TMP/respawn.log" || fail "fake respawn missing"
ok "synthetic frozen peer orch recovers only after permit grant"

"$SCRIPT" cycle --json | jq -e '
  any(.target_results[]; .session=="mobile-eats" and .stuck==false and .recovery_applied==false)
' >/dev/null || fail "alive pane false positive"
ok "alive pane hash movement is not recovered"

"$SCRIPT" cycle --json | jq -e '
  any(.target_results[]; .session=="flywheel" and .pane=="1" and .decision_reason=="self_orch_respawn_refused" and .recovery_applied==false)
' >/dev/null || fail "self orch refusal"
ok "flywheel self orchestrator is refused"

"$SCRIPT" cycle --json | jq -e '
  any(.target_results[]; .session=="alpsinsurance" and .permit_invoked==true and .permit_decision=="refuse" and .permit_reason=="protected_session_refused" and .recovery_applied==false)
' >/dev/null || fail "protected refusal"
ok "protected peer orch permit refusal blocks recovery"

rm -f "$TMP/respawn.log"
PEER_ORCH_AUTO_RESPAWN=0 "$SCRIPT" cycle --apply --json | jq -e '
  .recoveries_count==0 and
  any(.target_results[]; .session=="skillos" and .permit_decision=="permit" and .recovery_blocked_reason=="auto_respawn_disabled")
' >/dev/null || fail "auto disabled"
[[ ! -s "$TMP/respawn.log" ]] || fail "respawn ran while auto disabled"
ok "auto-respawn default remains disabled"

cat > "$TMP/monitor.jsonl" <<'JSONL'
{"schema_version":"peer-orch-freeze-monitor.v1","primitive":"peer-orch-freeze-monitor","status":"ok","ts":"2026-05-04T23:00:00Z","target_results":[]}
JSONL
"$SCRIPT" doctor --apply --json | jq -e '
  .schema_version|startswith("peer-orch-freeze-monitor")
' >/dev/null || fail "doctor schema"
grep -q 'peer-orch-monitor-stale' "$TMP/fuckup.jsonl" || fail "stale fuckup missing"
ok "stale monitor doctor logs fuckup row"

rm -f "$TMP/monitor.jsonl"
PEER_ORCH_AUTO_RESPAWN=1 "$SCRIPT" cycle --apply --json >/dev/null
"$SCRIPT" doctor --json | jq -e '
  .monitor_alive==true and
  .monitor_last_fire_ts=="2026-05-05T00:02:00Z" and
  .recoveries_24h==1 and
  .permit_gate_refusals_24h>=1 and
  .false_recovery_count_24h==0
' >/dev/null || fail "doctor metrics"
ok "doctor exposes required monitor metrics"

"$SCRIPT" install --apply --json | jq -e '.disabled_by_default==true and .launchctl_mutated==false' >/dev/null || fail "install"
grep -q '<key>Disabled</key>' "$TMP/ai.zeststream.peer-orch-freeze-monitor.plist" || fail "plist disabled key"
"$SCRIPT" validate --scope plist --json | jq -e '.status=="pass"' >/dev/null || fail "plist validate"
"$SCRIPT" uninstall --apply --json | jq -e '.removed==true and .launchctl_mutated==false' >/dev/null || fail "uninstall"
[[ ! -e "$TMP/ai.zeststream.peer-orch-freeze-monitor.plist" ]] || fail "plist still exists"
ok "disabled plist install and uninstall avoid launchctl mutation"

[[ "$pass" -eq 8 ]] || fail "pass count $pass"
printf 'OK peer-orch-freeze-monitor tests pass=8/8\n'
