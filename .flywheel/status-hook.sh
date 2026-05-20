#!/usr/bin/env bash
set -euo pipefail
# Tolerate SIGPIPE — callers may pipe through grep -q which closes pipe early
trap '' PIPE

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

storage_line="$("$ROOT/.flywheel/scripts/storage-health-probe.sh" --json 2>/dev/null | jq -r '.dashboard_line // empty' 2>/dev/null || true)"
# Tolerate EPIPE — consumers like `grep -q` close the pipe after the first match.
# Without `|| true`, the EPIPE on this second write would propagate as exit failure under pipefail.
if [[ -n "$storage_line" ]]; then
  printf '%s\n' "$storage_line" 2>/dev/null || true
else
  printf 'Storage: (no data)\n' 2>/dev/null || true
fi
