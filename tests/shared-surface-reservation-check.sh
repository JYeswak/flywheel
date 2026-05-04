#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd -P)"
SCRIPT="$ROOT/.flywheel/scripts/shared-surface-reservation-check.sh"
TMP="$(mktemp -d "${TMPDIR:-/tmp}/shared-surface-reservation.XXXXXX")"
trap 'rm -rf "$TMP"' EXIT

pass_count=0
fail_count=0

pass() { printf 'PASS %s\n' "$1"; pass_count=$((pass_count + 1)); }
fail() { printf 'FAIL %s\n' "$1" >&2; fail_count=$((fail_count + 1)); }

assert_jq() {
  local file="$1" expr="$2" label="$3"
  if jq -e "$expr" "$file" >/dev/null; then
    pass "$label"
  else
    fail "$label"
    jq . "$file" >&2 || true
  fi
}

LEDGER="$TMP/file-reservations.jsonl"
FUCKUP="$TMP/fuckup-log.jsonl"
COMMON=(--ledger "$LEDGER" --fuckup-log "$FUCKUP" --session flywheel --json)

chmod +x "$SCRIPT"
bash -n "$SCRIPT" && pass "script syntax" || fail "script syntax"

"$SCRIPT" --info --json >"$TMP/info.json"
assert_jq "$TMP/info.json" '.schema_version == "shared-surface-reservation/v1" and (.mutating_commands | index("--reserve"))' "info exposes mutation contract"

"$SCRIPT" --schema --json >"$TMP/schema.json"
assert_jq "$TMP/schema.json" '.exit_codes."1" == "reserved by another pane" and (.commands | index("--check <path>"))' "schema exposes commands and exit codes"

PATH_A="$TMP/shared/flywheel-loop"
PATH_B="$TMP/shared/AGENTS.md"
mkdir -p "$(dirname "$PATH_A")"
: >"$PATH_A"
: >"$PATH_B"

"$SCRIPT" "${COMMON[@]}" --reserve "$PATH_A" --pane=2 --task-id=t1 >"$TMP/reserve-a.json"
assert_jq "$TMP/reserve-a.json" '.status == "reserved" and .pane == "2"' "reserve path from pane 2"

"$SCRIPT" "${COMMON[@]}" --check "$PATH_A" --pane=2 >"$TMP/check-same.json"
assert_jq "$TMP/check-same.json" '.status == "free" and (.holders | length) == 1' "same pane check is free"

set +e
"$SCRIPT" "${COMMON[@]}" --check "$PATH_A" --pane=4 >"$TMP/check-other.json" 2>"$TMP/check-other.err"
rc=$?
set -e
[[ "$rc" -eq 1 ]] && pass "other pane check exits 1" || fail "other pane check exits 1"
assert_jq "$TMP/check-other.json" '.status == "blocked" and .blocking_holders[0].pane == "2" and (.detail | test("coordination-collision-detected"))' "other pane check prints holder"
assert_jq "$FUCKUP" '.trauma_class == "coordination-collision-detected" and (.what_happened | test("pane=4"))' "collision logs fuckup row"

"$SCRIPT" "${COMMON[@]}" --release "$PATH_A" --pane=2 >"$TMP/release-a.json"
assert_jq "$TMP/release-a.json" '.status == "released" and .pane == "2"' "release path"

"$SCRIPT" "${COMMON[@]}" --check "$PATH_A" --pane=4 >"$TMP/check-after-release.json"
assert_jq "$TMP/check-after-release.json" '.status == "free" and (.holders | length) == 0' "released path checks free"

"$SCRIPT" "${COMMON[@]}" --reserve "$PATH_A" --pane=2 --task-id=t2 >/dev/null
"$SCRIPT" "${COMMON[@]}" --reserve "$PATH_B" --pane=2 --task-id=t2 >/dev/null
"$SCRIPT" "${COMMON[@]}" --release "$PATH_A" --pane=2 >/dev/null
"$SCRIPT" "${COMMON[@]}" --list >"$TMP/list.json"
assert_jq "$TMP/list.json" '.active_count == 1 and .reservations[0].path == "'"$(cd "$TMP/shared" && pwd -P)"'/AGENTS.md"' "different paths remain independent"

printf '{bad-json\n' >>"$LEDGER"
"$SCRIPT" "${COMMON[@]}" --check "$PATH_B" --pane=2 >"$TMP/malformed.json"
assert_jq "$TMP/malformed.json" '.status == "free" and .malformed_rows_count == 1 and .warnings[0].code == "malformed_row_skipped"' "malformed JSONL row tolerated"

"$SCRIPT" "${COMMON[@]}" --doctor >"$TMP/doctor.json"
assert_jq "$TMP/doctor.json" '.coordination_collision_count_24h == 1 and .active_reservation_count == 1' "doctor counts 24h collisions and active reservations"

"$SCRIPT" "${COMMON[@]}" --release "$PATH_B" --pane=2 >/dev/null
"$SCRIPT" "${COMMON[@]}" --list >"$TMP/list-empty.json"
assert_jq "$TMP/list-empty.json" '.active_count == 0' "final release clears current set"

if [[ "$fail_count" -gt 0 ]]; then
  printf 'SUMMARY pass=%d fail=%d\n' "$pass_count" "$fail_count" >&2
  exit 1
fi
printf 'SUMMARY pass=%d fail=0\n' "$pass_count"
