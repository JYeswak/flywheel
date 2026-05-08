#!/usr/bin/env bash
set -euo pipefail

TMP="$(mktemp -d -t doctor-pws.XXXXXX)"
trap 'rm -rf "$TMP"' EXIT
source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)/doctor_pws_common.sh"

: >"$TMP/receipts.jsonl"
doctor_pws_append_false_idle "$TMP/receipts.jsonl" "2026-05-08T00:00:00Z" 2
doctor_pws_append_false_idle "$TMP/receipts.jsonl" "2026-05-08T00:05:00Z" 2
doctor_pws_append_false_idle "$TMP/receipts.jsonl" "2026-05-08T00:10:00Z" 2
doctor_pws_run "$TMP/receipts.jsonl" "$TMP/out.json"

assert_jq "$TMP/out.json" '.status == "fail"' "three_tick_streak_fails"
assert_jq "$TMP/out.json" '.streak_counts["2"] == 3' "three_tick_streak_count_recorded"
assert_jq "$TMP/out.json" '(.errors | length) == 3 and (.errors[] | select(.class == "ntm_codex_false_idle" and .severity == "error"))' "three_tick_streak_errors"

doctor_pws_finish 3
