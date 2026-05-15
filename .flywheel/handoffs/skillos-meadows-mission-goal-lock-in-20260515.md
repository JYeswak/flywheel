# SkillOS Meadows Mission/Goal Lock-In Handoff

bead: flywheel-7crg
handoff_bead: flywheel-hcazt
created_at: 2026-05-15T03:18:00Z
owner_boundary: Flywheel authors the diff preview; SkillOS owns apply/ratify.

## Source Inputs Read

- `.flywheel/jeff-corpus/v1/learnings/01-doctrine-cluster.md`
- `.flywheel/jeff-corpus/v1/learnings/02-code-patterns.md`
- `.flywheel/jeff-corpus/v1/learnings/04-adopt-extend-avoid.md`
- `.flywheel/jeff-corpus/v1/learnings/06-skill-enhancement-matrix.md`
- `/Users/josh/Developer/skillos/.flywheel/MISSION.md`
- `/Users/josh/Developer/skillos/.flywheel/GOAL.md`
- `/Users/josh/.claude/skills/donella-meadows-systems-thinking/references/LEVERAGE-POINTS.md`
- `/Users/josh/.claude/skills/donella-meadows-systems-thinking/references/STOCKS-AND-FLOWS.md`
- `/Users/josh/.claude/skills/donella-meadows-systems-thinking/references/FEEDBACK-LOOPS.md`
- `/Users/josh/.claude/skills/donella-meadows-systems-thinking/references/SOURCE-REGISTRY.md`

## Meadows Frame

SYSTEM: SkillOS capability control plane for ZestStream skills and packs.

STOCK: skills and packs that meet the Jeff-derived doctrine/code-pattern bar.

INFLOW: new or updated skills/packs that enter the system with doctrine-cluster
coverage, code-pattern applicability, fixtures, receipts, and doctor/repair
evidence.

OUTFLOW: skills/packs retired, deprecated, or sent back for hardening because
they fail the doctrine/code-pattern bar.

LOOP: monthly Jeff/external signal refresh plus pack/skill doctor receipts
compare the current stock against the goal and route gaps into beads.

LEVERAGE_POINT:

- Meadows #2 Paradigms: shift the mental model from "skill count" to "capability
  quality that compounds under proof."
- Meadows #3 Goals: optimize for skill/packs meeting the doctrine and code
  pattern bar, not for authored volume.
- Meadows #5 Rules: require new skill work to carry doctrine-cluster and
  code-pattern applicability tables before merge.

SOURCE: Donella Meadows, "Leverage Points: Places to Intervene in a System",
Donella Meadows Project archive and 1999 PDF, retrieved in the local
`donella-meadows-systems-thinking` source registry on 2026-05-01T20:11:11Z.

## Current SkillOS State Observed

SkillOS already moved in the right direction after this bead was originally
filed:

- `MISSION.md` rev 8 names SkillOS as the capability control plane and includes
  reinforcing/balancing loops.
- `GOAL.md` revision 6 already rejects ship-count goals and adds
  compression/adoption telemetry.

The remaining gap is narrower than the original bead: the Jeff-derived
doctrine/code-pattern quality bar is not yet named as a first-class SkillOS
mission/goal stock with an apply-time checklist for new skills.

## Proposed SkillOS MISSION.md Diff Preview

Do not apply from Flywheel. SkillOS owner should adapt or reject.

```diff
diff --git a/.flywheel/MISSION.md b/.flywheel/MISSION.md
--- a/.flywheel/MISSION.md
+++ b/.flywheel/MISSION.md
@@
 ## North Star

 skillos exists to make the ZestStream skill system compound. Worker pods do the
 client work. skillos receives the findings, routes the trauma, hardens the
 skills, synthesizes packs, and sends improved capability back to the fleet.
+
+## Jeff-Pattern Quality Anchor
+
+SkillOS does not optimize for the number of skills authored. It optimizes for
+the stock of skills and packs that can survive real use: the eight Jeff-derived
+doctrine clusters and the four ADOPT-grade code patterns that Flywheel mined
+from Jeffrey Emanuel's substrate.
+
+The doctrine clusters are:
+
+1. testing-patterns
+2. doctor-health-repair-triad
+3. idempotency-and-dry-run
+4. ipc-and-transport-contracts
+5. error-handling-and-recovery
+6. schema-versioning-and-migrations
+7. callback-and-receipt-envelope
+8. append-only-audit-and-lineage
+
+The ADOPT-grade code patterns are:
+
+1. idempotency-key-fail-closed
+2. testing-fixture-conventions
+3. lock-file-convention
+4. frontmatter-validation
+
+Meadows read: this is a paradigm and goal lock. The system gets smarter only
+when new skills enter with reusable proof, and when weak skills either harden or
+leave the active stock.
```

## Proposed SkillOS GOAL.md Diff Preview

Do not apply from Flywheel. SkillOS owner should adapt or reject.

```diff
diff --git a/.flywheel/GOAL.md b/.flywheel/GOAL.md
--- a/.flywheel/GOAL.md
+++ b/.flywheel/GOAL.md
@@
 ## Measurement Row

 Each rev-8 status row must include the existing loop-integrity fields plus
 these mission metrics:
@@
 - `assessment_workflow_compression_velocity_p50_minutes` (rev-6 addition; commercial outcome signal)
+- `skill_quality_bar_coverage_ratio`
+- `new_skill_adopt_pattern_pass_rate`
+- `skill_hardening_or_retirement_outflow_count`
+
+## Skill Quality Stock/Flow Contract
+
+STOCK: `skill_quality_bar_coverage_ratio`
+: skills and packs with both a doctrine-cluster-coverage table and a
+  code-pattern-applicability table divided by active skills/packs in scope.
+  Target: >=80% by 2026-Q3 for SkillOS-owned capability packs and newly
+  touched ZestStream-authored skills.
+
+INFLOW: `new_skill_adopt_pattern_pass_rate`
+: new or modified skills/packs that pass the four ADOPT-grade code pattern
+  checks at PR/apply time: idempotency-key-fail-closed,
+  testing-fixture-conventions, lock-file-convention, and
+  frontmatter-validation.
+
+OUTFLOW: `skill_hardening_or_retirement_outflow_count`
+: active skills/packs moved to hardened, deprecated, or retired because the
+  doctrine/code-pattern refresh found they do not meet the bar.
+
+FEEDBACK LOOP: monthly enhancement-matrix refresh
+: re-run the Jeff/external pattern matrix, compare current active skills/packs
+  against the doctrine/code-pattern bar, and route deltas to beads with
+  receipt-backed close evidence.
```

## Proposed SkillOS Follow-Up Bead

Title:
`skillos-skill-author-checklist-jeff-doctrine`

Type: task
Priority: P1

Description:

```text
Require every new or materially changed SkillOS-owned skill/pack to include:

1. doctrine-cluster-coverage table sourced from Flywheel
   .flywheel/jeff-corpus/v1/learnings/01-doctrine-cluster.md
2. code-pattern-applicability table sourced from Flywheel
   .flywheel/jeff-corpus/v1/learnings/02-code-patterns.md and
   04-adopt-extend-avoid.md
3. explicit ADOPT/EXTEND/DIVERGE/SKIP decision per relevant pattern
4. fixture/replay command or skip receipt for each adopted pattern
5. receipt proving the checklist ran before merge/apply

Acceptance:
- validator rejects a new skill/pack without both tables
- fixture covers a missing doctrine-cluster table
- fixture covers a missing code-pattern-applicability table
- SkillOS doctor reports the ratio as skill_quality_bar_coverage_ratio
```

## Proposed AGENTS/L-Rule Entry

Do not apply from Flywheel because `.flywheel/AGENTS-CANONICAL.md` and install
template AGENTS surfaces are already dirty with unrelated unowned edits.

```text
L### SKILLOS-DOCTRINE-PARADIGM-ANCHOR
SkillOS optimizes for the stock of skills/packs meeting the Jeff-derived
doctrine/code-pattern bar, not skill count. New or materially changed
SkillOS-owned skills/packs must include doctrine-cluster-coverage and
code-pattern-applicability before merge/apply, or carry an explicit skip
receipt.

Sources:
- Flywheel .flywheel/jeff-corpus/v1/learnings/01-doctrine-cluster.md
- Flywheel .flywheel/jeff-corpus/v1/learnings/02-code-patterns.md
- Flywheel .flywheel/jeff-corpus/v1/learnings/04-adopt-extend-avoid.md
- Donella Meadows leverage points #2 Paradigms, #3 Goals, #5 Rules
```

## Flywheel Close Boundary

Flywheel can close `flywheel-7crg` when this handoff, its verifier, the
`flywheel-hcazt` handoff bead, and the `/tmp` evidence receipts exist. SkillOS
still owns the actual mission/goal/L-rule application and should close
`flywheel-hcazt` only after applying, adapting, or explicitly rejecting the
preview with evidence.
