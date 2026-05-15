#!/usr/bin/env bash
set -euo pipefail

TMP="$(mktemp -d -t tick-ntm-activity.XXXXXX)"
trap 'rm -r "$TMP"' EXIT
# shellcheck source=tests/tick_pws_common.sh
source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)/tick_pws_common.sh"

tick_pws_run "$TMP" "cc" "STALLED" || { cat "$TMP/tick.err" >&2; exit 1; }
receipt="$TMP/repo/.flywheel/runtime/flywheel-loop/last_run.json"

jq -e '
  .ntm_activity.schema_version == "flywheel-tick-ntm-activity/v1"
  and .sessions_seen == ["flywheel"]
  and .sessions_error == []
  and (.stalled_panes | index(2))
  and .respawns_attempted == 0
  and .health_daemon_fresh == true
' "$receipt" >/dev/null

printf 'PASS tick NTM activity receipt fields\n'
