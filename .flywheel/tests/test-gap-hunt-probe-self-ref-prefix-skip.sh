#!/usr/bin/env bash
# .flywheel/tests/test-gap-hunt-probe-self-ref-prefix-skip.sh
# Filed by flywheel-ugali: defense-in-depth gap-hunt-* prefix skip in
# recent_ledger_text() + known_silos() symmetric hardening.
#
# Pre-ugali: recent_ledger_text() skipped only main LEDGER (gap-hunt.jsonl);
#            sister ledgers gap-hunt-false-positives.jsonl + gap-hunt-self-
#            calibration-runs.jsonl were INCLUDED. Empirically the current
#            sister schema doesn't carry script names, but future schema
#            changes could reintroduce the self-clearance vulnerability.
# Post-ugali: ANY gap-hunt-* ledger skipped from recent_ledger_text + added
#             to known_silos() default set. Mirrors cross-source-silos
#             allowlist intent for symmetric defense.
#
# Verifies:
#   AG1 — recent_ledger_text() prefix-skips gap-hunt-* + cites flywheel-ugali
#   AG2 — known_silos() default set includes gap-hunt-self-calibration-runs.jsonl
#   AG3 — bash -n gap-hunt-probe.sh succeeds
#   AG4 — running gap-hunt-probe.sh shows no cross-source-silos hits for
#         gap-hunt sister ledgers (would have appeared if sisters weren't skipped)
#   AG5 — build-spend-ledger-rust.sh (mooted by parallel SKILL.md fix per 2xdi.104)
#         remains cleared (no regression from the defense-in-depth change)

set -uo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd -P)"
PROBE="$ROOT/.flywheel/scripts/gap-hunt-probe.sh"

pass=0
fail=0
p() { pass=$((pass+1)); printf 'PASS %s\n' "$1"; }
f() { fail=$((fail+1)); printf 'FAIL %s\n' "$1" >&2; }

# AG1 — prefix-skip + flywheel-ugali cite
if grep -qE 'path\.name\.startswith\("gap-hunt"\)' "$PROBE" && grep -q 'flywheel-ugali' "$PROBE"; then
  p "AG1 recent_ledger_text() prefix-skip + flywheel-ugali cite present"
else
  f "AG1 prefix-skip or 2xdi/ugali cite missing"
fi

# AG2 — known_silos default set includes self-calibration-runs
if grep -q 'gap-hunt-self-calibration-runs.jsonl' "$PROBE"; then
  p "AG2 known_silos() default includes gap-hunt-self-calibration-runs.jsonl"
else
  f "AG2 known_silos() missing gap-hunt-self-calibration-runs.jsonl"
fi

# AG3 — syntax
if bash -n "$PROBE" 2>/dev/null; then
  p "AG3 bash -n gap-hunt-probe.sh"
else
  f "AG3 bash -n gap-hunt-probe.sh"
fi

if [[ "${TEST_QUICK:-0}" != "1" ]]; then
  RESULT="$("$PROBE" --json 2>/dev/null)" || { f "live probe invocation failed"; printf '%d passed, %d failed\n' "$pass" "$fail"; exit 1; }

  # AG4 — no cross-source-silos hits for gap-hunt-* ledgers
  if printf '%s' "$RESULT" | python3 -c '
import sys, json
d = json.load(sys.stdin)
ids = d.get("gap_ids", [])
hits = [g for g in ids if "gap-hunt" in g and g.startswith("cross-source-silos")]
sys.exit(0 if not hits else 1)
'; then
    p "AG4 no cross-source-silos for gap-hunt-* sister ledgers"
  else
    f "AG4 gap-hunt sister ledger STILL flagged cross-source-silos"
  fi

  # AG5 — build-spend-ledger-rust still cleared (no regression)
  if printf '%s' "$RESULT" | python3 -c '
import sys, json
d = json.load(sys.stdin)
ids = d.get("gap_ids", [])
hits = [g for g in ids if "build-spend-ledger-rust" in g and g.startswith("wired-but-cold")]
sys.exit(0 if not hits else 1)
'; then
    p "AG5 build-spend-ledger-rust still cleared (mooted by 2xdi.104 SKILL.md mention; no regression)"
  else
    f "AG5 build-spend-ledger-rust now flagged (regression?)"
  fi
else
  printf 'SKIP AG4/AG5 (TEST_QUICK=1; live probe skipped)\n'
fi

printf '%d passed, %d failed\n' "$pass" "$fail"
exit "$fail"
