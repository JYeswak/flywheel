#!/usr/bin/env bash
set -euo pipefail

TMP="$(mktemp -d -t doctor-pws.XXXXXX)"
trap 'rm -rf "$TMP"' EXIT
source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)/doctor_pws_common.sh"

: >"$TMP/receipts.jsonl"
doctor_pws_append_false_idle "$TMP/receipts.jsonl" "2026-05-08T00:00:00Z" 2
doctor_pws_append_false_idle "$TMP/receipts.jsonl" "2026-05-08T00:31:00Z" 2
doctor_pws_run "$TMP/receipts.jsonl" "$TMP/out.json"

assert_jq "$TMP/out.json" '.status == "fail"' "thirty_min_streak_fails"
assert_jq "$TMP/out.json" '.duration_seconds_by_pane["2"] > 1800' "thirty_min_duration_recorded"
assert_jq "$TMP/out.json" '(.errors | length) == 2 and (.errors[] | select(.class == "ntm_codex_false_idle"))' "thirty_min_errors_classified"

doctor_pws_finish 3
