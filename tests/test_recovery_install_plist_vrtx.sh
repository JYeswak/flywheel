#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd -P)"
PLIST="/Users/josh/Library/LaunchAgents/com.zeststream.vrtx.watcher.plist"
STATUS="$ROOT/.flywheel/receipts/recovery-install-vrtx-status.json"

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

[[ -f "$PLIST" ]] && pass "plist_exists" || fail "plist_exists"
plutil -lint "$PLIST" >/dev/null && pass "plist_lint" || fail "plist_lint"

assert_jq "$STATUS" \
  '.schema_version == "recovery-session-watcher-install/v1"
   and .source_plan == ".flywheel/PLANS/recovery-system-2026-05-01/00-PLAN.md"
   and .label == "com.zeststream.vrtx.watcher"
   and .session == "vrtx"
   and .plist_path == "/Users/josh/Library/LaunchAgents/com.zeststream.vrtx.watcher.plist"
   and .audit_receipt_path == "/tmp/preinstall-vrtx.json"
   and .dry_run_pass == true
   and .exactly_one_label == true
   and .reboot_recovery_claimed == false
   and .launchctl_load_attempted == false
   and .vrtx_repo_path_validated == true' \
  "status_shape"

assert_jq "$STATUS" \
  '.readiness.ntm_binary.executable == true
   and .readiness.ntm_config.exists == true
   and .readiness.repo.path == "/Users/josh/Developer/vrtx"
   and .readiness.repo.exists == true
   and .readiness.logs_dir.exists == true' \
  "readiness_shape"

assert_jq "$STATUS" \
  '.program_arguments[0] == "/Users/josh/.local/bin/ntm"
   and .program_arguments[1] == "watch"
   and .program_arguments[2] == "vrtx"
   and .working_directory == "/Users/josh/Developer/vrtx"
   and .watcher_race_and_stale_path_probe.working_directory_matches_topology == true
   and .watcher_race_and_stale_path_probe.working_directory_matches_ntm_config == true' \
  "runtime_path_shape"

cat "$STATUS"

printf 'SUMMARY pass=%d fail=%d\n' "$pass_count" "$fail_count"
[[ "$fail_count" -eq 0 && "$pass_count" -ge 5 ]]
