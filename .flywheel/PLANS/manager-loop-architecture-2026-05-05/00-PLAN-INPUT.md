---
title: "00-PLAN-INPUT — Manager-Loop Architecture for Orchestrators"
type: plan
created: 2026-05-06
frontmatter_source: scaffold-doc-frontmatter
---

# 00-PLAN-INPUT — Manager-Loop Architecture for Orchestrators

**Date:** 2026-05-05
**Author:** flywheel:1 (RubyCastle/LavenderGlen) + Joshua paradigm input
**Status:** plan-space; pre-review; 3-lane multi-lens about to dispatch
**Predecessor:** `fleet-autonomy-v1-2026-05-05` (P1-P6 + M; under integrate-revisions hold)
**Reframes:** that plan's framing of orchestrator-as-callback-recipient

---

## 1. Why this plan exists

Today's 8h overnight run produced 2 bead closures across 4 repos despite 107 dispatches. The Donella lane reviewing the fleet-autonomy plan named the **invisible structural element**: the orchestrator is a **conversational agent inside the message bus**, not a **manager above it**.

Every callback (60+ overnight) contended for the same context window the orchestrator needed to *think* with. The orch's working set was forced to be "what message just arrived?" — not "what is the highest-leverage thing to do next?" That's how I (orch pane 1) ended up logging 11 same-bead redispatches as "interesting noise" — the noise WAS the input stream.

This plan inverts that.

## 2. Hard evidence (where the current architecture fails)

| Symptom | Cause | Evidence |
|---|---|---|
| 60+ callback messages logged as success signals overnight | Orch reads pane-message stream, not aggregate | dispatch-log + agentmail review (this morning) |
| 778 unprocessed fuckup-log rows in 24h | Orch never aggregates the log; just reads top-of-stack | doctor JSON `fuckup_triage.candidates` |
| Watcher cycles 107×, 2 closures | Orch can't see the cycle pattern in real-time, only individual events | dispatch-log replay |
| 4 frozen panes recovered only after Joshua woke | No one was reading the aggregate freshness signal | session-topology + freeze-detector logs |
| Validator-split-brain (worker SAFE_TO_CLOSE vs integrator BLOCK_CLOSE) | Two readers, two streams, no shared canonical log | mobile-eats:1 cross-orch input 2026-05-05T15:45Z |
| skillos manual callback grading impossible | Orch + grader read different surfaces | skillos:1 cross-orch input 2026-05-05T15:25Z |
| Joshua interventions ≥3/day | Real top-10 leverage list lives in Joshua's head, not in substrate | this morning's session arc |

## 3. The paradigm shift

**Current (broken):**
```
Workers ──xpane callback──> Orch pane (1) ──reads stream──> decisions
                                  ↑
                          context drowns in messages
```

**Proposed (manager loop):**
```
Workers ──append──> ops-log.jsonl (canonical)
                          │
                          ├──> Orch tick (every N min)
                          │       reads last delta
                          │       computes top-10 leverage queue
                          │       emits ONE decision
                          │
                          └──> Joshua tick (manual or scheduled)
                                  reads same surface
                                  reviews orch's verdict
```

The orchestrator is no longer a recipient. The pane is for **running** the manager loop, not for receiving messages.

## 4. The 4 atomic primitives

Each of these is small, atomic, and reversible. None depends on the others to be useful — but composed they replace the conversational-orchestrator paradigm.

### M1 — Canonical ops-log (writer side)

**What:** Single append-only JSONL at `~/.local/state/flywheel/ops-log.jsonl` (or per-session variant). Workers, watchers, validators, doctor, integrator all append rows — no other channel for orchestrator-visible signals.

**Schema (minimum):**
```json
{
  "ts": "<iso-8601>",
  "writer": "<role:session:pane>",      // e.g. "worker:flywheel:3", "watcher:flywheel:0", "doctor:flywheel"
  "event": "dispatched|started|done|blocked|reserved|released|fuckup|gap_found|closure|callback_invalid",
  "task_id": "<id-or-null>",
  "bead_id": "<id-or-null>",
  "stock_delta": {"closures": 0, "dispatches": 1, "fuckups": 0},
  "evidence_path": "<absolute-or-null>",
  "trauma_class": "<class-or-null>",
  "details": "<≤200char freeform>"
}
```

**Constraints:**
- Atomic-write (temp + fsync + os.replace) per row.
- ≤200 char `details` to prevent log-bombing.
- `stock_delta` is the only place a writer asserts impact; orch uses it for tick-aggregate.
- Schema versioned (`schema_version: 1` on first row of each session).

**What it kills:** xpane callbacks as orchestrator input. Workers stop sending `ntm send` callbacks.

### M2 — Tick-driven orchestrator loop

**What:** Orch pane runs a single fixed loop:
```
while True:
    delta = read_ops_log(since=last_tick_ts)
    top_10 = compute_leverage_queue(delta, current_state)
    decision = decide_one(top_10)        # one action per tick
    execute(decision)                     # dispatch | wait | escalate | close
    write_tick_summary(top_10, decision)  # to ops-log AND to morning-ritual artifact
    sleep(tick_interval)                  # default 600s; configurable
```

**Constraints:**
- Tick interval bounded [60s, 1800s]. Default 600s.
- One decision per tick. If 5 things look urgent, the next 4 wait for the next tick. (Forces stock-level prioritization, not whack-a-mole.)
- Tick summary is the canonical "what did the orch do this tick" surface — replaces orch chat history as evidence.

**What it kills:** the conversational-orchestrator paradox. Orch reads aggregates, not messages.

### M3 — Top-10 leverage queue

**What:** A computed list, refreshed each tick, of the 10 highest-leverage actionable items across the fleet.

**Inputs (all read from canonical surfaces, not chat):**
- `bv --robot-next` per repo (PageRank-aware ready bead)
- In-flight dispatches with age > expected_delivery (escalation candidates)
- Recent fuckup-log promotion candidates (from `flywheel-loop doctor --json`)
- Cross-orch reservations expiring soon (from agent-mail or shared registry)
- Audit gaps from `closed_bead_audit_gap_count`
- Joshua-requests open + stale (from josh-requests.jsonl)

**Output (each item):** `{rank, kind, id, leverage_score, blocker_class, suggested_action, evidence_path}`

**Scoring:** documented and tunable. Donella-mode default = stock-impact * urgency / cost. Jeff-mode default = PageRank * unblocks / age. Multi-model can blend.

**What it kills:** the "newest message wins" failure. Stock + leverage rules the queue.

### M4 — Joshua-readable shared surface

**What:** The same top-10 queue + tick summary that the orch reads is rendered to a stable file path. Joshua's morning ritual = open one file, see what the orch has been doing and what the queue looks like RIGHT NOW.

**Path:** `~/.local/state/flywheel/manager-loop-state.md` (Markdown, atomic-rewritten each tick) + `~/.local/state/flywheel/manager-loop-state.json` (machine-readable mirror).

**Sections:**
- Current top-10 queue (rank + leverage + suggested_action)
- Last tick decision + rationale + evidence
- Last 5 ticks summary (dispatches / closures / fuckups / Joshua-interventions)
- Current verdict: HEALTHY / DEGRADED / BROKEN (auto-computed thresholds)
- Pending Joshua decisions (true blocker classes only)

**What it kills:** the morning ritual being a separate primitive. It IS the manager loop's output.

## 5. Donella lens applied (orchestrator-self-review)

| Leverage point | How this plan applies |
|---|---|
| #3 system goal | Orch's goal stops being "answer messages" and becomes "maintain top-10 leverage queue." Direct goal-shift. |
| #4 self-organization | Top-10 re-ranks from data each tick. No human or message-position bias. |
| #5 rules | New rule: "callbacks go to ops-log, not orch pane." Replaces "callbacks bombard orch." |
| #6 information flow | One canonical source (ops-log) replaces N pane-message streams. |
| #9 parameters | Tick interval + top-10 size + scoring weights. Tunable but secondary. |

This plan is primarily a #5 (rules) + #6 (information flow) intervention, with consequential #3 (goal) and #4 (self-organization) effects. By Donella's hierarchy this is much higher leverage than the fleet-autonomy-v1 P1-P6 set, which is mostly #6 with some #9.

## 6. Jeff lens applied (canonical-cli-scoping pre-check)

The plan must respect Jeff's discipline:

- **Canonical primitive ownership:** `bv` already does PageRank ranking. `br` already does dependency state. agent-mail already does reservations. The manager loop **composes** these — does not replicate them.
- **Robot mode:** the top-10 queue MUST be exposed as a robot-mode JSON surface (e.g. `flywheel-loop manager-state --json` or similar) so peer orchs / agents can consume it without scraping markdown.
- **Doctor/health/repair triad:** the manager loop needs `manager-loop doctor`, `manager-loop health`, `manager-loop repair` to enter the canonical-cli-scoping standard.
- **Atomic write contract:** every ops-log append goes through `fw_jsonl_append_validated` (already exists in our substrate per accretive-cron-orchestration doctrine).
- **Working sibling first:** there's already a manager-loop-shaped sibling — it's the morning ritual artifact spec from fleet-autonomy-v1's M primitive. Diff against it before authoring fresh.

## 7. Relationship to fleet-autonomy-v1

This plan **reframes** fleet-autonomy-v1's premise. The reviews stand, but their integrate-revisions phase MUST happen *after* this plan converges:

- **fleet-autonomy P1 (bv-replacement)** — still valid; becomes one input to M3's queue, not the watcher's only source of truth.
- **fleet-autonomy P2 (same-bead skip)** — folds into ops-log writer-side: writers MUST tag `same_bead_within_30min=true` so M3 can dampen.
- **fleet-autonomy P3 (status primitive)** — replaced by M4. No separate primitive.
- **fleet-autonomy P4-P6** — re-evaluate AFTER M1-M4 ship. Some may be unnecessary if the manager loop's tick handles them implicitly.
- **fleet-autonomy M (morning ritual)** — replaced by M4.

The integrate-revisions phase will explicitly handle this re-ordering — that's the whole point of running this plan first.

## 8. Cross-orch input integration

Three cross-orch signals already stacked from this morning:

| Source | Signal | How M1-M4 absorbs it |
|---|---|---|
| skillos:1 (15:25Z) | blocker-owner ≠ work-block; manual callbacks invisible | M1 ops-log includes `blocker_owner` + `manual_callback_path` fields; M3 queue dampens but doesn't drop blocker-owned-elsewhere items |
| mobile-eats:1 (15:45Z) | bead substrate trusts itself without mission grounding (7 failure classes) | M3 queue scoring requires `mission_anchor_evidence_path` for each item; without it, item is not eligible for top-10 |
| Donella lane (09:41Z) | "conversational_orchestrator" invisible structure | THIS PLAN IS THE ANSWER — orchestrator is no longer conversational |

## 9. Success criteria (Donella measurement loops)

| Loop | Measure | Target |
|---|---|---|
| A | Orch pane 1 received-callbacks/hour | < 1 (was: 60+/8h overnight) |
| B | Top-10 queue items refreshed per tick | 10 (always) |
| C | Joshua interventions/day for items already on top-10 | 0 (everything Joshua acts on should already be visible) |
| D | Tick latency (read → decide → execute) | < 30s |
| E | Time from worker write → ops-log row visible to orch | < 5s |
| F | Closure_against_mission_anchor_rate | tracked (not yet baseline) |
| G | Orchestrator context-window utilization | < 30% of available (was: regularly hitting compaction) |

## 10. What absolutely IS in scope

1. ops-log writer library (any language; minimum: Python + Bash helpers)
2. ops-log schema + validator + atomic-write helper
3. Manager-loop tick driver (one canonical implementation; replaces N orch chat patterns)
4. Top-10 leverage scorer (pluggable scoring; default = blended Donella+Jeff weights)
5. Manager-loop-state.md + .json renderer (atomic write per tick)
6. Migration plan for current xpane callbacks (workers stop sending; old callbacks gracefully archived)
7. Doctor / health / repair triad for the manager loop itself

## 11. What stays out of scope

- New product features. Zero.
- Replacement of `bv` / `br` / `ntm` / `agent-mail`. We compose; we don't replace.
- Multi-orchestrator quorum. One orch per session for now.
- Removing pane-state probes. Workers can still surface state via ntm robot-mode for the watcher; that's substrate-level, not orchestrator-input.

## 12. Constraints honored

1. Jeff-stack remote-push prohibition (memory `feedback_no_push_ntm_br`).
2. ntm-only for session/pane operations.
3. Agent Mail token never echoed in pane.
4. Atomic write contract for every state mutation.
5. canonical-cli-scoping triad mandatory for any new CLI.
6. Donella + Jeff lens applied to every primitive.
7. Mission-anchor-evidence required for every top-10 item (per mobile-eats:1 input).

## 13. Open questions for the 3 review lanes

The lanes should explicitly address these — they are the integration risks:

1. **Tick interval.** 600s default — is that right? Donella would say "what's the natural rhythm of the system being managed?" Jeff would say "what's the cheapest interval that doesn't miss state changes?"
2. **One-decision-per-tick.** Is it too constrained? Should it be "up to N decisions per tick where N = max(1, queue_urgency_count)?"
3. **Joshua-readable surface format.** Markdown vs JSON-only vs both? Joshua needs to be able to skim it in 30 seconds.
4. **Migration sequencing.** Can workers start writing to ops-log BEFORE the full orch loop ships, so we accumulate baseline data? (This is probably the right answer.)
5. **Verdict thresholds.** What is HEALTHY vs DEGRADED vs BROKEN, in numbers? The Donella lens should give measurable thresholds, not vibes.
6. **Backward-compat for the in-flight fleet-autonomy-v1 reviews.** They reviewed under the OLD framing. After integrate-revisions, do we re-review the converged plan? Or trust that the manager-loop-architecture obsoletes much of P3-P6?
7. **The orch pane during ticks.** Does it sleep (silent)? Does it run a status line? What does Joshua see if he opens the pane mid-tick?
8. **Failure modes.** What if ops-log is corrupted? What if disk fills? What if a tick takes longer than the interval? The doctor primitive must handle each.

## 14. Ship order (proposed; lanes may revise)

1. M1 (ops-log writer + schema + validator) — foundational; can ship in 1 day with tests.
2. Migration: 2 worker repos start writing to ops-log (in parallel with current callbacks; both surfaces co-exist for a few days).
3. M3 (top-10 scorer) — runs READ-ONLY against ops-log, emits to a file. Orch still receives callbacks but ALSO has the queue.
4. M4 (Joshua-readable surface) — Joshua starts using it for morning ritual.
5. M2 (orch tick loop) — orch begins running tick-mode. Workers stop sending xpane callbacks. CALLBACKS_DEAD migration complete.
6. Doctor/health/repair for manager-loop.
7. Re-evaluate fleet-autonomy-v1 P3-P6 (most likely deprecated by manager loop).

Each step is reversible. Each step ships independent value.

## 15. Verdict thresholds for "should we proceed"

The 3 review lanes (multi-model + Donella + Jeff) should produce composite scores. Convergence rule per `/flywheel:plan` doctrine:

- composite ≥ 9.0 across all 3 lanes + zero critical findings + ≤1 lens disagreement → auto-advance to integrate-revisions
- below that → revise, second pass

If lanes converge on "this plan obsoletes most of fleet-autonomy-v1," that itself is a finding worth dispatching as a cross-plan reconciliation bead.

---

## Appendix A — Canonical citations

- Donella lens framing: `.flywheel/PLANS/fleet-autonomy-v1-2026-05-05/01-REVIEW-donella.md` "invisible structure named: conversational_orchestrator"
- skillos cross-orch input: `.flywheel/PLANS/fleet-autonomy-v1-2026-05-05/cross-orch-input/skillos-1-2026-05-05T1525Z.md`
- mobile-eats cross-orch input: `.flywheel/PLANS/fleet-autonomy-v1-2026-05-05/cross-orch-input/mobile-eats-1-2026-05-05T1545Z.md`
- canonical-cli-scoping standard: `~/.claude/skills/canonical-cli-scoping/SKILL.md`
- accretive-cron-orchestration: `~/.claude/skills/accretive-cron-orchestration/SKILL.md`
- handoff this morning: `.flywheel/handoffs/2026-05-05T1523-for-compaction.md`
- fleet-autonomy-v1 plan input: `.flywheel/PLANS/fleet-autonomy-v1-2026-05-05/00-PLAN-INPUT.md`
