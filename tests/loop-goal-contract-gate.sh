#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd -P)"
GATE="$ROOT/.flywheel/scripts/loop-goal-contract-gate.sh"
TICK="$ROOT/.flywheel/flywheel-loop-tick"
PACKET="$ROOT/.flywheel/scripts/build-dispatch-packet.sh"
METRICS="$ROOT/.flywheel/scripts/dispatch-mode-metrics.py"
TMP="$(mktemp -d "${TMPDIR:-/tmp}/loop-goal-contract-gate.XXXXXX")"
trap 'rm -rf "$TMP"' EXIT

pass_count=0
fail_count=0
pass() { pass_count=$((pass_count + 1)); printf 'PASS %s\n' "$1"; }
fail() { fail_count=$((fail_count + 1)); printf 'FAIL %s\n' "$1" >&2; }

make_tick_repo() {
  local repo="$TMP/tick-repo"
  rm -rf "$repo"
  mkdir -p "$repo/.flywheel/scripts" "$repo/.flywheel/runtime/flywheel-loop" \
    "$repo/.flywheel/prompts" "$repo/.flywheel/validation-schema/v1" \
    "$repo/.flywheel/tick-contract-registry/v1/fixtures" "$repo/.beads"
  printf 'status: ready\n' >"$repo/.flywheel/MISSION.md"
  printf 'status: ready\n' >"$repo/.flywheel/GOAL.md"
  printf 'status: ready\n' >"$repo/.flywheel/STATE.md"
  : >"$repo/.beads/issues.jsonl"
  jq -nc '{phase:"DISPATCH"}' >"$repo/.flywheel/next_tick_override.json"
  cp "$ROOT/.flywheel/scripts/validate-callback.py" "$repo/.flywheel/scripts/validate-callback.py"
  cp "$ROOT/.flywheel/scripts/loop-goal-contract-gate.sh" "$repo/.flywheel/scripts/loop-goal-contract-gate.sh"
  cp "$ROOT/.flywheel/validation-schema/v1/schema.json" "$repo/.flywheel/validation-schema/v1/schema.json"
  cp "$ROOT/.flywheel/validation-schema/v1/parse.sh" "$repo/.flywheel/validation-schema/v1/parse.sh"
  cp "$ROOT/.flywheel/tick-contract-registry/v1/registry.json" "$repo/.flywheel/tick-contract-registry/v1/registry.json"
  chmod +x "$repo/.flywheel/scripts/loop-goal-contract-gate.sh" "$repo/.flywheel/validation-schema/v1/parse.sh"
  for script in josh-request-tick-promote.sh doctor-signal-bead-promotion.sh doctrine-ladder-promote.sh jeff-issue-response-poll.sh inbox-check-tick-step.sh; do
    printf '#!/usr/bin/env bash\nprintf '"'"'%%s\\n'"'"' '"'"'{"action":"test"}'"'"'\n' >"$repo/.flywheel/scripts/$script"
    chmod +x "$repo/.flywheel/scripts/$script"
  done
  cat >"$repo/.flywheel/scripts/leverage-ceiling-probe.sh" <<'SH'
#!/usr/bin/env bash
set -euo pipefail
jq -nc '{status:"ok",leverage_ceiling_score:800,binding_constraint:"fixture",warnings:[]}'
SH
  chmod +x "$repo/.flywheel/scripts/leverage-ceiling-probe.sh"
  cat >"$repo/.flywheel/scripts/frozen-pane-detector.sh" <<'SH'
#!/usr/bin/env bash
set -euo pipefail
jq -nc '{schema_version:"frozen-pane-detector.v2",success:true,source_health:{status:"healthy"},frozen_panes_detected:0,unknown_panes_detected:0,template_stub_prompt_count:0,queued_not_submitted_count:0,respawn_suppressed_count:0,recovery_suppressed_count:0,l60_signals_present:{no_silent_darkness:true,live_truth_delta:true,unknown_separated:true,recovery_budget:true,recovery_lease:true},soft_violations:[],durable_receipts:[],silent_dark_minutes:0,blackout_detection_latency_p95:0,false_recovery_count:0,unknown_auto_recovery_count:0}'
SH
  chmod +x "$repo/.flywheel/scripts/frozen-pane-detector.sh"
  cat >"$repo/.flywheel/scripts/dispatch-capacity-gate.sh" <<'SH'
#!/usr/bin/env bash
set -euo pipefail
jq -nc '{action:"snapshot",idle_count:1,work_summary:{pending_tasks:1},idle_capacity_source:"fixture"}'
SH
  chmod +x "$repo/.flywheel/scripts/dispatch-capacity-gate.sh"
  printf '%s\n' "$repo"
}

make_tick_ntm() {
  local ntm="$TMP/tick-ntm"
  cat >"$ntm" <<'SH'
#!/usr/bin/env bash
set -euo pipefail
printf '%s\n' "$*" >>"${TICK_NTM_CALLS:?}"
if [[ "${1:-}" == "copy" ]]; then
  out=""
  while [[ $# -gt 0 ]]; do
    if [[ "$1" == "--output" ]]; then out="$2"; shift 2; else shift; fi
  done
  : >"$out"
  exit 0
fi
if [[ "${1:-}" == "send" ]]; then
  jq -nc '{ok:true,transport:"fixture"}'
  exit 0
fi
jq -nc '{ok:true}'
SH
  chmod +x "$ntm"
  printf '%s\n' "$ntm"
}

log="$TMP/dispatch-log.jsonl"
missing_out="$TMP/missing.json"
"$GATE" validate --repo "$TMP" --decision DISPATCH_BEAD --task-id tick-missing --dispatch-log "$log" --json >"$missing_out"
jq -e '.status == "no_dispatch" and .reason == "missing_goal_contract" and (.missing_fields | index("contract_path"))' "$missing_out" >/dev/null \
  && jq -e '.event == "NO_DISPATCH" and .event_key == "NO_DISPATCH:missing-contract" and .status == "missing_goal_contract" and .mode == "loop" and .tick_id == "tick-missing" and has("goal_id") and has("sprint_id")' "$log" >/dev/null \
  && ! jq -e 'select(.event == "ntm_dispatch_sent")' "$log" >/dev/null \
  && pass "missing contract refuses dispatch" || fail "missing contract refuses dispatch"

tick_repo="$(make_tick_repo)"
tick_ntm="$(make_tick_ntm)"
tick_calls="$TMP/tick-ntm.calls"
: >"$tick_calls"
tick_log="$tick_repo/.flywheel/dispatch-log.jsonl"
tick_last="$tick_repo/.flywheel/runtime/flywheel-loop/last_run.json"
set +e
TICK_NTM_CALLS="$tick_calls" \
REPO="$tick_repo" SESSION="flywheel" TARGET_PANE="1" \
STATE_DIR="$tick_repo/.flywheel/runtime/flywheel-loop" \
PROMPT_DIR="$tick_repo/.flywheel/prompts" LOG="$tick_log" NTM="$tick_ntm" \
FLYWHEEL_LOOP_TICK_DRY_RUN=1 FLYWHEEL_GOAL_CONTRACT= \
  bash "$TICK" >"$TMP/tick.out" 2>"$TMP/tick.err"
tick_rc=$?
set -e
if [[ "$tick_rc" -eq 0 ]] \
  && jq -e '.dispatch_status == "no_dispatch_missing_contract" and .phase == "DISPATCH" and .loop_goal_contract_gate.status == "no_dispatch"' "$tick_last" >/dev/null \
  && jq -e 'select(.event == "NO_DISPATCH" and .event_key == "NO_DISPATCH:missing-contract" and .status == "missing_goal_contract" and .reason == "missing_goal_contract")' "$tick_log" >/dev/null \
  && ! jq -e 'select(.event == "ntm_dispatch_sent")' "$tick_log" >/dev/null \
  && ! grep -q '^send ' "$tick_calls"; then
  pass "synthetic tick blocks contract-less dispatch"
else
  fail "synthetic tick blocks contract-less dispatch"
  printf 'tick_rc=%s\n' "$tick_rc" >&2
  cat "$TMP/tick.out" >&2 || true
  cat "$TMP/tick.err" >&2 || true
  jq . "$tick_last" >&2 || true
  cat "$tick_log" >&2 || true
  cat "$tick_calls" >&2 || true
fi

contract="$TMP/contract.json"
jq -nc '{
  goal_id:"goal-fixture",
  sprint_id:"sprint-fixture",
  hard_bars:["bar1"],
  forbid_clauses:["no stale state fallback"],
  target_beads:["flywheel-fixture"],
  out_of_scope_lanes:["Track 1","Track 2"],
  callback_envelope:{required:["did","gaps","br_close_executed"]},
  stop_conditions:["missing contract"]
}' >"$contract"

valid_out="$TMP/valid.json"
"$GATE" validate --repo "$TMP" --decision DISPATCH_BEAD --task-id tick-valid --contract "$contract" --dispatch-log "$log" --json >"$valid_out"
jq -e '.status == "dispatch_allowed" and .contract.goal_id == "goal-fixture" and .contract.sprint_id == "sprint-fixture" and .mode == "loop"' "$valid_out" >/dev/null \
  && pass "valid contract allows dispatch" || fail "valid contract allows dispatch"

cat >"$TMP/br" <<'SH'
#!/usr/bin/env bash
set -euo pipefail
case "${1:-}" in
  show)
    jq -nc '[{id:"flywheel-fixture",title:"Fixture dispatch",description:"Acceptance: prove contract block",priority:1}]'
    ;;
  dep)
    jq -nc '{}'
    ;;
  *)
    jq -nc '{}'
    ;;
esac
SH
chmod +x "$TMP/br"

cat >"$TMP/ntm" <<'SH'
#!/usr/bin/env bash
set -euo pipefail
case "${1:-} ${2:-}" in
  "context build")
    jq -nc '{id:"ctx-fixture",repo_rev:"fixture-rev"}'
    ;;
  "template show")
    jq -nc '{name:"marching_orders",source:"fixture"}'
    ;;
  *)
    jq -nc '{}'
    ;;
esac
SH
chmod +x "$TMP/ntm"

topology="$TMP/topology.jsonl"
jq -nc '{session:"fixture",orchestrator_pane:1,callback_pane:1,worker_panes:[2],effective_at:"2026-05-18T00:00:00Z"}' >"$topology"

PATH="$TMP:$PATH" \
FLYWHEEL_NTM_BIN="$TMP/ntm" \
FLYWHEEL_TOPOLOGY="$topology" \
  "$PACKET" --bead-id flywheel-fixture --target-pane 2 --target-session fixture --task-id tick-valid --goal-contract "$contract" --output-dir "$TMP" --apply --json >"$TMP/packet.json"

packet_path="$(jq -r '.packet_path' "$TMP/packet.json")"
jq -e '.fields_resolved.goal_contract.goal_id == "goal-fixture" and .fields_resolved.goal_contract.sprint_id == "sprint-fixture" and (.validation_blocks_present | index("LOOP GOAL CONTRACT BLOCK"))' "$TMP/packet.json" >/dev/null \
  && grep -q '^## LOOP GOAL CONTRACT BLOCK' "$packet_path" \
  && grep -q '"goal_id":"goal-fixture"' "$packet_path" \
  && grep -q '"sprint_id":"sprint-fixture"' "$packet_path" \
  && pass "dispatch packet carries contract verbatim" || fail "dispatch packet carries contract verbatim"

metrics_log="$TMP/contract-bearing-loop.jsonl"
jq -nc --argjson contract "$(cat "$contract")" '{ts:"2026-05-18T00:00:00Z",event:"dispatch_sent",task_id:"tick-valid",origin_task_id:"tick-valid",mode:"loop",tick_id:"tick-valid",goal_id:"goal-fixture",sprint_id:"sprint-fixture",goal_contract:$contract}' >"$metrics_log"
jq -nc '{ts:"2026-05-18T00:10:00Z",event:"worker_callback",task_id:"tick-valid",status:"DONE"}' >>"$metrics_log"
"$METRICS" --log "$metrics_log" --json >"$TMP/metrics.json"
jq -e '.modes.loop.pulse_count == 1 and .modes.loop.productive_callback_count == 1 and .modes.loop.productive_callback_per_pulse == 1' "$TMP/metrics.json" >/dev/null \
  && pass "contract-bearing loop callbacks are attributable" || fail "contract-bearing loop callbacks are attributable"

printf 'Summary: %d passed, %d failed\n' "$pass_count" "$fail_count"
[[ "$fail_count" -eq 0 ]]
