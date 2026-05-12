#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd -P)"
INSTALLER="$ROOT/.flywheel/scripts/install-stuck-detector-watchdog.sh"
VERIFY="$ROOT/.flywheel/scripts/verify-watcher-launchd-active.sh"
PATTERN_TEST="$ROOT/.flywheel/tests/test-detector-pattern-bank-replay.sh"
INSTALL_LOG="$HOME/.local/state/flywheel/watcher-launchd-install.jsonl"
LEDGER="$HOME/.local/state/flywheel/codex-stuck-detector.jsonl"
DOMAIN="${WATCHER_LAUNCHD_DOMAIN:-gui/$(id -u)}"

LABEL_SPECS=(
  "ai.zeststream.codex-stuck-detector-watchdog:flywheel:primary"
  "ai.zeststream.mobile-eats-codex-stuck-detector:mobile-eats:session"
  "ai.zeststream.skillos-codex-stuck-detector:skillos:session"
  "ai.zeststream.alps-codex-stuck-detector:alpsinsurance:session"
  "ai.zeststream.vrtx-codex-stuck-detector:vrtx:session"
)

pass_count=0
fail_count=0

pass() { printf 'PASS %s\n' "$1"; pass_count=$((pass_count + 1)); }
fail() { printf 'FAIL %s\n' "$1" >&2; fail_count=$((fail_count + 1)); }

log_for_session() {
  if [[ "$1" == "flywheel" ]]; then
    printf '%s\n' "$HOME/.local/logs/codex-template-stuck-detector-watchdog.out.log"
  else
    printf '%s\n' "$HOME/.local/state/flywheel/codex-stuck-detector.$1.log"
  fi
}

run_log_has_session() {
  local session="$1" log_path
  log_path="$(log_for_session "$session")"
  test -s "$log_path" || return 1
  tail -200 "$log_path" | jq -s -e --arg session "$session" '
    any(.[]; (.session == $session or any((.panes // [])[]; .session == $session)) and (.ts | type == "string"))
  ' >/dev/null
}

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
for plist in "$ROOT"/.flywheel/launchd/ai.zeststream.*-codex-stuck-detector.plist; do
  plutil -lint "$plist" >/dev/null && pass "source_plist_lint_$(basename "$plist" .plist)" || fail "source_plist_lint_$(basename "$plist" .plist)"
done

tmp="$(mktemp -d "${TMPDIR:-/tmp}/watcher-launchd-active.XXXXXX")"
trap 'rm -rf "$tmp"' EXIT

bash "$INSTALLER" --json >"$tmp/install-1.json"
bash "$INSTALLER" --json >"$tmp/install-2.json"
assert_jq "$tmp/install-1.json" '.label == "ai.zeststream.codex-stuck-detector-watchdog" and .loaded == true and .launchctl_print_exit == 0 and .interval_sec == 60 and (.session_plists | length) == 4 and .all_loaded == true' "installer_first_run_all_loaded"
assert_jq "$tmp/install-2.json" '.loaded == true and .launchctl_print_exit == 0 and .installer_idempotent == true and .plists_installed == 5 and .all_loaded == true' "installer_second_run_idempotent"

for spec in "${LABEL_SPECS[@]}"; do
  IFS=: read -r label session kind <<<"$spec"
  plist="$HOME/Library/LaunchAgents/${label}.plist"
  test -f "$plist" && pass "plist_file_exists_${label}" || fail "plist_file_exists_${label}"
  count="$(find "$HOME/Library/LaunchAgents" -maxdepth 1 -name "${label}.plist" -print | wc -l | tr -d ' ')"
  [[ "$count" == "1" ]] && pass "single_target_plist_${label}" || fail "single_target_plist_${label}"

  if launchctl print "$DOMAIN/$label" >/dev/null 2>&1; then
    pass "launchctl_print_loaded_${label}"
  else
    fail "launchctl_print_loaded_${label}"
  fi

  if [[ "$kind" == "session" ]]; then
    if grep -q "select(.session==\"${session}\")" "$plist" && grep -q -- "--session ${session}" "$plist"; then
      pass "session_scoped_detector_${label}"
    else
      fail "session_scoped_detector_${label}"
    fi
  fi
done

if wait_for_verify "$tmp/verify.out"; then
  grep -q '^OK_watcher_launchd_active' "$tmp/verify.out" && pass "last_run_ts_recent_session_labels" || fail "last_run_ts_recent_session_labels"
else
  fail "last_run_ts_recent_session_labels"
  cat "$tmp/verify.out.err" >&2 || true
fi

if grep -q 'post_callback_reminder_template_with_stale_spinner' "$PATTERN_TEST"; then
  pass "fixture_pinned_subclass_still_present"
else
  fail "fixture_pinned_subclass_still_present"
fi

if test -s "$INSTALL_LOG" && tail -50 "$INSTALL_LOG" | jq -s -e '([.[] | select(.label | test("^ai[.]zeststream[.](codex-stuck-detector-watchdog|mobile-eats-codex-stuck-detector|skillos-codex-stuck-detector|alps-codex-stuck-detector|vrtx-codex-stuck-detector)$"))] | length) >= 5' >/dev/null; then
  pass "install_log_jsonl_all_labels"
else
  fail "install_log_jsonl_all_labels"
fi

if test -s "$LEDGER" && tail -200 "$LEDGER" | jq -s -e '(["flywheel","mobile-eats","skillos","alpsinsurance","vrtx"] - [.[].session] | length) == 0' >/dev/null; then
  pass "detector_shared_ledger_evidence_all_sessions"
else
  fail "detector_shared_ledger_evidence_all_sessions"
fi

log_evidence_ok=1
for spec in "${LABEL_SPECS[@]}"; do
  IFS=: read -r _label session _kind <<<"$spec"
  run_log_has_session "$session" || log_evidence_ok=0
done

if [[ "$log_evidence_ok" == "1" ]]; then
  pass "detector_launchd_log_evidence_all_sessions"
else
  fail "detector_launchd_log_evidence_all_sessions"
fi

printf 'Summary: %s passed, %s failed\n' "$pass_count" "$fail_count"
[[ "$fail_count" -eq 0 ]]
