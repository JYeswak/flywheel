#!/usr/bin/env bash
set -euo pipefail

TMP="$(mktemp -d -t doctor-pws.XXXXXX)"
scratch_parent=""
trap 'rm -rf "$TMP" "${repo:-}"; [[ -n "${scratch_parent:-}" ]] && rmdir "$scratch_parent" 2>/dev/null || true' EXIT
source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)/doctor_pws_common.sh"

scratch_parent="$ROOT/.flywheel/test-scratch"
mkdir -p "$scratch_parent"
repo="$(mktemp -d "$scratch_parent/doctor-pws.XXXXXX")"
(cd "$repo" && "$HOME/.cargo/bin/br" init --prefix flywheel --json >/dev/null)

: >"$TMP/receipts.jsonl"
doctor_pws_append_false_idle "$TMP/receipts.jsonl" "2026-05-08T00:00:00Z" 2
doctor_pws_append_false_idle "$TMP/receipts.jsonl" "2026-05-08T00:05:00Z" 2
doctor_pws_append_false_idle "$TMP/receipts.jsonl" "2026-05-08T00:10:00Z" 2
doctor_pws_run "$TMP/receipts.jsonl" "$TMP/pws.json"
jq -nc --slurpfile pws "$TMP/pws.json" '{status:"fail",pane_work_signal:$pws[0]}' >"$TMP/doctor.json"

DOCTOR_SIGNAL_DOCTOR_JSON_FILE="$TMP/doctor.json" \
BR_BIN="$HOME/.cargo/bin/br" \
  "$ROOT/.flywheel/scripts/doctor-signal-bead-promotion.sh" --repo "$repo" --dry-run >"$TMP/out.json"

assert_jq "$TMP/out.json" '.dry_run == true' "promotion_dry_run_flag"
assert_jq "$TMP/out.json" '.symptoms.pws_false_idle.ntm_codex_false_idle_error_count == 3' "promotion_counts_pws_errors"
assert_jq "$TMP/out.json" '.actions[] | select(contains("pws_false_idle") and contains("dry-run"))' "promotion_dry_run_action"

"$HOME/.cargo/bin/br" create "[auto-doctor:ntm-health-codex-false-idle-followup] existing" \
  --type bug --priority 0 --description fixture --json --db "$repo/.beads/beads.db" >/dev/null

DOCTOR_SIGNAL_DOCTOR_JSON_FILE="$TMP/doctor.json" \
BR_BIN="$HOME/.cargo/bin/br" \
  "$ROOT/.flywheel/scripts/doctor-signal-bead-promotion.sh" --repo "$repo" --dry-run >"$TMP/out-existing.json"

assert_jq "$TMP/out-existing.json" '.actions[] | select(contains("matched:") and contains("pws_false_idle"))' "promotion_idempotent_existing_match"

doctor_pws_finish 4
