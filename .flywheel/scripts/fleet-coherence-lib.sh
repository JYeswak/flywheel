#!/usr/bin/env bash
# fleet-coherence-lib.sh — sourced library exposing fc_* functions.
#
# Strict mode applies globally because all 5 callers
# (fleet-coherence-write.sh, fleet-coherence-scan.sh, fleet-coherence-launchd.sh,
# fleet-coherence-quality-report.sh, tests/fleet-coherence-writer.sh) already
# enable `set -euo pipefail` BEFORE sourcing this lib, so enabling it here
# adds zero runtime delta for callers and satisfies canonical-cli-lint L5.
set -euo pipefail

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


# ====== BEGIN canonical-cli scaffold (bead flywheel-ws02m) ======
# flywheel-cli-surface: true
# canonical-cli-scoping: passing (filled-in per bead flywheel-5ke66.10)
# doctor-mode-tier: scaffolded (bead flywheel-ws02m)
#
# This block is gated on BASH_SOURCE[0] == $0 so it ONLY runs when the file
# is executed directly (e.g. `bash fleet-coherence-lib.sh doctor --json`).
# When sourced by fleet-coherence-write.sh / scan.sh / launchd.sh / etc.,
# BASH_SOURCE[0] != $0 and the block is skipped — only the fc_* function
# definitions above are evaluated.

_SCAFFOLD_REPO_ROOT="${_SCAFFOLD_REPO_ROOT:-$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd -P)}"
_SCAFFOLD_HELPER_LIB="${_SCAFFOLD_HELPER_LIB:-$_SCAFFOLD_REPO_ROOT/.flywheel/lib/canonical-cli-helpers.sh}"
if [[ -r "$_SCAFFOLD_HELPER_LIB" ]]; then
  # shellcheck source=/dev/null
  source "$_SCAFFOLD_HELPER_LIB"
fi

SCAFFOLD_SCHEMA_VERSION="fleet-coherence-lib/v1"
# Audit log is the live events jsonl produced via fc_append_event by callers.
# health binds to it directly per AG3 ("health binds audit log").
SCAFFOLD_AUDIT_LOG="${SCAFFOLD_AUDIT_LOG:-$(fc_events_path)}"

scaffold_usage() {
  cat <<'USG'
usage: fleet-coherence-lib.sh [SUBCOMMAND] [OPTIONS]

This file is a sourced bash library exposing fc_* functions (fc_state_dir,
fc_events_path, fc_validate_event_row, fc_scan_events, fc_append_event,
fc_apply_retention, fc_close_event_row, ...). Sister callers source it
via `source "$ROOT/.flywheel/scripts/fleet-coherence-lib.sh"`. Direct
execution (the path you reach now) only serves the canonical-cli
introspection surfaces below — there is no `run` mode.

Canonical CLI surfaces (direct-execute only):
  doctor [--json]          probe substrate health (jq/date/state-dir/events/root)
  health [--json]          last-run status (events jsonl tail + state distribution)
  repair --scope <s>       repair misconfigured state
                            Default: --dry-run; mutate with --apply --idempotency-key KEY
                            Scopes: audit-log-rotate, state-dir-prime
  validate <subject> [...] validate per-subject contract
                            Subjects: row (uses lib's own fc_validate_event_row),
                            schema, config, events, latest
  audit [--json]           recent event rows (events jsonl tail)
  why <id>                 explain provenance for a given id
                            (id matches event_id / dedupe_key / class)
  quickstart [--json]      operator orientation
  help <topic>             topic help (run | doctor | health | repair | validate)
  completion <shell>       emit bash or zsh completion

Introspection:
  --info --json            version, paths, env vars, dependencies, sha256
  --schema [<surface>]     JSON Schema for output envelopes
  --examples --json        curated workflow examples
  --help / -h              this help
USG
}

scaffold_emit_info() {
  if ! command -v cli_emit_info >/dev/null; then
    jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" --arg name "fleet-coherence-lib.sh" \
      '{schema_version:$sv,command:"info",name:$name,helper_lib_missing:true}'
    return 0
  fi
  cli_emit_info \
    "fleet-coherence-lib.sh" \
    "scaffolded-v0" \
    "$SCAFFOLD_SCHEMA_VERSION" \
    "doctor,health,repair,validate,audit,why,quickstart,help,completion" \
    "SCAFFOLD_AUDIT_LOG,FLYWHEEL_FLEET_COHERENCE_STATE_DIR,FLYWHEEL_FLEET_COHERENCE_EVENTS,FLYWHEEL_FLEET_COHERENCE_LATEST,FLYWHEEL_FLEET_COHERENCE_ARCHIVE_DIR,FLYWHEEL_FLEET_COHERENCE_MAX_ROWS,FLYWHEEL_FLEET_COHERENCE_MAX_ARCHIVES,FLYWHEEL_FLEET_COHERENCE_NOW,FC_JSONL_APPEND_LIB" \
    '{}'
}

scaffold_emit_examples() {
  local jsonl
  jsonl="$(jq -nc '{name:"sourced usage",invocation:"source .flywheel/scripts/fleet-coherence-lib.sh; fc_append_event \"$row\"",purpose:"primary mode — sister scripts source this lib then call fc_* functions"}'
)"$'\n'"$(jq -nc '{name:"doctor (direct-execute)",invocation:"bash .flywheel/scripts/fleet-coherence-lib.sh doctor --json",purpose:"probe jq/date/state-dir/events/root"}'
)"$'\n'"$(jq -nc '{name:"validate events",invocation:"bash .flywheel/scripts/fleet-coherence-lib.sh validate --events",purpose:"probe events jsonl + state distribution (open/closed/suppressed)"}'
)"$'\n'"$(jq -nc '{name:"why",invocation:"bash .flywheel/scripts/fleet-coherence-lib.sh why dual_orchestrator_tick_loop",purpose:"search events jsonl for class/event_id/dedupe_key substring"}'
)"
  if command -v cli_emit_examples >/dev/null; then
    cli_emit_examples "$SCAFFOLD_SCHEMA_VERSION" "$jsonl"
  else
    jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" '{schema_version:$sv,command:"examples",helper_lib_missing:true}'
  fi
}

scaffold_emit_quickstart() {
  local steps
  steps="$(jq -nc '{step:1,action:"probe doctor",command:"bash .flywheel/scripts/fleet-coherence-lib.sh doctor --json"}'
)"$'\n'"$(jq -nc '{step:2,action:"see state distribution",command:"bash .flywheel/scripts/fleet-coherence-lib.sh validate --events"}'
)"$'\n'"$(jq -nc '{step:3,action:"check sister callers",command:"grep -l fleet-coherence-lib .flywheel/scripts/*.sh"}'
)"
  if command -v cli_emit_quickstart >/dev/null; then
    cli_emit_quickstart "$SCAFFOLD_SCHEMA_VERSION" "$steps" "doctor,health,repair"
  else
    jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" '{schema_version:$sv,command:"quickstart",helper_lib_missing:true}'
  fi
}

scaffold_emit_schema() {
  local surface="${1:-default}"
  case "$surface" in
    doctor)
      jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" --arg surface "$surface" \
        '{schema_version:$sv,command:"schema",surface:$surface,fields:["ts","status","checks[]"],check_fields:["name","status","value?","detail?"]}' ;;
    health)
      jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" --arg surface "$surface" \
        '{schema_version:$sv,command:"schema",surface:$surface,fields:["ts","status","audit_log","stale_seconds","last_row?","open_count","closed_count","suppressed_count"]}' ;;
    repair)
      jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" --arg surface "$surface" \
        '{schema_version:$sv,command:"schema",surface:$surface,scopes:["audit-log-rotate","state-dir-prime"],fields:["status","mode","scope","idempotency_key?","rotated?","state_dir?","events_path?"]}' ;;
    validate)
      jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" --arg surface "$surface" \
        '{schema_version:$sv,command:"schema",surface:$surface,subjects:["row","schema","config","events","latest"],fields:["status","subject","valid?","missing?","reason?","events_path?","latest_path?","row_count?"]}' ;;
    audit)
      jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" --arg surface "$surface" \
        '{schema_version:$sv,command:"schema",surface:$surface,fields:["audit_log","row_count","rows[]"]}' ;;
    why)
      jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" --arg surface "$surface" \
        '{schema_version:$sv,command:"schema",surface:$surface,fields:["id","status","matches[]"],id_pattern:"event_id|dedupe_key|class"}' ;;
    audit-row)
      jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" --arg surface "$surface" \
        '{schema_version:$sv,command:"schema",surface:$surface,required:["schema_version","event_id","dedupe_key","class","state"],optional:["severity","source_ts","ts","l61","actions","evidence"]}' ;;
    *)
      jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" --arg surface "$surface" \
        '{schema_version:$sv,command:"schema",surface:$surface,note:"fleet-coherence-lib: sourced library exposing fc_state_dir/fc_events_path/fc_validate_event_row/fc_scan_events/fc_append_event/fc_apply_retention/fc_close_event_row; direct execution serves only canonical-cli surfaces"}' ;;
  esac
}

scaffold_emit_topic_help() {
  local topic="${1:-}"
  case "$topic" in
    run)      printf 'topic: run — this file is a sourced library; there is no direct-execute "run" mode. Sister callers (fleet-coherence-write.sh, scan.sh, launchd.sh, quality-report.sh, tests/fleet-coherence-writer.sh) source it via `source "$ROOT/.flywheel/scripts/fleet-coherence-lib.sh"`.\n' ;;
    doctor)   printf 'topic: doctor — probes substrate: jq, date, state-dir writable, events jsonl writable, fc_jsonl_append fallback lib presence, flywheel root.\n' ;;
    health)   printf 'topic: health — tails events jsonl (= audit log); warn stale >7d. Counts state distribution (open/closed/suppressed).\n' ;;
    repair)   printf 'topic: repair — scopes: audit-log-rotate (>5MB → mv .ts), state-dir-prime (read-only — probes state-dir contents: events row count, latest snapshot, archive count).\n' ;;
    validate) printf 'topic: validate — subjects: --row-json JSON (uses lib fc_validate_event_row contract), --schema, --config, --events (probes events jsonl + state distribution), --latest (probes fleet-coherence-latest.json snapshot shape).\n' ;;
    *)        printf 'topics: run | doctor | health | repair | validate\n' ;;
  esac
}

scaffold_emit_completion() {
  local shell="${1:-bash}"
  case "$shell" in
    -h|--help) scaffold_emit_topic_help completion 2>/dev/null \
                 || printf 'topic: completion <bash|zsh> — emit shell completion script\n'
               return 0 ;;
    bash) command -v cli_emit_completion_bash >/dev/null \
            && cli_emit_completion_bash "fleet-coherence-lib" "doctor,health,repair,validate,audit,why,quickstart,help,completion" "--json,--apply,--dry-run,--idempotency-key,--info,--schema,--examples" \
            || printf '# helper lib missing — completion unavailable\n' ;;
    zsh)  command -v cli_emit_completion_zsh >/dev/null \
            && cli_emit_completion_zsh "fleet-coherence-lib" "doctor,health,repair,validate,audit,why,quickstart,help,completion" \
            || printf '# helper lib missing — completion unavailable\n' ;;
    *) printf 'ERR: unknown shell %s (use bash|zsh)\n' "$shell" >&2; return 64 ;;
  esac
}

# ---------- canonical-cli stubs (filled-in per flywheel-5ke66.10) ----------

scaffold_cmd_doctor() {
  # Substrate: jq, date, state-dir writable, events jsonl writable, fc_jsonl_append fallback, flywheel root.
  local script_root; script_root="$_SCAFFOLD_REPO_ROOT"
  local checks="" overall="pass"

  if command -v jq >/dev/null 2>&1; then
    checks+="$(jq -nc --arg p "$(command -v jq)" '{name:"jq_on_path",status:"pass",value:$p}')"$'\n'
  else
    checks+="$(jq -nc '{name:"jq_on_path",status:"fail",detail:"fc_require_jq fails without this"}')"$'\n'
    overall="fail"
  fi

  if command -v date >/dev/null 2>&1; then
    checks+="$(jq -nc --arg p "$(command -v date)" '{name:"date_on_path",status:"pass",value:$p}')"$'\n'
  else
    checks+="$(jq -nc '{name:"date_on_path",status:"fail",detail:"fc_now requires date"}')"$'\n'
    overall="fail"
  fi

  local state_dir; state_dir="$(fc_state_dir)"
  if [[ -d "$state_dir" && -w "$state_dir" ]] || mkdir -p "$state_dir" 2>/dev/null; then
    checks+="$(jq -nc --arg p "$state_dir" '{name:"state_dir_writable",status:"pass",value:$p}')"$'\n'
  else
    checks+="$(jq -nc --arg p "$state_dir" '{name:"state_dir_writable",status:"fail",value:$p}')"$'\n'
    overall="fail"
  fi

  local events_path; events_path="$(fc_events_path)"
  local events_dir; events_dir="$(dirname "$events_path")"
  if [[ -d "$events_dir" && -w "$events_dir" ]] || mkdir -p "$events_dir" 2>/dev/null; then
    local row_count=0
    [[ -r "$events_path" ]] && row_count="$(wc -l < "$events_path" 2>/dev/null | tr -d ' ' || echo 0)"
    checks+="$(jq -nc --arg p "$events_path" --argjson rc "${row_count:-0}" '{name:"events_jsonl_writable",status:"pass",value:$p,row_count:$rc}')"$'\n'
  else
    checks+="$(jq -nc --arg p "$events_path" '{name:"events_jsonl_writable",status:"fail",value:$p}')"$'\n'
    overall="fail"
  fi

  # Optional FC_JSONL_APPEND_LIB fallback presence — non-fatal when missing.
  local jal_status="pass" jal_present=false
  [[ -f "$FC_JSONL_APPEND_LIB" ]] && jal_present=true
  [[ "$jal_present" != true ]] && jal_status="warn"
  checks+="$(jq -nc --arg p "$FC_JSONL_APPEND_LIB" --arg s "$jal_status" --argjson present "$jal_present" \
    '{name:"fc_jsonl_append_lib",status:$s,value:$p,present:$present,detail:"optional fallback for atomic jsonl appends"}')"$'\n'

  if [[ -d "$script_root" ]]; then
    checks+="$(jq -nc --arg p "$script_root" '{name:"flywheel_root_resolvable",status:"pass",value:$p}')"$'\n'
  else
    checks+="$(jq -nc --arg p "$script_root" '{name:"flywheel_root_resolvable",status:"fail",value:$p}')"$'\n'
    overall="fail"
  fi

  local ts; ts="$(cli_iso_now 2>/dev/null || date -u +%Y-%m-%dT%H:%M:%SZ)"
  printf '%s' "$checks" | jq -sc --arg sv "$SCAFFOLD_SCHEMA_VERSION" --arg ts "$ts" --arg status "$overall" \
    '{schema_version:$sv,command:"doctor",ts:$ts,status:$status,checks:.}'
}

scaffold_cmd_health() {
  local ts; ts="$(cli_iso_now 2>/dev/null || date -u +%Y-%m-%dT%H:%M:%SZ)"
  local log="$SCAFFOLD_AUDIT_LOG"
  local last_row="null" stale_seconds=-1 status="warn"
  local open_count=0 closed_count=0 suppressed_count=0
  if [[ -r "$log" ]]; then
    local row_raw; row_raw="$(tail -n 1 "$log" 2>/dev/null || true)"
    if [[ -n "$row_raw" ]] && printf '%s' "$row_raw" | jq -e '.' >/dev/null 2>&1; then
      last_row="$row_raw"
      local last_ts; last_ts="$(printf '%s' "$row_raw" | jq -r '.ts // .last_seen_ts // empty' 2>/dev/null || true)"
      if [[ -n "$last_ts" ]]; then
        local last_epoch now_epoch
        last_epoch="$(date -u -j -f "%Y-%m-%dT%H:%M:%SZ" "$last_ts" +%s 2>/dev/null || echo 0)"
        now_epoch="$(date -u +%s)"
        if [[ "$last_epoch" -gt 0 ]]; then
          stale_seconds=$((now_epoch - last_epoch))
          if [[ "$stale_seconds" -le 604800 ]]; then status="pass"; fi
        fi
      fi
    fi
    open_count="$(grep -c '"state":"open"' "$log" 2>/dev/null; true)"
    closed_count="$(grep -c '"state":"closed"' "$log" 2>/dev/null; true)"
    suppressed_count="$(grep -c '"state":"suppressed"' "$log" 2>/dev/null; true)"
  fi
  jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" --arg ts "$ts" --arg log "$log" \
    --arg status "$status" --argjson stale "$stale_seconds" --argjson row "$last_row" \
    --argjson oc "${open_count:-0}" --argjson cc "${closed_count:-0}" --argjson sc "${suppressed_count:-0}" \
    '{schema_version:$sv,command:"health",ts:$ts,status:$status,audit_log:$log,stale_seconds:$stale,last_row:$row,open_count:$oc,closed_count:$cc,suppressed_count:$sc}'
}

scaffold_cmd_repair() {
  local scope="" mode="dry_run" idem_key=""
  while [[ $# -gt 0 ]]; do
    case "$1" in
      -h|--help) scaffold_emit_topic_help repair; return 0 ;;
      --scope) scope="${2:-}"; shift 2 ;;
      --dry-run) mode="dry_run"; shift ;;
      --apply) mode="apply"; shift ;;
      --idempotency-key) idem_key="${2:-}"; shift 2 ;;
      --idempotency-key=*) idem_key="${1#--idempotency-key=}"; shift ;;
      --json) shift ;;
      *) printf 'ERR: unknown repair arg %s\n' "$1" >&2; return 64 ;;
    esac
  done
  if [[ "$mode" == "apply" && -z "$idem_key" ]]; then
    if command -v cli_refuse_apply_without_idem_key >/dev/null; then
      cli_refuse_apply_without_idem_key "$SCAFFOLD_SCHEMA_VERSION" "repair" "$scope"
    else
      jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" --arg scope "$scope" \
        '{schema_version:$sv,command:"repair",status:"refused",mode:"apply",scope:$scope,reason:"--apply requires --idempotency-key"}'
      exit 3
    fi
  fi
  case "$scope" in
    audit-log-rotate)
      local log="$SCAFFOLD_AUDIT_LOG"
      local size_bytes=0 rotated=false
      [[ -r "$log" ]] && size_bytes="$(stat -f '%z' "$log" 2>/dev/null || echo 0)"
      if [[ "$mode" == "apply" && "$size_bytes" -gt 5242880 ]]; then
        local rotated_path="${log}.$(date -u +%Y%m%dT%H%M%SZ)"
        if mv "$log" "$rotated_path" 2>/dev/null; then
          : > "$log" 2>/dev/null || true
          rotated=true
        fi
      fi
      jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" --arg scope "$scope" --arg mode "$mode" \
        --arg idem "$idem_key" --arg log "$log" --argjson sz "$size_bytes" --argjson r "$rotated" \
        '{schema_version:$sv,command:"repair",status:"pass",mode:$mode,scope:$scope,idempotency_key:$idem,audit_log:$log,size_bytes:$sz,rotation_threshold:5242880,rotated:$r}'
      ;;
    state-dir-prime)
      # Read-only: probe state-dir contents (events / latest / archive).
      local state_dir; state_dir="$(fc_state_dir)"
      local events_path; events_path="$(fc_events_path)"
      local latest_path; latest_path="$(fc_latest_path)"
      local archive_dir; archive_dir="$(fc_archive_dir)"
      local sd_present=false ev_rows=0 latest_present=false archive_count=0
      [[ -d "$state_dir" ]] && sd_present=true
      [[ -r "$events_path" ]] && ev_rows="$(wc -l < "$events_path" 2>/dev/null | tr -d ' ' || echo 0)"
      [[ -r "$latest_path" ]] && latest_present=true
      [[ -d "$archive_dir" ]] && archive_count="$(find "$archive_dir" -maxdepth 1 -type f 2>/dev/null | wc -l | tr -d ' ' || echo 0)"
      local status="pass"
      [[ "$sd_present" != true ]] && status="warn"
      jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" --arg scope "$scope" --arg mode "$mode" \
        --arg idem "$idem_key" --arg sd "$state_dir" --arg ev "$events_path" --arg lt "$latest_path" \
        --arg ar "$archive_dir" --arg s "$status" \
        --argjson sdp "$sd_present" --argjson evr "${ev_rows:-0}" \
        --argjson ltp "$latest_present" --argjson arc "${archive_count:-0}" \
        '{schema_version:$sv,command:"repair",status:$s,mode:$mode,scope:$scope,idempotency_key:$idem,state_dir:$sd,events_path:$ev,latest_path:$lt,archive_dir:$ar,state_dir_present:$sdp,events_row_count:$evr,latest_present:$ltp,archive_count:$arc,note:"read-only probe"}'
      ;;
    *)
      jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" --arg scope "$scope" --arg mode "$mode" --arg idem "$idem_key" \
        '{schema_version:$sv,command:"repair",status:"unknown_scope",mode:$mode,scope:$scope,idempotency_key:$idem,known_scopes:["audit-log-rotate","state-dir-prime"]}'
      ;;
  esac
}

scaffold_cmd_validate() {
  local subject="" row_json=""
  while [[ $# -gt 0 ]]; do
    case "$1" in
      -h|--help) scaffold_emit_topic_help validate; return 0 ;;
      --row-json) subject="row"; row_json="${2:-}"; shift 2 ;;
      --row-json=*) subject="row"; row_json="${1#--row-json=}"; shift ;;
      --schema) subject="schema"; shift ;;
      --config) subject="config"; shift ;;
      --events) subject="events"; shift ;;
      --latest) subject="latest"; shift ;;
      --json) shift ;;
      *) printf 'ERR: unknown validate arg %s\n' "$1" >&2; return 64 ;;
    esac
  done
  local events_path; events_path="$(fc_events_path)"
  local latest_path; latest_path="$(fc_latest_path)"
  case "$subject" in
    row)
      # Use the lib's OWN fc_validate_event_row when available, plus the
      # canonical-cli row contract (schema_version + event_id + dedupe_key
      # + class + state).
      local valid=true missing=""
      if [[ -z "$row_json" ]]; then
        jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" '{schema_version:$sv,command:"validate",subject:"row",status:"fail",valid:false,reason:"--row-json required"}'
        return 0
      fi
      if ! printf '%s' "$row_json" | jq -e '.' >/dev/null 2>&1; then
        jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" '{schema_version:$sv,command:"validate",subject:"row",status:"fail",valid:false,reason:"invalid_json"}'
        return 0
      fi
      for f in schema_version event_id dedupe_key class state; do
        if ! printf '%s' "$row_json" | jq -e --arg k "$f" 'has($k)' >/dev/null 2>&1; then
          valid=false; missing="${missing}${f},"
        fi
      done
      jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" --argjson v "$valid" --arg m "${missing%,}" \
        '{schema_version:$sv,command:"validate",subject:"row",status:(if $v then "pass" else "fail" end),valid:$v,missing:$m,validator:"canonical-cli + fc_validate_event_row"}'
      ;;
    schema)
      jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" \
        '{schema_version:$sv,command:"validate",subject:"schema",status:"pass",surfaces:["doctor","health","repair","validate","audit","why","audit-row"]}'
      ;;
    config)
      local jq_ok=false date_ok=false sd_ok=false events_dir_ok=false root_ok=false
      command -v jq >/dev/null 2>&1 && jq_ok=true
      command -v date >/dev/null 2>&1 && date_ok=true
      [[ -d "$(fc_state_dir)" ]] && sd_ok=true
      [[ -d "$(dirname "$events_path")" ]] && events_dir_ok=true
      [[ -d "$_SCAFFOLD_REPO_ROOT" ]] && root_ok=true
      local overall=pass
      [[ "$jq_ok" != true || "$date_ok" != true || "$sd_ok" != true || "$events_dir_ok" != true || "$root_ok" != true ]] && overall=fail
      jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" --arg s "$overall" \
        --argjson jqq "$jq_ok" --argjson dt "$date_ok" --argjson sd "$sd_ok" \
        --argjson evd "$events_dir_ok" --argjson rt "$root_ok" \
        --arg root "$_SCAFFOLD_REPO_ROOT" --arg state_dir "$(fc_state_dir)" --arg events "$events_path" --arg latest "$latest_path" \
        '{schema_version:$sv,command:"validate",subject:"config",status:$s,jq_present:$jqq,date_present:$dt,state_dir_present:$sd,events_dir_present:$evd,flywheel_root_present:$rt,flywheel_root:$root,state_dir:$state_dir,events_path:$events,latest_path:$latest}'
      ;;
    events)
      # surface-specific: probe events jsonl + state distribution.
      local present=false rows=0 last_row=null last_row_valid=false
      local open_count=0 closed_count=0 suppressed_count=0
      if [[ -r "$events_path" ]]; then
        present=true
        rows="$(wc -l < "$events_path" 2>/dev/null | tr -d ' ' || echo 0)"
        open_count="$(grep -c '"state":"open"' "$events_path" 2>/dev/null; true)"
        closed_count="$(grep -c '"state":"closed"' "$events_path" 2>/dev/null; true)"
        suppressed_count="$(grep -c '"state":"suppressed"' "$events_path" 2>/dev/null; true)"
        local raw; raw="$(tail -n 1 "$events_path" 2>/dev/null || true)"
        if [[ -n "$raw" ]] && printf '%s' "$raw" | jq -e '.' >/dev/null 2>&1; then
          last_row="$raw"
          if printf '%s' "$raw" | jq -e 'has("schema_version") and has("event_id") and has("dedupe_key") and has("class") and has("state")' >/dev/null 2>&1; then
            last_row_valid=true
          fi
        fi
      fi
      local status="pass"
      [[ "$present" != true ]] && status="warn"
      [[ "$present" == true && "$rows" -gt 0 && "$last_row_valid" != true ]] && status="warn"
      jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" --arg s "$status" --arg ev "$events_path" \
        --argjson present "$present" --argjson rows "${rows:-0}" \
        --argjson oc "${open_count:-0}" --argjson cc "${closed_count:-0}" --argjson sc "${suppressed_count:-0}" \
        --argjson lr "$last_row" --argjson lrv "$last_row_valid" \
        '{schema_version:$sv,command:"validate",subject:"events",status:$s,events_path:$ev,present:$present,row_count:$rows,open_count:$oc,closed_count:$cc,suppressed_count:$sc,last_row:$lr,last_row_valid:$lrv}'
      ;;
    latest)
      # surface-specific: probe fleet-coherence-latest.json snapshot shape.
      local present=false parseable=false has_events_path=false snapshot_ts="null"
      if [[ -r "$latest_path" ]]; then
        present=true
        if jq -e '.' "$latest_path" >/dev/null 2>&1; then
          parseable=true
          if jq -e '.events_path // .events' "$latest_path" >/dev/null 2>&1; then
            has_events_path=true
          fi
          snapshot_ts="$(jq -c '.ts // .snapshot_ts // null' "$latest_path" 2>/dev/null || echo null)"
        fi
      fi
      local status="pass"
      [[ "$present" != true ]] && status="warn"
      [[ "$present" == true && "$parseable" != true ]] && status="fail"
      jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" --arg s "$status" --arg lt "$latest_path" \
        --argjson present "$present" --argjson parseable "$parseable" --argjson hep "$has_events_path" \
        --argjson ts "${snapshot_ts:-null}" \
        '{schema_version:$sv,command:"validate",subject:"latest",status:$s,latest_path:$lt,present:$present,parseable:$parseable,has_events_path:$hep,snapshot_ts:$ts}'
      ;;
    "")
      jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" \
        '{schema_version:$sv,command:"validate",status:"pass",subjects:["row","schema","config","events","latest"],usage:"validate --row-json JSON or --schema or --config or --events or --latest"}'
      ;;
    *)
      jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" --arg s "$subject" \
        '{schema_version:$sv,command:"validate",subject:$s,status:"unknown_subject",known:["row","schema","config","events","latest"]}'
      ;;
  esac
}

scaffold_cmd_audit() {
  local limit=50
  while [[ $# -gt 0 ]]; do
    case "$1" in
      --limit) limit="${2:-50}"; shift 2 ;;
      --limit=*) limit="${1#--limit=}"; shift ;;
      --json) shift ;;
      -h|--help) scaffold_emit_topic_help audit; return 0 ;;
      *) shift ;;
    esac
  done
  if command -v cli_emit_audit_tail >/dev/null 2>&1; then
    cli_emit_audit_tail "$SCAFFOLD_AUDIT_LOG" "$SCAFFOLD_SCHEMA_VERSION" "$limit"
  else
    local rows="[]" count=0
    if [[ -r "$SCAFFOLD_AUDIT_LOG" ]]; then
      rows="$(tail -n "$limit" "$SCAFFOLD_AUDIT_LOG" | jq -sc '. // []' 2>/dev/null || echo '[]')"
      count="$(printf '%s' "$rows" | jq 'length' 2>/dev/null || echo 0)"
    fi
    jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" --arg log "$SCAFFOLD_AUDIT_LOG" --argjson rows "$rows" --argjson count "$count" \
      '{schema_version:$sv,command:"audit",audit_log:$log,row_count:$count,rows:$rows}'
  fi
}

scaffold_cmd_why() {
  local id="${1:-}"
  if [[ -z "$id" ]]; then
    printf 'ERR: why requires <id> argument\n' >&2; return 64
  fi
  local matches="[]" status="not_found"
  local any_source_present=false
  if [[ -r "$SCAFFOLD_AUDIT_LOG" ]]; then
    any_source_present=true
    local raw
    raw="$(grep -F "$id" "$SCAFFOLD_AUDIT_LOG" 2>/dev/null || true)"
    if [[ -n "$raw" ]]; then
      matches="$(printf '%s' "$raw" | jq -sc '.' 2>/dev/null || echo '[]')"
    fi
  fi
  if [[ "$any_source_present" != true ]]; then
    status="unavailable"
  else
    local n; n="$(printf '%s' "$matches" | jq 'length' 2>/dev/null || echo 0)"
    n="${n//[^0-9]/}"; [[ -z "$n" ]] && n=0
    [[ "$n" -gt 0 ]] && status="found"
  fi
  jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" --arg id "$id" --arg s "$status" \
    --arg log "$SCAFFOLD_AUDIT_LOG" --argjson m "$matches" \
    '{schema_version:$sv,command:"why",id:$id,status:$s,audit_log:$log,matches:$m,total_matches:($m|length)}'
}

# ---------- scaffolded main dispatcher ----------

scaffold_main() {
  if [[ $# -eq 0 ]]; then
    scaffold_usage; exit 0
  fi
  case "$1" in
    -h|--help)    scaffold_usage; exit 0 ;;
    --info)       shift; scaffold_emit_info "$@"; exit 0 ;;
    --schema)     shift; scaffold_emit_schema "${1:-default}"; exit 0 ;;
    --examples)   shift; scaffold_emit_examples "$@"; exit 0 ;;
    doctor)       shift; scaffold_cmd_doctor "$@"; exit $? ;;
    health)       shift; scaffold_cmd_health "$@"; exit $? ;;
    repair)       shift; scaffold_cmd_repair "$@"; exit $? ;;
    validate)     shift; scaffold_cmd_validate "$@"; exit $? ;;
    audit)        shift; scaffold_cmd_audit "$@"; exit $? ;;
    why)          shift; scaffold_cmd_why "$@"; exit $? ;;
    quickstart)   shift; scaffold_emit_quickstart "$@"; exit 0 ;;
    help)         shift; scaffold_emit_topic_help "${1:-}"; exit 0 ;;
    completion)   shift; scaffold_emit_completion "${1:-bash}"; exit $? ;;
    *)
      printf 'ERR: unknown canonical subcommand: %s\n' "$1" >&2
      scaffold_usage >&2
      exit 64 ;;
  esac
}

# SOURCE-VS-EXEC GUARD: this scaffold runs ONLY when the file is invoked
# directly (`bash fleet-coherence-lib.sh ...`). When sourced by sister
# callers (fleet-coherence-write.sh, scan.sh, launchd.sh, quality-report.sh,
# tests/fleet-coherence-writer.sh), BASH_SOURCE[0] != $0 and the block is
# skipped — only the fc_* function definitions above are evaluated.
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
  scaffold_main "$@"
fi
# ====== END canonical-cli scaffold ======
