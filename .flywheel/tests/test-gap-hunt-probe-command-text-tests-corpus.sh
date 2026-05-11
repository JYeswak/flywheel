#!/usr/bin/env bash
# .flywheel/tests/test-gap-hunt-probe-command-text-tests-corpus.sh
# Filed by flywheel-2xdi.106: lock in command_text() (cross-source-silos
# receivers) extension to include tests/*-canonical-cli*.sh + test-/test_
# prefix-style regression tests. 11th META-RULE corpus extension this
# session (sister to 2xdi.47/48/49/50/54/58/69/88/98, e7lxv, kckw8 +
# nq5ns's producer-stem fallback).
#
# Pre-2xdi.106: receivers = AGENTS+INCIDENTS+README + doctrine/*.md +
#               rules/*.md + commands/flywheel/*.md (NO tests)
# Post-2xdi.106: + .flywheel/tests/ + tests/ (test-*.sh, test_*.sh,
#                  *-canonical-cli*.sh) at 50 KB per-file cap
#
# Verifies:
#   AG1 — command_text() body cites flywheel-2xdi.106 + has test_roots loop
#   AG2 — running gap-hunt-probe.sh does NOT flag ntm-approve-human-gates-runs.jsonl
#   AG3 — sister leverage: cross-source-silos count dropped ≥ 12 (from 18 to ≤6)
#   AG4 — prior nq5ns producer-stem fallback still preserved
#   AG5 — bash -n gap-hunt-probe.sh succeeds

set -uo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd -P)"
PROBE="$ROOT/.flywheel/scripts/gap-hunt-probe.sh"

pass=0
fail=0
p() { pass=$((pass+1)); printf 'PASS %s\n' "$1"; }
f() { fail=$((fail+1)); printf 'FAIL %s\n' "$1" >&2; }

# AG1 — extension present in command_text
if grep -q 'flywheel-2xdi.106' "$PROBE" && grep -q 'test_roots' "$PROBE"; then
  p "AG1 command_text() flywheel-2xdi.106 extension + test_roots loop present"
else
  f "AG1 command_text() extension missing"
fi

# AG4 — prior nq5ns producer-stem fallback preserved
if grep -q 'producer_stem' "$PROBE" && grep -qE 'producer_stem.*endswith.*-runs' "$PROBE"; then
  p "AG4 prior nq5ns producer-stem fallback preserved"
else
  f "AG4 nq5ns producer-stem fallback REGRESSED"
fi

# AG5 — syntax
if bash -n "$PROBE" 2>/dev/null; then
  p "AG5 bash -n gap-hunt-probe.sh"
else
  f "AG5 bash -n gap-hunt-probe.sh"
fi

if [[ "${TEST_QUICK:-0}" != "1" ]]; then
  RESULT="$("$PROBE" --json 2>/dev/null)" || { f "live probe invocation failed"; printf '%d passed, %d failed\n' "$pass" "$fail"; exit 1; }

  # AG2 — ntm-approve-human-gates no longer flagged
  if printf '%s' "$RESULT" | python3 -c '
import sys, json
d = json.load(sys.stdin)
ids = d.get("gap_ids", [])
hits = [g for g in ids if "ntm-approve-human-gates" in g and g.startswith("cross-source-silos")]
sys.exit(0 if not hits else 1)
'; then
    p "AG2 ntm-approve-human-gates-runs.jsonl no longer cross-source-silos flagged"
  else
    f "AG2 ntm-approve-human-gates-runs.jsonl STILL flagged"
  fi

  # AG3 — cross-source-silos count dropped (was 18 pre-fix, expect ≤6)
  CSS_COUNT=$(printf '%s' "$RESULT" | python3 -c '
import sys, json
d = json.load(sys.stdin)
ids = d.get("gap_ids", [])
print(sum(1 for g in ids if g.startswith("cross-source-silos")))
')
  if [[ "$CSS_COUNT" -le 6 ]]; then
    p "AG3 cross-source-silos count post-fix=$CSS_COUNT (≤6 means ≥12 sister resolutions vs pre-fix 18)"
  else
    f "AG3 cross-source-silos count post-fix=$CSS_COUNT > 6 (expected ≤6)"
  fi
else
  printf 'SKIP AG2/AG3 (TEST_QUICK=1; live probe skipped)\n'
fi

printf '%d passed, %d failed\n' "$pass" "$fail"
exit "$fail"
