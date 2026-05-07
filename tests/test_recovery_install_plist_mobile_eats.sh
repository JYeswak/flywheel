#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd -P)"
SCRIPT="$ROOT/.flywheel/scripts/recovery-install-plist-mobile-eats.sh"
PLIST="/Users/josh/Library/LaunchAgents/com.zeststream.mobile-eats.watcher.plist"
STATUS="$ROOT/.flywheel/receipts/recovery-install-mobile-eats-status.json"

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

bash -n "$SCRIPT" && pass "script_syntax" || fail "script_syntax"
[[ -f "$PLIST" ]] && pass "plist_exists" || fail "plist_exists"
plutil -lint "$PLIST" >/dev/null && pass "plist_lint" || fail "plist_lint"

assert_jq "$STATUS" \
  '.schema_version == "recovery-session-watcher-install/v1"
   and .source_plan == ".flywheel/PLANS/recovery-system-2026-05-01/00-PLAN.md"
   and .label == "com.zeststream.mobile-eats.watcher"
   and .session == "mobile-eats"
   and .plist_path == "/Users/josh/Library/LaunchAgents/com.zeststream.mobile-eats.watcher.plist"
   and .audit_receipt_path == "/tmp/preinstall-mobile-eats.json"
   and .dry_run_pass == true
   and .exactly_one_label == true
   and .reboot_recovery_claimed == false
   and .launchctl_load_attempted == false
   and .mobile_eats_repo_path_validated == true
   and .dashed_name_quoting_validated == true' \
  "status_shape"

assert_jq "$STATUS" \
  '.readiness.ntm_binary.executable == true
   and .readiness.ntm_config.exists == true
   and .readiness.repo.path == "/Users/josh/Developer/mobile-eats"
   and .readiness.repo.exists == true
   and .readiness.logs_dir.exists == true' \
  "readiness_shape"

assert_jq "$STATUS" \
  '.program_arguments[0] == "/Users/josh/.local/bin/ntm"
   and .program_arguments[1] == "watch"
   and .program_arguments[2] == "mobile-eats"
   and (.program_arguments | index("mobile-eats")) == 2
   and .working_directory == "/Users/josh/Developer/mobile-eats"' \
  "dashed_name_program_argument_shape"

printf 'SUMMARY pass=%d fail=%d\n' "$pass_count" "$fail_count"
[[ "$fail_count" -eq 0 && "$pass_count" -ge 6 ]]
