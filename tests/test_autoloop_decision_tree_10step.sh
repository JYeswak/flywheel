#!/usr/bin/env bash
set -euo pipefail

BIN="${FLYWHEEL_AUTOLOOP_BIN:-$HOME/.claude/skills/.flywheel/bin/flywheel-autoloop}"
TMP="$(mktemp -d -t autoloop-exec.XXXXXX)"
trap 'rm -r "$TMP"' EXIT

mkdir -p "$TMP/fw" "$TMP/state"

make_state() {
  local step="$1" file="$2"
  case "$step" in
    1) jq -n '{stop_present:true}' >"$file" ;;
    2) jq -n '{next_tick_override_present:true}' >"$file" ;;
    3) jq -n '{pending_callbacks:1}' >"$file" ;;
    4) jq -n '{doctor_fail:true}' >"$file" ;;
    5) jq -n '{ready_beads:1}' >"$file" ;;
    6) jq -n '{git_dirty:true}' >"$file" ;;
    7) jq -n '{state_stale:true}' >"$file" ;;
    8) jq -n '{external_deltas:1}' >"$file" ;;
    9) jq -n '{bead_graph_insufficient:true}' >"$file" ;;
    10) jq -n '{}' >"$file" ;;
  esac
}

expected_action() {
  case "$1" in
    1) printf 'blocked_receipt_cooldown\n' ;;
    2) printf 'execute_override_or_explain\n' ;;
    3) printf 'reap_validate_close\n' ;;
    4) printf 'repair_before_feature_work\n' ;;
    5) printf 'dispatch_one_bounded_lane\n' ;;
    6) printf 'smallest_validation\n' ;;
    7) printf 'update_repo_local_state_work\n' ;;
    8) printf 'bounded_research\n' ;;
    9) printf 'plan_space_artifact\n' ;;
    10) printf 'legitimate_idle_receipt_cooldown\n' ;;
  esac
}

for step in 1 2 3 4 5 6 7 8 9 10; do
  state="$TMP/state-$step.json"
  out="$TMP/out-$step.json"
  make_state "$step" "$state"
  HOME="$TMP/home" FLYWHEEL_HOME="$TMP/fw" FLYWHEEL_AUTOLOOP_STATE_DIR="$TMP/state" \
    "$BIN" executor --decision-tree --state "$state" --json >"$out"
  jq -e --argjson step "$step" --arg action "$(expected_action "$step")" '
    .schema_version == "flywheel-autoloop.decision-tree.v1"
    and (.steps | length) == 10
    and .next_step == $step
    and .next_action == $action
  ' "$out" >/dev/null
done

printf 'PASS autoloop decision tree 10 steps\n'
