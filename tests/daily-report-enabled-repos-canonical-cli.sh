#!/usr/bin/env bash
# tests/daily-report-enabled-repos-canonical-cli.sh
#
# Regression test for flywheel-jloib pilot — canonical-cli-scoping + doctor-mode
# upgrade of daily-report-enabled-repos.sh (first surface in fleet doctor-mode
# integration chain).
#
# Asserts:
#   1. bash -n syntax
#   2. canonical-cli-scoping checker passes (13/13)
#   3. each canonical surface returns valid JSON envelope
#   4. doctor distinguishes substrate health
#   5. repair --apply requires --idempotency-key (refuses bare --apply)
#   6. repair dry-run does not mutate filesystem
#   7. repair --apply --scope state mkdirs audit log dir, then second run is idempotent
#   8. audit log records the apply
#   9. validate config produces per-repo results
#   10. why <repo> distinguishes enabled vs disabled
#   11. backward-compat: --dry-run with no subcommand still runs
#
set -euo pipefail

SCRIPT="${DAILY_REPORT_ENABLED_BIN:-<flywheel-repo>/.flywheel/scripts/daily-report-enabled-repos.sh}"
CHECKER="${CANONICAL_CLI_CHECKER:-$HOME/.claude/skills/canonical-cli-scoping/scripts/check-cli-scoping.sh}"
TMP="$(mktemp -d "${TMPDIR:-/tmp}/dre-canonical-cli.XXXXXX")"
trap 'rm -rf "$TMP"' EXIT

[[ -x "$SCRIPT" ]] || { echo "FAIL: script not executable: $SCRIPT" >&2; exit 1; }

pass_count=0
fail_count=0
pass(){ printf 'PASS %s\n' "$1"; pass_count=$((pass_count + 1)); }
fail(){ printf 'FAIL %s\n' "$1" >&2; fail_count=$((fail_count + 1)); }

assert_jq() {
  local file="$1" expr="$2" label="$3"
  if jq -e "$expr" "$file" >/dev/null 2>&1; then
    pass "$label"
  else
    fail "$label"
    jq . "$file" >&2 || cat "$file" >&2
  fi
}

# 1. syntax
bash -n "$SCRIPT" && pass "01_bash_syntax" || fail "01_bash_syntax"

# 2. canonical-cli-scoping checker (13/13 pass)
mkdir -p "$TMP/bin"
ln -sf "$SCRIPT" "$TMP/bin/daily-report-enabled-repos.sh"
PATH="$TMP/bin:$PATH" bash "$CHECKER" daily-report-enabled-repos.sh >"$TMP/checker.txt" 2>&1
checker_rc=$?
if grep -q "Summary: 13 pass, 0 fail" "$TMP/checker.txt"; then
  pass "02_canonical_cli_scoping_13_of_13"
else
  fail "02_canonical_cli_scoping_13_of_13"
  cat "$TMP/checker.txt" >&2
fi
[[ "$checker_rc" -eq 0 ]] && pass "02b_checker_exit_0" || fail "02b_checker_exit_0"

# 3a. --info --json
"$SCRIPT" --info --json >"$TMP/info.json"
assert_jq "$TMP/info.json" \
  '.name == "daily-report-enabled-repos.sh" and .schema_version == "daily-report-enabled-repos/v1" and (.canonical_cli_surfaces | length) >= 10' \
  "03a_info_envelope"

# 3b. --schema (default)
"$SCRIPT" --schema >"$TMP/schema-default.json"
assert_jq "$TMP/schema-default.json" '.schema_version == "daily-report-enabled-repos/v1"' "03b_schema_default"

# 3c. --schema doctor
"$SCRIPT" --schema doctor >"$TMP/schema-doctor.json"
assert_jq "$TMP/schema-doctor.json" '.schema_version == "daily-report-enabled-repos.doctor/v1"' "03c_schema_doctor"

# 3d. --examples
"$SCRIPT" --examples >"$TMP/examples.json"
assert_jq "$TMP/examples.json" '(.examples | length) >= 5' "03d_examples_min_count"

# 4. doctor: substrate-health envelope
FLYWHEEL_DAILY_REPORT_AUDIT_LOG="$TMP/state/audit.jsonl" \
  "$SCRIPT" doctor >"$TMP/doctor.json" 2>"$TMP/doctor.err" || true
assert_jq "$TMP/doctor.json" \
  '.schema_version == "daily-report-enabled-repos.doctor/v1" and (.checks | length) >= 4 and (.status | IN("pass","warn","fail"))' \
  "04_doctor_envelope_shape"
assert_jq "$TMP/doctor.json" \
  'any(.checks[]; .name == "audit_log_dir" and .status == "warn")' \
  "04b_doctor_warns_on_missing_audit_dir"

# 5. repair --apply without --idempotency-key MUST refuse exit 3
set +e
FLYWHEEL_DAILY_REPORT_AUDIT_LOG="$TMP/state/audit.jsonl" \
  "$SCRIPT" repair --scope state --apply --json >"$TMP/repair-refused.json" 2>"$TMP/repair-refused.err"
refused_rc=$?
set -e
[[ "$refused_rc" -eq 3 ]] && pass "05a_repair_apply_no_key_exit_3" || fail "05a_repair_apply_no_key_exit_3 (rc=$refused_rc)"
assert_jq "$TMP/repair-refused.json" '.status == "refused" and (.reason | test("idempotency-key"))' "05b_repair_refused_envelope"

# 6. repair --dry-run state, no FS mutation
[[ ! -d "$TMP/state" ]] || rm -rf "$TMP/state"
FLYWHEEL_DAILY_REPORT_AUDIT_LOG="$TMP/state/audit.jsonl" \
  "$SCRIPT" repair --scope state --dry-run --json >"$TMP/repair-dry.json"
assert_jq "$TMP/repair-dry.json" '.status == "dry_run" and (.planned_actions | length) >= 1 and (.applied_actions | length) == 0' "06a_repair_dry_run_envelope"
[[ ! -d "$TMP/state" ]] && pass "06b_repair_dry_run_no_filesystem_mutation" || fail "06b_repair_dry_run_no_filesystem_mutation"

# 7a. repair --apply --scope state with key creates dir
FLYWHEEL_DAILY_REPORT_AUDIT_LOG="$TMP/state/audit.jsonl" \
  "$SCRIPT" repair --scope state --apply --idempotency-key "test-$$" --json >"$TMP/repair-apply.json"
assert_jq "$TMP/repair-apply.json" '.status == "applied" and (.idempotency_key | length) > 0 and (.applied_actions | length) >= 1' "07a_repair_apply_envelope"
[[ -d "$TMP/state" ]] && pass "07b_repair_apply_creates_state_dir" || fail "07b_repair_apply_creates_state_dir"

# 7c. second apply is idempotent (no new actions, dir already exists)
FLYWHEEL_DAILY_REPORT_AUDIT_LOG="$TMP/state/audit.jsonl" \
  "$SCRIPT" repair --scope state --apply --idempotency-key "test2-$$" --json >"$TMP/repair-apply2.json"
assert_jq "$TMP/repair-apply2.json" '.status == "applied" and (.applied_actions | length) == 0' "07c_repair_apply_is_idempotent"

# 8. audit log records the applies
[[ -f "$TMP/state/audit.jsonl" ]] && pass "08a_audit_log_exists" || fail "08a_audit_log_exists"
FLYWHEEL_DAILY_REPORT_AUDIT_LOG="$TMP/state/audit.jsonl" \
  "$SCRIPT" audit --json >"$TMP/audit.json"
assert_jq "$TMP/audit.json" '.status == "pass" and .row_count >= 2 and (.recent | length) >= 2' "08b_audit_records_applies"

# 9. validate config produces per-repo results envelope
"$SCRIPT" validate config --json >"$TMP/validate.json" 2>/dev/null || true
assert_jq "$TMP/validate.json" '.schema_version == "daily-report-enabled-repos.validate/v1" and (.results | length) >= 1' "09_validate_envelope"

# 10a. why on flywheel repo (always-enabled)
"$SCRIPT" why "$HOME/Developer/flywheel" >"$TMP/why-flywheel.json"
assert_jq "$TMP/why-flywheel.json" '.enabled == true and .has_flywheel == true' "10a_why_flywheel_enabled"

# 10b. why on /tmp (no .flywheel)
"$SCRIPT" why /tmp >"$TMP/why-tmp.json"
assert_jq "$TMP/why-tmp.json" '.enabled == false and .has_flywheel == false' "10b_why_tmp_not_enabled"

# 11. backward-compat: --dry-run with no subcommand
"$SCRIPT" --dry-run --json >"$TMP/run-dry.json"
assert_jq "$TMP/run-dry.json" '.command == "run" and (.repos | length) >= 1 and (.failed | type) == "number"' "11_backward_compat_dry_run"

# Summary
echo
echo "Summary: $pass_count pass, $fail_count fail"
[[ "$fail_count" -eq 0 ]]
