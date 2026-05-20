---
title: "/tmp Lifecycle Doctrine"
type: doctrine
created: 2026-05-07
frontmatter_source: scaffold-doc-frontmatter
---

# /tmp Lifecycle Doctrine

owner_bead: flywheel-2bd2r
schema_version: tmp-lifecycle-doctrine/v1
status: canonical

## Purpose

`/private/tmp` is an accreting substrate, not an infinite scratch drawer. The
2026-05-08 storage emergency hit 1.6% free with 18,041 tmp entries; Layer 2
aggressive prune reclaimed 18 GiB in commit `2c21355`, but cleanup after the
fact is only one layer. The lifecycle must also prevent new workers from
writing unowned, unclosed scratch.

## Four Layers

### Layer 1: Worker Scratch Convention

Every worker creates exactly one scratch directory:

```bash
WORK_TMP="$(mktemp -d -t <bead-short-id>.XXXXXX)"
```

All scratch files stay under `WORK_TMP`. Durable evidence is copied to the
dispatch-specified repo receipt or sanctioned state path before close. Bare
task-shaped artifacts such as `/private/tmp/<bead-id>-evidence.md`,
`/private/tmp/<bead-short-id>-audit.json`, or equivalent `/tmp`/`/var/tmp`
paths are invalid. The callback validator blocks these as
`tmp_evidence_outside_mktemp_dir`.

Dispatch templates enforce the convention at authoring time so workers receive
the pattern before they start writing.

### Layer 2: Default-Aggressive Prune

Layer 2 is already shipped and must not be reimplemented here:

- Script: `.flywheel/scripts/tmp-aggressive-prune.sh`
- Commit: `2c21355`
- Behavior: dry-run by default; apply requires an idempotency key; deny-lists
  system paths and active scratch while pruning stale top-level tmp entries.
- First apply receipt: reclaimed roughly 18 GiB and reduced tmp entries from
  18,048 to 12,478.

This layer drains historical and missed cleanup. It does not replace worker
close discipline.

### Layer 3: Worker Close Gate

DONE callbacks must include:

```text
tmp_dir_released=true
```

The close validator blocks missing or false values as
`tmp_dir_not_released`. `br close` is not allowed until scratch cleanup has
already happened, the same way file reservations must be released before a
worker reports DONE. BLOCKED callbacks may report `tmp_dir_released=false`
only when preserving the scratch directory is part of the blocker evidence.

The canonical taxonomy class is:

```text
failure_class=tmp_dir_not_released
retry_policy=manual
recovery_hint="rm -rf $TMPDIR/<bead-id>.* && re-run br close"
```

### Layer 4: Doctor Invariant

`flywheel-loop doctor` exposes `/private/tmp` entry count through
`.storage.tmp_entry_count`:

- `<=5000`: ok
- `>5000`: warn
- `>10000`: critical; doctor status fails and halt-on-breach consumers stop
  growth work.

The invariant is count-based because the emergency was a blindness failure:
disk pressure was visible only after free space fell through the floor. Axiom
10 applies here: every accreting surface needs a cheap stock measurement.

## Joshua Lens

PASS. This is operator-experience depth, not generic mission fit. `/tmp`
lifecycle is the silent ops disaster: a 25-year operations manager knows every
accreting surface gets retention-by-default or the team accepts the next floor
breach. The 18,041-entry blindness proves doctrine without invariants is
theater; the runbook needs convention, prune, close gate, and doctor stock
measurement together.

## Acceptance Mapping

- Layer 1: dispatch templates require `mktemp -d -t <bead-short-id>.XXXXXX`;
  validator rejects loose `/tmp` evidence.
- Layer 2: referenced as shipped in `2c21355`; script remains read-only here.
- Layer 3: validator requires `tmp_dir_released=true`; taxonomy adds
  `tmp_dir_not_released`.
- Layer 4: doctor exposes tmp entry count with warn and critical thresholds;
  fixture coverage creates 11,001 synthetic entries and verifies critical.

Mission-anchor: continuous-orchestrator-uptime-self-sustaining-fleet.


## Meta-Learning Cross-References (2026-05-19)

This doctrine surface was backfilled during JSM fleet audit batch-3 so recent doctrine cites the relevant MP lessons directly.

- **MP-17 — secret emission discipline:** see `/Users/josh/Developer/skillos/.flywheel/doctrine/meta-learnings/MP-17-secret-emission-discipline.md` for the canonical pattern.
- **MP-29 — production safety guardrails:** see `/Users/josh/Developer/skillos/.flywheel/doctrine/meta-learnings/MP-29-production-safety-guardrails.md` for the canonical pattern.
- **MP-30 — human-gated invasiveness:** see `/Users/josh/Developer/skillos/.flywheel/doctrine/meta-learnings/MP-30-human-gated-invasiveness.md` for the canonical pattern.
