#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../.." && pwd -P)"
cd "$ROOT"

bash tests/jeff-shadow-socraticode.sh >/dev/null

.flywheel/scripts/jeff-shadow-socraticode.sh status --json \
  | jq -e '.repo_count == 8 and .indexed_count == 8 and (.dashboard_line | startswith("jeff-shadow: 8/8 repos indexed"))' >/dev/null

rg -n 'jeff-shadow-socraticode.sh status --json|jeff-shadow:' /Users/josh/.claude/commands/flywheel/status.md >/dev/null

printf 'OK_jeff_shadow_socraticode_indexed\n'
