#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd -P)"
BIN="$ROOT/.flywheel/scripts/fleet-coherence-quality-report.sh"
TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT

fail() {
  echo "FAIL: $*" >&2
  exit 1
}

assert_jq() {
  local file="$1"
  local expr="$2"
  jq -e "$expr" "$file" >/dev/null || fail "jq assertion failed: $expr"
}

bash -n "$BIN"

cat >"$TMP/latest.json" <<'JSON'
{"schema_version":"fleet-coherence-latest/v2","generated_at":"2026-05-08T12:00:00Z","session_count":3,"pane_count":8,"event_count":3}
JSON

cat >"$TMP/suppressions.jsonl" <<'JSONL'
{"suppression_id":"known-benign","class":"fleet_scan_heartbeat","reason":"fixture"}
JSONL

cat >"$TMP/events.jsonl" <<'JSONL'
{"schema_version":"fleet-coherence-event/v2","ts":"2026-05-08T11:45:00Z","class":"pane_count_drift","state":"open","severity":"error","dedupe_key":"pane-count:1","resend_after_ts":"2026-05-08T12:15:00Z","evidence":{"scan_duration_ms":1200,"status_duration_ms":200},"actions":{"would_l61":false,"would_bead":true}}
{"schema_version":"fleet-coherence-event/v2","ts":"2026-05-08T11:50:00Z","class":"fleet_scan_heartbeat","state":"closed","severity":"info","dedupe_key":"heartbeat:1","evidence":{"scan_duration_ms":800,"status_duration_ms":100},"actions":{"would_l61":false,"would_bead":false}}
not-json
{"schema_version":"fleet-coherence-event/v2","ts":"2026-05-08T11:58:00Z","class":"pane_count_drift","state":"open","severity":"warn","dedupe_key":"pane-count:1","evidence":{"scan_duration_ms":1500,"status_duration_ms":400},"actions":{"would_l61":false,"would_bead":true}}
JSONL

"$BIN" \
  --events-file "$TMP/events.jsonl" \
  --latest-file "$TMP/latest.json" \
  --suppressions-file "$TMP/suppressions.jsonl" \
  --window 24h \
  --now 2026-05-08T12:00:00Z \
  --output "$TMP/report.md" \
  --json >"$TMP/report.json"

assert_jq "$TMP/report.json" '.decision == "blocked"'
assert_jq "$TMP/report.json" '.total_rows == 3'
assert_jq "$TMP/report.json" '.malformed_rows == 1'
assert_jq "$TMP/report.json" '.class_rows.pane_count_drift.rows == 2'
assert_jq "$TMP/report.json" '.class_rows.pane_count_drift.would_bead == 2'
assert_jq "$TMP/report.json" '.p95_scan_time_s == 1.5'
assert_jq "$TMP/report.json" '.dedupe.duplicate_rows == 1'
assert_jq "$TMP/report.json" '.shadow_side_effects.real_l61_attempts == 0'

grep -q 'Rows Per Class' "$TMP/report.md" || fail "missing per-class table"
grep -q 'Phase 2a: BLOCKED' "$TMP/report.md" || fail "missing blocked decision"
grep -q 'malformed rows | 1' "$TMP/report.md" || fail "missing malformed row count"

cat >"$TMP/clean-events.jsonl" <<'JSONL'
{"schema_version":"fleet-coherence-event/v2","ts":"2026-05-08T11:45:00Z","class":"fleet_scan_heartbeat","state":"closed","severity":"info","dedupe_key":"heartbeat:1","evidence":{"scan_duration_ms":1200,"status_duration_ms":200},"actions":{"would_l61":false,"would_bead":false}}
{"schema_version":"fleet-coherence-event/v2","ts":"2026-05-08T11:50:00Z","class":"suppression_expiry","state":"closed","severity":"info","dedupe_key":"suppression:1","evidence":{"scan_duration_ms":800,"status_duration_ms":100},"actions":{"would_l61":false,"would_bead":false}}
JSONL

"$BIN" \
  --events-file "$TMP/clean-events.jsonl" \
  --latest-file "$TMP/latest.json" \
  --suppressions-file "$TMP/suppressions.jsonl" \
  --window 24h \
  --now 2026-05-08T12:00:00Z \
  --output "$TMP/clean-report.md" >/dev/null

grep -q 'Phase 2a: UNBLOCKED' "$TMP/clean-report.md" || fail "missing unblocked decision"

"$BIN" \
  --events-file "$TMP/clean-events.jsonl" \
  --latest-file "$TMP/latest.json" \
  --suppressions-file "$TMP/suppressions.jsonl" \
  --window 24h \
  --now 2026-05-08T12:00:00Z \
  --output "$TMP/dry-run-report.md" \
  --dry-run >/dev/null

[[ ! -e "$TMP/dry-run-report.md" ]] || fail "dry-run wrote report"

echo "PASS tests/fleet-coherence-quality-report.sh"
