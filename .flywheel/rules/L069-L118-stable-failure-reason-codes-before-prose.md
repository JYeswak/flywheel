## L118 — STABLE-FAILURE-REASON-CODES-BEFORE-PROSE

---
id: L118
title: Stable failure reason codes before prose
status: long_term
shipped: 2026-05-05
review_due: 2026-11-05
trauma_class: prose-only-failure-taxonomy
---

Every agent-readable failure surface MUST carry a stable, machine-parseable
reason code before or beside prose. Human explanation is useful, but a loop,
validator, or downstream worker needs a durable enum to route the failure
without re-parsing English.

**How to apply:**
- New doctor, probe, validator, callback, and repair JSON that can report
  `warn`, `fail`, `blocked`, or `refuse` MUST expose `reason_code` or a named
  equivalent field such as `failed_signal`, `violation.class`, `trauma_class`,
  or `blocked_by`.
- Prefer lowercase snake_case or kebab-case codes already used by the substrate;
  introduce a new enum only when no existing code captures the failure.
- When prose changes but the operational class is unchanged, keep the code
  stable. When a code changes meaning, ship a schema or migration note.
- Beads filed from failures SHOULD include the code in the title or labels so
  repeated failures group mechanically.

**Forbidden outputs:**
- Routing a recurring failure from prose-only strings like "still broken" or
  "could not validate".
- Adding a new validator or doctor field whose failure classes cannot be
  counted with `jq` or `rg` without natural-language parsing.
- Renaming an existing failure code without a compatibility alias or migration
  note.

**Evidence:** Source: Jeff frankensearch:frankensearch/frankensearch/src/index_builder.rs:176 + ZestStream adaptation.
The code-shaped failure pattern appears in the philosophy catalog as
`failure-taxonomy-reason-codes`; flywheel adopts it
for callbacks, doctor JSON, validators, and Beads routing so L52/L53 findings
group by substrate class instead of prose.

**Cross-references:** L50, L52, L53, L56, L60, L64, L71, L80, L111, and
`dicklesworthstone-stack`.

