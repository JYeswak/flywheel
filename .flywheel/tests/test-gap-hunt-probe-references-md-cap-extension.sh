#!/usr/bin/env bash
# .flywheel/tests/test-gap-hunt-probe-references-md-cap-extension.sh
# Filed by flywheel-2xdi.98: lock in 3-pass references/*.md per-file cap
# extension (128 KB). Same META-RULE shape as flywheel-2xdi.66 (which raised
# SKILL.md per-file cap from 4 KB → 256 KB) and 2xdi.88 (canonical-cli test
# corpus glob extension). 10th META-RULE corpus extension this session.
#
# Pre-2xdi.98: 2-pass scan (SKILL.md @ 256 KB, all-other-md @ 4 KB)
# Post-2xdi.98: 3-pass scan (SKILL.md @ 256 KB, references/*.md @ 128 KB, other-md @ 4 KB)
#
# Verifies:
#   AG1 — gap-hunt-probe.sh skill_md_corpus has 3-pass structure with references_md_per_file_cap
#   AG2 — running gap-hunt-probe.sh does NOT flag cubcloud-ops/scripts/litellm-deep-probe.sh
#         (referenced at byte 12925 in cubcloud-ops/references/LITELLM-MODEL-SPEC.md)
#   AG3 — sister beads 2xdi.99 (setup-cubcloud-wireguard) and others not in scope; verify 4 leverage targets
#         (conflict-replay, workspace-export, statusline RESOLVED — but not strict-required since they are sister beads)
#   AG4 — prior 2xdi.66 SKILL.md cap (256 KB) still preserved
#   AG5 — bash -n gap-hunt-probe.sh succeeds (no syntax regression)

set -uo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd -P)"
PROBE="$ROOT/.flywheel/scripts/gap-hunt-probe.sh"

pass=0
fail=0
p() { pass=$((pass+1)); printf 'PASS %s\n' "$1"; }
f() { fail=$((fail+1)); printf 'FAIL %s\n' "$1" >&2; }

# AG1 — references_md_per_file_cap present
if grep -q 'references_md_per_file_cap' "$PROBE" && grep -qE 'references_md_paths' "$PROBE"; then
  p "AG1 references_md_per_file_cap + references_md_paths present (3-pass structure)"
else
  f "AG1 references_md_per_file_cap missing"
fi

# AG4 — prior 2xdi.66 SKILL.md cap preserved
if grep -q 'skill_md_per_file_cap = 256 \* 1024' "$PROBE"; then
  p "AG4 prior 2xdi.66 SKILL.md 256KB cap preserved"
else
  f "AG4 prior 2xdi.66 SKILL.md cap MUTATED (regression)"
fi

# AG5 — syntax
if bash -n "$PROBE" 2>/dev/null; then
  p "AG5 bash -n gap-hunt-probe.sh"
else
  f "AG5 bash -n gap-hunt-probe.sh"
fi

if [[ "${TEST_QUICK:-0}" != "1" ]]; then
  RESULT="$("$PROBE" --json 2>/dev/null)" || { f "live probe invocation failed"; printf '%d passed, %d failed\n' "$pass" "$fail"; exit 1; }

  # AG2 — litellm-deep-probe no longer wired-but-cold flagged
  if printf '%s' "$RESULT" | python3 -c '
import sys, json
d = json.load(sys.stdin)
ids = d.get("gap_ids", [])
hits = [g for g in ids if "litellm-deep-probe" in g and g.startswith("wired-but-cold")]
sys.exit(0 if not hits else 1)
'; then
    p "AG2 litellm-deep-probe.sh no longer wired-but-cold flagged"
  else
    f "AG2 litellm-deep-probe.sh STILL wired-but-cold flagged"
  fi

  # AG3 — sister leverage observations (informational, not strict — 3-of-4 enough for PASS)
  resolved=0
  for stem in conflict-replay workspace-export statusline; do
    if printf '%s' "$RESULT" | python3 -c "
import sys, json
d = json.load(sys.stdin)
ids = d.get('gap_ids', [])
hits = [g for g in ids if '$stem' in g and g.startswith('wired-but-cold')]
sys.exit(0 if not hits else 1)
"; then
      resolved=$((resolved + 1))
    fi
  done
  if [[ "$resolved" -ge 3 ]]; then
    p "AG3 sister-leverage: ${resolved}/3 expected sister resolutions (conflict-replay/workspace-export/statusline)"
  else
    f "AG3 sister-leverage: only ${resolved}/3 sister resolutions"
  fi
else
  printf 'SKIP AG2/AG3 (TEST_QUICK=1; live probe skipped)\n'
fi

printf '%d passed, %d failed\n' "$pass" "$fail"
exit "$fail"
