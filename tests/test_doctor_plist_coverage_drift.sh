#!/usr/bin/env bash
set -euo pipefail

BIN="${FLYWHEEL_LOOP_BIN:-$HOME/.claude/skills/.flywheel/bin/flywheel-loop}"
TMP="$(mktemp -d "${TMPDIR:-/tmp}/plist-coverage-drift.XXXXXX")"

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

repo="$TMP/repo"
mkdir -p "$repo/.flywheel" "$repo/.flywheel/reports" "$TMP/bin"
git -C "$repo" init -q >/dev/null 2>&1
printf '# Mission\n\nstatus: ready\n' >"$repo/.flywheel/MISSION.md"
printf '# Goal\n\nstatus: ready\n' >"$repo/.flywheel/GOAL.md"
printf '# State\n\nstatus: ready\n' >"$repo/.flywheel/STATE.md"
printf '# Fixture AGENTS\n' >"$repo/AGENTS.md"
printf '# daily\n' >"$repo/.flywheel/reports/daily-$(date -u +%F).md"
storage_fixture="$TMP/storage-healthy.json"
jq -nc '{disk_total_gb:926,disk_free_gb:400,disk_free_pct:43,developer_dir_gb:0,local_state_gb:0,stale_baks_count:0,stale_baks_size_mb:0,qdrant_volumes_size_mb:0,tmp_dispatch_artifacts_count:0}' >"$storage_fixture"
short_bin="$TMP/bin/flywheel-loop"
printf '#!/usr/bin/env bash\nprintf ok\n' >"$short_bin"
chmod +x "$short_bin"

write_sessions() {
  local topology="$1" roster="$2"
  shift 2
  : >"$topology"
  : >"$roster"
  local session
  for session in "$@"; do
    jq -nc --arg session "$session" '{session:$session,effective_at:"2026-05-07T00:00:00Z"}' >>"$topology"
    jq -nc --arg session "$session" '{session:$session,ts:"2026-05-07T00:00:00Z"}' >>"$roster"
  done
}

write_plists() {
  local dir="$1"
  shift
  rm -rf "$dir"
  mkdir -p "$dir"
  local session
  for session in "$@"; do
    : >"$dir/com.zeststream.$session.watcher.plist"
  done
}

run_doctor() {
  local topology="$1" roster="$2" plist_dir="$3" out="$4"
  FLYWHEEL_DOCTOR_NTM_HEALTH_DISABLED=1 \
  FLYWHEEL_STORAGE_PROBE_FIXTURE="$storage_fixture" \
  FLYWHEEL_SHARED_SURFACE_RESERVATION_CHECK="$TMP/shared-surface-probe-unavailable" \
  FLYWHEEL_LOOP_MONOLITH_PATH="$short_bin" \
  FLYWHEEL_SESSION_TOPOLOGY="$topology" \
  FLYWHEEL_TEAM_ROSTER="$roster" \
  FLYWHEEL_WATCHER_PLIST_DIR="$plist_dir" \
  FLYWHEEL_CANONICAL_DOCTRINE_PATH="$repo/AGENTS.md" \
  "$BIN" doctor --repo "$repo" --json >"$out" 2>"$out.err" || true
}

bash -n "$HOME/.claude/skills/.flywheel/lib/misc.sh" && pass "misc_syntax" || fail "misc_syntax"
bash -n "$HOME/.claude/skills/.flywheel/lib/portable/core.sh" && pass "portable_core_syntax" || fail "portable_core_syntax"

topology="$TMP/topology-a.jsonl"
roster="$TMP/roster-a.jsonl"
plist_dir="$TMP/plists-a"
write_sessions "$topology" "$roster" fakesession
write_plists "$plist_dir"
run_doctor "$topology" "$roster" "$plist_dir" "$TMP/doctor-a.json"
assert_jq "$TMP/doctor-a.json" '.plist_coverage_drift.severity == "amber" and .plist_coverage_drift.status == "warn"' "fixture_a_single_missing_is_amber"
assert_jq "$TMP/doctor-a.json" '.plist_coverage_drift.sessions_without_plist == ["fakesession"]' "fixture_a_names_missing_session"

topology="$TMP/topology-b.jsonl"
roster="$TMP/roster-b.jsonl"
plist_dir="$TMP/plists-b"
write_sessions "$topology" "$roster" one two three
write_plists "$plist_dir"
run_doctor "$topology" "$roster" "$plist_dir" "$TMP/doctor-b.json"
assert_jq "$TMP/doctor-b.json" '.plist_coverage_drift.severity == "red" and .plist_coverage_drift.status == "fail" and .plist_coverage_drift.missing_count == 3' "fixture_b_three_missing_is_red"
assert_jq "$TMP/doctor-b.json" '.status == "fail"' "fixture_b_red_blocks_doctor"

topology="$TMP/topology-c.jsonl"
roster="$TMP/roster-c.jsonl"
plist_dir="$TMP/plists-c"
write_sessions "$topology" "$roster" alpha
write_plists "$plist_dir" alpha zombie
run_doctor "$topology" "$roster" "$plist_dir" "$TMP/doctor-c.json"
assert_jq "$TMP/doctor-c.json" '.plist_coverage_drift.severity == "ok" and .plist_coverage_drift.plists_without_session == ["zombie"]' "fixture_c_orphan_plist_flagged"

topology="$TMP/topology-d.jsonl"
roster="$TMP/roster-d.jsonl"
plist_dir="$TMP/plists-d"
write_sessions "$topology" "$roster" alpha beta
write_plists "$plist_dir" alpha beta
run_doctor "$topology" "$roster" "$plist_dir" "$TMP/doctor-d.json"
assert_jq "$TMP/doctor-d.json" '.plist_coverage_drift.severity == "ok" and .plist_coverage_drift.sessions_without_plist == [] and .plist_coverage_drift.plists_without_session == []' "fixture_d_clean_state_ok"

printf 'SUMMARY pass=%d fail=%d\n' "$pass_count" "$fail_count"
[[ "$fail_count" -eq 0 && "$pass_count" -ge 8 ]]
