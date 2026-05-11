# flywheel-2xdi.127 — Evidence Pack

**Bead:** flywheel-2xdi.127 (P3)
**Title:** [gap-memory-without-cross-link] `feedback_legacy_compat_both_empty_either_empty.md`
**Mission fitness:** `adjacent` — doctrine cross-link makes the additive-API discipline grep-discoverable
**Sister recipe (now N=5):** 2xdi.93, 2xdi.109, 2xdi.116, 2xdi.118, **2xdi.127**

## Hypothesis vs root cause (N=24 bead-hypothesis META-rule)

**Bead hypothesis:** memory not cited in commands/doctrine/incidents/plans.

**Verified:**
- Memory EXISTS, 2295 bytes (2026-05-08, originating from same session as the JSM-auth one)
- Documents API additive-compat discipline (Jeff-precedent: ntm#131 working_dir + ntm#132 CM workspace)
- Fresh probe DOES flag it
- ZERO existing cross-links → genuine gap

Memory is operationally critical (any new additive field on a flywheel script's
callback envelope or CLI surface must follow this discipline to avoid breaking
legacy callers).

## Fix

Created `.flywheel/doctrine/api-additive-compat-both-empty-either-empty.md` — doctrine doc that:
1. TL;DR with the formal rule + explicit anti-pattern (reject-when-empty)
2. Cites the memory as "Canonical memory source"
3. Formal-rule pseudocode for the both-non-empty-and-disagree comparison
4. 6-step apply checklist
5. Jeff-precedent quotes from ntm#131 and ntm#132 (with commit SHAs)
6. Anti-pattern table (3 named anti-patterns + reasons)
7. Flywheel applications: `/flywheel:respawn` k4aeu, m482 dispatch lint, nvny skill-discovery fields
8. Sister doctrine + memory cross-refs
9. Conformance + lifecycle sections

## Acceptance gates (3/3)

| # | Gate | Status |
|---|---|---|
| AG1: Probe before assuming | DONE — fresh probe flags it; 0 cross-links → genuine gap |
| AG2: Create doctrine cross-link | DONE — new doctrine doc cites memory + Jeff precedents by name |
| AG3: Verify gap cleared | DONE — fresh probe gap_ids no longer contains target |

## Verification

```bash
$ ls feedback_legacy_compat_both_empty_either_empty.md
-rw-r--r-- 2295 May 7 18:55

$ grep -rln feedback_legacy_compat_both_empty_either_empty .flywheel/doctrine/
# pre-fix: empty
# post-fix:
.flywheel/doctrine/api-additive-compat-both-empty-either-empty.md

$ bash .flywheel/scripts/gap-hunt-probe.sh --json | jq '.gap_ids[] | select(test("memory-without-cross-link.*legacy_compat_both_empty"))'
(empty)
```

## DID / DIDNT / GAPS

- **DID 3/3** — gap identified, doctrine doc created, gap cleared
- **DIDNT none**
- **GAPS none**

## Files Changed

- `.flywheel/doctrine/api-additive-compat-both-empty-either-empty.md` (new, ~115 lines)
- `.flywheel/audit/flywheel-2xdi.127/` (this evidence pack)

No mutation of the memory file itself (consistent with the recipe pattern).

## L112 Probe

- `l112_probe_command`: `grep -l "feedback_legacy_compat_both_empty_either_empty" .flywheel/doctrine/ -r | head -1`
- `l112_probe_expected`: `grep:api-additive-compat-both-empty-either-empty.md`
- `l112_probe_timeout_sec`: `5`

## Recipe replication — N=5 (above promotion threshold)

The "forward-link doctrine doc" recipe is now N=5 instances this session:

1. **2xdi.93**  → cross-repo-consumer-vs-mutator-boundary
2. **2xdi.109** → dispatch-post-send-verification-silent-deaf
3. **2xdi.116** → jeff-corpus-substrate-lifecycle
4. **2xdi.118** → jsm-canonical-auth-contract
5. **2xdi.127** → api-additive-compat-both-empty-either-empty  ← THIS

Recipe applied unchanged across 5 distinct memory topics (cross-repo,
dispatch, storage, auth, API-compat). Promotion threshold (N=3) exceeded
by 2 instances. Skill extraction was filed at 2xdi.116; 2xdi.118 and
2xdi.127 are confirmation instances.

Filed: `pattern-emerged-forward-link-doctrine-doc-recipe-for-memory-without-cross-link-N5-empirically-stable`.

## Pattern reinforcement — cluster shape distribution

The 2xdi.* cluster's most-replicated patterns:
- **doctrine cross-link forward-link**: **N=5** (93, 109, 116, 118, 127) ← now most-replicated
- probe corpus extensions: N=4 (47, 49, 64, 66)
- unmanaged-skill direct mutation + paired patch: N=2 (105, 99)
- test-receiver wire-in: N=2 (90, 92)
- canonical-cli rename: N=2 (101, 102)
- singletons: 100, dnxjb, 9a3k1, 113

Doctrine cross-link has now surpassed probe corpus extensions as the
single most-replicated cluster pattern. All 9 distinct fix shapes in the
cluster remain represented; the distribution skews toward
"grep-discoverable wire-ins" (doctrine docs that cite memory by name)
rather than per-script mutations.

## Four-Lens Self-Grade

- **brand:** 10 — N=5 instance further reinforces the promoted skill discovery; faithful recipe
- **sniff:** 10 — probed before mutation; cited Jeff precedents (ntm#131, ntm#132) verbatim from memory
- **jeff:** 10 — doctrine doc anchors flywheel discipline in Jeff's working-tree shipped precedent
- **public:** 10 — future operator gets formal rule + 6-step checklist + 3 named anti-patterns + 3 flywheel applications + Jeff-precedent quotes in one doc
