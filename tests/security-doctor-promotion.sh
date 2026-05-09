#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd -P)"
PROMOTE="$ROOT/.flywheel/scripts/doctor-signal-bead-promotion.sh"
DAILY_PY="$ROOT/.flywheel/scripts/daily-report.py"
BR_BIN="${BR_BIN:-$HOME/.cargo/bin/br}"
TMP="$(mktemp -d "${TMPDIR:-/tmp}/security-doctor-promotion.XXXXXX")"
trap 'rm -rf "$TMP"' EXIT

pass_count=0
fail_count=0

pass() { printf 'PASS %s\n' "$1"; pass_count=$((pass_count + 1)); }
fail() { printf 'FAIL %s\n' "$1" >&2; fail_count=$((fail_count + 1)); }

assert_jq() {
  local file="$1" filter="$2" label="$3"
  if jq -e "$filter" "$file" >/dev/null; then
    pass "$label"
  else
    fail "$label"
    jq . "$file" >&2 || true
  fi
}

assert_jq_with_args() {
  local file="$1" label="$2"
  shift 2
  if jq -e "$@" "$file" >/dev/null; then
    pass "$label"
  else
    fail "$label"
    jq . "$file" >&2 || true
  fi
}

assert_file_contains() {
  local file="$1" pattern="$2" label="$3"
  if grep -Eq "$pattern" "$file"; then
    pass "$label"
  else
    fail "$label"
    sed -n '1,220p' "$file" >&2 || true
  fi
}

make_repo() {
  local repo="$1" prefix="${2:-fx}"
  mkdir -p "$repo/.flywheel" "$repo/.beads"
  git -C "$repo" init -q
  (cd "$repo" && "$BR_BIN" init --prefix "$prefix" >/dev/null)
}

write_br() {
  local bin="$1" payload="$2" ready="$3"
  printf '%s\n' \
    '#!/usr/bin/env bash' \
    'if [ "$1" = "ready" ]; then' \
    "  cat '$ready'" \
    'elif [ "$1" = "list" ]; then' \
    "  cat '$payload'" \
    'else' \
    '  printf "{}\n"' \
    'fi' >"$bin"
  chmod +x "$bin"
}

bash -n "$PROMOTE" && pass "promotion_shell_syntax" || fail "promotion_shell_syntax"
python3 -m py_compile "$DAILY_PY" && pass "daily_report_python_syntax" || fail "daily_report_python_syntax"

healthy_repo="$TMP/healthy"
make_repo "$healthy_repo"
jq -nc '{status:"pass",security:{status:"pass",settings_deny_rules_present:true,secret_path_deny_missing_count:0,leaked_secret_pattern_count:0,precommit_hook_installed:true,precommit_hook_missing_count:0,runtime_visible_secret_count:0}}' >"$TMP/healthy.json"
DOCTOR_SIGNAL_DOCTOR_JSON_FILE="$TMP/healthy.json" BR_BIN="$BR_BIN" "$PROMOTE" --repo "$healthy_repo" >"$TMP/healthy.out"
assert_jq "$TMP/healthy.out" '.action == "noop"' "healthy_security_fixture_noop"

leak_repo="$TMP/leak"
make_repo "$leak_repo"
jq -nc '{
  status:"fail",
  security:{
    status:"fail",
    leaked_secret_pattern_count:1,
    leaked_secret_pattern_classes:["openai_api_key"],
    leaked_secret_sample:"CANARY_TEST_OPENAI_SK_SHOULD_NOT_APPEAR"
  }
}' >"$TMP/leak.json"
DOCTOR_SIGNAL_DOCTOR_JSON_FILE="$TMP/leak.json" BR_BIN="$BR_BIN" "$PROMOTE" --repo "$leak_repo" >"$TMP/leak-first.out"
assert_jq "$TMP/leak-first.out" '.action == "promoted" and (.actions[] | test("created:.*:security_leaked_secret_patterns"))' "leaked_secret_creates_p0_bead"
leak_id="$(jq -r '.actions[] | select(test("created:.*:security_leaked_secret_patterns")) | split(":")[1]' "$TMP/leak-first.out")"
(cd "$leak_repo" && "$BR_BIN" show "$leak_id" --json) >"$TMP/leak-bead.json"
assert_jq "$TMP/leak-bead.json" '.[0].priority == 0 and (.[0].title | contains("[auto-doctor:security-leaked-secret-patterns]"))' "leaked_secret_bead_priority_and_title"
if jq -r '.[0].description // ""' "$TMP/leak-bead.json" | grep -F 'CANARY_TEST_OPENAI_SK_' >/dev/null; then
  fail "leaked_secret_description_redacts_values"
else
  pass "leaked_secret_description_redacts_values"
fi
DOCTOR_SIGNAL_DOCTOR_JSON_FILE="$TMP/leak.json" BR_BIN="$BR_BIN" "$PROMOTE" --repo "$leak_repo" >"$TMP/leak-second.out"
assert_jq_with_args "$TMP/leak-second.out" "leaked_secret_rerun_matches_existing" --arg id "$leak_id" '.actions[] | contains("matched:" + $id + ":security_leaked_secret_patterns")'

missing_repo="$TMP/missing"
make_repo "$missing_repo"
jq -nc '{
  status:"fail",
  security:{
    status:"fail",
    settings_deny_rules_present:false,
    secret_path_deny_missing_count:2,
    precommit_hook_installed:false,
    precommit_hook_missing_count:1,
    runtime_visible_status:"fail",
    runtime_visible_secret_count:1,
    runtime_secret_values_visible:true
  }
}' >"$TMP/missing.json"
DOCTOR_SIGNAL_DOCTOR_JSON_FILE="$TMP/missing.json" BR_BIN="$BR_BIN" "$PROMOTE" --repo "$missing_repo" >"$TMP/missing-first.out"
assert_jq "$TMP/missing-first.out" '[.actions[] | select(test("^created:.*:security_(missing_deny_rules|precommit_missing|runtime_visible_secrets)$"))] | length == 3' "missing_security_controls_create_class_beads"
DOCTOR_SIGNAL_DOCTOR_JSON_FILE="$TMP/missing.json" BR_BIN="$BR_BIN" "$PROMOTE" --repo "$missing_repo" >"$TMP/missing-second.out"
assert_jq "$TMP/missing-second.out" '[.actions[] | select(test("^matched:.*:security_(missing_deny_rules|precommit_missing|runtime_visible_secrets)$"))] | length == 3' "missing_security_controls_rerun_no_duplicates"

closed_repo="$TMP/recent-closed"
make_repo "$closed_repo"
closed_id="$(cd "$closed_repo" && "$BR_BIN" create "[auto-doctor:security-leaked-secret-patterns] fixture closed" --type bug --priority 0 --description fixture --json | jq -r '.id // .issue.id')"
(cd "$closed_repo" && "$BR_BIN" close "$closed_id" --reason fixture --json >/dev/null)
DOCTOR_SIGNAL_DOCTOR_JSON_FILE="$TMP/leak.json" BR_BIN="$BR_BIN" "$PROMOTE" --repo "$closed_repo" >"$TMP/recent-closed.out"
assert_jq_with_args "$TMP/recent-closed.out" "recent_closed_security_dedupe" --arg id "$closed_id" '.actions[] | contains("skipped:security_leaked_secret_patterns:recently_closed:" + $id)'

daily_repo="$TMP/daily"
make_repo "$daily_repo"
printf '{"issues":[]}\n' >"$TMP/daily-list.json"
printf '{"issues":[]}\n' >"$TMP/daily-ready.json"
write_br "$TMP/br-daily" "$TMP/daily-list.json" "$TMP/daily-ready.json"
jq -nc '{
  status:"fail",
  security:{
    status:"fail",
    leaked_secret_pattern_count:2,
    secret_path_deny_missing_count:1,
    precommit_hook_missing_count:1,
    runtime_visible_secret_count:1,
    top_failing_repos:[
      {repo:"alpha",status:"fail",leaked_secret_pattern_count:2},
      {repo:"beta",status:"warn"}
    ]
  }
}' >"$TMP/daily-doctor.json"
touch "$TMP/empty.jsonl"
BR_BIN="$TMP/br-daily" FLYWHEEL_DAILY_REPORT_NOW="2026-05-09T12:00:00Z" \
  "$DAILY_PY" --repo "$daily_repo" --date 2026-05-09 --doctor-json "$TMP/daily-doctor.json" \
  --dispatch-log "$TMP/empty.jsonl" --fuckup-log "$TMP/empty.jsonl" --cross-orch-log "$TMP/empty.jsonl" \
  --jeff-digest "$TMP/empty.jsonl" --incidents-file "$TMP/no-incidents.md" --no-notify --json >"$TMP/daily.out"
daily_report="$(jq -r '.report_path' "$TMP/daily.out")"
assert_jq "$TMP/daily.out" '.security_summary.status == "fail" and .security_summary.leaked_secret_pattern_count == 2 and (.security_summary.top_failing_repos | length) == 2' "daily_report_security_json"
assert_file_contains "$daily_report" '^## Security' "daily_report_security_section"
assert_file_contains "$daily_report" 'status: fail|leaked_secret_pattern_count: 2|alpha status=fail' "daily_report_security_counts_and_top_repos"

printf '\nSummary: %s passed, %s failed\n' "$pass_count" "$fail_count"
[[ "$fail_count" -eq 0 ]]
