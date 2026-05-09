## L134 — TEAM-ROSTER-FRESHNESS-GATES-LOOPS

---
id: L134
title: Team roster freshness gates loops
status: long_term
shipped: 2026-05-08
review_due: 2026-11-08
trauma_class: silent-session-loop
---

Doctor surfaces team-roster freshness per session. Pulse age greater than 15
minutes is `DEAD` unless the latest roster event is dormant, paused, or
teardown; `/flywheel:loop` refuses on missing roster rows or stale/missing
pulse rows. Silent sessions cannot keep running loops from stale markers.

**Evidence:** bead `flywheel-32so`; implementation in
`~/.claude/skills/.flywheel/lib/session.sh`,
`~/.claude/skills/.flywheel/lib/portable/core.sh`, and
`~/.claude/commands/flywheel/loop.md`.

Mission-anchor: continuous-orchestrator-uptime-self-sustaining-fleet.

