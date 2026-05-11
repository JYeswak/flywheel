---
bead: flywheel-2xdi.116
title: memory-without-cross-link fix — jeff-corpus substrate lifecycle doctrine
worker: MistyCliff (flywheel:0.4)
date: 2026-05-11
status: shipped
priority: P3
mission_fitness: adjacent
parent: flywheel-2xdi
sister_recipe: flywheel-2xdi.93, flywheel-2xdi.109 (N=3 instance — skill discovery promotion)
---

# Journey: flywheel-2xdi.116

## What the bead asked for

`feedback_jeff_corpus_indexed_data_separates_from_source.md` not cited
by sampled commands/doctrine/incidents/plans.

## Investigation (N=22 bead-hypothesis META-rule)

Probed before assuming:
- Memory EXISTS, 2755 bytes (Joshua's 2026-05-07 directive day)
- Fresh probe DOES flag it (genuine gap, NOT resolved-upstream like 113)
- 0 cross-links across doctrine/INCIDENTS/AGENTS/commands

Memory documents dual-substrate jeff-corpus lifecycle:
- Source bulk (~9 GB across ~180 repos) DISPOSABLE under invariant
- Indexed embeddings (~3.1 GB across socraticode + jeff-stack + openai) LOAD-BEARING

## What I shipped

`.flywheel/doctrine/jeff-corpus-substrate-lifecycle.md` — doctrine doc:
- TL;DR with 4-row substrate-class table
- Cites memory as Canonical memory source
- 4-state doctor invariant matrix
- Storage-prune gating invariant
- Re-index workflow (clone to /tmp; don't re-permanent into ~/Developer)
- Sister doctrine + memory cross-refs
- Anti-pattern + conformance checklist

## Verification

- Pre-fix: `grep -rln <memory> .flywheel/doctrine/` → empty
- Post-fix: → new doctrine doc
- Fresh probe: gap cleared

## L112 probe

    grep -l "feedback_jeff_corpus_indexed_data_separates_from_source" .flywheel/doctrine/ -r | head -1

Expected: `grep:jeff-corpus-substrate-lifecycle.md`.

## Skill discovery — N=3 promotion candidate

The "forward-link doctrine doc" recipe for memory-without-cross-link
has now shipped 3 times this session:
1. 2xdi.93 — consumer-vs-mutator memory → boundary doctrine
2. 2xdi.109 — silent-deaf memory → dispatch-post-send doctrine
3. 2xdi.116 — jeff-corpus memory → substrate-lifecycle doctrine

N=3 = promotion threshold. Filed
`pattern-emerged-forward-link-doctrine-doc-recipe-for-memory-without-cross-link-gap-class-N3-promotion-ready`.

5-step canonical procedure documented in evidence pack ready for skill
extraction.

## Pattern note

13th distinct fix shape in 2xdi.* cluster. The doctrine cross-link shape
now has N=3 instances and is the most-replicated pattern in the cluster.

Saved a needless skill mutation pass: I could have re-mutated the
memory file or invented a new pattern, but recognized the established
2xdi.93/.109 recipe and applied it faithfully. Pattern proven.
