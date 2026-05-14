#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
PROBE="$ROOT/.flywheel/scripts/idle-state-probe.sh"
TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT

fail() {
  printf 'FAIL: %s\n' "$1" >&2
  exit 1
}

write_json() {
  local path="$1"
  shift
  printf '%s\n' "$*" > "$path"
}

run_probe() {
  "$PROBE" --json --repo "$ROOT" --session flywheel \
    --activity-fixture "$TMP/activity.json" \
    --ready-fixture "$TMP/ready.json" \
    --mission-fixture "$TMP/mission.json" \
    --pane-last-fired "$TMP/pane-fired" \
    --bead-fired "$TMP/bead-fired" \
    --now-epoch 1000 "$@"
}

class_is() {
  local expected="$1" out
  out="$(run_probe)"
  jq -e --arg expected "$expected" '.idle_state_class[0].idle_state_class == $expected' <<<"$out" >/dev/null \
    || fail "expected class $expected, got $(jq -c '.idle_state_class' <<<"$out")"
}

write_activity() {
  local state="${1:-WAITING}" provenance="${2:-live}" age="${3:-900}"
  write_json "$TMP/activity.json" "{\"agents\":[{\"pane_idx\":2,\"state\":\"$state\",\"capture_provenance\":\"$provenance\",\"state_since_epoch\":$age}]}"
}

write_ready() {
  write_json "$TMP/ready.json" "$1"
}

write_json "$TMP/mission.json" '{"mission_pending_count":2}'
touch "$TMP/pane-fired" "$TMP/bead-fired"

write_activity WAITING live 900
write_ready '[{"id":"flywheel-a","priority":0,"created_at":"2026-05-01T00:00:00Z","title":"P0 repair"}]'
class_is dispatching

printf '2:950\n' > "$TMP/pane-fired"
class_is cooldown
> "$TMP/pane-fired"

write_ready '[]'
class_is light_queue

write_ready '[{"id":"a","priority":1,"created_at":"1","title":"x"},{"id":"b","priority":1,"created_at":"2","title":"x"},{"id":"c","priority":1,"created_at":"3","title":"x"},{"id":"d","priority":1,"created_at":"4","title":"x"},{"id":"e","priority":1,"created_at":"5","title":"x"},{"id":"f","priority":1,"created_at":"6","title":"x"},{"id":"g","priority":1,"created_at":"7","title":"x"},{"id":"h","priority":1,"created_at":"8","title":"x"},{"id":"i","priority":1,"created_at":"9","title":"x"},{"id":"j","priority":1,"created_at":"10","title":"x"}]'
printf 'a:950\nb:950\nc:950\nd:950\ne:950\nf:950\ng:950\nh:950\ni:950\nj:950\n' > "$TMP/bead-fired"
class_is saturated
> "$TMP/bead-fired"

write_activity THINKING live 900
out="$(run_probe --include-non-waiting)"
jq -e '.idle_state_summary.not_waiting == 1 and .idle_state_class[0].idle_state_class == "not_waiting"' <<<"$out" >/dev/null \
  || fail "pane-not-waiting fixture did not classify as not_waiting"

write_activity WAITING live 900
write_ready '[]'
write_json "$TMP/config-disabled.json" '{"schema_version":"idle-state-config/v1","enabled":false,"classes_active":["dispatching"],"thresholds":{"dispatching_fail_seconds":300,"pane_cooldown_seconds":180,"bead_dedupe_seconds":600,"light_queue_ready_count":10}}'
out="$(run_probe --config "$TMP/config-disabled.json")"
jq -e '.disabled == true and (.idle_state_class | length) == 0' <<<"$out" >/dev/null \
  || fail "enabled=false did not skip rows"

write_ready '[{"id":"a","priority":1,"created_at":"1","title":"x"},{"id":"b","priority":1,"created_at":"2","title":"x"},{"id":"c","priority":1,"created_at":"3","title":"x"},{"id":"d","priority":1,"created_at":"4","title":"x"},{"id":"e","priority":1,"created_at":"5","title":"x"},{"id":"f","priority":1,"created_at":"6","title":"x"},{"id":"g","priority":1,"created_at":"7","title":"x"},{"id":"h","priority":1,"created_at":"8","title":"x"},{"id":"i","priority":1,"created_at":"9","title":"x"},{"id":"j","priority":1,"created_at":"10","title":"x"}]'
printf 'a:950\nb:950\nc:950\nd:950\ne:950\nf:950\ng:950\nh:950\ni:950\nj:950\n' > "$TMP/bead-fired"
write_json "$TMP/config-filtered.json" '{"schema_version":"idle-state-config/v1","enabled":true,"classes_active":["dispatching","light_queue"],"thresholds":{"dispatching_fail_seconds":300,"pane_cooldown_seconds":180,"bead_dedupe_seconds":600,"light_queue_ready_count":10}}'
out="$(run_probe --config "$TMP/config-filtered.json")"
jq -e '.idle_state_class[0].idle_state_class == "disabled_class" and .idle_state_class[0].disabled_original_class == "saturated"' <<<"$out" >/dev/null \
  || fail "classes_active filter did not suppress saturated"

out="$("$PROBE" --json --repo "$ROOT" --session {capability-control-plane} \
  --activity-fixture "$TMP/activity.json" \
  --ready-fixture "$TMP/ready.json" \
  --mission-fixture "$TMP/mission.json" \
  --pane-last-fired "$TMP/pane-fired" \
  --bead-fired "$TMP/bead-fired" \
  --now-epoch 1000)"
jq -e '.idle_state_class[0].idle_state_class == "disabled_class" and .idle_state_class[0].disabled_original_class == "saturated"' <<<"$out" >/dev/null \
  || fail "peer orch default did not disable saturated"

write_activity WAITING live 100
write_ready '[{"id":"flywheel-a","priority":0,"created_at":"2026-05-01T00:00:00Z","title":"P0 repair"}]'
> "$TMP/bead-fired"
out="$(run_probe)"
jq -e '.status == "fail" and .idle_dispatching_over_threshold_count == 1' <<<"$out" >/dev/null \
  || fail "dispatching over threshold did not fail"

printf 'PASS tests/idle-state-probe.sh\n'
