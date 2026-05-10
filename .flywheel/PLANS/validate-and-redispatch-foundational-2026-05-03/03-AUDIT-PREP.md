---
title: "Phase 3 Audit Prep - Validate Everything We Build"
type: plan
created: 2026-05-04
frontmatter_source: scaffold-doc-frontmatter
---

## Contents

- [Research Ledger](#research-ledger)
- [Section 1 - Selected Audit Lenses](#section-1-selected-audit-lenses)
  - [Lens 1: Cross-Runtime Parity And Agent-Context Proof](#lens-1-cross-runtime-parity-and-agent-context-proof)
  - [Lens 2: Evidence Contract, Validation Primitive, And Closeout Integrity](#lens-2-evidence-contract-validation-primitive-and-closeout-integrity)
  - [Lens 3: Doctrine, Learning-Loop, And No-Punt Wire-In](#lens-3-doctrine-learning-loop-and-no-punt-wire-in)
- [Section 2 - Draft Dispatch Packets](#section-2-draft-dispatch-packets)
  - [Dispatch Packet 1 - Cross-Runtime Parity And Agent-Context Proof](#dispatch-packet-1-cross-runtime-parity-and-agent-context-proof)
- [Skills library baseline](#skills-library-baseline)
- [Required reading](#required-reading)
- [Audit scope](#audit-scope)
- [Acceptance gates](#acceptance-gates)
- [Findings format](#findings-format)
- [Convergence test](#convergence-test)
- [Out of scope](#out-of-scope)
  - [Dispatch Packet 2 - Evidence Contract, Validation Primitive, And Closeout Integrity](#dispatch-packet-2-evidence-contract-validation-primitive-and-closeout-integrity)
- [Skills library baseline](#skills-library-baseline)
- [Required reading](#required-reading)
- [Audit scope](#audit-scope)
- [Acceptance gates](#acceptance-gates)
- [Findings format](#findings-format)
- [Convergence test](#convergence-test)
- [Out of scope](#out-of-scope)
  - [Dispatch Packet 3 - Doctrine, Learning-Loop, And No-Punt Wire-In](#dispatch-packet-3-doctrine-learning-loop-and-no-punt-wire-in)
- [Skills library baseline](#skills-library-baseline)
- [Required reading](#required-reading)
- [Audit scope](#audit-scope)
- [Acceptance gates](#acceptance-gates)
- [Findings format](#findings-format)
- [Convergence test](#convergence-test)
- [Out of scope](#out-of-scope)
- [Section 3 - Audit Findings Register Format](#section-3-audit-findings-register-format)
- [Summary](#summary)
- [Findings By Severity](#findings-by-severity)
  - [Critical](#critical)
  - [High](#high)
  - [Medium](#medium)
  - [Low / Notes](#low-notes)
- [Decisions Needed For Joshua](#decisions-needed-for-joshua)
- [Dedupe / Supersession Log](#dedupe-supersession-log)
- [Round Ledger](#round-ledger)
- [Recommended Next Phase Entry](#recommended-next-phase-entry)
- [Section 4 - Joshua-Disposes Pause Shape](#section-4-joshua-disposes-pause-shape)
- [Section 5 - Phase 3 To Phase 4 Handoff](#section-5-phase-3-to-phase-4-handoff)
# Phase 3 Audit Prep - Validate Everything We Build

Plan: `validate-everything-we-build-2026-05-03`
Slug: `validate-and-redispatch-foundational-2026-05-03`
Status: `ladder_passed=yes`
Purpose: choose the three Phase 3 audit lenses and pre-draft ready dispatch packets.

Do not execute these audit dispatches until Phase 2 REFINE r3 converges. This
prep exists so Phase 3 can start immediately after convergence without doing
lens design in the critical path.

## Research Ledger

- Read `02-REFINE-r2.md`: current best plan, with B13/B14 additions and r2 bead DAG.
- Read `01-RESEARCH-A.md`: high-criticality gap matrix and surface taxonomy.
- Read `01-RESEARCH-MEADOWS.md`: codex-feedback leverage example, recommends `#3 + #5 + #6`.
- Read `01-RESEARCH-MEADOWS-COMPONENTS.md`: nine-component Meadows analysis.
- Read `04-BEADS-PREDRAFT.md`: preliminary bead bodies B01-B12.
- Read `~/.claude/skills/jeff-convergence-audit/SKILL.md`: source-a skills baseline, structured findings, and two consecutive zero-finding rounds required.
- Read `/Users/josh/.claude/commands/flywheel/_shared/dispatch-template.md`: callback contract, worker tick contract, capacity gate, file discipline, verification.
- Read `/Users/josh/.claude/commands/flywheel/plan.md`: Phase 3 uses three parallel Codex audit lenses and pauses for Joshua-disposes before Phase 4.
- Required skills lookup attempted: `flywheel skills-best-practices "audit lens security idempotency cross-cutting validation review" --top=10`; local CLI returned `ERR: unknown command: skills-best-practices`.
- Fallback skills lookup used `mcp__skill_search__query_skills_tool` with the same query. Top matches: `security-review`, `data-deidentification`, `fraud-detection`, `codebase-audit`, `contract-review`, `seo-audit`, `security-audit-for-saas`, `jeff-convergence-audit`, `human-in-the-loop`, `ux-audit`.
- Socraticode source survey: 3 searches, 30 returned chunks. Relevant hits included AGENTS L60/L61/L69/L70, README dispatch/validation guidance, INCIDENTS validation and observability classes, and `/flywheel:plan` Phase 3/Joshua-disposes spec.

## Section 1 - Selected Audit Lenses

### Lens 1: Cross-Runtime Parity And Agent-Context Proof

Why this lens:

The plan's validation layer is only useful if it works for Claude, Codex, and
future runtimes. Lane A flags `codex-pane-crashed-mid-dispatch`,
`frozen-codex-spinner-misclassified-as-thinking`, `fleet-death-rca`, and
`bypass-canonical-substrate-cluster` as high criticality. L69 says probes must
run through the agent execution context, not raw orchestrator shell context.
The codex-feedback Meadows analysis adds a recommended L71 capture parity rule.

Coverage gap it closes:

This lens checks whether the plan and bead pre-drafts keep runtime parity as a
goal-level constraint, not a Claude-first implementation with Codex added as a
note. It covers B11 and the r2-added B13, plus all places B01-B05/B12 must
exercise Claude and Codex paths separately.

Primary evidence:

- `01-RESEARCH-A.md`: `codex-pane-crashed-mid-dispatch`, `frozen-codex-spinner-misclassified-as-thinking`, `bypass-canonical-substrate-cluster`.
- `01-RESEARCH-MEADOWS.md`: codex-feedback gap and `#3 + #5 + #6` stack.
- `01-RESEARCH-MEADOWS-COMPONENTS.md`: Component 8, Codex parity general.
- `02-REFINE-r2.md`: L71 recommendation, `agent_context_probe_drift_count`, B11/B13.
- AGENTS L69.

### Lens 2: Evidence Contract, Validation Primitive, And Closeout Integrity

Why this lens:

The highest-risk failure mode is accepting a claim as done without mechanical
proof. Lane A's top gap is `orchestrator-skipped-callback-validation`; related
high gaps include `dispatch-acceptance-gate-incomplete-corpus`,
`meat-puppet-orchestrator-decision-on-partial-state`, and closed beads claiming
artifacts that are not present. Meadows shows the key leverage is `#5 Rules`
backed by `#6` evidence, not more prose.

Coverage gap it closes:

This lens checks B01-B07 and B12 for schema-backed receipts, fail-closed
callback behavior, dry-run-first mutation, duplicate/idempotency handling,
auto-open fix-bead correctness, auto-reopen correctness, and artifact proof.
It combines candidate lenses D, F, and G because those are one evidence
contract surface, not three independent risks.

Primary evidence:

- `01-RESEARCH-A.md`: `orchestrator-skipped-callback-validation`,
  `dispatch-acceptance-gate-incomplete-corpus`,
  `meat-puppet-orchestrator-decision-on-partial-state`,
  `documented-bug-not-actioned-self-recursion`.
- `01-RESEARCH-MEADOWS-COMPONENTS.md`: Components 1, 3, 4, and 5.
- `04-BEADS-PREDRAFT.md`: B01-B07 and B12.
- `02-REFINE-r2.md`: synthetic test cases for missing artifact, invalid no-bead reason, closed bead artifact missing.
- AGENTS L52/L53/L56/L60.

### Lens 3: Doctrine, Learning-Loop, And No-Punt Wire-In

Why this lens:

The plan exists because documented doctrine repeatedly failed to become a
runtime gate. L61 requires doctrine wire-in, L60 requires producer/measurement/
consumer/promotion for doctor signals, and L70 forbids punting a named next
action to a later tick. Lane A flags `canonical_doctrine_drift_local`,
`skill-substrate-validation-drift`, `info-source-watchtower-missing`, and
`orchestrator-idle-with-actionable-work`.

Coverage gap it closes:

This lens checks whether every proposed rule/signal/memory/skill update has a
consumer and same-tick behavior, whether `/flywheel:learn` routes validation
events exactly once, and whether B08/B09/B10/B14 implement Meadows `#3/#5`
alignment instead of producing another information-flow-only artifact.

Primary evidence:

- `01-RESEARCH-A.md`: `canonical_doctrine_drift_local`,
  `skill-substrate-validation-drift`, `info-source-watchtower-missing`,
  `orchestrator-idle-with-actionable-work`.
- `01-RESEARCH-MEADOWS-COMPONENTS.md`: Components 2, 6, 7, and 9.
- `02-REFINE-r2.md`: L70, L71, VALIDATE-CALLBACK-OR-PUNT, THREE-Q-AUDIT-PER-SURFACE.
- `04-BEADS-PREDRAFT.md`: B04, B08, B09, B10, B14 from r2 plan.
- AGENTS L60/L61/L70.

## Section 2 - Draft Dispatch Packets

These are ready-to-send packet bodies. At dispatch time, run the capacity gate
from `/Users/josh/.claude/commands/flywheel/_shared/dispatch-template.md` and
remap panes if needed. Nominal assignments assume `flywheel:2`, `flywheel:3`,
and `flywheel:4` are free.

### Dispatch Packet 1 - Cross-Runtime Parity And Agent-Context Proof

```markdown
# DISPATCH: Phase 3 AUDIT r1 lens A - cross-runtime parity and agent-context proof
# Plan: validate-everything-we-build-2026-05-03

**Nominal Pane:** flywheel:2 (run capacity gate at dispatch time; remap if blocked)
**Task:** Audit the converged Phase 2 plan for cross-runtime parity and agent-context proof gaps.
**Callback:** /Users/josh/.local/bin/ntm send flywheel --pane=1 --no-cass-check "DONE plan-phase-3-audit-parity evidence=.flywheel/plans/validate-and-redispatch-foundational-2026-05-03/03-AUDIT-r1-parity.md findings=<N> critical=<N> high=<N> zero_round=<yes|no>"
**Expected output:** `.flywheel/plans/validate-and-redispatch-foundational-2026-05-03/03-AUDIT-r1-parity.md`

## Skills library baseline

Run first:

```bash
/flywheel:skills-best-practices "cross runtime parity codex claude agent context validation callback capture" --top=10 --include-content
```

If the slash surface is unavailable, use the skill-search MCP or record `skills_library_gap=cross-runtime-parity`.
Expected skills to evaluate: `jeff-convergence-audit`, `codebase-audit`, `human-in-the-loop`, `agent-orchestration`, `codex-watchtower` if surfaced.

## Required reading

- `.flywheel/plans/validate-and-redispatch-foundational-2026-05-03/02-REFINE-r2.md`
- `.flywheel/plans/validate-and-redispatch-foundational-2026-05-03/01-RESEARCH-A.md`
- `.flywheel/plans/validate-and-redispatch-foundational-2026-05-03/01-RESEARCH-MEADOWS.md`
- `.flywheel/plans/validate-and-redispatch-foundational-2026-05-03/01-RESEARCH-MEADOWS-COMPONENTS.md`
- `.flywheel/plans/validate-and-redispatch-foundational-2026-05-03/04-BEADS-PREDRAFT.md`
- `AGENTS.md` L69 and L70
- `/tmp/codex-feedback-gap-probe.md` if present

## Audit scope

Audit whether the plan works for Claude Code and Codex separately. Do not accept raw shell, launchd, or pane-scrollback probes as Codex proof unless the plan also includes an agent-context proof path.

## Acceptance gates

1. Identify every planned runtime-facing mechanism: callback validator, dispatch block, VALIDATE phase, doctor signals, capture parity, parity probe, and e2e smoke.
2. For each mechanism, classify Claude proof path and Codex proof path as `full|partial|missing`.
3. Verify B11 and B13 cover both tool parity and Joshua-input capture parity, not only one.
4. Verify `agent_context_probe_drift_count` has producer, measurement, consumer, threshold, and fixture.
5. Verify every parity probe respects L69: probe runs through worker/agent execution context.
6. Verify the plan states what happens when Codex is unresponsive, crashed, or frozen mid-dispatch.
7. Verify the e2e smoke harness includes at least one Claude fixture and one Codex fixture for the same validation primitive.
8. Flag any place where Claude hook behavior is treated as universal runtime behavior.

## Findings format

Write findings in this table:

| id | severity | criticality | component/bead | file:line | finding | evidence | recommended change | decision_needed |
|---|---|---|---|---|---|---|---|---|

Severity: `critical|high|medium|low`.
Criticality: `blocks_phase4|must_fix_before_beads|can_polish|note`.

## Convergence test

This lens reaches zero only when a full reread finds no NEW `critical` or `high`
runtime parity findings. Phase 3 converges after two consecutive zero-finding
rounds across all three lenses.

## Out of scope

- Do not implement parity probes.
- Do not dispatch into skillos or mobile-eats panes.
- Do not edit AGENTS.md, source code, beads, or configs.
- Do not redo the codex-feedback investigation; cite `01-RESEARCH-MEADOWS.md` and check that the plan consumes it.
```

### Dispatch Packet 2 - Evidence Contract, Validation Primitive, And Closeout Integrity

```markdown
# DISPATCH: Phase 3 AUDIT r1 lens B - evidence contract and closeout integrity
# Plan: validate-everything-we-build-2026-05-03

**Nominal Pane:** flywheel:3 (run capacity gate at dispatch time; remap if blocked)
**Task:** Audit the converged Phase 2 plan for mechanical evidence, validation primitive correctness, auto-open/reopen safety, and closeout integrity.
**Callback:** /Users/josh/.local/bin/ntm send flywheel --pane=1 --no-cass-check "DONE plan-phase-3-audit-evidence evidence=.flywheel/plans/validate-and-redispatch-foundational-2026-05-03/03-AUDIT-r1-evidence.md findings=<N> critical=<N> high=<N> zero_round=<yes|no>"
**Expected output:** `.flywheel/plans/validate-and-redispatch-foundational-2026-05-03/03-AUDIT-r1-evidence.md`

## Skills library baseline

Run first:

```bash
/flywheel:skills-best-practices "validation schema idempotency closeout artifact evidence audit" --top=10 --include-content
```

If the slash surface is unavailable, use the skill-search MCP or record `skills_library_gap=evidence-contract-validation`.
Expected skills to evaluate: `jeff-convergence-audit`, `codebase-audit`, `data-quality-validation`, `testing coverage`, `beads-workflow`, `canonical-cli-scoping` if surfaced.

## Required reading

- `.flywheel/plans/validate-and-redispatch-foundational-2026-05-03/02-REFINE-r2.md`
- `.flywheel/plans/validate-and-redispatch-foundational-2026-05-03/01-RESEARCH-A.md`
- `.flywheel/plans/validate-and-redispatch-foundational-2026-05-03/01-RESEARCH-MEADOWS-COMPONENTS.md`
- `.flywheel/plans/validate-and-redispatch-foundational-2026-05-03/04-BEADS-PREDRAFT.md`
- `AGENTS.md` L52, L53, L56, L60
- Bead references in the plan: `flywheel-1z65`, `flywheel-7lby`, `flywheel-2p25`

## Audit scope

Audit whether every claim of validation has a schema, fixture, deterministic
probe, fail-closed behavior, and durable repair route. Focus on B01-B07 and B12,
but trace any dependency into B04/B05/B09 where validation failures are consumed.

## Acceptance gates

1. Verify B01 defines a receipt schema that can represent pass, fail, unknown, missing artifact, invalid callback, context drift, no-bead reason, and tick-punted cases.
2. Verify B02 requires dispatch-template validation fields and rejects newly authored packets missing those fields.
3. Verify B03 validates callbacks before summary or integration and treats malformed receipts as no receipt.
4. Verify B06 auto-open fix-bead behavior is idempotent and has dry-run/apply separation.
5. Verify B07 auto-reopen behavior distinguishes deterministic missing artifact from ambiguous evidence and starts candidate-first unless explicitly justified.
6. Verify B12 includes synthetic e2e tests for missing artifact, invalid no-bead reason, BLOCKED without fuckup row, closed bead artifact missing, and tick punt.
7. Verify every mutating path has rollback or no-op safety: duplicate detection, idempotency key, dry-run receipt, and repo-local scope.
8. Flag any "documented" or "should" language that substitutes for a mechanical gate.

## Findings format

Write findings in this table:

| id | severity | criticality | component/bead | file:line | finding | evidence | recommended change | decision_needed |
|---|---|---|---|---|---|---|---|---|

Severity: `critical|high|medium|low`.
Criticality: `blocks_phase4|must_fix_before_beads|can_polish|note`.

## Convergence test

This lens reaches zero only when a full reread finds no NEW `critical` or `high`
evidence-contract or closeout-integrity findings. Phase 3 converges after two
consecutive zero-finding rounds across all three lenses.

## Out of scope

- Do not implement validators, scanners, or bead mutation.
- Do not create or reopen beads.
- Do not edit source, AGENTS.md, INCIDENTS.md, or configs.
- Do not perform historical closed-bead backfill; audit the plan only.
```

### Dispatch Packet 3 - Doctrine, Learning-Loop, And No-Punt Wire-In

```markdown
# DISPATCH: Phase 3 AUDIT r1 lens C - doctrine, learning-loop, and no-punt wire-in
# Plan: validate-everything-we-build-2026-05-03

**Nominal Pane:** flywheel:4 (run capacity gate at dispatch time; remap if blocked)
**Task:** Audit the converged Phase 2 plan for L60/L61/L70 wire-in, /flywheel:learn routing, Meadows #3/#5 alignment, and no-punt mechanics.
**Callback:** /Users/josh/.local/bin/ntm send flywheel --pane=1 --no-cass-check "DONE plan-phase-3-audit-wirein evidence=.flywheel/plans/validate-and-redispatch-foundational-2026-05-03/03-AUDIT-r1-wirein.md findings=<N> critical=<N> high=<N> zero_round=<yes|no>"
**Expected output:** `.flywheel/plans/validate-and-redispatch-foundational-2026-05-03/03-AUDIT-r1-wirein.md`

## Skills library baseline

Run first:

```bash
/flywheel:skills-best-practices "doctor signal doctrine wire-in learn loop no punt orchestration" --top=10 --include-content
```

If the slash surface is unavailable, use the skill-search MCP or record `skills_library_gap=doctrine-learning-no-punt`.
Expected skills to evaluate: `jeff-convergence-audit`, `agent-orchestration`, `agent-governance`, `agent-memory`, `beads-workflow`, `human-in-the-loop` if surfaced.

## Required reading

- `.flywheel/plans/validate-and-redispatch-foundational-2026-05-03/02-REFINE-r2.md`
- `.flywheel/plans/validate-and-redispatch-foundational-2026-05-03/01-RESEARCH-A.md`
- `.flywheel/plans/validate-and-redispatch-foundational-2026-05-03/01-RESEARCH-MEADOWS.md`
- `.flywheel/plans/validate-and-redispatch-foundational-2026-05-03/01-RESEARCH-MEADOWS-COMPONENTS.md`
- `.flywheel/plans/validate-and-redispatch-foundational-2026-05-03/04-BEADS-PREDRAFT.md`
- `AGENTS.md` L56, L60, L61, L69, L70
- `/Users/josh/.claude/commands/flywheel/plan.md` Phase 3 and Joshua-disposes sections

## Audit scope

Audit whether the plan wires doctrine and learning into runtime surfaces, not
just memory. Focus on B04, B08, B09, B10, B14, and r2's recommended L71,
VALIDATE-CALLBACK-OR-PUNT, and THREE-Q-AUDIT-PER-SURFACE rules.

## Acceptance gates

1. Verify each doctor signal has producer, measurement, consumer, threshold, and promotion path per L60.
2. Verify doctrine work includes AGENTS.md, README where relevant, memory note, INCIDENTS/fuckup evidence, and skill update or explicit no-skill reason per L61/L56.
3. Verify `/flywheel:learn` routes validation events exactly once and separates failures from positive validation receipts.
4. Verify L70 chain-forward is implemented mechanically in B08 and not only cited; every `next_phase` has `chain_if_capacity` or `chain_blocked_reason`.
5. Verify the plan does not default every component to Meadows `#6` information flow; `#3` goals and `#5` rules must be represented in bead acceptance gates.
6. Verify B14 makes "every surface" finite and auditable with Q1/Q2/Q3 evidence refs.
7. Verify Joshua-disposes decisions are explicit and not silently converted into beads before human review.
8. Flag any doctrine that lands before executable proof exists, unless the plan explicitly marks it as temporary or candidate doctrine.

## Findings format

Write findings in this table:

| id | severity | criticality | component/bead | file:line | finding | evidence | recommended change | decision_needed |
|---|---|---|---|---|---|---|---|---|

Severity: `critical|high|medium|low`.
Criticality: `blocks_phase4|must_fix_before_beads|can_polish|note`.

## Convergence test

This lens reaches zero only when a full reread finds no NEW `critical` or `high`
doctrine-wire-in, learning-loop, or no-punt findings. Phase 3 converges after
two consecutive zero-finding rounds across all three lenses.

## Out of scope

- Do not land L-rules.
- Do not edit AGENTS.md, README, INCIDENTS, memory, skills, or source.
- Do not create beads.
- Do not approve Joshua-disposes decisions; only identify them.
```

## Section 3 - Audit Findings Register Format

Phase 3 should consolidate individual lens outputs into:

`.flywheel/plans/validate-and-redispatch-foundational-2026-05-03/03-AUDIT-FINDINGS.md`

Canonical schema:

```markdown
# Phase 3 Audit Findings - Validate Everything We Build

Plan: validate-everything-we-build-2026-05-03
Round range: r1..rN
Convergence: streak=<0|1|2>/2
Status: open | paused_for_joshua | approved_for_phase4

## Summary

| severity | count | unresolved | decisions_needed |
|---|---:|---:|---:|
| critical | 0 | 0 | 0 |
| high | 0 | 0 | 0 |
| medium | 0 | 0 | 0 |
| low | 0 | 0 | 0 |

## Findings By Severity

### Critical

| id | lens | criticality | component/bead | file:line | finding | evidence | recommended action | owner phase | decision_needed | status |
|---|---|---|---|---|---|---|---|---|---|---|

### High

| id | lens | criticality | component/bead | file:line | finding | evidence | recommended action | owner phase | decision_needed | status |
|---|---|---|---|---|---|---|---|---|---|---|

### Medium

| id | lens | criticality | component/bead | file:line | finding | evidence | recommended action | owner phase | decision_needed | status |
|---|---|---|---|---|---|---|---|---|---|---|

### Low / Notes

| id | lens | criticality | component/bead | file:line | finding | evidence | recommended action | owner phase | decision_needed | status |
|---|---|---|---|---|---|---|---|---|---|---|

## Decisions Needed For Joshua

| decision_id | linked_findings | question | recommendation | alternatives | approve_effect | defer_effect |
|---|---|---|---|---|---|---|

## Dedupe / Supersession Log

| duplicate_id | canonical_id | reason |
|---|---|---|

## Round Ledger

| round | lens | artifact | findings | critical | high | zero_round |
|---|---|---|---:|---:|---:|---|

## Recommended Next Phase Entry

Phase 4 status: `blocked|ready_after_joshua|ready_now_if_no_findings`

Phase 4 inputs:
- `02-REFINE-r<N>.md` final converged plan
- `03-AUDIT-FINDINGS.md`
- `04-BEADS-PREDRAFT.md`
- audit lens artifacts

Phase 4 instruction:
<exact instruction for DECOMPOSE worker after Joshua-disposes>
```

Severity rules:

- `critical`: Phase 4 must not start until plan changes or Joshua explicitly accepts risk.
- `high`: Phase 4 may start only if the finding is converted into a required bead or pre-draft modification.
- `medium`: Phase 4 should carry into bead acceptance gates or polish notes.
- `low`: record only; no phase block unless clustered.

Criticality rules:

- `blocks_phase4`: hard block before bead creation.
- `must_fix_before_beads`: change plan/pre-draft before Phase 4 creates beads.
- `can_polish`: safe to carry into Phase 5 polish.
- `note`: record for traceability.

## Section 4 - Joshua-Disposes Pause Shape

After Phase 3 reaches two consecutive zero-finding rounds, the pipeline pauses
before Phase 4. The digest to Joshua should be:

```text
⏸ /flywheel:plan: validate-and-redispatch-foundational-2026-05-03 — PAUSED for Joshua-disposes

Findings:
- Total: <N>
- Critical: <N>
- High: <N>
- Medium: <N>
- Low: <N>
- Unresolved phase blockers: <N>

Decisions for you: <M>
1. <decision_id>: <short question>
   Recommendation: <approve|defer> — <one-line why>
   If approve: <effect on Phase 4>
   If defer: <effect on Phase 4>

Audit convergence:
- Round streak: 2/2 zero NEW critical/high findings
- Lens artifacts:
  - parity: <path>
  - evidence: <path>
  - wire-in: <path>
- Register: .flywheel/plans/validate-and-redispatch-foundational-2026-05-03/03-AUDIT-FINDINGS.md

Recommended action:
- approve Phase 4 with findings converted into bead edits, OR
- defer specific decisions and keep state=AUDIT_REVIEWED.

Resume command:
/flywheel:plan --resume validate-and-redispatch-foundational-2026-05-03
```

Digest rules:

- Do not auto-advance to Phase 4.
- Do not hide disagreements between lenses; each disagreement becomes a decision row.
- If there are zero decisions, say `Decisions for you: 0` and recommend resume.
- If any `critical` finding remains unresolved, recommend defer unless Joshua explicitly accepts the risk.
- If all findings are converted into clear Phase 4 bead modifications, recommend approve.

## Section 5 - Phase 3 To Phase 4 Handoff

Phase 4 DECOMPOSE starts only after Joshua-disposes approval.

Data flowing into Phase 4:

1. Final Phase 2 plan: normally `02-REFINE-r3.md` or latest converged refine artifact.
2. Audit register: `03-AUDIT-FINDINGS.md`.
3. Lens artifacts: `03-AUDIT-rN-parity.md`, `03-AUDIT-rN-evidence.md`, `03-AUDIT-rN-wirein.md`.
4. Existing pre-draft: `04-BEADS-PREDRAFT.md`.
5. This prep file for dispatch intent and lens rationale.

How audit findings affect Phase 4:

- Phase 3 does not create beads directly.
- `critical` and `high` findings must either modify the Phase 4 bead bodies before creation or become explicit new bead candidates in the DECOMPOSE worker's output.
- Medium findings should become acceptance gates, DOD clauses, or polish notes.
- Low findings may remain in the findings register unless they reveal a repeated pattern.
- If audit confirms the r2-added B13/B14 are required, Phase 4 should create them even though the earlier `04-BEADS-PREDRAFT.md` only contains B01-B12.
- If audit finds B01-B14 exceed the 15-bead cap, Phase 4 should split rather than compress unrelated gates into overloaded beads.

Phase 4 start state:

```text
Entry condition:
- Phase 2 steady-state confirmed
- Phase 3 convergence streak=2/2
- 03-AUDIT-FINDINGS.md written
- Joshua-disposes approval received

DECOMPOSE worker instruction:
- Start from final refine artifact and 04-BEADS-PREDRAFT.md.
- Apply audit findings as bead edits/additions before `br create`.
- Ensure every critical/high finding has a mitigating bead or explicit Joshua-approved defer.
- Create repo-local beads only after approval.
- Validate DAG cycles are empty and waves remain 3-5 beads.
```
