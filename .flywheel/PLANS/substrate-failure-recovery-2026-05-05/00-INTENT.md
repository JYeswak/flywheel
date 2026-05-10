---
title: "INTENT — Substrate Failure Recovery 2026-05-05"
type: plan
created: 2026-05-06
frontmatter_source: scaffold-doc-frontmatter
---

# INTENT — Substrate Failure Recovery 2026-05-05

**Date:** 2026-05-05
**Scope:** Single-day fleet-wide substrate failure recovery + accretive structural fixes
**Lens:** Donella Meadows systems-thinking (#5 rules, #6 information-flow primary leverage)
**Authored by:** flywheel:1 orchestrator (CloudyMill identity at start of session)

## Why this plan exists

Joshua woke up to:

1. ~70% of overnight watcher activity was wasted probe cycles (zaat redispatched 11 times, 668a 8 times, useh/se3h parents 5+ times each) — workers correctly declined every time but burned 30+ socraticode searches and 30+ pane minutes total
2. alpsinsurance:1 stalled 6h50m on a Railway P3b deploy substrate fix, acknowledging 14 launchd heartbeats with no execution despite codified rule `feedback-decide-and-execute-not-fork-every-choice` from the prior morning
3. flywheel:1 (me, the human-facing orchestrator) saw the watcher pattern accumulating across 11 redispatches and **logged it as "interesting noise"** instead of patching the watcher despite having edit access, repo write access, and 3 idle worker panes that could have absorbed a fix-dispatch within 5 minutes
4. skillos:1 froze at 20m58s on a docs improvement task; flywheel:4 froze at 13m44s post-callback waiting for callback verification that never returned
5. Joshua intervened personally at 14:44Z to fire NIXPACKS rebuild on alps Railway after orchestrator stall — the exact meat-puppet failure the entire fleet protocol is supposed to prevent

The two failures have **a single root class**: orchestrators treating *describing the problem* as a substitute for *executing the next tactical move when the cost of being wrong is reversible*.

This is L70 orch-punt. The codified rule already exists. The codified rule does not yet have a substrate-level guard that *forces* execution. Without that guard, every tired orchestrator will fall back into "log it and ack the next heartbeat" because that pattern is locally-cheaper than fix-dispatch even when the global cost (Joshua's morning) is enormous.

## The mission

Build accretive substrate that makes "describe and ack" *more expensive* than "execute and report" at the orchestrator level, while simultaneously fixing the watcher's readiness probe so the same wasted-cycle class does not repeat tonight.

This is a **Donella Meadows #5 rules** intervention layered on top of a **#6 information-flow** intervention. The watcher's probe lacks the right inputs (information-flow); the orchestrator lacks the right rules around what counts as "work" (rules). Both must be patched. Patching only one re-creates the failure in the other dimension.

## What stays out of scope

- New features. None of this work creates new product capability.
- Changes to Jeff's upstream binaries (br, ntm, dcg, cm). Those are read-only relative to this plan.
- Changes to MISSION.md or paradigm-level doctrine. The paradigm is fine; the substrate enforcing the paradigm is broken.
- Anything that risks the 20+ overnight bead closures already shipped (jeff-philosophy, jeff-intel pipelines, jrvh handoff template, g343 skillos handoff, k5yp monthly plist, etc.). Every change here must preserve that work.

## What absolutely IS in scope

1. **Watcher readiness probe filter** — closed beads, currently-reserved beads, parents-with-open-children, beads with recent BLOCKED note within an exclusion window
2. **Orch execution gate** — a substrate hook that fires if any orchestrator pane logs the same trauma class N times in a sliding window without a corresponding fix-dispatch action recorded
3. **Storage trend monitor** — automatic ballast prune + alert when disk drops below configurable thresholds (currently 29GB free with no automatic action)
4. **Pane freeze detector with auto-respawn permit-gate** — multi-frame hash-diff converging on a single canonical surface, with respawn permitted under specific guards
5. **Fleet SITREP cron** — replaces ad-hoc "what happened overnight" with a structured artifact written every 15 min by an independent process
6. **Repair-bead-to-action pipeline** — when repair beads are filed (like 1eg0k for br-sync), the substrate must dispatch them within N hours rather than letting them sit indefinitely
7. **Cross-orch reservation timeout enforcement** — agent-mail reservations longer than 5 minutes on shared substrate files (`.beads/beads.db`, etc.) auto-release with notification

## Constraints that must be honored

1. The Jeff-stack remote-push prohibition (memory `feedback_no_push_ntm_br`) — ALL upstream binary changes go in via local-edit or upstream-issue pathway only
2. `feedback_topology_lookup_before_dispatch` — every dispatch lookup `~/.local/state/flywheel/session-topology.jsonl` first
3. `feedback_use_ntm_not_raw_tmux` — no raw tmux, only `ntm` for session/pane operations
4. `feedback_data_decides_not_human_meatpuppet` — fixes must be data-decided not Joshua-gated except for the 6 TRUE-blocker classes
5. `feedback_orch_punt_is_l70_failure_dispatch_dont_ask` — the meta-failure this plan exists to fix; do not violate it WHILE building the fix

## Success criteria (Donella measurement loops)

| Loop | Measure | Target |
|------|---------|--------|
| A | Same-bead redispatch count per night | < 2 (was: zaat=11, 668a=8) |
| B | Orchestrator stalls > 30min on tactical work | 0 (was: 6h50m alps + 13m44s flywheel:4 + 20m58s skillos:1) |
| C | Joshua manual interventions per day on substrate | < 1 (was: ≥3 yesterday) |
| D | Time from repair-bead-filed to repair-bead-dispatched | < 2hr (was: 1eg0k filed but never worked) |
| E | Storage low-water-mark distance from threshold | > 50GB (was: 29GB free) |
| F | Cross-orch reservation timeout violations | 0 (was: MagentaPond holding .beads/beads.db 50+ min repeatedly) |
| G | Frozen panes detected without orchestrator action within 1 watcher tick | 0 (was: 3 frozen panes survived multiple ticks today) |

If any measure regresses after the plan ships, the plan failed and triggers a rework bead.

## What this plan is NOT

- Not a redesign of the watcher. The watcher's architecture is correct (60s tick, dispatches via robot-activity, classifier converged with `br ready`). The probe's filter set is incomplete. We add filters; we don't replace the watcher.
- Not a replacement for `/flywheel:plan`. This is a focused recovery plan, not a milestone roadmap.
- Not a hot-patch. The plan must produce reviewable, testable, documented work that future orchs can audit.
- Not optional. Every overnight cycle without these fixes wastes ~30 worker pane-minutes and ~5 Joshua-minutes the next morning. The compounding cost over a month is fleet-disabling.
