#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd -P)"
SCRIPT="$ROOT/.flywheel/scripts/agent-mail-restart.sh"
TMP="$(mktemp -d "${TMPDIR:-/tmp}/agent-mail-restart.XXXXXX")"
trap 'rm -rf "$TMP"' EXIT

pass_count=0
fail_count=0

pass() { printf 'PASS %s\n' "$1"; pass_count=$((pass_count + 1)); }
fail() { printf 'FAIL %s\n' "$1" >&2; fail_count=$((fail_count + 1)); }

make_fakes() {
  local dir="$1"
  cat >"$dir/launchctl" <<'SH'
#!/usr/bin/env bash
set -euo pipefail
state="${AGENT_MAIL_FAKE_STATE:?}"
log="${AGENT_MAIL_FAKE_LOG:?}"
cmd="${1:-}"
shift || true
loaded="$(cat "$state" 2>/dev/null || printf unloaded)"
case "$cmd" in
  print)
    printf 'print %s\n' "$*" >>"$log"
    if [[ "$loaded" == loaded ]]; then
      printf 'gui/501/ai.zeststream.mcp-agent-mail-local = {\n    state = running\n    pid = 123\n}\n'
      exit 0
    fi
    exit 3
    ;;
  bootout)
    printf 'bootout %s\n' "$*" >>"$log"
    printf unloaded >"$state"
    exit 0
    ;;
  bootstrap)
    printf 'bootstrap %s\n' "$*" >>"$log"
    count_file="${AGENT_MAIL_FAKE_BOOTSTRAP_COUNT:?}"
    count="$(cat "$count_file" 2>/dev/null || printf 0)"
    count=$((count + 1))
    printf '%s' "$count" >"$count_file"
    fail_count="${AGENT_MAIL_FAKE_BOOTSTRAP_FAILS:-0}"
    if [[ "$count" -le "$fail_count" ]]; then
      printf 'Bootstrap failed: 5\n' >&2
      exit 5
    fi
    printf loaded >"$state"
    exit 0
    ;;
  kickstart)
    printf 'kickstart %s\n' "$*" >>"$log"
    [[ "$(cat "$state" 2>/dev/null || printf unloaded)" == loaded ]]
    ;;
  *)
    printf 'unknown %s %s\n' "$cmd" "$*" >>"$log"
    exit 9
    ;;
esac
SH
  cat >"$dir/pgrep" <<'SH'
#!/usr/bin/env bash
set -euo pipefail
if [[ "$(cat "${AGENT_MAIL_FAKE_STATE:?}" 2>/dev/null || printf unloaded)" == loaded ]]; then
  printf '456\n'
  exit 0
fi
exit 1
SH
  cat >"$dir/plutil" <<'SH'
#!/usr/bin/env bash
exit 0
SH
  cat >"$dir/sleep" <<'SH'
#!/usr/bin/env bash
exit 0
SH
  chmod +x "$dir/launchctl" "$dir/pgrep" "$dir/plutil" "$dir/sleep"
}

run_case() {
  local name="$1" initial_state="$2" bootstrap_fails="${3:-0}"
  local dir="$TMP/$name"
  mkdir -p "$dir"
  make_fakes "$dir"
  printf '%s' "$initial_state" >"$dir/state"
  printf '0' >"$dir/bootstrap-count"
  : >"$dir/log"
  : >"$dir/plist"
  AGENT_MAIL_RESTART_LAUNCHCTL="$dir/launchctl" \
    AGENT_MAIL_RESTART_PGREP="$dir/pgrep" \
    AGENT_MAIL_RESTART_PLUTIL="$dir/plutil" \
    AGENT_MAIL_RESTART_SLEEP_BIN="$dir/sleep" \
    AGENT_MAIL_FAKE_STATE="$dir/state" \
    AGENT_MAIL_FAKE_LOG="$dir/log" \
    AGENT_MAIL_FAKE_BOOTSTRAP_COUNT="$dir/bootstrap-count" \
    AGENT_MAIL_FAKE_BOOTSTRAP_FAILS="$bootstrap_fails" \
    AGENT_MAIL_PLIST="$dir/plist" \
    "$SCRIPT" --apply --explain --json >"$dir/out.jsonl" 2>"$dir/err.log"
  printf '%s\n' "$dir"
}

bash -n "$SCRIPT" && pass "restart script syntax" || fail "restart script syntax"
"$SCRIPT" --info --json | jq -e '.mutates_with_apply == true and .dry_run_default == true' >/dev/null \
  && pass "info documents dry-run/apply posture" || fail "info documents dry-run/apply posture"

unloaded_dir="$(run_case unloaded unloaded 0)"
grep -q '^bootstrap ' "$unloaded_dir/log" && grep -q '^kickstart ' "$unloaded_dir/log" \
  && [[ "$(cat "$unloaded_dir/state")" == loaded ]] \
  && pass "unloaded service bootstraps and kickstarts" || fail "unloaded service bootstraps and kickstarts"

loaded_dir="$(run_case loaded loaded 0)"
grep -q '^bootout ' "$loaded_dir/log" && grep -q '^bootstrap ' "$loaded_dir/log" && grep -q '^kickstart ' "$loaded_dir/log" \
  && [[ "$(cat "$loaded_dir/state")" == loaded ]] \
  && pass "already loaded service bootouts then reloads" || fail "already loaded service bootouts then reloads"

recover_dir="$(run_case recover loaded 3)"
[[ "$(cat "$recover_dir/state")" == loaded ]] \
  && [[ "$(cat "$recover_dir/bootstrap-count")" == 4 ]] \
  && grep -q 'recovered from bootstrap failure after bootout' "$recover_dir/out.jsonl" \
  && pass "bootstrap failure after bootout recovers loaded service" || fail "bootstrap failure after bootout recovers loaded service"

printf '\nSummary: %s passed, %s failed\n' "$pass_count" "$fail_count"
[[ "$fail_count" -eq 0 ]]
