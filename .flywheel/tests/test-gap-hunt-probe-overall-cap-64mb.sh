#!/usr/bin/env bash
# .flywheel/tests/test-gap-hunt-probe-overall-cap-64mb.sh
# Filed by flywheel-2xdi.112: lock in skill_md_corpus overall_cap raise
# from 32 MB → 64 MB. Calibration of 2xdi.98 (which raised per-file caps
# for references/*.md to 128 KB but did NOT raise overall_cap, causing
# alphabetically-late skills to be budget-starved).
#
# Pre-2xdi.112: overall_cap = 32 MB → infisical-secrets references at
#                position 3116/3221 unreachable; rotate-cache.sh +
#                validate-identity.sh false-positive wired-but-cold
# Post-2xdi.112: overall_cap = 64 MB → all references/*.md reachable
#                (natural total ~26 MB; SKILL.md ~6 MB; other ~7 MB = 39 MB)
#
# Verifies:
#   AG1 — overall_cap raised to 64 MB (or larger) with flywheel-2xdi.112 cite
#   AG2 — running gap-hunt-probe.sh does NOT flag rotate-cache.sh
#   AG3 — prior 2xdi.98 references_md_per_file_cap (128 KB) still preserved
#   AG4 — prior 2xdi.66 skill_md_per_file_cap (256 KB) still preserved
#   AG5 — bash -n gap-hunt-probe.sh succeeds

set -uo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd -P)"
PROBE="$ROOT/.flywheel/scripts/gap-hunt-probe.sh"

pass=0
fail=0
p() { pass=$((pass+1)); printf 'PASS %s\n' "$1"; }
f() { fail=$((fail+1)); printf 'FAIL %s\n' "$1" >&2; }

# AG1 — overall_cap raised
if grep -qE 'overall_cap.*64_000_000' "$PROBE" && grep -q 'flywheel-2xdi.112' "$PROBE"; then
  p "AG1 overall_cap = 64_000_000 + flywheel-2xdi.112 cite"
else
  f "AG1 overall_cap raise missing or no 2xdi.112 cite"
fi

# AG3 — references_md_per_file_cap (2xdi.98)
if grep -q 'references_md_per_file_cap = 128 \* 1024' "$PROBE"; then
  p "AG3 prior 2xdi.98 references_md_per_file_cap 128 KB preserved"
else
  f "AG3 2xdi.98 references cap REGRESSED"
fi

# AG4 — skill_md_per_file_cap (2xdi.66)
if grep -q 'skill_md_per_file_cap = 256 \* 1024' "$PROBE"; then
  p "AG4 prior 2xdi.66 skill_md_per_file_cap 256 KB preserved"
else
  f "AG4 2xdi.66 SKILL.md cap REGRESSED"
fi

# AG5 — syntax
if bash -n "$PROBE" 2>/dev/null; then
  p "AG5 bash -n gap-hunt-probe.sh"
else
  f "AG5 bash -n gap-hunt-probe.sh"
fi

if [[ "${TEST_QUICK:-0}" != "1" ]]; then
  RESULT="$("$PROBE" --json 2>/dev/null)" || { f "live probe invocation failed"; printf '%d passed, %d failed\n' "$pass" "$fail"; exit 1; }

  # AG2 — rotate-cache no longer flagged
  if printf '%s' "$RESULT" | python3 -c '
import sys, json
d = json.load(sys.stdin)
ids = d.get("gap_ids", [])
hits = [g for g in ids if "rotate-cache" in g and g.startswith("wired-but-cold")]
sys.exit(0 if not hits else 1)
'; then
    p "AG2 infisical-secrets/scripts/rotate-cache.sh no longer wired-but-cold flagged"
  else
    f "AG2 rotate-cache.sh STILL flagged"
  fi
else
  printf 'SKIP AG2 (TEST_QUICK=1; live probe skipped)\n'
fi

printf '%d passed, %d failed\n' "$pass" "$fail"
exit "$fail"
