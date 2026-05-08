#!/usr/bin/env bash
set -euo pipefail

TMP="$(mktemp -d -t tick-pws.XXXXXX)"
trap 'rm -r "$TMP"' EXIT
source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)/tick_pws_common.sh"

tick_pws_run "$TMP" "cod" "idle" || { cat "$TMP/tick.err" >&2; exit 1; }
receipt="$TMP/repo/.flywheel/runtime/flywheel-loop/last_run.json"

jq -e '
  .dispatch_capacity.panes[0].gate.verdict == "blocked"
  and .dispatch_capacity.panes[0].gate.reason == "pane_work_signal_working"
  and (.pane_work_signal_soft_violations[] | select(.class == "pane_work_signal_disagrees_with_ntm_health" and .pane == 2))
  and (.pane_work_signal_disagreements[] | select(.pane == 2 and .truth_state == "working"))
' "$receipt" >/dev/null

printf 'PASS tick PWS canonical for Codex capacity\n'
