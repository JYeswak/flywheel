#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd -P)"
SCRIPT="$ROOT/.flywheel/scripts/frozen-pane-detector-fleet.sh"
TMP="$(mktemp -d "${TMPDIR:-/tmp}/frozen-pane-fleet-test.XXXXXX")"
trap 'rm -rf "$TMP"' EXIT

pass_count=0
fail_count=0

pass() { printf 'PASS %s\n' "$1"; pass_count=$((pass_count + 1)); }
fail() { printf 'FAIL %s\n' "$1"; fail_count=$((fail_count + 1)); }

assert_jq() {
  local file="$1" expr="$2" label="$3"
  if jq -e "$expr" "$file" >/dev/null; then
    pass "$label"
  else
    fail "$label"
    sed -n '1,120p' "$file" >&2 || true
  fi
}

env_base() {
  FROZEN_FLEET_STATE_DIR="$TMP/state" \
  FROZEN_FLEET_PLIST="$TMP/ai.zeststream.frozen-pane-detector-fleet.plist" \
  FROZEN_FLEET_STDOUT_PATH="$TMP/logs/out.log" \
  FROZEN_FLEET_STDERR_PATH="$TMP/logs/err.log" \
  FROZEN_FLEET_STOP_FILE="$TMP/STOP-fleet" \
  FROZEN_FLEET_GLOBAL_STOP_FILE="$TMP/STOP-ALL" \
  FROZEN_FLEET_FATAL_FILE="$TMP/state/FATAL" \
  FROZEN_FLEET_EVENTS="$TMP/state/events.jsonl" \
  "$@"
}

bash -n "$SCRIPT" && pass "script syntax" || fail "script syntax"

env_base "$SCRIPT" --doctor --json >"$TMP/doctor-absent.json"
assert_jq "$TMP/doctor-absent.json" '.status == "WARN" and .daemon_installed == false and (.warnings[]?.code == "daemon_absent")' "doctor handles absent daemon"

env_base "$SCRIPT" install --dry-run --json >"$TMP/install-dry-run.json"
assert_jq "$TMP/install-dry-run.json" '.dry_run == true and .disabled_by_default == true and any(.planned_actions[]?; .action == "write_disabled_launchagent")' "install dry-run plans disabled LaunchAgent"

env_base "$SCRIPT" install --apply --json >"$TMP/install-apply.json"
assert_jq "$TMP/install-apply.json" '.applied == true and .disabled_by_default == true' "install apply writes disabled LaunchAgent"
if plutil -extract Disabled raw "$TMP/ai.zeststream.frozen-pane-detector-fleet.plist" | grep -Eq '^(1|true)$' \
  && plutil -extract StartInterval raw "$TMP/ai.zeststream.frozen-pane-detector-fleet.plist" | grep -qx '120' \
  && plutil -extract StandardOutPath raw "$TMP/ai.zeststream.frozen-pane-detector-fleet.plist" | grep -qx "$TMP/logs/out.log" \
  && plutil -extract StandardErrorPath raw "$TMP/ai.zeststream.frozen-pane-detector-fleet.plist" | grep -qx "$TMP/logs/err.log"; then
  pass "plist cadence stdout stderr disabled"
else
  fail "plist cadence stdout stderr disabled"
fi

env_base "$SCRIPT" --doctor --json >"$TMP/doctor-installed.json"
assert_jq "$TMP/doctor-installed.json" '.status == "PASS" and .daemon_installed == true and .disabled_by_default == true and .cadence_seconds == 120' "doctor validates installed daemon contract"

touch "$TMP/STOP-fleet"
env_base "$SCRIPT" cycle --json >"$TMP/cycle-stop.json"
assert_jq "$TMP/cycle-stop.json" '.decision == "stopped" and .recovery_applied == false' "STOP file blocks cycle"
rm "$TMP/STOP-fleet"

mkdir -p "$TMP/state"
touch "$TMP/state/FATAL"
env_base "$SCRIPT" cycle --json >"$TMP/cycle-fatal.json" || true
assert_jq "$TMP/cycle-fatal.json" '.decision == "fatal" and .fatal == true and .recovery_applied == false' "FATAL state blocks cycle"
rm "$TMP/state/FATAL"

cat >"$TMP/degraded.json" <<'JSON'
{"schema_version":"frozen-pane-detector.v2","success":false,"session":"all","source_health":{"status":"degraded"},"l60_signals_present":{}}
JSON
FROZEN_FLEET_DETECTOR_FIXTURE="$TMP/degraded.json" env_base "$SCRIPT" cycle --json >"$TMP/cycle-degraded.json"
assert_jq "$TMP/cycle-degraded.json" '.decision == "degraded_truth" and .degraded_truth_auto_recovery_blocked == true and .recovery_applied == false' "degraded truth never auto-recovers"

cat >"$TMP/healthy.json" <<'JSON'
{"schema_version":"frozen-pane-detector.v2","success":true,"session":"all","source_health":{"status":"healthy"},"l60_signals_present":{"no_silent_darkness":true}}
JSON
for idx in 1 2 3 4; do
  jq -nc --arg ts "2026-05-04T04:0${idx}:00Z" --arg session all --arg pane 1 '{ts:$ts,session:$session,pane:$pane,recovery_applied:true}' >>"$TMP/state/events.jsonl"
done
FROZEN_FLEET_DETECTOR_FIXTURE="$TMP/healthy.json" env_base "$SCRIPT" cycle --pane 1 --json >"$TMP/cycle-budget.json"
assert_jq "$TMP/cycle-budget.json" '.decision == "budget_exhausted" and .budget.ok == false and .recovery_applied == false' "global and per-pane budgets block recovery storms"

env_base "$SCRIPT" validate budgets --json >"$TMP/validate-budgets.json" || true
assert_jq "$TMP/validate-budgets.json" '.mode == "validate" and .thing == "budgets"' "validate budgets surface exists"

env_base "$SCRIPT" audit --json >"$TMP/audit.json"
assert_jq "$TMP/audit.json" '.mode == "audit" and (.events | type == "array")' "audit surface reads event ledger"

"$SCRIPT" --info | jq -e '.commands | index("doctor") and index("repair") and index("validate") and index("audit") and index("why")' >/dev/null \
  && pass "canonical CLI info includes triads" || fail "canonical CLI info includes triads"
"$SCRIPT" --examples >/dev/null && pass "examples surface" || fail "examples surface"
"$SCRIPT" quickstart >/dev/null && pass "quickstart surface" || fail "quickstart surface"
"$SCRIPT" completion zsh >/dev/null && pass "completion surface" || fail "completion surface"
"$SCRIPT" why truth | grep -q 'degraded' && pass "why surface explains truth gate" || fail "why surface explains truth gate"

if [[ "$fail_count" -gt 0 ]]; then
  printf 'SUMMARY pass=%d fail=%d\n' "$pass_count" "$fail_count"
  exit 1
fi

printf 'SUMMARY pass=%d fail=0\n' "$pass_count"
