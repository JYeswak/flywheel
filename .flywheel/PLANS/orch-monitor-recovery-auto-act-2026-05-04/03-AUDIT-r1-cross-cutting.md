# Phase 3 Audit R1 - Cross-Cutting

```text
plan=orch-monitor-recovery-auto-act-2026-05-04
artifact=03-AUDIT-r1-cross-cutting.md
lens=cross-cutting
mode=plan-space-read-only
worker_identity=MagentaPond
date=2026-05-04
```

## 1. Verdict

Disposition: auto-advance with required Phase 4 rework.

Self-grade: Y.

Composite score: 7.2 / 10.

Critical findings: 0.

High findings: 2.

Medium findings: 4.

Low findings: 1.

TRUE blocker classes triggered: none.

The converged r1 plan is directionally right: it names the missing layer as
observation-to-action authority, makes B1 the supervision-first root, absorbs
watcher, Beads DB, and Agent Mail into the same handler, and keeps
wire-or-explain as the owner of artifact wiring truth.

The cross-cutting problem is not conceptual disagreement. The problem is that
the refined plan is carrying two pieces of unresolved structure into Phase 4:

1. L110 is cited by a sibling paradigm artifact, but not materialized as a bead
   or as explicit acceptance gates on the existing bead set.
2. The 27-bead r1 set exceeds `/flywheel:plan`'s total cap of 15 beads per
   plan, and the L110 absorption path would make that 28 unless the plan is
   split or amended.

These are high-priority Phase 4 corrections, not Joshua blockers.

## 2. Evidence Read

Required sources read: `00-INTENT.md`, `01-RESEARCH-A.md`,
`01-RESEARCH-B.md`, `01-RESEARCH-C.md`, `02-REFINE-r1.md`,
`.flywheel/PARADIGM-substrate-self-organization-2026-05-04.md`,
`../wire-or-explain-tick-gate-2026-05-04/02-REFINE-r2.md`, and
`~/.claude/commands/flywheel/plan.md` Phase 3/4 spec.

Pre-flight substrate survey:

```text
socraticode_queries=4
indexed_chunks_observed=443
reservation_conflict_check=clear
mcp_file_reservation=not_authenticated_as_MagentaPond
raw_token_used=no
commits_total=0
```

The Agent Mail MCP reservation call required a registration token for
`MagentaPond` in this MCP session. I did not pass a raw token. I checked the
active reservation table for the exact output path and broad plan-path overlaps;
no active reservation conflicted with this audit artifact.

Skills applied: `donella-meadows-systems-thinking`,
`gate-truth-separation`, `canonical-cli-scoping`,
`simplify-and-refactor-code-isomorphically`, and
`multi-pass-bug-hunting`.

## 3. Audit Frame

This audit asks whether cross-cutting concerns are structurally owned, not
whether every local implementation detail is already specified.

The key invariants:

1. Every recurring observation surface must have an action, no-auto-repair
   reason, or explicit escalation threshold.
2. Wire-or-explain owns artifact truth; orch-monitor consumes that truth when
   deciding whether to act.
3. Sibling plans must not create duplicate ledgers, gates, or branch/reset
   policies.
4. Peer-orchestrator action must be scoped by ownership rows and protected
   recovery evidence.
5. Phase 4 must remain dispatchable: 8-15 beads per plan, 3-5 beads per wave,
   no unbounded "mega-DAG".
6. Audit findings do not pause unless one of the six TRUE blocker classes fires.

## 4. Finding Summary

| ID | Severity | Beads affected | Summary | Required Phase 4 action |
|---|---:|---|---|---|
| CC-1 | high | B1,B11,B13,B14,B21-B27 | L110 is not concretely absorbed. | Add B28 or amend named beads with `substrate-loop-contract/v1` gates. |
| CC-2 | high | B1-B27 plus L110 path | 27 beads violates the 15-bead cap; L110 would make 28. | Split into sequential plans or explicitly collapse/amend before `br create`. |
| CC-3 | medium | B1,B2,B5,B7,B9,B11,B14,B21-B27 | Lane B says 35 primitives audited and 25 wired, but r1 maps them coarsely. | Add primitive-to-bead trace matrix. |
| CC-4 | medium | B25-B27,B1,B11,B14 | Agent Mail tactical repair has landed; r1 language still reads as if live rows are unresolved. | Reframe Agent Mail beads as recurrence prevention and regression coverage. |
| CC-5 | medium | B1,B5,B10-B14,B16-B20,B25-B27 | WOE ownership is resolved 5/5, but handler ordering and consumed fields are not explicit enough. | Add a WOE consumption contract to B1/B11/B12/B13. |
| CC-6 | medium | B5-B7,B9-B12,B16-B20,B25-B27 | Cross-orch action scope lacks one owner/source/TTL table. | Add peer-scope decision table and failover fixtures. |
| CC-7 | low | B1,B8,B11,B14 | Canonical CLI surface is underspecified in r1 bead wording. | Add `why`, `audit`, `validate`, `repair`, JSON schema, and stable exits where applicable. |

Findings total: 7.

Cross-bead findings count: 7.

## 5. CC-1 - L110 Is Not Absorbed

Severity: high.

Affected beads: B1, B11, B13, B14, B21, B23, B25, B27, and likely B28.

Evidence:

1. The paradigm artifact proposes L110 as the rule that every substrate primitive
   declaring a recurring condition must name stock, inflow, outflow, repair
   owner, action class, ledger, verification probe, and tick/status consequence.
2. The same artifact defines `substrate-loop-contract/v1` fields and recommends
   Phase 4 absorption into this orch-monitor plan.
3. It explicitly proposes `B28 - substrate-loop-contract-l110`.
4. The r1 refined plan has B13 as `supervision-contract-three-surface`, but B13
   is doctrine-after-mechanics, not the mechanical contract schema.
5. The r1 27-bead table does not include B28 and does not amend B1, B11, B13,
   B14, B21, B23, B25, or B27 with the L110 fallback gates.

Why this matters:

The core failure class in INTENT is "probe measured, fleet did not act." L110 is
the reusable contract that prevents the same pattern from reappearing as soon as
the system adds another probe. Without it, the plan can still ship another
bespoke supervisor while leaving future substrate primitives free to repeat the
observation-only failure.

This is a Donella #5 and #4 gap:

1. #5 rules: the substrate work contract has not changed yet.
2. #4 self-organization: new primitives do not have a schema they can use to
   declare their own repair loops.

Required correction:

Preferred: add B28 `substrate-loop-contract-l110` with dependencies:

1. Depends on B1.
2. Depends on B11.
3. Feeds B13.
4. Feeds B14.
5. Proves against B21-B27.

Acceptance gates:

1. `substrate-loop-contract/v1` schema exists.
2. Validator accepts fixtures for watcher, Beads DB, Agent Mail, observatory,
   and wire-or-explain consumption gaps.
3. Validator rejects observation-only probes with no action and no explicit
   no-auto-repair reason.
4. Doctor emits `substrate_loop_contract_missing_count`.
5. Status shows a compact substrate-loop contract line.
6. Dispatch template for substrate work requires contract fields.
7. L110 cites this convergence artifact.

Fallback if cap cannot absorb B28:

Amend B1, B11, B13, B14, B21, B23, B25, and B27 with the same L110 acceptance
gates. Do not claim L110 absorption until one of these two routes is explicit.

Audit result:

```text
L110_absorbed=no
```

## 6. CC-2 - Bead Cap Risk Is High

Severity: high.

Affected beads: B1-B27, plus proposed B28.

Evidence:

1. `/flywheel:plan` Phase 4 says total cap is 15 beads per plan.
2. r1 says the final count is intentionally 27.
3. r1 breaks the count into 15 core supervision, 5 watcher propagation, 4 Beads
   DB maintenance, and 3 Agent Mail registration beads.
4. The L110 paradigm artifact proposes a 28th bead or fallback amendments.

Why this matters:

The cap is not arbitrary bookkeeping. It preserves dispatchability, keeps waves
at 3-5 beads, and prevents one plan from becoming the owner of every related
substrate problem. This plan is already a cross-cutting convergence point. If
Phase 4 creates all 27 or 28 beads inside one bead DAG, the plan will become a
fleet-infra mega-DAG that is hard to schedule, audit, and close.

Required correction:

Split before `br create`, unless the orchestrator records an explicit cap
decision in Phase 4.

Recommended split:

Plan A: `orch-monitor-recovery-auto-act-core`.

1. Owns B1-B15.
2. Delivers the supervision-first handler.
3. Consumes WOE artifacts.
4. Produces doctor/status/action ledger fields.
5. Dogfoods ALPS phantom blocker.

Plan B: `orch-monitor-substrate-self-org-propagation`.

1. Owns B16-B28 or the L110 fallback amendments.
2. Carries watcher propagation, Beads DB maintenance, Agent Mail registration
   recurrence prevention, and substrate-loop contract validation.
3. Depends on Plan A B1/B11/B13/B14 interfaces, not on Plan A implementation
   internals.

Audit result:

```text
cap_violation_risk=high
```

## 7. CC-3 - Lane B Primitive Traceability Is Too Coarse

Severity: medium.

Affected beads: B1, B2, B5, B7, B9, B11, B14, B21-B27.

Evidence:

1. r1 reports `lane_b_primitives_audited=35`.
2. r1 reports `lane_b_primitives_wired_proposed=25`.
3. r1's source mapping collapses the entire Lane B inventory into
   `B1,B2,B5,B7,B9,B11,B14,B21-B27`.
4. That mapping proves high-level absorption, but not that each of the 25
   adopted primitives has a consumer, owner, acceptance gate, and no-duplicate
   rule.

Why this matters:

Lane B is the inventory of existing substrate. The plan's central promise is
reuse before build. If Phase 4 does not preserve primitive-level traceability,
implementation can accidentally rebuild a local version of an existing primitive
or leave an adopted primitive as "supporting context" instead of a consumed
input.

Primitive trace notes:

| # | Primitive class | Expected coverage | Cross-cutting audit note |
|---:|---|---|---|
| 1 | frozen pane detector v2 | B1,B2,B5,B12 | Covered; needs handler-first consumption proof. |
| 2 | frozen recovery leases | B5,B12 | Covered; no duplicate lease namespace. |
| 3 | frozen recovery ledger | B1,B5,B11,B14 | Covered; needs root action ID join. |
| 4 | frozen pane samples | B5,B11 | Covered; sample paths should be action evidence. |
| 5 | frozen detector self-test | B12 | Covered as fixture input. |
| 6 | frozen detector SLO thresholds | B11,B12 | Covered; preserve 180s envelope. |
| 7 | frozen fleet wrapper | B5,B8 | Covered; wrapper must not become the supervisor. |
| 8 | frozen fleet launchd | B8 | Covered; enablement decision must be explicit. |
| 9 | recovery SLO probe | B11,B14 | Covered; probe is not action. |
| 10 | idle state probe | B7,B11 | Covered; dispatch bridge must be explicit. |
| 11 | idle pane auto dispatch | B7 | Covered; do not duplicate dispatch engine. |
| 12 | idle watcher plists | B8,B16-B20 | Covered; propagation track owns templates. |
| 13 | peer blocker watch | B7,B9,B11 | Covered; notify policy must stay sparse. |
| 14 | peer productivity watch | B7,B9 | Covered; use action rows, not separate escalation story. |
| 15 | productivity ledger | B1,B7,B11 | Covered; needs root action ID join. |
| 16 | fleet comms health | B7,B9,B11 | Covered; comms repair remains axis-local. |
| 17 | comms health ledger | B1,B11 | Covered; child ledger reference needed. |
| 18 | cross-orch coordination ledger | B10,B11,B12 | Covered; WOE row scoping must be consumed. |
| 19 | fleet conformance probe | B11,B14 | Covered; timebox so it cannot block recovery. |
| 20 | fleet process gap detector | B7,B11,B13 | Covered; structural bead filing is fallback, not recovery. |
| 21 | process gap state | B11,B13 | Covered; state should not be a second doctrine source. |
| 22 | fleet observatory aggregate | B1,B11,B14 | Covered; recommendation must become action or no-action row. |
| 23 | fleet watcher coverage probe | B16-B20 | Covered; propagation owns repair. |
| 24 | canonical rule freshness | B11,B13 | Input only; should not block recovery. |
| 25 | L-rule lag probe | B11,B13 | Input only; process debt not worker recovery. |
| 26 | Agent Mail identity registry | B25-B27 | Covered; token path only, no raw token. |
| 27 | identity history | B26,B27 | Covered; predecessor chain preservation needed. |
| 28 | orch-worker identity manifest | B25-B27 | Covered; dispatch identity should consume manifest. |
| 29 | NTM fleet health | B2,B11 | Covered; liveness cannot be single source of truth. |
| 30 | flywheel loop driver plists | B8,B11 | Covered; driver proof remains an input. |
| 31 | protected session recovery skill | B5,B6,B12 | Covered; evidence gate before mutation. |
| 32 | flywheel recovery skill | B5,B6 | Input only; cite as recovery fallback. |
| 33 | notify binary | B9 | Covered; notify only sparse classes. |
| 34 | halt disease watchdog | B7,B11,B12 | Covered; signal input, not action owner. |
| 35 | dispatch delivery receipt L91 | B1,B11,B13 | Covered; supervisor actions need receipts too. |

No critical orphan primitive was found, but the r1 plan needs this matrix or an
equivalent in Phase 4. The current source mapping is too coarse to prove
`25/25` adoption at closeout.

Required correction:

Add a Phase 4 table with one row per adopted primitive:

```text
primitive_id=
consumed_by_bead=
owner_surface=
action_or_no_action=
child_ledger_reference=
duplicate_avoidance_rule=
acceptance_gate=
```

## 8. CC-4 - Agent Mail Beads Need Post-Repair Reframe

Severity: medium.

Affected beads: B25-B27, B1, B11, B14.

Evidence:

1. r1 absorbed Agent Mail registration because three live panes had
   `needs_registration`.
2. The later resolver-fire tactical fix completed: `alpsinsurance:1`,
   `alpsinsurance:2`, and `vrtx:1` now resolve to active, ready identities with
   token paths present.
3. The identity doctor currently reports those three rows as active and ready:
   `YellowNorth`, `AmberCanyon`, and `AmberStone`.
4. Inactive historical rows still exist, but those are not the same as current
   live unresolved rows.

Why this matters:

B25-B27 are still valid, but their job changed. They should no longer read as
"repair today's live three rows." They should read as "prevent recurrence and
make future resolver fire safe, tokenless, and auditable."

Required correction:

Reframe B25-B27:

1. B25: broadcast close-loop requires recipients to transition to active,
   explicitly defer, or write a blocking receipt.
2. B26: live-vs-dead readiness gate distinguishes active topology rows from
   archived or inactive historical identities.
3. B27: repair CLI validates `identity_resolved`, `token_path`, and token
   fingerprint only; it never prints or transports raw tokens.

Acceptance gates:

1. Fixture with the three formerly unresolved rows passes.
2. Fixture with inactive historical rows does not fail live readiness.
3. Fixture with a missing token path on an active row fails.
4. Repair command emits before/after readiness counts and no secret material.

## 9. CC-5 - WOE Overlap Ownership Is Resolved, But Contract Fields Are Missing

Severity: medium.

Affected beads: B1, B5, B10, B11, B12, B13, B14, B16-B20, B25-B27.

Evidence:

1. WOE B1-B7 own ledger schema, writer, classifier, doctor fields, close gate,
   and shadow/enforce mode.
2. WOE B12 owns cross-orch fleet rollout and row scoping.
3. WOE B13 owns worker side-branch enforcement.
4. WOE B14 owns DCG orphan reset blocking.
5. WOE B15 owns substrate-loss memory and learn promotion.
6. r1 correctly says orch-monitor should consume these outputs and not recreate
   them.

Sibling overlap resolution:

| Overlap | Ownership verdict | Residual contract needed |
|---|---|---|
| Artifact ledger and close gate | Resolved: WOE owns; orch consumes. | B1 names exact WOE status fields consumed before recovery. |
| Cross-orch row scoping | Resolved: WOE B12 owns. | B10/B12 use row ownership to decide local halt vs fleet-visible debt. |
| Worker side branches | Resolved: WOE B13 owns. | B5/B12 read branch proof before recovery or merge-sensitive action. |
| DCG orphan reset blocker | Resolved: WOE B14 owns. | B5/B21-B24 respect guard outcome; no second reset rule. |
| Substrate-loss learn path | Resolved: WOE B15 owns. | B13 links supervision failures to WOE memory rows, not duplicate doctrine. |

Audit result:

```text
sibling_plan_overlap_resolved_count=5/5
```

The residual problem is not duplicate ownership. It is the lack of a field-level
contract in the orch-monitor bead acceptances.

Required correction:

B1 should include an explicit WOE consumption contract:

```text
wire_or_explain_fields_consumed=
  row_id,
  ship_repo,
  ship_actor,
  artifact_class,
  wired_status,
  defer_until,
  owning_orch,
  enforce_mode,
  side_branch_ref,
  substrate_loss_guard
```

B12 should add fault-injection cases where WOE rows are stale, ambiguous,
cross-repo, or owned by another orchestrator.

## 10. CC-6 - Peer-Orch Scope Needs One Decision Table

Severity: medium.

Affected beads: B5-B7, B9-B12, B16-B20, B25-B27.

Evidence:

1. INTENT is driven by peer failures: skillos frozen, ALPS phantom blocker,
   idle panes, and passive ledgers.
2. Lane A names `flywheel:1-itself-down`, protected sessions,
   identity-rotation-mid-flight, and cross-fleet failure storms.
3. Lane B shows many primitives that can act in one axis but no single
   class-to-action-to-owner table.
4. r1 has B10 as mesh failover claim flow, but the table of who can act on
   which peer state is not yet a first-class acceptance gate.

Why this matters:

Cross-orch recovery is high leverage and high risk. If ownership is too loose,
the system can over-act on another orchestrator's state. If ownership is too
tight, it repeats the current passive failure where everyone observes and no one
acts.

Required correction:

Add a decision table to B1 or B10:

```text
failure_class=
source_probe=
freshness_budget_seconds=
owner_orch=
allowed_action=
protected_gate=
claim_ttl_seconds=
notify_policy=
no_action_receipt=
reprobe_required=
```

Required fixtures: peer frozen owned locally, peer frozen protected with no
authorization, peer idle with stale dispatch, peer true blocker already
notified, peer row owned elsewhere, and fleet storm across three repos.

## 11. CC-7 - Canonical CLI Surface Is Underspecified

Severity: low.

Affected beads: B1, B8, B11, B14.

Lane C has a reasonable handler shape, and r1 names handler-first execution,
launchd safety, doctor fields, and action-visible status. The missing part is
operator-grade CLI scoping: fast `doctor`/`health`, explanatory `audit`/`why`,
schema `validate`, dry-run default mutation via `repair`/`apply`, `--json`, and
stable exit codes. Add a compact acceptance block to B1/B8/B11/B14.

## 12. TRUE Blocker Class Evaluation

Result: 6/6 evaluated, 0 triggered.

| # | TRUE blocker class | Triggered? | Rationale |
|---:|---|---|---|
| 1 | `new-platform-or-vendor-not-in-mission-lock` | no | The audit proposes no new platform or vendor. |
| 2 | `secret-rotation-or-new-credential-creation` | no | Agent Mail repair is token-path/fingerprint only; no new credential or rotation proposed. |
| 3 | `financial-commitment-above-mission-budget` | no | No paid resource or tier change proposed. |
| 4 | `legal-or-compliance-decision` | no | No ToS, DPA, legal, or compliance decision proposed. |
| 5 | `destructive-irreversible-on-shared-state` | no | Phase 4 recommendations are plan/bead edits; no irreversible shared-state mutation. |
| 6 | `paradigm-conflict-with-active-mission` | no | L110 extends the active paradigm; it does not contradict it. |

Pause decision:

```text
audit_disposition=auto_advance
true_blocker_classes_triggered=none
blocker_class_evaluations=6/6
notify_required=no
```

## 13. L110 Absorption Decision

L110 should be absorbed into this plan.

It should not become a detached standalone plan unless orch-monitor Phase 4
freezes or implementation proves the same substrate-loop contract gap in another
repo family.

Current state:

```text
L110_absorbed=no
```

Minimum acceptable Phase 4 state:

```text
L110_absorbed=yes
route=one_of:
  B28_added
  existing_beads_amended
substrate_loop_contract_validator=present
doctor_field=substrate_loop_contract_missing_count
status_line=present
fixtures_cover=watcher,beads_db,agentmail,observatory,woe
```

Do not mark L110 absorbed merely because B13 exists. B13 is a doctrine bead; L110
requires a mechanical contract or explicit gate amendments.

## 14. Cap Split Recommendation

Recommended Phase 4 structure:

```text
Plan A:
  name=orch-monitor-recovery-auto-act-core
  beads=B1-B15
  cap=15
  purpose=ship handler-first supervision loop

Plan B:
  name=orch-monitor-substrate-self-org-propagation
  beads=B16-B28 or amended fallback
  cap=13
  purpose=watcher propagation, Beads DB maintenance, Agent Mail recurrence, L110
  dependency=Plan A interfaces B1,B11,B13,B14
```

This preserves the plan's convergence while respecting dispatchability.

If the orchestrator keeps one plan, the Phase 4 artifact must explicitly record:

1. Why the cap is being waived.
2. Which beads are in each 3-5 bead wave.
3. Which beads can be delayed without breaking core supervision.
4. How WOE-owned surfaces remain owned by WOE.
5. How L110 is absorbed without creating a third observation-only artifact.

## 15. Cross-Plan Coordination Verdict

WOE overlap is resolved at ownership level.

`orch-monitor` should consume:

1. WOE ledger row IDs and status.
2. WOE row scoping.
3. WOE side-branch proof.
4. WOE DCG orphan reset guard result.
5. WOE substrate-loss memory/learn promotion rows.

`orch-monitor` should not create:

1. A second artifact ledger.
2. A second close gate.
3. A second side-branch policy.
4. A second DCG reset doctrine.
5. A second substrate-loss memory rule.

The Phase 4 bead DAG should make this explicit in dependencies and acceptance
gates, not only prose.

## 16. Required Phase 4 Edits

P0 edits:

1. Resolve cap before creating beads.
2. Add B28 or amend existing beads for L110.
3. Add WOE consumption fields to B1/B11/B12/B13.
4. Reframe B25-B27 as recurrence and regression prevention after resolver-fire.

P1 edits:

1. Add Lane B primitive-to-bead trace matrix.
2. Add peer-orch action-scope table and fixtures.
3. Add CLI contract block to B1/B8/B11/B14.

## 17. Final Callback Values

```text
DONE orchmon-audit-cross-cutting output=.flywheel/plans/orch-monitor-recovery-auto-act-2026-05-04/03-AUDIT-r1-cross-cutting.md self_grade=Y findings_total=7 findings_by_severity={critical:0,high:2,medium:4,low:1} composite_score=7.2 true_blocker_classes_triggered=none blocker_class_evaluations=6/6 cross_bead_findings_count=7 L110_absorbed=no cap_violation_risk=high sibling_plan_overlap_resolved_count=5/5 commits_total=0 callback_delivery_verified=true
```
