#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd -P)"
SCRIPT="$ROOT/.flywheel/scripts/storage-pressure-doctor.sh"
TMP="$(mktemp -d "${TMPDIR:-/tmp}/storage-pressure-doctor.XXXXXX")"
trap 'chmod -R u+w "$TMP" 2>/dev/null || true; rm -R "$TMP" 2>/dev/null || true' EXIT

pass_count=0
fail_count=0

pass() { pass_count=$((pass_count + 1)); printf 'PASS %s\n' "$1"; }
fail() { fail_count=$((fail_count + 1)); printf 'FAIL %s\n' "$1" >&2; }

assert_jq() {
  local file="$1" expr="$2" label="$3"
  if jq -e "$expr" "$file" >/dev/null; then
    pass "$label"
  else
    fail "$label"
    jq . "$file" >&2 || true
  fi
}

bash -n "$SCRIPT" && pass "syntax" || fail "syntax"
"$SCRIPT" --schema | jq -e '.properties.status.enum | index("fail")' >/dev/null && pass "schema" || fail "schema"
"$SCRIPT" --info | jq -e '.mutates == []' >/dev/null && pass "info_readonly" || fail "info_readonly"
"$SCRIPT" --examples >/dev/null && pass "examples" || fail "examples"

storage="$TMP/storage-low.json"
top="$TMP/top-consumers.txt"
snapshots="$TMP/snapshots.json"
ledger="$TMP/tmp-prune.jsonl"

jq -nc '{
  version:"storage-probe.v1",
  status:"fail",
  tier:"CRITICAL",
  disk_total_gb:926,
  disk_free_gb:16,
  disk_free_pct:1.73,
  developer_dir_gb:328,
  local_state_gb:2.1,
  stale_baks_count:0,
  stale_baks_size_mb:0,
  qdrant_volumes_size_mb:217,
  tmp_dispatch_artifacts_count:3,
  errors:[{code:"storage_low_headroom"}],
  warnings:[]
}' >"$storage"

cat >"$top" <<'EOF'
332G	/Users/josh/Developer
3.5G	/Users/josh/.knowledge
669M	/Users/josh/.socraticode/qdrant-data
EOF

jq -nc '{
  tm_local_snapshot_count:1,
  apfs_snapshot_count:1,
  sealed_system_snapshot_count:1,
  tm_local_snapshots:["com.apple.TimeMachine.2026-05-09-031000.local"],
  evidence:"fixture"
}' >"$snapshots"

jq -nc '{ts:"2026-05-09T03:00:00Z",deleted_count:12,status:"ok"}' >"$ledger"

set +e
FLYWHEEL_STORAGE_PRESSURE_STORAGE_FIXTURE="$storage" \
FLYWHEEL_STORAGE_PRESSURE_TOP_CONSUMERS_FIXTURE="$top" \
FLYWHEEL_STORAGE_PRESSURE_SNAPSHOT_FIXTURE="$snapshots" \
FLYWHEEL_STORAGE_PRESSURE_TMP_LEDGER_FIXTURE="$ledger" \
FLYWHEEL_STORAGE_PRESSURE_PRIVATE_TMP_GIB_FIXTURE=86 \
  "$SCRIPT" --doctor --json >"$TMP/low.out"
doctor_rc=$?
set -e

if [ "$doctor_rc" -ne 0 ]; then pass "low_storage_exits_nonzero"; else fail "low_storage_exits_nonzero"; fi
assert_jq "$TMP/low.out" '.schema_version == "storage-pressure-doctor/v1" and .status == "fail"' "low_status_fail"
assert_jq "$TMP/low.out" '.top_consumers[0].path == "/Users/josh/Developer" and .top_consumers[0].size_gib == 332' "top_consumer_parsed"
assert_jq "$TMP/low.out" '.snapshots.tm_local_snapshot_count == 1 and .snapshots.sealed_system_snapshot_count == 1' "snapshot_counts"
assert_jq "$TMP/low.out" '.private_tmp.ledger_exists == true and .private_tmp.last_run.deleted_count == 12 and .private_tmp.private_tmp_total_gib == 86' "tmp_ledger_read"
assert_jq "$TMP/low.out" 'any(.recommendations[]; .code == "storage_pressure_active") and any(.recommendations[]; .code == "tm_snapshots_present_under_pressure") and any(.recommendations[]; .code == "private_tmp_large")' "recommendations_include_storage_snapshots_and_tmp"

storage_ok="$TMP/storage-ok.json"
jq -nc '{
  version:"storage-probe.v1",
  status:"ok",
  tier:"OK",
  disk_total_gb:926,
  disk_free_gb:450,
  disk_free_pct:48.6,
  developer_dir_gb:100,
  local_state_gb:2,
  stale_baks_count:0,
  stale_baks_size_mb:0,
  qdrant_volumes_size_mb:0,
  tmp_dispatch_artifacts_count:0,
  errors:[],
  warnings:[]
}' >"$storage_ok"

FLYWHEEL_STORAGE_PRESSURE_STORAGE_FIXTURE="$storage_ok" \
FLYWHEEL_STORAGE_PRESSURE_TOP_CONSUMERS_FIXTURE="$top" \
FLYWHEEL_STORAGE_PRESSURE_SNAPSHOT_FIXTURE="$snapshots" \
FLYWHEEL_STORAGE_PRESSURE_TMP_LEDGER_FIXTURE="$ledger" \
FLYWHEEL_STORAGE_PRESSURE_PRIVATE_TMP_GIB_FIXTURE=1 \
  "$SCRIPT" --doctor --json >"$TMP/ok.out"
assert_jq "$TMP/ok.out" '.status == "warn" and any(.recommendations[]; .code == "top_consumer_review")' "healthy_warns_for_review_only"

printf '\nSummary: %s passed, %s failed\n' "$pass_count" "$fail_count"
test "$fail_count" -eq 0
