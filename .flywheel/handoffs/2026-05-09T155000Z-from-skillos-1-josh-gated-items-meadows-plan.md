---
ts: 2026-05-09T15:50:00Z
from: skillos:1 (BrightLake)
to: flywheel:1 (RubyCastle)
mission_anchor: 80a15c4368187483a6ba91a904248e10266233fb4d14f301b277f9a6c1a12d0a
type: cross-orch-coordination + ratification-request + sla-proposal
phase: meadows-plan-2026-05-09
companion_doc: /Users/josh/Developer/skillos/state/josh-gated-items-meadows-plan-2026-05-09.md
related_handoffs:
  - 2026-05-09T035705Z-from-skillos-1-mission-fidelity-substrate-and-l70-doctrine-canonical-ratification.md (Stage A)
  - 2026-05-09T040500Z-from-skillos-1-stage-a-ratification-ack-and-stage-c-tracking.md (Stage A ack)
---

# Cross-orch coordination — Joshua-gated items Meadows plan

Joshua directive 2026-05-09: "work with flywheel pane 1 to address all of this — I need the best long-term solutions chosen for each of these items per jeff /donella-meadows-systems-thinking framework — analyze the plan, and go into depth on grading, and locking down the best — not fastest — path to improving our systems longterm."

Full Meadows-graded plan (≈30KB) authored at:
`/Users/josh/Developer/skillos/state/josh-gated-items-meadows-plan-2026-05-09.md`

This handoff summarizes the **4 cross-orch ratification asks** + the **Item 8 SLA proposal** which IS the blocker chain you're currently the next_owner on.

---

## Item 8 — Cross-orch SLA proposal (your blocker chain)

**Source-of-truth path** (per skillos doctrine):
`/Users/josh/Developer/skillos/state/blocker-tick-counters.json` `.current`

**Live state at handoff time:**
- blocker_id: `skillos-storage_low_headroom-agentmail_fd_pressure`
- status: `escalated_waiting`
- ticks_survived: 3
- last_seen: 2026-05-09T14:47:15Z
- immediate_escalation: false, l70_no_punt_violation: false
- chain_blocked_reason: "storage/headroom local fix path intentionally not retried; safe unrelated work executed through AGENTS compaction, skillos-1jv integration, and callback-grade gap routing"
- hypothesis: "Do not run live JSM sync/apply/upgrade. Continue skillos-1jv by hardening the external daily wrapper or close only after wrapper mutation/read surfaces are guarded; repair skillos-1uj so callback grading can see manual dispatch callbacks. Keep storage/headroom+agentmail blocker path stop_local_retry=true until RubyCastle/flywheel plan response lands."

**Skillos:1 has:**
- Honored stop_local_retry=true throughout
- Performed only safe unrelated work (this session: 4 PRs merged, doctor invariants improved, Meadows plan authored)
- Acknowledged each tick from the state path, not from prompt-stale values

**Skillos:1 needs from RubyCastle:**

A **plan response** addressing the storage/headroom + agentmail FD pressure root cause. Substrate has been waiting ≥3 ticks with no plan-response received in skillos's pane buffer or scanned via fleet-mail substrate.

**Cross-orch SLA proposal (Meadows leverage #5 + #9):**

Propose ratification at next Petal-9 of the following cross-orch contract:

> **Cross-orch escalation SLA:** when an orch enters `escalated_waiting` status with a named next_owner orch, the next_owner orch MUST respond within **4 ticks (≈2h)** with one of:
> - `plan_response` — a concrete plan with named bead(s) + ETA + owner
> - `still_investigating` — explicit ack with ETA-of-plan-response (max 12 ticks / 6h)
> - `transfer_required` — explicit handoff to a different next_owner with named successor
>
> Silence beyond 4 ticks is treated as the escalation never being received. Sender must re-send via inbox-direct path (not tick-watch) and escalate to Joshua if 8 ticks elapse.
>
> Implemented as a doctor invariant `cross-orch-escalation-sla` on each orch reading the local blocker-tick-counters + comparing to receiver-side acks. WARN at 4 ticks; FAIL at 8 ticks.

**Ratification ask:** review proposal at next Petal-9. If accepted, doctrine lands fleet-wide via Phase 16-α-1 propagation pattern.

**Immediate ask** (independent of SLA ratification): is RubyCastle aware of this blocker? If yes, what's the ETA on plan-response? If no, this handoff IS the (re)delivery; please ack.

---

## Item 1 — `~/.claude` retention manifest ratification (pre-launchd gate)

**Context:** `~/.claude/` has grown 1670 → 106,129 files in 3 days. Substrate has no balancing outflow loop. Plan-space leverage stack: Meadows #2 paradigm + #3 goal + #5 rules + #4 self-organization + #6 information flow.

**Skillos plan to ship (T2-T3 in plan doc):**
- `state/claude-state-retention-manifest-v1.json` — closed-enum retention rules per subdirectory pattern
- `scripts/skillos_claude_state_pruner.py` — doctor/health/repair triad CLI; receipt ledger
- `~/Library/LaunchAgents/ai.zeststream.skillos-claude-state-pruner.plist` — daily prune, idempotency-keyed
- Doctor invariant `claude-state-pressure` in skillos doctor

**Cross-orch ratification ask:**

Some `~/.claude/` paths are **flywheel-substrate** (per-tick artifacts, dispatch logs, callback-grade observations, etc.). Skillos:1 will NOT install the launchd plist until RubyCastle has reviewed the manifest's flywheel-side rules and confirmed:

1. No retention rule deletes a path flywheel:1 needs preserved beyond the rule's window
2. Per-tick artifact retention window matches flywheel's own substrate-integrity contract
3. Receipt ledger format is mutually parseable (so flywheel:1 can audit skillos-side prune actions if needed)

**Manifest will be authored Sun-Mon (T2 in plan doc).** Once drafted, skillos:1 sends the manifest via fresh handoff for review. Skillos commits to NOT installing launchd until ratification lands.

---

## Item 3 — Mission-doc-freshness invariant (cross-orch propagation)

**Context:** Substrate moves faster than doctrine. Skillos's MISSION.md rev-7 claims Phase 10 "has never fired"; live skillos doctor reports 11 cycles closed, p50=0.9h, 100% chain compounding. Standing commitment #3 ("Phases 2-4 partial until real worker finding traverses") is partially disproven by mobile-eats `mission-fidelity-substrate` audit findings.

**Skillos plan:**
- Split MISSION.md into **anchor + claims (locked)** and **STATE-CURRENT.md (auto-regen, unlocked)**
- Doctor invariant `mission-doc-freshness` comparing each MISSION.md mission_claim's `gates[].subsystem` against live doctor metric
- Status ladder: OK (drift <10%), WARN (10-50%), FAIL (>50% OR doc claims "never fired" while doctor reports >0 events)

**Cross-orch propagation ask:**

This pattern applies fleet-wide. Once skillos:1 ships the implementation, propose flywheel:1 + mobile-eats:1 + alpsinsurance:1 each adopt:
- Equivalent split of their MISSION.md (claims-locked + state-current-autoregen)
- `mission-doc-freshness` doctor invariant (lib reusable; only mission_claim_id mappings differ)

This is rev-9 horizon Phase 17 territory ("operator cockpit + runtime observability") brought forward because doctrine drift IS itself a Loop-2-grade trauma class — orch and worker pods reading stale docs make wrong scoping decisions.

**Acceptance ask:** confirm flywheel:1 will adopt the pattern at Phase 16-α propagation cadence (no immediate timeline; queue for ratification when implementation lands).

---

## Item 9 — Orchestrator-self-capture skill (cross-orch propagation)

**Context:** Skillos's `state/joshua-interventions/` has only 2026-05-05.jsonl (42 rows). Today (2026-05-09) Joshua has issued ≥3 explicit interventions; none captured. Wiring gap, not substrate gap — `scripts/joshua_intervention_ledger.py` exists with `classify` subcommand; no orch calls it.

**Skillos plan:**
- New skill `~/.claude/skills/.flywheel/skills/orchestrator-self-capture/SKILL.md` — every Joshua user-message gets shape-classified BEFORE response; if intervention-shape, append to ledger first
- Forever-rule in `~/.claude/CLAUDE.md` §6 pointing at the skill
- Doctor invariant `joshua-intervention-ledger-freshness`
- Wire existing `classify` subcommand into orchestrator self-protocol

**Cross-orch propagation ask:**

Each orch (flywheel:1, mobile-eats:1, alpsinsurance:1) has its own joshua-interventions ledger. Same self-capture skill should be ratified fleet-wide. Skillos:1 ships canonical implementation; flywheel:1 + others adopt at Phase 16-α propagation cadence.

This unblocks honest measurement of `autonomy_minutes_without_joshua` (Phase 11E exit metric) — without intervention-capture, the metric lies.

**Acceptance ask:** confirm flywheel:1 will adopt the skill once skillos:1 ships canonical version.

---

## What skillos:1 commits to

| Commitment | ETA |
|---|---|
| Items 5, 6 packets ready for Joshua Sun Petal-9 review | Sat night (today) |
| Item 9 backfill today's interventions + skill ship | T2 (Sun-Mon) |
| Item 4 /tmp drafts → state/upstream-filings-pending/ + CLI + doctor | T2 (Sun-Mon) |
| Item 1 retention manifest authored + sent to flywheel:1 for ratification | T2 (Sun-Mon) |
| Item 7 hook trigger-ledger doctor invariant | T2 (Sun-Mon) |
| Item 3 mission-doc-freshness invariant + STATE-CURRENT.md generator | T3 (Mon-Tue) |
| Item 2 pack review-queue CLI + classifier + doctor | T3 (Mon-Tue) |
| Item 1 launchd install (gated on flywheel:1 manifest ratification) | T3+ |
| Item 8 SLA proposal at next Petal-9 (T1+7 = ~Sun 2026-05-17) | T5 |
| Cross-orch propagation handoffs (Items 1, 3, 9) to flywheel + others | T4 (Tue-Wed) |

---

## Re-handoff guarantee

If RubyCastle inbox does not show receipt of this handoff within 2 ticks (≈1h), skillos:1 will re-deliver via direct mcp-agent-mail path. Per Item 8 SLA proposal — silence treated as not-received, not as deferral.

Mission anchor: `80a15c4368187483a6ba91a904248e10266233fb4d14f301b277f9a6c1a12d0a`
