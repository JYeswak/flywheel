#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd -P)"
INSTALLER="$ROOT/.flywheel/scripts/install-stuck-detector-watchdog.sh"
VERIFY="$ROOT/.flywheel/scripts/verify-watcher-launchd-active.sh"
PATTERN_TEST="$ROOT/.flywheel/tests/test-detector-pattern-bank-replay.sh"
LABEL="ai.zeststream.codex-stuck-detector-watchdog"
PLIST="$HOME/Library/LaunchAgents/${LABEL}.plist"
INSTALL_LOG="$HOME/.local/state/flywheel/watcher-launchd-install.jsonl"
LEDGER="$HOME/.local/state/flywheel/codex-stuck-detector.jsonl"
DOMAIN="${WATCHER_LAUNCHD_DOMAIN:-gui/$(id -u)}"

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

wait_for_verify() {
  local out="$1" deadline now
  deadline=$((SECONDS + 150))
  while true; do
    if "$VERIFY" >"$out" 2>"$out.err"; then
      return 0
    fi
    now="$SECONDS"
    [[ "$now" -lt "$deadline" ]] || return 1
    sleep 5
  done
}

bash -n "$INSTALLER" && pass "installer_syntax" || fail "installer_syntax"
bash -n "$VERIFY" && pass "verify_probe_syntax" || fail "verify_probe_syntax"

tmp="$(mktemp -d "${TMPDIR:-/tmp}/watcher-launchd-active.XXXXXX")"
trap 'rm -rf "$tmp"' EXIT

bash "$INSTALLER" --json >"$tmp/install-1.json"
bash "$INSTALLER" --json >"$tmp/install-2.json"
assert_jq "$tmp/install-1.json" '.label == "ai.zeststream.codex-stuck-detector-watchdog" and .loaded == true and .launchctl_print_exit == 0 and .interval_sec == 60' "installer_first_run_loaded"
assert_jq "$tmp/install-2.json" '.loaded == true and .launchctl_print_exit == 0 and .installer_idempotent == true' "installer_second_run_idempotent"

test -f "$PLIST" && pass "plist_file_exists" || fail "plist_file_exists"
count="$(find "$HOME/Library/LaunchAgents" -maxdepth 1 -name "${LABEL}.plist" -print | wc -l | tr -d ' ')"
[[ "$count" == "1" ]] && pass "single_target_plist" || fail "single_target_plist"

if launchctl print "$DOMAIN/$LABEL" >/dev/null 2>&1; then
  pass "launchctl_print_loaded"
else
  fail "launchctl_print_loaded"
fi

if wait_for_verify "$tmp/verify.out"; then
  grep -q '^OK_watcher_launchd_active' "$tmp/verify.out" && pass "last_run_ts_recent" || fail "last_run_ts_recent"
else
  fail "last_run_ts_recent"
  cat "$tmp/verify.out.err" >&2 || true
fi

if grep -q 'post_callback_reminder_template_with_stale_spinner' "$PATTERN_TEST" && grep -q 'codex-template-stuck-detector.sh' "$PLIST"; then
  pass "scheduled_path_reaches_fixture_pinned_subclass"
else
  fail "scheduled_path_reaches_fixture_pinned_subclass"
fi

if test -s "$INSTALL_LOG" && tail -20 "$INSTALL_LOG" | jq -s -e --arg label "$LABEL" 'any(.[]; .label == $label and .action == "install" and .launchctl_print_exit == 0 and .interval_sec == 60 and .installer_idempotent == true)' >/dev/null; then
  pass "install_log_jsonl"
else
  fail "install_log_jsonl"
fi

if test -s "$LEDGER" && tail -50 "$LEDGER" | jq -s -e 'any(.[]; .schema_version == "codex-stuck-detector.ledger.v1")' >/dev/null; then
  pass "detector_ledger_evidence"
else
  fail "detector_ledger_evidence"
fi

printf 'Summary: %s passed, %s failed\n' "$pass_count" "$fail_count"
[[ "$fail_count" -eq 0 ]]
