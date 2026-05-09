## L90 — PANE-ACTION-PLAN-REQUIRES-LIVE-CAPTURE

---
id: L90
title: Pane action plan requires live capture
status: long_term
shipped: 2026-05-04
review_due: 2026-11-04
trauma_class: orchestrator-pane-action-without-live-truth
---

Before any destructive, interrupting, or recovery pane action, the orchestrator
MUST produce a pane-action receipt from fresh live capture. Robot activity,
stale error text, pane title, old health JSON, or capacity math are hints, not
authority. Clean agent prompt means dispatch/no-op; active work means wait;
unknown means classify unknown and do not destroy.

Required receipt fields are `session`, `pane`, `capture_ts`,
`capture_provenance`, `visible_prompt_class`, `activity_state`,
`target_action`, `allowed_by_rule`, `forbidden_actions_checked`, and
`recovery_postcondition`. A valid probe should fail unless
`capture_provenance == "live"`, `capture_ts` is within the freshness window,
and destructive actions are blocked unless `visible_prompt_class` proves a
recoverable shell or confirmed-dead state.

**Why:** Last-24h fuckup-log evidence shows 38 rows across pane/capacity action
classes: `worker_capacity_gate_failed` 12 rows
`~/.local/state/flywheel/fuckup-log.jsonl#L312-L327`,
`mobile-eats-dispatch-health-gate-fail` 11 rows `#L455-L467`,
`worker-pane-not-waiting-integrate-blocker` 6 rows `#L399-L414`,
`worker_capacity_gate_false_block` 5 rows `#L328-L344`, and
`integrate_worker_not_waiting` 4 rows `#L351-L359`. Memory cross-ref:
`~/.claude/projects/-Users-josh-Developer-flywheel/memory/feedback_orchestrator_is_the_killer_not_codex.md`.

**How to apply:** enforce a pane-action receipt schema and validator before any
pane-touching action; the validator should expose a machine check equivalent to
`jq -e '.capture_provenance == "live" and (.forbidden_actions_checked | length) > 0 and .allowed_by_rule == true'`.

**Cross-references:** L29 (NTM-only pane I/O), L57 (loop marker is not driver),
L67 (truth source must be live), L71 (validate-and-redispatch), L85 (idle state
class canonical), L87 (stale error auto-ping recovery), and
`feedback_probe_shape_ambiguity_is_not_joshua_gate.md`.

