## L129 — WORKER-SUBSTRATE-EXPLICIT

---
id: L129
title: Worker substrate explicit for dispatch and convergence work
status: long_term
shipped: 2026-05-07
review_due: 2026-11-07
trauma_class: convergence-audit-bypass-codex-workers
---

Every schema v2 dispatch row and packet header MUST classify the worker
substrate explicitly:
`worker_substrate=codex-pane|claude-pane|background-agent|local` and
`agent_type=codex|claude|unknown`. `/flywheel:dispatch` defaults NTM pane
sends to `worker_substrate=codex-pane agent_type=codex`.

Convergence, adversarial review, audit-wave, and synthesis work requires
`worker_substrate=codex-pane` unless `JOSHUA_OVERRIDE` is present and logged by
the worker-substrate lint gate with reason
`convergence_to_background_agent_blocked` or `joshua_override`.

**Why:** L120-L127 callback enforcement and L128 convergence-proved-with-data
only compose when work travels through the visible NTM dispatch substrate.
Background-agent side channels bypass dispatch-log, close-handler, callback
contract, and validation evidence, so L128's data trail disappears.

**Evidence:** bead `flywheel-2tv3`; plan
`.flywheel/PLANS/dispatch-enforcement-2026-05-01.md`; lint gate
`.flywheel/scripts/dispatch-worker-substrate-gate.sh`; command docs
`~/.claude/commands/flywheel/dispatch.md` and
`~/.claude/commands/flywheel/_shared/dispatch-template.md`.

Mission-anchor: continuous-orchestrator-uptime-self-sustaining-fleet.

**Cross-references:** L48, L50, L52, L53, L56, L60, L70, L71, L72, L96, L110,
L116, and L120.

