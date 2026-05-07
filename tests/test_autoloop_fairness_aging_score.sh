#!/usr/bin/env bash
set -euo pipefail

BIN="${FLYWHEEL_AUTOLOOP_BIN:-$HOME/.claude/skills/.flywheel/bin/flywheel-autoloop}"
TMP="$(mktemp -d "${TMPDIR:-/tmp}/autoloop-fairness.XXXXXX")"

pass_count=0
fail_count=0
pass() { printf 'PASS %s\n' "$1"; pass_count=$((pass_count + 1)); }
fail() { printf 'FAIL %s\n' "$1" >&2; fail_count=$((fail_count + 1)); }
assert_jq() {
  local file="$1" filter="$2" label="$3"
  if jq -e "$filter" "$file" >/dev/null; then pass "$label"; else fail "$label"; jq . "$file" >&2 || true; fi
}
assert_jq_repo() {
  local file="$1" repo="$2" filter="$3" label="$4"
  if jq -e --arg repo "$repo" "$filter" "$file" >/dev/null; then pass "$label"; else fail "$label"; jq . "$file" >&2 || true; fi
}
iso_ago() {
  local minutes="$1"
  date -u -v-"${minutes}"M +%Y-%m-%dT%H:%M:%SZ 2>/dev/null || date -u -d "-${minutes} minutes" +%Y-%m-%dT%H:%M:%SZ
}

mkdir -p "$TMP/home" "$TMP/fw/bin" "$TMP/fw/config" "$TMP/repo-a" "$TMP/repo-b" "$TMP/state"
cat >"$TMP/fw/bin/flywheel-check" <<'SH'
#!/usr/bin/env bash
cat "$AUTOLOOP_FIXTURE_CHECK_JSON"
SH
chmod +x "$TMP/fw/bin/flywheel-check"

repo_a="$TMP/repo-a"
repo_b="$TMP/repo-b"
jq -n --arg a "$repo_a" --arg b "$repo_b" '{
  scanned_git_repos:2,
  repos:[
    {repo:$a,status:"ready",next_owner:"agent",next_tick_override_present:false,dirty_count:40},
    {repo:$b,status:"ready",next_owner:"agent",next_tick_override_present:false,dirty_count:1}
  ]
}' >"$TMP/check.json"

for i in 1 2 3 4 5; do
  jq -nc --arg ts "$(iso_ago "$i")" --arg repo "$repo_a" '{ts:$ts,event:"autoloop_dispatch_sent",status:"pending",repo:$repo}' >>"$TMP/state/dispatch-log.jsonl"
done
jq -n --arg b "$repo_b" --arg ts "$(iso_ago 30)" '{schema_version:"flywheel-autoloop.repo-state.v1",repos:{($b):{last_run_at:$ts}}}' >"$TMP/state/repo-state.json"

HOME="$TMP/home" \
FLYWHEEL_HOME="$TMP/fw" \
FLYWHEEL_CHECK_CMD="$TMP/fw/bin/flywheel-check" \
FLYWHEEL_AUTOLOOP_STATE_DIR="$TMP/state" \
FLYWHEEL_AUTOLOOP_ROOT="$TMP" \
FLYWHEEL_AUTOLOOP_STARVATION_AGING_INTERVAL_SECONDS=60 \
AUTOLOOP_FIXTURE_CHECK_JSON="$TMP/check.json" \
  "$BIN" scan --dry-run --json >"$TMP/scan.json"

assert_jq_repo "$TMP/scan.json" "$repo_b" '.queue[0].repo == $repo' "starved_repo_selected_before_bursty_repo"
assert_jq_repo "$TMP/scan.json" "$repo_a" '.queue[] | select(.repo == $repo) | .fairness.runs_last_hour == 5 and .fairness.hourly_budget_exhausted == true' "bursty_repo_hourly_budget_exhausted"
assert_jq_repo "$TMP/scan.json" "$repo_b" '.queue[] | select(.repo == $repo) | .fairness.starvation_score >= 30' "starved_repo_accumulates_aging_score"

printf 'SUMMARY pass=%d fail=%d\n' "$pass_count" "$fail_count"
[[ "$fail_count" -eq 0 && "$pass_count" -ge 3 ]]
