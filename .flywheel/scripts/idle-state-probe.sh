#!/usr/bin/env bash
set -euo pipefail

SESSION="flywheel"
REPO="/Users/josh/Developer/flywheel"
ACTIVITY_FIXTURE="${FLYWHEEL_IDLE_STATE_ACTIVITY_FIXTURE:-}"
READY_FIXTURE="${FLYWHEEL_IDLE_STATE_READY_FIXTURE:-}"
MISSION_FIXTURE="${FLYWHEEL_IDLE_STATE_MISSION_FIXTURE:-}"
CONFIG_PATH="${FLYWHEEL_IDLE_STATE_CONFIG:-}"
PANE_LAST_FIRED="${FLYWHEEL_IDLE_STATE_PANE_LAST_FIRED:-/tmp/idle-pane-last-fired}"
BEAD_FIRED="${FLYWHEEL_IDLE_STATE_BEAD_FIRED:-/tmp/watcher-bead-fired}"
NOW_EPOCH="${FLYWHEEL_IDLE_STATE_NOW_EPOCH:-$(date +%s)}"
JSON_OUT=0
DOCTOR=0
INCLUDE_NON_WAITING=0

usage() {
  printf '%s\n' "usage: idle-state-probe.sh --json [--session flywheel] [--repo PATH] [--activity-fixture PATH] [--ready-fixture PATH] [--mission-fixture PATH] [--config PATH]"
}

info() {
  jq -nc '{
    command:"idle-state-probe.sh",
    schema_version:"idle-state-probe/v1",
    purpose:"Classify idle worker panes for doctor and watcher consumption",
    states:["dispatching","cooldown","light_queue","saturated","disabled_class","not_waiting"],
    canonical_paths:[".flywheel/scripts/idle-state-probe.sh",".flywheel/validation-schema/v1/idle-state-config.schema.json"]
  }'
}

examples() {
  printf '%s\n' \
    "idle-state-probe.sh --json" \
    "idle-state-probe.sh --doctor --json --session flywheel" \
    "FLYWHEEL_IDLE_STATE_ACTIVITY_FIXTURE=/tmp/activity.json idle-state-probe.sh --json"
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --json) JSON_OUT=1; shift ;;
    --doctor) DOCTOR=1; JSON_OUT=1; shift ;;
    --include-non-waiting) INCLUDE_NON_WAITING=1; shift ;;
    --session) SESSION="${2:?}"; shift 2 ;;
    --repo) REPO="${2:?}"; shift 2 ;;
    --activity-fixture) ACTIVITY_FIXTURE="${2:?}"; shift 2 ;;
    --ready-fixture) READY_FIXTURE="${2:?}"; shift 2 ;;
    --mission-fixture) MISSION_FIXTURE="${2:?}"; shift 2 ;;
    --config) CONFIG_PATH="${2:?}"; shift 2 ;;
    --now-epoch) NOW_EPOCH="${2:?}"; shift 2 ;;
    --pane-last-fired) PANE_LAST_FIRED="${2:?}"; shift 2 ;;
    --bead-fired) BEAD_FIRED="${2:?}"; shift 2 ;;
    --help|-h) usage; exit 0 ;;
    --info) info; exit 0 ;;
    --examples) examples; exit 0 ;;
    --version) printf '%s\n' "idle-state-probe 1.0.0"; exit 0 ;;
    *) printf 'ERR: unknown argument: %s\n' "$1" >&2; usage >&2; exit 64 ;;
  esac
done

default_config() {
  local classes
  if [[ "$SESSION" == "mobile-eats" || "$SESSION" == "skillos" ]]; then
    classes='["dispatching","light_queue"]'
  else
    classes='["dispatching","cooldown","light_queue","saturated"]'
  fi
  jq -nc --argjson classes "$classes" '{
    schema_version:"idle-state-config/v1",
    enabled:true,
    classes_active:$classes,
    thresholds:{
      dispatching_fail_seconds:300,
      pane_cooldown_seconds:180,
      bead_dedupe_seconds:600,
      light_queue_ready_count:10
    },
    peer_orch_escalation:"xpane_to_flywheel_1"
  }'
}

config_json="$(default_config)"
config_loaded=false
if [[ -n "$CONFIG_PATH" && -f "$CONFIG_PATH" ]]; then
  if jq -e . "$CONFIG_PATH" >/dev/null 2>&1; then
    config_json="$(jq -c --argjson defaults "$config_json" '
      $defaults
      * .
      | .thresholds = (($defaults.thresholds // {}) * (.thresholds // {}))
    ' "$CONFIG_PATH")"
    config_loaded=true
  fi
elif [[ -f "$REPO/.flywheel/idle-state-config.json" ]]; then
  CONFIG_PATH="$REPO/.flywheel/idle-state-config.json"
  if jq -e . "$CONFIG_PATH" >/dev/null 2>&1; then
    config_json="$(jq -c --argjson defaults "$config_json" '
      $defaults
      * .
      | .thresholds = (($defaults.thresholds // {}) * (.thresholds // {}))
    ' "$CONFIG_PATH")"
    config_loaded=true
  fi
fi

enabled="$(jq -r 'if has("enabled") then .enabled else true end' <<<"$config_json")"
dispatching_fail_seconds="$(jq -r '.thresholds.dispatching_fail_seconds // 300' <<<"$config_json")"
pane_cooldown_seconds="$(jq -r '.thresholds.pane_cooldown_seconds // 180' <<<"$config_json")"
bead_dedupe_seconds="$(jq -r '.thresholds.bead_dedupe_seconds // 600' <<<"$config_json")"
light_queue_ready_count="$(jq -r '.thresholds.light_queue_ready_count // 10' <<<"$config_json")"

if [[ "$enabled" != "true" ]]; then
  jq -nc --arg session "$SESSION" --arg repo "$REPO" --arg config_path "$CONFIG_PATH" --argjson config_loaded "$config_loaded" '{
    schema_version:"idle-state-probe/v1",
    status:"pass",
    session:$session,
    repo:$repo,
    idle_state_class:[],
    idle_state_summary:{dispatching:0,cooldown:0,light_queue:0,saturated:0,disabled_class:0,not_waiting:0},
    idle_dispatching_over_threshold_count:0,
    idle_state_config_path:(if $config_path == "" then null else $config_path end),
    idle_state_config_loaded:$config_loaded,
    disabled:true
  }'
  exit 0
fi

activity_json='{"agents":[]}'
if [[ -n "$ACTIVITY_FIXTURE" ]]; then
  activity_json="$(jq -c . "$ACTIVITY_FIXTURE")"
else
  activity_json="$(/Users/josh/.local/bin/ntm --robot-activity="$SESSION" --activity-type=codex 2>/dev/null || printf '{"agents":[]}')"
fi

ready_json='[]'
if [[ -n "$READY_FIXTURE" ]]; then
  ready_json="$(jq -c . "$READY_FIXTURE")"
else
  if [[ -d "$REPO" ]]; then
    ready_json="$(cd "$REPO" && br ready --json 2>/dev/null || printf '[]')"
  fi
fi

mission_pending_count=0
if [[ -n "$MISSION_FIXTURE" ]]; then
  mission_pending_count="$(jq -r 'if type == "number" then . else (.mission_pending_count // 0) end' "$MISSION_FIXTURE")"
fi

fired_beads_json='[]'
if [[ -f "$BEAD_FIRED" ]]; then
  cutoff=$((NOW_EPOCH - bead_dedupe_seconds))
  fired_beads_json="$(awk -F: -v cutoff="$cutoff" '$2 >= cutoff {print $1}' "$BEAD_FIRED" 2>/dev/null | sort -u | jq -Rsc 'split("\n") | map(select(length>0))')"
fi

pane_last_json='{}'
if [[ -f "$PANE_LAST_FIRED" ]]; then
  pane_last_json="$(awk -F: 'NF >= 2 {print "{\"pane\":\""$1"\",\"last\":"$2"}"}' "$PANE_LAST_FIRED" 2>/dev/null | jq -sc 'map(select(.pane != "")) | reduce .[] as $r ({}; .[$r.pane] = $r.last)' 2>/dev/null || printf '{}')"
fi

entries="$(jq -nc \
  --argjson activity "$activity_json" \
  --argjson ready "$ready_json" \
  --argjson fired "$fired_beads_json" \
  --argjson pane_last "$pane_last_json" \
  --argjson config "$config_json" \
  --arg session "$SESSION" \
  --argjson now "$NOW_EPOCH" \
  --argjson mission_pending_count "$mission_pending_count" \
  --argjson pane_cooldown_seconds "$pane_cooldown_seconds" \
  --argjson light_queue_ready_count "$light_queue_ready_count" \
  --argjson include_non_waiting "$([[ "$INCLUDE_NON_WAITING" -eq 1 ]] && printf true || printf false)" '
  def epic: ((.title // .description // "") | test("(^|[^a-z])epic[- ]|EPIC|meta-?epic"; "i"));
  def open_ready:
    $ready
    | map(select((.priority // 99) <= 1))
    | map(select(epic | not));
  def candidates:
    open_ready
    | map(select((.id // "") as $id | ($fired | index($id)) | not))
    | sort_by((.priority // 99), (.created_at // ""));
  def oldest($p):
    candidates
    | map(select((.priority // 99) == $p))
    | sort_by(.created_at // "")
    | .[0].id // null;
  def is_active($class): (($config.classes_active // []) | index($class)) != null;
  def pane_age($a):
    if ($a.state_since_epoch? | type == "number") then ($now - $a.state_since_epoch)
    elif ($a.waiting_since_epoch? | type == "number") then ($now - $a.waiting_since_epoch)
    else 0 end;
  [($activity.agents // [])
    | map(select((.pane_idx // .pane // 0) >= 2 and (.pane_idx // .pane // 0) <= 4))
    | .[]
    | (.pane_idx // .pane) as $pane
    | (.state // "UNKNOWN") as $state
    | (.capture_provenance // "") as $prov
    | if (($state != "WAITING" or $prov != "live") and ($include_non_waiting | not)) then empty
      else
        (candidates) as $candidates
        | (oldest(0)) as $oldest_p0
        | (oldest(1)) as $oldest_p1
        | ($pane_last[($pane|tostring)] // 0) as $last
        | (if ($state != "WAITING" or $prov != "live") then "not_waiting"
           elif (($last|tonumber) > 0 and ($now - ($last|tonumber)) < $pane_cooldown_seconds) then "cooldown"
           elif (($candidates | length) > 0) then "dispatching"
           elif ((open_ready | length) >= $light_queue_ready_count) then "saturated"
           else "light_queue" end) as $raw_class
        | (if ($raw_class == "not_waiting" or is_active($raw_class)) then $raw_class else "disabled_class" end) as $class
        | {
            pane:$pane,
            state:$state,
            capture_provenance:$prov,
            idle_state_class:$class,
            disabled_original_class:(if $class == "disabled_class" then $raw_class else null end),
            oldest_p0:$oldest_p0,
            oldest_p1:$oldest_p1,
            mission_pending_count:$mission_pending_count,
            dispatch_candidate:($candidates[0].id // null),
            dispatch_priority:($candidates[0].priority // null),
            ready_p0_p1_count:(open_ready | length),
            cooldown_remaining_seconds:(if $class == "cooldown" then (($pane_cooldown_seconds - ($now - ($last|tonumber))) | if . < 0 then 0 else . end) else 0 end),
            age_seconds:(pane_age(.))
          }
      end]'
)"

summary="$(jq -nc --argjson entries "$entries" '
  {
    dispatching:($entries | map(select(.idle_state_class == "dispatching")) | length),
    cooldown:($entries | map(select(.idle_state_class == "cooldown")) | length),
    light_queue:($entries | map(select(.idle_state_class == "light_queue")) | length),
    saturated:($entries | map(select(.idle_state_class == "saturated")) | length),
    disabled_class:($entries | map(select(.idle_state_class == "disabled_class")) | length),
    not_waiting:($entries | map(select(.idle_state_class == "not_waiting")) | length)
  }')"
over_threshold="$(jq -r --argjson threshold "$dispatching_fail_seconds" '[.[] | select(.idle_state_class == "dispatching" and (.age_seconds // 0) > $threshold)] | length' <<<"$entries")"
status="pass"
if [[ "${over_threshold:-0}" -gt 0 ]]; then
  status="fail"
fi

jq -nc \
  --arg schema_version "idle-state-probe/v1" \
  --arg status "$status" \
  --arg session "$SESSION" \
  --arg repo "$REPO" \
  --arg config_path "$CONFIG_PATH" \
  --argjson config_loaded "$config_loaded" \
  --argjson entries "$entries" \
  --argjson summary "$summary" \
  --argjson over_threshold "$over_threshold" \
  --argjson threshold "$dispatching_fail_seconds" \
  '{
    schema_version:$schema_version,
    status:$status,
    session:$session,
    repo:$repo,
    idle_state_class:$entries,
    idle_state_summary:$summary,
    idle_dispatching_over_threshold_count:$over_threshold,
    idle_dispatching_threshold_seconds:$threshold,
    idle_state_config_path:(if $config_path == "" then null else $config_path end),
    idle_state_config_loaded:$config_loaded
  }'
