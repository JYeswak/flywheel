## L80 — CLOSED-BEAD-AUDIT-MINING

---
id: L80
title: Closed bead audit mining
status: long_term
shipped: 2026-05-04
review_due: 2026-11-04
trauma_class: closed-bead-quality-drift
---

Closed beads are not accepted as complete solely because the close reason says
they shipped. Every worker callback MUST report structured
`did=<n>/<total>`, `didnt=<bead-ids|none>`, and `gaps=<bead-ids|none>`, and any
uncompleted gate or newly-discovered work MUST already have a fix or audit-gap
bead before callback. The orchestrator must treat missing DID/DIDNT/GAPS fields
as a validation failure.

**How to apply:**
- Worker dispatch templates and `/flywheel:worker-tick` require a DID/DIDNT/GAPS
  self-audit before callback.
- `/flywheel:learn --bead-quality-mining` runs
  `.flywheel/scripts/bead-quality-mining.sh --repo <repo> --json`.
- The miner inspects closed beads from the last 48h, parses acceptance gates,
  derives mechanical checks for paths, doctor signals, and skipped tests, then
  creates parented audit-gap beads for unverified gates.
- Closed bead notes get
  `audit_status=full|partial|gap_pending; audit_run_at=<ts>; gap_beads=<ids>`.
- `flywheel-loop doctor --repo <repo> --json` MUST expose
  `closed_bead_audit_pending_count`, `closed_bead_audit_gap_count`, and
  `audit_gap_top_classes`; pending count greater than 2 is a failing signal.

**Forbidden outputs:**
- Closing, summarizing, or routing a worker callback that lacks DID/DIDNT/GAPS
  fields.
- Reporting `didnt=none` or `gaps=none` before auditing every assigned
  acceptance gate.
- Treating a closed bead with missing artifacts, missing doctor signals,
  skipped tests, or non-derivable gates as fully validated without an audit note
  or gap bead.
- Running closed-bead mining repeatedly and creating duplicate audit-gap beads
  for the same original bead and gate.

**Evidence:** bead `flywheel-7yic`; script
`.flywheel/scripts/bead-quality-mining.sh`; tests
`tests/bead-quality-mining.sh`; command docs
`~/.claude/commands/flywheel/worker-tick.md`,
`~/.claude/commands/flywheel/_shared/dispatch-template.md`, and
`~/.claude/commands/flywheel/learn.md`.

**Companion rules:** L52 (beads or no-bead receipt), L53 (fuckups reported in
callbacks), L56 (promotion ladder), L60 (doctor signal contract), L70 (no
punt), and L71 (validate-and-redispatch discipline).

