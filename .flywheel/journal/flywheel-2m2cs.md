---
bead: flywheel-2m2cs
title: bulk-resolve 16 2xdi.* sub-beads cleared by paired probe-+-data fix
worker: MistyCliff (flywheel:0.4)
date: 2026-05-11
status: shipped
priority: P3
mission_fitness: adjacent
related: flywheel-zsk2d (probe fix), flywheel-xhevf (scripts/ patch), flywheel-b6p1m (tools/ patch)
---

# Journey: flywheel-2m2cs

## What the bead asked for

Verify that the combined effect of zsk2d (256KB SKILL.md cap) + xhevf (scripts/
patch) + b6p1m (tools/ patch) cleared the 2xdi.67-.85+ wired-but-cold cluster
targeting agent-ergonomics-and-agent-intuitiveness paths. Close cleared
sub-beads individually (anti-pattern guard: NO bulk-close without per-bead
probe).

## What I shipped

- Fresh probe captured → 0 agent-ergonomics paths in cold list
- Per-bead resolution matrix built: 16 of 16 cleared
- 16 individual `br close` operations executed; 0 failed

Combined patches reduced agent-ergonomics-and-agent-intuitiveness open 2xdi.*
sub-beads from 16 to 0.

## Anti-pattern guard honored

Per bead body explicit warning, did NOT bulk-close without per-bead probe.
Built `journey/per-bead-resolution-matrix.tsv` row-by-row, verified each
target absent from fresh probe gap_ids, then closed.

## Pattern emerging (skill discovery N=1)

Wired-but-cold FP clusters need PAIRED fix:
1. **Probe-side** — corpus collector handles target's wiring shape
2. **Data-side** — SKILL.md / source docs fully document the target

Either alone is insufficient. Filed as skill-discovery candidate;
promote at N=3 instances.

## L112 probe

    bash .flywheel/scripts/gap-hunt-probe.sh --json |
      jq '[.gap_ids[] | select(contains("agent-ergonomics-and-agent-intuitiveness"))] | length'

Expected: `literal:0`.

## What's still open

Other 2xdi.* sub-beads NOT in scope of this bead:
- 2xdi.96 (sister skill `agent-ergonomics-and-intuitiveness` — no "-agent-" middle prefix)
- 2xdi.87/.88/.89/.90/.92/.93/.97/.98/.99 (non-ergonomics targets)

These need their own corpus extension or SKILL.md hygiene passes.

## Notable

The probe's wired-but-cold cap of 20 is now freed up for genuine other-skill gaps.
Future 2xdi.* filings against agent-ergonomics-and-agent-intuitiveness paths
should not occur — that path is now fully covered by the paired fix.
