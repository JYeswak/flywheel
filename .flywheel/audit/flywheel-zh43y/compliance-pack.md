---
bead: flywheel-zh43y
dispatch_task: flywheel-zh43y-4eb3a7
worker: MistyCliff
identity: flywheel:0.4
date: 2026-05-10
total_score: 920/1000
mode: bug-triage-and-partial-fix
---

# Compliance Pack — flywheel-zh43y

## Sniff-rubric

| Axis | Weight | Score | Evidence |
|---|---|---|---|
| Triage rigor | 150 | 150 | All 5 fail codes investigated to root cause via gate-source code reading; each disposition justified |
| Test load-bearingness | 150 | 150 | 11-test regression suite; 4 tests are strict load-bearing (frontmatter presence, mem doctor status, active-dir count=0, archive preservation) |
| AC honesty | 150 | 140 | Top-level status still fail honestly disclosed; 2-of-5 fix narrated transparently; -10 for not also surfacing the new beads in the AC table summary |
| Bead filing discipline | 100 | 100 | 2 new beads filed with full investigation contexts (kmf4z + wz5rh); each bead body cites root cause + 2 fix paths + blocker reason |
| Reservation discipline | 100 | 100 | All 4 mutated paths reserved + released (3 memory files + validation-receipts dir) |
| Sister-pattern + memory cite | 50 | 50 | Cited e5f2f + project_bead_isolation_plan + feedback_beads_jsonl_writes_via_br_only |
| Mission fitness clarity | 50 | 50 | direct + 5→3 fail-codes reduction explicit |
| Self-grade integrity | 50 | 50 | 4-lens with sniff-10 backed by load-bearing assertions |
| Evidence pack completeness | 100 | 100 | evidence + journey + compliance + smoke-doctor + test-run (5 artifacts) |
| Bead close discipline | 100 | 80 | Will close after callback per L120; -20 if any deferred bead has not been confirmed in JSONL (verified inline) |
| **Total** | **1000** | **920** | |

## Four-Lens

### Brand (9/10)
- Triage table follows the e5f2f honest-disclosure shape (root cause +
  disposition + outcome columns)
- Cited 3 prior memories to justify deferrals (project_bead_isolation_plan,
  feedback_beads_jsonl_writes_via_br_only, e5f2f sister)
- DCG-respected throughout
- -1: didn't add a `flywheel-loop repair --scope archive-pre-v1-receipts`
  proposal as a follow-up bead (would have been ergonomic for next time)

### Sniff (10/10)
- Reduced top-level fail_codes from 5 to 3 (deterministic measurement)
- Memory FAIL→WARN verified at 2 layers: file frontmatter inspection +
  `mem memory doctor` status output
- Validation receipts: 8→0 active-dir invalid, 8 preserved in archive
- 11/11 regression tests pass including load-bearing checks for ALL
  artifact-state preservation properties
- Honest AC: top-level still fail (deferred to 2 new beads)

### Jeff (9/10)
- Zero changes to flywheel-loop binary or doctor probe rollup logic;
  only data-layer fixes (frontmatter on memory files, archive of
  schema-invalid receipts)
- 2 new beads created — minimal new-substrate cost
- Reused canonical `mem memory doctor`, `parse.sh`, sqlite3 inspection
- -1: didn't probe for a "list invalid receipts" canonical primitive
  before bulk-archiving (might have existed)

### Public (10/10)
- Three judges check passes:
  - Operator: archive README explains the why; bead filings are
    actionable (each lists 2 fix paths)
  - Maintainer: gate-source code references in evidence link each fix
    to the exact line that flips top-level status
  - Future worker: tests/doctor-non-identity-failures-fixes.sh is a
    self-contained regression suite that doesn't depend on environment
    state beyond the canonical primitives

## DID/DIDNT/GAPS

### DID
- Investigated all 5 fail codes to root cause via gate-source reading
- Fixed #4 (memory_health FAIL→WARN) — added frontmatter to 3 files
- Fixed #5 (validation_receipts 8→0) — archived 8 pre-v1 receipts
- Filed flywheel-kmf4z (loop driver state migration) for #1+#3
- Filed flywheel-wz5rh (beads source_repo basename) for #2
- Wrote 11-test regression suite, all pass
- L107 reservations on 4 paths (3 memory files + receipts dir)

### DIDNT
- **#1+#3 loop_driver**: filed as flywheel-kmf4z; cannot mutate josh's
  loop state file without operator directive (operationally load-bearing)
- **#2 beads leakage**: filed as flywheel-wz5rh; subset of multi-phase
  project_bead_isolation_plan initiative; needs canonical bulk-update path
  that `br update --source-repo` doesn't currently provide

### GAPS
- **canonical archive primitive**: `flywheel-loop repair --scope
  archive-pre-v1-receipts` could canonicalize this fix shape. Noted in
  journey but not filed as a separate bead (skill-discovery candidate).
- **br --source-repo flag upstream**: jeff-stack `br update` lacks a
  `--source-repo` flag needed to fix #2 through canonical write path.
  Could be filed as upstream Jeff issue but deferred to flywheel-wz5rh's
  scope (operator should make the upstream call).

## L112 verify probe

```bash
# 1. Regression test
bash /Users/josh/Developer/flywheel/tests/doctor-non-identity-failures-fixes.sh 2>&1 | tail -1
# expected: SUMMARY pass=11 fail=0

# 2. AC at probe layer for #4 + #5
mem memory doctor 2>&1 | grep -E '^-Users-josh-Developer-flywheel\s+' | awk '{print $2}'
# expected: WARN

PASS=0; FAIL=0
for F in /Users/josh/Developer/flywheel/.flywheel/validation-receipts/*.json; do
  [ -f "$F" ] || continue
  bash /Users/josh/Developer/flywheel/.flywheel/validation-schema/v1/parse.sh "$F" >/dev/null 2>&1 && PASS=$((PASS+1)) || FAIL=$((FAIL+1))
done
echo "active-receipts pass=$PASS fail=$FAIL"
# expected: pass=6 fail=0

# 3. Beads exist
br show flywheel-kmf4z --json | jq -r '.[0].status'  # expected: open
br show flywheel-wz5rh --json | jq -r '.[0].status'  # expected: open
```
