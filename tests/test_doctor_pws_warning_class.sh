#!/usr/bin/env bash
set -euo pipefail

TMP="$(mktemp -d -t doctor-pws.XXXXXX)"
trap 'rm -rf "$TMP"' EXIT
source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)/doctor_pws_common.sh"

: >"$TMP/receipts.jsonl"
doctor_pws_append_false_idle "$TMP/receipts.jsonl" "2026-05-08T00:00:00Z" 2
doctor_pws_run "$TMP/receipts.jsonl" "$TMP/out.json"

assert_jq "$TMP/out.json" '.status == "warn"' "false_idle_single_tick_warns"
assert_jq "$TMP/out.json" '.warnings[] | select(.class == "ntm_codex_false_idle" and .pane == 2 and .capacity == false)' "warning_class_and_capacity_false"
assert_jq "$TMP/out.json" '.disagreements_by_pane["2"] == 1 and .streak_counts["2"] == 1' "warning_counts_by_pane"

doctor_pws_finish 3
