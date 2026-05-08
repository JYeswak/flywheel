#!/usr/bin/env bash
set -euo pipefail

TMP="$(mktemp -d -t tick-pws.XXXXXX)"
trap 'rm -r "$TMP"' EXIT
source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)/tick_pws_common.sh"

tick_pws_run "$TMP" "cod" "idle" || { cat "$TMP/tick.err" >&2; exit 1; }
receipt="$TMP/repo/.flywheel/runtime/flywheel-loop/last_run.json"

jq -e '
  .pane_work_signal_sampled == true
  and (.pane_work_signal_by_pane["2"].truth_state == "working")
  and (.pane_work_signal_disagreements | length) == 1
  and .idle_capacity_source == "pane_work_signal_for_codex"
' "$receipt" >/dev/null

printf 'PASS tick receipt PWS fields\n'
