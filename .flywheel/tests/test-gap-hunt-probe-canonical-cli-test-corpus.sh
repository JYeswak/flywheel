#!/usr/bin/env bash
# .flywheel/tests/test-gap-hunt-probe-canonical-cli-test-corpus.sh
# Filed by flywheel-2xdi.88: lock in `*-canonical-cli*.sh` test corpus glob
# extension. Same META-RULE shape as flywheel-2xdi.58 (tests/test_*.sh) +
# flywheel-2xdi.47/.49/.50/.54/.58/.69 + e7lxv + kckw8 — fix the corpus
# property, not the per-script allowlist.
#
# Pre-2xdi.88 corpus glob: ("test-*.sh", "test_*.sh")
# Post-2xdi.88 corpus glob: ("test-*.sh", "test_*.sh", "*-canonical-cli*.sh")
#
# Verifies:
#   AG1 — gap-hunt-probe.sh test_files_corpus glob includes "*-canonical-cli*.sh"
#   AG2 — running gap-hunt-probe.sh does NOT flag mobile-eats-end-user-health-probe.sh
#         (probe has tests/mobile-eats-end-user-health-probe-canonical-cli.sh receiver)
#   AG3 — running gap-hunt-probe.sh does NOT flag operator-fatigue-probe.sh
#         (sister bead flywheel-2xdi.90 — 2-for-1 leverage by this extension)
#   AG4 — prior 2xdi.58 (tests/test_*.sh) allowlist still preserved
#   AG5 — bash -n gap-hunt-probe.sh succeeds (no syntax regression)

set -uo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd -P)"
PROBE="$ROOT/.flywheel/scripts/gap-hunt-probe.sh"

pass=0
fail=0

p() { pass=$((pass+1)); printf 'PASS %s\n' "$1"; }
f() { fail=$((fail+1)); printf 'FAIL %s\n' "$1" >&2; }

# AG1 — glob extension present
if grep -qE 'test-\*\.sh.*test_\*\.sh.*\*-canonical-cli\*\.sh' "$PROBE"; then
  p "AG1 corpus glob includes *-canonical-cli*.sh"
else
  f "AG1 corpus glob missing *-canonical-cli*.sh extension"
fi

# AG5 — syntax check (run first so we don't waste cycles if broken)
if bash -n "$PROBE" 2>/dev/null; then
  p "AG5 bash -n gap-hunt-probe.sh"
else
  f "AG5 bash -n gap-hunt-probe.sh"
fi

# Skip live probe runs in CI-light mode (--quick env flag); run full only when
# operator explicitly invokes
if [[ "${TEST_QUICK:-0}" != "1" ]]; then
  RESULT="$("$PROBE" --json 2>/dev/null)" || { f "live probe invocation failed"; printf '%d passed, %d failed\n' "$pass" "$fail"; exit 1; }

  # AG2 — mobile-eats not flagged
  if printf '%s' "$RESULT" | python3 -c '
import sys, json
d = json.load(sys.stdin)
ids = d.get("gap_ids", [])
hits = [g for g in ids if "mobile-eats-end-user-health-probe" in g and g.startswith("probe-without-receiver")]
sys.exit(0 if not hits else 1)
'; then
    p "AG2 mobile-eats-end-user-health-probe.sh no longer flagged"
  else
    f "AG2 mobile-eats-end-user-health-probe.sh STILL flagged"
  fi

  # AG3 — operator-fatigue not flagged
  if printf '%s' "$RESULT" | python3 -c '
import sys, json
d = json.load(sys.stdin)
ids = d.get("gap_ids", [])
hits = [g for g in ids if "operator-fatigue-probe" in g and g.startswith("probe-without-receiver")]
sys.exit(0 if not hits else 1)
'; then
    p "AG3 operator-fatigue-probe.sh no longer flagged (sister 2xdi.90 also resolved)"
  else
    f "AG3 operator-fatigue-probe.sh STILL flagged"
  fi
else
  printf 'SKIP AG2/AG3 (TEST_QUICK=1; live probe skipped)\n'
fi

# AG4 — prior 2xdi.58 test_*.sh allowlist preserved
if grep -qE 'test_\*\.sh' "$PROBE"; then
  p "AG4 prior 2xdi.58 test_*.sh allowlist preserved"
else
  f "AG4 prior 2xdi.58 test_*.sh allowlist DROPPED (regression)"
fi

printf '%d passed, %d failed\n' "$pass" "$fail"
exit "$fail"
