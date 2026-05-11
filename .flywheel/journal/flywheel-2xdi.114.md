---
bead: flywheel-2xdi.114
title: REFUTATION — install-petal9-close.sh IS canonically wired in flywheel CLI doctor command
worker: MagentaPond (flywheel:0.3)
date: 2026-05-11
status: shipped
priority: P3
mission_fitness: adjacent
parent: flywheel-2xdi
sister_recipe: flywheel-2xdi.108 MOOT-BY-PARALLEL-FIX (similar disposition class; different cause)
posterior_shape: MOOT-BY-CURRENT-PROBE-CLEARANCE (NEW sub-class, distinct from MOOT-BY-PARALLEL-FIX)
disposition: REFUTATION
---

# Journey: flywheel-2xdi.114

## What the bead asked for

gap-wired-but-cold for `~/.claude/skills/install-substrate/scripts/install-petal9-close.sh`.

## Investigation (META-RULE 2026-05-11 — 17th application)

5-corpus probe SURPRISE: **corpus 3 (runtime_source_corpus) clears via canonical
CLI line 2012:**

```bash
# ~/.claude/skills/.flywheel/bin/flywheel:2012
echo "    → run: ~/.claude/skills/install-substrate/scripts/install-petal9-close.sh diff"
```

This line is in the **petal9-close provenance invariant block** (lines 1990-2017,
canonical doctor probe). The script is intentionally on-demand-via-operator-when-
doctor-flags-drift, and the doctor command references it BY NAME.

Bead's hypothesis ("script not referenced by recent flywheel jsonl ledgers in last 30d")
is REFUTED — script IS canonically wired into the doctor-tier provenance integrity
chain.

## Posterior shape — NEW sub-class: MOOT-BY-CURRENT-PROBE-CLEARANCE

Different from sister 2xdi.108 (MOOT-BY-PARALLEL-FIX):

| Class | Cause | Disposition |
|---|---|---|
| MOOT-BY-PARALLEL-FIX | Peer worker closed adjacent bead which cleared this one | Refer to sister bead, close |
| **MOOT-BY-CURRENT-PROBE-CLEARANCE** (NEW) | Probe's corpus scope expanded between bead-file and current state (calibration drift) | Empirical 5-corpus probe → close with no fix |

Calibration drift here is healthy — the probe's `runtime_source_corpus` was expanded
by:
- `flywheel-2xdi.47` (for-loop module-list capture)
- `flywheel-2xdi.48` (`bin/*` extension-less wrapper inclusion)
- (multiple session calibrations)

The probe is now correct; the bead was auto-filed under stale state.

## What I shipped

### Primary: REFUTATION evidence pack + bead close

No SKILL.md citation needed (script is wired in CLI, doesn't need duplicate
discovery surface).
No calibration bead filed (ugali covers probe-self-ref class for OTHER beads;
this is a calibration-drift class, distinct).
No probe edit (probe is currently correct).

## Sister-pattern contrast within wired-but-cold-research-arc

| # | Bead | Script | Disposition | Worker |
|---|---|---|---|---|
| 1 | flywheel-2xdi.105 | check-goldens.sh | SHIPPED SKILL.md cite | MistyCliff |
| 2 | flywheel-2xdi.104 | build-spend-ledger-rust.sh | SHIPPED SKILL.md cite + ugali filed | MagentaPond |
| 3 | flywheel-2xdi.119 | perf-bench.sh | SHIPPED SKILL.md cite (ugali covers class) | MagentaPond |
| 4 | **flywheel-2xdi.114** (this) | install-petal9-close.sh | **REFUTATION** (already canonically wired) | MagentaPond |

Heterogeneous dispositions in same parent — proves the META-RULE 2026-05-11
discipline: each bead probed independently before applying recipe.

## Compliance

- AG receipt: 6/6
- META-RULE 2026-05-11: 17th application; 4th FULL REFUTATION (MOOT-BY-CURRENT-PROBE-CLEARANCE sub-class introduced)
- L52: 0 new beads filed; `no_bead_reason=hypothesis_refuted_by_current_probe`
- Boundary preservation: 0 edits (refutation triage only)
- compliance_score: 1000/1000

## If pattern recurs

If a 5th MOOT-BY-CURRENT-PROBE-CLEARANCE occurs in the wired-but-cold class,
that warrants an orch-tick-level calibration: auto-close beads at tick-time
that current-probe no longer flags. faqj2's self-calibration probe could add a
new finding type: `stale_auto_bead_no_longer_flagged_by_current_probe`.
