#!/usr/bin/env bash
set -euo pipefail

BIN="${FLYWHEEL_AUTOLOOP_BIN:-$HOME/.claude/skills/.flywheel/bin/flywheel-autoloop}"
TMP="$(mktemp -d "${TMPDIR:-/tmp}/autoloop-digest.XXXXXX")"

pass_count=0
fail_count=0
pass() { printf 'PASS %s\n' "$1"; pass_count=$((pass_count + 1)); }
fail() { printf 'FAIL %s\n' "$1" >&2; fail_count=$((fail_count + 1)); }
assert_jq() {
  local file="$1" filter="$2" label="$3"
  if jq -e "$filter" "$file" >/dev/null; then pass "$label"; else fail "$label"; jq . "$file" >&2 || true; fi
}

mkdir -p "$TMP/home" "$TMP/fw/bin" "$TMP/repo-a" "$TMP/repo-b"
cat >"$TMP/fw/bin/flywheel-check" <<'SH'
#!/usr/bin/env bash
cat "$AUTOLOOP_FIXTURE_CHECK_JSON"
SH
chmod +x "$TMP/fw/bin/flywheel-check"

jq -n --arg a "$TMP/repo-a" --arg b "$TMP/repo-b" '{
  scanned_git_repos:2,
  repos:[
    {repo:$a,status:"ready",next_owner:"agent",next_tick_override_present:false,dirty_count:5},
    {repo:$b,status:"ready",next_owner:"agent",next_tick_override_present:false,dirty_count:2}
  ]
}' >"$TMP/check.json"

HOME="$TMP/home" \
FLYWHEEL_HOME="$TMP/fw" \
FLYWHEEL_CHECK_CMD="$TMP/fw/bin/flywheel-check" \
FLYWHEEL_AUTOLOOP_STATE_DIR="$TMP/state" \
FLYWHEEL_AUTOLOOP_DIGEST_DIR="$TMP/digests" \
FLYWHEEL_AUTOLOOP_ROOT="$TMP" \
AUTOLOOP_FIXTURE_CHECK_JSON="$TMP/check.json" \
  "$BIN" scan --json >"$TMP/scan.json"

digest="$TMP/digests/$(date -u +%F).jsonl"
test -s "$digest" && pass "digest_file_written" || fail "digest_file_written"
tail -n 1 "$digest" >"$TMP/digest-row.json"
assert_jq "$TMP/digest-row.json" '.schema_version == "flywheel-autoloop.queue-digest.v1" and .generated_at' "digest_schema"
assert_jq "$TMP/digest-row.json" '(.repo_rows | length) == 2 and all(.repo_rows[]; .repo_path and (.runs_today|type=="number") and (.deferrals|type=="number") and (.starvation_score|type=="number") and (.last_run_age_sec|type=="number"))' "digest_repo_rows"
assert_jq "$TMP/digest-row.json" '.summary_counts.repos_active == 2 and (.summary_counts.total_runs|type=="number") and (.summary_counts.repos_starved|type=="number")' "digest_summary_counts"

HOME="$TMP/home" \
FLYWHEEL_HOME="$TMP/fw" \
FLYWHEEL_AUTOLOOP_STATE_DIR="$TMP/state" \
FLYWHEEL_AUTOLOOP_DIGEST_DIR="$TMP/digests" \
  "$BIN" digest --json >"$TMP/digest-command.json"
assert_jq "$TMP/digest-command.json" '.schema_version == "flywheel-autoloop.queue-digest.v1" and .paths.digest' "digest_command_json"

printf 'SUMMARY pass=%d fail=%d\n' "$pass_count" "$fail_count"
[[ "$fail_count" -eq 0 && "$pass_count" -ge 5 ]]
