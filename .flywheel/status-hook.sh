#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd -P)"
POLICY="$ROOT/.flywheel/CI-POLICY.json"

if [[ ! -s "$POLICY" ]]; then
  printf 'CI spend: (no data)\n'
  exit 0
fi

jq -r '
  .spend_dashboard as $d
  | "CI spend: $\($d.current_month_estimate_usd) est this month, \($d.on_target_pct)%-on-target (\($d.target_label); source=\($d.source))"
' "$POLICY"
