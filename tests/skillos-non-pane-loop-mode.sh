#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd -P)"
SCRIPT="$ROOT/.flywheel/scripts/gap-hunt-probe.sh"

pass_count=0
fail_count=0

pass() {
  pass_count=$((pass_count + 1))
  printf 'PASS %s\n' "$1"
}

fail() {
  fail_count=$((fail_count + 1))
  printf 'FAIL %s\n' "$1" >&2
}

contains() {
  local needle="$1"
  local label="$2"
  if rg -Fq -- "$needle" "$SCRIPT"; then
    pass "$label"
  else
    fail "$label"
  fi
}

contains "non_pane_loop_mode_signal" "non-pane loop classifier exists"
contains "launchd_prompt_non_pane_loop" "classifier names launchd non-pane reason"
contains "raw_failed_signals" "raw failed signals remain exposed"
contains "non_pane_operating_mode" "classifier evidence remains inspectable"
contains "pane_state_changed_since_last_tick" "pane signal remains modeled"
contains "ledger_writes_since_last_tick" "ledger signal required"
contains "receipt_files_written_since_last_tick" "receipt signal required"
contains "callback_received_in_last_2_ticks" "callback signal required"
contains "fuckup_log_decisions_made_since_last_tick" "decision signal required"
contains "marker_fresh" "marker freshness required"
contains "callback_receipt_fresh" "callback receipt freshness required"
contains "canonical_bridge_fresh" "canonical bridge freshness required"

if [[ "$fail_count" -gt 0 ]]; then
  printf 'SUMMARY pass=%d fail=%d\n' "$pass_count" "$fail_count" >&2
  exit 1
fi

printf 'SUMMARY pass=%d fail=0\n' "$pass_count"
