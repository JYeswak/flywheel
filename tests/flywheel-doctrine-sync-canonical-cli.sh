#!/usr/bin/env bash
set -euo pipefail

BIN="${FLYWHEEL_DOCTRINE_SYNC_BIN:-$HOME/.claude/skills/.flywheel/bin/flywheel-doctrine-sync}"
CHECKER="${CANONICAL_CLI_CHECKER:-$HOME/.claude/skills/canonical-cli-scoping/scripts/check-cli-scoping.sh}"
TMP="$(mktemp -d "${TMPDIR:-/tmp}/flywheel-doctrine-sync-cli.XXXXXX")"
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

export FLYWHEEL_CANONICAL_DOCTRINE_PATH="$TMP/canonical/AGENTS.md"
export FLYWHEEL_DOCTRINE_DEVELOPER_ROOT="$TMP/dev"
export FLYWHEEL_DOCTRINE_SYNC_LOG="$TMP/state/doctrine-sync.log"
export FLYWHEEL_DOCTRINE_SYNC_LEDGER="$TMP/state/doctrine-sync-ledger.jsonl"

mkdir -p "$TMP/canonical" "$TMP/dev/repo/.flywheel"
printf '# Canonical\n\n## L48 fixture\n' >"$FLYWHEEL_CANONICAL_DOCTRINE_PATH"
printf '# Local\n\n## L48 fixture\n' >"$TMP/dev/repo/AGENTS.md"
printf '{}\n' >"$TMP/dev/repo/.flywheel/loop.json"

bash -n "$BIN" && pass "shell_syntax" || fail "shell_syntax"

"$BIN" --help >"$TMP/help.txt"
assert_text "$TMP/help.txt" '^usage:' "help_usage"

"$BIN" --info --json >"$TMP/info.json"
assert_jq "$TMP/info.json" '.name == "flywheel-doctrine-sync" and .runtime_sha256 and .paths.ledger' "info_json"

"$BIN" --examples --json >"$TMP/examples.json"
assert_jq "$TMP/examples.json" '(.examples | length) >= 6' "examples_json"

"$BIN" quickstart --json >"$TMP/quickstart.json"
assert_jq "$TMP/quickstart.json" '.status == "ok" and (.steps | length) >= 5' "quickstart_json"

"$BIN" help repair --json >"$TMP/help-topic.json"
assert_jq "$TMP/help-topic.json" '.topic == "repair" and (.text | test("Topics"))' "help_topic_json"

"$BIN" schema quickstart --json >"$TMP/schema.json"
assert_jq "$TMP/schema.json" '.schema_version == "flywheel-doctrine-sync.canonical.v1" and .command == "quickstart"' "schema_json"

"$BIN" completion bash >"$TMP/completion.bash"
assert_text "$TMP/completion.bash" 'complete -W' "completion_bash"

"$BIN" completion zsh >"$TMP/completion.zsh"
assert_text "$TMP/completion.zsh" '^compadd ' "completion_zsh"

"$BIN" doctor --json >"$TMP/doctor.json"
assert_jq "$TMP/doctor.json" '.command == "doctor" and .status == "pass" and .subsystems.canonical.status == "ok"' "doctor_json"

"$BIN" health --json >"$TMP/health.json"
assert_jq "$TMP/health.json" '.command == "health" and .status == "pass"' "health_json"

"$BIN" health --watch -i 1 --json >"$TMP/health-watch.jsonl" &
watch_pid="$!"
sleep 2
kill "$watch_pid" >/dev/null 2>&1 || true
wait "$watch_pid" >/dev/null 2>&1 || true
if [[ "$(wc -l <"$TMP/health-watch.jsonl" | tr -d ' ')" -ge 1 ]]; then pass "health_watch_emits"; else fail "health_watch_emits"; fi

"$BIN" repair --scope state --dry-run --explain --idempotency-key ynys-repair --json >"$TMP/repair-dry.json"
assert_jq "$TMP/repair-dry.json" '.command == "repair" and .dry_run == true and .explain == true and .idempotency_key == "ynys-repair" and (.actual_actions | length) == 0 and (.would_write | length) == 0 and .audit_log' "repair_dry_run_contract"

"$BIN" --dry-run --explain --idempotency-key ynys-sync --json >"$TMP/sync-dry.json"
assert_jq "$TMP/sync-dry.json" '.command == "sync" and .mode == "dry_run" and .explain == true and .idempotency_key == "ynys-sync" and (.planned_actions | length) >= 1 and (.actual_actions | length) == 0 and .audit_log' "sync_dry_run_contract"

"$BIN" validate canonical --json >"$TMP/validate.json"
assert_jq "$TMP/validate.json" '.command == "validate" and .target == "canonical" and .status == "pass"' "validate_json"

"$BIN" audit 5 --json >"$TMP/audit.json"
assert_jq "$TMP/audit.json" '.command == "audit" and (.rows | type) == "array"' "audit_json"

"$BIN" why ledger --json >"$TMP/why.json"
assert_jq "$TMP/why.json" '.command == "why" and .subject == "ledger" and .refs.ledger' "why_json"

set +e
"$BIN" --definitely-not-a-real-flag >/dev/null 2>"$TMP/bad.err"
bad_rc=$?
set -e
if [[ "$bad_rc" -eq 2 ]]; then pass "usage_error_exit_2"; else fail "usage_error_exit_2"; fi

bash "$CHECKER" "$BIN" >"$TMP/check-cli-scoping.txt"
assert_text "$TMP/check-cli-scoping.txt" 'Summary: 13 pass, 0 fail' "canonical_checker"

printf 'SUMMARY pass=%d fail=%d\n' "$pass_count" "$fail_count"
[[ "$fail_count" -eq 0 ]]
