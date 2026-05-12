---
title: recovery lane wave 1 — canonical-cli scaffold for 8 P0 surfaces
type: apply-spec
created: 2026-05-10
bead: flywheel-jloib.2.1
parent: flywheel-jloib (canonical-baseline) / flywheel-wzjo9 (recovery decomposition)
chain: doctor-mode-integration / lane-work
---

# Recovery lane wave 1 (8 surfaces)

First sub-wave of the 37-surface recovery lane. Same scaffold-only
pattern proven by dispatch waves 1+2 (yw63j, war3i — 8 surfaces each
in 2-3 min wall clock).

## Eight target surfaces

1. `.flywheel/scripts/cross-skill-dependency-probe.sh`
1. `.flywheel/scripts/flywheel-recovery.sh`
1. `.flywheel/scripts/handoff-skill-to-skillos.sh`
1. `.flywheel/scripts/recovery-doctor-probe.sh`
1. `.flywheel/scripts/recovery-escape-then-reprompt.sh`
1. `.flywheel/scripts/recovery-restore-harness.sh`
1. `.flywheel/scripts/skill-bandit-measurement-probe.sh`
1. `.flywheel/scripts/skill-enhance-jsm-discipline.sh`

## Method

Same as dispatch waves 1+2:
1. `scaffold-canonical-cli.sh <target> --apply --idempotency-key <surface>-jloib.2.1-2026-05-10`
2. Lint clean
3. Test 13/13 canonical-cli + 15/15 regression
4. Inventory.jsonl row updated → canonical_cli_scoping_status: passing
5. Single batched commit

## Acceptance gate

- 8/8 surfaces canonical-cli 13/13 PASS
- 8/8 lint clean
- 8 inventory rows stamped
- Backward compat preserved
- Single batched commit

## Boundary

- ONLY 8 surfaces.
- TODO fill-in deferred to followup bead.

## Estimated effort

~2-5 min wall clock per dispatch-wave precedent.

## Goal

See body above.

## Acceptance gate

See body above.
