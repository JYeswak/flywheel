#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd -P)"
WRITER="$ROOT/.flywheel/scripts/fleet-coherence-write.sh"
LIB="$ROOT/.flywheel/scripts/fleet-coherence-lib.sh"
FIXTURE="$ROOT/.flywheel/fixtures/fleet-coherence-events-v2.jsonl"
FIXTURE_VALIDATOR="$ROOT/.flywheel/fixtures/validate-fleet-coherence-fixtures.sh"
TMP="$(mktemp -d "${TMPDIR:-/tmp}/fleet-coherence-writer.XXXXXX")"
trap 'rm -rf "$TMP"' EXIT

pass_count=0
fail_count=0

pass() { printf 'PASS %s\n' "$1"; pass_count=$((pass_count + 1)); }
fail() { printf 'FAIL %s\n' "$1" >&2; fail_count=$((fail_count + 1)); }

line_count() {
  [[ -f "$1" ]] || { printf '0'; return 0; }
  wc -l <"$1" | tr -d ' '
}

assert_jq() {
  local file="$1" filter="$2" label="$3"
  if jq -e "$filter" "$file" >/dev/null; then
    pass "$label"
  else
    fail "$label"
    jq . "$file" >&2 || true
  fi
}

assert_file_contains() {
  local file="$1" pattern="$2" label="$3"
  if rg -F -q -- "$pattern" "$file"; then
    pass "$label"
  else
    fail "$label"
  fi
}

export FLYWHEEL_FLEET_COHERENCE_STATE_DIR="$TMP/state"
export FLYWHEEL_FLEET_COHERENCE_EVENTS="$TMP/state/fleet-coherence-events-v2.jsonl"
export FLYWHEEL_FLEET_COHERENCE_LATEST="$TMP/state/fleet-coherence-latest.json"
export FLYWHEEL_FLEET_COHERENCE_ARCHIVE_DIR="$TMP/state/archive"
export FLYWHEEL_FLEET_COHERENCE_MAX_ROWS=3
export FLYWHEEL_FLEET_COHERENCE_MAX_ARCHIVES=2
export FLYWHEEL_FLEET_COHERENCE_NOW="2026-05-07T00:00:00Z"

bash -n "$LIB" && pass "lib_syntax" || fail "lib_syntax"
bash -n "$WRITER" && pass "writer_syntax" || fail "writer_syntax"
"$FIXTURE_VALIDATOR" >/dev/null && pass "v2_fixtures_remain_valid" || fail "v2_fixtures_remain_valid"

"$WRITER" --info --json >"$TMP/info.json"
assert_jq "$TMP/info.json" \
  '.status == "ok" and .writer_contract == "fleet-coherence-writer/v1" and .l112_observed == "OK_fleet_coherence_writer"' \
  "info_reports_contract"
"$WRITER" --schema --json >"$TMP/schema.json"
assert_jq "$TMP/schema.json" \
  '.event_schema_version == 2 and .close_dedupe_suffix == ":closed" and (.required_top_level_fields | index("l61"))' \
  "schema_reports_v2_contract"

jq -c 'select(.record_type == "event")' "$FIXTURE" | sed -n '1p' >"$TMP/row1.json"
jq -c 'select(.record_type == "event")' "$FIXTURE" | sed -n '2p' >"$TMP/row2.json"
jq -c 'select(.record_type == "event")' "$FIXTURE" | sed -n '3p' >"$TMP/row3.json"

"$WRITER" append --row "$TMP/row1.json" --json >"$TMP/append1.json"
assert_jq "$TMP/append1.json" \
  '.status == "ok" and .latest_snapshot_written == true and .l112_observed == "OK_fleet_coherence_writer" and .append_receipt.idempotent_skip == false' \
  "first_append_receipt_ok"
jq empty "$FLYWHEEL_FLEET_COHERENCE_EVENTS" && pass "events_jsonl_valid_after_first_append" || fail "events_jsonl_valid_after_first_append"
[[ "$(line_count "$FLYWHEEL_FLEET_COHERENCE_EVENTS")" == "1" ]] && pass "first_append_writes_one_row" || fail "first_append_writes_one_row"
assert_jq "$FLYWHEEL_FLEET_COHERENCE_LATEST" \
  '.schema_version == "fleet-coherence-latest/v1" and .status == "ok" and .latest_event.event_id != null' \
  "latest_snapshot_written_after_first_append"

"$WRITER" append --row "$TMP/row2.json" --json >"$TMP/append2.json"
[[ "$(line_count "$FLYWHEEL_FLEET_COHERENCE_EVENTS")" == "2" ]] && pass "second_append_does_not_truncate" || fail "second_append_does_not_truncate"
jq -s 'length == 2' "$FLYWHEEL_FLEET_COHERENCE_EVENTS" >/dev/null && pass "second_append_preserves_both_rows" || fail "second_append_preserves_both_rows"

export FLYWHEEL_FLEET_COHERENCE_NOW="2026-05-07T00:00:10Z"
"$WRITER" close --row "$TMP/row1.json" --reason "test close" --json >"$TMP/close.json"
assert_jq "$TMP/close.json" '.state == "closed" and (.dedupe_key | endswith(":closed"))' "close_receipt_has_closed_suffix"
assert_jq "$FLYWHEEL_FLEET_COHERENCE_EVENTS" \
  'select(.state == "closed" and (.dedupe_key | endswith(":closed")) and .evidence.close_reason == "test close")' \
  "close_row_appended"
[[ "$(line_count "$FLYWHEEL_FLEET_COHERENCE_EVENTS")" == "3" ]] && pass "close_row_appends_without_truncating" || fail "close_row_appends_without_truncating"

printf '{bad-json\n' >>"$FLYWHEEL_FLEET_COHERENCE_EVENTS"
"$WRITER" doctor --json >"$TMP/doctor-corrupt.json"
assert_jq "$TMP/doctor-corrupt.json" \
  '.status == "warn" and .corrupt_row_count == 1 and .detector_runtime_drift_count == 1 and .detector_runtime_drift[0].class == "detector_runtime_drift"' \
  "corrupt_row_surfaces_as_runtime_drift_nonfatal"

"$WRITER" retention --json >"$TMP/retention1.json"
assert_jq "$TMP/retention1.json" '.retention.rotated == true and .retention.max_rows == 3 and .latest_snapshot_written == true' "retention_rotates_when_bounded"
jq empty "$FLYWHEEL_FLEET_COHERENCE_EVENTS" && pass "retention_rewrites_hot_log_with_valid_rows" || fail "retention_rewrites_hot_log_with_valid_rows"
[[ "$(line_count "$FLYWHEEL_FLEET_COHERENCE_EVENTS")" -le 3 ]] && pass "retention_keeps_hot_log_bounded" || fail "retention_keeps_hot_log_bounded"
find "$FLYWHEEL_FLEET_COHERENCE_ARCHIVE_DIR" -type f -name 'fleet-coherence-events-v2.jsonl.*' | rg -q . \
  && pass "retention_archives_previous_hot_log" \
  || fail "retention_archives_previous_hot_log"

export FLYWHEEL_FLEET_COHERENCE_NOW="2026-05-07T00:00:20Z"
"$WRITER" append --row "$TMP/row3.json" --json >"$TMP/append3.json"
assert_jq "$TMP/append3.json" '.retention.rotated == true and .status == "ok"' "append_applies_retention_after_write"
jq empty "$FLYWHEEL_FLEET_COHERENCE_EVENTS" && pass "events_jsonl_valid_after_retained_append" || fail "events_jsonl_valid_after_retained_append"
[[ "$(line_count "$FLYWHEEL_FLEET_COHERENCE_EVENTS")" == "3" ]] && pass "retained_append_keeps_max_rows" || fail "retained_append_keeps_max_rows"
assert_file_contains "$LIB" 'mktemp "$dir/.${base}.XXXXXX"' "latest_snapshot_uses_target_dir_mktemp"
assert_file_contains "$LIB" 'mv "$tmp" "$target"' "latest_snapshot_uses_atomic_mv"

printf 'OK_fleet_coherence_writer\n'
printf 'SUMMARY pass=%d fail=%d\n' "$pass_count" "$fail_count"
[[ "$fail_count" -eq 0 && "$pass_count" -ge 24 ]]
