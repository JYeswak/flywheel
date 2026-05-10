---
title: "Phase 3 AUDIT r1 — Failure-Mode Coverage"
type: plan
created: 2026-05-06
frontmatter_source: scaffold-doc-frontmatter
---

# Phase 3 AUDIT r1 — Failure-Mode Coverage

Plan: `wire-or-explain-tick-gate-2026-05-04`
Lens: failure-mode-coverage
Generated: 2026-05-04T22:52Z
Mode: plan-space read-only audit

## Scope

This lens verifies the bidirectional coverage contract:

1. Every canonical failure mode FM1-FM7 in r2 has at least one mitigating bead.
2. Every bead B1-B15 has a clear failure mode or source finding it prevents.
3. Failure modes surfaced by other audit lenses but not named FM1-FM7 are
   recorded as canonical-list coverage gaps for Phase 4/5.

This report does not duplicate cross-cutting, idempotency, or bootstrap
findings. It treats those reports as source evidence and asks whether r2's
canonical FM list and bead DAG cover the whole risk surface.

Skills applied:

- `donella-meadows-systems-thinking`: stock is unresolved or misclassified
  shipped artifacts; mitigation must reduce inflow or increase verified outflow.
- `lean-formal-feedback-loop`: coverage claims need witnesses, fixtures, and
  artifact hashes; prose mapping is not enough.
- `multi-pass-bug-hunting`: inverse pass checks for orphan beads and unnamed
  failure classes after prior lenses.

Socraticode survey:

- Query 1: `wire explain failure mode coverage matrix bead audit FM1 FM7`
- Query 2: `failure mode coverage audit matrix plan beads idempotency bootstrap recursion`
- Relevant precedent: closed-bead audit doctrine and test fixtures emphasize
  DID/DIDNT/GAPS and machine-checkable coverage; self-recursion INCIDENTS
  confirms bootstrap cases need explicit escape logic.

Composite score: `7.6/10.0`

Disposition: `auto_advance_eligible`

## Findings Table

| ID | Severity | Beads affected | Description | Mitigation |
|---|---|---|---|---|
| FMC-F1 | high | B1,B3,B5,B9 | FM1 says bounded scan roots, cache by mtime/digest, hard per-row/total timeout, and latency doctor field, but B1/B3 acceptance gates do not yet require those fields. | Add discovery budget fields to B1 schema and B3/B9 fixtures; B5 exposes per-row timeout and p95. |
| FMC-F2 | medium | B3,B6,B7,B9 | FM2 names bounded override and manual `wired_into`, but override issuer authority and manual-consumer registry ownership are not mechanical. | Add override issuer/auth fields and manual-consumer registry ownership to B7/B3; B9 rejects unauthenticated overrides. |
| FMC-F3 | medium | B2,B6,B8,B9 | FM3 depends on tick-open backfill over commit range, but r2 does not bound horizon, range source, or max scan cost. | Add `backfill_since`, `backfill_until`, horizon cap, and missed-collector fixture. |
| FMC-F4 | medium | B1,B6,B7,B12 | FM6 says bounded cross-repo pending, but the bound is not defined as time, row count, retry count, or ownership handoff. | Add `cross_repo_pending_expires_at`, retry/row caps, and owner handoff fields. |
| FMC-F5 | medium | B3,B5,B9,B11 | FM7 says daily re-verification and repair bead, but cadence, cost budget, and stale-consumer repair owner are unspecified. | Add reverify cadence/budget, stale-consumer owner, and status remediation proof. |
| FMC-F6 | low | B10,B13,B14,B15 | No bead is orphan, but B13-B15 and B10 map to source findings that are not represented in FM1-FM7, so the canonical FM list is incomplete for Phase 4 polish. | Add FM8+ candidate list or an explicit `non_fm_source_finding` section to bead bodies. |

Findings total: 6

Findings by severity: critical 0, high 1, medium 4, low 1

## FM × Bead Coverage Matrix

Legend: `D` direct mitigation, `I` indirect/supporting mitigation, `-` no coverage.

| FM | B1 | B2 | B3 | B4 | B5 | B6 | B7 | B8 | B9 | B10 | B11 | B12 | B13 | B14 | B15 |
|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|
| FM1 slow consumer discovery | I | I | D | I | D | I | - | I | D | - | I | I | - | - | - |
| FM2 false positive blocks wired artifact | I | - | D | I | I | D | D | - | D | I | D | I | - | - | - |
| FM3 false negative misses unwired artifact | I | D | D | I | D | D | - | D | D | - | I | I | I | - | - |
| FM4 gate becomes bottleneck | I | I | I | D | D | D | D | I | D | - | I | I | - | - | - |
| FM5 bootstrap recursion | D | I | D | - | I | D | D | D | D | I | - | I | I | I | I |
| FM6 cross-repo ship waits | D | I | I | I | D | D | D | I | D | I | D | D | I | I | I |
| FM7 stale wiring after removal | I | - | D | I | D | I | - | - | D | - | D | I | - | - | I |

Coverage summary:

- FM1-FM7 coverage: `7/7`.
- `fm_coverage_pct=100`.
- Every FM has at least one direct mitigation.
- Every FM has at least one fixture owner, usually B9.
- The matrix is strongest for FM5/FM6 because later audit lenses forced
  bootstrap and cross-orch specificity.
- The matrix is weakest for FM1/FM7 because scan budgets and reverification
  cadence are named in the FM table but not fully represented in bead
  acceptance gates.

## Per-FM Analysis

### FM1 — Slow Consumer Discovery

Source: r2 requires bounded scan roots, cache by mtime/digest, hard per-row and
total timeout, and latency doctor field at `02-REFINE-r2.md:62`.

Coverage:

- Direct: B3 detector, B5 doctor fields, B9 timeout fixture.
- Indirect: B1 schema, B2 classifier, B4 ranker, B6 close gate, B8 dogfood,
  B11 status, B12 rollout.

Strength:

B9 explicitly has an FM1 timeout fixture at `02-REFINE-r2.md:357`, and r2's
rollout criteria include `wire_or_explain_gate_p95_latency_ms < 5000` at
`02-REFINE-r2.md:476`.

Gap:

B1 schema acceptance at `02-REFINE-r2.md:263-271` does not require
`scan_root`, `consumer_discovery_timeout_ms`, `scan_cache_key`, `mtime_digest`,
or `total_scan_budget_ms`. B3 acceptance proves classifications, not discovery
budget behavior.

New finding: FMC-F1.

### FM2 — False Positive Blocks Wired Artifact

Source: r2 requires `why`, manual `wired_into` with evidence, bounded override,
and manual-consumers registry at `02-REFINE-r2.md:63`.

Coverage:

- Direct: B3 detector, B6 close gate, B7 override, B9 false-positive fixture.
- Indirect: B1 schema, B4 ranking, B5 doctor, B10 doctrine, B11 status, B12
  fleet rollout.

Strength:

B3 explicitly separates README-only mentions from real wiring at
`02-REFINE-r2.md:287-293`, and B7 rejects empty/expired overrides at
`02-REFINE-r2.md:337-341`.

Gap:

The plan says bounded override, but not who can issue one, what authority proves
it, or where manual consumer registry ownership lives. Idempotency lens covered
expiry equality; bootstrap lens covered seed-vs-bypass. This lens adds issuer
authority and registry ownership.

New finding: FMC-F2.

### FM3 — False Negative Misses Unwired Artifact

Source: r2 requires tick-open backfill over commit range, collector health
field, and dogfood import at `02-REFINE-r2.md:64`.

Coverage:

- Direct: B2 classifier, B3 detector, B6 close gate, B8 dogfood import, B9
  collector-missed fixture.
- Indirect: B1 ledger, B4 ranker, B5 doctor, B11 status, B12 rollout, B13
  worker branch artifact rows.

Strength:

B2 covers artifact-class fixture rows at `02-REFINE-r2.md:273-281`, B8 imports
known corpus rows at `02-REFINE-r2.md:343-351`, and B9 creates
`ship_event_unclassified_count_24h` at `02-REFINE-r2.md:359`.

Gap:

Backfill range is not bounded. The plan does not say whether the close hook
scans since last tick, last commit, last successful high-watermark, or a time
horizon. Without a horizon, FM3 mitigation can become FM4 bottleneck.

New finding: FMC-F3.

### FM4 — Gate Becomes Bottleneck

Source: r2 requires shadow-first, non-blocking collector, tick-close only, and
p95 latency signal at `02-REFINE-r2.md:65`.

Coverage:

- Direct: B4 ranker, B5 doctor, B6 tick-close gate, B7 rollout mode, B9 latency
  fixture.
- Indirect: B1/B2/B3 substrate, B8 dogfood, B11 status, B12 rollout.

Strength:

The rollout machine is explicit: off, shadow, warn, enforce, rollback at
`02-REFINE-r2.md:460-470`, with p95 latency budget at `02-REFINE-r2.md:476`.

Gap:

No new finding. FM4 is covered well enough for Phase 4 because the p95 budget is
concrete and B9 owns the latency fixture. FMC-F3's backfill horizon amendment
is the main protection against FM3 creating FM4.

### FM5 — Bootstrap Recursion

Source: r2 requires bootstrap rows, self-test evidence hash, and dogfood before
enforce at `02-REFINE-r2.md:66`.

Coverage:

- Direct: B1 schema, B3 detector, B6 close hook, B7 bootstrap/override, B8
  dogfood, B9 FM5 fixture.
- Indirect: B2 classifier, B5 doctor, B10 doctrine, B12 rollout, B13-B15
  substrate-loss layers.

Strength:

Bootstrap lens already adds first-event mechanics: `bootstrap_seed/v1`,
first-detector witness, seed-vs-bypass split, first L109 proof, first side
branch path, and leader/follower rollout.

Gap:

No new finding beyond BR-F1 through BR-F6. The FM is covered; Phase 4 must
import the bootstrap lens amendments.

### FM6 — Cross-Repo Ship Waits On Peer Repo Consumer

Source: r2 requires fleet ledger, repo ownership scope, and bounded cross-repo
pending at `02-REFINE-r2.md:67`.

Coverage:

- Direct: B1 fleet ledger, B5 doctor, B6 close gate, B7 cross-repo pending, B9
  expiry fixture, B11 status, B12 rollout.
- Indirect: B2/B3/B4/B8/B10/B13/B14/B15.

Strength:

B12 explicitly says each orch blocks only on owned rows and cross-repo pending
surfaces without halting unrelated repos before expiry at
`02-REFINE-r2.md:390-394`.

Gap:

The bound is not defined. "Before expiry" implies time, but the plan does not
name the expiry field, default duration, row-count cap, retry cap, or owner
handoff behavior. Cross-cutting lens covers ownership scope; this lens covers
the boundedness requirement itself.

New finding: FMC-F4.

### FM7 — Stale Wiring After Consumer Removal

Source: r2 requires daily re-verification, new superseding unwired row, and
repair bead at `02-REFINE-r2.md:68`.

Coverage:

- Direct: B3 detector, B5 doctor, B9 stale-consumer fixture, B11 operator
  surface.
- Indirect: B1 ledger, B4 ranker, B6 close gate, B12 rollout, B15 learn route.

Strength:

B9 explicitly includes stale consumer supersession at `02-REFINE-r2.md:363`.
B11 gives the operator a resolve/defer command path at `02-REFINE-r2.md:379-385`.

Gap:

"Daily" is not enough for implementation. The plan does not specify cadence,
cost budget, skip/defer rules for expensive repos, stale-consumer owner, or
repair-bead trigger. This is coverage weakness, not a blocker.

New finding: FMC-F5.

## Per-Bead Inverse Analysis

| Bead | Direct FMs | Source-finding coverage | Orphan? |
|---|---|---|---|
| B1 ledger schema + writer | FM5,FM6 | F1,F3, idempotency identity/write safety | no |
| B2 ship-event classifier | FM3 | F1,F8,F9, idempotency identity | no |
| B3 wired detector | FM1,FM2,FM3,FM5,FM7 | F1,F2,F7, bootstrap first-detector proof | no |
| B4 ranker | FM4 | F4 list-and-sort, bottleneck protection | no |
| B5 doctor fields | FM1,FM4,FM6,FM7 | F7 remediation hints, CC-F4 action JSON | no |
| B6 close gate | FM2,FM3,FM4,FM5,FM6 | F1,F2,F5, idempotent gate evaluation | no |
| B7 shadow/enforce/override | FM2,FM4,FM5,FM6 | F5 rollout, override boundaries, bootstrap seed | no |
| B8 dogfood import | FM3,FM5 | F1,F3,F4,F5,F8,F9, import idempotency | no |
| B9 fault-injection tests | FM1-FM7 | all FM fixtures plus audit-lens hardening | no |
| B10 L109 doctrine | FM2,FM5,FM6 | F2,F5,F6, three-surface sync baseline | no |
| B11 wire-status surface | FM2,FM6,FM7 | F4,F7 operator remediation | no |
| B12 cross-orch rollout | FM6, plus FM4/5 support | F6,F8, cross-orch ownership | no |
| B13 side-branch enforcement | FM5/6 support | F9 substrate-loss worker commit orphan | no |
| B14 DCG reset blocker | FM5/6 support | F9 substrate-loss information-flow guard | no |
| B15 memory + learn promotion | FM6/7 support | F9 behavioral promotion and learn path | no |

Orphan beads count: `0`

Notes:

- B13-B15 do not map cleanly to FM1-FM7 because they were added for Finding 9,
  not the original seven-mode runtime list.
- That is not an orphan-bead problem. It is a canonical failure-mode-list gap.
- B10 is also not orphaned: it supports FM2/FM5/FM6 by preventing the gate from
  remaining doctrine-only and by using the three-surface propagation pattern.

## Coverage Gap List

These are not new duplicate findings; they are unnamed failure classes already
surfaced by r2 or prior audit lenses that do not fit neatly in FM1-FM7.

| Candidate | Source | Why not fully covered by FM1-FM7 | Recommended Phase 4/5 treatment |
|---|---|---|---|
| FM8 ledger corruption / replay nondeterminism | idempotency lens IDEMP-01 to IDEMP-08 | FM1-FM7 talk about discovery, false positives, false negatives, bottleneck, bootstrap, cross-repo, stale wiring; none names crash-tail/reducer corruption. | Add FM8 or a `ledger_integrity` subsection under B1/B9. |
| FM9 substrate-loss worker commit orphan | INTENT Finding 9 and B13-B15 | It is a git workflow substrate-loss class, not a wiring classification class. | Add FM9 or explicitly label B13-B15 as `non_fm_source_finding=F9`. |
| FM10 consumer-path mismatch | INTENT Jeff-corpus finding and B2/B8/B12 | This is a shipped-corpus consumer-default-path mismatch; related to FM3, but not identical. | Add as FM10 or B2 artifact class `consumer_path_pointer`. |
| FM11 doctor/status remediation absent | cross-cutting CC-F4 | Related to FM2/FM7 but applies to all unresolved rows and automation consumers. | Add action-hint requirements to B5/B11, not necessarily a top-level FM. |
| FM12 first-event bootstrap subtypes | bootstrap lens BR-F1 to BR-F6 | FM5 names bootstrap recursion but not first detector, first override, first L-rule, first side-branch, or leader/follower specifics. | Keep as FM5 submodes unless Phase 5 polish wants explicit FM5a-FM5f. |

Coverage gaps count: `5`

## TRUE Blocker Class Evaluation

Result: no TRUE blocker class triggered.

| Class | Triggered | Evaluation |
|---|---|---|
| `new-platform-or-vendor-not-in-mission-lock` | no | No new platform/vendor; findings are local schema, fixture, and plan-bead amendments. |
| `secret-rotation-or-new-credential-creation` | no | No secrets or credentials are created or rotated. |
| `financial-commitment-above-mission-budget` | no | No spending or paid resource is proposed. |
| `legal-or-compliance-decision` | no | No legal/compliance decision is required. |
| `destructive-irreversible-on-shared-state` | no | This lens is read-only; B14 is a prevention guard and uses synthetic fixtures. |
| `paradigm-conflict-with-active-mission` | no | Coverage gaps reinforce the plan's paradigm; they do not contradict it. |

Blocker class evaluations: 6/6

Triggered blocker classes: none

## Composite Score

Score: `7.6/10.0`

Pass threshold: `>=7.0`

Verdict: pass

Rationale:

- All FM1-FM7 have direct mitigation beads and test owners.
- No B1-B15 bead is orphaned.
- The inverse pass finds the expected shape: B9 is the universal fixture bead,
  B1/B2/B3/B6 are core substrate, B7/B8/B12 handle rollout, and B13-B15 cover
  Finding 9.
- Score is not higher because several FM mitigations are only described at
  concept level: FM1 scan budget, FM2 authority, FM3 horizon, FM6 bounds, FM7
  cadence.
- Coverage gaps are additive Phase 4/5 polish work, not blockers.

## Systems Reading

SYSTEM: wire-or-explain tick close and artifact-utilization loop.

STOCK: unresolved shipped artifacts plus unnamed failure classes.

PATTERN: a plan can have broad bead coverage while still leaking specificity at
FM boundaries.

LOOP: coverage matrix is the balancing loop. It converts "we have a bead" into
"this failure mode has a runnable proof and owner."

LEVERAGE_POINT: Meadows #5 rules and #6 information flows. The rule is the
FM-to-bead matrix; the information flow is callback metrics
`fm_coverage_pct`, `coverage_gaps_count`, and `orphan_beads_count`.

INTERVENTION: carry the matrix into Phase 4 bead bodies and Phase 5 polish,
where every bead must cite its direct FM or source-finding coverage.

MEASURE: `fm_coverage_pct=100`, `orphan_beads_count=0`,
`coverage_gaps_count=5`.

## Final Decision

Audit disposition: `auto_advance_eligible`.

Conditions:

- No critical findings.
- No TRUE blocker class triggered.
- FM1-FM7 all covered.
- No orphan beads.
- Coverage gaps have Phase 4/5 amendment paths.

Callback fields:

```text
self_grade=Y
findings_total=6
findings_by_severity={critical:0,high:1,medium:4,low:1}
composite_score=7.6
true_blocker_classes_triggered=none
blocker_class_evaluations=6/6
fm_coverage_pct=100
coverage_gaps_count=5
orphan_beads_count=0
commits_total=0
```
