#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd -P)"
SCRIPT="$ROOT/.flywheel/scripts/fleet-observatory-aggregate.sh"
TMP="$(mktemp -d "${TMPDIR:-/tmp}/fleet-observatory-aggregate-test.XXXXXX")"
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

chmod +x "$SCRIPT"
bash -n "$SCRIPT" && pass "script syntax" || fail "script syntax"

"$SCRIPT" --info --json >"$TMP/info.json"
assert_jq "$TMP/info.json" '.doctor_field == "fleet_observatory_health_score" and (.canonical_cli_flags | index("--watch=Ns")) and .anti_agent_shaming == true' "info exposes CLI contract"

"$SCRIPT" --schema --json >"$TMP/schema.json"
assert_jq "$TMP/schema.json" '.properties.fleet_overall_health_score.maximum == 100 and (.required | index("recommended_action"))' "schema exposes bounded score"

cat >"$TMP/green.json" <<'JSON'
{
  "peer_orch_productive_count":5,
  "peer_orch_productivity_total_count":5,
  "fleet_conformance_min_score":95,
  "fleet_conformance_yellow_count":0,
  "fleet_conformance_worst_session":"flywheel",
  "fleet_comms_min_score":100,
  "fleet_comms_worst_session":"flywheel",
  "fleet_comms_silent_session_count":0,
  "fleet_comms_token_stale_count":0,
  "fleet_process_open_gap_count":0,
  "fleet_process_health_score":100,
  "fleet_process_gap_detector":{"top_gaps":[]},
  "fleet_metrics":{"rework_ratio":0.05,"founder_dispose_pct":0.10},
  "fleet_identity_drift_count":0,
  "fleet_repo_l_rule_lag_count":0,
  "fleet_watcher_coverage_count":5,
  "fleet_watcher_coverage_total":5
}
JSON

cat >"$TMP/red.json" <<'JSON'
{
  "peer_orch_productive_count":2,
  "peer_orch_productivity_total_count":5,
  "fleet_conformance_min_score":45,
  "fleet_conformance_yellow_count":1,
  "fleet_conformance_worst_session":"{session}",
  "fleet_comms_min_score":50,
  "fleet_comms_worst_session":"{capability-control-plane}",
  "fleet_comms_silent_session_count":2,
  "fleet_comms_token_stale_count":1,
  "fleet_process_open_gap_count":7,
  "fleet_process_top_gap_class":"sticky_doctor_error",
  "fleet_process_gap_detector":{"top_gaps":[{"class":"sticky_doctor_error"},{"class":"fleet_identity_drift"},{"class":"watcher_hole"}]},
  "fleet_metrics":{"rework_ratio":0.90,"founder_dispose_pct":0.40},
  "fleet_identity_drift_count":3,
  "fleet_repo_l_rule_lag_count":12,
  "fleet_watcher_coverage_count":2,
  "fleet_watcher_coverage_total":5
}
JSON

cat >"$TMP/math.json" <<'JSON'
{
  "peer_orch_productive_count":4,
  "peer_orch_productivity_total_count":5,
  "fleet_conformance_min_score":80,
  "fleet_comms_min_score":90,
  "fleet_process_open_gap_count":2,
  "fleet_metrics":{"rework_ratio":0.20,"founder_dispose_pct":0.20},
  "fleet_identity_drift_count":1,
  "fleet_repo_l_rule_lag_count":4,
  "fleet_watcher_coverage_count":3,
  "fleet_watcher_coverage_total":5
}
JSON

cat >"$TMP/missing.json" <<'JSON'
{"status":"warn"}
JSON

"$SCRIPT" --doctor-json "$TMP/green.json" --json >"$TMP/green-out.json"
assert_jq "$TMP/green-out.json" '.fleet_overall_health_score >= 85 and .status == "green"' "known-green fixture is green"
assert_jq "$TMP/green-out.json" '.spines_aggregated == 8 and (.spines | length) == 8' "all eight spines aggregated"

"$SCRIPT" --doctor-json "$TMP/red.json" --json >"$TMP/red-out.json" || true
assert_jq "$TMP/red-out.json" '.fleet_overall_health_score < 60 and .status == "red"' "known-red fixture is red"
assert_jq "$TMP/red-out.json" '.worst_session == "{session}" and .worst_spine == "architecture"' "worst session and spine selected"
assert_jq "$TMP/red-out.json" '.top_process_gaps == ["sticky_doctor_error","fleet_identity_drift","watcher_hole"]' "top three process gaps surfaced"
assert_jq "$TMP/red-out.json" '.recommended_action | contains("rework")' "recommended action follows worst spine"

"$SCRIPT" --doctor-json "$TMP/math.json" --json >"$TMP/math-out.json"
assert_jq "$TMP/math-out.json" '.fleet_overall_health_score == 78' "weighted mean math correctness"
assert_jq "$TMP/math-out.json" '.spines[] | select(.name == "l_rule_lag" and .score == 80)' "L-rule lag score math"
assert_jq "$TMP/math-out.json" '.spines[] | select(.name == "identity_drift" and .score == 75)' "identity score math"

"$SCRIPT" --doctor-json "$TMP/missing.json" --json >"$TMP/missing-out.json"
assert_jq "$TMP/missing-out.json" '.spines_aggregated == 8 and .fleet_overall_health_score >= 0 and .fleet_overall_health_score <= 100' "missing spines degrade gracefully"

"$SCRIPT" --doctor-json "$TMP/green.json" --no-emoji >"$TMP/render.txt"
grep -q "FLEET OBSERVATORY" "$TMP/render.txt" && pass "dashboard renders title" || fail "dashboard renders title"
grep -q "OVERALL HEALTH" "$TMP/render.txt" && pass "dashboard renders overall health" || fail "dashboard renders overall health"

if [[ "$fail_count" -gt 0 ]]; then
  printf 'SUMMARY pass=%d fail=%d\n' "$pass_count" "$fail_count" >&2
  exit 1
fi
printf 'SUMMARY pass=%d fail=0\n' "$pass_count"
