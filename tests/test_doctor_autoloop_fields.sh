#!/usr/bin/env bash
set -euo pipefail

BIN="${FLYWHEEL_LOOP_BIN:-$HOME/.claude/skills/.flywheel/bin/flywheel-loop}"
TMP="$(mktemp -d "${TMPDIR:-/tmp}/doctor-autoloop.XXXXXX")"

pass_count=0
fail_count=0
pass() { printf 'PASS %s\n' "$1"; pass_count=$((pass_count + 1)); }
fail() { printf 'FAIL %s\n' "$1" >&2; fail_count=$((fail_count + 1)); }
assert_jq() {
  local file="$1" filter="$2" label="$3"
  if jq -e "$filter" "$file" >/dev/null; then pass "$label"; else fail "$label"; jq . "$file" >&2 || true; fi
}

repo="$TMP/repo"
mkdir -p "$repo/.flywheel" "$repo/.flywheel/reports" "$TMP/state" "$TMP/bin"
git -C "$repo" init -q >/dev/null 2>&1
printf '# Mission\n\nstatus: ready\n' >"$repo/.flywheel/MISSION.md"
printf '# Goal\n\nstatus: ready\n' >"$repo/.flywheel/GOAL.md"
printf '# State\n\nstatus: ready\n' >"$repo/.flywheel/STATE.md"
printf '# Fixture AGENTS\n' >"$repo/AGENTS.md"
printf '# daily\n' >"$repo/.flywheel/reports/daily-$(date -u +%F).md"
jq -nc '{disk_total_gb:926,disk_free_gb:400,disk_free_pct:43,developer_dir_gb:0,local_state_gb:0,stale_baks_count:0,stale_baks_size_mb:0,qdrant_volumes_size_mb:0,tmp_dispatch_artifacts_count:0}' >"$TMP/storage.json"
printf '#!/usr/bin/env bash\nprintf ok\n' >"$TMP/bin/flywheel-loop"
chmod +x "$TMP/bin/flywheel-loop"

jq -nc --arg ts "$(date -u +%Y-%m-%dT%H:%M:%SZ)" '{ts:$ts,status:"queued"}' >"$TMP/state/last_run.json"
jq -nc '{queue:[{repo:"fixture",score:90},{repo:"other",score:70}]}' >"$TMP/state/queue.json"
jq -nc --arg ts "$(date -u +%Y-%m-%dT%H:%M:%SZ)" '{ts:$ts,event:"autoloop_dispatch_skipped",status:"no_dispatch",repo:"fixture"}' >"$TMP/state/dispatch-log.jsonl"
printf '123\t0\tai.zeststream.flywheel-autoloop\n' >"$TMP/launchctl.txt"

FLYWHEEL_DOCTOR_NTM_HEALTH_DISABLED=1 \
FLYWHEEL_STORAGE_PROBE_FIXTURE="$TMP/storage.json" \
FLYWHEEL_SHARED_SURFACE_RESERVATION_CHECK="$TMP/shared-surface-probe-unavailable" \
FLYWHEEL_LOOP_MONOLITH_PATH="$TMP/bin/flywheel-loop" \
FLYWHEEL_AUTOLOOP_STATE_DIR="$TMP/state" \
FLYWHEEL_AUTOLOOP_LAUNCHCTL_LIST_FIXTURE="$TMP/launchctl.txt" \
FLYWHEEL_CANONICAL_DOCTRINE_PATH="$repo/AGENTS.md" \
  "$BIN" doctor --repo "$repo" --json >"$TMP/doctor.json" 2>"$TMP/doctor.err" || true

assert_jq "$TMP/doctor.json" '.autoloop.schema_version == "flywheel-autoloop-doctor/v1"' "autoloop_object_present"
assert_jq "$TMP/doctor.json" '.autoloop_loaded == true and .autoloop.autoloop_loaded == true' "autoloop_loaded_field"
assert_jq "$TMP/doctor.json" '.autoloop_running == true and .autoloop_last_run_age_sec >= 0' "autoloop_running_age_fields"
assert_jq "$TMP/doctor.json" '.autoloop_queue_depth == 2 and .autoloop_recent_failures == 1' "autoloop_queue_and_failures_fields"

printf 'SUMMARY pass=%d fail=%d\n' "$pass_count" "$fail_count"
[[ "$fail_count" -eq 0 && "$pass_count" -ge 4 ]]
