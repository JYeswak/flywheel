#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd -P)"
BIN="${FLYWHEEL_LOOP_BIN:-$HOME/.claude/skills/.flywheel/bin/flywheel-loop}"
PROMOTE="$ROOT/.flywheel/scripts/doctor-signal-bead-promotion.sh"
FIXTURES="$ROOT/tests/fixtures/wire-or-explain-doctor"
TMP="$(mktemp -d "${TMPDIR:-/tmp}/wire-or-explain-doctor.XXXXXX")"
trap 'rm -rf "$TMP"' EXIT

pass_count=0
fail_count=0

pass() { printf 'PASS %s\n' "$1"; pass_count=$((pass_count + 1)); }
fail() { printf 'FAIL %s\n' "$1" >&2; fail_count=$((fail_count + 1)); }

run_doctor() {
  local ledger="$1" out="$2"
  shift 2
  env "$@" FLYWHEEL_WIRE_OR_EXPLAIN_LEDGER="$ledger" "$BIN" doctor --repo "$ROOT" --scope wire-or-explain --json >"$out"
}

run_wire_status() {
  local ledger="$1" out="$2"
  shift 2
  env "$@" FLYWHEEL_WIRE_OR_EXPLAIN_LEDGER="$ledger" "$BIN" wire-status --repo "$ROOT" --json >"$out"
}

assert_jq() {
  local file="$1" filter="$2" label="$3"
  if jq -e "$filter" "$file" >/dev/null; then
    pass "$label"
  else
    fail "$label"
    jq . "$file" || true
  fi
}

bash -n "$BIN" && pass "flywheel_loop_syntax"
bash -n "$PROMOTE" && pass "promotion_syntax"
bash -n "$HOME/.claude/skills/.flywheel/lib/wire.sh" && pass "wire_lib_syntax"

set +e
env FLYWHEEL_WIRE_OR_EXPLAIN_MODE=bootstrap FLYWHEEL_WIRE_OR_EXPLAIN_LEDGER="$TMP/missing.jsonl" \
  "$BIN" doctor --repo "$ROOT" --scope wire-or-explain --json >"$TMP/missing-bootstrap.json"
bootstrap_rc=$?
env FLYWHEEL_WIRE_OR_EXPLAIN_MODE=enforce FLYWHEEL_WIRE_OR_EXPLAIN_LEDGER="$TMP/missing.jsonl" \
  "$BIN" doctor --repo "$ROOT" --scope wire-or-explain --json >"$TMP/missing-enforce.json"
enforce_rc=$?
set -e
if [ "$bootstrap_rc" -eq 0 ]; then pass "missing_ledger_bootstrap_rc_warn"; else fail "missing_ledger_bootstrap_rc_warn"; fi
if [ "$enforce_rc" -ne 0 ]; then pass "missing_ledger_enforce_rc_error"; else fail "missing_ledger_enforce_rc_error"; fi
assert_jq "$TMP/missing-bootstrap.json" '.status == "warn" and .mode == "bootstrap" and .reason_code == "ledger_missing"' "missing_ledger_bootstrap_shape"
assert_jq "$TMP/missing-enforce.json" '.status == "error" and .mode == "enforce" and .auto_bead_promotion_trigger.enabled == true' "missing_ledger_enforce_shape"

run_doctor "$FIXTURES/base.jsonl" "$TMP/base.json" FLYWHEEL_WIRE_OR_EXPLAIN_OVERDUE_HOURS=99999
assert_jq "$TMP/base.json" '.counts_by_state.unwired == 1 and .counts_by_state.questionably_wired == 1 and .unresolved_count == 2 and .questionably_wired_count == 1' "counts_by_state_and_unresolved"
assert_jq "$TMP/base.json" '.top_actions | length == 2 and all(.[]; has("payload") | not) and all(.[]; has("metadata") | not)' "top_actions_redacted_shape"
assert_jq "$TMP/base.json" '.signals.unresolved_count.producer and .signals.overdue_count.measurement and .signals.skill_relay.consumer' "signals_have_producer_measurement_consumer"
run_wire_status "$FIXTURES/base.jsonl" "$TMP/wire-status-base.json" FLYWHEEL_WIRE_OR_EXPLAIN_OVERDUE_HOURS=99999
jq -n --slurpfile doctor "$TMP/base.json" --slurpfile status "$TMP/wire-status-base.json" '
  $doctor[0].counts_by_state == $status[0].counts_by_state
  and $doctor[0].unresolved_count == $status[0].unresolved_count
  and $doctor[0].overdue_count == $status[0].overdue_count
  and $doctor[0].top_actions == $status[0].top_actions
' >/dev/null && pass "wire_status_json_matches_doctor_counts_and_actions" || fail "wire_status_json_matches_doctor_counts_and_actions"
env FLYWHEEL_WIRE_OR_EXPLAIN_LEDGER="$FIXTURES/base.jsonl" FLYWHEEL_WIRE_OR_EXPLAIN_OVERDUE_HOURS=99999 \
  "$BIN" wire-status --repo "$ROOT" >"$TMP/wire-status-human.txt"
if [ "$(wc -l <"$TMP/wire-status-human.txt" | tr -d ' ')" -le 50 ]; then
  pass "wire_status_human_under_50_lines"
else
  fail "wire_status_human_under_50_lines"
  cat "$TMP/wire-status-human.txt" >&2
fi

set +e
run_doctor "$FIXTURES/overdue.jsonl" "$TMP/overdue.json" FLYWHEEL_WIRE_OR_EXPLAIN_OVERDUE_HOURS=0
overdue_rc=$?
set -e
if [ "$overdue_rc" -ne 0 ]; then pass "overdue_blocker_rc_error"; else fail "overdue_blocker_rc_error"; fi
assert_jq "$TMP/overdue.json" '.status == "error" and .overdue_count == 1 and .promotion_metadata.overdue_count == 1 and .auto_bead_promotion_trigger.enabled == true' "overdue_blocker_promotion_metadata"

set +e
run_doctor "$FIXTURES/skill-relay-success.jsonl" "$TMP/skill-success.json" FLYWHEEL_WIRE_OR_EXPLAIN_OVERDUE_HOURS=99999
skill_success_rc=$?
run_doctor "$FIXTURES/skill-relay-failure.jsonl" "$TMP/skill-failure.json" FLYWHEEL_WIRE_OR_EXPLAIN_OVERDUE_HOURS=99999
skill_failure_rc=$?
set -e
if [ "$skill_success_rc" -eq 0 ]; then pass "skill_relay_success_rc_warn"; else fail "skill_relay_success_rc_warn"; fi
if [ "$skill_failure_rc" -ne 0 ]; then pass "skill_relay_failure_rc_error"; else fail "skill_relay_failure_rc_error"; fi
assert_jq "$TMP/skill-success.json" '.skill_candidate_backlog_count == 1 and .skill_candidate_unrelayed_count == 0 and any(.actions[]; .kind == "skill_relay" and .status == "pass")' "skill_relay_success_metrics"
assert_jq "$TMP/skill-failure.json" '.skill_candidate_relay_failure_count == 1 and any(.actions[]; .kind == "skill_relay" and .status == "error")' "skill_relay_failure_metrics"
run_wire_status "$FIXTURES/skill-relay-success.jsonl" "$TMP/wire-status-skill.json" FLYWHEEL_WIRE_OR_EXPLAIN_OVERDUE_HOURS=99999
assert_jq "$TMP/wire-status-skill.json" 'any(.top_actions[]; .artifact_class == "skill_candidate" and .relay_status == "sent" and .owner == "{capability-control-plane}") and any(.actions[]; .kind == "skill_relay")' "wire_status_skill_relay_first_class_action"
"$BIN" wire-status --schema --json >"$TMP/wire-status-schema.json"
assert_jq "$TMP/wire-status-schema.json" '.command == "wire-status" and .read_only_default == true and (.mutation_subcommands | index("defer")) and (.exit_codes."1" | test("doctor.*error"))' "wire_status_schema_and_exit_codes"
"$BIN" wire-status --info --json >"$TMP/wire-status-info.json"
assert_jq "$TMP/wire-status-info.json" '.command == "wire-status" and .mutation.default_read_only == true' "wire_status_info"
"$BIN" wire-status --examples --json >"$TMP/wire-status-examples.json"
assert_jq "$TMP/wire-status-examples.json" '.command == "wire-status" and (.examples | length) >= 5' "wire_status_examples"
"$BIN" wire-status help --json >"$TMP/wire-status-help.json"
assert_jq "$TMP/wire-status-help.json" '.command == "help" and (.text | test("Exit codes"))' "wire_status_help"
"$BIN" wire-status completion bash >"$TMP/wire-status-completion.bash"
rg -q '_flywheel_loop_wire_status_completion' "$TMP/wire-status-completion.bash" \
  && pass "wire_status_completion" || fail "wire_status_completion"
env FLYWHEEL_WIRE_OR_EXPLAIN_LEDGER="$FIXTURES/base.jsonl" FLYWHEEL_WIRE_OR_EXPLAIN_OVERDUE_HOURS=99999 \
  "$BIN" --explain wire-status --repo "$ROOT" --json >"$TMP/wire-status-explain.json"
assert_jq "$TMP/wire-status-explain.json" '.command == "wire-status" and .explain == true' "wire_status_explain"
"$BIN" wire-status validate --repo "$ROOT" --json >"$TMP/wire-status-validate.json"
assert_jq "$TMP/wire-status-validate.json" '.command == "validate" and .scope == "wire-or-explain"' "wire_status_validate"
"$BIN" wire-status audit --repo "$ROOT" --json >"$TMP/wire-status-audit.json"
assert_jq "$TMP/wire-status-audit.json" '.command == "wire-status" and .read_only_default == true and .raw_evidence_payloads_printed == false' "wire_status_audit"
"$BIN" wire-status why actions --repo "$ROOT" --json >"$TMP/wire-status-why.json"
assert_jq "$TMP/wire-status-why.json" '.command == "why" and .scope == "wire-or-explain" and .field == "actions"' "wire_status_why"
"$BIN" wire-status defer fixture-row --repo "$ROOT" --dry-run --json >"$TMP/wire-status-defer.json"
assert_jq "$TMP/wire-status-defer.json" '.command == "wire-status" and .subcommand == "defer" and .status == "dry_run" and .would_mutate == false' "wire_status_defer_dry_run"

run_doctor "$FIXTURES/secret-redaction.jsonl" "$TMP/secret.json" FLYWHEEL_WIRE_OR_EXPLAIN_OVERDUE_HOURS=99999
if ! rg -q 'SECRET_FIXTURE_SHOULD_NOT_APPEAR|RAW_PAYLOAD_SHOULD_NOT_APPEAR|raw_payload_excerpt|fixture_secret_value' "$TMP/secret.json"; then
  pass "secret_payload_not_emitted"
else
  fail "secret_payload_not_emitted"
  cat "$TMP/secret.json" >&2
fi

fake_br="$TMP/br"
printf '%s\n' \
  '#!/usr/bin/env bash' \
  'case "$1" in' \
  '  list) printf "{\"issues\":[]}\\n" ;;' \
  '  show) printf "[]\\n" ;;' \
  '  create) printf "{\"id\":\"flywheel-wire-doctor-fixture\"}\\n" ;;' \
  '  update) printf "{\"id\":\"updated\"}\\n" ;;' \
  '  *) printf "{}\\n" ;;' \
  'esac' >"$fake_br"
chmod +x "$fake_br"
doctor_json="$(jq -nc --slurpfile wire "$TMP/overdue.json" '{status:"ok",wire_or_explain:$wire[0]}')"
BR_BIN="$fake_br" DOCTOR_SIGNAL_DOCTOR_JSON="$doctor_json" "$PROMOTE" "$ROOT" >"$TMP/promote.json"
assert_jq "$TMP/promote.json" '.actions[]? | test("wire_or_explain")' "doctor_promotion_wire_or_explain_symptom"

full_timeout="${WIRE_OR_EXPLAIN_FULL_DOCTOR_TIMEOUT_SECONDS:-120}"
if env FLYWHEEL_DOCTOR_NTM_HEALTH_DISABLED=1 timeout "$full_timeout" "$BIN" doctor --repo "$ROOT" --json >"$TMP/full-doctor.json" 2>"$TMP/full-doctor.err"; then
  full_rc=0
else
  full_rc=$?
fi
if jq -e '.wire_or_explain' "$TMP/full-doctor.json" >/dev/null; then
  pass "full_doctor_exposes_wire_or_explain"
else
  fail "full_doctor_exposes_wire_or_explain rc=$full_rc"
  cat "$TMP/full-doctor.err" >&2 || true
  cat "$TMP/full-doctor.json" >&2 || true
fi

tail -n 1 "$ROOT/.flywheel/wire-or-explain-doctor/README.md" | grep -qx 'Part of the Yuzu Method framework by {operator-company}.' \
  && pass "doctor_readme_yuzu_footer" || fail "doctor_readme_yuzu_footer"

printf '\nSummary: %s passed, %s failed\n' "$pass_count" "$fail_count"
[[ "$fail_count" -eq 0 ]]
