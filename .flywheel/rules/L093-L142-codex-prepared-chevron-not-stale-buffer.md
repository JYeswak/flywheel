## L142 — CODEX-PREPARED-CHEVRON-NOT-STALE-BUFFER

---
id: L142
title: Codex prepared chevron is the normal pre-dispatch state
status: long_term
shipped: 2026-05-08
review_due: 2026-11-08
trauma_class: dispatch-validator-false-positive
---

`dispatch-pre-send-validator.sh` refuses dispatch with
`reason=capture_disagreement_reminder_template` when a codex pane shows
`state=WAITING` per robot-activity but the tail capture shows a CASS
reminder template in the buffer. **This is a false positive.** Per Joshua
directive 2026-05-08: codex workers always have prepared buffer content
sitting there; we paste into it. The "reminder template" is the codex
pane's normal prepared chevron buffer waiting for input.

**Override pattern (canonical for codex-pane dispatches):** when the
validator refuses with `capture_disagreement_reminder_template` AND the
pane is a codex worker AND robot-activity confirms
`state=WAITING capture_provenance=live`, log an override to dispatch-log
and proceed:

```text
validator_override_reason="codex_prepared_buffer_normal_state_per_joshua_directive_2026_05_08_dispatch_validator_false_positive_capture_disagreement_reminder_template"
```

The dispatch packet is still built via `build-dispatch-packet.sh`; L130
gate is satisfied by `FLYWHEEL_DISPATCH_WRAPPER=1` env on ntm send;
post-send delivery is verified per L140 (`dispatch-and-verify.sh`).

**Forbidden:** override does NOT apply to genuinely stale buffers (need
`/flywheel:respawn`), other validator failure reasons
(`pane_not_waiting`, `stale_capture`, `probe_failure`), or non-codex panes.

**Permanent fix (followup):** validator should distinguish prepared codex
chevron from genuinely stale buffer using a heuristic.

**Evidence:** finding 2026-05-08T15:30Z (9-hour fleet idle root cause);
doctrine `.flywheel/doctrine/loop-non-accretive-trauma-class.md`; validator
`~/.claude/commands/flywheel/_shared/dispatch-pre-send-validator.sh`.

Mission-anchor: continuous-orchestrator-uptime-self-sustaining-fleet.

**Cross-references:** L130, L140, L141.

