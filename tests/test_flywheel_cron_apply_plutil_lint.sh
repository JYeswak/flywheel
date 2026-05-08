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
    --label com.zeststream.fixture.apply \
    --owner flywheel \
    --command "$cmd" \
    --interval 300 \
    --json >"$TMP/out.json"

plist="$TMP/LaunchAgents/com.zeststream.fixture.apply.plist"
test -s "$plist" && pass "apply_writes_temp_plist" || fail "apply_writes_temp_plist"
plutil -lint "$plist" >/dev/null && pass "apply_plutil_lint" || fail "apply_plutil_lint"
assert_jq "$TMP/out.json" '.status == "applied" and .plutil_validated == true and .launchctl_load_attempted == false' "apply_json_status"
python3 - "$plist" <<'PY'
import plistlib, sys
with open(sys.argv[1], "rb") as fh:
    p = plistlib.load(fh)
assert p["Disabled"] is True
assert p["RunAtLoad"] is True
assert p["EnvironmentVariables"]["PATH"]
PY
pass "apply_plist_disabled_with_path"

printf 'SUMMARY pass=%d fail=%d\n' "$pass_count" "$fail_count"
[[ "$fail_count" -eq 0 && "$pass_count" -ge 4 ]]
