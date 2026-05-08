#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd -P)"
BIN="${FLYWHEEL_LOOP_BIN:-$HOME/.claude/skills/.flywheel/bin/flywheel-loop}"
TMP="$(mktemp -d "${TMPDIR:-/tmp}/tmp-lifecycle-doctor.XXXXXX")"
trap 'rm -rf "$TMP"' EXIT

fail() {
  printf 'FAIL: %s\n' "$*" >&2
  exit 1
}

need() {
  command -v "$1" >/dev/null 2>&1 || fail "missing command: $1"
}

need jq

tmp_root="$TMP/private-tmp"
mkdir -p "$tmp_root"
i=0
while [ "$i" -le 11000 ]; do
  : >"$tmp_root/entry-$i"
  i=$((i + 1))
done

storage_fixture="$TMP/storage-healthy.json"
jq -nc '{
  disk_total_gb:926,
  disk_free_gb:400,
  disk_free_pct:43,
  developer_dir_gb:328,
  local_state_gb:2.1,
  stale_baks_count:0,
  stale_baks_size_mb:0,
  qdrant_volumes_size_mb:217,
  tmp_dispatch_artifacts_count:0
}' >"$storage_fixture"

set +e
FLYWHEEL_DOCTOR_CACHE_DISABLE=1 \
FLYWHEEL_DOCTOR_NTM_HEALTH_DISABLED=1 \
FLYWHEEL_TMP_ENTRY_ROOT="$tmp_root" \
FLYWHEEL_STORAGE_PROBE_FIXTURE="$storage_fixture" \
"$BIN" doctor --repo "$ROOT" --json >"$TMP/doctor.json" 2>"$TMP/doctor.err"
rc=$?
set -e

[ "$rc" -ne 0 ] || fail "critical tmp entry count should make doctor exit non-zero"
jq -e '
  .storage.tmp_entry_count == 11001
  and .storage.tmp_entry_count_status == "critical"
  and .storage.status == "fail"
  and any(.storage.errors[]?; .code == "tmp_entry_count_critical")
  and any(.errors[]?; .code == "tmp_entry_count_critical")
' "$TMP/doctor.json" >/dev/null || {
  jq . "$TMP/doctor.json" >&2 || true
  cat "$TMP/doctor.err" >&2 || true
  fail "doctor JSON did not expose tmp_entry_count critical invariant"
}

printf 'PASS: tmp lifecycle doctor invariant\n'
