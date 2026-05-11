#!/usr/bin/env bash
# .flywheel/tests/test-gap-hunt-probe-wired-but-cold-flywheel-doctrine-corpus.sh
# Filed by flywheel-2xdi.140: lock in probe_wired_but_cold() corpus
# extension to include .flywheel/doctrine/*.md (via command_text) +
# tests/*.sh (via test_files_corpus). 14th META-RULE corpus extension
# this session (sister to 2xdi.88 + 2xdi.98 + 2xdi.106 + 2xdi.112 + ugali).
#
# Pre-2xdi.140: probe_wired_but_cold checked 5 corpora (recent_ledger +
#               sibling_repo + runtime_source + skill_md + launchd_plist).
#               Missed in-flywheel-repo doctrine + tests as canonical
#               receiver evidence.
# Post-2xdi.140: 7 corpora. .flywheel/doctrine/*.md + tests/*.sh now
#               count as receiver-evidence.
#
# Verifies:
#   AG1 — in_flywheel_doctrine + in_test_files checks present + cite flywheel-2xdi.140
#   AG2 — bash -n gap-hunt-probe.sh succeeds
#   AG3 — autoloop-target-selector.sh no longer wired-but-cold flagged
#   AG4 — bcv-task-harness.sh no longer flagged (sister resolution)
#   AG5 — prior corpus checks (skill_md, launchd, source) preserved

set -uo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd -P)"
PROBE="$ROOT/.flywheel/scripts/gap-hunt-probe.sh"

pass=0
fail=0
p() { pass=$((pass+1)); printf 'PASS %s\n' "$1"; }
f() { fail=$((fail+1)); printf 'FAIL %s\n' "$1" >&2; }

# AG1 — new corpora present
if grep -q 'in_flywheel_doctrine' "$PROBE" && grep -q 'in_test_files' "$PROBE" && grep -q 'flywheel-2xdi.140' "$PROBE"; then
  p "AG1 in_flywheel_doctrine + in_test_files + cite present"
else
  f "AG1 new corpora or cite missing"
fi

# AG5 — prior checks preserved
if grep -q 'in_skill_md' "$PROBE" && grep -q 'in_launchd' "$PROBE" && grep -q 'in_source' "$PROBE"; then
  p "AG5 prior 5-corpora checks preserved"
else
  f "AG5 prior corpora check REGRESSED"
fi

# AG2 — syntax
if bash -n "$PROBE" 2>/dev/null; then
  p "AG2 bash -n gap-hunt-probe.sh"
else
  f "AG2 bash -n gap-hunt-probe.sh"
fi

if [[ "${TEST_QUICK:-0}" != "1" ]]; then
  RESULT="$("$PROBE" --json 2>/dev/null)" || { f "live probe invocation failed"; printf '%d passed, %d failed\n' "$pass" "$fail"; exit 1; }

  # AG3 — autoloop-target-selector resolved
  if printf '%s' "$RESULT" | python3 -c '
import sys, json
d = json.load(sys.stdin)
ids = d.get("gap_ids", [])
hits = [g for g in ids if "autoloop-target-selector" in g and g.startswith("wired-but-cold")]
sys.exit(0 if not hits else 1)
'; then
    p "AG3 autoloop-target-selector.sh no longer wired-but-cold"
  else
    f "AG3 autoloop-target-selector.sh STILL flagged"
  fi

  # AG4 — bcv-task-harness resolved (sister test_files_corpus match)
  if printf '%s' "$RESULT" | python3 -c '
import sys, json
d = json.load(sys.stdin)
ids = d.get("gap_ids", [])
hits = [g for g in ids if "bcv-task-harness" in g and g.startswith("wired-but-cold")]
sys.exit(0 if not hits else 1)
'; then
    p "AG4 bcv-task-harness.sh no longer wired-but-cold (sister leverage)"
  else
    f "AG4 bcv-task-harness.sh STILL flagged (no sister leverage)"
  fi
else
  printf 'SKIP AG3/AG4 (TEST_QUICK=1)\n'
fi

printf '%d passed, %d failed\n' "$pass" "$fail"
exit "$fail"
