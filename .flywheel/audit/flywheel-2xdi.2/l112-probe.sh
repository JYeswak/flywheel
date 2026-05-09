#!/usr/bin/env bash
set -euo pipefail

bash -n /Users/josh/.claude/skills/.flywheel/lib/common.sh \
  /Users/josh/.claude/skills/.flywheel/bin/flywheel-loop

bash -lc '
  source /Users/josh/.claude/skills/.flywheel/lib/common.sh
  test "$(fw_classify_source x:@zeststream)" = "x_user|zeststream"
  test "$(fw_normalize_url x_search flywheel)" = "x:search:flywheel"
'

rg -n 'source "\$LIB/common\.sh"|source "\$FLYWHEEL_HOME/lib/common\.sh"' \
  /Users/josh/.claude/skills/.flywheel/bin/flywheel-loop \
  /Users/josh/.claude/skills/.flywheel/bin/flywheel >/dev/null

printf 'OK_common_sh_load_bearing\n'
