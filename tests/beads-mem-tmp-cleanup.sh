#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd -P)"
SCRIPT="$ROOT/.flywheel/scripts/beads-mem-tmp-cleanup.py"
TMP="$(mktemp -d "${TMPDIR:-/tmp}/beads-mem-cleanup-test.XXXXXX")"
trap 'kill "${OPEN_PID:-}" 2>/dev/null || true; rm -rf "$TMP"' EXIT

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

old_file() {
  local path="$1" size="${2:-payload}"
  printf '%s\n' "$size" >"$path"
  touch -t 202001010101 "$path"
}

head -n 1 "$SCRIPT" | grep -qx '#!/usr/bin/env python3' && pass "script_shebang"
python3 -m py_compile "$SCRIPT" && pass "python_compile"

"$SCRIPT" --schema --json >"$TMP/schema.json"
assert_jq "$TMP/schema.json" '.default_mode == "dry-run" and (.mutation_modes | index("--apply")) and .scope.depth == "top-level files only" and .scope.filename_regex == "^beads_mem_[0-9]+_0\\.db(?:-wal|-shm)?$"' "schema_scope"

fixture="$TMP/T"
mkdir -p "$fixture/nested" "$TMP/bin"
old_file "$fixture/beads_mem_100_0.db" "delete-db"
old_file "$fixture/beads_mem_100_0.db-wal" "delete-wal"
old_file "$fixture/beads_mem_100_0.db-shm" "delete-shm"
old_file "$fixture/beads_mem_100_1.db" "wrong-index"
old_file "$fixture/not_beads_mem_100_0.db" "wrong-prefix"
old_file "$fixture/nested/beads_mem_200_0.db" "nested"
printf 'young\n' >"$fixture/beads_mem_300_0.db"

cat >"$TMP/doctor.json" <<'JSON'
{"status":"warn","storage":{"disk_free_gb":10},"private_tmp":{"private_tmp_total_gib":186}}
JSON

"$SCRIPT" --tmpdir "$fixture" --min-age-seconds 60 --ledger "$TMP/ledger.jsonl" --doctor-fixture "$TMP/doctor.json" --dry-run --json >"$TMP/dry.json"
assert_jq "$TMP/dry.json" '.status == "ok" and .dry_run == true and .planned_count == 3 and .deleted_count == 0' "dry_run_plans_only_old_matching_top_level"
assert_jq "$TMP/dry.json" '.skipped_count == 1 and any(.files[]; .name == "beads_mem_300_0.db" and .reason == "too_young")' "too_young_protected"
assert_jq "$TMP/dry.json" '.lsof.checked_count == 4 and .post_run_storage_pressure_doctor.status == "warn"' "ledger_fields_present"
test -e "$fixture/beads_mem_100_0.db" && pass "dry_run_no_mutation"

if "$SCRIPT" --tmpdir "$fixture" --apply --min-age-seconds 60 --ledger "$TMP/ledger.jsonl" --json >"$TMP/apply-no-key.json" 2>"$TMP/apply-no-key.err"; then
  fail "apply_requires_idempotency_key"
else
  pass "apply_requires_idempotency_key"
fi

"$SCRIPT" --tmpdir "$fixture" --apply --idempotency-key test-key --min-age-seconds 60 --ledger "$TMP/ledger.jsonl" --doctor-fixture "$TMP/doctor.json" --json >"$TMP/apply.json"
assert_jq "$TMP/apply.json" '.status == "ok" and .apply == true and .planned_count == 3 and .deleted_count == 3 and .deleted_bytes > 0' "apply_deletes_only_planned"
for removed in beads_mem_100_0.db beads_mem_100_0.db-wal beads_mem_100_0.db-shm; do
  if [ ! -e "$fixture/$removed" ]; then pass "removed/$removed"; else fail "removed/$removed"; fi
done
for protected in beads_mem_100_1.db not_beads_mem_100_0.db nested/beads_mem_200_0.db beads_mem_300_0.db; do
  if [ -e "$fixture/$protected" ]; then pass "protected/$protected"; else fail "protected/$protected"; fi
done

open_fixture="$TMP/open-T"
mkdir -p "$open_fixture"
old_file "$open_fixture/beads_mem_400_0.db" "open"
python3 - "$open_fixture/beads_mem_400_0.db" <<'PY' &
import pathlib
import sys
import time

handle = pathlib.Path(sys.argv[1]).open("r")
try:
    time.sleep(20)
finally:
    handle.close()
PY
OPEN_PID=$!
sleep 1
"$SCRIPT" --tmpdir "$open_fixture" --apply --idempotency-key open-key --min-age-seconds 60 --ledger "$TMP/ledger.jsonl" --doctor-fixture "$TMP/doctor.json" --json >"$TMP/open.json"
assert_jq "$TMP/open.json" '.planned_count == 0 and .skipped_count == 1 and any(.files[]; .reason == "open_handle" and .lsof_open == true)' "open_handle_skipped"
test -e "$open_fixture/beads_mem_400_0.db" && pass "open_file_survives"

assert_jq "$TMP/ledger.jsonl" 'select(.schema_version == "beads-mem-tmp-cleanup/v1" and .age_threshold_seconds == 60 and (.lsof.checked_count >= 1) and (.post_run_storage_pressure_doctor.status == "warn"))' "jsonl_ledger_records_required_fields"

if [ "$fail_count" -ne 0 ]; then
  printf 'FAIL: %s failures, %s passes\n' "$fail_count" "$pass_count" >&2
  exit 1
fi
printf 'PASS beads_mem_tmp_cleanup: %s checks\n' "$pass_count"
