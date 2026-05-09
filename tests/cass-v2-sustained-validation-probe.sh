#!/usr/bin/env bash
set -euo pipefail

BIN="${CASS_V2_PROBE_BIN:-$HOME/.local/bin/cass-v2-sustained-validation-probe}"
TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT

pass() { printf 'PASS %s\n' "$1"; }
fail() { printf 'FAIL %s\n' "$1"; exit 1; }
assert_jq() {
  local file="$1" expr="$2" label="$3"
  if jq -e "$expr" "$file" >/dev/null; then
    pass "$label"
  else
    jq . "$file" >&2 || true
    fail "$label"
  fi
}

mkdir -p "$TMP/repo-a" "$TMP/repo-b"
cat >"$TMP/hook.sh" <<'SH'
#!/usr/bin/env bash
printf 'MEMORY INTEGRITY: HEALTHY age=12s project=fixture-sha repo=%s\n' "${PROJECT:-unknown}"
SH
chmod +x "$TMP/hook.sh"

state="$TMP/cass-v2-sustained-validation.jsonl"
repos="$TMP/repo-a:$TMP/repo-b"

bash -n "$BIN" && pass "script syntax" || fail "script syntax"

"$BIN" --help | rg -q 'cass-v2-sustained-validation-probe \[command\]' \
  && pass "help emits usage" || fail "help emits usage"

"$BIN" --info --json --state-file "$state" --hook "$TMP/hook.sh" --repos "$repos" >"$TMP/info.json"
assert_jq "$TMP/info.json" '.command == "info" and .read_only_doctor == true and (.canonical_cli_flags | index("doctor"))' "info json canonical fields"

"$BIN" --schema --json >"$TMP/schema.json"
assert_jq "$TMP/schema.json" '.schema_version == "cass-v2-sustained-validation.canonical.v1" and (.fields | has("consecutive_healthy"))' "schema exposes doctor fields"

"$BIN" --doctor --json --state-file "$state" >"$TMP/doctor-empty.json"
assert_jq "$TMP/doctor-empty.json" '.command == "doctor" and .read_only == true and .count == 0 and (.warnings | index("state_file_missing"))' "doctor is read-only on missing state"
test ! -e "$state" && pass "doctor did not create state" || fail "doctor created state"

"$BIN" run --json --state-file "$state" --hook "$TMP/hook.sh" --repos "$repos" >"$TMP/run.json"
assert_jq "$TMP/run.json" '.command == "run" and .status == "ok" and .rows_appended == 2' "run appends rows"
test "$(wc -l <"$state" | tr -d ' ')" = "2" && pass "state has two rows" || fail "state row count"

"$BIN" doctor --json --state-file "$state" >"$TMP/doctor.json"
assert_jq "$TMP/doctor.json" '.status == "ok" and .count == 2 and .last_probe_ts and .consecutive_healthy == 2 and (.warnings | length) == 0' "doctor reports explicit status fields"

"$BIN" health --json --state-file "$state" >"$TMP/health.json"
assert_jq "$TMP/health.json" '.command == "health" and .status == "ok" and .count == 2' "health json"

"$BIN" validate state --json --state-file "$state" >"$TMP/validate.json"
assert_jq "$TMP/validate.json" '.command == "validate" and .thing == "state" and .valid == true' "validate state"

"$BIN" audit --json --state-file "$state" >"$TMP/audit.json"
assert_jq "$TMP/audit.json" '.command == "audit" and .count == 2 and (.rows | length) == 2' "audit rows"

"$BIN" why "$TMP/repo-b" --json --state-file "$state" >"$TMP/why.json"
assert_jq "$TMP/why.json" '.command == "why" and .latest_row.repo == "'"$TMP/repo-b"'"' "why repo"

"$BIN" --explain --idempotency-key fixture repair --scope state --dry-run --json --state-file "$TMP/new/state.jsonl" >"$TMP/repair.json"
assert_jq "$TMP/repair.json" '.command == "repair" and .dry_run == true and .explain == true and .idempotency_key == "fixture" and (.planned_actions | index("ensure_state_dir"))' "repair dry-run"

"$BIN" quickstart --json >"$TMP/quickstart.json"
assert_jq "$TMP/quickstart.json" '.command == "quickstart" and (.steps | length) >= 5' "quickstart json"

"$BIN" help doctor --json >"$TMP/help-topic.json"
assert_jq "$TMP/help-topic.json" '.command == "help" and .topic == "doctor"' "help topic"

"$BIN" completion bash >"$TMP/completion.bash"
rg -q 'complete -W' "$TMP/completion.bash" && pass "bash completion" || fail "bash completion"

bash "$HOME/.claude/skills/canonical-cli-scoping/scripts/check-cli-scoping.sh" cass-v2-sustained-validation-probe >"$TMP/check-cli.txt"
rg -q 'Summary: [0-9]+ pass, 0 fail' "$TMP/check-cli.txt" && pass "canonical CLI checker" || fail "canonical CLI checker"
