## L71 — VALIDATE-AND-REDISPATCH-DISCIPLINE

---
id: L71
title: Validate-and-redispatch discipline
status: long_term
shipped: 2026-05-03
review_due: 2026-11-03
trauma_class: orchestrator-skipped-callback-validation
---

Every worker callback, closed bead, and changed flywheel surface is a claim
until the validate-and-redispatch discipline produces a mechanical receipt. The
orchestrator MUST validate the claim, document the evidence surface, and route
any finding before it summarizes work as complete or integrates the result.

This doctrine is long-term after B12 (`flywheel-yasl`) proved the full
end-to-end rollout with a staged smoke harness. Executable proof exists for the
core primitives: B03 callback validation, B05 VALIDATE phase, B06 fix-bead
creation, B07 closed-bead reopen candidates, B08 L70 same-tick chaining, B09
learn routing, B11 runtime context parity, ft04 doctrine propagation, f589
callback delivery verification, and B12 final smoke. B13 capture parity and B14
3-Q registry remain companion expansion gates and must not be silently bypassed.

**How to apply:**
- Treat worker `DONE` / `BLOCKED` callbacks as untrusted input until
  `.flywheel/scripts/validate-callback.py` or a successor emits a validation
  receipt with `status=pass`, `fail`, or `unknown`.
- A failed or unknown validation MUST route to exactly one durable outcome
  before summary or integration: fix bead/update, reopen candidate/apply,
  explicit `no_bead_reason`, or BLOCKED callback with evidence.
- Closed beads that cite shipped artifacts MUST be checked by
  `.flywheel/scripts/closed-bead-artifact-scan.py`; missing files, invalid
  schemas, non-executable scripts, and failed smoke commands are not closed
  work.
- Workers MUST verify callback delivery with
  `.flywheel/scripts/verify-callback-delivery.sh` or equivalent pane-log proof
  before exiting cleanly.
- When validation names a next actionable phase, L70 applies: chain the phase in
  the same tick if capacity exists, or emit `chain_blocked_reason=<concrete>`.
- New validation doctrine or surfaces MUST wire into AGENTS.md, README.md,
  memory, canonical paths, and skill guidance in the same session per L61.

**Forbidden outputs:**
- "Worker done", "bead shipped", "validated", or "integrated" based only on a
  callback line, close reason, or worker prose.
- Forwarding worker findings to Joshua as fact before artifact, schema, command,
  or receipt validation runs.
- Closing a validation failure with no fix bead, reopen candidate, no-bead
  receipt, or learn-route record.
- Treating raw orchestrator-shell success as runtime proof when L69 requires an
  in-agent probe.
- Letting a named next phase wait for launchd/cron when same-tick capacity
  exists.

**Evidence:** plan
`.flywheel/plans/validate-and-redispatch-foundational-2026-05-03/00-PLAN.md`;
beads `flywheel-bc7c`, `flywheel-scwo`, `flywheel-0wbf`, `flywheel-zgo3`,
`flywheel-hf58`, `flywheel-8xrn`, `flywheel-i8b6`, `flywheel-zdva`,
`flywheel-u2dr`, `flywheel-ft04`, and `flywheel-f589`; parent doctrine bead
`flywheel-1z65`; mechanical gate bead `flywheel-7lby`; memory entries
`feedback_orchestrator_validates_callbacks.md`,
`feedback_worker_verify_callback_delivered.md`,
`feedback_low_bead_threshold_work_hunt.md`, and
`feedback_three_audit_questions_per_surface.md`.

**Companion rules:** L52 (issue/no-bead receipts), L56 (promotion ladder), L60
(five-signal loop integrity), L61 (ecosystem wire-in), L69 (agent-context
probes), L70 (same-tick chaining), `orchestrator-validation-discipline` skill,
and the validate-and-redispatch discipline memory note.


