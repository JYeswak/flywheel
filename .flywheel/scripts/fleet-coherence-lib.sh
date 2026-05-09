#!/usr/bin/env bash

FC_WRITER_CONTRACT="fleet-coherence-writer/v1"
FC_SCHEMA_VERSION=2
FC_DETECTOR="fleet-coherence"
FC_DEFAULT_MAX_ROWS=10000
FC_DEFAULT_MAX_ARCHIVES=20
FC_JSONL_APPEND_LIB="${FC_JSONL_APPEND_LIB:-$HOME/.local/share/flywheel-watchers/lib/jsonl-append.sh}"

if [[ -f "$FC_JSONL_APPEND_LIB" ]]; then
  # shellcheck source=/dev/null
  source "$FC_JSONL_APPEND_LIB"
fi

fc_state_dir() {
  printf '%s\n' "${FLYWHEEL_FLEET_COHERENCE_STATE_DIR:-${XDG_STATE_HOME:-$HOME/.local/state}/flywheel/fleet-coherence}"
}

fc_events_path() {
  printf '%s\n' "${FLYWHEEL_FLEET_COHERENCE_EVENTS:-$(fc_state_dir)/fleet-coherence-events-v2.jsonl}"
}

fc_latest_path() {
  printf '%s\n' "${FLYWHEEL_FLEET_COHERENCE_LATEST:-$(fc_state_dir)/fleet-coherence-latest.json}"
}

fc_archive_dir() {
  printf '%s\n' "${FLYWHEEL_FLEET_COHERENCE_ARCHIVE_DIR:-$(fc_state_dir)/archive}"
}

fc_max_rows() {
  printf '%s\n' "${FLYWHEEL_FLEET_COHERENCE_MAX_ROWS:-$FC_DEFAULT_MAX_ROWS}"
}

fc_max_archives() {
  printf '%s\n' "${FLYWHEEL_FLEET_COHERENCE_MAX_ARCHIVES:-$FC_DEFAULT_MAX_ARCHIVES}"
}

fc_now() {
  if [[ -n "${FLYWHEEL_FLEET_COHERENCE_NOW:-}" ]]; then
    printf '%s\n' "$FLYWHEEL_FLEET_COHERENCE_NOW"
  else
    date -u +%Y-%m-%dT%H:%M:%SZ
  fi
}

fc_require_jq() {
  command -v jq >/dev/null 2>&1 || {
    printf 'fleet-coherence requires jq\n' >&2
    return 127
  }
}

fc_json_compact() {
  jq -cS .
}

fc_jsonl_append() {
  local path="$1"
  local row="$2"

  fc_require_jq
  local canonical
  canonical="$(printf '%s\n' "$row" | jq -cS 'select(type == "object")')" || return 1

  mkdir -p "$(dirname "$path")"
  if declare -F fw_jsonl_append_validated >/dev/null 2>&1; then
    fw_jsonl_append_validated "$path" "$canonical"
  else
    printf '%s\n' "$canonical" >>"$path"
  fi
}

fc_atomic_write_json() {
  local target="$1"
  local payload="$2"
  local dir base tmp
  dir="$(dirname "$target")"
  base="$(basename "$target")"
  mkdir -p "$dir"
  tmp="$(mktemp "$dir/.${base}.XXXXXX")"
  printf '%s\n' "$payload" | fc_json_compact >"$tmp"
  chmod 0644 "$tmp"
  mv "$tmp" "$target"
}

fc_validate_event_row() {
  fc_require_jq
  jq -e '
    def has_all($keys): . as $object | all($keys[]; . as $key | $object | has($key));
    type == "object"
    and .schema_version == 2
    and .record_type == "event"
    and has_all([
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
    ])
    and (.event_id | type == "string" and length > 0)
    and (.class | type == "string" and length > 0)
    and (.detector | type == "string" and length > 0)
    and (.confidence | type == "number" and . >= 0 and . <= 1)
    and (.severity | IN("info", "warning", "error", "critical"))
    and (.state | IN("open", "still_open", "closed"))
    and (.dedupe_key | type == "string" and length > 0)
    and (.raw_source_refs | type == "array")
    and (.evidence | type == "object")
    and (.l61 | type == "object" and has_all([
      "ntm_attempted",
      "ntm_pane",
      "ntm_session",
      "ntm_result",
      "ntm_sent_at",
      "agent_mail_attempted",
      "agent_mail_from",
      "agent_mail_to",
      "agent_mail_message_id",
      "agent_mail_sent_at",
      "l61_pairing_status",
      "degraded_reason",
      "fleet_mail_identity_source",
      "project_key",
      "vault_token_validated"
    ]))
    and (.l62 | type == "object" and has_all([
      "repair_callback_required",
      "sd_count",
      "sd_ids"
    ]))
    and (.l63 | type == "object" and has_all([
      "recovery_action_requires_drill",
      "recovery_drill_ids"
    ]))
    and (.actions | type == "object" and has_all([
      "would_l61",
      "would_bead",
      "would_no_bead_reason",
      "bead_id",
      "no_bead_reason",
      "receipt_required",
      "shadow_mode"
    ]))
  ' >/dev/null
}

fc_drift_event_json() {
  local drift_class="$1"
  local count="$2"
  local events_path="$3"
  local first_bad_line="$4"
  local now
  now="$(fc_now)"

  jq -ncS \
    --arg now "$now" \
    --arg drift_class "$drift_class" \
    --arg events_path "$events_path" \
    --arg first_bad_line "$first_bad_line" \
    --argjson count "$count" \
    --arg writer "$FC_WRITER_CONTRACT" \
    '{
      actions: {
        bead_id: null,
        no_bead_reason: "detector runtime drift surfaced by fleet-coherence writer",
        receipt_required: false,
        shadow_mode: true,
        would_bead: false,
        would_l61: false,
        would_no_bead_reason: "detector runtime drift surfaced by fleet-coherence writer"
      },
      class: "detector_runtime_drift",
      confidence: 1,
      dedupe_key: ("detector_runtime_drift:fleet-coherence:" + $drift_class),
      detector: "fleet-coherence",
      detector_git_sha: "runtime",
      detector_version: $writer,
      event_id: ("fc_runtime_drift_" + $drift_class + "_" + ($now | gsub("[^0-9A-Za-z]"; ""))),
      evidence: {
        drift_class: $drift_class,
        corrupt_row_count: $count,
        first_bad_line: ($first_bad_line | tonumber?),
        events_path: $events_path,
        surfaced_as: "detector_runtime_drift"
      },
      first_seen_ts: $now,
      l61: {
        agent_mail_attempted: false,
        agent_mail_from: null,
        agent_mail_message_id: null,
        agent_mail_sent_at: null,
        agent_mail_to: null,
        degraded_reason: null,
        fleet_mail_identity_source: "not_applicable",
        l61_pairing_status: "not_attempted",
        ntm_attempted: false,
        ntm_pane: null,
        ntm_result: null,
        ntm_sent_at: null,
        ntm_session: null,
        project_key: null,
        vault_token_validated: false
      },
      l62: {
        repair_callback_required: false,
        sd_count: 0,
        sd_ids: []
      },
      l63: {
        recovery_action_requires_drill: false,
        recovery_drill_ids: []
      },
      last_seen_ts: $now,
      pane: null,
      raw_source_refs: [
        {
          line: ($first_bad_line | tonumber?),
          path: $events_path
        }
      ],
      record_type: "event",
      resend_after_ts: null,
      sample_count: $count,
      sample_window_s: 0,
      schema_version: 2,
      seen_count: $count,
      session: "fleet-coherence",
      severity: "warning",
      source_age_s: 0,
      source_ts: $now,
      state: "open",
      suppression_id: null,
      ts: $now
    }'
}

fc_scan_events() {
  local events_path="${1:-$(fc_events_path)}"
  local valid_rows bad_rows line line_no corrupt_count first_bad_line canonical drift_event
  valid_rows="$(mktemp "${TMPDIR:-/tmp}/fleet-coherence-valid.XXXXXX")"
  bad_rows="$(mktemp "${TMPDIR:-/tmp}/fleet-coherence-bad.XXXXXX")"

  line_no=0
  corrupt_count=0
  first_bad_line=""

  if [[ -f "$events_path" ]]; then
    while IFS= read -r line || [[ -n "$line" ]]; do
      line_no=$((line_no + 1))
      [[ -z "$line" ]] && continue
      if canonical="$(printf '%s\n' "$line" | jq -cS . 2>/dev/null)" && printf '%s\n' "$canonical" | fc_validate_event_row; then
        printf '%s\n' "$canonical" >>"$valid_rows"
      else
        corrupt_count=$((corrupt_count + 1))
        [[ -n "$first_bad_line" ]] || first_bad_line="$line_no"
        jq -ncS --argjson line_no "$line_no" --arg raw "$line" '{line:$line_no,raw:$raw}' >>"$bad_rows"
      fi
    done <"$events_path"
  fi

  drift_event="null"
  if [[ "$corrupt_count" -gt 0 ]]; then
    drift_event="$(fc_drift_event_json "corrupt_jsonl_row" "$corrupt_count" "$events_path" "$first_bad_line")"
  fi

  local scan_payload
  scan_payload="$(jq -s -cS \
    --arg events_path "$events_path" \
    --arg generated_at "$(fc_now)" \
    --argjson corrupt_count "$corrupt_count" \
    --argjson drift_event "$drift_event" \
    --slurpfile corrupt_rows "$bad_rows" '
      {
        schema_version: "fleet-coherence-scan/v1",
        status: (if $corrupt_count > 0 then "warn" else "ok" end),
        generated_at: $generated_at,
        events_path: $events_path,
        valid_event_count: length,
        corrupt_row_count: $corrupt_count,
        detector_runtime_drift_count: (if $corrupt_count > 0 then 1 else 0 end),
        detector_runtime_drift: (if $corrupt_count > 0 then [$drift_event] else [] end),
        open_count: (map(select(.state == "open" or .state == "still_open")) | length),
        closed_count: (map(select(.state == "closed")) | length),
        latest_event: (if length > 0 then .[-1] else null end),
        corrupt_rows: $corrupt_rows
      }
    ' "$valid_rows")"
  rm -f "$valid_rows" "$bad_rows"
  printf '%s\n' "$scan_payload"
}

fc_update_latest_snapshot() {
  local events_path="${1:-$(fc_events_path)}"
  local latest_path="${2:-$(fc_latest_path)}"
  local retention_payload="${3:-null}"
  local scan payload
  scan="$(fc_scan_events "$events_path")"

  payload="$(jq -ncS \
    --arg generated_at "$(fc_now)" \
    --arg writer "$FC_WRITER_CONTRACT" \
    --arg latest_path "$latest_path" \
    --argjson scan "$scan" \
    --argjson retention "$retention_payload" '
      {
        schema_version: "fleet-coherence-latest/v1",
        writer_contract: $writer,
        generated_at: $generated_at,
        latest_path: $latest_path,
        status: $scan.status,
        l112_observed: "OK_fleet_coherence_writer",
        valid_event_count: $scan.valid_event_count,
        corrupt_row_count: $scan.corrupt_row_count,
        detector_runtime_drift_count: $scan.detector_runtime_drift_count,
        detector_runtime_drift: $scan.detector_runtime_drift,
        open_count: $scan.open_count,
        closed_count: $scan.closed_count,
        latest_event: $scan.latest_event,
        retention: $retention
      }
    ')"
  fc_atomic_write_json "$latest_path" "$payload"
  printf '%s\n' "$payload"
}

fc_apply_retention() {
  local events_path="${1:-$(fc_events_path)}"
  local max_rows="${2:-$(fc_max_rows)}"
  local archive_dir="${3:-$(fc_archive_dir)}"
  local max_archives="${4:-$(fc_max_archives)}"
  local valid_rows total_rows valid_count archive_path new_hot tmp_list now

  [[ "$max_rows" =~ ^[0-9]+$ && "$max_rows" -gt 0 ]] || {
    printf 'invalid FLYWHEEL_FLEET_COHERENCE_MAX_ROWS=%s\n' "$max_rows" >&2
    return 64
  }
  [[ "$max_archives" =~ ^[0-9]+$ && "$max_archives" -gt 0 ]] || {
    printf 'invalid FLYWHEEL_FLEET_COHERENCE_MAX_ARCHIVES=%s\n' "$max_archives" >&2
    return 64
  }

  if [[ ! -f "$events_path" ]]; then
    jq -ncS --arg path "$events_path" --argjson max_rows "$max_rows" \
      '{schema_version:"fleet-coherence-retention/v1",status:"ok",rotated:false,events_path:$path,max_rows:$max_rows,total_rows_before:0,valid_rows_kept:0,archive_path:null}'
    return 0
  fi

  total_rows="$(wc -l <"$events_path" | tr -d ' ')"
  if [[ "$total_rows" -le "$max_rows" ]]; then
    jq -ncS --arg path "$events_path" --argjson max_rows "$max_rows" --argjson total_rows "$total_rows" \
      '{schema_version:"fleet-coherence-retention/v1",status:"ok",rotated:false,events_path:$path,max_rows:$max_rows,total_rows_before:$total_rows,valid_rows_kept:$total_rows,archive_path:null}'
    return 0
  fi

  mkdir -p "$archive_dir" "$(dirname "$events_path")"
  now="$(fc_now | tr -cd '0-9A-Za-z')"
  archive_path="$archive_dir/$(basename "$events_path").$now"
  cp "$events_path" "$archive_path"

  valid_rows="$(mktemp "${TMPDIR:-/tmp}/fleet-coherence-retain-valid.XXXXXX")"
  new_hot="$(mktemp "$(dirname "$events_path")/.fleet-coherence-events.XXXXXX")"
  tmp_list="$(mktemp "${TMPDIR:-/tmp}/fleet-coherence-archives.XXXXXX")"

  while IFS= read -r line || [[ -n "$line" ]]; do
    [[ -z "$line" ]] && continue
    if canonical="$(printf '%s\n' "$line" | jq -cS . 2>/dev/null)" && printf '%s\n' "$canonical" | fc_validate_event_row; then
      printf '%s\n' "$canonical" >>"$valid_rows"
    fi
  done <"$events_path"

  valid_count="$(wc -l <"$valid_rows" | tr -d ' ')"
  if [[ "$valid_count" -gt "$max_rows" ]]; then
    tail -n "$max_rows" "$valid_rows" >"$new_hot"
  else
    cp "$valid_rows" "$new_hot"
  fi
  mv "$new_hot" "$events_path"

  find "$archive_dir" -type f -name "$(basename "$events_path").*" -print0 \
    | xargs -0 ls -1t 2>/dev/null >"$tmp_list" || true
  if [[ "$(wc -l <"$tmp_list" | tr -d ' ')" -gt "$max_archives" ]]; then
    tail -n +"$((max_archives + 1))" "$tmp_list" | while IFS= read -r old_archive; do
      rm -f "$old_archive"
    done
  fi

  local retention_payload
  retention_payload="$(jq -ncS \
    --arg path "$events_path" \
    --arg archive_path "$archive_path" \
    --argjson max_rows "$max_rows" \
    --argjson total_rows "$total_rows" \
    --argjson valid_count "$valid_count" \
    '{schema_version:"fleet-coherence-retention/v1",status:"ok",rotated:true,events_path:$path,max_rows:$max_rows,total_rows_before:$total_rows,valid_rows_kept:([ $valid_count, $max_rows ] | min),archive_path:$archive_path}')"
  rm -f "$valid_rows" "$new_hot" "$tmp_list"
  printf '%s\n' "$retention_payload"
}

fc_append_event() {
  local row="$1"
  local events_path="${2:-$(fc_events_path)}"
  local latest_path="${3:-$(fc_latest_path)}"
  local canonical retention snapshot pre_scan status

  canonical="$(printf '%s\n' "$row" | fc_json_compact)"
  printf '%s\n' "$canonical" | fc_validate_event_row || {
    printf 'invalid fleet-coherence v2 event row\n' >&2
    return 65
  }

  fc_jsonl_append "$events_path" "$canonical"
  pre_scan="$(fc_scan_events "$events_path")"
  retention="$(fc_apply_retention "$events_path")"
  snapshot="$(fc_update_latest_snapshot "$events_path" "$latest_path" "$retention")"

  status="$(jq -nr --argjson scan "$pre_scan" --argjson snapshot "$snapshot" 'if (($scan.corrupt_row_count // 0) > 0 or ($snapshot.corrupt_row_count // 0) > 0) then "warn" else "ok" end')"
  jq -ncS \
    --arg status "$status" \
    --arg writer "$FC_WRITER_CONTRACT" \
    --arg events_path "$events_path" \
    --arg latest_path "$latest_path" \
    --argjson row "$canonical" \
    --argjson pre_scan "$pre_scan" \
    --argjson retention "$retention" \
    --argjson snapshot "$snapshot" '
      {
        schema_version: "fleet-coherence-write-receipt/v1",
        status: $status,
        writer_contract: $writer,
        l112_observed: "OK_fleet_coherence_writer",
        events_path: $events_path,
        latest_path: $latest_path,
        event_id: $row.event_id,
        dedupe_key: $row.dedupe_key,
        state: $row.state,
        append_receipt: {status:"ok",idempotent_skip:false},
        latest_snapshot_written: true,
        detector_runtime_drift_count: (($pre_scan.detector_runtime_drift_count // 0) + ($snapshot.detector_runtime_drift_count // 0)),
        retention: $retention
      }
    '
}

fc_close_event_row() {
  local row="$1"
  local reason="${2:-closed by fleet-coherence writer}"
  local now canonical
  now="$(fc_now)"
  canonical="$(printf '%s\n' "$row" | fc_json_compact)"
  printf '%s\n' "$canonical" | fc_validate_event_row || {
    printf 'invalid fleet-coherence v2 event row\n' >&2
    return 65
  }

  jq -cS \
    --arg now "$now" \
    --arg reason "$reason" \
    --arg writer "$FC_WRITER_CONTRACT" '
      . as $source
      | .event_id = (($source.event_id + "_closed_" + ($now | gsub("[^0-9A-Za-z]"; ""))) | gsub("[^A-Za-z0-9_:-]"; "_"))
      | .state = "closed"
      | .ts = $now
      | .source_ts = $now
      | .source_age_s = 0
      | .last_seen_ts = $now
      | .resend_after_ts = null
      | .dedupe_key = (if (.dedupe_key | endswith(":closed")) then .dedupe_key else (.dedupe_key + ":closed") end)
      | .evidence.close_reason = $reason
      | .evidence.closed_by = $writer
      | .evidence.closed_source_event_id = $source.event_id
      | .actions.would_l61 = false
      | .actions.would_bead = false
      | .actions.would_no_bead_reason = $reason
      | .actions.bead_id = null
      | .actions.no_bead_reason = $reason
      | .actions.receipt_required = false
      | .actions.shadow_mode = false
    ' <<<"$canonical"
}
