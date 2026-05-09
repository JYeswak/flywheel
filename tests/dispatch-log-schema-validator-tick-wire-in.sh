#!/usr/bin/env bash
# tests/dispatch-log-schema-validator-tick-wire-in.sh
# Bead flywheel-yu8g acceptance fixture: prove the validator and the doctor
# wrapper return PASS on v2-conformant rows and FAIL on missing required
# fields, with --tail N bounding the row sample.
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd -P)"
TMP="$(mktemp -d "${TMPDIR:-/tmp}/dispatch-log-schema-validator-tick-wire-in.XXXXXX")"
trap 'rm -rf "$TMP"' EXIT

VALIDATOR="$ROOT/.flywheel/scripts/dispatch-log-schema-validator.sh"
DOCTOR="$ROOT/.flywheel/scripts/dispatch-log-v2-violations-doctor.sh"
SCHEMA="$ROOT/.flywheel/validation-schema/v1/dispatch-log-entry-v2.schema.json"

pass_count=0
fail_count=0
pass() { pass_count=$((pass_count + 1)); printf 'PASS %s\n' "$1"; }
fail() { fail_count=$((fail_count + 1)); printf 'FAIL %s\n' "$1" >&2; }

assert_eq() {
  local label="$1" expected="$2" actual="$3"
  if [[ "$expected" == "$actual" ]]; then
    pass "$label"
  else
    fail "$label (expected=$expected actual=$actual)"
  fi
}

# Build a synthetic .flywheel layout the validator can read.
mkdir -p "$TMP/.flywheel/validation-schema/v1"
cp "$SCHEMA" "$TMP/.flywheel/validation-schema/v1/dispatch-log-entry-v2.schema.json"
LOG="$TMP/.flywheel/dispatch-log.jsonl"

valid_row() {
  jq -nc \
    --arg ts "$1" --arg task_id "$2" \
    '{
      task_id:$task_id,
      ts:$ts,
      from:"flywheel:1",
      to:"flywheel-pane-2",
      pane:2,
      session:"flywheel",
      task_summary:"valid v2 fixture",
      task_file:"/tmp/dispatch_fixture.md",
      agent_type:"codex",
      pane_state_source:"ntm_health",
      mission_anchor:"continuous-orchestrator-uptime-self-sustaining-fleet",
      mission_fitness_claim:"Directly enforces the mission anchor at dispatch time.",
      mission_fitness_class:"direct",
      idempotency_token:$task_id,
      callback_received_at:null,
      schema_version:2
    }'
}

# Test 1: clean v2 rows — validator and doctor both PASS, exit 0
{
  valid_row "2026-05-09T00:00:00Z" "fix-row-1"
  valid_row "2026-05-09T00:00:01Z" "fix-row-2"
  valid_row "2026-05-09T00:00:02Z" "fix-row-3"
} > "$LOG"

set +e
bash "$VALIDATOR" validate --repo "$TMP" --tail 3 --json >"$TMP/clean-validate.json" 2>/dev/null
clean_validator_exit=$?
set -e
assert_eq "validator exit 0 on 3 conformant v2 rows" 0 "$clean_validator_exit"
clean_invalid="$(jq -r '.invalid' "$TMP/clean-validate.json")"
assert_eq "validator invalid==0 on conformant rows" 0 "$clean_invalid"

set +e
bash "$DOCTOR" doctor --repo "$TMP" --tail 3 --json >"$TMP/clean-doctor.json" 2>/dev/null
clean_doctor_exit=$?
set -e
assert_eq "doctor wrapper exit 0 on conformant rows" 0 "$clean_doctor_exit"
clean_count="$(jq -r '.dispatch_log_v2_violations_count' "$TMP/clean-doctor.json")"
assert_eq "doctor wrapper count==0 on conformant rows" 0 "$clean_count"
clean_status="$(jq -r '.status' "$TMP/clean-doctor.json")"
assert_eq "doctor wrapper status=pass on conformant rows" pass "$clean_status"

# Test 2: append a row with missing required fields — validator + doctor FAIL
{
  valid_row "2026-05-09T00:00:00Z" "fix-row-1"
  valid_row "2026-05-09T00:00:01Z" "fix-row-2"
  jq -nc '{task_id:"missing-required-fields",ts:"2026-05-09T00:00:02Z"}'
} > "$LOG"

set +e
bash "$VALIDATOR" validate --repo "$TMP" --tail 3 --json >"$TMP/dirty-validate.json" 2>/dev/null
dirty_validator_exit=$?
set -e
assert_eq "validator exit 1 on row with missing required fields" 1 "$dirty_validator_exit"
dirty_invalid="$(jq -r '.invalid' "$TMP/dirty-validate.json")"
assert_eq "validator invalid==1 on dirty tail" 1 "$dirty_invalid"

set +e
bash "$DOCTOR" doctor --repo "$TMP" --tail 3 --json >"$TMP/dirty-doctor.json" 2>/dev/null
dirty_doctor_exit=$?
set -e
assert_eq "doctor wrapper exit 1 on dirty tail" 1 "$dirty_doctor_exit"
dirty_count="$(jq -r '.dispatch_log_v2_violations_count' "$TMP/dirty-doctor.json")"
assert_eq "doctor wrapper count==1 on dirty tail" 1 "$dirty_count"
dirty_status="$(jq -r '.status' "$TMP/dirty-doctor.json")"
assert_eq "doctor wrapper status=fail on dirty tail" fail "$dirty_status"

# Test 3: doctor wrapper field shape — required keys present
for key in schema_version status dispatch_log_v2_violations_count tail_size dispatch_log_v2_total_rows_checked log_present errors warnings; do
  if jq -e --arg k "$key" 'has($k)' "$TMP/clean-doctor.json" >/dev/null; then
    pass "doctor wrapper packet has key=$key"
  else
    fail "doctor wrapper packet missing key=$key"
  fi
done

# Test 4: tick.md cites the new step + the doctor wrapper script
TICK_MD="${FLYWHEEL_TICK_MD:-$HOME/.claude/commands/flywheel/tick.md}"
if [[ -r "$TICK_MD" ]]; then
  if grep -Fq "dispatch-log-v2-violations-doctor.sh" "$TICK_MD"; then
    pass "tick.md cites dispatch-log-v2-violations-doctor.sh"
  else
    fail "tick.md missing dispatch-log-v2-violations-doctor.sh reference"
  fi
  if grep -Fq "dispatch_log_v2_violations_count" "$TICK_MD"; then
    pass "tick.md cites dispatch_log_v2_violations_count field"
  else
    fail "tick.md missing dispatch_log_v2_violations_count reference"
  fi
else
  fail "tick.md not readable at $TICK_MD"
fi

if [[ "$fail_count" -gt 0 ]]; then
  printf 'SUMMARY pass=%d fail=%d\n' "$pass_count" "$fail_count" >&2
  exit 1
fi
printf 'SUMMARY pass=%d fail=0\n' "$pass_count"
