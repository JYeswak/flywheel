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
    --label com.zeststream.fixture.registry \
    --owner {capability-control-plane} \
    --command "$cmd" \
    --interval 120 \
    --json >"$TMP/out.json"

test -s "$TMP/state/substrate-registry.jsonl" && pass "registry_written" || fail "registry_written"
assert_jq "$TMP/state/substrate-registry.jsonl" '.kind == "launchd" and .owner == "{capability-control-plane}" and (.review_due | type == "string" and length > 0)' "registry_kind_owner_review_due"
assert_jq "$TMP/out.json" '.registry_row.kind == "launchd" and .registry_written == true' "register_output_registry_kind"

FLYWHEEL_CRON_REGISTRY_PATH="$TMP/state/substrate-registry.jsonl" "$SCRIPT" list --json >"$TMP/list.json"
assert_jq "$TMP/list.json" '.count == 1 and .jobs[0].label == "com.zeststream.fixture.registry"' "list_reads_launchd_registry"

printf 'SUMMARY pass=%d fail=%d\n' "$pass_count" "$fail_count"
[[ "$fail_count" -eq 0 && "$pass_count" -ge 4 ]]
