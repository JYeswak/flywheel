#!/usr/bin/env bash
set -euo pipefail

TMP="$(mktemp -d -t doctor-deferral.XXXXXX)"
trap 'rm -rf "$TMP"' EXIT

pass_count=0
fail_count=0
pass() { printf 'PASS %s\n' "$1"; pass_count=$((pass_count + 1)); }
fail() { printf 'FAIL %s\n' "$1" >&2; fail_count=$((fail_count + 1)); }
assert_jq() {
  local file="$1" filter="$2" label="$3"
  if jq -e "$filter" "$file" >/dev/null; then pass "$label"; else fail "$label"; jq . "$file" >&2 || true; fi
}

source "$HOME/.claude/skills/.flywheel/lib/misc.sh"

FLYWHEEL_DATA_BACKED_DEFERRAL_SAVES_FILE="$TMP/missing-saves.jsonl" \
FLYWHEEL_DATA_BACKED_DEFERRAL_OVERRIDES_FILE="$TMP/missing-overrides.jsonl" \
  doctor_check_data_backed_deferral >"$TMP/doctor.json"

assert_jq "$TMP/doctor.json" '.schema_version == "data-backed-deferral-doctor/v1"' "clean_schema"
assert_jq "$TMP/doctor.json" '.status == "ok"' "clean_status_ok"
assert_jq "$TMP/doctor.json" '.saves_count == 0 and .overrides_count == 0 and .violations_count == 0' "clean_counts_zero"
assert_jq "$TMP/doctor.json" '.last_suggested_action == null' "clean_last_suggested_null"

printf 'SUMMARY pass=%d fail=%d\n' "$pass_count" "$fail_count"
[[ "$fail_count" -eq 0 && "$pass_count" -ge 4 ]]
