# flywheel-2xdi.116 — Evidence Pack

**Bead:** flywheel-2xdi.116 (P3)
**Title:** [gap-memory-without-cross-link] `feedback_jeff_corpus_indexed_data_separates_from_source.md`
**Mission fitness:** `adjacent` — doctrine cross-link unlocks discoverability of jeff-corpus storage discipline
**Sister recipe:** flywheel-2xdi.93, flywheel-2xdi.109 (same forward-link doctrine doc pattern). This is **N=3 → skill discovery promotion candidate**.

## Hypothesis vs root cause (N=22 bead-hypothesis META-rule)

**Bead hypothesis:** memory not cited in commands/doctrine/incidents/plans.

**Verified:**
- Memory EXISTS, 2755 bytes, dated 2026-05-07 (Joshua's directive day)
- Documents the jeff-corpus dual-substrate lifecycle (source bulk DISPOSABLE; indexed embeddings LOAD-BEARING)
- Fresh probe DOES flag it (NOT resolved-upstream like 2xdi.113)
- ZERO existing cross-links in `.flywheel/doctrine/`, `INCIDENTS.md`, `AGENTS.md`, or `~/.claude/commands/flywheel/`

Genuine memory-without-cross-link gap — load-bearing rule that's not yet doctrine-discoverable.

## Fix

Created `.flywheel/doctrine/jeff-corpus-substrate-lifecycle.md` — doctrine doc that:
1. Summarizes the dual-substrate table at canonical-doctrine quality
2. Cites the memory as "Canonical memory source"
3. Documents doctor invariants (4 states: ALERT, GREEN x2, CRITICAL)
4. Documents storage-prune integration (the gating invariant for auto-prune)
5. Documents re-index workflow (clone to /tmp; don't permanently re-clone into ~/Developer/jeff-corpus/)
6. Cross-refs sister doctrine (.flywheel/PLANS/storage-discipline-consolidation/README.md) + sister memory (`feedback_storage_pressure_blocks_substrate`)
7. Anti-pattern + conformance checklist

## Acceptance gates (3/3)

| # | Gate | Status |
|---|---|---|
| AG1: Probe before assuming | DONE — memory exists; fresh probe flags it; 0 cross-links → genuine gap |
| AG2: Create doctrine cross-link | DONE — new doctrine doc cites memory by name |
| AG3: Verify gap cleared | DONE — fresh probe gap_ids no longer contains target |

## Verification

```bash
$ ls /Users/josh/.claude/projects/-Users-josh-Developer-flywheel/memory/feedback_jeff_corpus_indexed_data_separates_from_source.md
-rw-r--r-- 2755 May 6 20:27

$ grep -rln feedback_jeff_corpus_indexed_data_separates_from_source .flywheel/doctrine/ INCIDENTS.md AGENTS.md ~/.claude/commands/flywheel/
# pre-fix: empty
# post-fix:
.flywheel/doctrine/jeff-corpus-substrate-lifecycle.md

$ bash .flywheel/scripts/gap-hunt-probe.sh --json | jq '.gap_ids[] | select(test("memory-without-cross-link.*jeff_corpus_indexed_data_separates"))'
(empty)
```

## DID / DIDNT / GAPS

- **DID 3/3** — gap identified, doctrine doc created, gap cleared
- **DIDNT none**
- **GAPS none**

## Files Changed

- `.flywheel/doctrine/jeff-corpus-substrate-lifecycle.md` (new, doctrine canonical, 105 lines)
- `.flywheel/audit/flywheel-2xdi.116/` (this evidence pack)

No mutation of the memory file itself (consistent with 2xdi.93/.109 pattern — memory is truth source; doctrine cites it).

## L112 Probe

- `l112_probe_command`: `grep -l "feedback_jeff_corpus_indexed_data_separates_from_source" .flywheel/doctrine/ -r | head -1`
- `l112_probe_expected`: `grep:jeff-corpus-substrate-lifecycle.md`
- `l112_probe_timeout_sec`: `5`

## Skill discovery — N=3 promotion candidate

The "forward-link doctrine doc" recipe has now shipped 3 times for the `memory-without-cross-link` class:
1. **2xdi.93** — feedback_cross_repo_consumer_vs_mutator_distinction.md → cross-repo-consumer-vs-mutator-boundary.md
2. **2xdi.109** — feedback_dispatch_post_send_verify_for_silent_deaf.md → dispatch-post-send-verification-silent-deaf.md
3. **2xdi.116** — feedback_jeff_corpus_indexed_data_separates_from_source.md → jeff-corpus-substrate-lifecycle.md

N=3 = promotion threshold. Filed `skill_discoveries=1 sd_ids=pattern-emerged-forward-link-doctrine-doc-recipe-for-memory-without-cross-link-gap-class-N3-promotion-ready`.

Recipe shape (canonical, ready for skill extraction):
1. Read memory file's frontmatter `name` + body
2. Choose doctrine filename: `<topic-noun>-<subject>.md` under `.flywheel/doctrine/`
3. Frontmatter: title, type=doctrine, created, frontmatter_source
4. Body sections: Version/Owner/Status/Source-bead → TL;DR → Canonical memory source (citing the memory file by name) → derived sections (rules / invariants / workflow / when to use) → Sister doctrine + sister memories → Conformance checklist → Anti-pattern
5. Verify: `grep -l <memory-filename> .flywheel/doctrine/ -r` returns the new doc

This is essentially "extract a canonical write-up from a feedback memory and pin it where doctrine grep + socraticode will find it."

## Pattern reinforcement

**13th distinct fix shape** in 2xdi.* cluster (same as 2xdi.93/.109 recipe, now N=3 → skill discovery candidate):
- 47/49/64/66 = probe corpus extensions
- 93/109/116 = doctrine cross-link forward-link **(N=3)**
- 90/92 = test-receiver wire-in
- 100 = INCIDENTS citation
- 101/102 = canonical-cli rename
- dnxjb = probe-finder path filter
- 9a3k1 = auto-bead-filer dedup
- 105/99 = unmanaged-skill direct mutation + paired patch
- 113 = resolve-upstream-no-mutation

## Four-Lens Self-Grade

- **brand:** 10 — N=3 instance triggers skill discovery promotion; faithful sister-pattern
- **sniff:** 10 — verified resolution chain absence (not resolved-upstream like 113) before mutating
- **jeff:** 9 — convergent with 2xdi.* cluster
- **public:** 10 — future operator gets canonical 4-state doctor-invariant table + storage-prune gating invariant + re-index workflow
