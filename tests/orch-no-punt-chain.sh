#!/usr/bin/env bash
set -euo pipefail

ROOT="/Users/josh/Developer/flywheel"
PROBE="$ROOT/.flywheel/scripts/ticks-punted-probe.sh"
DRIVER="$ROOT/.flywheel/flywheel-loop-tick"
LOOP="$HOME/.claude/skills/.flywheel/bin/flywheel-loop"

TMP="$(mktemp -d "${TMPDIR:-/tmp}/orch-no-punt-chain.XXXXXX")"
trap 'rm -rf "$TMP"' EXIT

LOG="$TMP/dispatch-log.jsonl"
printf '{"event":"l70_chain_decision","chain_required":true,"chained":true}\n' >"$LOG"
printf '{"event":"l70_chain_decision","chain_required":true,"chained":false,"chain_blocked_reason":"capacity_exhausted"}\n' >>"$LOG"
printf '{"event":"l70_chain_decision","chain_required":true,"chained":false}\n' >>"$LOG"

probe_json="$("$PROBE" --log "$LOG" --json)"
if [[ "$(jq -r '.ticks_punted_count' <<<"$probe_json")" != "1" ]]; then
  printf 'FAIL: expected ticks_punted_count=1\n%s\n' "$probe_json" >&2
  exit 1
fi
if [[ "$(jq -r '.malformed_row_count // 0' <<<"$probe_json")" != "0" ]]; then
  printf 'FAIL: expected clean probe malformed_row_count=0\n%s\n' "$probe_json" >&2
  exit 1
fi

MIXED_LOG="$TMP/mixed-dispatch-log.jsonl"
printf 'not-json historical row\n' >"$MIXED_LOG"
printf '{"event":"l70_chain_decision","chain_required":true,"chained":false}\n' >>"$MIXED_LOG"
mixed_probe_json="$("$PROBE" --log "$MIXED_LOG" --json)"
if [[ "$(jq -r '.ticks_punted_count' <<<"$mixed_probe_json")" != "1" || "$(jq -r '.malformed_row_count' <<<"$mixed_probe_json")" != "1" || "$(jq -r '.malformed_rows[0].line' <<<"$mixed_probe_json")" != "1" ]]; then
  printf 'FAIL: expected mixed malformed dispatch log to succeed with line count\n%s\n' "$mixed_probe_json" >&2
  exit 1
fi

BAD_LOG="$TMP/bad-dispatch-log.jsonl"
printf 'not-json\nalso-not-json\n' >"$BAD_LOG"
set +e
bad_probe_json="$("$PROBE" --log "$BAD_LOG" --json)"
bad_probe_rc=$?
unreadable_probe_json="$("$PROBE" --log "$TMP" --json)"
unreadable_probe_rc=$?
set -e
if [[ "$bad_probe_rc" -eq 0 || "$(jq -r '.status' <<<"$bad_probe_json")" != "error" ]]; then
  printf 'FAIL: expected all-unreadable dispatch log to fail\n%s\n' "$bad_probe_json" >&2
  exit 1
fi
if [[ "$unreadable_probe_rc" -eq 0 || "$(jq -r '.warning' <<<"$unreadable_probe_json")" != "dispatch_log_unreadable" ]]; then
  printf 'FAIL: expected unreadable dispatch log path to fail\n%s\n' "$unreadable_probe_json" >&2
  exit 1
fi

REPO="$TMP/repo"
mkdir -p "$REPO/.flywheel/scripts" "$REPO/.flywheel/plans" "$REPO/.beads"
git -C "$REPO" init -q
for f in MISSION.md GOAL.md STATE.md; do
  printf '# %s\n\nstatus: ready\n' "$f" >"$REPO/.flywheel/$f"
done
printf '# plan\n' >"$REPO/.flywheel/plans/00-PLAN.md"
printf '' >"$REPO/.beads/issues.jsonl"

FLYWHEEL_LOOP_TICK_DRY_RUN=1 \
REPO="$REPO" \
SESSION="synthetic" \
TARGET_PANE=1 \
STATE_DIR="$REPO/.flywheel/runtime/flywheel-loop" \
PROMPT_DIR="$REPO/.flywheel/prompts" \
LOG="$REPO/.flywheel/dispatch-log.jsonl" \
FLYWHEEL_FUCKUP_LOG="$TMP/fuckups.jsonl" \
"$DRIVER" >/dev/null

decision="$(jq -s '[.[] | select(.event=="l70_chain_decision")] | .[-1]' "$REPO/.flywheel/dispatch-log.jsonl")"
if [[ "$(jq -r '.source' <<<"$decision")" != "dispatch_no_ready_plan_artifacts" || "$(jq -r '.to_phase' <<<"$decision")" != "BEADS" || "$(jq -r '.chained' <<<"$decision")" != "true" ]]; then
  printf 'FAIL: expected DISPATCH->BEADS chain decision\n%s\n' "$decision" >&2
  exit 1
fi
prompt="$(jq -r '.prompt_file' "$REPO/.flywheel/runtime/flywheel-loop/last_run.json")"
if ! grep -q 'chain_if_capacity' "$prompt"; then
  printf 'FAIL: prompt missing chain_if_capacity block\n' >&2
  exit 1
fi
if ! grep -q 'chain_blocked_reason=<reason|none>' "$prompt"; then
  printf 'FAIL: callback envelope missing chain_blocked_reason\n' >&2
  exit 1
fi

printf '{"event":"l70_chain_decision","chain_required":true,"chained":false}\n' >"$REPO/.flywheel/dispatch-log.jsonl"
doctor_json="$("$LOOP" doctor --repo "$REPO" --json 2>/dev/null || true)"
if [[ "$(jq -r '.ticks_punted_count // 0' <<<"$doctor_json")" != "1" ]]; then
  printf 'FAIL: doctor missing ticks_punted_count=1\n%s\n' "$doctor_json" >&2
  exit 1
fi
if [[ "$(jq -r '[.errors[]? | select(.code=="ticks_punted_count")] | length' <<<"$doctor_json")" != "1" ]]; then
  printf 'FAIL: doctor missing ticks_punted_count error\n%s\n' "$doctor_json" >&2
  exit 1
fi

printf 'PASS: L70 no-punt chain probe and driver fixtures passed\n'
