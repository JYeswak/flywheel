#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd -P)"
LIB="${FLYWHEEL_FLEET_COHERENCE_LIB:-$ROOT/.flywheel/scripts/fleet-coherence-lib.sh}"

# shellcheck source=.flywheel/scripts/fleet-coherence-lib.sh
source "$LIB"

usage() {
  cat <<'USAGE'
fleet-coherence-write.sh [--json] <command>

Commands:
  append --row <path|->          append one v2 event row and refresh latest
  append --row-json <json>       append one v2 event row and refresh latest
  close --row <path|->           append a closed v2 event row derived from input
  close --row-json <json>        append a closed v2 event row derived from input
  doctor                         scan ledger and refresh latest snapshot
  retention                      apply bounded ledger retention
  --info                         print writer contract metadata
  --schema                       print event contract metadata
USAGE
}

emit() {
  local payload="$1"
  if [[ "$JSON_MODE" == "1" ]]; then
    printf '%s\n' "$payload" | jq -cS .
  else
    printf '%s\n' "$payload" | jq -r '.message // .status // "ok"'
  fi
}

read_row_file() {
  local path="$1"
  if [[ "$path" == "-" ]]; then
    cat
  else
    cat "$path"
  fi
}

info_payload() {
  jq -ncS \
    --arg writer "$FC_WRITER_CONTRACT" \
    --arg events "$(fc_events_path)" \
    --arg latest "$(fc_latest_path)" \
    --arg archive "$(fc_archive_dir)" \
    --argjson max_rows "$(fc_max_rows)" \
    '{
      schema_version: "fleet-coherence-writer-info/v1",
      status: "ok",
      writer_contract: $writer,
      l112_observed: "OK_fleet_coherence_writer",
      commands: ["append", "close", "doctor", "retention"],
      paths: {
        events: $events,
        latest: $latest,
        archive_dir: $archive
      },
      retention: {
        max_rows: $max_rows,
        policy: "archive full hot ledger, rewrite hot ledger with newest valid rows, cap archive count"
      },
      exit_codes: {
        "0": "success",
        "64": "invalid args",
        "65": "invalid v2 event row",
        "127": "missing dependency"
      }
    }'
}

schema_payload() {
  jq -ncS --arg writer "$FC_WRITER_CONTRACT" '{
    schema_version: "fleet-coherence-writer-schema/v1",
    status: "ok",
    writer_contract: $writer,
    event_schema_version: 2,
    record_type: "event",
    close_dedupe_suffix: ":closed",
    runtime_drift_class: "detector_runtime_drift",
    required_top_level_fields: [
      "event_id",
      "schema_version",
      "record_type",
      "class",
      "detector",
      "detector_version",
      "detector_git_sha",
      "confidence",
      "severity",
      "state",
      "session",
      "pane",
      "ts",
      "source_ts",
      "source_age_s",
      "first_seen_ts",
      "last_seen_ts",
      "seen_count",
      "sample_count",
      "sample_window_s",
      "resend_after_ts",
      "suppression_id",
      "dedupe_key",
      "raw_source_refs",
      "evidence",
      "l61",
      "l62",
      "l63",
      "actions"
    ]
  }'
}

JSON_MODE=0
if [[ "${1:-}" == "--json" ]]; then
  JSON_MODE=1
  shift
fi

case "${1:-}" in
  --help|-h|"")
    usage
    exit 0
    ;;
  --info)
    shift || true
    [[ "${1:-}" == "--json" ]] && JSON_MODE=1
    emit "$(info_payload)"
    ;;
  --schema)
    shift || true
    [[ "${1:-}" == "--json" ]] && JSON_MODE=1
    emit "$(schema_payload)"
    ;;
  append)
    shift
    row=""
    while [[ $# -gt 0 ]]; do
      case "$1" in
        --json)
          JSON_MODE=1
          shift
          ;;
        --row)
          row="$(read_row_file "${2:?--row requires path}")"
          shift 2
          ;;
        --row-json)
          row="${2:?--row-json requires JSON}"
          shift 2
          ;;
        *)
          printf 'unknown append arg: %s\n' "$1" >&2
          exit 64
          ;;
      esac
    done
    [[ -n "$row" ]] || { printf 'append requires --row or --row-json\n' >&2; exit 64; }
    emit "$(fc_append_event "$row")"
    ;;
  close)
    shift
    row=""
    reason="closed by fleet-coherence writer"
    while [[ $# -gt 0 ]]; do
      case "$1" in
        --json)
          JSON_MODE=1
          shift
          ;;
        --row)
          row="$(read_row_file "${2:?--row requires path}")"
          shift 2
          ;;
        --row-json)
          row="${2:?--row-json requires JSON}"
          shift 2
          ;;
        --reason)
          reason="${2:?--reason requires text}"
          shift 2
          ;;
        *)
          printf 'unknown close arg: %s\n' "$1" >&2
          exit 64
          ;;
      esac
    done
    [[ -n "$row" ]] || { printf 'close requires --row or --row-json\n' >&2; exit 64; }
    emit "$(fc_append_event "$(fc_close_event_row "$row" "$reason")")"
    ;;
  doctor)
    shift
    while [[ $# -gt 0 ]]; do
      case "$1" in
        --json)
          JSON_MODE=1
          shift
          ;;
        *)
          printf 'unknown doctor arg: %s\n' "$1" >&2
          exit 64
          ;;
      esac
    done
    scan="$(fc_scan_events "$(fc_events_path)")"
    snapshot="$(fc_update_latest_snapshot "$(fc_events_path)" "$(fc_latest_path)" null)"
    emit "$(jq -ncS --argjson scan "$scan" --argjson snapshot "$snapshot" --arg writer "$FC_WRITER_CONTRACT" '{
      schema_version: "fleet-coherence-doctor/v1",
      status: $scan.status,
      writer_contract: $writer,
      l112_observed: "OK_fleet_coherence_writer",
      events_path: $scan.events_path,
      latest_path: $snapshot.latest_path,
      valid_event_count: $scan.valid_event_count,
      corrupt_row_count: $scan.corrupt_row_count,
      detector_runtime_drift_count: $scan.detector_runtime_drift_count,
      detector_runtime_drift: $scan.detector_runtime_drift,
      latest_snapshot_written: true
    }')"
    ;;
  retention)
    shift
    while [[ $# -gt 0 ]]; do
      case "$1" in
        --json)
          JSON_MODE=1
          shift
          ;;
        *)
          printf 'unknown retention arg: %s\n' "$1" >&2
          exit 64
          ;;
      esac
    done
    retention="$(fc_apply_retention "$(fc_events_path)")"
    snapshot="$(fc_update_latest_snapshot "$(fc_events_path)" "$(fc_latest_path)" "$retention")"
    emit "$(jq -ncS --argjson retention "$retention" --argjson snapshot "$snapshot" --arg writer "$FC_WRITER_CONTRACT" '{
      schema_version: "fleet-coherence-retention-receipt/v1",
      status: $retention.status,
      writer_contract: $writer,
      l112_observed: "OK_fleet_coherence_writer",
      retention: $retention,
      latest_snapshot_written: true,
      latest_path: $snapshot.latest_path
    }')"
    ;;
  *)
    printf 'unknown command: %s\n' "$1" >&2
    usage >&2
    exit 64
    ;;
esac

# Meta-Learning Cross-References (2026-05-19)
# Batch-16 comment backfill; citations are documentation-only and do not alter runtime behavior.
# Related: `/Users/josh/Developer/skillos/.flywheel/doctrine/meta-learnings/MP-19-flywheel-engagement-protocol.md`
# Related: `/Users/josh/Developer/skillos/.flywheel/doctrine/meta-learnings/MP-61-agent-first-operator-surface.md`
