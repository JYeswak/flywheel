#!/usr/bin/env bash
# w5-founder-dispose-cadence-tick.sh — Daily W5 cadence (v5 forever-goal).
# Fires architecture-health-rollup.sh, writes weekly report, appends cadence row.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)"
REPO_ROOT="${W5_REPO:-$(cd "$SCRIPT_DIR/../.." && pwd -P)}"
LEDGER="${W5_CADENCE_LEDGER:-$REPO_ROOT/.flywheel/state/founder-dispose-cadence-ledger.jsonl}"
ROLLUP="$REPO_ROOT/.flywheel/scripts/architecture-health-rollup.sh"
REPORTS="$REPO_ROOT/.flywheel/reports"

case "${1:-tick}" in
  --info) echo '{"name":"w5-founder-dispose-cadence-tick","schema_version":"flywheel.w5_cadence.v0","wave":"W5","cadence":"daily"}'; exit 0 ;;
  --schema) echo '{"row":"{ts,wave,founder_dispose_pct,rework_ratio,health_status,report_path,arch_bead_filed}"}'; exit 0 ;;
  --examples) echo '{"examples":[{"command":".flywheel/scripts/w5-founder-dispose-cadence-tick.sh tick"}]}'; exit 0 ;;
  health|doctor)
    [[ -x "$ROLLUP" ]] && status=ok || status=fail
    printf '{"command":"%s","status":"%s","rollup":"%s"}\n' "${1}" "$status" "$ROLLUP"
    [[ "$status" == ok ]] && exit 0 || exit 1 ;;
esac

mkdir -p "$(dirname "$LEDGER")" "$REPORTS"
TS="$(date -u +%Y-%m-%dT%H:%M:%SZ)"
DATE="$(date -u +%Y-%m-%d)"

out="$("$ROLLUP" --period 7d --json 2>/dev/null || echo '{}')"
fdp="$(echo "$out" | jq -r '.fleet_metrics.founder_dispose_pct // null')"
rwk="$(echo "$out" | jq -r '.fleet_metrics.rework_ratio // null')"
hs="$(echo "$out" | jq -r '.architecture_health_status // "unknown"')"

REPORT="$REPORTS/founder-dispose-pct-$DATE.md"
if [[ ! -f "$REPORT" ]]; then
  {
    echo "# founder_dispose_pct daily — $DATE"
    echo ""
    echo "founder_dispose_pct=$fdp  rework_ratio=$rwk  health=$hs"
    echo ""
    echo "Source: .flywheel/scripts/architecture-health-rollup.sh --period 7d"
    echo "Cadence ledger: $LEDGER"
  } >"$REPORT"
fi

row="$(jq -nc --arg ts "$TS" --arg fdp "$fdp" --arg rwk "$rwk" --arg hs "$hs" --arg rp "$REPORT" \
  '{ts:$ts,wave:"W5",founder_dispose_pct:$fdp,rework_ratio:$rwk,health_status:$hs,report_path:$rp,arch_bead_filed:false}')"
echo "$row" >>"$LEDGER"
echo "$row"
