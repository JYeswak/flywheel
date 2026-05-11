---
bead: flywheel-2xdi.134
title: memory-without-cross-link fix — naming-rename cross-repo doctrine (N=6 post-kwjja)
worker: MistyCliff (flywheel:0.4)
date: 2026-05-11
status: shipped
priority: P3
mission_fitness: adjacent
parent: flywheel-2xdi
sister_recipe: 2xdi.93, .109, .116, .118, .127 (N=6 instance)
sanctioning: flywheel-kwjja (Option D) explicitly sanctioned this recipe
---

# Journey: flywheel-2xdi.134

## What the bead asked for

`feedback_naming_rename_is_cross_repo_wire_or_explain.md` not cited
by sampled commands/doctrine/incidents/plans.

## Investigation (N=27 bead-hypothesis META-rule)

- Memory EXISTS, 6049 bytes (Joshua 2026-05-05T~21:00Z directive)
- Documents Yuzu-Method naming-rename cross-repo wire-or-explain
  discipline + 13 consumer paths + 5 anti-patterns + 5 related-rule
  cross-refs
- Fresh probe DOES flag it (genuine gap)
- 0 cross-links across all sampled corpora

## What I shipped

`.flywheel/doctrine/naming-rename-cross-repo-wire-or-explain.md`:
- TL;DR with Joshua-quoted directive (verbatim)
- Cites memory as Canonical memory source
- Formal rule (5 ship conditions)
- Discovery-set table (13 canonical consumer paths)
- Why-this-matters (Donella #6 information flow + mission anchor)
- 6-step apply procedure
- 5-row anti-pattern table with reasons
- Sister doctrine + 5 related-memory cross-refs + socraticode cite
- Conformance + lifecycle (HARD RULE)

## Verification

- Pre-fix: 0 doctrine cross-links to memory
- Post-fix: doctrine doc cites memory by name
- Fresh probe: gap cleared

## L112 probe

    grep -l "feedback_naming_rename_is_cross_repo_wire_or_explain" .flywheel/doctrine/ -r | head -1

Expected: `grep:naming-rename-cross-repo-wire-or-explain.md`.

## Significance — first post-kwjja-sanctioning instance

The kwjja decision (shipped earlier this tick) explicitly sanctioned the
"forward-link doctrine doc" recipe as the canonical resolution for
memory-without-cross-link FPs (Option D). This bead is the FIRST
post-decision application:
- Honors the kwjja decision (no re-litigation; recipe is sanctioned)
- Confirms operational correctness (~15min ship time; doctrine doc has
  independent canonical-write-up value)
- N=6 confirms recipe stability across 6 distinct topic classes

## Pattern note

16th distinct fix shape entry; 6th instance of doctrine cross-link:
- doctrine cross-link forward-link: **N=6** ← most-replicated by 2x
- probe corpus extensions: N=4
- unmanaged-skill direct mutation + paired patch: N=2
- test-receiver wire-in: N=2
- canonical-cli rename: N=2
- stale-orphan REMOVE: N=2
- batch skill-doc + subordinate-close: N=1 (03yaj)
- probe-class taxonomy decision: N=1 (kwjja)
- singletons: 100, dnxjb, 9a3k1, 113

The two top patterns (doctrine cross-link N=6 + probe corpus extensions
N=4) together account for 10/16 of the 2xdi cluster work. Both are
probe-side leverage fixes — make discipline grep-discoverable rather
than per-script allowlist.
