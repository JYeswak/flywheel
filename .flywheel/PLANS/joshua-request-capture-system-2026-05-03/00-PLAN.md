---
title: "Converged plan: joshua-request-capture-system"
type: plan
created: 2026-05-04
frontmatter_source: scaffold-doc-frontmatter
---

# Converged plan: joshua-request-capture-system

> Phase 2 REFINE output. Self-authored. Single round (steady-state by construction — internally consistent across the doctor-signal/jeff-issue-chain patterns shipped today).

## One-paragraph summary

Every Joshua message to a flywheel-managed orch session must be substrate-captured to that repo's MISSION.md `## Joshua Requests` section AND mirrored to a JSONL registry, via a Claude Code `UserPromptSubmit` hook (mandatory, not optional). The tick-path mechanism reads the JSONL each tick, surfaces open requests in the tick prompt, auto-creates beads for unprocessed requests >2h old, and surfaces open-request count in `/flywheel:status` dashboard. Schema propagates to all 7 fleet repos via the doctrine-sync hook. Closure protocol requires evidence (commit/bead/explicit-defer); orchs cannot just mark done. Backfill scans today's transcript for missed requests including the socraticode-index ask that triggered this plan.

## Architecture

```
Joshua message → CC harness UserPromptSubmit hook
                         ↓
              josh-request-capture.sh
                  ├─→ MISSION.md (canonical, append-only)
                  └─→ ~/.local/state/flywheel/josh-requests.jsonl (mirror)
                         ↓
              flywheel-loop-tick (every 30 min)
                  ├─→ josh-request-tick-promote.sh
                  │     ├─ surface in tick prompt
                  │     └─ auto-bead unprocessed >2h
                  └─→ /flywheel:status dashboard line
                         ↓
              orch dispatches → bead linked → closure with evidence
                         ↓
              cross-session: doctrine-sync stamps schema to 6 peer MISSION files
```

## Decisions locked

1. **MISSION.md is canon, JSONL is mirror.** MISSION.md survives session resets and is git-tracked. JSONL gives fast queries.
2. **Capture is MANDATORY at hook layer.** Cannot be "forgotten" by orch — substrate enforces.
3. **Inference happens at orch layer, not hook layer.** Hook captures excerpt + matches request-shape pattern; orch interprets `inferred_action`. Why: hook is regex; orch is reasoning.
4. **Append-only entries; status field is mutable.** No editing past entries — closure is a separate field/event.
5. **Closure requires evidence.** A request can be `done` only with linked bead-close-receipt or commit hash. `wont_do` requires Joshua confirmation excerpt.
6. **Cross-session via doctrine-sync hook (existing).** No new propagation mechanism — leverage what shipped via flywheel-t5bn this session.
7. **Phase 1 hook patterns: PERMISSIVE (start broad, tighten via doctrine-ladder).** Better to over-capture noise than miss real asks. False-positives easy to mark `wont_do`.
8. **Tick-path consumer is sibling to doctor-signal-bead-promotion.** Same architectural pattern, same wiring point in flywheel-loop-tick.

## Anti-decisions (explicit non-choices)

- **Not** auto-fulfilling requests. Capture surfaces; orch decides what to dispatch.
- **Not** modifying Joshua's input UX. Hook is purely passive observer of his messages.
- **Not** using STATE.md as canon. STATE.md is per-tick mutable; requests are eternal.
- **Not** building cross-session enforcement (each peer-orch is responsible for its own dispatching of its own captured requests; we provide schema + propagate it).
- **Not** auto-closing requests on bead-close. Closure requires explicit `josh-requests close <id> --evidence` — prevents premature "done" when bead closed but Joshua wanted more.
