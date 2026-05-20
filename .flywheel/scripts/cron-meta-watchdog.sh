#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
EMITTER="$ROOT/.flywheel/scripts/cron-heartbeat-emit.sh"
WATCHDOG_LABEL="ai.zeststream.cron-meta-watchdog"
WATCHDOG_PLIST="$ROOT/.flywheel/launchd/ai.zeststream.cron-meta-watchdog.plist"

now_iso() {
  if [[ -n "${CRON_WATCHDOG_NOW:-}" ]]; then
    printf '%s\n' "$CRON_WATCHDOG_NOW"
  else
    date -u +%Y-%m-%dT%H:%M:%SZ
  fi
}

now_epoch() {
  date -j -u -f "%Y-%m-%dT%H:%M:%SZ" "$(now_iso)" +%s
}

default_ledger() {
  printf '%s\n' "${CRON_HEARTBEAT_LEDGER:-$HOME/.local/state/flywheel/cron-heartbeat.jsonl}"
}

default_intervals() {
  printf '%s\n' "${CRON_HEARTBEAT_INTERVALS:-$ROOT/.flywheel/scripts/cron-heartbeat-intervals.json}"
}

default_alerts() {
  printf '%s\n' "${CRON_WATCHDOG_ALERTS:-$HOME/.local/state/flywheel/cron-watchdog-alerts.jsonl}"
}

emit_self_heartbeat() {
  local mode="$1" status="${2:-ok}" runtime_ms="${3:-0}"
  [[ "${CRON_WATCHDOG_NO_SELF_HEARTBEAT:-0}" == "1" ]] && return 0
  [[ -x "$EMITTER" ]] || return 0

  if [[ "$mode" == "entry" ]]; then
    CRON_HEARTBEAT_LEDGER="$(default_ledger)" CRON_HEARTBEAT_NOW="$(now_iso)" \
      "$EMITTER" --entry --label "$WATCHDOG_LABEL" --plist "$WATCHDOG_PLIST" >/dev/null 2>&1 || true
  else
    CRON_HEARTBEAT_LEDGER="$(default_ledger)" CRON_HEARTBEAT_NOW="$(now_iso)" \
      "$EMITTER" --exit "$status" "$runtime_ms" --label "$WATCHDOG_LABEL" --plist "$WATCHDOG_PLIST" >/dev/null 2>&1 || true
  fi
}

usage() {
  cat >&2 <<'EOF'
Usage:
  cron-meta-watchdog.sh [--json]

Environment:
  CRON_HEARTBEAT_LEDGER             Override heartbeat ledger path.
  CRON_HEARTBEAT_INTERVALS          Override intervals JSON path.
  CRON_WATCHDOG_ALERTS              Override alert JSONL path.
  CRON_WATCHDOG_NOW                 Override UTC timestamp for tests.
  CRON_WATCHDOG_NO_SELF_HEARTBEAT=1 Disable watchdog self heartbeat for tests.
EOF
}

main() {
  local format="json"
  while [[ $# -gt 0 ]]; do
    case "$1" in
      --json)
        format="json"
        shift
        ;;
      -h|--help)
        usage
        return 0
        ;;
      *)
        printf 'cron-meta-watchdog: unknown argument: %s\n' "$1" >&2
        usage
        return 2
        ;;
    esac
  done

  local started_ms ledger heartbeat_input intervals alerts now now_sec tmp_result
  started_ms="$(perl -MTime::HiRes=time -e 'printf "%d\n", time()*1000')"
  ledger="$(default_ledger)"
  heartbeat_input="$ledger"
  [[ -f "$heartbeat_input" ]] || heartbeat_input="/dev/null"
  intervals="$(default_intervals)"
  alerts="$(default_alerts)"
  now="$(now_iso)"
  now_sec="$(now_epoch)"

  emit_self_heartbeat entry

  tmp_result="$(mktemp)"
  if ! jq -n \
    --slurpfile interval_docs "$intervals" \
    --rawfile heartbeat_raw "${heartbeat_input}" \
    --arg schema_version "skillos.cron_meta_watchdog.v1" \
    --arg ts "$now" \
    --arg heartbeat_path "$ledger" \
    --arg intervals_path "$intervals" \
    --arg source ".flywheel/scripts/cron-meta-watchdog.sh" \
    --argjson now_sec "$now_sec" '
      def rows:
        $heartbeat_raw
        | split("\n")
        | map(select(length > 0) | try fromjson catch empty);

      def epoch($ts):
        try ($ts | fromdateiso8601) catch null;

      def intervals:
        $interval_docs[0]
        | to_entries
        | map(select(.value | type == "number"));

      def label_of($row): ($row.label // $row.cron_id // "");
      def status_of($row): ($row.run_status // $row.status // "");

      def latest_for($label):
        rows
        | map(select(label_of(.) == $label))
        | sort_by(epoch(.ts) // 0)
        | last;

      def label_status($entry):
        ($entry.key) as $label
        | ($entry.value | floor) as $expected
        | (latest_for($label)) as $latest
        | if $latest == null then
            {
              label: $label,
              expected_interval_sec: $expected,
              threshold_sec: ($expected * 2),
              last_heartbeat_ts: null,
              last_run_status: null,
              staleness_sec: null,
              stale: true,
              reason: "missing_heartbeat"
            }
          else
            (epoch($latest.ts)) as $last_sec
            | (($now_sec - $last_sec) | if . < 0 then 0 else . end | floor) as $staleness
            | (status_of($latest)) as $run_status
            | {
                label: $label,
                expected_interval_sec: $expected,
                threshold_sec: ($expected * 2),
                last_heartbeat_ts: $latest.ts,
                last_run_status: $run_status,
                staleness_sec: $staleness,
                stale: ($staleness > ($expected * 2)),
                reason: (
                  if $staleness <= ($expected * 2) then "fresh"
                  elif $run_status == "started" then "missing_exit"
                  else "stale_heartbeat"
                  end
                )
              }
          end;

      (intervals | map(label_status(.))) as $labels
      | ($labels | map(select(.stale))) as $stale
      | {
          schema_version: $schema_version,
          ts: $ts,
          heartbeat_path: $heartbeat_path,
          intervals_path: $intervals_path,
          stale_count: ($stale | length),
          labels: $labels,
          stale_labels: ($stale | map(.label)),
          escalations: (
            $stale
            | map({
                channel: "cron-watchdog-alerts-jsonl",
                severity: (if (.reason == "missing_exit" or .reason == "missing_heartbeat") then "high" else "normal" end),
                label: .label,
                reason: .reason,
                alert_path: "'"$alerts"'"
              })
          ),
          source: $source
        }
    ' >"$tmp_result"; then
    rm -f "$tmp_result"
    emit_self_heartbeat exit fail 0
    printf '{"schema_version":"skillos.cron_meta_watchdog.v1","ts":"%s","error":"watchdog_json_build_failed","stale_labels":[],"escalations":[]}\n' "$now"
    return 0
  fi

  local stale_count max_staleness runtime_ms
  stale_count="$(jq -r '.stale_count' "$tmp_result")"
  max_staleness="$(jq -r '[.labels[] | select(.stale and .staleness_sec != null) | .staleness_sec] | max // 0' "$tmp_result")"

  if [[ "$stale_count" =~ ^[0-9]+$ && "$stale_count" -gt 0 ]]; then
    mkdir -p "$(dirname "$alerts")" 2>/dev/null || true
    jq -c \
      --arg schema_version "skillos.cron_watchdog_alert.v1" \
      --arg ts "$now" \
      --arg source ".flywheel/scripts/cron-meta-watchdog.sh" \
      --argjson max_staleness_sec "$max_staleness" \
      '{schema_version:$schema_version,ts:$ts,stale_count:.stale_count,stale_labels:.stale_labels,max_staleness_sec:$max_staleness_sec,source:$source}' \
      "$tmp_result" >>"$alerts" 2>/dev/null || true
  fi

  runtime_ms="$(( $(perl -MTime::HiRes=time -e 'printf "%d\n", time()*1000') - started_ms ))"
  emit_self_heartbeat exit ok "$runtime_ms"

  case "$format" in
    json) cat "$tmp_result" ;;
  esac
  rm -f "$tmp_result"
}

main "$@"
