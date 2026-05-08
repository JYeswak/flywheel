#!/usr/bin/env bash
set -euo pipefail

TMP="$(mktemp -d -t tick-pws.XXXXXX)"
trap 'rm -r "$TMP"' EXIT
source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)/tick_pws_common.sh"

tick_pws_run "$TMP" "cod" "idle" "FLYWHEEL_PANE_WORK_SIGNAL_DISABLE=1" || { cat "$TMP/tick.err" >&2; exit 1; }
receipt="$TMP/repo/.flywheel/runtime/flywheel-loop/last_run.json"

jq -e '
  .pane_work_signal_sampled == false
  and .pane_work_signal_disabled == true
  and .pane_work_signal_disabled_reason == "pws_disabled_via_env"
  and .idle_capacity_source == "ntm_health"
  and .dispatch_capacity.panes[0].gate.verdict == "available"
' "$receipt" >/dev/null

printf 'PASS tick PWS disabled via env\n'
