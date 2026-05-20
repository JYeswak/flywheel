#!/usr/bin/env bash
set -euo pipefail

VERSION="idle-pane-mechanical-gate/v1"

REPO="${PWD:-/Users/josh/Developer/flywheel}"
SESSION="${FLYWHEEL_SESSION:-flywheel}"
RECEIPT=""
DISPATCH_LOG=""
IDLE_STATE_PROBE=""
PEER_BLOCKER_WATCH=""
PEER_LEDGER="${FLYWHEEL_CROSS_ORCH_COORDINATION_LEDGER:-$HOME/.local/state/flywheel/cross-orch-coordination.jsonl}"
NTM="${NTM:-/Users/josh/.local/bin/ntm}"
ACTIVITY_FIXTURE="${FLYWHEEL_IDLE_GATE_ACTIVITY_FIXTURE:-}"
READY_FIXTURE="${FLYWHEEL_IDLE_GATE_READY_FIXTURE:-}"
MEMORY_READY_FILE="${FLYWHEEL_IDLE_GATE_MEMORY_READY_FILE:-}"
MEMORY_READY_COUNT="${FLYWHEEL_IDLE_GATE_MEMORY_READY_COUNT:-0}"
NOW_EPOCH="${FLYWHEEL_IDLE_GATE_NOW_EPOCH:-}"
JSON_OUT=0
STRICT_RECEIPT=0
REQUIRE_WORK_HUNT=0
HOOK_EVENT="${FLYWHEEL_IDLE_GATE_HOOK_EVENT:-}"

usage() {
  cat <<'USAGE'
usage: idle-pane-mechanical-gate.sh --repo PATH --session NAME [options]

Orchestrator-side closeout gate for L70 v2 idle enforcement.

Options:
  --repo PATH                 Repo whose tick is closing.
  --session NAME              NTM session name.
  --receipt PATH              Closeout receipt JSON or tick result JSON.
  --dispatch-log PATH         JSONL log; latest l70_chain_decision is fallback input.
  --idle-state-probe PATH     Override canonical idle-state-probe.sh path.
  --peer-blocker-watch PATH   Override peer-orch-blocker-watch.sh path.
  --peer-ledger PATH          Cross-orch coordination JSONL path.
  --memory-ready-file PATH    JSON/JSONL/text memory work-hits queue.
  --memory-ready-count N      Ready memory hits supplied by caller.
  --activity-fixture PATH     Fixture passed through to idle-state-probe.
  --ready-fixture PATH        Fixture passed through to idle-state-probe and ready probe.
  --now-epoch N               Deterministic timestamp for fixtures.
  --strict-receipt            Missing/invalid L70 fields may block.
  --require-work-hunt         no_work requires work_hunt_completed=true.
  --hook-event NAME           Emit Claude hook-shaped denial for PreToolUse/Stop.
  --json                      Emit full JSON decision.
  --help                      Show this help.

Exit:
  0 allow tick close
  2 block tick close; stderr names the mechanical fault

This gate is intended to run from receipt validators and staged hook wrappers.
USAGE
}

examples() {
  cat <<'EXAMPLES'
idle-pane-mechanical-gate.sh --repo /Users/josh/Developer/flywheel --session flywheel --json
idle-pane-mechanical-gate.sh --repo "$PWD" --session mobile-eats --receipt .flywheel/last_closeout_receipt.json --strict-receipt --json
idle-pane-mechanical-gate.sh --repo "$PWD" --session skillos --dispatch-log .flywheel/dispatch-log.jsonl --json
EXAMPLES
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --repo) REPO="${2:?}"; shift 2 ;;
    --session) SESSION="${2:?}"; shift 2 ;;
    --receipt) RECEIPT="${2:?}"; shift 2 ;;
    --dispatch-log) DISPATCH_LOG="${2:?}"; shift 2 ;;
    --idle-state-probe) IDLE_STATE_PROBE="${2:?}"; shift 2 ;;
    --peer-blocker-watch) PEER_BLOCKER_WATCH="${2:?}"; shift 2 ;;
    --peer-ledger) PEER_LEDGER="${2:?}"; shift 2 ;;
    --memory-ready-file) MEMORY_READY_FILE="${2:?}"; shift 2 ;;
    --memory-ready-count) MEMORY_READY_COUNT="${2:?}"; shift 2 ;;
    --activity-fixture) ACTIVITY_FIXTURE="${2:?}"; shift 2 ;;
    --ready-fixture) READY_FIXTURE="${2:?}"; shift 2 ;;
    --now-epoch) NOW_EPOCH="${2:?}"; shift 2 ;;
    --strict-receipt) STRICT_RECEIPT=1; shift ;;
    --require-work-hunt) REQUIRE_WORK_HUNT=1; shift ;;
    --hook-event) HOOK_EVENT="${2:?}"; shift 2 ;;
    --json) JSON_OUT=1; shift ;;
    --examples) examples; exit 0 ;;
    --help|-h) usage; exit 0 ;;
    *) printf 'ERR: unknown argument: %s\n' "$1" >&2; usage >&2; exit 64 ;;
  esac
done

if [[ "${CLAUDE_STOP_HOOK_ACTIVE:-}" == "true" || "${stop_hook_active:-}" == "true" ]]; then
  # Stop hooks must not trap the model in a recursive continue loop.
  [[ "$JSON_OUT" -eq 1 ]] && jq -nc --arg version "$VERSION" '{schema_version:$version,status:"pass",decision:"allow",reason:"stop_hook_active"}'
  exit 0
fi

if ! command -v jq >/dev/null 2>&1; then
  printf 'IDLE PANE MECHANICAL GATE: jq missing; allowing for backcompat.\n' >&2
  exit 0
fi

REPO="$(cd "$REPO" 2>/dev/null && pwd -P || printf '%s' "$REPO")"
[[ -n "$DISPATCH_LOG" ]] || DISPATCH_LOG="$REPO/.flywheel/dispatch-log.jsonl"

if [[ -z "$IDLE_STATE_PROBE" ]]; then
  if [[ -x "$REPO/.flywheel/scripts/idle-state-probe.sh" ]]; then
    IDLE_STATE_PROBE="$REPO/.flywheel/scripts/idle-state-probe.sh"
  elif [[ -x "$HOME/Developer/flywheel/.flywheel/scripts/idle-state-probe.sh" ]]; then
    IDLE_STATE_PROBE="$HOME/Developer/flywheel/.flywheel/scripts/idle-state-probe.sh"
  else
    IDLE_STATE_PROBE=""
  fi
fi

if [[ -z "$PEER_BLOCKER_WATCH" ]]; then
  if [[ -x "$REPO/.flywheel/scripts/peer-orch-blocker-watch.sh" ]]; then
    PEER_BLOCKER_WATCH="$REPO/.flywheel/scripts/peer-orch-blocker-watch.sh"
  elif [[ -x "$HOME/Developer/flywheel/.flywheel/scripts/peer-orch-blocker-watch.sh" ]]; then
    PEER_BLOCKER_WATCH="$HOME/Developer/flywheel/.flywheel/scripts/peer-orch-blocker-watch.sh"
  else
    PEER_BLOCKER_WATCH=""
  fi
fi

json_file_or_empty() {
  local path="$1"
  if [[ -n "$path" && -f "$path" ]] && jq -e . "$path" >/dev/null 2>&1; then
    jq -c . "$path"
  else
    printf '{}\n'
  fi
}

latest_l70_from_log() {
  local log="$1"
  if [[ -f "$log" ]]; then
    jq -s -c '[.[]? | select(type=="object") | select((.event // "") == "l70_chain_decision")] | last // {}' "$log" 2>/dev/null || printf '{}\n'
  else
    printf '{}\n'
  fi
}

receipt_input_json() {
  if [[ -n "$RECEIPT" && -f "$RECEIPT" ]]; then
    json_file_or_empty "$RECEIPT"
  else
    latest_l70_from_log "$DISPATCH_LOG"
  fi
}

extract_l70_fields() {
  jq -c '
    def yn:
      if . == true or . == "true" or . == "yes" or . == "YES" then "yes"
      elif . == false or . == "false" or . == "no" or . == "NO" then "no"
      elif . == null then null
      else tostring end;
    def nonempty:
      if . == null then null
      else (tostring | if length == 0 then null else . end) end;
    . as $r
    | (($r.chain_required // false) == true) as $chain_required
    | {
        receipt_present: (($r | length) > 0),
        l70_contract_version: ($r.l70_contract_version // $r.l70.contract_version // null),
        event: ($r.event // null),
        status: ($r.status // null),
        decision: ($r.decision // null),
        next_action_named: (
          $r.next_action_named //
          $r.next_action //
          $r.next_phase //
          $r.chain_blocker.next_phase //
          $r.to_phase //
          null
        ),
        same_tick_chain_attempted: (
          $r.same_tick_chain_attempted //
          $r.chain_result.same_tick_chain_attempted //
          $r.l70.same_tick_chain_attempted //
          (if $chain_required then ($r.chained // false) else null end)
          | yn
        ),
        chain_blocked_reason: (
          $r.chain_blocked_reason //
          $r.chain_blocker.chain_blocked_reason //
          $r.l70.chain_blocked_reason //
          "none"
          | tostring
        ),
        peer_blocker_routed: (
          $r.peer_blocker_routed //
          $r.flywheel_blocker_routed //
          $r.flywheel_blocker_dispatched_to //
          "none"
          | tostring
        ),
        idle_reason_class: (
          $r.idle_reason_class //
          $r.idle_state_class //
          $r.l70.idle_reason_class //
          null
        ),
        work_hunt_completed: (
          $r.work_hunt_completed //
          $r.work_hunt_probe_completed //
          $r.l70.work_hunt_completed //
          false
          | yn
        ),
        tick_complete_like: (
          (($r.event // $r.status // $r.decision // "") | tostring | test("tick_complete|done|complete|IDLE_CLEAN"; "i"))
        ),
        chain_required: $chain_required,
        chained: ($r.chained // null)
      }
  '
}

memory_ready_count() {
  local path="$MEMORY_READY_FILE" count="$MEMORY_READY_COUNT"
  if [[ -n "$path" && -f "$path" ]]; then
    if jq -e . "$path" >/dev/null 2>&1; then
      count="$(jq 'if type=="array" then length elif type=="object" then ([.[]?] | length) else 0 end' "$path" 2>/dev/null || printf '0')"
    else
      count="$(grep -cv '^[[:space:]]*$' "$path" 2>/dev/null || printf '0')"
    fi
  fi
  case "$count" in
    ''|*[!0-9]*) printf '0\n' ;;
    *) printf '%s\n' "$count" ;;
  esac
}

ready_work_count() {
  if [[ -n "$READY_FIXTURE" && -f "$READY_FIXTURE" ]]; then
    jq 'if type=="array" then length else (.issues // [] | length) end' "$READY_FIXTURE" 2>/dev/null || printf '0\n'
    return 0
  fi
  if command -v br >/dev/null 2>&1 && [[ -d "$REPO" ]]; then
    local out
    out="$(cd "$REPO" && br ready --json 2>/dev/null || true)"
    if jq -e . >/dev/null 2>&1 <<<"$out"; then
      jq 'if type=="array" then length else (.issues // [] | length) end' <<<"$out" 2>/dev/null || printf '0\n'
      return 0
    fi
  fi
  if [[ -f "$REPO/.beads/issues.jsonl" ]]; then
    jq -s '[.[]? | select(type=="object") | select((.status // "open") != "closed")] | length' "$REPO/.beads/issues.jsonl" 2>/dev/null || printf '0\n'
    return 0
  fi
  printf '0\n'
}

idle_state_json() {
  if [[ -z "$IDLE_STATE_PROBE" ]]; then
    jq -nc '{schema_version:"idle-state-probe/v1",status:"warn",idle_state_class:[],idle_state_summary:{},idle_dispatching_over_threshold_count:0,warning:"idle_state_probe_missing"}'
    return 0
  fi

  local args=(--json --repo "$REPO" --session "$SESSION")
  [[ -n "$ACTIVITY_FIXTURE" ]] && args+=(--activity-fixture "$ACTIVITY_FIXTURE")
  [[ -n "$READY_FIXTURE" ]] && args+=(--ready-fixture "$READY_FIXTURE")
  [[ -n "$NOW_EPOCH" ]] && args+=(--now-epoch "$NOW_EPOCH")

  local out
  out="$("$IDLE_STATE_PROBE" "${args[@]}" 2>/dev/null || true)"
  if jq -e . >/dev/null 2>&1 <<<"$out"; then
    printf '%s\n' "$out"
  else
    jq -nc '{schema_version:"idle-state-probe/v1",status:"warn",idle_state_class:[],idle_state_summary:{},idle_dispatching_over_threshold_count:0,warning:"idle_state_probe_invalid_json"}'
  fi
}

peer_blocker_json() {
  if [[ -z "$PEER_BLOCKER_WATCH" ]]; then
    jq -nc '{schema_version:"peer-orch-blocker-watch/v1",status:"warn",stale_blockers_count:0,warning:"peer_blocker_watch_missing"}'
    return 0
  fi
  local out
  out="$("$PEER_BLOCKER_WATCH" --doctor --json --ledger "$PEER_LEDGER" 2>/dev/null || true)"
  if jq -e . >/dev/null 2>&1 <<<"$out"; then
    printf '%s\n' "$out"
  else
    jq -nc '{schema_version:"peer-orch-blocker-watch/v1",status:"warn",stale_blockers_count:0,warning:"peer_blocker_watch_invalid_json"}'
  fi
}

build_decision() {
  local receipt_json l70 idle_json peer_json ready_count memory_count
  receipt_json="$(receipt_input_json)"
  l70="$(printf '%s\n' "$receipt_json" | extract_l70_fields)"
  idle_json="$(idle_state_json)"
  peer_json="$(peer_blocker_json)"
  ready_count="$(ready_work_count)"
  memory_count="$(memory_ready_count)"

  jq -nc \
    --arg version "$VERSION" \
    --arg repo "$REPO" \
    --arg session "$SESSION" \
    --arg receipt "${RECEIPT:-}" \
    --arg dispatch_log "$DISPATCH_LOG" \
    --arg idle_state_probe "$IDLE_STATE_PROBE" \
    --arg peer_blocker_watch "$PEER_BLOCKER_WATCH" \
    --argjson strict_receipt "$([[ "$STRICT_RECEIPT" -eq 1 ]] && printf true || printf false)" \
    --argjson require_work_hunt "$([[ "$REQUIRE_WORK_HUNT" -eq 1 ]] && printf true || printf false)" \
    --argjson l70 "$l70" \
    --argjson idle "$idle_json" \
    --argjson peer "$peer_json" \
    --argjson ready_count "$ready_count" \
    --argjson memory_count "$memory_count" '
      def has_ready: (($ready_count + $memory_count) > 0);
      def dispatching_count: ($idle.idle_state_summary.dispatching // ([($idle.idle_state_class // [])[]? | select(.idle_state_class == "dispatching")] | length));
      def light_queue_count: ($idle.idle_state_summary.light_queue // ([($idle.idle_state_class // [])[]? | select(.idle_state_class == "light_queue")] | length));
      def saturated_count: ($idle.idle_state_summary.saturated // ([($idle.idle_state_class // [])[]? | select(.idle_state_class == "saturated")] | length));
      def cooldown_count: ($idle.idle_state_summary.cooldown // ([($idle.idle_state_class // [])[]? | select(.idle_state_class == "cooldown")] | length));
      def waiting_like_count: (dispatching_count + light_queue_count + saturated_count + cooldown_count);
      def peer_stale_count: ($peer.stale_blockers_count // 0);
      def route_ok: (($l70.peer_blocker_routed // "none") | test("^[A-Za-z0-9_.-]+:[0-9]+$"));
      def receipt_required: ($strict_receipt or (($l70.l70_contract_version // "") == "l70-orch-no-punt/v2"));
      def no_work_proven: ((has_ready | not) and (dispatching_count == 0) and (peer_stale_count == 0));
      def no_capacity_proven: (waiting_like_count == 0);
      def allowed_exit:
        if (($l70.same_tick_chain_attempted // null) == "yes") then "same_tick_chain_attempted"
        elif (($l70.idle_reason_class // null) == "hard_blocker" and (($l70.chain_blocked_reason // "") == "hard_blocker")) then "hard_blocker"
        elif (($l70.idle_reason_class // null) == "peer_owned" and (($l70.chain_blocked_reason // "") == "peer_owned") and route_ok) then "peer_owned_routed"
        elif (($l70.idle_reason_class // null) == "no_capacity" and (($l70.chain_blocked_reason // "") == "capacity") and no_capacity_proven) then "no_capacity"
        elif (($l70.idle_reason_class // null) == "no_work" and no_work_proven and ((($require_work_hunt | not) or (($l70.work_hunt_completed // "") == "yes")))) then "no_work"
        elif ((receipt_required | not) and (($l70.receipt_present // false) | not)) then "receipt_absent_grace"
        else null end;
      def fault:
        if (receipt_required and (($l70.receipt_present // false) | not)) then "missing_l70_receipt"
        elif (($l70.idle_reason_class // null) == "peer_owned" and (($l70.chain_blocked_reason // "") == "peer_owned") and (route_ok | not)) then "peer_owned_without_route"
        elif (($l70.idle_reason_class // null) == "no_capacity" and (no_capacity_proven | not)) then "declared_no_capacity_but_idle_panes"
        elif (($l70.idle_reason_class // null) == "no_work" and (no_work_proven | not)) then "declared_no_work_but_ready_work_or_peer_blocker"
        elif (($l70.idle_reason_class // null) == "no_work" and $require_work_hunt and (($l70.work_hunt_completed // "") != "yes")) then "declared_no_work_without_work_hunt"
        elif (dispatching_count > 0 and has_ready) then "idle_with_capacity_AND_ready_work"
        elif (receipt_required and (($l70.same_tick_chain_attempted // null) == "no") and (($l70.idle_reason_class // null) == null)) then "missing_idle_reason_class"
        else null end;
      allowed_exit as $allowed
      | fault as $fault
      | {
          schema_version:$version,
          status:(if $fault == null then "pass" else "fail" end),
          decision:(if $fault == null then "allow" else "block" end),
          reason:($allowed // $fault // "allow"),
          repo:$repo,
          session:$session,
          receipt:(if $receipt == "" then null else $receipt end),
          dispatch_log:$dispatch_log,
          strict_receipt:$strict_receipt,
          require_work_hunt:$require_work_hunt,
          l70:$l70,
          probes:{
            idle_state_probe:(if $idle_state_probe == "" then null else $idle_state_probe end),
            idle_state:$idle,
            peer_blocker_watch:(if $peer_blocker_watch == "" then null else $peer_blocker_watch end),
            peer_blocker:$peer,
            ready_work_count:$ready_count,
            memory_ready_count:$memory_count,
            total_ready_signal_count:($ready_count + $memory_count),
            dispatching_idle_pane_count:dispatching_count,
            waiting_like_pane_count:waiting_like_count,
            stale_peer_blocker_count:peer_stale_count
          },
          false_block_mitigations:[
            "graceful_allow_when_no_l70_v2_receipt_and_not_strict",
            "use_L85_idle_state_probe_as_primary_capacity_truth",
            "no_work_requires_ready_count_zero_memory_hits_zero_peer_blockers_zero",
            "no_capacity_requires_no_waiting_like_idle_state_rows",
            "peer_owned_requires_session_pane_route",
            "stop_hook_active_allows_to_avoid_recursion",
            "probe_missing_or_invalid_becomes_warn_not_block_unless_concrete_fault_exists"
          ],
          recommended_fuckup_row:(if $fault == null then null else {
            class:$fault,
            severity:(if $fault == "idle_with_capacity_AND_ready_work" then "high" else "medium" end),
            command:"flywheel-loop fuckup log --class " + $fault + " --severity high --what-happened \"tick close attempted while idle capacity and ready work existed\" --json"
          } end)
        }
    '
}

emit_hook_block_json() {
  local reason="$1"
  case "$HOOK_EVENT" in
    PreToolUse)
      jq -cn --arg reason "$reason" '{
        hookSpecificOutput:{
          hookEventName:"PreToolUse",
          permissionDecision:"deny",
          permissionDecisionReason:$reason
        }
      }'
      ;;
    Stop)
      jq -cn --arg reason "$reason" '{decision:"block", reason:$reason}'
      ;;
    *)
      return 1
      ;;
  esac
}

decision_json="$(build_decision)"
decision="$(jq -r '.decision' <<<"$decision_json")"
reason="$(jq -r '.reason' <<<"$decision_json")"

if [[ "$decision" == "block" ]]; then
  message="$(
    jq -r '
      "IDLE PANE MECHANICAL GATE: " + .reason + "\n"
      + "session=" + .session + " repo=" + .repo + "\n"
      + "dispatching_idle_pane_count=" + (.probes.dispatching_idle_pane_count|tostring)
      + " ready_work_count=" + (.probes.ready_work_count|tostring)
      + " memory_ready_count=" + (.probes.memory_ready_count|tostring)
      + " stale_peer_blocker_count=" + (.probes.stale_peer_blocker_count|tostring) + "\n"
      + "Required: dispatch ready work, chain same-tick action, or emit a legitimate idle_reason_class with proof."
    ' <<<"$decision_json"
  )"
  if [[ "$JSON_OUT" -eq 1 ]]; then
    printf '%s\n' "$decision_json"
  elif emit_hook_block_json "$message"; then
    :
  fi
  printf '%s\n' "$message" >&2
  exit 2
fi

if [[ "$JSON_OUT" -eq 1 ]]; then
  printf '%s\n' "$decision_json"
fi

exit 0

# Meta-Learning Cross-References (2026-05-19)
# Batch-16 comment backfill; citations are documentation-only and do not alter runtime behavior.
# Related: `/Users/josh/Developer/skillos/.flywheel/doctrine/meta-learnings/MP-20-cross-orch-handoff.md`
# Related: `/Users/josh/Developer/skillos/.flywheel/doctrine/meta-learnings/MP-63-phase-tick-bounded-action.md`
