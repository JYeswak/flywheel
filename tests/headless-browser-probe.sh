#!/usr/bin/env bash
# shellcheck disable=SC2015,SC2016
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd -P)"
PROBE="$ROOT/.flywheel/scripts/headless-browser-probe.sh"
REAP="$ROOT/.flywheel/scripts/headless-browser-reap.sh"
PROMOTE="$ROOT/.flywheel/scripts/doctor-signal-bead-promotion.sh"
TMP="$(mktemp -d "${TMPDIR:-/tmp}/headless-browser-probe.XXXXXX")"
trap 'rm -rf "$TMP"' EXIT

pass_count=0
fail_count=0

pass() { printf 'PASS %s\n' "$1"; pass_count=$((pass_count + 1)); }
fail() { printf 'FAIL %s\n' "$1"; fail_count=$((fail_count + 1)); }

assert_jq() {
  local file="$1" filter="$2" label="$3"
  if jq -e "$filter" "$file" >/dev/null; then
    pass "$label"
  else
    fail "$label"
    jq . "$file" || true
  fi
}

date_for() {
  date -r "$1" '+%a %b %e %H:%M:%S %Y'
}

NOW="$(date +%s)"
RECENT="$(date_for $((NOW - 600)))"
OLD="$(date_for $((NOW - 7200)))"
AGENT_DIR="/var/folders/zz/flywheel-test/agent-browser-chrome-abc"
PRIMARY_DIR="$HOME/Library/Application Support/Google/Chrome"

line() {
  local pid="$1" start="$2" rss="$3" dir="$4"
  printf '%5s %5s %s %6s /Applications/Google Chrome.app/Contents/MacOS/Google Chrome --headless --user-data-dir=%s --remote-debugging-port=0\n' "$pid" 1 "$start" "$rss" "$dir"
}

bash -n "$PROBE" && pass "probe_syntax" || fail "probe_syntax"
bash -n "$REAP" && pass "reap_syntax" || fail "reap_syntax"

empty="$TMP/empty.ps"
touch "$empty"
"$PROBE" --fixture "$empty" --json >"$TMP/empty.json"
assert_jq "$TMP/empty.json" '.status == "pass" and .headless_agent_browser_count == 0 and .oldest_age_minutes == 0' "zero_processes_pass"

under="$TMP/under.ps"
line 101 "$RECENT" 10240 "$AGENT_DIR-1" >"$under"
line 102 "$RECENT" 20480 "$AGENT_DIR-2" >>"$under"
"$PROBE" --fixture "$under" --json >"$TMP/under.json"
assert_jq "$TMP/under.json" '.status == "pass" and .headless_agent_browser_count == 2 and .total_memory_mb == 30' "under_threshold_passes"

over="$TMP/over.ps"
for pid in 201 202 203 204 205 206; do
  line "$pid" "$RECENT" 4096 "$AGENT_DIR-$pid" >>"$over"
done
"$PROBE" --fixture "$over" --json >"$TMP/over.json"
assert_jq "$TMP/over.json" '.status == "fail" and .headless_agent_browser_count == 6 and any(.errors[]; .code == "agent_browser_count_high")' "over_count_fails"

old="$TMP/old.ps"
line 301 "$OLD" 4096 "$AGENT_DIR-old" >"$old"
"$PROBE" --fixture "$old" --json >"$TMP/old.json"
assert_jq "$TMP/old.json" '.status == "fail" and .oldest_age_minutes > 60 and any(.errors[]; .code == "agent_browser_oldest_age_high")' "oldest_age_fails"

primary="$TMP/primary.ps"
line 401 "$RECENT" 4096 "$PRIMARY_DIR" >"$primary"
line 402 "$RECENT" 4096 "$AGENT_DIR-real" >>"$primary"
"$PROBE" --fixture "$primary" --json >"$TMP/primary.json"
assert_jq "$TMP/primary.json" '.headless_agent_browser_count == 1 and (.agent_browser_processes[0].user_data_dir | contains("agent-browser-chrome"))' "primary_chrome_profile_excluded"

history="$TMP/reaps.jsonl"
"$REAP" --fixture "$over" --history "$history" --dry-run --json >"$TMP/reap.json"
assert_jq "$TMP/reap.json" '.dry_run == true and .candidate_count == 6 and (.killed_pids | length) == 0' "reap_dry_run_lists_candidates"
"$REAP" --fixture "$over" --history "$history" --apply --json >"$TMP/reap-apply.json"
if [[ -s "$history" ]] && jq -e '.version == "headless-browser-reap.v1" and .apply == true' "$history" >/dev/null; then
  pass "reap_history_append_apply_only"
else
  fail "reap_history_append_apply_only"
fi

fake_br="$TMP/br"
printf '%s\n' \
  '#!/usr/bin/env bash' \
  'case "$1" in' \
  '  list) printf "{\"issues\":[]}\\n" ;;' \
  '  show) printf "[]\\n" ;;' \
  '  create) printf "{\"id\":\"flywheel-headless-fixture\"}\\n" ;;' \
  '  update) printf "{\"id\":\"updated\"}\\n" ;;' \
  '  *) printf "{}\\n" ;;' \
  'esac' >"$fake_br"
chmod +x "$fake_br"
doctor_json="$(jq -nc --slurpfile agent_browser_leak "$TMP/over.json" '{status:"fail",agent_browser_leak:$agent_browser_leak[0]}')"
BR_BIN="$fake_br" DOCTOR_SIGNAL_DOCTOR_JSON="$doctor_json" "$PROMOTE" "$ROOT" >"$TMP/promote.json"
assert_jq "$TMP/promote.json" '.actions[]? | test("headless_browser")' "doctor_promotion_headless_browser_symptom"

printf '\nSummary: %s passed, %s failed\n' "$pass_count" "$fail_count"
[[ "$fail_count" -eq 0 ]]
