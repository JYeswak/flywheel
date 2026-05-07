#!/usr/bin/env bash
set -euo pipefail

BIN="${FLYWHEEL_LOOP_BIN:-$HOME/.claude/skills/.flywheel/bin/flywheel-loop}"
TMP="$(mktemp -d "${TMPDIR:-/tmp}/monolith-size-regression.XXXXXX")"

pass_count=0
fail_count=0
pass() { printf 'PASS %s\n' "$1"; pass_count=$((pass_count + 1)); }
fail() { printf 'FAIL %s\n' "$1"; fail_count=$((fail_count + 1)); }

assert_jq() {
  local file="$1" filter="$2" label="$3"
  if jq -e "$filter" "$file" >/dev/null; then
    pass "$label"
  else
    fail "$label"
    jq . "$file" || true
  fi
}

repo="$TMP/repo"
mkdir -p "$repo/.flywheel"
git -C "$repo" init -q >/dev/null 2>&1
printf '# Mission\n\nstatus: ready\n' >"$repo/.flywheel/MISSION.md"
printf '# Goal\n\nstatus: ready\n' >"$repo/.flywheel/GOAL.md"
printf '# State\n\nstatus: ready\n' >"$repo/.flywheel/STATE.md"
storage_fixture="$TMP/storage-healthy.json"
jq -nc '{disk_total_gb:926,disk_free_gb:400,disk_free_pct:43,developer_dir_gb:0,local_state_gb:0,stale_baks_count:0,stale_baks_size_mb:0,qdrant_volumes_size_mb:0,tmp_dispatch_artifacts_count:0}' >"$storage_fixture"

long_bin="$TMP/flywheel-loop-long"
{
  printf '#!/usr/bin/env bash\n'
  awk 'BEGIN { for (i = 0; i < 510; i++) print "printf ok" }'
} >"$long_bin"
chmod +x "$long_bin"

FLYWHEEL_DOCTOR_NTM_HEALTH_DISABLED=1 \
FLYWHEEL_STORAGE_PROBE_FIXTURE="$storage_fixture" \
FLYWHEEL_SHARED_SURFACE_RESERVATION_CHECK="$TMP/shared-surface-probe-unavailable" \
FLYWHEEL_LOOP_MONOLITH_PATH="$long_bin" \
"$BIN" doctor --repo "$repo" --json >"$TMP/doctor.json" 2>"$TMP/doctor.err" || true

assert_jq "$TMP/doctor.json" '.monolith_size_regression.status == "fail"' "monolith_size_regression_status"
assert_jq "$TMP/doctor.json" '.monolith_size_regression.lines > 500' "monolith_size_regression_line_count"
assert_jq "$TMP/doctor.json" '.status == "fail" and .action == "split_flywheel_loop_dispatcher"' "monolith_size_regression_blocks_doctor"

printf '\nSummary: %s passed, %s failed\n' "$pass_count" "$fail_count"
[[ "$fail_count" -eq 0 ]]
