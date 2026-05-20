#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd -P)"
INPUTS="$ROOT/.flywheel/fixtures/fleet-coherence-classifier-inputs.jsonl"
EVENTS="$ROOT/.flywheel/fixtures/fleet-coherence-events-v2.jsonl"
MODE=classify
JSON=0
VERSION="fleet-coherence-classifiers/v1"

usage() {
  cat <<'EOF'
fleet-coherence-classifiers.sh [--classify] [--inputs PATH] [--events-file PATH] [--json]
fleet-coherence-classifiers.sh --info|--schema|--doctor|--health|--validate|--audit|--why|--repair [--json]
EOF
}

emit() {
  if [[ "$JSON" == 1 ]]; then
    jq -cS .
  else
    jq .
  fi
}

require_jq() {
  command -v jq >/dev/null 2>&1 || {
    jq -ncS '{schema_version:"fleet-coherence-classifiers/error/v1",status:"error",code:"JQ_MISSING"}'
    exit 127
  }
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --classify) MODE=classify; shift ;;
    --info) MODE=info; shift ;;
    --schema) MODE=schema; shift ;;
    --doctor) MODE=doctor; shift ;;
    --health) MODE=health; shift ;;
    --validate) MODE=validate; shift ;;
    --audit) MODE=audit; shift ;;
    --why) MODE=why; shift ;;
    --repair) MODE=repair; shift ;;
    --inputs) INPUTS="${2:?}"; shift 2 ;;
    --events-file) EVENTS="${2:?}"; shift 2 ;;
    --json) JSON=1; shift ;;
    -h|--help) usage; exit 0 ;;
    *) echo "unknown option: $1" >&2; exit 64 ;;
  esac
done

require_jq

required_classes_json() {
  jq -ncS '[
    "alert_channel_degraded",
    "codex_auth_expired_silent",
    "detector_runtime_drift",
    "dual_orchestrator_tick_loop",
    "fleet_mail_identity_invalid_or_missing",
    "loop_running_without_topology",
    "orchestrator_no_cadence",
    "pane_activity_misclassified",
    "pane_count_drift",
    "schedule_source_drift",
    "skill_version_drift",
    "sustained_operator_pause_exceeded",
    "topology_missing_unmanaged_session",
    "topology_stale_or_kind_mismatch",
    "worker_role_command_mismatch"
  ]'
}

validate_inputs() {
  [[ -f "$INPUTS" ]] || return 66
  jq -e '
    type == "object"
    and (.fixture_id | type == "string")
    and (.class | type == "string")
    and (.fixture_state | IN("open","closed","suppressed"))
    and (.case | type == "string")
    and (.observed | type == "object")
  ' "$INPUTS" >/dev/null
}

classify() {
  validate_inputs
  jq -cS --arg version "$VERSION" '
    def source_quality:
      if (.class | IN("dual_orchestrator_tick_loop","worker_role_command_mismatch","pane_count_drift","pane_activity_misclassified")) then
        {
          ntm_health_activity_authoritative: false,
          pane_work_signal_present: ((.signals | index("pane-work-signal")) != null),
          hash_delta_present: ((.signals | index("hash-delta")) != null)
        }
      else
        {
          ntm_health_activity_authoritative: false,
          pane_work_signal_present: ((.signals | index("pane-work-signal")) != null),
          hash_delta_present: ((.signals | index("hash-delta")) != null)
        }
      end;
    def event_state:
      if .fixture_state == "suppressed" then "open" else .fixture_state end;
    def severity:
      if .fixture_state == "closed" or .fixture_state == "suppressed" then "info"
      elif (.class | IN("alert_channel_degraded","fleet_mail_identity_invalid_or_missing","pane_activity_misclassified")) then "warn"
      else "error"
      end;
    def would_bead:
      (.fixture_state == "open" and (.class | IN(
        "dual_orchestrator_tick_loop",
        "worker_role_command_mismatch",
        "topology_stale_or_kind_mismatch",
        "topology_missing_unmanaged_session",
        "pane_count_drift",
        "schedule_source_drift",
        "codex_auth_expired_silent",
        "detector_runtime_drift",
        "loop_running_without_topology",
        "orchestrator_no_cadence",
        "skill_version_drift",
        "sustained_operator_pause_exceeded"
      )));
    {
      schema_version: 2,
      record_type: "event",
      class: .class,
      detector: "fleet-coherence",
      detector_version: $version,
      detector_git_sha: "shadow-fixture",
      event_id: ("fc_shadow_" + .fixture_id),
      dedupe_key: (.dedupe_key // (.class + ":" + (.session // "fleet") + ":" + .case)),
      classification_source: (.classification_source // "classifier-input-fixture"),
      confidence: (.confidence // 0.82),
      severity: severity,
      state: event_state,
      session: (.session // "fleet"),
      pane: (.pane // null),
      ts: (.ts // "2026-05-08T17:30:00Z"),
      source_ts: (.source_ts // "2026-05-08T17:29:30Z"),
      first_seen_ts: (.ts // "2026-05-08T17:30:00Z"),
      last_seen_ts: (.ts // "2026-05-08T17:30:00Z"),
      seen_count: 1,
      sample_count: (.sample_count // 1),
      sample_window_s: (.sample_window_s // 90),
      confidence: (.confidence // 0.82),
      source_age_s: (.source_age_s // 30),
      suppression_id: (if .fixture_state == "suppressed" then ("sup_" + .fixture_id) else null end),
      resend_after_ts: (if .fixture_state == "closed" or .fixture_state == "suppressed" then null else "2026-05-08T17:31:00Z" end),
      raw_source_refs: (.raw_source_refs // [{path: ("fixture://" + .fixture_id)}]),
      evidence: {
        fixture_name: .fixture_id,
        case: .case,
        observed: .observed,
        source_quality: source_quality,
        shadow_classifier_pack: true
      },
      actions: {
        shadow_mode: true,
        would_l61: (.fixture_state == "open" and (.would_l61 // true)),
        would_bead: would_bead,
        would_no_bead_reason: (if .fixture_state == "closed" then "closed_fixture_row" elif .fixture_state == "suppressed" then "suppressed_fixture_row" else null end),
        bead_id: null,
        no_bead_reason: (if .fixture_state == "closed" then "closed_fixture_row" elif .fixture_state == "suppressed" then "suppressed_fixture_row" else null end),
        receipt_required: (.fixture_state == "open")
      },
      l61: {
        ntm_attempted: false,
        ntm_pane: (.pane // null),
        ntm_session: (.session // null),
        ntm_result: null,
        ntm_sent_at: null,
        agent_mail_attempted: false,
        agent_mail_from: null,
        agent_mail_to: null,
        agent_mail_message_id: null,
        agent_mail_sent_at: null,
        l61_pairing_status: "not_attempted",
        degraded_reason: null,
        fleet_mail_identity_source: (.fleet_mail_identity_source // "fixture"),
        project_key: "/Users/josh/.local/state/flywheel/fleet-mail-project",
        vault_token_validated: false
      },
      l62: {repair_callback_required: false, sd_count: 0, sd_ids: []},
      l63: {recovery_action_requires_drill: (.class == "detector_runtime_drift"), recovery_drill_ids: (if .class == "detector_runtime_drift" then ["fixture-drill-required"] else [] end)}
    }
  ' "$INPUTS"
}

case "$MODE" in
  info)
    required="$(required_classes_json)"
    jq -ncS --arg version "$VERSION" --arg inputs "$INPUTS" --arg events "$EVENTS" --argjson classes "$required" '{
      schema_version:"fleet-coherence-classifiers-info/v1",
      status:"ok",
      classifier_contract:$version,
      inputs:$inputs,
      events_file:$events,
      required_classes:$classes,
      mutation_default:"none",
      output:"fleet-coherence-event/v2 shadow JSONL"
    }' | emit
    ;;
  schema)
    jq -ncS --arg version "$VERSION" '{
      schema_version:"fleet-coherence-classifiers/schema/v1",
      classifier_contract:$version,
      input_required:["fixture_id","class","fixture_state","case","observed"],
      output_required:["schema_version","record_type","class","confidence","raw_source_refs","dedupe_key","actions"],
      actions_required:["shadow_mode","would_l61","would_bead","would_no_bead_reason"],
      schedule_source_drift_cases:["absent","duplicate","early","late","foreign"]
    }' | emit
    ;;
  doctor|health|validate)
    if validate_inputs; then status=ok; rc=0; else status=fail; rc=1; fi
    required="$(required_classes_json)"
    jq -ncS --arg mode "$MODE" --arg status "$status" --arg inputs "$INPUTS" --argjson classes "$required" '{
      schema_version:"fleet-coherence-classifiers-check/v1",
      mode:$mode,
      status:$status,
      inputs:$inputs,
      required_class_count:($classes|length)
    }' | emit
    exit "$rc"
    ;;
  audit)
    required="$(required_classes_json)"
    jq -csS --argjson classes "$required" '
      {rows:length,
       class_count:([.[].class]|unique|length),
       missing_classes:($classes - ([.[].class]|unique)),
       schedule_cases:([.[]|select(.class=="schedule_source_drift")|.case]|unique),
       state_counts:(group_by(.fixture_state)|map({(.[0].fixture_state):length})|add)}
    ' "$INPUTS" | emit
    ;;
  why)
    jq -ncS '{
      schema_version:"fleet-coherence-classifiers-why/v1",
      status:"ok",
      reason:"Phase 1e runs in shadow mode: classify scanner-derived rows into would_* events without mutating beads, L61, or no-bead ledgers."
    }' | emit
    ;;
  repair)
    jq -ncS '{
      schema_version:"fleet-coherence-classifiers-repair/v1",
      status:"refused",
      code:"NO_MUTATION_SURFACE",
      reason:"classifier pack is read-only shadow mode; repair is intentionally not implemented"
    }' | emit
    exit 1
    ;;
  classify)
    classify
    ;;
esac

# Meta-Learning Cross-References (2026-05-19)
# Batch-16 comment backfill; citations are documentation-only and do not alter runtime behavior.
# Related: `/Users/josh/Developer/skillos/.flywheel/doctrine/meta-learnings/MP-19-flywheel-engagement-protocol.md`
# Related: `/Users/josh/Developer/skillos/.flywheel/doctrine/meta-learnings/MP-61-agent-first-operator-surface.md`
