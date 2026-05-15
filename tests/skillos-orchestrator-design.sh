#!/usr/bin/env bash
set -u

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd -P)"
DOC="$ROOT/.flywheel/PLANS/skillos-orchestrator-design-2026-05-14.md"

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
  if rg -Fq -- "$needle" "$DOC"; then
    pass "$label"
  else
    fail "$label"
  fi
}

if [[ -f "$DOC" ]]; then
  pass "design refresh doc exists"
else
  fail "design refresh doc exists"
fi

contains "flywheel.skillos_orchestrator_design_refresh.v1" "schema marker present"
contains "flywheel-668a" "parent bead cited"
contains "flywheel-hg2w" "dependent apply bead cited"
contains "pane_state_changed_since_last_tick" "old pane signal preserved"
contains "fuckup_decisions_made_since_last_tick" "old fuckup signal preserved"
contains "callback_receipt_fresh" "current callback signal cited"
contains "canonical_bridge_fresh" "current bridge signal cited"
contains "ledger_writes_since_last_tick" "full doctor ledger signal cited"
contains '"verdict": "LIMPING"' "bounded verdict remains limping"
contains '"verdict": "DEAD"' "full doctor verdict remains dead"
contains "flywheel-2xdi.165" "gap-hunt filed new gap bead 165"
contains "flywheel-2xdi.166" "gap-hunt filed new gap bead 166"
contains "flywheel-2xdi.167" "gap-hunt filed new gap bead 167"
contains "No direct writes to" "cross-repo boundary heading preserved"
contains "/Users/josh/Developer/skillos" "cross-repo boundary path preserved"
contains "No closure of" "apply bead non-closure preserved"

if br show flywheel-hg2w --json 2>/dev/null \
  | jq -e '.[0].status != "closed"' >/dev/null; then
  pass "flywheel-hg2w remains open"
else
  fail "flywheel-hg2w remains open"
fi

if [[ "$fail_count" -gt 0 ]]; then
  printf 'SUMMARY pass=%d fail=%d\n' "$pass_count" "$fail_count" >&2
  exit 1
fi

printf 'SUMMARY pass=%d fail=0\n' "$pass_count"
