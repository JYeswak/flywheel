#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd -P)"
BIN="$ROOT/.flywheel/scripts/fleet-coherence-classifiers.sh"
INPUTS="$ROOT/.flywheel/fixtures/fleet-coherence-classifier-inputs.jsonl"
EVENTS="$ROOT/.flywheel/fixtures/fleet-coherence-events-v2.jsonl"
TMP="$(mktemp -d "${TMPDIR:-/tmp}/fleet-coherence-classifiers.XXXXXX")"
trap 'rm -rf "$TMP"' EXIT

PASS=0
FAIL=0

pass() { printf '[OK] %s\n' "$1"; PASS=$((PASS + 1)); }
fail() { printf '[FAIL] %s\n' "$1"; FAIL=$((FAIL + 1)); }

assert_jq() {
  local file="$1" expr="$2" label="$3"
  if jq -e "$expr" "$file" >/dev/null; then
    pass "$label"
  else
    fail "$label"
  fi
}

assert_jq_stream() {
  local file="$1" expr="$2" label="$3"
  if jq -s -e "$expr" "$file" >/dev/null; then
    pass "$label"
  else
    fail "$label"
  fi
}

required_classes=(
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

bash -n "$BIN" && pass "classifier shell syntax" || fail "classifier shell syntax"
bash -n "$ROOT/.flywheel/scripts/fleet-coherence-scan.sh" && pass "scanner shell syntax" || fail "scanner shell syntax"
jq empty "$INPUTS" && pass "classifier inputs jsonl valid" || fail "classifier inputs jsonl valid"
jq empty "$EVENTS" && pass "events fixture jsonl valid" || fail "events fixture jsonl valid"

"$BIN" --info --json >"$TMP/info.json"
assert_jq "$TMP/info.json" '.status == "ok" and .classifier_contract == "fleet-coherence-classifiers/v1" and .mutation_default == "none"' "info surface"

"$BIN" --schema --json >"$TMP/schema.json"
assert_jq "$TMP/schema.json" '.schedule_source_drift_cases == ["absent","duplicate","early","late","foreign"]' "schema schedule cases"

"$BIN" --doctor --json >"$TMP/doctor.json"
assert_jq "$TMP/doctor.json" '.status == "ok" and .mode == "doctor"' "doctor surface"

"$BIN" --health --json >"$TMP/health.json"
assert_jq "$TMP/health.json" '.status == "ok" and .mode == "health"' "health surface"

"$BIN" --validate --json >"$TMP/validate.json"
assert_jq "$TMP/validate.json" '.status == "ok" and .mode == "validate"' "validate surface"

"$BIN" --audit --json >"$TMP/audit.json"
assert_jq "$TMP/audit.json" '.rows >= 47 and .missing_classes == [] and (.schedule_cases | sort) == ["absent","duplicate","early","foreign","late"]' "audit surface"

"$BIN" --why --json >"$TMP/why.json"
assert_jq "$TMP/why.json" '.status == "ok" and (.reason | test("shadow mode"))' "why surface"

if "$BIN" --repair --json >"$TMP/repair.json"; then
  fail "repair refuses mutation"
else
  assert_jq "$TMP/repair.json" '.status == "refused" and .code == "NO_MUTATION_SURFACE"' "repair refuses mutation"
fi

"$BIN" --classify --json >"$TMP/out.jsonl"
jq empty "$TMP/out.jsonl" && pass "classifier output jsonl valid" || fail "classifier output jsonl valid"

assert_jq_stream "$TMP/out.jsonl" 'all(.[]; .schema_version == 2 and .record_type == "event" and .actions.shadow_mode == true)' "all outputs are v2 shadow events"
assert_jq_stream "$TMP/out.jsonl" 'all(.[]; .actions | has("would_l61") and has("would_bead") and has("would_no_bead_reason"))' "would action fields present"
assert_jq_stream "$TMP/out.jsonl" 'all(.[]; .actions.bead_id == null)' "no real bead actions emitted"
assert_jq_stream "$TMP/out.jsonl" 'all(.[]; (.confidence | type == "number") and (.raw_source_refs | type == "array") and (.dedupe_key | type == "string"))' "confidence raw refs dedupe grammar present"

for cls in "${required_classes[@]}"; do
  assert_jq_stream "$INPUTS" "any(.[]; .class == \"$cls\")" "input fixture class $cls"
  assert_jq_stream "$TMP/out.jsonl" "any(.[]; .class == \"$cls\")" "output class $cls"
  assert_jq_stream "$INPUTS" "any(.[]; .class == \"$cls\" and .fixture_state == \"open\")" "open fixture $cls"
  assert_jq_stream "$INPUTS" "any(.[]; .class == \"$cls\" and .fixture_state == \"closed\")" "closed fixture $cls"
  assert_jq_stream "$INPUTS" "any(.[]; .class == \"$cls\" and .fixture_state == \"suppressed\")" "suppressed fixture $cls"
done

for variant in absent duplicate early late foreign; do
  assert_jq_stream "$INPUTS" "any(.[]; .class == \"schedule_source_drift\" and .case == \"$variant\")" "schedule_source_drift $variant fixture"
done

assert_jq_stream "$INPUTS" 'any(.[]; .class == "schedule_source_drift" and (.observed.related_hashes // [] | index("91d8af29")) and (.observed.related_hashes // [] | index("38b88c74")))' "schedule fixture carries 91d8af29/38b88c74-style refs"
assert_jq_stream "$TMP/out.jsonl" 'all(.[] | select(.class | IN("dual_orchestrator_tick_loop","worker_role_command_mismatch","pane_count_drift","pane_activity_misclassified")); .evidence.source_quality.ntm_health_activity_authoritative == false and (.evidence.source_quality.pane_work_signal_present or .evidence.source_quality.hash_delta_present))' "pane work/hash-delta authoritative for work-state classes"

for cls in "${required_classes[@]}"; do
  assert_jq_stream "$EVENTS" "any(.[]; .class == \"$cls\")" "events v2 fixture class $cls"
done

printf 'PASS=%d FAIL=%d\n' "$PASS" "$FAIL"
if [[ "$FAIL" -eq 0 ]]; then
  printf 'PASS fleet-coherence-classifiers\n'
  exit 0
fi

printf 'FAIL fleet-coherence-classifiers\n'
exit 1
