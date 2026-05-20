#!/usr/bin/env bash
set -euo pipefail

LEDGER="${DICKLESWORTHSTONE_DRIFT_LEDGER:-$HOME/.local/state/flywheel/dicklesworthstone-version-drift.jsonl}"
FOUNDER_EVENTS="${FOUNDER_PAGE_EVENTS:-$HOME/.local/state/flywheel/founder-page-events.jsonl}"
REPO="${SKILLOS_REPO:-/Users/josh/Developer/skillos}"

now_iso() {
  date -u '+%Y-%m-%dT%H:%M:%SZ'
}

latest_rows() {
  jq -s -c '
    map(select(.tool != null))
    | sort_by(.ts)
    | group_by(.tool)
    | map(last)
  ' "$LEDGER"
}

main() {
  if [[ ! -s "$LEDGER" ]]; then
    jq -c -n --arg ts "$(now_iso)" --arg ledger "$LEDGER" \
      '{ts:$ts,status:"no_ledger",ledger:$ledger,escalated:false}'
    return 0
  fi

  local rows worst_days worst_missed stale_count
  rows="$(latest_rows)"
  worst_days="$(jq '[.[].days_stale // 0] | max // 0' <<<"$rows")"
  worst_missed="$(jq '[.[].releases_missed // 0] | max // 0' <<<"$rows")"
  stale_count="$(jq '[.[] | select((.days_stale // 0) >= 1 or (.releases_missed // 0) >= 2)] | length' <<<"$rows")"

  if (( stale_count > 0 )); then
    mkdir -p "$(dirname "$FOUNDER_EVENTS")"
    jq -c -n \
      --arg schema_version "skillos.founder_page_event.v1" \
      --arg ts "$(now_iso)" \
      --arg repo "$REPO" \
      --arg ledger "$LEDGER" \
      --arg summary "Dicklesworthstone upstream stack drift detected" \
      --argjson worst_days "$worst_days" \
      --argjson worst_missed "$worst_missed" \
      --argjson stale_tools "$(jq '[.[] | select((.days_stale // 0) >= 1 or (.releases_missed // 0) >= 2) | .tool]' <<<"$rows")" \
      '{
        schema_version:$schema_version,
        ts:$ts,
        class:"upstream.dicklesworthstone_version_drift",
        severity:(if $worst_missed >= 3 then "high" else "medium" end),
        repo:$repo,
        source:"dicklesworthstone-watchdog",
        summary:$summary,
        ledger:$ledger,
        worst_days_stale:$worst_days,
        worst_releases_missed:$worst_missed,
        stale_tools:$stale_tools
      }' >> "$FOUNDER_EVENTS"
  fi

  jq -c -n \
    --arg ts "$(now_iso)" \
    --arg ledger "$LEDGER" \
    --arg founder_events "$FOUNDER_EVENTS" \
    --argjson worst_days "$worst_days" \
    --argjson worst_missed "$worst_missed" \
    --argjson stale_count "$stale_count" \
    '{ts:$ts,status:"ok",ledger:$ledger,worst_days_stale:$worst_days,worst_releases_missed:$worst_missed,stale_count:$stale_count,escalated:($stale_count > 0),founder_events:$founder_events}'
}

main "$@"
