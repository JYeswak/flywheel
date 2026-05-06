# Fleet Autonomy v1 — Plan Input for /planning-workflow Review

**Date:** 2026-05-05
**Status:** Plan-input ready for multi-model review per `/planning-workflow` exact-prompt
**Author:** flywheel:1 orchestrator (after Donella+Jeff lens audit + bv end-to-end verification)

---

## Stated mission

> Build a system that runs 8+ hours autonomously while founder sleeps, producing high-quality bead closures against locked mission anchors per repo, with no founder intervention required for tactical-next-move execution. Founder grows OUTSIDE the founder. The fleet is a flywheel, not a set of tools requiring an operator.

## Hard evidence — overnight 2026-05-05T07:00Z → 15:00Z (8 hours)

| Metric | Reality | Stated goal |
|---|---|---|
| Bead closures (4 repos combined) | **2** (both flywheel `7lby` + `7lby.1`) | 5-15 |
| Dispatches fired | 107 | — (input, not output) |
| Closure conversion rate | **1.9%** | >25% |
| Fuckups logged | 390 | <50 |
| Top trauma class | `fleet-propagation-failed` (188 dup-encoded events) | — |
| 2nd trauma class | `dispatch_callback_overdue` (82) | <10 |
| 3rd trauma class | `owner-custody-missing` (64, mobile-eats stuck loop) | <5 |
| Pane freezes | 4 (alps:1 6h50m, skillos:1 20m58s, flywheel:4 13m44s, mobile-eats:1 ERROR) | 0 |
| Joshua manual interventions | ≥3 (alps NIXPACKS fire, skillos respawn, plus orchestrator-fleet-stats requests) | 0 |

The fleet **succeeded at appearing busy** while **failing at producing work**. This is leverage point #3 (system goal) misalignment.

## Donella's diagnosis (she would lead with this)

The fleet's revealed goal is "maximize visible activity," not "maximize closure velocity." Three reinforcing loops with no balancing partners:

- **Loop A:** watcher fires → worker probes stuck bead → BLOCKED → watcher re-picks same bead → repeat. No same-bead-skip dampener.
- **Loop B:** mobile-eats reap-poll → owner-custody-missing → record commit → reap-poll. No iteration cap.
- **Loop C:** orchestrator (me) reads worker callbacks → ack → next callback → repeat. No closure-vs-callback ratio gate.

Each loop passed its local check (dispatch fired, callback received, commit landed) while the global stock (closures) flatlined.

Her interventions, in order:
1. **Redefine "work" as closure-against-mission, not dispatch-fired.** (Leverage #3 — system goal)
2. **Cap every reinforcing loop with N-iterations-before-escalate.** (Leverage #4 — self-organization rules)
3. **Wire the fuckup-log into the watcher selection logic.** Information already exists, doesn't flow. (Leverage #6 — information flow)
4. **Shorten delays by 10×:** repair-bead-aging 2h cap, heartbeat-without-execution 3min cap, pane-freeze 5min cap. (Leverage #9 — parameters)
5. **Lead morning report with stocks, not flows.** Closures, ready-aging, repair-aging, mission-progress. Dispatches/commits/fuckups go on page 2.

## Jeff's diagnosis (he would not write this — he would ship)

His mental model: every dispatch is an `Operation`, every bead is the `Object`, the watcher computes `next_op = f(state)`. If `next_op == previous_op` for the same `Object` and no closure event happened between, the loop is divergent — assert, log, stop.

His one observation: **the watcher is consuming `br ready` instead of `bv --robot-next`.** That's the entire bug. `br ready` is "what could be worked." `bv --robot-next` is "what should be worked, ranked by PageRank-on-the-DAG, deprioritizing stuck downstream chains, surfacing unblockers." The substrate already has the right primitive — the watcher refuses to use it.

His fix: 1-line change. Replace `br ready --json | jq '.[0].id'` with `bv --robot-next | jq -r '.id'`. Test by replaying last night's dispatch-log. Done in one bead, one worker, ~30min.

His secondary observations:
- `dispatch_callback_overdue` (82 events) means dispatches don't have a CRDT-style atomicity contract. He'd add one.
- MagentaPond's 50min `.beads/beads.db` reservation hold is **the substrate not enforcing its own contract**. agent-mail has TTL — set it to 300s.
- Sibling-inspection-first (Hard Rule #0 you just codified for Railway) is the same anti-pattern: alps spent 7h *understanding* a broken config when the diff against working siblings was 30sec away.

## bv end-to-end verification (just completed 2026-05-05T15:14Z)

| Test | Result |
|---|---|
| `which bv` | `/Users/josh/.local/bin/bv` ✅ |
| `bv --robot-next` (no args, returns JSON natively) | ✅ Returns `flywheel-4m2a` (P0, PageRank 100%, unblocks 1, unclaimed) |
| Stability (5 consecutive picks) | ✅ Same ID, score increments tiny (cache-freshness only) |
| Counterfactual: zaat status | `BLOCKED` — bv would have skipped, watcher dispatched 10× |
| Counterfactual: 668a status | `BLOCKED` — bv would have skipped, watcher dispatched 15× |
| What bv picks now (`flywheel-4m2a`) | High-leverage unblocker for `flywheel-333j`, never dispatched overnight |

**Conclusion:** The single highest-leverage line-change in the entire fleet is replacing the watcher's `br ready` selection with `bv --robot-next`. Estimated impact: 107 → ~30 dispatches with same closure budget, plus the closures land on real unblockers cascading more downstream work.

---

## Plan: Fleet Autonomy v1

The mission decomposes into 5 substrate primitives + 1 measurement loop, each addressing a specific failure observed overnight. Order matters — implementations later in the list depend on earlier ones being stable.

### P1: Watcher uses `bv --robot-next` (one-line core change + tests)

**Status:** Highest-leverage, lowest-blast-radius. Ships first.

**Donella view:** Closes Loop A (same-bead redispatch). Replaces "what could be worked" with "what should be worked next, PageRank-ranked, DAG-aware."

**Jeff view:** Stops inferring from partial view, uses canonical-state primitive. The substrate already knows the right answer.

**Change:** In `~/Developer/flywheel/.flywheel/scripts/idle-state-probe.sh` (or wherever the next-bead selection happens — needs grep), replace:
```bash
NEXT=$(br ready --json | jq -r '.[0].id // empty')
```
with:
```bash
NEXT=$(bv --robot-next 2>/dev/null | jq -r '.id // empty')
SCORE=$(bv --robot-next 2>/dev/null | jq -r '.score // 0')
UNBLOCKS=$(bv --robot-next 2>/dev/null | jq -r '.unblocks // 0')
# Log the rationale into the dispatch-log
```

**Test fixture:** Replay last night's 107-dispatch sequence. Assert that the bv-picked bead would have been different from the watcher's pick on at least 60 of 107 events. Acceptance gate: counterfactual closure rate > 15% on the replay.

**Worker:** 1 codex pane, ~30min.

**Risk:** `bv --robot-next` could pick a bead that's been dispatched recently and is in-flight. **Mitigation:** add a sibling check that consults `dispatch-log.jsonl` for the same `bead_id` in the last 30min — skip if found.

---

### P2: Watcher self-asserts on divergent loops (Jeff's CRDT invariant)

**Status:** Ships immediately after P1. Same script, additive.

**Donella view:** Adds the balancing dampener Loop A is missing. After 2 same-bead picks within 30min without a closure event between, the watcher must mark the bead `recently_attempted` and skip for the rest of the cooldown window.

**Jeff view:** Substrate enforces its own loop-divergence invariant. Self-assertion at the consumer level until upstream `br` exposes "skip-recently-attempted" natively.

**Change:** Within the same probe, before calling `bv --robot-next`, query `dispatch-log.jsonl` for the picked bead-id in last 30min. If count >= 2 and no `closure_event` in the same window, log the skip with reason `same-bead-cooldown` and call `bv` again with the previous pick excluded (via `bv --robot-next --exclude=<id>` if it exists, else fallback to "no dispatch this tick, log idle").

**Test fixture:** Synthetic scenario where same bead is dispatched 3 times in 5min — assert 3rd attempt is skipped.

**Worker:** Same pane as P1 (combine into single dispatch).

---

### P3: `flywheel-loop status` primitive with computed verdict

**Status:** Foundation for the morning ritual. Independent of P1/P2 (different file).

**Donella view:** Stocks-before-flows. The morning report leads with closures, ready-aging, repair-aging, mission-progress. The verdict is **computed** not interpreted.

**Jeff view:** Canonical-cli-scoping triad. `flywheel-loop status [--since=Nh] [--watch -i N] [--json]`. Reused, not bespoke per consumer.

**Output schema:**
```json
{
  "generated_at": "<iso>",
  "window_hours": 8,
  "closures_per_repo": {"flywheel": 2, "skillos": 0, "alpsinsurance": 0, "mobile-eats": 0},
  "dispatches_per_repo": {"flywheel": 107, ...},
  "closure_conversion_rate": 0.019,
  "ready_bead_age_p95_hours": {...},
  "repair_bead_age_p95_hours": {...},
  "dispatch_callback_overdue_rate": 0.77,
  "watcher_unique_bead_ratio": 0.31,
  "frozen_panes": [{"session": "alpsinsurance", "pane": 1, "duration_min": 410}, ...],
  "joshua_interventions_count": 3,
  "verdict": "DEGRADED",
  "verdict_reasons": [
    "closure_conversion_rate=0.019 below threshold 0.25",
    "dispatch_callback_overdue_rate=0.77 above threshold 0.10",
    "1 frozen_pane >30min observed"
  ]
}
```

**Verdict thresholds (codified):**
- `HEALTHY`: closure_conversion >= 0.25, callback_overdue <= 0.10, no frozen panes, all repair beads aged < 2h
- `DEGRADED`: any single threshold breach
- `BROKEN`: 2+ threshold breaches OR closure_conversion = 0 with > 50 dispatches

**Storage:** appends to `~/.local/state/flywheel/status-history.jsonl` every 5min via launchd plist. Morning ritual = `tail -1` + jq pretty-print.

**Worker:** 1 codex pane. ~60min.

**Acceptance gate:** Run against last night's data, must return `BROKEN` verdict with all 3 reasons listed.

---

### P4: Cross-orch reservation TTL enforcement

**Donella view:** MagentaPond holding `.beads/beads.db` for 50min repeatedly is unbounded delay. Cap at 300s.

**Jeff view:** agent-mail's TTL is the substrate's contract. Enforce it.

**Change:** Within the watcher probe, before dispatching, check agent-mail reservations on `.beads/beads.db` and `.beads/issues.jsonl`. If a reservation older than 300s exists, log `cross-orch-stale-reservation` event AND fire a `force-release` against agent-mail (auto, no Joshua). Skip dispatch this tick.

**Worker:** 1 pane. ~30min including agent-mail probing.

---

### P5: Pane freeze auto-respawn permit-gate

**Status:** Generalizes the multi-frame hash-diff freeze detection that already exists in `frozen-pane-detector v2` to fire respawn under permit.

**Donella view:** Loop B (frozen pane untreated) needs a balancing loop. Auto-respawn after 5min hash-converged.

**Jeff view:** Permit-gate guards correctness — `human_pane`/`orchestrator_pane`/`callback_pane` are protected, others auto-respawn under the existing 6-step (snapshot → respawn → relaunch → wait → inject → verify).

**Change:** Extend frozen-pane-detector to invoke `flywheel-respawn` skill when:
- multi-frame hash-converged for 5min
- pane NOT in topology's protected list
- no Joshua-permit override active

**Risk:** False-positive freezes on legitimately long-running tasks (long socraticode, long compile). **Mitigation:** Hash-converge over 5min PLUS heuristic that working tasks usually log to stdout — if `tmux capture-pane` shows new bytes since last frame, NOT frozen.

**Worker:** 1 pane. ~60min.

---

### P6: Repair-bead-aging escalation pipeline

**Donella view:** `flywheel-1eg0k` (br-sync repair) sat 8h+ untouched. That's a delay too long to tolerate.

**Jeff view:** Beads with label `repair-bead` should rank specially in `bv` priority — they unblock substrate. File upstream issue if `bv` doesn't already do this.

**Change:** Watcher tier on detected repair-bead-aging:
- 0-2h: normal priority
- 2-6h: P0-promoted, escalated to current ready queue
- 6h+: Pushover + auto-escalate to flywheel:1 inbox via agent-mail

**Worker:** 1 pane. ~30min (mostly logic + dispatch hooks).

---

### M (Measurement): Morning ritual artifact

The morning ritual = `flywheel-loop status --since=overnight --human` which renders the most-recent `status-history.jsonl` row as a markdown brief, leading with:

```
🚦 Fleet verdict: DEGRADED
Reasons: 1) closure_conversion_rate=0.019 below threshold

Stocks (overnight 8h):
  Closures by repo: flywheel=2, skillos=0, alps=0, mobile-eats=0
  Conversion rate: 1.9% (target ≥25%)
  Repair beads aging > 2h: flywheel-1eg0k (8h)
  Frozen panes: alpsinsurance:1 (410min)

Flows (page 2 — process noise, not stocks):
  Dispatches: 107
  Commits: 66
  Fuckups: 390 (top class: fleet-propagation-failed × 188)

Joshua interventions: 3
Mission-progress vs locked anchors: NO DELTA (no closures landed)
```

This is the artifact you read with coffee, not me composing a chat summary.

---

## Constraints

1. **No push to Jeff-stack remotes** (memory `feedback_no_push_ntm_br`).
2. **Preserve overnight closures** (jeff-philosophy/jeff-intel pipelines, jrvh, g343, k5yp, etc.).
3. **Canonical-cli-scoping** on every new CLI surface.
4. **ntm not raw tmux**.
5. **Data-decides-not-meatpuppet** — no Joshua gates except 6 TRUE-blocker classes.
6. **Sibling-inspection-first** (railway-api Hard Rule #0, generalize to all substrate-config debug).

## Success criteria

| Loop | Measure | Target | Was |
|---|---|---|---|
| A | same-bead-redispatch per night | < 2 | 11 (zaat), 15 (668a) |
| B | orchestrator stalls > 30min on tactical | 0 | 6h50m (alps) |
| C | Joshua manual interventions per day on substrate | < 1 | ≥3 |
| D | repair-bead filed→dispatched | < 2hr | indefinite (1eg0k 8h+) |
| E | storage low-water distance from threshold | > 50GB | 29GB |
| F | cross-orch reservation timeout violations | 0 | repeated 50min holds |
| G | frozen panes detected→action within 1 watcher tick | 0 | 3 today |
| H | fleet runs 8h founder-absent without degradation | YES | NO |

If any measure regresses post-ship, the plan failed → rework bead auto-fires.

## Out of scope

- New features (no product capability)
- Changes to Jeff's upstream binaries (file upstream issues if needed; do not local-fork)
- MISSION.md or paradigm-level doctrine changes
- Anything that risks overnight closures already shipped

## Why this plan and not the 3000-line version

I started a 3000-line plan and Donella+Jeff would have rejected it as a busy-ness signal of its own. The real plan is 6 atomic primitives + 1 measurement, each independently shippable, totaling maybe 6 worker-pane hours. The 3000-line version was the L70 anti-pattern recursing into planning itself.

The plan you should review is short because the system is simple once you accept that the watcher is consuming the wrong primitive. Everything else cascades from that one fix.
