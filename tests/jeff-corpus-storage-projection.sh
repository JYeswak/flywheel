#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd -P)"
PROJECTION="$ROOT/.flywheel/scripts/jeff-corpus-storage-projection.sh"
TMP="$(mktemp -d "${TMPDIR:-/tmp}/jeff-storage-projection.XXXXXX")"
trap 'rm -rf "$TMP"' EXIT

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

repos="$TMP/repos.jsonl"
cat >"$repos" <<'JSONL'
{"name":"a","path":"/tmp/a","index_status":"verified_indexed","qdrant_collection":"codebase_a","qdrant_points":100}
{"name":"b","path":"/tmp/b","index_status":"verified_indexed","qdrant_collection":"codebase_b","qdrant_points":200}
{"name":"c","path":"/tmp/c","index_status":"verified_indexed","qdrant_collection":"codebase_c","qdrant_points":300}
{"name":"d","path":"/tmp/d","index_status":"skipped_budget"}
{"name":"e","path":"/tmp/e","index_status":"skipped_budget"}
JSONL

storage="$TMP/storage.json"
jq -nc '{status:"ok",disk_total_gb:100,disk_free_gb:20,disk_free_pct:20}' >"$storage"
sizes="$TMP/sizes.json"
jq -nc '{codebase_a:10,codebase_b:20,codebase_c:30}' >"$sizes"

bash -n "$PROJECTION" && pass "projection_shell_syntax" || fail "projection_shell_syntax"
python3 -m py_compile "$ROOT/.flywheel/scripts/jeff-corpus-storage-projection.py" && pass "projection_python_syntax" || fail "projection_python_syntax"
"$PROJECTION" --help >/dev/null && pass "projection_help" || fail "projection_help"
"$PROJECTION" --info --json >/dev/null && pass "projection_info" || fail "projection_info"
"$PROJECTION" --examples >/dev/null && pass "projection_examples" || fail "projection_examples"
"$PROJECTION" --version >/dev/null && pass "projection_version" || fail "projection_version"

"$PROJECTION" \
  --repo "$ROOT" \
  --repos-jsonl "$repos" \
  --storage-fixture "$storage" \
  --collection-size-fixture "$sizes" \
  --qdrant-storage-mb 60 \
  --sample-size 3 \
  --scenario-remaining 92 \
  --out "$TMP/projection-state.json" \
  --json >"$TMP/projection.out"

assert_jq "$TMP/projection.out" '.verified_indexed_count == 3 and .remaining_actual_count == 2 and .scenario_remaining_count == 92' "counts_actual_and_scenario"
assert_jq "$TMP/projection.out" '.average_sample_collection_mb == 20 and .average_total_qdrant_mb_per_verified_repo == 20' "sample_and_total_average"
assert_jq "$TMP/projection.out" '.projected_actual_remaining_gb > 0 and .projected_scenario_remaining_gb > 1.7' "projection_gb_fields"
assert_jq "$TMP/projection.out" '.disk_free_gb == 20 and .headroom_above_reserve_gb == 10 and .recommendation == "full"' "headroom_recommendation_full"
assert_jq "$TMP/projection-state.json" '.schema_version == "jeff-corpus-storage-projection/v1"' "state_file_written"

jq -nc '{status:"fail",disk_total_gb:100,disk_free_gb:8,disk_free_pct:8}' >"$TMP/low-storage.json"
set +e
"$PROJECTION" \
  --repo "$ROOT" \
  --repos-jsonl "$repos" \
  --storage-fixture "$TMP/low-storage.json" \
  --collection-size-fixture "$sizes" \
  --qdrant-storage-mb 60 \
  --sample-size 3 \
  --scenario-remaining 92 \
  --out "$TMP/projection-low-state.json" \
  --json >"$TMP/projection-low.out"
rc=$?
set -e
if [[ "$rc" -eq 1 ]]; then pass "low_storage_exit_nonzero"; else fail "low_storage_exit_nonzero"; fi
assert_jq "$TMP/projection-low.out" '.status == "fail" and .recommendation == "increase_headroom_first" and (.warnings[]?.code == "storage_below_reserve")' "low_storage_recommendation"

printf '\nSummary: %s passed, %s failed\n' "$pass_count" "$fail_count"
[[ "$fail_count" -eq 0 ]]
