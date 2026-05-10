#!/usr/bin/env bash
set -euo pipefail

BIN="${FLYWHEEL_AUTOLOOP_BIN:-/Users/josh/.claude/skills/.flywheel/bin/flywheel-autoloop}"
CHECKER="${CANONICAL_CLI_CHECKER:-/Users/josh/.claude/skills/canonical-cli-scoping/scripts/check-cli-scoping.sh}"
TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"; rm -f /tmp/flywheel-autoloop-fixture-dispatch-90.md' EXIT

pass() {
  printf 'PASS: %s\n' "$1"
}

run_jq_allow_status() {
  local output="$1"
  shift
  set +e
  "$@" >"$output"
  local rc=$?
  set -e
  jq empty "$output"
  case "$rc" in
    0|1|3) return 0 ;;
    *) printf 'unexpected exit %s for %s\n' "$rc" "$*" >&2; return 1 ;;
  esac
}

ROOT="$TMP/root"
STATE="$TMP/state"
mkdir -p "$ROOT"

test -x "$BIN"
pass "flywheel-autoloop is executable"

FLYWHEEL_AUTOLOOP_STATE_DIR="$STATE" FLYWHEEL_AUTOLOOP_ROOT="$ROOT" "$BIN" --help >"$TMP/help.txt"
test ! -e "$STATE"
grep -q -- '--watch' "$TMP/help.txt"
grep -q -- '--dry-run' "$TMP/help.txt"
pass "help exits before state writes and documents watch"

run_jq_allow_status "$TMP/doctor.json" "$BIN" doctor --json
pass "doctor --json emits parseable JSON with clean domain exit"

run_jq_allow_status "$TMP/health.json" "$BIN" health --json
pass "health --json emits parseable JSON with clean domain exit"

"$BIN" health --watch -i 1 --json >"$TMP/health-watch.jsonl" &
watch_pid=$!
sleep 2
if ! kill -0 "$watch_pid" 2>/dev/null; then
  printf 'health --watch exited before external stop\n' >&2
  exit 1
fi
kill "$watch_pid" 2>/dev/null || true
wait "$watch_pid" 2>/dev/null || true
test "$(wc -l <"$TMP/health-watch.jsonl" | tr -d ' ')" -ge 2
while IFS= read -r line; do
  jq empty <<<"$line"
done <"$TMP/health-watch.jsonl"
pass "health --watch --json is long-running and stoppable"

FIXTURE_HOME="$TMP/flywheel-home"
mkdir -p "$FIXTURE_HOME/bin" "$FIXTURE_HOME/config"

cat >"$FIXTURE_HOME/config/autoloop.json" <<'EOF'
{
  "schema_version": "flywheel-autoloop.config.v1",
  "cooldowns": {
    "same_repo_seconds": 14400
  },
  "budgets": {
    "max_autonomous_ticks_per_run": 1,
    "global_ticks_per_day": 12,
    "per_repo_ticks_per_day": 3
  },
  "repos": {
    "allowlist": []
  },
  "dispatch": {
    "min_score": 80,
    "session": "flywheel",
    "pane": 2,
    "callback_pane": 1,
    "auto_spawn": false,
    "timeout_seconds": 3600
  }
}
EOF
jq -e '.schema_version and .cooldowns and .budgets and .dispatch' "$FIXTURE_HOME/config/autoloop.json" >/dev/null
pass "default autoloop config exposes schema_version cooldowns budgets and dispatch"

cat >"$FIXTURE_HOME/bin/flywheel-check" <<'EOF'
#!/usr/bin/env bash
set -euo pipefail
printf '%s\n' "$*" >> "$AUTOLOOP_FIXTURE_CHECK_LOG"
cat "$AUTOLOOP_FIXTURE_CHECK_JSON"
EOF
chmod +x "$FIXTURE_HOME/bin/flywheel-check"

cat >"$FIXTURE_HOME/bin/flywheel-loop" <<'EOF'
#!/usr/bin/env bash
set -euo pipefail
cmd="${1:-}"
shift || true
repo=""
file=""
strict=0
while [[ $# -gt 0 ]]; do
  case "$1" in
    --strict) strict=1; shift ;;
    --repo) repo="$2"; shift 2 ;;
    --file) file="$2"; shift 2 ;;
    --json) shift ;;
    *) shift ;;
  esac
done
printf '%s strict=%s repo=%s file=%s\n' "$cmd" "$strict" "$repo" "$file" >> "$AUTOLOOP_FIXTURE_LOOP_LOG"
case "$cmd" in
  doctor)
    printf '{"status":"ok","repo_docs_state":"ready","action":"tick"}\n'
    ;;
  tick)
    sleep "${AUTOLOOP_FIXTURE_TICK_SLEEP:-0}"
    printf '{"status":"ok","action":"fixture_tick","decision":"fixture"}\n'
    ;;
  validate-receipt)
    if [[ -n "$repo" && -f "$file" ]] && jq empty "$file" >/dev/null 2>&1; then
      printf '{"status":"pass","repo":"%s","file":"%s"}\n' "$repo" "$file"
    else
      printf '{"status":"fail","reason":"fixture_invalid_receipt","repo":"%s","file":"%s"}\n' "$repo" "$file"
      exit 1
    fi
    ;;
  *)
    printf 'unsupported fixture command: %s\n' "$cmd" >&2
    exit 2
    ;;
esac
EOF
chmod +x "$FIXTURE_HOME/bin/flywheel-loop"

cat >"$FIXTURE_HOME/bin/ntm" <<'EOF'
#!/usr/bin/env bash
set -euo pipefail
cmd="${1:-}"
shift || true
printf '%s' "$cmd" >> "$AUTOLOOP_FIXTURE_NTM_LOG"
for arg in "$@"; do
  printf ' %s' "$arg" >> "$AUTOLOOP_FIXTURE_NTM_LOG"
done
printf '\n' >> "$AUTOLOOP_FIXTURE_NTM_LOG"
case "$cmd" in
  send)
    file=""
    while [[ $# -gt 0 ]]; do
      case "$1" in
        --file) file="${2:-}"; shift 2 ;;
        *) shift ;;
      esac
    done
    [[ -n "$file" && -f "$file" ]] || exit 12
    printf '{"success":true,"transport":"fixture"}\n'
    ;;
  *)
    printf 'unsupported fixture ntm command: %s\n' "$cmd" >&2
    exit 2
    ;;
esac
EOF
chmod +x "$FIXTURE_HOME/bin/ntm"

empty_check_json="$TMP/check-empty.json"
jq -n '{scanned_git_repos:0,status_counts:{},repos:[]}' >"$empty_check_json"

no_ready_state="$TMP/no-ready-state"
no_ready_check_log="$TMP/no-ready-check.log"
no_ready_loop_log="$TMP/no-ready-loop.log"
HOME="$TMP/home-no-ready" \
FLYWHEEL_HOME="$FIXTURE_HOME" \
FLYWHEEL_AUTOLOOP_STATE_DIR="$no_ready_state" \
FLYWHEEL_AUTOLOOP_ROOT="$ROOT" \
AUTOLOOP_FIXTURE_CHECK_JSON="$empty_check_json" \
AUTOLOOP_FIXTURE_CHECK_LOG="$no_ready_check_log" \
AUTOLOOP_FIXTURE_LOOP_LOG="$no_ready_loop_log" \
  "$BIN" run --json >"$TMP/no-ready.json"
jq -e '.status == "no_ready_repo" and .check_ran == true and .tick_ran == false' "$TMP/no-ready.json" >/dev/null
jq -e '.ts and .status' "$no_ready_state/last_run.json" >/dev/null
test "$(wc -l <"$no_ready_state/autoloop-$(date -u +%Y%m%d).jsonl" | tr -d ' ')" -eq 1
grep -q -- "--root" "$no_ready_check_log"
test ! -s "$no_ready_loop_log"
pass "run --json returns a receipt, writes last_run/jsonl, and skips tick when no repo is ready"

repo_a="$ROOT/a-repo"
repo_z="$ROOT/z-repo"
repo_b="$ROOT/b-repo"
repo_human="$ROOT/human-repo"
repo_override="$ROOT/override-repo"
mkdir -p "$repo_a/.flywheel" "$repo_z/.flywheel" "$repo_b/.flywheel" "$repo_human/.flywheel" "$repo_override/.flywheel"

select_check_json="$TMP/check-select.json"
jq -n \
  --arg repo_a "$repo_a" \
  --arg repo_z "$repo_z" \
  --arg repo_b "$repo_b" \
  --arg repo_human "$repo_human" \
  --arg repo_override "$repo_override" \
  '{
    scanned_git_repos: 5,
    repos: [
      {repo:$repo_z,status:"ok",next_owner:"agent",next_tick_override_present:false,dirty_count:20},
      {repo:$repo_a,status:"ready",next_owner:"agent",next_tick_override_present:false,dirty_count:20},
      {repo:$repo_b,status:"ready",next_owner:"agent",next_tick_override_present:false,dirty_count:10},
      {repo:$repo_human,status:"ready",next_owner:"human",next_tick_override_present:false,dirty_count:99},
      {repo:$repo_override,status:"ready",next_owner:"agent",next_tick_override_present:true,dirty_count:100}
    ]
  }' >"$select_check_json"

scan_no_ready_state="$TMP/scan-no-ready-state"
scan_no_ready_check_log="$TMP/scan-no-ready-check.log"
scan_no_ready_loop_log="$TMP/scan-no-ready-loop.log"
HOME="$TMP/home-scan-no-ready" \
FLYWHEEL_HOME="$FIXTURE_HOME" \
FLYWHEEL_AUTOLOOP_STATE_DIR="$scan_no_ready_state" \
FLYWHEEL_AUTOLOOP_ROOT="$ROOT" \
AUTOLOOP_FIXTURE_CHECK_JSON="$empty_check_json" \
AUTOLOOP_FIXTURE_CHECK_LOG="$scan_no_ready_check_log" \
AUTOLOOP_FIXTURE_LOOP_LOG="$scan_no_ready_loop_log" \
  "$BIN" scan --dry-run --json >"$TMP/scan-no-ready.json"
jq -e '.status == "idle" and (.queue | length) == 0 and .tick_ran == false' "$TMP/scan-no-ready.json" >/dev/null
jq -e '.status and .queue' "$TMP/scan-no-ready.json" >/dev/null
test ! -e "$scan_no_ready_state"
test ! -s "$scan_no_ready_loop_log"
pass "scan --dry-run --json yields idle queue and no state or tick when no repo is ready"

one_ready_check_json="$TMP/check-one-ready.json"
jq -n --arg repo "$repo_a" '{
  scanned_git_repos: 1,
  repos: [
    {repo:$repo,status:"ready",next_owner:"agent",next_tick_override_present:false,dirty_count:0}
  ]
}' >"$one_ready_check_json"

scan_deterministic_state="$TMP/scan-deterministic-state"
scan_deterministic_check_log="$TMP/scan-deterministic-check.log"
scan_deterministic_loop_log="$TMP/scan-deterministic-loop.log"
for n in 1 2; do
  HOME="$TMP/home-scan-deterministic" \
  FLYWHEEL_HOME="$FIXTURE_HOME" \
  FLYWHEEL_AUTOLOOP_STATE_DIR="$scan_deterministic_state" \
  FLYWHEEL_AUTOLOOP_ROOT="$ROOT" \
  AUTOLOOP_FIXTURE_CHECK_JSON="$one_ready_check_json" \
  AUTOLOOP_FIXTURE_CHECK_LOG="$scan_deterministic_check_log" \
  AUTOLOOP_FIXTURE_LOOP_LOG="$scan_deterministic_loop_log" \
    "$BIN" scan --dry-run --json >"$TMP/scan-deterministic-$n.json"
done
jq -e --arg repo "$repo_a" '.status == "queued" and (.queue | length) == 1 and .queue[0].repo == $repo and .queue[0].score >= 50' "$TMP/scan-deterministic-1.json" >/dev/null
test "$(jq -r '.queue[0].score' "$TMP/scan-deterministic-1.json")" = "$(jq -r '.queue[0].score' "$TMP/scan-deterministic-2.json")"
test ! -e "$scan_deterministic_state"
test ! -s "$scan_deterministic_loop_log"
pass "scan dry-run produces deterministic scores and does not dispatch"

scan_write_state="$TMP/scan-write-state"
scan_write_check_log="$TMP/scan-write-check.log"
scan_write_loop_log="$TMP/scan-write-loop.log"
HOME="$TMP/home-scan-write" \
FLYWHEEL_HOME="$FIXTURE_HOME" \
FLYWHEEL_AUTOLOOP_STATE_DIR="$scan_write_state" \
FLYWHEEL_AUTOLOOP_ROOT="$ROOT" \
AUTOLOOP_FIXTURE_CHECK_JSON="$one_ready_check_json" \
AUTOLOOP_FIXTURE_CHECK_LOG="$scan_write_check_log" \
AUTOLOOP_FIXTURE_LOOP_LOG="$scan_write_loop_log" \
  "$BIN" scan --json >"$TMP/scan-write.json"
jq -e --arg repo "$repo_a" '
  .status == "queued"
  and .paths.queue == "'"$scan_write_state"'/queue.json"
  and .paths.repo_state == "'"$scan_write_state"'/repo-state.json"
  and .queue[0].repo == $repo
  and (.queue[0] | has("score") and has("reason") and has("repo") and has("threshold") and has("cooldown"))
' "$TMP/scan-write.json" >/dev/null
jq -e --arg repo "$repo_a" '.queue[0].repo == $repo and (.queue[0].score | type) == "number"' "$scan_write_state/queue.json" >/dev/null
jq -e --arg repo "$repo_a" '.repos[$repo].last_queued_at and .repos[$repo].cooldown_until == null' "$scan_write_state/repo-state.json" >/dev/null
test ! -s "$scan_write_loop_log"
pass "scan --json writes queue.json and repo-state.json without tick dispatch"

scan_cooldown_check_log="$TMP/scan-cooldown-check.log"
HOME="$TMP/home-scan-write" \
FLYWHEEL_HOME="$FIXTURE_HOME" \
FLYWHEEL_AUTOLOOP_STATE_DIR="$scan_write_state" \
FLYWHEEL_AUTOLOOP_ROOT="$ROOT" \
AUTOLOOP_FIXTURE_CHECK_JSON="$one_ready_check_json" \
AUTOLOOP_FIXTURE_CHECK_LOG="$scan_cooldown_check_log" \
AUTOLOOP_FIXTURE_LOOP_LOG="$scan_write_loop_log" \
  "$BIN" scan --json >"$TMP/scan-cooldown.json"
jq -e '.queue[0].threshold == "cooldown" and .queue[0].cooldown.active == true and .queue[0].dispatch_allowed == false' "$TMP/scan-cooldown.json" >/dev/null
test ! -s "$scan_write_loop_log"
pass "scan applies four-hour same-repo cooldown on repeated queue writes"

scan_allowlist_state="$TMP/scan-allowlist-state"
scan_allowlist_check_log="$TMP/scan-allowlist-check.log"
scan_allowlist_loop_log="$TMP/scan-allowlist-loop.log"
HOME="$TMP/home-scan-allowlist" \
FLYWHEEL_HOME="$FIXTURE_HOME" \
FLYWHEEL_AUTOLOOP_STATE_DIR="$scan_allowlist_state" \
FLYWHEEL_AUTOLOOP_ROOT="$ROOT" \
FLYWHEEL_AUTOLOOP_REPOS="$repo_b" \
AUTOLOOP_FIXTURE_CHECK_JSON="$select_check_json" \
AUTOLOOP_FIXTURE_CHECK_LOG="$scan_allowlist_check_log" \
AUTOLOOP_FIXTURE_LOOP_LOG="$scan_allowlist_loop_log" \
  "$BIN" scan --dry-run --json >"$TMP/scan-allowlist.json"
jq -e --arg repo "$repo_b" '(.queue | length) == 1 and .queue[0].repo == $repo' "$TMP/scan-allowlist.json" >/dev/null
test ! -e "$scan_allowlist_state"
test ! -s "$scan_allowlist_loop_log"
pass "FLYWHEEL_AUTOLOOP_REPOS limits scan candidates to allowlist"

config_roundtrip="$TMP/autoloop-config-roundtrip.json"
jq -n --arg repo "$repo_b" '{
  schema_version:"flywheel-autoloop.config.v1",
  cooldowns:{same_repo_seconds:60},
  budgets:{max_autonomous_ticks_per_run:1,global_ticks_per_day:12,per_repo_ticks_per_day:3},
  repos:{allowlist:[$repo]}
}' >"$config_roundtrip"
scan_config_state="$TMP/scan-config-state"
scan_config_check_log="$TMP/scan-config-check.log"
scan_config_loop_log="$TMP/scan-config-loop.log"
HOME="$TMP/home-scan-config" \
FLYWHEEL_HOME="$FIXTURE_HOME" \
FLYWHEEL_AUTOLOOP_CONFIG="$config_roundtrip" \
FLYWHEEL_AUTOLOOP_STATE_DIR="$scan_config_state" \
FLYWHEEL_AUTOLOOP_ROOT="$ROOT" \
AUTOLOOP_FIXTURE_CHECK_JSON="$select_check_json" \
AUTOLOOP_FIXTURE_CHECK_LOG="$scan_config_check_log" \
AUTOLOOP_FIXTURE_LOOP_LOG="$scan_config_loop_log" \
  "$BIN" scan --dry-run --json >"$TMP/scan-config.json"
jq -e --arg repo "$repo_b" '(.queue | length) == 1 and .queue[0].repo == $repo and .queue[0].cooldown.seconds == 60' "$TMP/scan-config.json" >/dev/null
test ! -e "$scan_config_state"
test ! -s "$scan_config_loop_log"
pass "FLYWHEEL_AUTOLOOP_CONFIG round-trips allowlist and cooldown settings"

dispatch_repo="$ROOT/dispatch-repo"
mkdir -p "$dispatch_repo/.flywheel"

dispatch_dry_state="$TMP/dispatch-dry-state"
dispatch_dry_ntm_log="$TMP/dispatch-dry-ntm.log"
mkdir -p "$dispatch_dry_state"
jq -n --arg repo "$dispatch_repo" '{
  schema_version:"flywheel-autoloop.queue.v1",
  status:"queued",
  queue:[
    {repo:$repo,status:"ready",score:90,threshold:"dispatch-eligible",dispatch_allowed:true,reason:["fixture"],signals:[]}
  ]
}' >"$dispatch_dry_state/queue.json"
HOME="$TMP/home-dispatch-dry" \
FLYWHEEL_HOME="$FIXTURE_HOME" \
FLYWHEEL_AUTOLOOP_CONFIG="$FIXTURE_HOME/config/autoloop.json" \
FLYWHEEL_AUTOLOOP_STATE_DIR="$dispatch_dry_state" \
FLYWHEEL_NTM_CMD="$FIXTURE_HOME/bin/ntm" \
AUTOLOOP_FIXTURE_NTM_LOG="$dispatch_dry_ntm_log" \
AUTOLOOP_FIXTURE_LOOP_LOG="$TMP/dispatch-dry-loop.log" \
  "$BIN" dispatch --dry-run --json >"$TMP/dispatch-dry.json"
jq -e --arg repo "$dispatch_repo" '
  .status == "dry_run"
  and .repo == $repo
  and .score == 90
  and (.packet_path | startswith("/tmp/flywheel-autoloop-"))
  and .would_send == true
  and .sent == false
' "$TMP/dispatch-dry.json" >/dev/null
test ! -e "$dispatch_dry_ntm_log"
test ! -e "$(jq -r '.packet_path' "$TMP/dispatch-dry.json")"
pass "dispatch --dry-run --json reports queue item and packet path without sending"

dispatch_low_state="$TMP/dispatch-low-state"
dispatch_low_ntm_log="$TMP/dispatch-low-ntm.log"
mkdir -p "$dispatch_low_state"
jq -n --arg repo "$dispatch_repo" '{
  schema_version:"flywheel-autoloop.queue.v1",
  status:"queued",
  queue:[
    {repo:$repo,status:"ready",score:60,threshold:"queue",dispatch_allowed:false,reason:["fixture_low_score"],signals:[]}
  ]
}' >"$dispatch_low_state/queue.json"
HOME="$TMP/home-dispatch-low" \
FLYWHEEL_HOME="$FIXTURE_HOME" \
FLYWHEEL_AUTOLOOP_CONFIG="$FIXTURE_HOME/config/autoloop.json" \
FLYWHEEL_AUTOLOOP_STATE_DIR="$dispatch_low_state" \
FLYWHEEL_NTM_CMD="$FIXTURE_HOME/bin/ntm" \
AUTOLOOP_FIXTURE_NTM_LOG="$dispatch_low_ntm_log" \
AUTOLOOP_FIXTURE_LOOP_LOG="$TMP/dispatch-low-loop.log" \
  "$BIN" dispatch --json >"$TMP/dispatch-low.json"
jq -e '.status == "no_dispatch" and .reason == "score_below_threshold" and .sent == false' "$TMP/dispatch-low.json" >/dev/null
jq -e '.event == "autoloop_dispatch_skipped" and .reason == "score_below_threshold"' "$dispatch_low_state/dispatch-log.jsonl" >/dev/null
jq -e '.dispatches[0].status == "no_dispatch" and .dispatches[0].reason == "score_below_threshold"' "$dispatch_low_state/dispatch-state.json" >/dev/null
test ! -e "$dispatch_low_ntm_log"
pass "dispatch score below threshold writes skip receipt and does not send"

dispatch_apply_state="$TMP/dispatch-apply-state"
dispatch_apply_ntm_log="$TMP/dispatch-apply-ntm.log"
dispatch_apply_loop_log="$TMP/dispatch-apply-loop.log"
mkdir -p "$dispatch_apply_state"
jq -n --arg repo "$dispatch_repo" '{
  schema_version:"flywheel-autoloop.queue.v1",
  status:"queued",
  queue:[
    {repo:$repo,status:"ready",score:90,threshold:"dispatch-eligible",dispatch_allowed:true,reason:["fixture_high_score"],signals:[]}
  ]
}' >"$dispatch_apply_state/queue.json"
HOME="$TMP/home-dispatch-apply" \
FLYWHEEL_HOME="$FIXTURE_HOME" \
FLYWHEEL_AUTOLOOP_CONFIG="$FIXTURE_HOME/config/autoloop.json" \
FLYWHEEL_AUTOLOOP_STATE_DIR="$dispatch_apply_state" \
FLYWHEEL_NTM_CMD="$FIXTURE_HOME/bin/ntm" \
AUTOLOOP_FIXTURE_NTM_LOG="$dispatch_apply_ntm_log" \
AUTOLOOP_FIXTURE_LOOP_LOG="$dispatch_apply_loop_log" \
  "$BIN" dispatch --idempotency-key fixture-dispatch-90 --json >"$TMP/dispatch-apply.json"
packet_path="$(jq -r '.packet_path' "$TMP/dispatch-apply.json")"
jq -e --arg repo "$dispatch_repo" '.status == "dispatched" and .repo == $repo and .log_row.event == "autoloop_dispatch_sent" and .log_row.status == "pending"' "$TMP/dispatch-apply.json" >/dev/null
test -f "$packet_path"
grep -q "repo=$dispatch_repo" "$packet_path"
grep -q "## Acceptance Gates" "$packet_path"
grep -q "## Callback Envelope" "$packet_path"
grep -q "send flywheel --pane=2 --no-cass-check --file $packet_path" "$dispatch_apply_ntm_log"
jq -e --arg packet "$packet_path" '.event == "autoloop_dispatch_sent" and .packet_path == $packet and .ntm.argv == ["send","flywheel","--pane=2","--no-cass-check","--file",$packet]' "$dispatch_apply_state/dispatch-log.jsonl" >/dev/null
pass "dispatch score above threshold writes packet, logs row, and sends with canonical ntm transport"

jq -n '{schema_version:"flywheel-loop.closeout-receipt.v2", status:"done", next_owner:"agent", safe_local_work_remaining:false}' >"$dispatch_repo/.flywheel/last_closeout_receipt.json"
HOME="$TMP/home-dispatch-apply" \
FLYWHEEL_HOME="$FIXTURE_HOME" \
FLYWHEEL_AUTOLOOP_CONFIG="$FIXTURE_HOME/config/autoloop.json" \
FLYWHEEL_AUTOLOOP_STATE_DIR="$dispatch_apply_state" \
FLYWHEEL_NTM_CMD="$FIXTURE_HOME/bin/ntm" \
AUTOLOOP_FIXTURE_NTM_LOG="$dispatch_apply_ntm_log" \
AUTOLOOP_FIXTURE_LOOP_LOG="$dispatch_apply_loop_log" \
  "$BIN" reap --json >"$TMP/dispatch-reap.json"
jq -e '.status == "reaped" and .reaped == 1 and .results[0].status == "complete" and .results[0].receipt_validation.exit_code == 0' "$TMP/dispatch-reap.json" >/dev/null
jq -e '.dispatches[0].status == "complete" and .dispatches[0].event == "autoloop_callback_reaped"' "$dispatch_apply_state/dispatch-state.json" >/dev/null
grep -q "validate-receipt strict=0 repo=$dispatch_repo file=$dispatch_repo/.flywheel/last_closeout_receipt.json" "$dispatch_apply_loop_log"
pass "reap validates closeout receipt fixture and marks dispatch complete"

select_state="$TMP/select-state"
select_check_log="$TMP/select-check.log"
select_loop_log="$TMP/select-loop.log"
HOME="$TMP/home-select" \
FLYWHEEL_HOME="$FIXTURE_HOME" \
FLYWHEEL_AUTOLOOP_STATE_DIR="$select_state" \
FLYWHEEL_AUTOLOOP_ROOT="$ROOT" \
AUTOLOOP_FIXTURE_CHECK_JSON="$select_check_json" \
AUTOLOOP_FIXTURE_CHECK_LOG="$select_check_log" \
AUTOLOOP_FIXTURE_LOOP_LOG="$select_loop_log" \
  "$BIN" run --json >"$TMP/select.json"
jq -e --arg repo "$repo_a" '
  .status == "ticked"
  and .repo == $repo
  and .selected_status == "ready"
  and .scanned == 5
  and .ready == 3
  and .check_ran == true
  and .doctor_ran == true
  and .tick_ran == true
  and .agent_wakeups == false
  and .l112_observed == "OK_autoloop_p0_runner"
' "$TMP/select.json" >/dev/null
jq -e '.ts and .status' "$select_state/last_run.json" >/dev/null
grep -q -- "doctor strict=1 repo=$repo_a" "$select_loop_log"
grep -q -- "tick strict=0 repo=$repo_a" "$select_loop_log"
pass "run selects dirtiest eligible repo, breaks ties lexicographically, and runs strict doctor then tick"

stop_state="$TMP/stop-state"
stop_check_log="$TMP/stop-check.log"
stop_loop_log="$TMP/stop-loop.log"
mkdir -p "$TMP/home-stop/.flywheel"
touch "$TMP/home-stop/.flywheel/STOP-autoloop"
HOME="$TMP/home-stop" \
FLYWHEEL_HOME="$FIXTURE_HOME" \
FLYWHEEL_AUTOLOOP_STATE_DIR="$stop_state" \
FLYWHEEL_AUTOLOOP_ROOT="$ROOT" \
AUTOLOOP_FIXTURE_CHECK_JSON="$select_check_json" \
AUTOLOOP_FIXTURE_CHECK_LOG="$stop_check_log" \
AUTOLOOP_FIXTURE_LOOP_LOG="$stop_loop_log" \
  "$BIN" run --json >"$TMP/stop.json"
jq -e '.status == "stopped" and .reason == "STOP-autoloop" and .check_ran == false and .tick_ran == false' "$TMP/stop.json" >/dev/null
jq -e '.status == "stopped"' "$stop_state/last_run.json" >/dev/null
test ! -e "$stop_loop_log"
pass "STOP-autoloop writes stopped receipt and does not run repo tick"

explicit_stop_state="$TMP/explicit-stop-state"
mkdir -p "$TMP/home-explicit-stop"
HOME="$TMP/home-explicit-stop" \
FLYWHEEL_HOME="$FIXTURE_HOME" \
FLYWHEEL_AUTOLOOP_STATE_DIR="$explicit_stop_state" \
  "$BIN" stop --autoloop --reason test --json >"$TMP/explicit-stop.json"
jq -e '
  .schema_version == "flywheel-autoloop.stop.receipt.v1"
  and .status == "stopped"
  and .scope == "autoloop"
  and .reason == "test"
  and .ts
  and .actor
  and (.sentinel_path | endswith("/.flywheel/STOP-autoloop"))
' "$TMP/explicit-stop.json" >/dev/null
jq -e '.reason == "test" and .actor and .sentinel_path' "$TMP/home-explicit-stop/.flywheel/STOP-autoloop" >/dev/null
pass "stop --autoloop writes JSON STOP receipt with reason timestamp actor and sentinel path"

status_state="$TMP/status-state"
status_home="$TMP/home-status"
mkdir -p "$status_state" "$status_home/Library/LaunchAgents"
jq -n '{status:"fixture-last-run"}' >"$status_state/last_run.json"
jq -n '{queue:[{repo:"fixture",score:90}]}' >"$status_state/queue.json"
jq -n '{repos:{fixture:{last_queued_at:"2026-05-07T00:00:00Z"}}}' >"$status_state/repo-state.json"
jq -n '{dispatches:[{status:"pending"}]}' >"$status_state/dispatch-state.json"
HOME="$status_home" \
FLYWHEEL_HOME="$FIXTURE_HOME" \
FLYWHEEL_AUTOLOOP_STATE_DIR="$status_state" \
FLYWHEEL_AUTOLOOP_LAUNCHCTL_LIST_FIXTURE="$TMP/status-launchctl-empty.txt" \
  "$BIN" status --json >"$TMP/status.json"
jq -e '
  .schema_version == "flywheel-autoloop.status.v1"
  and .last_run
  and .queue
  and .repo_state
  and .dispatch_state
  and .pending_dispatches == 1
  and .budgets
  and .launch_agent.status == "missing"
' "$TMP/status.json" >/dev/null
pass "status --json reads last_run queue repo-state dispatch-state budgets and missing LaunchAgent"

touch "$TMP/status-launchctl-empty.txt"
cat >"$status_home/Library/LaunchAgents/ai.zeststream.flywheel-autoloop.plist" <<'EOF'
<?xml version="1.0" encoding="UTF-8"?>
<plist version="1.0"><dict><key>Label</key><string>ai.zeststream.flywheel-autoloop</string></dict></plist>
EOF
HOME="$status_home" \
FLYWHEEL_HOME="$FIXTURE_HOME" \
FLYWHEEL_AUTOLOOP_STATE_DIR="$status_state" \
FLYWHEEL_AUTOLOOP_LAUNCHCTL_LIST_FIXTURE="$TMP/status-launchctl-empty.txt" \
  "$BIN" status --json >"$TMP/status-stale.json"
jq -e '.launch_agent.status == "stale" and .launch_agent.plist_exists == true and .launch_agent.loaded == false' "$TMP/status-stale.json" >/dev/null
pass "status --json surfaces stale LaunchAgent when plist exists but launchctl row is absent"

budget_state="$TMP/budget-state"
budget_ntm_log="$TMP/budget-ntm.log"
mkdir -p "$budget_state"
jq -n --arg repo "$dispatch_repo" '{
  schema_version:"flywheel-autoloop.queue.v1",
  status:"queued",
  queue:[
    {repo:$repo,status:"ready",score:90,threshold:"dispatch-eligible",dispatch_allowed:true,reason:["fixture_high_score"],signals:[]}
  ]
}' >"$budget_state/queue.json"
for i in $(seq 1 12); do
  printf '{"ts":"%sT00:00:%02dZ","event":"autoloop_dispatch_sent","repo":"%s","status":"pending"}\n' "$(date -u +%Y-%m-%d)" "$i" "$dispatch_repo" >>"$budget_state/dispatch-log.jsonl"
done
HOME="$TMP/home-budget" \
FLYWHEEL_HOME="$FIXTURE_HOME" \
FLYWHEEL_AUTOLOOP_CONFIG="$FIXTURE_HOME/config/autoloop.json" \
FLYWHEEL_AUTOLOOP_STATE_DIR="$budget_state" \
FLYWHEEL_NTM_CMD="$FIXTURE_HOME/bin/ntm" \
AUTOLOOP_FIXTURE_NTM_LOG="$budget_ntm_log" \
  "$BIN" dispatch --json >"$TMP/budget-dispatch.json"
jq -e '
  .status == "no_dispatch"
  and .reason == "budget_exhausted"
  and .budgets.ok == false
  and (.budgets.exhausted | index("global_ticks_per_day"))
  and .budgets.global.remaining == 0
' "$TMP/budget-dispatch.json" >/dev/null
test ! -e "$budget_ntm_log"
pass "budget-exhausted dispatch fixture emits machine-readable budget_exhausted and does not send"

concurrent_state="$TMP/concurrent-state"
concurrent_check_log="$TMP/concurrent-check.log"
concurrent_loop_log="$TMP/concurrent-loop.log"
run_concurrent() {
  local output="$1"
  HOME="$TMP/home-concurrent" \
  FLYWHEEL_HOME="$FIXTURE_HOME" \
  FLYWHEEL_AUTOLOOP_STATE_DIR="$concurrent_state" \
  FLYWHEEL_AUTOLOOP_ROOT="$ROOT" \
  AUTOLOOP_FIXTURE_CHECK_JSON="$select_check_json" \
  AUTOLOOP_FIXTURE_CHECK_LOG="$concurrent_check_log" \
  AUTOLOOP_FIXTURE_LOOP_LOG="$concurrent_loop_log" \
  AUTOLOOP_FIXTURE_TICK_SLEEP=1 \
    "$BIN" run --json >"$output"
}
mkdir -p "$TMP/home-concurrent"
run_concurrent "$TMP/concurrent-1.json" &
pid1=$!
sleep 0.1
run_concurrent "$TMP/concurrent-2.json" &
pid2=$!
wait "$pid1"
wait "$pid2"
jq -s '
  ([.[].status] | map(select(. == "ticked")) | length) == 1
  and ([.[].status] | map(select(. == "lock_held")) | length) == 1
' "$TMP/concurrent-1.json" "$TMP/concurrent-2.json" >/dev/null
test "$(grep -c '^tick ' "$concurrent_loop_log")" -eq 1
test "$(wc -l <"$concurrent_state/autoloop-$(date -u +%Y%m%d).jsonl" | tr -d ' ')" -eq 2
pass "simultaneous runs produce one tick and one lock-held receipt"

bash "$CHECKER" "$BIN" >"$TMP/check-cli-scoping.txt"
cat "$TMP/check-cli-scoping.txt"
pass "canonical CLI scoping checker passes"
