#!/usr/bin/env bash
set -euo pipefail

BIN="${FLYWHEEL_AUTOLOOP_BIN:-$HOME/.claude/skills/.flywheel/bin/flywheel-autoloop}"
TMP="$(mktemp -d "${TMPDIR:-/tmp}/autoloop-explain.XXXXXX")"

pass_count=0
fail_count=0
pass() { printf 'PASS %s\n' "$1"; pass_count=$((pass_count + 1)); }
fail() { printf 'FAIL %s\n' "$1" >&2; fail_count=$((fail_count + 1)); }
assert_jq() {
  local file="$1" filter="$2" label="$3"
  if jq -e "$filter" "$file" >/dev/null; then pass "$label"; else fail "$label"; jq . "$file" >&2 || true; fi
}

mkdir -p "$TMP/home" "$TMP/fw/bin" "$TMP/repo"
cat >"$TMP/fw/bin/flywheel-check" <<'SH'
#!/usr/bin/env bash
cat "$AUTOLOOP_FIXTURE_CHECK_JSON"
SH
chmod +x "$TMP/fw/bin/flywheel-check"

repo="$TMP/repo"
jq -n --arg repo "$repo" '{scanned_git_repos:1,repos:[{repo:$repo,status:"ready",next_owner:"agent",next_tick_override_present:false,dirty_count:12,open_beads:2}]}' >"$TMP/check.json"

HOME="$TMP/home" \
FLYWHEEL_HOME="$TMP/fw" \
FLYWHEEL_CHECK_CMD="$TMP/fw/bin/flywheel-check" \
FLYWHEEL_AUTOLOOP_STATE_DIR="$TMP/state" \
FLYWHEEL_AUTOLOOP_ROOT="$TMP" \
AUTOLOOP_FIXTURE_CHECK_JSON="$TMP/check.json" \
  "$BIN" explain --repo "$repo" --json >"$TMP/explain.json"

assert_jq "$TMP/explain.json" '.schema_version == "flywheel-autoloop.explain.v1" and .command == "explain"' "explain_schema"
assert_jq "$TMP/explain.json" '.signal_values.status_ready and .computed_score >= 80 and (.threshold == "dispatch-eligible" or .threshold == "priority")' "explain_score_fields"
assert_jq "$TMP/explain.json" '.cooldown_remaining_sec == 0 and .next_action == "dispatch"' "explain_next_action_dispatch"
assert_jq "$TMP/explain.json" '.no_event_db_reason == "event_state_db_not_found" and .event_state.integrated == false' "explain_event_state_reason"

printf 'SUMMARY pass=%d fail=%d\n' "$pass_count" "$fail_count"
[[ "$fail_count" -eq 0 && "$pass_count" -ge 4 ]]
