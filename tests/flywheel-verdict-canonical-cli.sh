#!/usr/bin/env bash
set -euo pipefail

BIN="${FLYWHEEL_VERDICT_BIN:-$HOME/.claude/skills/.flywheel/bin/flywheel-verdict}"
CHECKER="${CANONICAL_CLI_CHECKER:-$HOME/.claude/skills/canonical-cli-scoping/scripts/check-cli-scoping.sh}"
TMP="$(mktemp -d "${TMPDIR:-/tmp}/flywheel-verdict-cli.XXXXXX")"
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

export FLYWHEEL_DB="$TMP/state.db"
export FLYWHEEL_LOG="$TMP/flywheel.log"
sqlite3 "$FLYWHEEL_DB" <<'SQL'
CREATE TABLE deltas(id INTEGER PRIMARY KEY, source_id INTEGER, title TEXT);
CREATE TABLE sources(id INTEGER PRIMARY KEY, url TEXT);
CREATE TABLE joshua_verdicts(id INTEGER PRIMARY KEY, target_kind TEXT, target_id INTEGER, verdict TEXT, note TEXT, created_at TEXT DEFAULT CURRENT_TIMESTAMP);
CREATE TABLE events(id INTEGER PRIMARY KEY, kind TEXT, skill TEXT, duration_ms INTEGER, detail TEXT, created_at TEXT DEFAULT CURRENT_TIMESTAMP);
INSERT INTO sources(id, url) VALUES (1, 'https://example.com/source');
INSERT INTO deltas(id, source_id, title) VALUES (1, 1, 'fixture');
SQL

bash -n "$BIN" && pass "shell_syntax" || fail "shell_syntax"

db_before="$(shasum -a 256 "$FLYWHEEL_DB" | awk '{print $1}')"
"$BIN" --help >"$TMP/help.txt"
"$BIN" --dry-run --help >"$TMP/dry-help.txt"
db_after="$(shasum -a 256 "$FLYWHEEL_DB" | awk '{print $1}')"
assert_text "$TMP/help.txt" '^flywheel-verdict' "help_usage"
assert_text "$TMP/dry-help.txt" '^flywheel-verdict' "dry_help_usage"
if [[ "$db_before" == "$db_after" ]]; then pass "help_read_only_db"; else fail "help_read_only_db"; fi

"$BIN" --info --json >"$TMP/info.json"
assert_jq "$TMP/info.json" '.name == "flywheel-verdict" and .paths.state_db' "info_json"

"$BIN" --examples --json >"$TMP/examples.json"
assert_jq "$TMP/examples.json" '(.examples | length) >= 6' "examples_json"

"$BIN" quickstart --json >"$TMP/quickstart.json"
assert_jq "$TMP/quickstart.json" '.command == "quickstart" and .status == "ok" and (.steps | length) >= 4' "quickstart_json"

"$BIN" help repair --json >"$TMP/help-topic.json"
assert_jq "$TMP/help-topic.json" '.command == "help" and .topic == "repair"' "help_topic_json"

"$BIN" schema record --json >"$TMP/schema.json"
assert_jq "$TMP/schema.json" '.schema_version == "flywheel-verdict.canonical.v1" and .command == "record"' "schema_json"

"$BIN" completion bash >"$TMP/completion.bash"
assert_text "$TMP/completion.bash" 'complete -W' "completion_bash"

"$BIN" completion zsh >"$TMP/completion.zsh"
assert_text "$TMP/completion.zsh" '^compadd ' "completion_zsh"

"$BIN" doctor --json >"$TMP/doctor.json"
assert_jq "$TMP/doctor.json" '.command == "doctor" and .status == "OK"' "doctor_json"

"$BIN" health --json >"$TMP/health.json"
assert_jq "$TMP/health.json" '.command == "health" and .status == "OK" and .verdict_count == 0' "health_json"

"$BIN" health --watch -i 1 --json >"$TMP/health-watch.jsonl" &
watch_pid="$!"
sleep 2
kill "$watch_pid" >/dev/null 2>&1 || true
wait "$watch_pid" >/dev/null 2>&1 || true
if [[ "$(wc -l <"$TMP/health-watch.jsonl" | tr -d ' ')" -ge 1 ]]; then pass "health_watch_emits"; else fail "health_watch_emits"; fi

"$BIN" repair --scope state --dry-run --explain --idempotency-key 6flh-repair --json >"$TMP/repair-dry.json"
assert_jq "$TMP/repair-dry.json" '.command == "repair" and .dry_run == true and .explain == true and .idempotency_key == "6flh-repair" and (.actual_actions | length) == 0 and (.would_write | length) >= 1 and .audit_log' "repair_dry_run_contract"

"$BIN" validate db --json >"$TMP/validate.json"
assert_jq "$TMP/validate.json" '.command == "validate" and .status == "pass"' "validate_json"

"$BIN" audit --json >"$TMP/audit.json"
assert_jq "$TMP/audit.json" '.command == "audit" and (.rows | type) == "array"' "audit_json"

"$BIN" why verdict --json >"$TMP/why.json"
assert_jq "$TMP/why.json" '.command == "why" and .subject == "verdict"' "why_json"

"$BIN" --delta-id 1 --verdict thumbs_up --note fixture --dry-run --explain --idempotency-key 6flh-record --json >"$TMP/record-dry.json" 2>"$TMP/record-dry.err"
assert_jq "$TMP/record-dry.json" '.command == "record" and .dry_run == true and .cli_verdict == "thumbs_up" and .planned_actions[0].verdict == "keep" and (.actual_actions | length) == 0 and (.would_write | length) == 2 and .audit_log' "record_dry_run_alias_contract"

"$BIN" --source https://example.com/source --verdict skip --note fixture --explain --idempotency-key 6flh-actual --json >"$TMP/record-actual.json" 2>"$TMP/record-actual.err"
assert_jq "$TMP/record-actual.json" '.command == "record" and .status == "recorded" and .cli_verdict == "skip" and .actual_actions[0].verdict == "defer" and (.actual_actions | length) == 2 and .audit_log' "record_actual_alias_contract"

set +e
"$BIN" --definitely-not-a-real-flag >/dev/null 2>"$TMP/bad.err"
bad_rc=$?
set -e
if [[ "$bad_rc" -eq 2 ]]; then pass "usage_error_exit_2"; else fail "usage_error_exit_2"; fi

bash "$CHECKER" "$BIN" >"$TMP/check-cli-scoping.txt"
assert_text "$TMP/check-cli-scoping.txt" 'Summary: [0-9]+ pass, 0 fail' "canonical_checker"

# ===== Substantive fillin assertions (flywheel-wzjo9.1.4) =====

# 1. --info envelope carries the new audit_log path (added by fillin)
"$BIN" --info --json >"$TMP/info-2.json"
assert_jq "$TMP/info-2.json" '.paths.audit_log | type == "string" and length > 0' "info_audit_log_path"

# 2. doctor has 9 named substrate checks (lifted from 6 → 9)
"$BIN" doctor --json >"$TMP/doctor-checks.json"
assert_jq "$TMP/doctor-checks.json" '(.checks | length) >= 9 and ([.checks[].name] | contains(["state_db","dependency:jq","dependency:sqlite3","audit_log_writable","helper_lib_loaded"]))' "doctor_named_probes_9plus"

# 3. health surfaces audit-log staleness field (>24h warn)
"$BIN" health --json >"$TMP/health-2.json"
assert_jq "$TMP/health-2.json" '.audit_log_stale | type == "boolean"' "health_audit_log_stale"

# 4. repair supports new --scope audit-log
SCAFFOLD_AUDIT_LOG="$TMP/audit-out.jsonl" "$BIN" repair --scope audit-log --dry-run --json >"$TMP/repair-audit.json"
assert_jq "$TMP/repair-audit.json" '.command == "repair" and .scope == "audit-log" and .dry_run == true' "repair_scope_audit_log"

# 5. repair --apply without --idempotency-key is refused (canonical refusal contract)
set +e
SCAFFOLD_AUDIT_LOG="$TMP/audit-out.jsonl" "$BIN" repair --scope state --apply --json >"$TMP/repair-refused.json" 2>"$TMP/repair-refused.err"
refused_rc=$?
set -e
if [[ "$refused_rc" -eq 3 ]]; then pass "repair_apply_refused_without_idem_key"; else fail "repair_apply_refused_without_idem_key"; fi
assert_jq "$TMP/repair-refused.json" '.status == "refused" and (.reason | test("idempotency-key"))' "repair_refusal_envelope"

# 6. why has multi-resolution (found / not_found / unavailable)
"$BIN" why db --json >"$TMP/why-db.json"
assert_jq "$TMP/why-db.json" '.resolution | type == "string" and (. == "found" or . == "not_found" or . == "unavailable")' "why_multi_resolution"

# 7. cli_audit_append wired: doctor invocation appends a row to SCAFFOLD_AUDIT_LOG
audit_log="$TMP/audit-trace.jsonl"
: >"$audit_log"
SCAFFOLD_AUDIT_LOG="$audit_log" "$BIN" doctor --json >/dev/null
if [[ -s "$audit_log" ]] && jq -e '.action == "doctor"' "$audit_log" >/dev/null 2>&1; then pass "cli_audit_append_wired_doctor"; else fail "cli_audit_append_wired_doctor"; fi

# 8. cli_audit_append wired on record path too
SCAFFOLD_AUDIT_LOG="$audit_log" "$BIN" --delta-id 1 --verdict keep --idempotency-key 6flh-trace --json >/dev/null 2>&1 || true
if grep -q '"action":"record"' "$audit_log" 2>/dev/null; then pass "cli_audit_append_wired_record"; else fail "cli_audit_append_wired_record"; fi

# 9. schema --per-surface includes audit-row variant
"$BIN" schema audit-row --json >"$TMP/schema-audit-row.json"
assert_jq "$TMP/schema-audit-row.json" '.schema_version == "flywheel-verdict.canonical.v1" and .command == "audit-row" and (.required | type == "array")' "schema_audit_row"

printf 'SUMMARY pass=%d fail=%d\n' "$pass_count" "$fail_count"
[[ "$fail_count" -eq 0 ]]
