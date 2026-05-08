#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd -P)"
PWS_DOCTOR_LIB="$HOME/.claude/skills/.flywheel/lib/misc.sh"

pass_count=0
fail_count=0

pass() { printf 'PASS %s\n' "$1"; pass_count=$((pass_count + 1)); }
fail() { printf 'FAIL %s\n' "$1" >&2; fail_count=$((fail_count + 1)); }

assert_jq() {
  local file="$1" filter="$2" label="$3"
  if jq -e "$filter" "$file" >/dev/null; then
    pass "$label"
  else
    fail "$label"
    jq . "$file" >&2 || true
  fi
}

doctor_pws_finish() {
  printf 'SUMMARY pass=%d fail=%d\n' "$pass_count" "$fail_count"
  [[ "$fail_count" -eq 0 && "$pass_count" -ge "${1:-1}" ]]
}

doctor_pws_append_false_idle() {
  local file="$1" ts="$2" pane="${3:-2}"
  jq -nc \
    --arg ts "$ts" \
    --argjson pane "$pane" \
    '{
      ts:$ts,
      pane_work_signal_sampled:true,
      pane_work_signal_disabled:false,
      pane_work_signal_disabled_reason:null,
      idle_capacity_source:"pane_work_signal_for_codex",
      pane_work_signal_by_pane:{
        ($pane|tostring):{
          agent_kind:"codex",
          truth_state:"working",
          truth_source:"pane_work_signal",
          ntm_activity:"idle",
          ntm_status:"ok",
          capacity:false
        }
      },
      pane_work_signal_disagreements:[{
        pane:$pane,
        ntm_activity:"idle",
        ntm_status:"ok",
        truth_state:"working"
      }],
      pane_work_signal_soft_violations:[{
        class:"pane_work_signal_disagrees_with_ntm_health",
        pane:$pane,
        ntm_activity:"idle",
        ntm_status:"ok",
        truth_state:"working",
        mode:"SOFT"
      }]
    }' >>"$file"
}

doctor_pws_run() {
  local receipts="$1" out="$2" repo="${3:-$ROOT}"
  FLYWHEEL_PANE_WORK_SIGNAL_RECEIPTS_FILE="$receipts" \
  FLYWHEEL_PANE_WORK_SIGNAL_REPO="$repo" \
    bash -lc 'source "$HOME/.claude/skills/.flywheel/lib/misc.sh"; doctor_check_pane_work_signal' >"$out"
}
