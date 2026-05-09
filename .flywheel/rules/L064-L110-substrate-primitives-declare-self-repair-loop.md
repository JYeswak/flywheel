## L110 — SUBSTRATE-PRIMITIVES-DECLARE-SELF-REPAIR-LOOP

---
id: L110
title: Substrate primitives declare self-repair loop
status: long_term
shipped: 2026-05-04
review_due: 2026-11-04
trauma_class: ship-then-orphan-substrate
---

Every flywheel substrate primitive that observes a recurring operational
condition, emits a finding, or produces a durable work artifact MUST declare
its repair or promotion loop in the same artifact that defines the observation.

Observable is not operational. Substrate that observes a recurring condition
without an outflow drain creates the ship-then-orphan failure mode. Six same-axis
gaps close isomorphically with this single primitive: wire-or-explain,
beadsdb-vacuum, worker-watcher, agentmail-registration, substrate-loss, and
skill-promotion-handoff. See
`.flywheel/PARADIGM-substrate-self-organization-2026-05-04.md`.

**Required contract per primitive:**
- `stock`: what accumulates.
- `inflow`: what creates or increments the stock.
- `artifact_class`: `unwired-artifact`, `maintenance-debt`,
  `watcher-coverage`, `identity-registration`, `worker-commit`,
  `skill-candidate`, or `other`.
- `consumer`: command, script, skillos inbox route, bead owner, or `NONE`.
- `deferral_owner` and `deferral_until` when no consumer can run now.
- `owner`: responsible orchestrator, pane, substrate owner, or human.
- `action_ledger`: durable JSONL row written at observation time.
- `verification_probe`: mechanical test that proves the loop closed.
- `tick_status_consequence`: doctor/status field plus warn/error policy.
- `auto_fire_trigger`: predicate that drains the stock automatically, or
  `explicit_no_auto_repair_reason` with owner and escalation threshold.
- `drain_receipt_shape`: callback, ledger row, PR, bead, or skillos relay
  receipt proving the consumer ran.

**Examples:** wire-or-explain ledger row schema; beadsdb-vacuum maintenance
window predicate; agentmail-registration resolver-mediated row; worker-commit
side-branch/reset guard; skillos relay consuming wire-or-explain rows with
`artifact_class=skill-candidate`.

**Enforcement:** `.flywheel/dispatch-log.jsonl` artifact-shipped or
rule-codification row is required at write time. Tick close gates refuse if any
in-scope primitive is missing the required contract fields. Doctor/status
surfaces expose backlog, unconsumed stock, failed drain attempts, and last
successful drain timestamp for every primitive.

**Validator:** `.flywheel/scripts/substrate-loop-contract-validator.sh` owns
`substrate-loop-contract.v1`, emits the bootstrap self-row, and is exposed via
`flywheel-loop doctor --scope substrate-loop-contract --json`.

**Forbidden outputs:**
- Shipping a watcher, ledger, report, finding class, or durable artifact without
  a named consumer or explicit deferral contract.
- Creating a second substrate for skill promotion when the wire-or-explain
  ledger can carry `artifact_class=skill-candidate`.
- Reporting a primitive "done" because it observes a condition while the stock
  has no outflow.
- Leaving action only in prose, pane scrollback, or a plan appendix without a
  durable action ledger row.

**Evidence:** paradigm synthesis
`.flywheel/PARADIGM-substrate-self-organization-2026-05-04.md`, Round 2
Finding 10 skillos-relay amendment, and CoralRaven memory classes
`feedback-substrate-loss-worker-commit-orphan.md` and
`feedback-foundational-tool-error-halt-class.md`.

**Cross-references:** L50 (Socraticode preflight), L56 (promotion ladder), L60
(doctor signal contract), L70 (no-punt chain forward), L71
(validate-and-redispatch), L82 (canonical CLI scope), L96 (3-surface doctrine),
L102 (cache refresh), L107 (shared-surface reservations), and
`feedback_wire_into_ecosystem.md`.

