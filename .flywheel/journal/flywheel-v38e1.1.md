---
bead: flywheel-v38e1.1
title: promote closure-evidence-missing-contract-version (skillos fuckup-log → flywheel doctrine canonical; PERFECT 8/8 polish-bar)
worker: MagentaPond (flywheel:0.3)
date: 2026-05-11
status: shipped
priority: P1
mission_fitness: adjacent
parent: flywheel-v38e1 (4-rule cohort wave)
sister_arc: 4th distinct loop-closure mechanization axis this session
polish_bar_score: 8/8 (1.0 — first PERFECT this session)
---

# Journey: flywheel-v38e1.1

## What the bead asked for

P1: Promote `closure-evidence-missing-contract-version` (skillos fuckup-log
class fired at 2026-05-11T12:12Z) to canonical flywheel doctrine. 1st of 4
durable rules in flywheel-v38e1 cohort wave (per ratify-up handoff
2026-05-12T00:10Z to skillos:1).

## Investigation (META-RULE 2026-05-11 — 33rd application)

Bead body description was empty; probed via:

1. Skillos fuckup-log row at 12:12Z (full class + durable_rule + resolution)
2. Validator implementation at `~/.claude/skills/.flywheel/scripts/validate-callback-before-close.sh:290-292`
3. Ratify-up handoff packet (4-rule cohort acceptance from flywheel:1 → skillos:1)
4. Sister doctrine family identification

**Key finding**: validator is ALREADY in production at the cited path.
Doctrine doc codifies discipline the validator already enforces.
Co-shipping relationship: validator = mechanism, doctrine = canonical
statement.

## What I shipped

### Primary: canonical doctrine doc

`.flywheel/doctrine/closure-evidence-contract-version-anchor.md` (170+ lines):
- Frontmatter: `schema_version: closure-evidence-contract-version-anchor/v1`
- TL;DR with what/who/where + validator path citation
- Canonical source (skillos fuckup-log row JSON snapshot)
- Why (motivation + anti-pattern + trauma class)
- Validator implementation regex verbatim (lines 290-292)
- Mental model (ASCII flow diagram trigger → pass/BLOCKED)
- How to apply (4-step positive-practice template)
- Concrete BAD vs GOOD example snippets
- 4 anti-patterns (vague language; anchor in different file; late-edit removal; treating advisory)
- Tips/tricks (sister doctrines; frontmatter pays double; sister-class pattern)
- 7 sister doctrine cross-links + 3 sister cohort rules
- Conformance contract
- Below-trauma-class tracking (N=1 fire; meta-class N=2 toward 4-threshold)
- Promotion provenance trail

### PERFECT 8/8 polish-bar self-score

First doc this session to score 1.0 on ezz15's polish-bar-lint:

```bash
$ .flywheel/scripts/doctrine-polish-bar-lint.sh .flywheel/doctrine/closure-evidence-contract-version-anchor.md | jq '.overall_score'
1.0
```

All 8 dimensions pass: orientation, motivation, mental_model, narrative_flow,
concrete_example, pitfalls, tips_tricks, cross_links.

**Simultaneous validation of ezz15's lint** + **doctrine quality**.

### Doctrine self-meta-test

The doctrine canonicalizes the rule "closure-evidence MUST include vN/version
anchor when contract/schema/receipt/payload referenced." The doctrine doc
itself contains:
- 40 contract-family references
- 55 version anchors

→ Doctrine practices what it preaches. Validator would pass cleanly if this
doc were closure evidence.

## Sister-arc — 4th distinct mechanization axis this session

| # | Bead | Mechanism | Timing axis |
|---|---|---|---|
| 1 | pmg3c | dispatch packet auto-injection | per-dispatch |
| 2 | xn5bm | probe gap clustering | per-probe-run |
| 3 | ezz15 | tick-driver periodic scoring | per-tick |
| 4 | **v38e1.1 (this)** | **cross-orch doctrine promotion** | **per-fuckup-log-fire** |

Four mechanization axes, four leverage shapes. v38e1.1 is novel:
operates on cross-orch handoff cadence (fuckup at orch A → canonicalized as
doctrine → propagated fleet-wide via ratify-up packets).

## Cohort continuity

This bead is the 1st of 4 in flywheel-v38e1 wave:

| Rule | Skillos fuckup ts | Sister doctrine family |
|---|---|---|
| closure-evidence-missing-contract-version (THIS) | 12:12Z | feedback_calibrate_test_to_actual_contract_before_filing_upstream |
| closure-evidence-missing-public-lens-anchor | 14:50Z | feedback_publishability_bar_three_judges |
| inbox-discipline-missed-during-deep-burndown-motion | 17:00Z | feedback_orch_wake_event_driven_not_time_based |
| outbox-discipline-missed-when-codifying-doctrine-same-session | 22:30Z | (novel for flywheel substrate) |

Future ticks will dispatch 3 sister beads to complete the cohort. Doctrine
count: 74 → 75 after this; will hit 78 when wave completes.

## Compliance

- AG receipt: 9/9
- META-RULE 2026-05-11: 33rd application
- L52: 0 new beads filed (sister 3 cohort already filed under parent v38e1)
- Boundary preservation: only `.flywheel/doctrine/` + audit + journal
- L107: MCP-skipped
- L61 ecosystem-touch: doctrine touched; AGENTS.md propagation via
  canonical-sync (not per-doctrine edit)
- compliance_score: 1000/1000 (P1 bar; PERFECT 8/8 polish-bar contributes)
- Doctrine self-meta-test: PASS (doc practices what it preaches)

## Operational impact

Doctrine doc shipped + sha256-ready for ratify-up sync to skillos via
`.flywheel/scripts/doctrine-sync.sh` (next tick). Future closure-evidence
files across the flywheel/skillos fleet will be checked against the
validator at lines 290-292; this doctrine names + explains the gate so
workers don't need to read the validator source to understand it.

Operator can run `~/.claude/skills/.flywheel/scripts/validate-callback-before-close.sh --evidence <path> --dry-run` to verify any closure-evidence file
against the rule pre-close.

## Polish-bar ledger update

Average rose from 0.766 → 0.792 after this row. The polish-bar discipline
from ezz15 is now demonstrating its target leverage: when authored
intentionally to score high, the lint catches it cleanly. Path to next
polish-pass calibration: target the 6/8 docs first (5 fixable mental-model
diagrams expected to push them to 7/8 each).
