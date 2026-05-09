## L109 — WIRE-OR-EXPLAIN-IS-A-FLOW-GATE

---
id: L109
title: Wire-or-explain is a flow gate
status: long_term
shipped: 2026-05-08
review_due: 2026-11-08
trauma_class: advisory-wire-drift
---

Wire-or-explain is a flow gate, not a reminder. Any shipped durable artifact,
rule, script, hook, callback contract, report, or skill candidate that creates a
new operational obligation must either be wired to a named consumer or explain
the deferral in the wire-or-explain ledger before close.

**Why:** The wire-or-explain plan proved that orphaned observations do not fail
because agents forget prose; they fail because no stock, consumer, and outflow
exist. B6 mechanics now make that stock operational: the close gate can block or
shadow-block unresolved local rows, and doctor/status can expose the backlog
before the loop claims health.

**How to apply:**
- Emit or update a `wire-or-explain-ledger/v1` row through the ledger writer for
  any shipped artifact that is not already consumed by a command, test, doctor
  field, hook, skillos route, or bead owner.
- Classify the row with the shipped detector and ranker so unresolved work has
  `state`, `artifact_class`, `owner`, `consumer`, `blocking_scope`,
  `verification_probe`, and `tick_status_consequence`.
- Run `.flywheel/scripts/wire-or-explain-close-gate.sh --json` during tick
  close. Shadow mode may report `would_block=true`; enforce mode blocks close
  until unresolved in-scope rows are wired or carry a bounded override receipt.
- Use `flywheel-loop doctor --repo <repo> --json` and the `.wire_or_explain`
  field as the operator surface for unresolved count, overdue count, skill
  candidate backlog, relay failures, and suggested next action.

**Forbidden outputs:**
- Calling wire-or-explain a checklist, reminder, or advisory note.
- Closing a tick after shipping a new obligation with no ledger row, consumer,
  or explicit deferral owner.
- Hiding unresolved wire-or-explain rows in prose while doctor/status claims the
  loop is healthy.
- Filing a new skill candidate outside the wire-or-explain flow when the row can
  carry `artifact_class=skill-candidate` and route to skillos.

**Evidence:** mechanics beads `flywheel-4m2a` (ledger schema/writer),
`flywheel-333j` (ship-event classifier), `flywheel-12ip` (wired detector),
`flywheel-y6a1` (wire-priority ranker), `flywheel-2eow` (doctor fields), and
`flywheel-2ypj` (tick-close gate); plan sources
`.flywheel/PLANS/wire-or-explain-tick-gate-2026-05-04/02-REFINE-r2.md` and
`.flywheel/PLANS/wire-or-explain-tick-gate-2026-05-04/03-AUDIT-r2-confirmation.md`;
tests `tests/wire-or-explain-ledger.sh`, `tests/wire-or-explain-detector.sh`,
`tests/wire-or-explain-ranker.sh`, `tests/wire-or-explain-close-gate.sh`, and
`tests/wire-or-explain-close-gate-fault-injection.sh`.

**Cross-references:** L50 (Socraticode preflight), L52 (beads/no-bead receipt),
L56 (promotion ladder), L60 (doctor signal contract), L61 (ecosystem wire-in),
L82 (canonical CLI scope), L96 (3-surface doctrine), L108 (sync convergence),
L110 (self-repair loop), and L112 (callback probe fields).

