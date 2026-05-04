#!/usr/bin/env bash
set -euo pipefail

BIN="${FLYWHEEL_AUTOLOOP_BIN:-/Users/josh/.claude/skills/.flywheel/bin/flywheel-autoloop}"
CHECKER="${CANONICAL_CLI_CHECKER:-/Users/josh/.claude/skills/canonical-cli-scoping/scripts/check-cli-scoping.sh}"
TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT

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
mkdir -p "$FIXTURE_HOME/bin"
cat >"$FIXTURE_HOME/bin/flywheel-loop" <<'EOF'
#!/usr/bin/env bash
set -euo pipefail
if [[ "${1:-}" == "fleet" ]]; then
  printf '{"scanned_repos_with_loop_signals":0,"ready_count":0,"repos":[]}\n'
  exit 0
fi
printf 'unsupported fixture command\n' >&2
exit 2
EOF
chmod +x "$FIXTURE_HOME/bin/flywheel-loop"
rc=0
FLYWHEEL_HOME="$FIXTURE_HOME" FLYWHEEL_AUTOLOOP_STATE_DIR="$TMP/run-state" FLYWHEEL_AUTOLOOP_ROOT="$ROOT" "$BIN" --json >"$TMP/no-arg.json" || rc=$?
rc="${rc:-0}"
test "$rc" -eq 0
jq -e '.status == "no_ready_repo"' "$TMP/run-state/last_run.json" >/dev/null
pass "no-arg supervisor path still runs under empty-root guard"

REPAIR_HOME="$TMP/repair-home"
REPAIR_ROOT="$TMP/repair-root"
REPAIR_MARKERS="$TMP/repair-markers"
mkdir -p "$REPAIR_HOME/bin" "$REPAIR_ROOT" "$REPAIR_MARKERS"

cat >"$REPAIR_HOME/bin/flywheel-loop" <<'EOF'
#!/usr/bin/env bash
set -euo pipefail
cmd="${1:-}"
shift || true
repo=""
while [[ $# -gt 0 ]]; do
  case "$1" in
    --repo) repo="$2"; shift 2 ;;
    --root) shift 2 ;;
    --json) shift ;;
    *) shift ;;
  esac
done
case "$cmd" in
  fleet)
    cat "$AUTOLOOP_FIXTURE_FLEET_JSON"
    ;;
  doctor)
    case "${AUTOLOOP_FIXTURE_CASE:-}" in
      drift_repair_success)
        if [[ -f "$AUTOLOOP_FIXTURE_MARKERS/lock-repair-applied" ]]; then
          printf '{"status":"ok","repo_docs_state":"ready","action":"tick"}\n'
          exit 0
        fi
        printf '{"status":"fail","repo_docs_state":"drift_detected","action":"repair_docs"}\n'
        exit 1
        ;;
      drift_repair_fails)
        printf '{"status":"fail","repo_docs_state":"drift_detected","action":"repair_docs"}\n'
        exit 1
        ;;
      *)
        printf '{"status":"ok","repo_docs_state":"ready","action":"tick"}\n'
        ;;
    esac
    ;;
  tick)
    printf '{"status":"ok","action":"noop","decision":"fixture"}\n'
    ;;
  init)
    printf '{"status":"ok","repo":"%s"}\n' "$repo"
    ;;
  *)
    printf 'unsupported fixture command: %s\n' "$cmd" >&2
    exit 2
    ;;
esac
EOF
chmod +x "$REPAIR_HOME/bin/flywheel-loop"

cat >"$REPAIR_HOME/bin/flywheel-lock-repair" <<'EOF'
#!/usr/bin/env bash
set -euo pipefail
printf '%s\n' "$*" >> "$AUTOLOOP_FIXTURE_LOCK_REPAIR_LOG"
if [[ "${AUTOLOOP_FIXTURE_CASE:-}" == "drift_repair_fails" ]]; then
  printf '{"command":"repair","status":"fail"}\n'
  exit 1
fi
touch "$AUTOLOOP_FIXTURE_MARKERS/lock-repair-applied"
printf '{"command":"repair","status":"ok"}\n'
EOF
chmod +x "$REPAIR_HOME/bin/flywheel-lock-repair"

fail_repo="$REPAIR_ROOT/fail-repo"
ready_repo="$REPAIR_ROOT/ready-repo"
mkdir -p "$fail_repo/.flywheel" "$ready_repo/.flywheel"
fleet_fixture="$TMP/fleet.json"
jq -n \
  --arg fail "$fail_repo" \
  --arg ready "$ready_repo" \
  '{
    scanned_repos_with_loop_signals: 2,
    ready_count: 1,
    repos: [
      {repo:$ready,opted_in:true,next_owner:"agent",next_tick_override_present:false,status:"ready",dirty_count:99},
      {repo:$fail,opted_in:true,next_owner:"agent",next_tick_override_present:false,status:"fail",dirty_count:0}
    ]
  }' >"$fleet_fixture"

HOME="$TMP/home-dry" \
FLYWHEEL_HOME="$REPAIR_HOME" \
FLYWHEEL_AUTOLOOP_STATE_DIR="$TMP/dry-repair-state" \
FLYWHEEL_AUTOLOOP_ROOT="$REPAIR_ROOT" \
AUTOLOOP_FIXTURE_FLEET_JSON="$fleet_fixture" \
  "$BIN" --dry-run >"$TMP/dry-repair.json"
jq -e --arg repo "$fail_repo" '.selected_repo == $repo and .selected_status == "fail" and .selected_priority == 100' "$TMP/dry-repair.json" >/dev/null
pass "dry-run selects fail before ready candidates"

run_repair_fixture() {
  local case_name="$1" state markers lock_log
  state="$TMP/state-$case_name"
  markers="$TMP/markers-$case_name"
  lock_log="$TMP/lock-$case_name.log"
  rm -rf "$state" "$markers"
  mkdir -p "$markers"
  HOME="$TMP/home-$case_name" \
  FLYWHEEL_HOME="$REPAIR_HOME" \
  FLYWHEEL_AUTOLOOP_STATE_DIR="$state" \
  FLYWHEEL_AUTOLOOP_ROOT="$REPAIR_ROOT" \
  AUTOLOOP_FIXTURE_FLEET_JSON="$fleet_fixture" \
  AUTOLOOP_FIXTURE_CASE="$case_name" \
  AUTOLOOP_FIXTURE_MARKERS="$markers" \
  AUTOLOOP_FIXTURE_LOCK_REPAIR_LOG="$lock_log" \
    "$BIN" --json >"$TMP/out-$case_name.json" 2>"$TMP/err-$case_name.log" || true
  printf '%s\n' "$state"
}

success_state="$(run_repair_fixture drift_repair_success)"
grep -q -- "repair --scope locks --repo $fail_repo --apply --json" "$TMP/lock-drift_repair_success.log"
test "$(rg -c '"event":"diagnose_doctor"' "$REPAIR_HOME/logs/autoloop-$(date -u +%Y%m%d).jsonl")" -ge 1
jq -e '.status == "ticked" and .repo == "'"$fail_repo"'"' "$success_state/last_run.json" >/dev/null
if [[ -s "$success_state/negative-cache.jsonl" ]]; then
  ! jq -e 'select(.reason == "doctor_failed")' "$success_state/negative-cache.jsonl" >/dev/null
fi
pass "doctor drift fixture calls lock-repair, retries doctor, and avoids doctor_failed cache"

failed_state="$(run_repair_fixture drift_repair_fails)"
jq -e '.status == "repair_failed"' "$failed_state/last_run.json" >/dev/null
jq -e 'select(.reason == "repair_failed" or .reason == "repair_not_available")' "$failed_state/negative-cache.jsonl" >/dev/null
! jq -e 'select(.reason == "doctor_failed")' "$failed_state/negative-cache.jsonl" >/dev/null
pass "failed repair fixture caches repair_failed/repair_not_available only"

bash "$CHECKER" "$BIN" >"$TMP/check-cli-scoping.txt"
cat "$TMP/check-cli-scoping.txt"
pass "canonical CLI scoping checker passes"
