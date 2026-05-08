#!/usr/bin/env bash
set -euo pipefail

TMP="$(mktemp -d -t doctor-pws.XXXXXX)"
trap 'rm -rf "$TMP"' EXIT
source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)/doctor_pws_common.sh"

: >"$TMP/receipts.jsonl"
doctor_pws_append_false_idle "$TMP/receipts.jsonl" "2026-05-08T00:00:00Z" 2
FLYWHEEL_PANE_WORK_SIGNAL_DISABLE=1 doctor_pws_run "$TMP/receipts.jsonl" "$TMP/out.json"

assert_jq "$TMP/out.json" '.status == "disabled" and .disabled == true' "env_disable_status"
assert_jq "$TMP/out.json" '.disabled_reason == "pws_disabled_via_env"' "env_disable_reason"
assert_jq "$TMP/out.json" '.false_idle_count == 0 and (.warnings | length) == 0 and (.errors | length) == 0' "env_disable_zero_false_disagreements"

doctor_pws_finish 3
