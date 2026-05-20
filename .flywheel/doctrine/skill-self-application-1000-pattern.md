---
title: "Skill Self-Application 1000-Pattern"
type: doctrine
created: 2026-05-08
frontmatter_source: scaffold-doc-frontmatter
---

# Skill Self-Application 1000-Pattern

## Status

Doctrine from `flywheel-gb54d.2`.

This pattern is close-ready as a reusable method, but not ready for canonical
AGENTS promotion until it is reused on at least one additional skill.

## Source Evidence

Primary source: `flywheel-gb54d`, the canonical-cli-scoping uplift spawned from
the agent-ergonomics audit on 2026-05-08.

Evidence already present:

- `.flywheel/receipts/flywheel-gb54d/evidence.md` records Phase 1 quick wins:
  R-001 checker JSON/capabilities/exit-code dictionary, R-003 state-handling
  examples, the worked example corpus, and checker JSON tests.
- `.flywheel/receipts/flywheel-gb54d/post-phase1-scorecard.jsonl` records the
  manual post-Phase-1 scoring estimate.
- `.flywheel/receipts/flywheel-gb54d/self-audit.md` records the structural
  self-audit that kept the later phases open.

Final scorer evidence:

- `.flywheel/receipts/flywheel-gb54d.1/evidence.md` records phases 2-4 for
  `canonical-cli-scoping`.
- `.flywheel/audit/flywheel-gb54d.1/skill-score.json` records
  `composite_score=992`.
- `.flywheel/audit/flywheel-gb54d.1/regression-ladder.json` records the
  golden, wrong-but-legible, and mutation regression ladder.
- `.flywheel/audit/flywheel-gb54d.1/fresh-agent-simulation.json` records the
  fresh-agent path.

## Pattern

Use this method when a skill must become an exemplar of the rules it teaches.
Do not jump from a baseline score directly to broad rewrites. Drive the work as
four bounded phases, each with its own scorer evidence and stop condition.

### Phase 1: Quick Wins

Goal: remove low-blast friction that prevents agents from using or measuring
the skill.

Typical moves:

- Add machine-readable surfaces such as `--json`, capability listings, schema
  output, and exit-code dictionaries to helper scripts.
- Add concrete examples where the skill uses abstract trigger language.
- Add a small regression test that proves the new surface is callable by an
  agent without interpretation.

Close condition: re-audit shows a measurable lift and identifies which weak
dimensions remain. Phase 1 is not the 1000-point claim.

Canonical example: `flywheel-gb54d` landed R-001 and R-003 for
`canonical-cli-scoping` and explicitly split the remaining ladder into follow-up
beads rather than over-claiming.

### Phase 2: Validator Or Subagent Contract

Goal: give the skill an independent reviewer that can score real candidates
against the skill's own rules.

Typical moves:

- Define the validator input contract: skill path, target surface, source
  evidence, executable evidence, and expected rule set.
- Emit per-rule findings, not one prose verdict.
- Make the validator catch partial implementations that static grep checks
  miss.
- Separate scorer evidence from fixer behavior so a worker cannot self-approve
  its own patch.

Close condition: the validator or reviewer workflow exists, produces a durable
scorecard, and can be rerun by a future worker.

### Phase 3: Regression Ladder

Goal: make the skill resistant to well-intentioned drift.

Typical moves:

- Add golden tests for every contract rule.
- Add wrong-but-legible invocation fixtures: malformed inputs that should still
  produce actionable diagnostics.
- Add mutation tests for single-rule drift, such as changed flag names,
  weakened output guarantees, or missing examples.
- Store fixtures near the validator so future edits extend the ladder instead
  of bypassing it.

Close condition: the regression set catches both missing implementation and
misleading implementation. A prose-only self-audit is not enough.

### Phase 4: Asymptote And Fresh-Agent Simulation

Goal: make the skill usable first try by a capable agent with no hidden session
context.

Typical moves:

- Fix intent inference gaps: aliases, fuzzy phrasing, and partially correct
  invocations should route to useful diagnostics.
- Make the skill self-applying: every rule it demands of others is visible in
  its own scripts, examples, tests, and evidence.
- Align with adjacent canonical patterns instead of inventing a local dialect.
- Run a fresh-agent simulation where a new worker starts from the skill and
  completes the expected task without private context.

Close condition: re-audit reaches 1000, or a 990+ score with explicit scorer
evidence proving the remaining gap is irreducible or not worth the added system
cost.

## Reuse Contract

Before promoting this page into canonical AGENTS doctrine, require one reuse
outside `canonical-cli-scoping`:

1. Pick a second skill with a measurable baseline and a live operator surface.
2. Run the same four-phase ladder.
3. Save Phase 1 and final evidence under the bead's receipt or audit path.
4. Record whether the final score reached 990+ or why it stopped lower.
5. Only then promote this method from provisional doctrine to canonical
   operational doctrine.

## Anti-Patterns

- Treating quick wins as proof of the full 1000-point path.
- Letting the same worker implement and score the final result without an
  independent validator contract.
- Adding examples without regression fixtures.
- Claiming final 990+ evidence without a scorer receipt.
- Promoting a one-skill success directly into AGENTS doctrine before reuse.

## Four-Lens Self-Grade

- brand: 8
- sniff: 9
- jeff: 8
- public: 8

Three Judges check: a skeptical operator can see which evidence exists and
which scorer evidence supports the method; a maintainer can reuse the four
phases without canonical-cli-scoping-specific assumptions; a future worker can
rerun the scorer and fresh-agent receipts before promoting the pattern.


## Meta-Learning Cross-References (2026-05-19)

This doctrine surface was backfilled during JSM fleet audit batch-3 so recent doctrine cites the relevant MP lessons directly.

- **MP-09 — info-source watchtower:** see `/Users/josh/Developer/skillos/.flywheel/doctrine/meta-learnings/MP-09-info-source-watchtower.md` for the canonical pattern.
- **MP-13 — living documentation:** see `/Users/josh/Developer/skillos/.flywheel/doctrine/meta-learnings/MP-13-living-documentation.md` for the canonical pattern.
- **MP-28 — checklist before claim:** see `/Users/josh/Developer/skillos/.flywheel/doctrine/meta-learnings/MP-28-checklist-before-claim.md` for the canonical pattern.
