---
bead: flywheel-2xdi.93
title: memory-without-cross-link fix — consumer-vs-mutator doctrine doc created
worker: MistyCliff (flywheel:0.4)
date: 2026-05-11
status: shipped
priority: P3
mission_fitness: adjacent
parent: flywheel-2xdi
---

# Journey: flywheel-2xdi.93

## What the bead asked for

Memory file `feedback_cross_repo_consumer_vs_mutator_distinction.md` not
cited by sampled commands, doctrine, incidents, or recent plan files.

## What I found

- Memory file EXISTS, 7230 bytes, this-session canonical
- IS in MEMORY.md index (line 1) — auto-memory loader surfaces it
- NOT cited from `.flywheel/doctrine/` (gap)
- Drives N=2+ worker decisions this session via dispatch template's
  SKILL-ENHANCE JSM DISCIPLINE BLOCK

## What I shipped

Created `.flywheel/doctrine/cross-repo-consumer-vs-mutator-boundary.md`
that:
- Summarizes the pattern at canonical-doctrine quality (frontmatter,
  version, owner, status, source-bead)
- Cites the memory file as "Canonical memory source" — explicit cross-link
- Cross-refs sister doctrine + sister memories + conformance checklist

## Verification

- Pre-fix: `grep -l <memory> .flywheel/doctrine/ -r` → empty
- Post-fix: same grep → new doctrine doc
- Fresh probe: `gap_ids` no longer contains the .93 target

## L112 probe

    grep -l "feedback_cross_repo_consumer_vs_mutator_distinction" .flywheel/doctrine/ -r | head -1

Expected: `grep:cross-repo-consumer-vs-mutator-boundary.md`.

## Pattern note

`memory-without-cross-link` gap class resolves via **doctrine cross-link**,
not memory edit. Memory is truth source; doctrine cites it. This bead
extends the 2xdi.* fix cluster (47, 49, 64, 66 = corpus extensions; 93
= doctrine cross-link).

## What's still open

105 total flywheel-2xdi.* exist; the wired-but-cold cluster targeting
the patched skill is now cleared (2m2cs closed 16). Other classes
(probe-without-receiver, cross-source-silos, memory-without-cross-link
for OTHER memories) remain — each needs its own targeted resolution.
