---
bead: flywheel-03yaj
title: research-triad SKILL.md batch hygiene + 4 subordinate beads closed
worker: MistyCliff (flywheel:0.4)
date: 2026-05-11
status: shipped
priority: P2
mission_fitness: adjacent
joshua_authorized: cross-repo batch
subordinate_closes: 2xdi.121, .122, .123, .124 (resolved-upstream)
---

# Journey: flywheel-03yaj

## What the bead asked for

Joshua-authorized cross-repo batch: bulk-fix N≥9 wired-but-cold
research-triad scripts via single SKILL.md mutation + close all
subordinate auto-beads with resolved-upstream disposition.

## Audit (N=25 bead-hypothesis META-rule)

- 31 scripts in `~/.claude/skills/research-triad/scripts/`
- 0 tools (no tools/ directory)
- 5 mentioned in SKILL.md pre-tick (check-goldens, build-spend-ledger-
  rust, perf-bench, x-stream-consumer narrative, restore-graph-from-
  frozen narrative)
- **26 missing** — bigger than the bead's "9+" estimate

## What I shipped

### Direct mutation

`~/.claude/skills/research-triad/SKILL.md` — appended
"### Scripts inventory (canonical)" subsection inside Operator scripts.
26 missing scripts documented in 7 capability-cluster tables:

1. Spend-ledger + cost accounting (5)
2. Axis pollers + research-axis maintenance (6)
3. Native build + Rust query path (2)
4. Calibration + validation (6)
5. Trauma / incident-archive surfaces (2)
6. X follow-graph + cluster mining (5; one cross-listed)
7. Local-grep + socraticode adapter (1)

Final coverage: **31/31** (was 5/31 pre-tick).

### Paired patch

`.flywheel/audit/flywheel-03yaj/patches/`:
- SKILL.md.original (210 lines)
- SKILL.md.proposed (276 lines)
- SKILL.md.patch (72 lines)
- apply-instructions.md (apply + verify + rollback + subordinate-close log)

### Subordinate closes (resolved-upstream)

- 2xdi.121 (research-axis-status.sh) — CLOSED
- 2xdi.122 (research-query-route-fix-test.sh) — CLOSED
- 2xdi.123 (spend-ledger-fast.sh) — CLOSED
- 2xdi.124 (trauma-ingest-test.sh) — CLOSED

(2xdi.119 + 2xdi.120 already closed pre-tick.)

## Verification

- 31/31 scripts mentioned in SKILL.md
- All 4 subordinate-bead targets present
- Fresh gap-hunt-probe: 0 research-triad wired-but-cold gaps

## L112 probe

    for f in $(ls ~/.claude/skills/research-triad/scripts/); do
      grep -q "scripts/$f" ~/.claude/skills/research-triad/SKILL.md || echo "MISSING: $f"
    done | wc -l | tr -d ' '

Expected: `literal:0`.

## Pattern note — 15th fix shape (batch variant)

`pattern-emerged-batch-skill-doc-completeness-plus-subordinate-bead-bulk-close`

This unifies two prior cluster patterns:
- **2m2cs** bulk-close pattern (close N already-resolved sub-beads via per-bead probe)
- **2xdi.105/.99** unmanaged-skill single-script doc-fix recipe

The batch variant: one SKILL.md mutation covers N sub-bead targets +
N-bead bulk close in same tick. Filed N=1 instance; promote at N=3
to skill.

## Hint-productivity

Bead body cited the precedent (2xdi.119 PERFECT 1000) and the
underlying SD from 2xdi.120 audit-only worker tick. Orch had already
done the surfacing; my job was clean execution of the established
recipe.
