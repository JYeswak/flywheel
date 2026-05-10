---
title: "Phase 3 AUDIT r1 — Bootstrap Recursion"
type: plan
created: 2026-05-06
frontmatter_source: scaffold-doc-frontmatter
---

# Phase 3 AUDIT r1 — Bootstrap Recursion

Plan: `wire-or-explain-tick-gate-2026-05-04`
Lens: bootstrap-recursion
Generated: 2026-05-04T22:47Z
Mode: plan-space read-only audit
Prior round: none

## Scope

This lens audits only self-proving, self-bypassing, first-event, and
chicken-and-egg failure modes in the r2 plan. It reads the cross-cutting audit
and does not duplicate its main finding, CC-F2, which says the B6 enforce flip
must depend on B8/B9 bootstrap proof.

This audit instead asks: what is the first valid event for each loop primitive,
and what out-of-band or lower-layer fact lets that first event terminate rather
than recurse forever?

Skills applied:

- `gate-truth-separation`: this is a wiring-flow bootstrap audit, not code
  correctness, safety approval, or mission approval.
- `donella-meadows-systems-thinking`: stock is unwired-output backlog; bootstrap
  rows are a rule-level intervention that must not become a bypass stock.
- `lean-formal-feedback-loop`: each first event needs a witness, fixture, and
  hashable proof artifact.
- `multi-pass-bug-hunting`: findings are new bootstrap-specific gaps, not
  duplicates of cross-cutting CC-F1 through CC-F7.

Socraticode survey:

- Query 1: `wire or explain bootstrap recursion self proof override tick close gate`
- Query 2: `bootstrap self proof shadow enforce override flywheel loop audit`
- Relevant precedent surfaced: `INCIDENTS.md` documents
  `documented-bug-not-actioned-self-recursion`, where self-bug beads were caught
  in the selector failure they described. That is the same recursion class this
  plan must avoid.

Self-grade: `Y`

Composite score: `7.9/10.0`

Disposition: `auto_advance_eligible`

Reason: no TRUE Joshua-blocker class fires. The recursion classes are tractable
with seed rows, one-shot bootstrap authority, shadow-first enforcement, and
first-event fixtures.

## Findings Table

| ID | Severity | Beads affected | Description | Mitigation |
|---|---|---|---|---|
| BR-F1 | high | B1,B6,B7,B8,B9 | r2 names bootstrap rows, but does not define the first valid bootstrap authority that makes a bootstrap row valid before the gate exists. | Add `bootstrap_seed/v1` row type and one-shot genesis verifier owned by B1/B7; B9 proves it is consumed and cannot mint general bypasses. |
| BR-F2 | high | B3,B6,B8,B9 | B3 refuses circular proof, but the first wired-detector proof can still become circular if the detector's own row is classified by itself. | Require first detector proof to use an independent static consumer registry plus B9 witness; detector cannot classify its own first row as `wired`. |
| BR-F3 | medium | B7,B9,B10 | General bypass/override semantics can precede their own wiring proof unless bootstrap override and normal bypass are separate states. | Split `bootstrap_seed` from `bypassed`; general `bypassed` disabled until B7 proof exists and B10 cites it. |
| BR-F4 | medium | B10,B12 | L109's first three-surface deployment is governed by the system it describes; using the new gate as the first proof would recurse. | First L109 row must be proven by the pre-existing D2 canonical sync/check chain, then later rechecked by wire-or-explain. |
| BR-F5 | medium | B13,B14,B15 | First worker side-branch dispatch cannot require a worker to comply with B13 before B13 is installed in the dispatch template. | Add a one-tick `legacy_bootstrap_dispatch` path where the orchestrator creates/announces the branch contract and B13 records adoption before enforcement. |
| BR-F6 | medium | B12,B1,B6,B7 | Cross-orch first rollout can deadlock if orch A waits on orch B's consumer while orch B waits on orch A's ledger writes. | Add leader/follower rollout phases and `cross_repo_pending_bootstrap` rows that surface but do not halt until both sides have a consumer. |

Findings total: 6

Findings by severity: critical 0, high 2, medium 4, low 0

## Finding BR-F1 — Missing First Bootstrap Authority

Severity: high

Class: bootstrap authority / self-bypass

Beads affected: B1, B6, B7, B8, B9

Description:

r2 says FM5 is mitigated by "bootstrap rows, self-test evidence hash, dogfood
before enforce" at `02-REFINE-r2.md:66`, and B7 says bootstrap override expires
after gate self-test at `02-REFINE-r2.md:341`. The missing primitive is the
authority model for the very first bootstrap row. A row cannot be valid because
the gate says it is valid if the gate is not yet installed.

First-event failure scenario:

1. B1 ships schema and writer.
2. B6 ships a close hook in shadow mode.
3. B7 wants to write a bootstrap override to let the gate's own row pass.
4. The override system has not yet proven itself wired.
5. If the row is simply `bypassed`, it teaches the system that arbitrary bypass
   can precede proof.
6. If the row must be verified by B7, it recurses into "B7 proves B7."

Mitigation:

Add a separate `bootstrap_seed/v1` state that is not the same as `bypassed`.
It is valid only for a hardcoded set of artifacts created by B1-B9 during
initial installation and only until the first B9 FM5 witness passes.

Gate amendments: B1 validates seed allowlist and required proof fields; B7
rejects normal bypass until seed consumption; B9 proves one seed closes and
cannot be reused; B6 enforce refuses unconsumed or off-allowlist seeds.

## Finding BR-F2 — First Wired-Detector Proof Can Still Be Circular

Severity: high

Class: self-proving detector / circular witness

Beads affected: B3, B6, B8, B9

Description:

B3 already refuses circular proof where producer path equals consumer proof path
at `02-REFINE-r2.md:292-293`. That prevents the simplest self-proof, but the
first detector row still needs an independent witness. Otherwise B3 can classify
the B3 detector as wired using a discover command that ultimately invokes B3.

First-event failure scenario:

1. B3 detector ships.
2. B2 classifier emits `artifact_class=detector` for B3.
3. B3 tries to classify the detector's own row.
4. The discover command runs B3 or a wrapper around B3.
5. The row becomes "wired" because the detector says the detector is wired.

Mitigation:

Define an independent first-detector witness:

- A static `manual-consumers/bootstrap.json` or schema fixture lists B3's first
  valid consumer as B6 shadow close hook plus B9 FM5 test.
- B3 may read that registry but cannot write it.
- The first detector row is `bootstrap_seed` or `questionably_wired` until B9
  records a witness hash.
- After B9 passes, B3 can classify later detector changes normally.

Gate amendments: B3 self-pointing fixtures return `questionably_wired`, not
`wired`; the first detector row needs a static registry plus B9 evidence; B8
imports that proof; B9 rejects discover commands that call B3 as circular.

## Finding BR-F3 — Bootstrap Override and General Bypass Must Be Different States

Severity: medium

Class: first-override paradox

Beads affected: B7, B9, B10

Description:

r2's resolution states include `bypassed` at `02-REFINE-r2.md:42`, while B7
owns shadow/enforce/override at `02-REFINE-r2.md:333-342`. If the first
override is represented as a normal bypass, then normal bypass exists before
the bypass policy is itself wired. That is a first-override paradox.

First-event failure scenario:

1. A bootstrap artifact is unresolved.
2. B7 writes a `bypassed` row so the tick can continue.
3. Future code sees `bypassed` as a normal state and accepts it.
4. The distinction between one-shot bootstrap and operator override is lost.

Mitigation:

Split state:

- `bootstrap_seed`: installation-only, hard allowlist, consumed by B9.
- `bypassed`: post-B7 normal override, requires `override_reason`,
  `override_owner`, `expires_at`, `authorized_by`, and B7 proof hash.

Gate amendments: general `bypassed` rows are invalid before B7 proof; bootstrap
seeds cannot carry Joshua-approval semantics; normal bypass cannot reference
expired seed artifacts; B10 states seed rows are not override precedent; B9
proves invalid reuse fails.

## Finding BR-F4 — L109 First Deployment Needs Existing Sync Proof

Severity: medium

Class: doctrine self-governance recursion

Beads affected: B10, B12

Description:

B10 deploys L109, a doctrine rule governing wire-or-explain, and B10 acceptance
requires three-surface landing at `02-REFINE-r2.md:365-373`. If L109's first
deployment is considered wired only because wire-or-explain certifies it, the
rule proves itself. The r2 plan already identifies the existing canonical
meta-rule sync/check chain as the one D2 fully wired baseline; L109 should use
that pre-existing chain as its first proof.

First-event failure scenario:

1. B10 adds L109 to AGENTS surfaces.
2. B2 emits `artifact_class=l_rule`.
3. Wire-or-explain tries to decide whether L109 is wired.
4. The only consumer named is wire-or-explain itself.
5. L109 self-certifies through the rule it is installing.

Mitigation:

For first deployment only:

- L109's initial row uses `wired_by_existing_sync_chain`.
- Evidence points to the established canonical sync/check path and drift count.
- A later recheck may convert it to normal `wired` once B10/B12 rollout proves
  wire-or-explain consumes L-rule rows.

Gate amendments: B10 first-row fixture must be
`wired_by_existing_sync_chain`; missing sync evidence invalidates it; B12 later
rechecks L109 and emits a superseding normal row; L109 cannot evidence itself.

## Finding BR-F5 — First Side-Branch Dispatch Needs a Legacy Bootstrap Path

Severity: medium

Class: contract rollout recursion

Beads affected: B13, B14, B15

Description:

B13 requires dispatch packets to include a worker side-branch and callbacks to
report branch/ref at `02-REFINE-r2.md:397-405`. The first dispatch using that
new contract may target a worker whose dispatch template does not yet contain
B13. Requiring B13 proof before B13 is installed creates a first-dispatch
recursion.

First-event failure scenario:

1. Orchestrator sends the first B13 implementation dispatch.
2. The existing dispatch template lacks side-branch requirements.
3. Worker writes to local main because old contract allowed it.
4. B14 later blocks reset or B13 marks callback invalid.
5. The first B13 installation reproduces the substrate-loss class it was meant
   to prevent.

Mitigation:

Add `legacy_bootstrap_dispatch` for exactly the B13 rollout:

- Orchestrator creates or names the branch in the packet.
- Worker reports branch/ref even if template does not yet require it.
- B13 records adoption as a seed row.
- After B13 lands, legacy bootstrap is disabled.

Gate amendments: first B13 fixture uses
`contract_version=legacy_bootstrap`; second legacy use fails; worker-main is
invalid unless the orchestrator already recorded a branch ref; B14 enforce waits
for B13 adoption; B15 cites the adoption receipt.

## Finding BR-F6 — Cross-Orch First Rollout Needs Leader/Follower Phases

Severity: medium

Class: two-party bootstrap deadlock

Beads affected: B12, B1, B6, B7

Description:

B12 says cross-repo pending rows surface fleet-wide but do not halt unrelated
repos before expiry at `02-REFINE-r2.md:393-394`. That is good for steady state,
but first rollout needs a stronger sequence: orch A's ledger writes may require
orch B's consumer, while orch B's consumer may require orch A's ledger rows.

First-event failure scenario:

1. Flywheel installs ledger writes first.
2. Skillos has no consumer yet, so flywheel rows targeting skillos are pending.
3. Skillos installs the consumer but waits for flywheel to mark the row owned.
4. Both sides surface the problem but neither can prove the first cross-orch
   row is valid.

Mitigation:

Add rollout phases:

1. `leader_shadow`: flywheel writes fleet rows, never halts siblings.
2. `follower_shadow`: sibling reads rows and emits consumer proof, never halts.
3. `paired_warn`: both sides can warn on expired cross-repo pending.
4. `paired_enforce`: only rows with ownership proof can halt the owning repo.

Gate amendments: A-only rows are `cross_repo_pending_bootstrap`; paired A+B
rows become `cross_repo_wired`; B6 ignores pending bootstrap rows until expiry;
B7 cannot turn them into permanent bypass; B12 callback reports paired and
unpaired counts.

## Bootstrap Order Map

The following order is the minimum safe topological order for bootstrap
recursion. It is stricter than the r2 DAG only where first-event semantics need
more precision.

```text
O1  B1 schema supports normal rows plus bootstrap_seed/v1.
O2  B1 writer can append seed rows with flock and idempotency.
O3  B2 classifier emits ship rows but does not classify rows as wired.
O4  B3 detector ships in shadow with static bootstrap consumer registry.
O5  B4 ranker can rank bootstrap/unresolved rows without blocking.
O6  B5 doctor exposes bootstrap status and invalid seed count.
O7  B6 close hook installs in shadow only; enforce disabled.
O8  B7 consumes bootstrap_seed/v1 and proves normal bypass remains disabled.
O9  B8 imports dogfood rows, including B3/B6/B7/B8 self rows and D2 baseline.
O10 B9 FM5 fixture proves bootstrap seed closes and cannot be reused.
O11 B6 enforce flip becomes eligible after O10.
O12 B10 L109 doctrine lands through existing sync/check chain first.
O13 B11 wire-status renders bootstrap status but does not mutate.
O14 B13 side-branch contract adopts via one legacy bootstrap dispatch.
O15 B14 DCG reset blocker runs shadow until B13 adoption exists.
O16 B15 memory/learn promotion cites B13/B14 receipts.
O17 B12 cross-orch rollout starts leader_shadow, then follower_shadow, then paired_warn, then paired_enforce.
```

Order properties:

- B6 shadow is allowed before B8/B9; B6 enforce is not.
- B10 doctrine is allowed before B12 fleet rollout only because it uses the
  existing D2 sync/check chain as first proof.
- B14 shadow is allowed before B13 adoption; B14 enforce is not.
- B12 paired enforce is not allowed until at least one leader/follower pair has
  emitted reciprocal proof.

Bootstrap order documented: yes

## First-Event Scenarios

### 1. B3 Wired Detector

First instance: first ship row for the B3 detector.

Escape hatch:

- Static bootstrap registry names B6 shadow hook and B9 witness as independent
  consumers.
- B3 cannot classify its own first row as `wired`.
- State progresses `bootstrap_seed` -> `bootstrap_wired` -> `wired`.

Risk if omitted: detector self-certifies.

### 2. FM5 Bootstrap State

First instance: first `bootstrap_seed/v1` row written by B1/B7.

Escape hatch:

- Hard allowlist and expiry.
- B9 consumes it.
- B6 enforce refuses unconsumed or expired seed rows.

Risk if omitted: bootstrap becomes permanent bypass.

### 3. B7 Override Mechanism

First instance: first normal `bypassed` row.

Escape hatch:

- Normal bypass invalid until B7 proof hash exists.
- Bootstrap seed is separate and cannot carry normal override semantics.

Risk if omitted: first override proves override system by using it.

### 4. B6 Tick-Close Gate Self-Evaluation

First instance: first artifact row for the close hook itself.

Escape hatch:

- Shadow hook writes rows and receipts but cannot block.
- B8 imports the self-row.
- B9 proves self-row closure.
- Enforce flips only after proof.

Risk if omitted: infinite regress or false-green close.

### 5. B14 DCG Core.git Rule

First instance: first installation of `core.git:reset-mixed-with-orphan-commits`.

Escape hatch:

- Install in shadow first.
- Enforce waits for B13 side-branch adoption.
- Synthetic fixtures only; no production refs touched.

Risk if omitted: guard blocks the migration that installs the guard.

### 6. B13 Worker Side-Branch Contract

First instance: first dispatch after the new branch contract is introduced.

Escape hatch:

- `legacy_bootstrap_dispatch` one-shot path.
- Orchestrator names/creates branch and records adoption.
- Second legacy use fails.

Risk if omitted: first B13 implementation repeats worker-main orphaning.

### 7. B15 Memory Promotion

First instance: first `feedback-substrate-loss-worker-commit-orphan.md`
promotion row.

Escape hatch:

- Memory row can be `not_required` or `wired_by_existing_memory_index` for first
  event.
- Later learn/doctrine path can supersede it after B15 proof.

Risk if omitted: memory infrastructure must prove itself through memory
promotion.

### 8. B12 Cross-Orch Fleet Rollout

First instance: first cross-repo row where producer and consumer are in
different orchestrator sessions.

Escape hatch:

- `leader_shadow` writes without halting.
- `follower_shadow` consumes without halting.
- Paired proof enables warn, then enforce.

Risk if omitted: orch A and orch B each wait on the other to be first.

### 9. B10 L109 Doctrine Deployment

First instance: first L109 row across root AGENTS, canonical AGENTS, and
template AGENTS.

Escape hatch:

- First proof comes from existing D2 sync/check baseline.
- Later wire-or-explain rechecks as normal artifact class.

Risk if omitted: L109 proves itself by saying L109 is required.

First-event scenarios: 9

## TRUE Blocker Class Evaluation

Result: no TRUE blocker class triggered.

| Class | Triggered | Evaluation |
|---|---|---|
| `new-platform-or-vendor-not-in-mission-lock` | no | All mitigations use existing local plan/bead/doctor/ledger/sync/DCG surfaces. |
| `secret-rotation-or-new-credential-creation` | no | No credential, token, or secret mutation is needed. |
| `financial-commitment-above-mission-budget` | no | No paid service, infra spend, or budget decision is introduced. |
| `legal-or-compliance-decision` | no | This is an internal operational gate; no legal/compliance judgment is needed. |
| `destructive-irreversible-on-shared-state` | no | B14 concerns destructive reset prevention, but this audit only requires shadow mode and synthetic fixtures. |
| `paradigm-conflict-with-active-mission` | no | Bootstrap recursion is tractable; it does not contradict the mission. It requires better first-event mechanics, not a new paradigm. |

Blocker class evaluations: 6/6

Triggered blocker classes: none

## Composite Score

Score: `7.9/10.0`

Pass threshold: `>=7.0`

Verdict: pass

Scoring rationale: r2 correctly recognizes FM5 and circular self-proof, and
existing shadow mode plus the D2 sync/check baseline make recursion tractable.
The score stays below 8.0 because first-event mechanics, bootstrap seed vs
normal bypass, and cross-orch leader/follower rollout are not yet
machine-specified.

## Audit Ledger

Three-Q audit:

- VALIDATED: every finding cites r2/cross-cutting/intent/plan command source
  lines and has a concrete first-event failure scenario.
- DOCUMENTED: bootstrap order map and nine first-event scenarios are included.
- SURFACED: no TRUE blocker class; findings map to Phase 4 bead amendments.

Plan-space discipline:

- Source files edited: none.
- Beads DB writes: none.
- Commits: none.
- New artifact:
  `.flywheel/plans/wire-or-explain-tick-gate-2026-05-04/03-AUDIT-r1-bootstrap-recursion.md`.

Callback fields:

```text
self_grade=Y
findings_total=6
findings_by_severity={critical:0,high:2,medium:4,low:0}
composite_score=7.9
true_blocker_classes_triggered=none
blocker_class_evaluations=6/6
bootstrap_order_documented=yes
first_event_scenarios=9
commits_total=0
```
