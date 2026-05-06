# Flywheel Repo-Local Doctrine Index

This file exists as a repo-local `.flywheel/` doctrine artifact for acceptance
gates and artifact scanners that require evidence inside `.flywheel/`.

Canonical doctrine remains `../AGENTS.md`; the fleet propagation snapshot is
`.flywheel/AGENTS-CANONICAL.md`.

## L79 — STORAGE-OVERRIDE-RECEIPTS-ARE-MECHANICAL

---
id: L79
title: Storage override receipts are mechanical
status: long_term
shipped: 2026-05-04
review_due: 2026-11-04
trauma_class: manual-storage-threshold-override
canonical_source: ../AGENTS.md#L79
---

Joshua-disposed storage threshold exceptions MUST be represented as
`storage-override/v1` receipts, not as prose or one-off environment tweaks.
`flywheel-loop doctor` is the gate owner: it reads active receipts, applies the
lowest valid temporary threshold, exposes override counters, fails closed when
no active receipt applies, and appends `STORAGE-CLEARED` when storage recovers
above the base threshold.

**How to apply:**
- Receipt schema lives at
  `.flywheel/validation-schema/v1/storage-override.schema.json`.
- Active receipts live under
  `~/.local/state/flywheel/storage-overrides/*.json`; event rows live in
  `~/.local/state/flywheel/storage-overrides/events.jsonl`.
- `flywheel-loop doctor --json` MUST expose top-level
  `storage_override_active_count` and `storage_override_expiring_in_min`, plus
  `.storage_override.effective_min_free_pct`.
- `flywheel-loop doctor --storage-min-free-pct N` and
  `FLYWHEEL_STORAGE_MIN_FREE_PCT=N` are explicit base-threshold controls; active
  receipts may only lower the gate temporarily and must expire.
- `sync-canonical-doctrine.sh --apply` propagates the storage override schema to
  flywheel-installed repos alongside canonical doctrine.

**Evidence:** bead `flywheel-vso8`; audit-gap repair bead `flywheel-vso8.2`;
schema `.flywheel/validation-schema/v1/storage-override.schema.json`; tests
`tests/storage-override.sh`; receipts
`~/.local/state/flywheel/storage-overrides/`.

**Companion rules:** L60 (doctor signal contract), L61 (wire-in), L70 (chain
repair), L71 (validate every surface), L72 (storage discipline), and L77 (daily
report surfaces).

## L80 — CLOSED-BEAD-AUDIT-MINING

---
id: L80
title: Closed bead audit mining
status: long_term
shipped: 2026-05-04
review_due: 2026-11-04
trauma_class: closed-bead-quality-drift
canonical_source: ../AGENTS.md#L80
---

Closed bead closure is no longer a prose trust event. A worker callback that
says DONE becomes eligible for orchestrator closeout only after the closed-bead
mining probe validates the bead acceptance gates, or after each missing gate has
a linked gap bead, updated bead, or explicit no-bead receipt.

**How to apply:**
- Worker callbacks use the canonical `DID/DIDNT/GAPS` shape so downstream
  mining can distinguish completed gates, intentionally uncompleted gates, and
  discovered repair work.
- `.flywheel/scripts/bead-quality-mining.sh` scans recently closed beads and
  classifies missing artifact evidence, unwired doctor signals, skipped tests,
  absent doctrine, and ambiguous gate language.
- `flywheel-loop doctor --json` MUST expose
  `closed_bead_audit_pending_count`, `closed_bead_audit_gap_count`, and
  `audit_gap_top_classes`.
- The orchestrator closes or integrates a worker result only after the mining
  probe verifies all acceptance gates or the callback names the carry-forward
  gap/no-bead receipt.
- `sync-canonical-doctrine.sh --apply` is the fleet propagation mechanism for
  the canonical L80 entry and sibling doctrine snapshots.

**Evidence:** parent bead `flywheel-7yic`; repair bead `flywheel-g1sn`; mining
probe `.flywheel/scripts/bead-quality-mining.sh`; tests
`tests/bead-quality-mining.sh`; canonical docs
`~/.claude/commands/flywheel/worker-tick.md`,
`~/.claude/commands/flywheel/_shared/dispatch-template.md`, and
`~/.claude/commands/flywheel/learn.md`.

**Companion rules:** L52 (beads or no-bead receipt), L53 (fuckups reported in
callbacks), L56 (promotion ladder), L60 (doctor signal contract), L70
(same-tick chain-forward), and L71 (validate-and-redispatch discipline).
