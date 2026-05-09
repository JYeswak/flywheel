## L130 — DISPATCH-SKILL-REQUIRED-HOOK-GATE

---
id: L130
title: Dispatch skill required hook gate
status: long_term
shipped: 2026-05-07
review_due: 2026-11-07
trauma_class: dispatch-wrapper-bypass
---

Raw worker-dispatch `ntm send` commands are rejected unless they carry
`/flywheel:dispatch` wrapper proof. The `dispatch_skill_required` hook gate
matches worker-dispatch language such as dispatch-file reads, worker-tick
parity, and task callback instructions; allow proof is
`FLYWHEEL_DISPATCH_WRAPPER=1`, a `dispatch_skill_version` receipt, or
`JOSHUA_OVERRIDE=1`. Per-gate disable remains available for false-positive
recovery. Without this gate, dispatch-log entries do not exist and L120-L128
enforcement can silent-fail.

**Evidence:** bead `flywheel-wbjg`; hook
`~/.claude/hooks/flywheel-loop-dispatch-transport-gate.sh`; tests
`tests/test_dispatch_skill_required_blocks_raw_send.sh`,
`tests/test_dispatch_skill_required_allows_with_wrapper.sh`,
`tests/test_dispatch_skill_required_warn_mode.sh`, and
`tests/test_dispatch_skill_required_disable_per_gate.sh`.

Mission-anchor: continuous-orchestrator-uptime-self-sustaining-fleet.

