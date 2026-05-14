#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd -P)"
BIN="<flywheel-state>/bin/flywheel-loop"
TMP="$(mktemp -d "${TMPDIR:-/tmp}/fleet-coherence-step4i.XXXXXX")"
trap 'rm -rf "$TMP"' EXIT

pass_count=0
fail_count=0

pass() { printf 'PASS %s\n' "$1"; pass_count=$((pass_count + 1)); }
fail() { printf 'FAIL %s\n' "$1" >&2; fail_count=$((fail_count + 1)); }

assert_jq() {
  local file="$1" expr="$2" label="$3"
  if jq -e "$expr" "$file" >/dev/null; then
    pass "$label"
  else
    fail "$label"
    jq . "$file" >&2 || true
  fi
}

cat >"$TMP/latest.json" <<'JSON'
{"schema_version":"fleet-coherence-latest/v1","generated_at":"2026-05-08T12:00:00Z","latest_event":{"event_id":"fc-open-latest","ts":"2026-05-08T12:00:00Z"}}
JSON

cat >"$TMP/suppressions.jsonl" <<'JSONL'
{"id":"sup-step4i","class":"suppressed_class","dedupe_key_pattern":"suppressed_class:*","reason":"fixture","expires_at":"2026-05-08T14:00:00Z"}
JSONL

cat >"$TMP/events.jsonl" <<'JSONL'
{"schema_version":"fleet-coherence-event/v2","event_id":"fc-open-old","ts":"2026-05-08T11:50:00Z","class":"open_class","severity":"warn","state":"open","dedupe_key":"open_class:flywheel:pane1","actions":{"receipt_required":true,"would_bead":true,"would_l61":true}}
{"schema_version":"fleet-coherence-event/v2","event_id":"fc-open-new","ts":"2026-05-08T11:55:00Z","class":"open_class","severity":"error","state":"still_open","dedupe_key":"open_class:flywheel:pane1","actions":{"receipt_required":true,"would_bead":true,"would_l61":true}}
{"schema_version":"fleet-coherence-event/v2","event_id":"fc-closed","ts":"2026-05-08T11:56:00Z","class":"closed_class","severity":"error","state":"closed","dedupe_key":"closed_class:flywheel:pane2","actions":{"receipt_required":false,"would_bead":false,"would_l61":false}}
{"schema_version":"fleet-coherence-event/v2","event_id":"fc-suppressed","ts":"2026-05-08T11:57:00Z","class":"suppressed_class","severity":"warn","state":"open","dedupe_key":"suppressed_class:flywheel:pane3","actions":{"receipt_required":true,"would_bead":true,"would_l61":true}}
not-json
JSONL

before_beads="$(shasum "$ROOT/.beads/issues.jsonl" | awk '{print $1}')"

bash -n "$BIN" && pass "flywheel_loop_syntax" || fail "flywheel_loop_syntax"

env \
  FLYWHEEL_AUTO_RESPAWN=0 \
  FLYWHEEL_FLEET_COHERENCE_EVENTS="$TMP/events.jsonl" \
  FLYWHEEL_FLEET_COHERENCE_LATEST="$TMP/latest.json" \
  FLYWHEEL_FLEET_COHERENCE_SUPPRESSIONS="$TMP/suppressions.jsonl" \
  FLYWHEEL_FLEET_COHERENCE_NOW_EPOCH=1778245201 \
  "$BIN" tick --repo "$ROOT" --dry-run --json >"$TMP/tick.json"

assert_jq "$TMP/tick.json" '.dry_run == true and .receipt_path == null' "tick_dry_run_no_receipt_file"
assert_jq "$TMP/tick.json" '.fleet_coherence_step4i.schema_version == "fleet-coherence-step4i-readonly/v1" and .fleet_coherence_step4i.mode == "read_only"' "step4i_schema_mode"
assert_jq "$TMP/tick.json" '.fleet_coherence_step4i.open_decision_count == 1 and .fleet_coherence_step4i.receipt_event_ids == ["fc-open-new"]' "dedupe_keeps_latest_open_event"
assert_jq "$TMP/tick.json" '.fleet_coherence_step4i.dedupe_duplicate_count == 1' "duplicate_count_recorded"
assert_jq "$TMP/tick.json" '.fleet_coherence_step4i.closed_count == 1 and (.fleet_coherence_step4i.closed_event_ids | index("fc-closed"))' "closed_rows_honored"
assert_jq "$TMP/tick.json" '.fleet_coherence_step4i.suppressed_count == 1 and (.fleet_coherence_step4i.suppressed_decisions[0].event_id == "fc-suppressed")' "suppressed_rows_honored"
assert_jq "$TMP/tick.json" '.fleet_coherence_step4i.malformed_rows == 1 and (.fleet_coherence_step4i.degraded_reasons | index("malformed_rows"))' "malformed_rows_reported"
assert_jq "$TMP/tick.json" '.fleet_coherence_step4i.latest_stale == true and (.fleet_coherence_step4i.degraded_reasons | index("latest_stale"))' "stale_latest_reported"
assert_jq "$TMP/tick.json" '.fleet_coherence_step4i.no_mutations == true and .fleet_coherence_step4i.br_create_executed == false and .fleet_coherence_step4i.no_bead_reason_finalized == false and .fleet_coherence_step4i.fleet_repair_dispatched == false' "phase3a_forbidden_actions_absent"

after_beads="$(shasum "$ROOT/.beads/issues.jsonl" | awk '{print $1}')"
if [[ "$before_beads" == "$after_beads" ]]; then
  pass "bead_db_not_mutated"
else
  fail "bead_db_not_mutated"
fi

if [[ "$fail_count" -eq 0 ]]; then
  printf 'PASS tests/fleet-coherence-step4i-readonly.sh (%s checks)\n' "$pass_count"
  exit 0
fi

printf 'FAIL tests/fleet-coherence-step4i-readonly.sh (%s failures, %s passes)\n' "$fail_count" "$pass_count" >&2
exit 1
