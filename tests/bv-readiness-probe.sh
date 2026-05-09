#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
PROBE="$ROOT/.flywheel/scripts/bv-readiness-probe.sh"
TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT

fail() {
  printf 'FAIL: %s\n' "$1" >&2
  exit 1
}

cat >"$TMP/current-insights.json" <<'JSON'
{
  "schema_version": "bv.robot-insights/v0.13.0",
  "Bottlenecks": [{"ID": "flywheel-a", "Value": 1}]
}
JSON

cat >"$TMP/robot-plan.json" <<'JSON'
{
  "plan": {
    "tracks": [
      {"track_id": "track-A", "items": [{"id": "flywheel-a"}, {"id": "flywheel-b"}]},
      {"track_id": "track-B", "items": [{"id": "flywheel-c"}]}
    ]
  }
}
JSON

cat >"$TMP/br-ready.json" <<'JSON'
[
  {"id": "flywheel-br-a"},
  {"id": "flywheel-br-b"}
]
JSON

cat >"$TMP/empty-plan.json" <<'JSON'
{"plan": {"tracks": []}}
JSON

cat >"$TMP/future-insights-array.json" <<'JSON'
{
  "ready_beads": [
    {"id": "flywheel-future-a"},
    {"id": "flywheel-future-b"},
    {"id": "flywheel-future-c"},
    {"id": "flywheel-future-d"}
  ]
}
JSON

cat >"$TMP/future-insights-number.json" <<'JSON'
{"ready_beads": 5}
JSON

out="$("$PROBE" --json \
  --robot-insights-fixture "$TMP/current-insights.json" \
  --robot-plan-fixture "$TMP/robot-plan.json" \
  --br-ready-fixture "$TMP/br-ready.json")"
jq -e '.ready_count == 3 and .source == "bv_robot_plan.items" and .selected_id == "flywheel-a"' <<<"$out" >/dev/null \
  || fail "current bv fallback did not use robot-plan"

out="$("$PROBE" --json \
  --robot-insights-fixture "$TMP/current-insights.json" \
  --robot-plan-fixture "$TMP/empty-plan.json" \
  --br-ready-fixture "$TMP/br-ready.json")"
jq -e '.ready_count == 2 and .source == "br_ready" and .selected_id == "flywheel-br-a"' <<<"$out" >/dev/null \
  || fail "br ready fallback did not return ready_count"

out="$("$PROBE" --json \
  --robot-insights-fixture "$TMP/future-insights-array.json" \
  --robot-plan-fixture "$TMP/robot-plan.json" \
  --br-ready-fixture "$TMP/br-ready.json")"
jq -e '.ready_count == 4 and .source == "bv_robot_insights.ready_beads" and .selected_id == "flywheel-future-a"' <<<"$out" >/dev/null \
  || fail "future ready_beads array did not win"

out="$("$PROBE" --json --robot-insights-fixture "$TMP/future-insights-number.json")"
jq -e '.ready_count == 5 and .source == "bv_robot_insights.ready_beads"' <<<"$out" >/dev/null \
  || fail "future ready_beads number did not win"

"$PROBE" --schema >/dev/null
"$PROBE" --info >/dev/null
"$PROBE" --examples >/dev/null
"$PROBE" repair --dry-run --json | jq -e '.actual_actions == []' >/dev/null \
  || fail "repair dry-run did not report zero actual actions"

printf 'PASS tests/bv-readiness-probe.sh\n'
