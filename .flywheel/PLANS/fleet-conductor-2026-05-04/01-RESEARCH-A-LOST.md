# Lane A LOST — orchestrator waiter bug 2026-05-04T04:30Z

## What happened
The waiter daemon (/tmp/fleet-conductor-waiter.sh) tracked "fired" via touch files but did NOT track "pane currently busy." When p3 became WAITING after a quick dispatch, the waiter:
- 04:20:22Z dispatched Lane A to p3 (correct)
- 04:22:41Z dispatched Lane C to p3 (BUG — only 2min later, p3 still consuming Lane A input)

Codex's input buffer received Lane C while still parsing Lane A → Lane A task body lost; Lane C executed and completed at 04:25Z (437 lines).

## Decision (Meadows-friendly approval blanket)
DO NOT redispatch Lane A. Reasoning:
- Parent plan's Lane A (`orchestrator-workforce-supervision-2026-05-04/01-RESEARCH-A.md`, 210 lines) covers session-local problem-space taxonomy
- This plan's Lane B (232 lines) + Lane C (437 lines, full 9-layer architecture) + INTENT-AMENDMENT (49 lines, v2/v3 framing) cover the fleet-tier expansion
- REFINE worker will synthesize from B+C+amendment+parent's Lane A
- Cost savings: ~12 worker-min
- Risk: REFINE may flag fleet-specific failure-mode catalog gaps; Phase 3 AUDIT will catch + ADDENDUM-absorb if real

## Bug filed
flywheel-loop-waiter-pane-busy-tracking — added to backlog (filed inline as no-bead since fleet-conductor's Layer 4 will obsolete this ad-hoc waiter pattern entirely).

## Resume directive
REFINE r1 worker: ingest Lane B + Lane C + INTENT-AMENDMENT + parent's Lane A as Phase 1 inputs. Note Lane A miss in synthesis. Phase 3 AUDIT must explicitly probe for fleet-tier failure-class gaps that Lane A would have surfaced.
