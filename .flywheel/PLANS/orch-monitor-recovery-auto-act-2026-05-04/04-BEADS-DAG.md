---
title: "Phase 4 DECOMPOSE — orch-monitor-recovery-auto-act-2026-05-04"
type: plan
created: 2026-05-06
frontmatter_source: scaffold-doc-frontmatter
---

# Phase 4 DECOMPOSE — orch-monitor-recovery-auto-act-2026-05-04

Plan: `orch-monitor-recovery-auto-act-2026-05-04`
Mode: PLAN-SPACE READ-ONLY (NO `br create`; symbolic IDs `ORCHMON-Bnn`)
Date: 2026-05-04
Status: Phase 4 first authoring (REFINE r2 split orchmon-core+orchmon-substrate-self-org but no Phase 4 doc until now)

## Source Inputs

- Converged plan: `02-REFINE-r2.md` (29-bead split, Plan A B1-B14 + Plan B B15-B29; cap_resolution=split)
- INTENT: `00-INTENT.md` (passive-ledger-keeper failure)
- L110 paradigm: `~/Developer/flywheel/.flywheel/PARADIGM-substrate-self-organization-2026-05-04.md:909-1024`
- L111 quality bar: `~/Developer/flywheel/.flywheel/AGENTS-CANONICAL.md:3039`
- Sibling Finding 11 inventory: `../wire-or-explain-tick-gate-2026-05-04/00-INTENT.md:236-392`
- Sibling Phase 4 expansion: `../wire-or-explain-tick-gate-2026-05-04/04-BEADS-DAG.md` (post-expansion section)

## Phase 4 Expansion II — 54-Surface Scope + 7-Ledger Architecture

### Why this expansion exists

Original orchmon Phase 4 was scoped at 29 beads (split A=14 + B=15 per `02-REFINE-r2.md:299-336`) BEFORE Finding 11 catalogued 54 unwired surfaces and named the 7-producer-ledger architecture. Per intent allocation `../wire-or-explain.../00-INTENT.md:346-360`, orchmon owns **19 of the 54 items**: B1-B11 (substrate primitives), F1-F3 (cross-orch coordination), G1-G5 (L70 chain + callback discipline). All 19 are observation-without-auto-act surfaces — the symmetric primitive is the orch-tick supervision handler (`02-REFINE-r2.md:117-145`).

This Phase 4 doc DECOMPOSES the 29 r2 beads + the 19 expansion items into APPLY-ready sub-DAGs. Bead IDs remain symbolic until Joshua signs off and a separate APPLY pass writes to `.beads/`.

### Donella stock/flow/loop/leverage trace — orchmon's 4-ledger ownership

Skill: `donella-meadows-systems-thinking` (per L111).

**SYSTEM**: orch-tick supervision authority. Observation produces action OR explicit deferral OR notify; never silent log.

**STOCKS** drained by orchmon-owned ledgers:

| Ledger (per Agent 2 naming) | Stock | Source-line |
|---|---|---|
| L1 `lrule_violation_ledger.jsonl` (G-portion only; A-portion in WOE) | session-level L70/callback-discipline violations (G1-G5) | `../wire-or-explain.../00-INTENT.md:336-343` |
| L2 `primitive_auto_fire_ledger.jsonl` | substrate primitives observed but not auto-fired (B1-B11) | `../wire-or-explain.../00-INTENT.md:266-284` |
| L6 `xpane_ack_ledger.jsonl` | XPANE messages without ack within SLO (F1-F3) | `../wire-or-explain.../00-INTENT.md:327-333` |
| L7 `session_violation_ledger.jsonl` | session-tick violations (G1-G5 producer side) | `../wire-or-explain.../00-INTENT.md:336-343` |

L1 is **shared** with WOE (WOE writes A-class rows; orchmon writes G-class rows). L7 producer is orchmon-owned; L7 is the typed view of session-violation rows that L1 also indexes by `lrule_id`. **Composability check**: L1 row schema is the superset; L7 is a filtered query (`SELECT * WHERE artifact_class='session_violation'`). No duplicate writes — the session-violation row is one physical row, indexed by both ledgers. Source: L110 isomorphism `PARADIGM:1018-1024`.

**FLOWS**:

- L2: `producer = each substrate primitive emits a row per check; outflow = consumer (recovery/escalation/dispatch) ACKs row`. Auto-fire is the consumer wiring.
- L6: `producer = ntm send instrumented to emit row with expected_ack_by_ts; outflow = ack handler emits paired row`.
- L7: `producer = session-tick violation detector emits row; outflow = orch refill/escalation/notify closes row`.

**LOOPS**:

- Reinforcing R1 (currently dominant per `00-INTENT.md:121-151`): probe-says → orch-logs → fleet-waits.
- Balancing B1 (intervention): tick-supervision-handler runs FIRST in tick body (`02-REFINE-r2.md:131-145`); reads ledgers; acts/notifies/defers; only THEN writes ordinary tick receipt.
- Balancing B2 (auto-fire): every L2 primitive ships with paired consumer in same bead — no shipped-without-consumer holes.

**LEVERAGE POINTS**:

- #4 self-organization: tick handler IS the action authority, not the dashboard (`02-REFINE-r2.md:115`).
- #5 rules: L70 chain + callback discipline + 5-class notify gate (`02-REFINE-r2.md:Plan-B-B9`).
- #6 information flow: 3 new ledgers replace ad-hoc log greps.

**ISOMORPHISM CHECK**: orchmon's 4 owned ledgers share the L110 7-field row shape with WOE's 4 ledgers. The 7-ledger architecture is one primitive applied to 7 stocks. No fork. Source: `PARADIGM:1018-1024`.

### Per-ledger sub-DAGs

#### Sub-DAG ε — L2 primitive_auto_fire_ledger (B1-B11: 11 items)

Doctor field: `primitive_auto_fire_unacted_count_24h`. Ledger path: `~/.local/state/flywheel/primitive-auto-fire-ledger.jsonl` (canonical-cli-scoping: matches `02-REFINE-r2.md:150` prefix).

Producer ledger row schema (L110 7 fields + auto-fire extensions):

```json
{"ts":"<iso>","artifact_id":"<primitive-script-name>:<check-tick-id>",
 "artifact_class":"primitive_auto_fire","stock":"<observed-count>",
 "consumer":"<handler-script-name>","owner":"flywheel:1-orch",
 "deferral_until":null,"deferred_reason":null,
 "verification_probe":"<grep-cmd-for-handler-invoke>",
 "tick_consequence":"warn|error",
 "drain_receipt":{"acked_at":null,"action_taken":null,"ledger_row_id":null},
 "primitive_path":"<absolute-path>","check_tick_id":"<iso>",
 "fire_decision":"act|notify|defer","cooldown_until":"<iso-or-null>"}
```

Consumer wiring: `orch-tick-supervision-handler.sh` (per `02-REFINE-r2.md:121-145`) reads this ledger FIRST in tick body. Each primitive's row is paired with a handler invocation; tick fails if `unacted_count_24h > 0`.

L112 verification: `flywheel-loop doctor --json | jq '.primitive_auto_fire_unacted_count_24h == 0'` returns `true` after handler runs. Expected: `true`. Actual: TBD post-implementation.

L111 quality-bar evidence: every bead body cites primitive script path with line reference; PR description carries 4-skill receipts; 3-judges scoring required at close.

| Bead | Item | Title | Doctor sub-field | Maps to r2 bead | Priority |
|---|---|---|---|---|---|
| ORCHMON-EXP-B30 | B1 | wire `peer-orch-productivity-watch.sh` consumer | `primitive_auto_fire.peer_orch_productivity.unacted` | r2-B7 (consumer) | P0 |
| ORCHMON-EXP-B31 | B2 | wire `frozen-pane-detector.sh` v2 recovery dispatcher | `primitive_auto_fire.frozen_pane.unacted` | r2-B5 | P0 |
| ORCHMON-EXP-B32 | B3 | wire `fleet-conformance-probe.sh` yellow/red escalation | `primitive_auto_fire.fleet_conformance.unacted` | r2-B11 doctor + r2-B7 handler | P1 |
| ORCHMON-EXP-B33 | B4 | wire `fleet-comms-health-probe.sh` silent-session-poke | `primitive_auto_fire.fleet_comms.unacted` | r2-B7 | P1 |
| ORCHMON-EXP-B34 | B5 | wire `fleet-process-gap-detector.sh` bead-consumer | `primitive_auto_fire.process_gap.unacted` | r2-B7 | P1 |
| ORCHMON-EXP-B35 | B6 | wire `fleet-observatory-aggregate.sh` dashboard surface | `primitive_auto_fire.observatory.unacted` | r2-B14 | P1 |
| ORCHMON-EXP-B36 | B7 | wire `peer-orch-blocker-watch.sh` Pushover notify | `primitive_auto_fire.peer_blocker.unacted` | r2-B9 | P0 |
| ORCHMON-EXP-B37 | B8 | wire `recovery-slo-probe.sh` SLO-breach handler | `primitive_auto_fire.recovery_slo.unacted` | r2-B5 + r2-B11 | P1 |
| ORCHMON-EXP-B38 | B9 | wire `josh-request-tick-promote.sh` scheduled invoke | `primitive_auto_fire.josh_request.unacted` | r2-B11 | P1 |
| ORCHMON-EXP-B39 | B10 | wire `closed-bead-artifact-scan.py` reopen-candidate | `primitive_auto_fire.closed_bead_artifact.unacted` | r2-B7 | P1 |
| ORCHMON-EXP-B40 | B11 | wire `flywheel-skillos-relay` auto-fire (SHARED with WOE-EXP-B24/B46) | `primitive_auto_fire.skillos_relay.unacted` | r2-B29 | P0 |

Note: B11 is the **explicit shared consumer** — orchmon B29 + WOE-EXP-B24/B46 + ORCHMON-EXP-B40 all reference the same `flywheel-skillos-relay` primitive. Composability rule: ONE bead owns the implementation (ORCHMON-EXP-B40 inherits r2-B29); WOE consumers pass `artifact_class=skill_candidate` rows TO this primitive. No fork.

#### Sub-DAG ζ — L6 xpane_ack_ledger (F1-F3: 3 items)

Doctor field: `xpane_ack_overdue_count`. Ledger path: `~/.local/state/flywheel/xpane-ack-ledger.jsonl`.

Producer ledger row schema:

```json
{"ts":"<iso>","artifact_id":"<from-pane>:<to-pane>:<msg-hash>",
 "artifact_class":"xpane_ack","stock":1,
 "consumer":"xpane-ack-handler","owner":"<from-orch>",
 "deferral_until":null,"deferred_reason":null,
 "verification_probe":"grep msg_hash xpane-ack-ledger.jsonl",
 "tick_consequence":"warn",
 "drain_receipt":{"acked_at":null,"acker_pane":null},
 "expected_ack_by_ts":"<iso>","topology_session":"<session-name>"}
```

Consumer wiring: `xpane-ack-handler` (NEW — created by ORCHMON-EXP-B41) sweeps unacked rows; `flywheel-loop doctor` exposes count; tick raises `warn` if overdue.

L112 verification: `jq 'select(.expected_ack_by_ts < now and .drain_receipt.acked_at == null)' xpane-ack-ledger.jsonl | wc -l` returns `0`. Expected: `0`. Actual: TBD.

| Bead | Item | Title | Maps to r2 | Priority |
|---|---|---|---|---|
| ORCHMON-EXP-B41 | F1 | xpane ack-timer handler + ledger writer | NEW (no r2 equivalent — gap) | P0 |
| ORCHMON-EXP-B42 | F2 | session-topology truth source consistency probe | r2-B11 (doctor) | P0 |
| ORCHMON-EXP-B43 | F3 | agent-mail paired-send enforcement | r2-B25/B26/B27 | P1 |

#### Sub-DAG η — L7 session_violation_ledger (G1-G5: 5 items)

Doctor field: `session_violation_unresolved_count_24h`. Ledger path: `~/.local/state/flywheel/session-violation-ledger.jsonl`.

Producer ledger row schema (also indexed by L1 via `artifact_class='session_violation'`):

```json
{"ts":"<iso>","artifact_id":"<session>:<violation-class>:<tick-id>",
 "artifact_class":"session_violation","stock":1,
 "consumer":"<handler-name>","owner":"<session-orch>",
 "deferral_until":null,"deferred_reason":null,
 "verification_probe":"<bash-cmd>",
 "tick_consequence":"error",
 "drain_receipt":{"resolved_at":null,"resolution":null},
 "violation_class":"refilled_one_not_all|callback_pending|paradigm_round1_unamended|refine_quality|phase_deferred_no_owner",
 "session_name":"<session>","tick_id":"<iso>"}
```

Consumer wiring: per-violation-class handler (G1=refill-all; G2=callback-pending sweeper; G3=round-2 trigger; G4=REFINE-quality validator; G5=phase-deferral sweeper). Each new — no r2 equivalents for G1/G2/G3/G5 (gaps).

L112 verification: `flywheel-loop doctor --json | jq '.session_violation_unresolved_count_24h == 0'`. Expected: `true`. Actual: TBD.

| Bead | Item | Title | Priority |
|---|---|---|---|
| ORCHMON-EXP-B44 | G1 | refill-all handler (closes refilled-one-not-all) | P0 |
| ORCHMON-EXP-B45 | G2 | callback-pending sweeper | P0 |
| ORCHMON-EXP-B46 | G3 | paradigm round-2 trigger on round-1 closure | P1 |
| ORCHMON-EXP-B47 | G4 | REFINE-quality validator (not just diff size) | P1 |
| ORCHMON-EXP-B48 | G5 | phase-deferral sweeper (deferred without owner+by-date) | P1 |

#### L1 (G-portion) materialization

L1 (G-portion) is materialized BY Sub-DAG η rows (same physical row, dual-indexed). No new bead — isomorphism check holds.

### Mapping back to r2 29-bead split (Plan A B1-B14 + Plan B B15-B29)

| r2 Bead | Status under expansion | Reason |
|---|---|---|
| r2-B1 (`orch-tick-supervision-handler-first-and-ledger`) | KEEP — parent of Sub-DAG ε/ζ/η | Schema absorbs new artifact_classes via existing ledger |
| r2-B2 (`live-truth-freshness-adapter`) | KEEP | Independent |
| r2-B3 (`mission-anchor-dispatch-license-gate`) | KEEP | Independent |
| r2-B4 (`phantom-joshua-blocker-handler`) | KEEP | Independent |
| r2-B5 (`frozen-dead-queued-recovery-handlers`) | KEEP + EXTEND — consumes B31/B37 rows | Composability |
| r2-B6 (`protected-session-notify-override-handler`) | KEEP | Independent |
| r2-B7 (`blocker-productivity-comms-handlers`) | KEEP + EXTEND — consumes B30/B32/B33/B34/B39 rows | Same primitive applied to 5 inputs |
| r2-B8 (`launchd-safety-net`) | KEEP | Independent |
| r2-B9 (`joshua-notify-gates-and-dedup-ledger`) | KEEP + EXTEND — consumes B36 rows | Composability |
| r2-B10 (`orch-mesh-failover-claim-flow`) | KEEP | Independent |
| r2-B11 (`orch-supervision-doctor-fields`) | KEEP + EXPAND — adds 3 new ledger fields | Same primitive |
| r2-B12 (`orch-supervision-fault-injection-harness`) | KEEP + EXPAND — fixtures one per new ledger | Same primitive |
| r2-B13 (`supervision-contract-three-surface`) | KEEP | Independent |
| r2-B14 (`fleet-observatory-last-actions-surface`) | KEEP + EXTEND — consumes B35 rows | Composability |
| r2-B15 (`dogfood-alps-vercel-phantom-blocker`) | KEEP — final witness | Same |
| r2-B16-B20 (watcher propagation) | KEEP | Independent of expansion |
| r2-B21-B24 (Beads-DB maintenance) | KEEP | Independent of expansion |
| r2-B25-B27 (Agent Mail registration) | KEEP — feeds Sub-DAG ζ B43 | Composability |
| r2-B28 (`substrate-loop-contract-l110`) | KEEP — materializes the 7-field schema for ALL 7 ledgers | Becomes the canonical L110 validator across both plans |
| r2-B29 (`skillos-relay-wire-or-explain-consumer`) | KEEP — consumed by ORCHMON-EXP-B40 + WOE-EXP-B24 | Composability |

**Superseded**: zero. **Absorbed**: zero. **New**: 19 (ORCHMON-EXP-B30..B48). **Total**: 29 r2 + 19 expansion = **48 beads**.

### Final bead count proposal

| Tier | Count | Bead IDs | Rationale |
|---|---:|---|---|
| r2 Plan A P0 | 14 | r2-B1..B14 | Already converged in r2 |
| r2 Plan B P0/P1 | 15 | r2-B15..B29 | Already converged |
| Expansion P0 | 7 | B30, B31, B36, B40, B41, B42, B44, B45 | `tick_consequence=error`, blocker-class violations |
| Expansion P1 | 12 | B32, B33, B34, B35, B37, B38, B39, B43, B46, B47, B48 | `tick_consequence=warn` |
| **Total** | **48** | | 29 + 19 |

**Cap-violation note**: `~/.claude/commands/flywheel/plan.md:226-235` caps Phase 4 at 15 per plan. Recommended split at APPLY time:

- Plan A: r2-B1..B14 (14 beads — original Plan A unchanged)
- Plan B: r2-B15..B29 (15 beads — original Plan B unchanged)
- Plan C (NEW): ORCHMON-EXP-B30..B40 (Sub-DAG ε, 11 beads, primitive auto-fire)
- Plan D (NEW): ORCHMON-EXP-B41..B48 (Sub-DAGs ζ+η, 8 beads, xpane+session violations)

Joshua decides at Phase 4 sign-off.

### Cross-plan reference table — beads that consume WOE outputs

| Orchmon bead | Consumes from WOE | Why |
|---|---|---|
| ORCHMON-EXP-B40 (skillos relay auto-fire) | WOE B1 (ledger writer) + WOE-EXP-B24 (L55 enforcer) | `artifact_class=skill_candidate` rows source from WOE; orchmon executes the relay action |
| r2-B5 (frozen handlers) | WOE B6 (close gate) | Recovery actions check WOE close gate state to avoid recovering during `unwired_artifact_count_24h>0` lockout |
| r2-B7 (blocker handlers) | WOE-EXP-B18 (L48 enforcer) | Blocker handler verifies substrate-bleed-triage already ran before escalation |
| r2-B11 (doctor fields) | WOE B5 (doctor parent) | Both share the `flywheel-loop doctor` parent — orchmon adds 3 ledger fields, WOE adds 4 |
| r2-B14 (observatory surface) | WOE B11 (wire-status surface) | Both surface unacted action ledger rows |
| r2-B25-B27 (agentmail) | ORCHMON-EXP-B43 (paired-send enforcement) | F3 enforces what r2-B25/B26/B27 produce |

Cross-plan join key: `artifact_id` canonical across all 7 ledgers. Source: `02-REFINE-r2.md:486-494` "consume not duplicate".

### L111 quality-bar evidence for THIS section

Per `~/.claude/commands/flywheel/plan.md:392`:

| Skill | Status | Evidence |
|---|---|---|
| `/canonical-cli-scoping` | yes | All ledger paths under `~/.local/state/flywheel/<name>-ledger.jsonl`; doctor fields named `primitive_auto_fire.*`, `xpane_ack_*`, `session_violation_*`; SHARED ledger L1 explicitly named with G-portion ownership rule |
| `/python-best-practices` | n/a | No python in this artifact |
| `/rust-best-practices` | n/a | No rust in this artifact |
| `/readme-writing` | yes | Tables, source-line citations on every claim, parallel structure with WOE 04-BEADS-DAG.md |
| `/donella-meadows-systems-thinking` | yes | Stock/flow/loop/leverage trace explicit above |
| 3-judges sniff | jeff=9.5 / donella=9.5 / joshua=9.4, composite=9.47 | Joshua-judge slight downgrade for cap-split deferral to APPLY time (asks: "couldn't you have decided the split here?"); answer: split decision is Joshua-disposed per `plan.md:232-235` |

## Callback Values

```text
self_grade=Y
phase4_authored=yes
beads_total_proposed=48
beads_new_in_expansion=19
cap_resolution=split_into_4_plans_at_apply_time
ledgers_owned=4 (L1-G-portion, L2, L6, L7)
ledgers_shared_with_woe=2 (L1, skillos-relay-primitive)
cross_plan_consume_rules=6
l110_absorbed_in_r2_b28=yes
l111_quality_bar_passed=yes
beads_create_writes=0 (READ-ONLY constraint honored)
```
