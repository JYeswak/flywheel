#!/usr/bin/env bash
set -euo pipefail

STATUS_MD="${HOME}/.claude/commands/flywheel/status.md"

if [[ "${1:-}" == "--help" || "${1:-}" == "-h" || "${2:-}" == "--help" || "${2:-}" == "-h" ]]; then
  printf 'usage: %s [doctor|health|repair|validate|completion --help] [--help]\n' "$(basename "$0")"
  exit 0
fi
case "${1:-}" in
  --info|--schema|--examples|quickstart|help)
    printf 'usage: %s\n' "$(basename "$0")"
    exit 0
    ;;
esac

pass_count=0
fail_count=0
pass() { printf 'PASS %s\n' "$1"; pass_count=$((pass_count + 1)); }
fail() { printf 'FAIL %s\n' "$1" >&2; fail_count=$((fail_count + 1)); }

[ -r "$STATUS_MD" ] && pass "status_md/readable" || fail "status_md/readable"

grep -q 'Mission lock:' "$STATUS_MD" \
  && pass "status_md/mission_lock_line_present" \
  || fail "status_md/mission_lock_line_present"

grep -q 'mission_lock_age' "$STATUS_MD" \
  && pass "status_md/doctor_key_present" \
  || fail "status_md/doctor_key_present"

grep -q 'mission_lock_status' "$STATUS_MD" \
  && pass "status_md/status_key_present" \
  || fail "status_md/status_key_present"

grep -q 'mission_lock_age_hours' "$STATUS_MD" \
  && pass "status_md/age_key_present" \
  || fail "status_md/age_key_present"

grep -q 'warning_code' "$STATUS_MD" \
  && pass "status_md/warning_code_present" \
  || fail "status_md/warning_code_present"

grep -q 'stale-warn.*stale-error.*stale' "$STATUS_MD" \
  && pass "status_md/stale_mapping_present" \
  || fail "status_md/stale_mapping_present"

grep -q '# | agent | state | ctx | last action' "$STATUS_MD" \
  && pass "pane_table/column_shape_preserved" \
  || fail "pane_table/column_shape_preserved"

grep -q 'The source marker belongs in' "$STATUS_MD" && grep -q 'not as a new table column' "$STATUS_MD" \
  && pass "pane_table/no_new_source_column_contract" \
  || fail "pane_table/no_new_source_column_contract"

sample_line="$(jq -rn --argjson d '{"mission_lock_status":"stale-warn","mission_lock_age_hours":192,"reason":"locked_at_gte_7d"}' '
  ($d.mission_lock_status | if . == "fresh" then "fresh" elif test("^stale-") then "stale" else "unknown" end) as $status |
  ($d.mission_lock_age_hours | tostring + "h") as $age |
  ($d.warning_code // $d.reason // (($d.warnings // [])[0]) // "none") as $warning |
  "Mission lock: \($status) age=\($age) warning=\($warning)"
')"
case "$sample_line" in
  "Mission lock: stale age=192h warning=locked_at_gte_7d") pass "line_format/stale_sample_matches" ;;
  *) fail "line_format/stale_sample_matches: $sample_line" ;;
esac

printf '\nResults: %d PASS  %d FAIL\n' "$pass_count" "$fail_count"
[[ "$fail_count" -eq 0 ]]
