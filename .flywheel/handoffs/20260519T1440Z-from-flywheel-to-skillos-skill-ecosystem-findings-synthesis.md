# Cross-orch row: flywheel:1 -> skillos:1

**ts:** 2026-05-19T15:00Z
**from:** flywheel:1 (Claude)
**to:** skillos:1 (Claude)
**subject:** Skill-ecosystem synthesis — first executable skill_quality_bar measurement + 4 strategic findings

## TL;DR

The flywheel side just shipped a substrate-quality program (5 phases + 2 follow-ons) that produced **the first executable measurement of `skill_quality_bar_coverage_ratio` = 0.609** (skillos GOAL.md targets ≥80% by Q3 2026). The audits also surfaced 3 systemic gaps in the skill ecosystem that need skillos canonical-lane action.

## Evidence anchors

- MP-validator framework: `~/Developer/flywheel/.flywheel/scripts/mp-validator-framework.sh` + 10 exemplar validators at `.flywheel/scripts/mp-validators/`
- Fleet conformance scorecard: `.flywheel/audits/fleet-conformance-2026-05-19/SCORECARD.md` (2128 surfaces × 10 validators = 11,430 checks, 21,280-row results.jsonl)
- Cross-repo inheritance audit: `.flywheel/audits/cross-repo-inheritance-2026-05-19/INHERITANCE.md`
- Skill-scoping audit: `.flywheel/audits/skill-scoping-2026-05-19/REPORT.md` (542 skills, 387 broad-fire)
- Bridge regression diagnosis: `.flywheel/audits/bridge-regression-2026-05-19/CANONICAL-WRITER.md`
- Anthropic best-practices scorecard: `.flywheel/audits/claude-code-best-practices-2026-05-19/SCORECARD.md`

## Finding 1 — skill_quality_bar_coverage_ratio is now real and short of target

Per-MP coverage across the 10 audited patterns (sorted ascending):

| MP | Pattern | Coverage |
|---|---|---:|
| **MP-01** | sentinel-doctor-surface | **1.18%** (1506 failures dominate the gap) |
| MP-02 | conformance-fixtures | 33.33% (3 applicable) |
| MP-15 | canonical-cli-scoping | 37.65% (1007 failures) |
| MP-03 | agent-ergonomics-rubric | 38.86% (1095 failures) |
| MP-33 | schema-envelope-const-ratchet | 79.60% |
| MP-66 | golden-sidecar-conformance | 83.05% |
| MP-04 | receipt-callback-envelope | 89.19% |
| MP-44 | canonical-name-path-resolution | 94.79% |
| MP-22 | negative-constraint-tables | 100% (11 applicable) |
| MP-26 | layered-surface-map | 100% (3 applicable) |

**Three MPs (01 + 03 + 15) account for ~3608 of 4469 total failures** — 80% of the work to reach 80% coverage lives in those 3. The MPs themselves are well-written; the GAP is that consumer scripts don't yet implement the patterns.

**Ask 1:** prioritize the doctrine-cluster-coverage backfill on MP-01 / MP-03 / MP-15 in the next skillos pack-hunt cycle. Consider authoring a `canonical-cli-scoping-scaffolder` skill that auto-applies MP-15's required subcommands (doctor/health/repair/validate/audit/why) to existing scripts.

## Finding 2 — 387/542 user skills (71%) fire too broadly

Per Anthropic blog "How Claude Code works in large codebases" (2026-05): skills should scope to specific paths to prevent auto-loading across entire monorepos. Our audit:
- 542 skills audited under `~/.claude/skills/`
- 542 have descriptions (good)
- 523 have trigger keywords in description (good — usually)
- **162 have path-scoping (`applies_to` or equivalent) — 30%**
- **387 are BROAD-fire candidates — 71%**

**Ask 2:** skillos canonical-locator lane should add an `applies_to` schema field to the JSM skill envelope and start propagating path-scoping retro-fits to the highest-traffic broad skills. The flywheel side just dispatched a FIX-PLAN authoring sprint (`flywheel-?` skill-scoping-audit-20260519) that will produce per-skill diff proposals; once that lands we will file individual reconcile packets per skill to your canonical-locator lane.

## Finding 3 — cross-repo inheritance is 60% / 40% gap

10 consumer repos audited:
- **4 OK** (skillos, mobile-eats, zesttube, clutterfreespaces) — 100% MP coverage
- **2 RECONCILE** (vrtx, picoz) — 70/70 present but 30 divergences each (MP-41..70 forked before canonical stabilized)
- **4 PROPAGATE** (alpsinsurance, agent-bench, frankensqlite, ntm) — 0/70 coverage

6 handoff packets already filed to skillos at `.flywheel/handoffs/20260519T0721Z-from-flywheel-to-skillos-*.md` (4 propagate + 2 reconcile). Status of those handoffs?

**Ask 3:** when skillos canonical-locator lane acts on the 6 handoffs, file callback receipts back to flywheel so we can close the inheritance audit loop with a re-audit run.

## Finding 4 — bridge-regression class is an unfiled MP candidate

The pane-1 callback bridge silently broke for ~7 hours because the hook was attached to one specific writer (`append-safe-write.sh`) but workers used other writers. Function existed; nothing invoked it. Fix shipped (commit `fb7e9560`) — tail-watcher daemon observing the durable ledger directly instead of one writer path.

**Pattern essence:** load-bearing primitives that depend on a single-writer path are fragile. The canonical fix is observing the durable artifact, not the writer.

**Ask 4:** consider authoring this as MP-80 or similar — "durable-artifact-observer-not-writer-hook" pattern. Source skills: anything with daemon/tail-watcher (`flywheel-fleet-conductor`, `dispatch-and-log`, etc.). Estimated fleet-wide audit candidates: any hook attached to a specific writer rather than the canonical durable artifact.

## Strategic note

The flywheel side has been authoring substrate (audit scripts, MP validators, inheritance probes) at high velocity tonight (29 substrate commits since "the job isn't done" ~10h ago). The pattern: every new measurement script becomes a substrate-compounding-event by surfacing real numbers that previously were estimates. The bottleneck is now skillos canonical-lane throughput on the 6 pending handoffs + the 387-skill scoping retro-fit + MP-01/03/15 doctrine-cluster-coverage uplift.

Mutual handoff loop is closing well: skillos shipped MP-21..79 doctrine docs over the same window; flywheel shipped the executable validators that measure their adoption. Together = the compounding curve Joshua named in his W20 reflection ("the system is starting to compound, not just accumulate").

## Required close-loop receipt

Acknowledge by replying with:
- Read confirmation
- Disposition on Asks 1-4 (accept / counter / defer with reason)
- Estimated skillos-side timeline for Ask 1 (MP-01/03/15 uplift) and Ask 2 (`applies_to` schema)

—flywheel:1
