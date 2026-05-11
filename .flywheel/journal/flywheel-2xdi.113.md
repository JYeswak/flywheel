---
bead: flywheel-2xdi.113
title: wired-but-cold resolved-upstream — no mutation needed
worker: MistyCliff (flywheel:0.4)
date: 2026-05-11
status: shipped
priority: P3
mission_fitness: adjacent
parent: flywheel-2xdi
disposition: resolved-upstream (no skill mutation)
sister: flywheel-2m2cs (bulk-close pattern; this is the single-bead version)
---

# Journey: flywheel-2xdi.113

## What the bead asked for

`~/.claude/skills/infisical-secrets/scripts/validate-identity.sh`
flagged wired-but-cold by gap-hunt-probe.

## Investigation (N=21 bead-hypothesis META-rule)

Probed empirically before assuming a SKILL.md mutation was needed:
- Script exists, well-formed
- Documented at `infisical-secrets/references/COMMANDS.md:47` AND
  `references/extracted-detail.md:117` (both in `references/*.md` tier)
- **Fresh gap-hunt-probe does NOT flag this script** — gap already cleared
- Simulated the probe's 3-pass corpus inline: `validate-identity.sh`
  is captured at ~6 MB of the 64 MB budget (Pass 2 references/*.md)

## Root cause of staleness

Bead was filed BEFORE one of the corpus extensions shipped. The chain:
1. 2xdi.66 — *.md corpus broadening
2. zsk2d — SKILL.md 256 KB priority cap
3. 2xdi.98 — references/*.md 128 KB priority cap
4. **2xdi.112 — overall_cap 32 MB → 64 MB** (this extension specifically
   landed alphabetically late-skill iteration which includes
   `infisical-secrets`)

Bead 113 was queued during the pre-2xdi.112 window and stayed open while
2xdi.112 shipped underneath it.

## What I shipped

NOTHING. Resolved-upstream disposition. No skill mutation, no probe
change, no test file. Just evidence documenting the chain.

Saved one unnecessary skill-mutation cycle by honoring the
bead-hypothesis META-rule (probe before assuming).

## L112 probe

    bash .flywheel/scripts/gap-hunt-probe.sh --json |
      jq '[.gap_ids[] | select(test("wired-but-cold.*validate-identity"))] | length'

Expected: `literal:0`.

## Pattern note

12th distinct fix shape in 2xdi.* cluster: **resolve-upstream-no-mutation**
(single-bead version of 2m2cs bulk pattern).

Bead-hypothesis discipline N=21 — at this rate, roughly 1 in 20 stale
2xdi beads in this cluster is resolved-upstream rather than needing a
fresh mutation. Worth keeping the probe-first discipline.

Sister auto-filer staleness property is documented indirectly in
xbsd8 (faqj2 semantic-cross-link finding). The dedup work in 9a3k1
catches duplicates of currently-live gaps but not "gaps that USED to
exist before a probe-corpus extension landed". This is a known
property; not filing a new meta-bead.
