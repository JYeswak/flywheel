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

jq -nc --arg ts "$(date -u +%Y-%m-%dT%H:%M:%SZ)" '{ts:$ts,event:"data_backed_deferral_prevented",suggested_action_summary:"dispatch the selected bead"}' >"$TMP/saves.jsonl"
jq -nc --arg ts "$(date -u +%Y-%m-%dT%H:%M:%SZ)" '{ts:$ts,event:"data_backed_deferral_override",reason:"orch_question_when_data_clear",details:"fixture"}' >"$TMP/overrides.jsonl"

FLYWHEEL_DATA_BACKED_DEFERRAL_SAVES_FILE="$TMP/saves.jsonl" \
FLYWHEEL_DATA_BACKED_DEFERRAL_OVERRIDES_FILE="$TMP/overrides.jsonl" \
  doctor_check_data_backed_deferral >"$TMP/doctor.json"

assert_jq "$TMP/doctor.json" '.status == "warn"' "one_violation_warns"
assert_jq "$TMP/doctor.json" '.saves_count == 1 and .overrides_count == 1 and .violations_count == 1' "warn_counts_numeric"
assert_jq "$TMP/doctor.json" '.status | IN("ok","warn","fail")' "warn_status_ladder_enum"
assert_jq "$TMP/doctor.json" '.last_suggested_action == "dispatch the selected bead"' "warn_last_suggested_summary"

printf 'SUMMARY pass=%d fail=%d\n' "$pass_count" "$fail_count"
[[ "$fail_count" -eq 0 && "$pass_count" -ge 4 ]]
