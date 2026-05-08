#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd -P)"
SCRIPT="$ROOT/.flywheel/scripts/flywheel-cron.sh"
TMP="$(mktemp -d -t flywheel-cron.XXXXXX)"
trap 'chmod -R u+w "$TMP" 2>/dev/null || true; find "$TMP" -mindepth 1 -delete 2>/dev/null || true; rmdir "$TMP" 2>/dev/null || true' EXIT

pass_count=0
fail_count=0
pass() { printf 'PASS %s\n' "$1"; pass_count=$((pass_count + 1)); }
fail() { printf 'FAIL %s\n' "$1" >&2; fail_count=$((fail_count + 1)); }
assert_jq() {
  local file="$1" filter="$2" label="$3"
  if jq -e "$filter" "$file" >/dev/null; then pass "$label"; else fail "$label"; jq . "$file" >&2 || true; fi
}

mkdir -p "$TMP/LaunchAgents"
export FLYWHEEL_CRON_LAUNCHAGENTS_DIR="$TMP/LaunchAgents"
label="com.zeststream.fixture.lifecycle"

"$SCRIPT" remove --label "$label" --dry-run --json >"$TMP/remove.json"
"$SCRIPT" pause --label "$label" --dry-run --json >"$TMP/pause.json"
"$SCRIPT" resume --label "$label" --dry-run --json >"$TMP/resume.json"

assert_jq "$TMP/remove.json" '.dry_run == true and .launchctl_action.argv[1] == "bootout" and .plist_mutations[0].action == "delete_plist"' "remove_dry_run_actions"
assert_jq "$TMP/pause.json" '.dry_run == true and .launchctl_action.argv[1] == "bootout" and .plist_mutations[0].Disabled == true' "pause_dry_run_actions"
assert_jq "$TMP/resume.json" '.dry_run == true and .launchctl_action.argv[1] == "bootstrap" and .plist_mutations[0].Disabled == false' "resume_dry_run_actions"
test ! -e "$TMP/LaunchAgents/$label.plist" && pass "dry_run_no_mutation" || fail "dry_run_no_mutation"

printf 'SUMMARY pass=%d fail=%d\n' "$pass_count" "$fail_count"
[[ "$fail_count" -eq 0 && "$pass_count" -ge 4 ]]
