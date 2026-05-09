#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../.." && pwd -P)"
cd "$ROOT"

.flywheel/scripts/jeff-shadow-socraticode.sh status --json \
  | jq -e '
      .success == true
      and .repo_count == 8
      and .indexed_count == 8
      and (.dashboard_line | startswith("jeff-shadow: 8/8 repos indexed"))
      and all(.repos[]; .exists == true and .index_status == "indexed")
    ' >/dev/null

printf 'OK_jeff_shadow_indexed_8_of_8\n'
