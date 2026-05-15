#!/usr/bin/env bash
set -euo pipefail

BIN="${FLYWHEEL_REFRESH_SOURCE_BIN:-$HOME/.claude/skills/.flywheel/bin/flywheel-refresh-source}"
CHECKER="${CANONICAL_CLI_CHECKER:-$HOME/.claude/skills/canonical-cli-scoping/scripts/check-cli-scoping.sh}"
TMP="$(mktemp -d "${TMPDIR:-/tmp}/flywheel-refresh-source-cli.XXXXXX")"
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

assert_text() {
  local file="$1" pattern="$2" label="$3"
  if rg -q "$pattern" "$file"; then
    pass "$label"
  else
    fail "$label"
    sed -n '1,120p' "$file" >&2 || true
  fi
}

bash -n "$BIN" && pass "shell_syntax" || fail "shell_syntax"

db_before="$(shasum -a 256 "$HOME/.claude/skills/.flywheel/state.db" | awk '{print $1}')"
"$BIN" --help >"$TMP/help.txt"
"$BIN" --dry-run --help >"$TMP/dry-help.txt"
db_after="$(shasum -a 256 "$HOME/.claude/skills/.flywheel/state.db" | awk '{print $1}')"
assert_text "$TMP/help.txt" '^usage:' "help_usage"
assert_text "$TMP/dry-help.txt" '^usage:' "dry_run_help_usage"
if [[ "$db_before" == "$db_after" ]]; then pass "help_read_only_db"; else fail "help_read_only_db"; fi

"$BIN" --info --json >"$TMP/info.json"
assert_jq "$TMP/info.json" '.name == "flywheel-refresh-source" and .paths.audit_log' "info_json"

"$BIN" doctor --json >"$TMP/doctor.json" || true
assert_jq "$TMP/doctor.json" '.schema_version == "flywheel-refresh-source.doctor/v1" and .subsystems.db.path' "doctor_json"

"$BIN" health --json >"$TMP/health.json" || true
assert_jq "$TMP/health.json" '.schema_version == "flywheel-refresh-source.health/v1" and .health' "health_json"

"$BIN" repair --scope logs --dry-run --explain --idempotency-key pfpd-test --json >"$TMP/repair-dry.json"
assert_jq "$TMP/repair-dry.json" '.mode == "dry_run" and .explain == true and .idempotency_key == "pfpd-test" and (.planned_actions | length) >= 1 and (.actual_actions | length) == 0 and .audit_log' "repair_dry_run_contract"

"$BIN" --explain --idempotency-key pfpd-refresh refresh "$TMP/no-such-skill" --dry-run --json >"$TMP/refresh-dry.json"
assert_jq "$TMP/refresh-dry.json" '.mode == "dry_run" and .explain == true and .idempotency_key == "pfpd-refresh" and (.would_write | length) >= 1 and (.actual_actions | length) == 0 and .audit_log' "refresh_dry_run_contract"

"$BIN" validate skill-dir "$HOME/.claude/skills/agent-mail" --json >"$TMP/validate.json" || true
assert_jq "$TMP/validate.json" '.schema_version == "flywheel-refresh-source.validate/v1" and .thing == "skill-dir"' "validate_json"

"$BIN" audit --json >"$TMP/audit.json"
assert_jq "$TMP/audit.json" '.schema_version == "flywheel-refresh-source.audit/v1" and (.rows | type) == "array"' "audit_json"

"$BIN" why agent-mail --json >"$TMP/why.json"
assert_jq "$TMP/why.json" '.schema_version == "flywheel-refresh-source.why/v1" and .target == "agent-mail"' "why_json"

"$BIN" schema health --json >"$TMP/schema.json"
assert_jq "$TMP/schema.json" '.schema_version == "json-schema-draft-lite/v1" and (.command | test("health"))' "schema_json"

"$BIN" --examples --json >"$TMP/examples.json"
assert_jq "$TMP/examples.json" '(.examples | length) >= 4' "examples_json"

"$BIN" quickstart --json >"$TMP/quickstart.json"
assert_jq "$TMP/quickstart.json" '.status == "ok" and (.steps | length) >= 5' "quickstart_json"

"$BIN" help doctor --json >"$TMP/help-topic.json"
assert_jq "$TMP/help-topic.json" '.topic == "doctor" and (.content | test("Diagnose"))' "help_topic_json"

"$BIN" completion bash >"$TMP/completion.bash"
assert_text "$TMP/completion.bash" 'complete -F _flywheel_refresh_source_complete flywheel-refresh-source' "completion_bash"

bash "$CHECKER" "$BIN" >"$TMP/check-cli-scoping.txt"
assert_text "$TMP/check-cli-scoping.txt" 'Summary: 13 pass, 0 fail' "canonical_checker"

printf 'SUMMARY pass=%d fail=%d\n' "$pass_count" "$fail_count"
[[ "$fail_count" -eq 0 ]]
