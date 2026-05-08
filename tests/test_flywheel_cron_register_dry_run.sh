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

mkdir -p "$TMP/bin" "$TMP/LaunchAgents" "$TMP/logs" "$TMP/state" "$TMP/stop"
cmd="$TMP/bin/job.sh"
cat >"$cmd" <<'SH'
#!/usr/bin/env bash
printf 'fixture\n'
SH
chmod +x "$cmd"

FLYWHEEL_CRON_LAUNCHAGENTS_DIR="$TMP/LaunchAgents" \
FLYWHEEL_CRON_LOG_DIR="$TMP/logs" \
FLYWHEEL_CRON_REGISTRY_PATH="$TMP/state/substrate-registry.jsonl" \
FLYWHEEL_CRON_STOP_DIR="$TMP/stop" \
  "$SCRIPT" register \
    --label com.zeststream.fixture.cron \
    --owner flywheel \
    --command "$cmd" \
    --interval 600 \
    --max-runtime 300 \
    --dry-run \
    --json >"$TMP/out.json"

assert_jq "$TMP/out.json" '.dry_run == true and .status == "dry_run"' "dry_run_status"
assert_jq "$TMP/out.json" '.planned_plist.Label == "com.zeststream.fixture.cron" and .planned_plist.StartInterval == 600 and .planned_plist.TimeOut == 300' "planned_plist_shape"
assert_jq "$TMP/out.json" '.registry_row.kind == "launchd" and .registry_row.owner == "flywheel" and (.registry_row.review_due | type == "string" and length > 0)' "registry_row_shape"
assert_jq "$TMP/out.json" '.stop_sentinel_path | endswith("STOP-com.zeststream.fixture.cron")' "stop_sentinel_path"
assert_jq "$TMP/out.json" '.stdout_path and .stderr_path and ."EnvironmentVariables.PATH"' "logs_and_path"

jq -r '.planned_plist_content' "$TMP/out.json" >"$TMP/planned.plist"
plutil -lint "$TMP/planned.plist" >/dev/null && pass "planned_plist_plutil_lint" || fail "planned_plist_plutil_lint"
test ! -e "$TMP/LaunchAgents/com.zeststream.fixture.cron.plist" && pass "dry_run_no_plist_write" || fail "dry_run_no_plist_write"
test ! -e "$TMP/state/substrate-registry.jsonl" && pass "dry_run_no_registry_write" || fail "dry_run_no_registry_write"

printf 'SUMMARY pass=%d fail=%d\n' "$pass_count" "$fail_count"
[[ "$fail_count" -eq 0 && "$pass_count" -ge 8 ]]
