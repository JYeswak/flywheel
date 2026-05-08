#!/usr/bin/env bash
# validate-fleet-coherence-fixtures.sh
# Bead: flywheel-2te — Phase 0 fleet-coherence schema fixtures
# Acceptance gate: run this script, expect PASS exit 0
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd -P)"
FIXTURES_DIR="$ROOT/.flywheel/fixtures"
EVENTS_FILE="$FIXTURES_DIR/fleet-coherence-events-v2.jsonl"
SUPPRESSIONS_FILE="$FIXTURES_DIR/fleet-coherence-suppressions-v2.jsonl"

REQUIRED_CLASSES=(
  alert_channel_degraded
  codex_auth_expired_silent
  detector_runtime_drift
  dual_orchestrator_tick_loop
  fleet_mail_identity_invalid_or_missing
  loop_running_without_topology
  orchestrator_no_cadence
  pane_activity_misclassified
  pane_count_drift
  schedule_source_drift
  skill_version_drift
  sustained_operator_pause_exceeded
  topology_missing_unmanaged_session
  topology_stale_or_kind_mismatch
  worker_role_command_mismatch
)

MIN_ROWS_PER_CLASS=5
MIN_SUPPRESSIONS=5

PASS=0
FAIL=0

check() {
  local label="$1" result="$2"
  if [[ "$result" == "ok" ]]; then
    printf '  [OK]  %s\n' "$label"
    ((PASS++)) || true
  else
    printf '  [FAIL] %s — %s\n' "$label" "$result"
    ((FAIL++)) || true
  fi
}

printf '=== fleet-coherence fixture validator ===\n\n'

# 1. Files exist
[[ -f "$EVENTS_FILE" ]] && check "events file exists" "ok" || check "events file exists" "missing: $EVENTS_FILE"
[[ -f "$SUPPRESSIONS_FILE" ]] && check "suppressions file exists" "ok" || check "suppressions file exists" "missing: $SUPPRESSIONS_FILE"

# 2. Files are valid JSONL
if jq -c . "$EVENTS_FILE" >/dev/null 2>&1; then
  check "events JSONL is valid" "ok"
else
  check "events JSONL is valid" "jq parse failed"
fi

if jq -c . "$SUPPRESSIONS_FILE" >/dev/null 2>&1; then
  check "suppressions JSONL is valid" "ok"
else
  check "suppressions JSONL is valid" "jq parse failed"
fi

# 3. All event rows have record_type == event
bad_event_rt=$(jq -r 'select(.record_type != "event") | .event_id // "unknown"' "$EVENTS_FILE" | wc -l | tr -d ' ')
if [[ "$bad_event_rt" -eq 0 ]]; then
  check "all event rows have record_type=event" "ok"
else
  check "all event rows have record_type=event" "$bad_event_rt rows with wrong record_type"
fi

# 4. All suppression rows have record_type == suppression
bad_sup_rt=$(jq -r 'select(.record_type != "suppression") | .id // "unknown"' "$SUPPRESSIONS_FILE" | wc -l | tr -d ' ')
if [[ "$bad_sup_rt" -eq 0 ]]; then
  check "all suppression rows have record_type=suppression" "ok"
else
  check "all suppression rows have record_type=suppression" "$bad_sup_rt rows with wrong record_type"
fi

# 5. schema_version == 2 on all event rows
bad_sv=$(jq -r 'select(.schema_version != 2) | .event_id // "unknown"' "$EVENTS_FILE" | wc -l | tr -d ' ')
if [[ "$bad_sv" -eq 0 ]]; then
  check "all events have schema_version=2" "ok"
else
  check "all events have schema_version=2" "$bad_sv rows with wrong schema_version"
fi

# 6. Required fields present on every event row
REQUIRED_EVENT_FIELDS=(event_id schema_version record_type class detector detector_version confidence severity state session ts source_ts raw_source_refs dedupe_key l61 l62 l63 actions)
for field in "${REQUIRED_EVENT_FIELDS[@]}"; do
  missing=$(jq -r --arg f "$field" 'select(has($f) | not) | .event_id // "unknown"' "$EVENTS_FILE" | wc -l | tr -d ' ')
  if [[ "$missing" -eq 0 ]]; then
    check "event field present: $field" "ok"
  else
    check "event field present: $field" "$missing rows missing field"
  fi
done

# 7. Required fields present on every suppression row
REQUIRED_SUP_FIELDS=(id record_type class session allowed_classes dedupe_key_pattern created_at created_by expires_at review_due max_ttl reason source_event_id)
for field in "${REQUIRED_SUP_FIELDS[@]}"; do
  missing=$(jq -r --arg f "$field" 'select(has($f) | not) | .id // "unknown"' "$SUPPRESSIONS_FILE" | wc -l | tr -d ' ')
  if [[ "$missing" -eq 0 ]]; then
    check "suppression field present: $field" "ok"
  else
    check "suppression field present: $field" "$missing rows missing field"
  fi
done

# 8. High-severity suppressions must have bead_id or no_bead_reason
# (suppression rows linked to critical/error events must have one or the other)
bad_hisev=$(jq -r 'select((.bead_id == null) and (.no_bead_reason == null)) | .id // "unknown"' "$SUPPRESSIONS_FILE" | wc -l | tr -d ' ')
if [[ "$bad_hisev" -eq 0 ]]; then
  check "all suppressions have bead_id or no_bead_reason" "ok"
else
  check "all suppressions have bead_id or no_bead_reason" "$bad_hisev suppressions missing both"
fi

# 9. Each drift class has >= MIN_ROWS_PER_CLASS event rows
for cls in "${REQUIRED_CLASSES[@]}"; do
  count=$(jq -r --arg c "$cls" 'select(.class == $c) | .class' "$EVENTS_FILE" | wc -l | tr -d ' ')
  if [[ "$count" -ge "$MIN_ROWS_PER_CLASS" ]]; then
    check "class $cls has >=$MIN_ROWS_PER_CLASS rows ($count)" "ok"
  else
    check "class $cls has >=$MIN_ROWS_PER_CLASS rows" "only $count rows"
  fi
done

# 10. Total suppression count >= MIN_SUPPRESSIONS
sup_count=$(jq -r '.id' "$SUPPRESSIONS_FILE" | wc -l | tr -d ' ')
if [[ "$sup_count" -ge "$MIN_SUPPRESSIONS" ]]; then
  check "suppression count >=$MIN_SUPPRESSIONS ($sup_count)" "ok"
else
  check "suppression count >=$MIN_SUPPRESSIONS" "only $sup_count"
fi

# 11. l61 object has required sub-fields on all events
L61_FIELDS=(ntm_attempted agent_mail_attempted l61_pairing_status vault_token_validated)
for f in "${L61_FIELDS[@]}"; do
  missing=$(jq -r --arg f "$f" 'select(.l61 | has($f) | not) | .event_id // "unknown"' "$EVENTS_FILE" | wc -l | tr -d ' ')
  if [[ "$missing" -eq 0 ]]; then
    check "l61.$f present on all events" "ok"
  else
    check "l61.$f present on all events" "$missing rows missing l61.$f"
  fi
done

# 12. Smoke: jq compact parse round-trip
tmp_events=$(mktemp)
tmp_sups=$(mktemp)
jq -c . "$EVENTS_FILE" > "$tmp_events"
jq -c . "$SUPPRESSIONS_FILE" > "$tmp_sups"
events_orig=$(wc -l < "$EVENTS_FILE" | tr -d ' ')
events_rt=$(wc -l < "$tmp_events" | tr -d ' ')
sups_orig=$(wc -l < "$SUPPRESSIONS_FILE" | tr -d ' ')
sups_rt=$(wc -l < "$tmp_sups" | tr -d ' ')
rm -f "$tmp_events" "$tmp_sups"

if [[ "$events_orig" -eq "$events_rt" ]]; then
  check "events compact round-trip ($events_orig rows)" "ok"
else
  check "events compact round-trip" "row count changed: $events_orig -> $events_rt"
fi
if [[ "$sups_orig" -eq "$sups_rt" ]]; then
  check "suppressions compact round-trip ($sups_orig rows)" "ok"
else
  check "suppressions compact round-trip" "row count changed: $sups_orig -> $sups_rt"
fi

# Summary
printf '\n=== summary: %d passed, %d failed ===\n' "$PASS" "$FAIL"
if [[ "$FAIL" -eq 0 ]]; then
  printf 'PASS\n'
  exit 0
else
  printf 'FAIL\n'
  exit 1
fi
