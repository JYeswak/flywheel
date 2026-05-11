---
bead: flywheel-90k49.2
title: capability matrix — 8 flywheel storage scripts vs SBH surface
worker: MistyCliff (flywheel:0.4)
date: 2026-05-11
status: shipped
priority: P4
mission_fitness: adjacent
parent: flywheel-90k49
sister: flywheel-90k49.1 (formula-watch), flywheel-bx592 (install-now-actionable, filed during this bead)
---

# Journey: flywheel-90k49.2

## What the bead asked for

Classify each of 8 flywheel storage scripts vs SBH's verb surface
(`check / status / scan / clean / explain / blame / emergency / stats /
dashboard / install`) into SUPERSEDED / STILL NEEDED / COMPLEMENT, with a
consolidation proposal at `.flywheel/PLANS/storage-discipline-consolidation/`.
Don't actually remove anything in this bead.

## Gate decision

Trigger was "when SBH is installed locally (gated on 90k49.1 firing first)".
Live probe: `sbh` not on PATH; brew not tapped. But `Formula/sbh.rb` is now
PUBLISHED on Jeff's `homebrew-sbh` repo (was `.gitkeep` only when 90k49.1
closed). So:

- Install hasn't happened (matrix work is gated)
- BUT the bead body lists the verbs explicitly and the deliverable is a
  plan doc, not a smoke test
- Proceeded analytically; filed `flywheel-bx592` to trigger install per
  90k49.1's AG5

## Headline result

- 2 SUPERSEDED (private-tmp-prune, storage-headroom-watcher)
- 3 COMPLEMENT (storage-pause-auto-resume, beads-mem-tmp-cleanup, session-residue-prune)
- 3 STILL NEEDED (jeff-corpus-storage-projection, promotion-candidate-stale-fire-reaper, stale-in-progress-reaper)

Sub-discovery: 3 of the 8 (#6, #7, #8) aren't actually disk-storage scripts.
#6 and #8 are bead-DB hygiene; #7 is flywheel-repo hygiene. Co-located in
`.flywheel/scripts/` but out of SBH's domain. Surfaced in README + classification.

## L112 probe

    awk 'NR>1 {print $2}' .flywheel/PLANS/storage-discipline-consolidation/matrix.tsv | sort -u | wc -l | tr -d ' '

Expected: `literal:3`.

## Follow-ups for orch

1. **flywheel-bx592** (P3) — Formula now published; trigger install + smoke.
2. After install, run shadow-mode validation (per migration order section 3
   in the plan README): 7+ days of side-by-side comparison.
3. Then retire SUPERSEDED scripts in the order listed.

## Pattern note

This bead's hypothesis (8 scripts vs SBH classification) included 3 items
that don't belong in the comparison at all (out-of-domain). Recurrence of
the bead-hypothesis-is-prior META-rule: the bead body's enumeration was a
working list, not a vetted ontology. Honored by surfacing the out-of-domain
classification rather than forcing a SBH equivalence that doesn't exist.
