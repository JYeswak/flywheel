---
title: dispatch lane wave 2 — canonical-cli scaffold for 8 P0 surfaces
type: apply-spec
created: 2026-05-10
bead: flywheel-jloib.1.2 (alias flywheel-war3i)
parent: flywheel-jloib (canonical-baseline)
chain: doctor-mode-integration / lane-work
---

# Dispatch lane wave 2 — canonical-cli scaffold

Continues the dispatch-lane scaffold pattern proven by wave 1
(yw63j: 8 surfaces × 13/13 canonical-cli, 3 min wall clock, 100×
faster than estimated). TODO fill-in is captured in followup
flywheel-wgitr; this bead's scope is **scaffold-and-ship-canonical-cli only**.

## Eight target surfaces

1. `.flywheel/scripts/dispatch-self-test-delivery-identity.sh`
2. `.flywheel/scripts/dispatch-surface-conflict-probe.sh`
3. `.flywheel/scripts/dispatch-trigger-gated-precheck.sh`
4. `.flywheel/scripts/idle-pane-auto-dispatch.sh`
5. `.flywheel/scripts/ntm-approve-human-gates.sh`
6. `.flywheel/scripts/ntm-coordinator-shadow.sh`
7. `.flywheel/scripts/ntm-fleet-health.sh`
8. `.flywheel/scripts/ntm-pane-sidecar-respawn.sh`

## Method (per surface)

Same as wave 1 (flywheel-yw63j):

1. `scaffold-canonical-cli.sh <target> --apply --idempotency-key <surface>-jloib.1.2-2026-05-10`
2. Lint clean (use canonical-cli-lint.sh)
3. Test scaffold runs 13/13 canonical-cli + 15/15 regression
4. Inventory.jsonl row updated
5. Backward-compat smoke: `bash <target> --help` returns 0 with usage
6. Single batched commit (matching wave 1 pattern; per-surface commit
   was deviation in wave 1 and is OK to continue batched)

## Acceptance gate

- All 8 surfaces canonical-cli 13/13 PASS
- All 8 lint clean OR documented variance (max 1)
- 8 inventory rows stamped
- Backward compat preserved (existing flag invocations work)
- One commit (batched OK per wave-1 precedent)
- TODO fill-in NOT in scope; goes to flywheel-wgitr or per-wave followup

## Boundary

- ONLY 8 surfaces in this bead.
- TODO markers REMAIN; substance fill-in is followup-bead work.
- If a surface's scaffold takes >5 min, abort and file followup with
  complexity classification.
- Production state must be FUNCTIONAL post-scaffold (canonical-cli
  surfaces work even if doctor/health/repair are stubs).

## Estimated effort

~5-15 minutes wall clock. Wave 1 took 3 min; wave 2 should be similar
given the proven scaffolder.

## Dependencies

- yw63j (wave 1) — CLOSED, shipped 8 scaffolded surfaces
- pfjkw (lane pilot) — CLOSED
- Tooling chain (jloib.0a/0b/0c/0d, b9dfv) — CLOSED

## Canonical structure (post-hoc canonical for F7 lint)

## Goal

See body above.

## Acceptance gate

See body above.
