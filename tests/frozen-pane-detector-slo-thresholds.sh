#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd -P)"
DETECTOR="$ROOT/.flywheel/scripts/frozen-pane-detector.sh"
FLEET="$ROOT/.flywheel/scripts/frozen-pane-detector-fleet.sh"
TMP="$(mktemp -d "${TMPDIR:-/tmp}/frozen-pane-slo-thresholds.XXXXXX")"
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
    sed -n '1,140p' "$file" >&2 || true
  fi
}

fleet_env() {
  FROZEN_FLEET_STATE_DIR="$TMP/fleet-state" \
  FROZEN_FLEET_PLIST="$TMP/ai.zeststream.frozen-pane-detector-fleet.plist" \
  FROZEN_FLEET_STDOUT_PATH="$TMP/logs/out.log" \
  FROZEN_FLEET_STDERR_PATH="$TMP/logs/err.log" \
  "$@"
}

bash -n "$DETECTOR" && pass "detector syntax" || fail "detector syntax"
bash -n "$FLEET" && pass "fleet syntax" || fail "fleet syntax"

"$DETECTOR" --info >"$TMP/detector-info.json"
assert_jq "$TMP/detector-info.json" '.defaults.threshold_seconds == 90 and .defaults.queued_threshold_seconds == 60' "detector SLO defaults are 90s/60s"
assert_jq "$TMP/detector-info.json" '.defaults.queued_timer_drift_seconds == 60 and .defaults.respawn_suppression_seconds == 120' "non-target detector recovery windows remain unchanged"

FROZEN_PANE_THRESHOLD_SECONDS=111 FROZEN_PANE_QUEUED_THRESHOLD_SECONDS=55 "$DETECTOR" --info >"$TMP/detector-env-info.json"
assert_jq "$TMP/detector-env-info.json" '.defaults.threshold_seconds == 111 and .defaults.queued_threshold_seconds == 55' "detector env overrides remain wired"

"$DETECTOR" --threshold-seconds 123 --queued-threshold-seconds 45 --doctor --json >"$TMP/detector-doctor.json"
assert_jq "$TMP/detector-doctor.json" '.recovery_policy.threshold_seconds == 123 and .recovery_policy.queued_threshold_seconds == 45' "detector CLI overrides reach doctor policy"

fleet_env "$FLEET" --doctor --json >"$TMP/fleet-doctor-absent.json"
assert_jq "$TMP/fleet-doctor-absent.json" '.cadence_seconds == 30 and .recovery_budget.per_pane_per_hour == 1' "fleet SLO cadence is 30s and per-pane budget stays one"

fleet_env "$FLEET" install --apply --json >"$TMP/fleet-install.json"
assert_jq "$TMP/fleet-install.json" '.applied == true and .disabled_by_default == true' "fleet install writes disabled LaunchAgent"
if plutil -extract StartInterval raw "$TMP/ai.zeststream.frozen-pane-detector-fleet.plist" | grep -qx '30'; then
  pass "plist StartInterval is 30"
else
  fail "plist StartInterval is 30"
fi

if [[ "$fail_count" -gt 0 ]]; then
  printf 'SUMMARY pass=%d fail=%d\n' "$pass_count" "$fail_count"
  exit 1
fi

printf 'SUMMARY pass=%d fail=0\n' "$pass_count"
