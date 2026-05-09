#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd -P)"
DAILY="$ROOT/.flywheel/scripts/daily-report.sh"
ENABLED_RUNNER="$ROOT/.flywheel/scripts/daily-report-enabled-repos.sh"
LOOP="${FLYWHEEL_LOOP_BIN:-$HOME/.claude/skills/.flywheel/bin/flywheel-loop}"
PROMOTE="$ROOT/.flywheel/scripts/doctor-signal-bead-promotion.sh"
TMP="$(mktemp -d "${TMPDIR:-/tmp}/daily-report-test.XXXXXX")"
trap 'rm -rf "$TMP"' EXIT

pass_count=0
fail_count=0

pass() { printf 'PASS %s\n' "$1"; pass_count=$((pass_count + 1)); }
fail() { printf 'FAIL %s\n' "$1"; fail_count=$((fail_count + 1)); }

assert_file_contains() {
  local file="$1" pattern="$2" label="$3"
  if grep -Eq "$pattern" "$file"; then
    pass "$label"
  else
    fail "$label"
    sed -n '1,220p' "$file" || true
  fi
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

make_repo() {
  local repo="$1"
  mkdir -p "$repo/.flywheel" "$repo/.beads"
  git -C "$repo" init -q >/dev/null 2>&1
  printf '# Mission\n\nstatus: ready\n' >"$repo/.flywheel/MISSION.md"
  printf '# Goal\n\nstatus: ready\n' >"$repo/.flywheel/GOAL.md"
  printf '# State\n\nstatus: ready\n' >"$repo/.flywheel/STATE.md"
  printf 'daily_report_dir\t.flywheel/reports\tflywheel-o7dq\tDaily narrative report output directory.\n' >"$repo/.flywheel/canonical-paths.txt"
}

write_br() {
  local bin="$1" payload="$2" ready="$3"
  printf '%s\n' \
    '#!/usr/bin/env bash' \
    'if [ "$1" = "ready" ]; then' \
    "  cat '$ready'" \
    'elif [ "$1" = "list" ]; then' \
    "  cat '$payload'" \
    'elif [ "$1" = "show" ]; then' \
    '  printf "[]\n"' \
    'elif [ "$1" = "create" ]; then' \
    '  printf "{\"id\":\"flywheel-daily-report-fixture\"}\n"' \
    'elif [ "$1" = "update" ]; then' \
    '  printf "{\"id\":\"updated\"}\n"' \
    'else' \
    '  printf "{}\n"' \
    'fi' >"$bin"
  chmod +x "$bin"
}

date_today="2026-05-04"
empty_log="$TMP/empty.jsonl"
touch "$empty_log"

bash -n "$DAILY" && pass "daily_report_shell_syntax" || fail "daily_report_shell_syntax"
bash -n "$ENABLED_RUNNER" && pass "daily_report_enabled_runner_shell_syntax" || fail "daily_report_enabled_runner_shell_syntax"
python3 -m py_compile "$ROOT/.flywheel/scripts/daily-report.py" && pass "daily_report_python_syntax" || fail "daily_report_python_syntax"
plutil -lint "$HOME/Library/LaunchAgents/ai.zeststream.flywheel-daily-report.plist" >/dev/null && pass "daily_report_launchd_plist_lint" || fail "daily_report_launchd_plist_lint"

zero_repo="$TMP/zero"
make_repo "$zero_repo"
printf '{"issues":[]}\n' >"$TMP/zero-list.json"
printf '{"issues":[]}\n' >"$TMP/zero-ready.json"
write_br "$TMP/br-zero" "$TMP/zero-list.json" "$TMP/zero-ready.json"
printf '{"status":"ok","ticks_punted_count":0}\n' >"$TMP/doctor-ok.json"
BR_BIN="$TMP/br-zero" FLYWHEEL_DAILY_REPORT_NOW="${date_today}T12:00:00Z" \
  "$DAILY" --repo "$zero_repo" --date "$date_today" --doctor-json "$TMP/doctor-ok.json" \
  --dispatch-log "$empty_log" --fuckup-log "$empty_log" --cross-orch-log "$empty_log" \
  --jeff-digest "$empty_log" --incidents-file "$TMP/no-incidents.md" --no-notify --json >"$TMP/zero.out"
zero_report="$(jq -r '.report_path' "$TMP/zero.out")"
assert_jq "$TMP/zero.out" '.status == "pass" and .closed_today_count == 0 and .hard_blockers_count == 0' "zero_bead_day_json"
assert_file_contains "$zero_report" 'No beads closed today' "zero_bead_day_report"

stuck_repo="$TMP/stuck"
make_repo "$stuck_repo"
cat >"$TMP/stuck-list.json" <<'JSON'
{"issues":[{"id":"flywheel-stuck","title":"[daily-report] stuck fixture","status":"in_progress","priority":0,"updated_at":"2026-05-02T00:00:00Z"}]}
JSON
printf '{"issues":[]}\n' >"$TMP/stuck-ready.json"
write_br "$TMP/br-stuck" "$TMP/stuck-list.json" "$TMP/stuck-ready.json"
printf '{"status":"fail","ticks_punted_count":1}\n' >"$TMP/doctor-fail.json"
printf '{"schema_version":"flywheel.l70_punt_report.v1","status":"ok","event_count":2,"top_phrases":[["want me to",2]]}\n' >"$TMP/punt-report.json"
notify_log="$TMP/notify.log"
notify_bin="$TMP/notify"
printf '#!/usr/bin/env bash\nprintf "%%s\\n" "$*" >>"%s"\n' "$notify_log" >"$notify_bin"
chmod +x "$notify_bin"
BR_BIN="$TMP/br-stuck" FLYWHEEL_DAILY_REPORT_NOW="${date_today}T12:00:00Z" \
  FLYWHEEL_PUNT_PHRASE_REPORT_JSON_FILE="$TMP/punt-report.json" \
  "$DAILY" --repo "$stuck_repo" --date "$date_today" --doctor-json "$TMP/doctor-fail.json" \
  --dispatch-log "$empty_log" --fuckup-log "$empty_log" --cross-orch-log "$empty_log" \
  --jeff-digest "$empty_log" --incidents-file "$TMP/no-incidents.md" --notify --notify-bin "$notify_bin" --json >"$TMP/stuck.out"
stuck_report="$(jq -r '.report_path' "$TMP/stuck.out")"
assert_jq "$TMP/stuck.out" '.hard_blockers_count >= 2 and .notify_sent == true' "all_stuck_day_notifies"
assert_file_contains "$stuck_report" 'flywheel-stuck.*age>24h' "all_stuck_day_report"
assert_file_contains "$stuck_report" 'l70_punt_phrase_events_24h: 2' "punt_phrase_events_reported"
if grep -q 'FLYWHEEL DAILY BLOCKERS' "$notify_log"; then pass "notify_integration"; else fail "notify_integration"; fi

normal_repo="$TMP/normal"
make_repo "$normal_repo"
cat >"$TMP/normal-list.json" <<'JSON'
{"issues":[{"id":"flywheel-closed","title":"[doctrine] closed today","status":"closed","priority":1,"updated_at":"2026-05-04T08:00:00Z"},{"id":"flywheel-open","title":"[jeff] ready next","status":"open","priority":0,"updated_at":"2026-05-04T07:00:00Z"}]}
JSON
cat >"$TMP/normal-ready.json" <<'JSON'
{"issues":[{"id":"flywheel-open","title":"[jeff] ready next","status":"open","priority":0,"updated_at":"2026-05-04T07:00:00Z"}]}
JSON
write_br "$TMP/br-normal" "$TMP/normal-list.json" "$TMP/normal-ready.json"
memory_dir="$TMP/memory"
mkdir -p "$memory_dir"
printf '# memory\n' >"$memory_dir/feedback_daily_report_fixture.md"
dispatch_log="$TMP/dispatch.jsonl"
printf '%s\n' "{\"ts\":\"${date_today}T09:00:00Z\",\"event\":\"dispatch_sent\",\"pane\":2,\"callback_received_at\":\"${date_today}T09:10:00Z\"}" >"$dispatch_log"
fuckup_log="$TMP/fuckup.jsonl"
printf '%s\n' "{\"ts\":\"${date_today}T09:00:00Z\",\"trauma_class\":\"fixture-trauma\",\"severity\":\"medium\"}" >"$fuckup_log"
cross_log="$TMP/cross.jsonl"
printf '%s\n' "{\"ts\":\"${date_today}T09:00:00Z\",\"session\":\"mobile-eats\",\"event\":\"ack\"}" >"$cross_log"
jeff_log="$TMP/jeff.jsonl"
printf '%s\n' "{\"ts\":\"${date_today}T09:00:00Z\",\"title\":\"Jeff fixture release\"}" >"$jeff_log"
jeff_projection="$TMP/jeff-storage-projection.json"
jq -nc '{
  schema_version:"jeff-corpus-storage-projection/v1",
  verified_indexed_count:177,
  remaining_actual_count:0,
  scenario_remaining_count:92,
  projected_actual_remaining_gb:0,
  projected_scenario_remaining_gb:3.12,
  disk_free_gb:84,
  recommendation:"full_already_indexed_increase_headroom_first"
}' >"$jeff_projection"
incidents="$TMP/INCIDENTS.md"
printf 'Date: %s\n' "$date_today" >"$incidents"
BR_BIN="$TMP/br-normal" FLYWHEEL_DAILY_REPORT_NOW="${date_today}T12:00:00Z" \
  "$DAILY" --repo "$normal_repo" --date "$date_today" --doctor-json "$TMP/doctor-ok.json" \
  --memory-dir "$memory_dir" --dispatch-log "$dispatch_log" --fuckup-log "$fuckup_log" \
  --cross-orch-log "$cross_log" --jeff-digest "$jeff_log" --jeff-storage-projection "$jeff_projection" \
  --incidents-file "$incidents" --no-notify --json >"$TMP/normal.out"
normal_report="$(jq -r '.report_path' "$TMP/normal.out")"
assert_jq "$TMP/normal.out" '.closed_today_count == 1 and .ready_count == 1 and (.sections | length) == 6' "normal_day_json"
assert_file_contains "$normal_report" 'What shipped\?|What did we learn\?|What'\''s Jeff up to\?|Cross-orch state' "normal_day_sections"
assert_file_contains "$normal_report" 'Jeff fixture release' "normal_day_jeff_section"
assert_file_contains "$normal_report" 'jeff_corpus_storage_projection: full_already_indexed_increase_headroom_first' "normal_day_jeff_projection_section"
assert_jq "$TMP/normal.out" '.jeff_corpus_storage_projection.remaining_actual_count == 0 and .jeff_corpus_storage_projection.scenario_remaining_count == 92' "normal_day_projection_json"

FLYWHEEL_DOCTOR_NTM_HEALTH_DISABLED=1 "$LOOP" doctor --repo "$normal_repo" --json >"$TMP/doctor-recent.json" 2>/dev/null || true
assert_jq "$TMP/doctor-recent.json" '.daily_report.status == "not_applicable" and .daily_report.enabled == false and .daily_report_age_hours == null' "doctor_daily_report_config_missing_skips"

printf '{"enabled":false}\n' >"$normal_repo/.flywheel/daily-report-config.json"
FLYWHEEL_DOCTOR_NTM_HEALTH_DISABLED=1 "$LOOP" doctor --repo "$normal_repo" --json >"$TMP/doctor-disabled.json" 2>/dev/null || true
assert_jq "$TMP/doctor-disabled.json" '.daily_report.status == "not_applicable" and .daily_report.enabled == false and .daily_report_age_hours == null' "doctor_daily_report_disabled_skips"

printf '{"enabled":true}\n' >"$normal_repo/.flywheel/daily-report-config.json"
FLYWHEEL_DOCTOR_NTM_HEALTH_DISABLED=1 "$LOOP" doctor --repo "$normal_repo" --json >"$TMP/doctor-recent.json" 2>/dev/null || true
assert_jq "$TMP/doctor-recent.json" 'has("daily_report_age_hours") and .daily_report.status == "pass"' "doctor_daily_report_recent"

old_repo="$TMP/old"
make_repo "$old_repo"
printf '{"enabled":true}\n' >"$old_repo/.flywheel/daily-report-config.json"
mkdir -p "$old_repo/.flywheel/reports"
printf '# old\n' >"$old_repo/.flywheel/reports/daily-2026-05-01.md"
touch -t 202001010101 "$old_repo/.flywheel/reports/daily-2026-05-01.md"
FLYWHEEL_DOCTOR_NTM_HEALTH_DISABLED=1 "$LOOP" doctor --repo "$old_repo" --json >"$TMP/doctor-old.json" 2>/dev/null || true
assert_jq "$TMP/doctor-old.json" '.daily_report.status == "fail" and .daily_report_age_hours > 36' "doctor_daily_report_age_fail"

runner_root="$TMP/runner-root"
enabled_repo="$runner_root/enabled"
disabled_repo="$runner_root/disabled"
missing_config_repo="$runner_root/missing-config"
make_repo "$enabled_repo"
make_repo "$disabled_repo"
make_repo "$missing_config_repo"
printf '{"enabled":true}\n' >"$enabled_repo/.flywheel/daily-report-config.json"
printf '{"enabled":false}\n' >"$disabled_repo/.flywheel/daily-report-config.json"
rm -f "$missing_config_repo/.flywheel/daily-report-config.json"
FLYWHEEL_DAILY_REPORT_REPO_ROOTS="$runner_root" "$ENABLED_RUNNER" --dry-run --json >"$TMP/enabled-runner.out"
assert_jq "$TMP/enabled-runner.out" '.generated == 1 and .skipped == 2 and ([.repos[] | select(.status == "would_generate") | .repo] | length) == 1' "enabled_runner_scopes_to_opted_in_repos"

fake_br="$TMP/br-promote"
write_br "$fake_br" "$TMP/zero-list.json" "$TMP/zero-ready.json"
doctor_json="$(jq -nc '{status:"fail",daily_report:{status:"fail",daily_report_age_hours:99,latest_report:null}}')"
BR_BIN="$fake_br" DOCTOR_SIGNAL_DOCTOR_JSON="$doctor_json" "$PROMOTE" "$normal_repo" >"$TMP/promote.out"
assert_jq "$TMP/promote.out" '.actions[]? | test("daily_report")' "doctor_promotion_daily_report"

printf '\nSummary: %s passed, %s failed\n' "$pass_count" "$fail_count"
[[ "$fail_count" -eq 0 ]]
