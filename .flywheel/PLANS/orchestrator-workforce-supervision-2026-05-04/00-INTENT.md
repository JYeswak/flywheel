---
title: "Plan Intent — orchestrator-workforce-supervision-deep-redesign"
type: plan
created: 2026-05-04
frontmatter_source: scaffold-doc-frontmatter
---

# Plan Intent — orchestrator-workforce-supervision-deep-redesign

**Slug:** orchestrator-workforce-supervision-2026-05-04
**Started:** 2026-05-04T03:38:00Z
**Triggered by:** Joshua Nowak

## Verbatim trigger

> "your callback fixes aren't working - this needs deeper /flywheel:plan"
> "why hasn't your nudge been updated to take advantage of all of our new tools / system to keep close tabs on the workforce?"

## Problem statement

The orchestrator's workforce supervision is reactive and shallow. We have many tools (watcher v4, auto-nudge, ntm robot-activity + capture_provenance + robot-diagnose, frozen-pane v2, doctor signals, watchtower, bead-quality contract, validation-receipts) but they don't compose into a unified supervision mesh.

Symptoms (all observed 2026-05-04):
- Joshua repeatedly points out idle panes ("skillos is idle", "pane 4 idle", "skillos repo is still idle")
- Each fix is a point-patch, not systemic
- Orchestrator doesn't proactively surface workforce drift before Joshua notices
- "dispatch capacity blocked / activity_THINKING" loop driver gate suggests workers are working, but reality is they may be stuck/error/false-positive
- Auto-nudge daemon was built ad-hoc 5min ago — should have been doctrine
- Nudge logic is primitive: only catches stale-error class, not stuck-thinking, callback-stuck, dispatch-stalled
- Cross-session visibility is poor — flywheel orch can't see skillos+mobile-eats+alps workforce state in one dashboard

## Goal — comprehensive workforce-supervision-mesh

A canonical system that:

1. **Detects ALL workforce-failure classes proactively:**
   - stale-error-text (capture-window false-positive)
   - stuck-thinking-too-long (THINKING with no scrollback delta >5min)
   - callback-never-arrived (dispatched bead, no DONE in expected window)
   - capture-unavailable (ntm can't read pane content)
   - registry-drift (worker identity missing or wrong)
   - MCP-disconnected (orch tools degraded)
   - identity-mismatch (worker callback cites wrong identity)
   - frozen-pane (truly dead, scrollback frozen)

2. **Auto-recovers what can be auto-recovered:**
   - stale-error → benign ping (already shipped: auto-nudge daemon)
   - stuck-thinking → soft interrupt + status-probe
   - identity-mismatch → re-read from registry, force re-cite
   - MCP-disconnected → pre-rendered /mcp instruction surfaced to orch pane

3. **Escalates what can't:**
   - 3-strike → file gap-bead with full diagnostic capture
   - frozen-pane → respawn (existing flywheel-respawn path)
   - capture-unavailable → fleet-respawn lane
   - callback-stuck → dispatch-log forensics, file no-bead receipt or fix-bead

4. **Surfaces workforce-state-of-truth on every tick** — Joshua never has to ask "why is X idle":
   - Per-pane state + last-action + time-since-last-callback
   - Per-session utilization (working/total)
   - Per-trauma-class active count
   - Auto-recovery attempts in last hour
   - Escalations pending Joshua review

5. **Cross-session: one dashboard for flywheel+skillos+mobile-eats+alps+picoz workforce** — single source of truth, not per-session probing

6. **Integrates ALL existing tools (no duplication, all signals fused):**
   - watcher v4 (per-bead dedupe + capture_provenance)
   - auto-nudge daemon (stale-error)
   - ntm robot-activity (state truth per canonical-cli-scoping)
   - ntm robot-diagnose (annotation only)
   - capture_provenance (Jeff PR #117 live/unavailable distinction)
   - frozen-pane detector v2
   - doctor signals (repo health)
   - codex watchtower (upstream substrate issues)
   - bead-quality contract (did/didnt/gaps)
   - validation-receipts (callback truth)

## Three-judges lens (per flywheel-wcq5 publishability bar)

- **Jeff:** would he look at this and say "tight, observable, fail-closed, executable verification"?
- **Donella:** are stocks (workforce-utilization, workforce-stuckness, callback-debt) named? Are feedback loops visible? Is the leverage point explicit (probably #6 INFORMATION FLOWS — making the invisible visible)?
- **Josh:** does the dashboard read as zeststream-brand-voice (per flywheel-06zn)? First-person ops, evidence-grounded, no enemy framing?

## Output expected

Full 5-phase plan (RESEARCH lanes A/B/C → REFINE → AUDIT → DECOMPOSE → POLISH) producing a bead DAG that, when dispatched, builds the canonical workforce-supervision-mesh.

## Dependencies / siblings

- flywheel-pp1g (ntm classifier stale-error issue)
- flywheel-7yic (bead-quality did/didnt/gaps contract)
- flywheel-et7t (locked worker identities)
- flywheel-ef8m (ntm #117 capture provenance mechanization)
- flywheel-wcq5 (publishability bar)
- flywheel-06zn (zeststream-soul binding)
- /tmp/auto-nudge-stale-error-recovery.sh PID 86138 (just-shipped recovery layer to be canonized)
- /tmp/idle-pane-auto-dispatch.sh + idle-pane-auto-dispatch-generic.sh (watcher v4)
- ~/.local/state/flywheel/session-topology.jsonl (cross-session topology source)

## Constraints

- READ-ONLY through Phase 3
- Phase 4 mutates beads DB only
- All worker dispatches go to visible panes via ntm send (visibility doctrine)
- Plan-space tokens 25× cheaper than code-space — invest here
