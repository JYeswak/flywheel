---
title: recovery lane wave 2 — canonical-cli scaffold for 8 P0 surfaces
type: apply-spec
created: 2026-05-10
bead: flywheel-jloib.2.2
parent: flywheel-jloib (canonical-baseline) / flywheel-wzjo9 (recovery decomposition)
chain: doctor-mode-integration / lane-work
---

# Recovery lane wave 2 (8 surfaces)

Continues the 37-surface recovery lane decomposition.

## Eight target surfaces (alphabetical 9-16)

1. `.flywheel/scripts/skillos-routed-tail.sh`
1. `.flywheel/scripts/test-auto-respawn.sh`
1. `.flywheel/scripts/test-skillos-bridge.sh`
1. `.flywheel/scripts/worker-auto-respawn-watchdog-install.sh`
1. `.flywheel/scripts/worker-auto-respawn-watchdog.sh`
1. `/Users/josh/.claude/commands/flywheel/_shared/inject-skill-auto-routes.sh`
1. `/Users/josh/.claude/skills/.flywheel/bin/auto-respawn-detector.sh`
1. `/Users/josh/.claude/skills/.flywheel/bin/flywheel`

## Method

Same as proven dispatch-lane scaffold pattern (yw63j, war3i, 6k36c
each landed in 1.5-3 min wall clock, 8 surfaces each).

1. `scaffold-canonical-cli.sh <target> --apply --idempotency-key <surface>-jloib.2.2-2026-05-10`
2. Lint clean
3. Test 13/13 + 15/15
4. Inventory.jsonl row updated
5. Backward compat smoke

## Acceptance gate

- 8/8 canonical-cli 13/13
- 8/8 lint clean (or ≤1 documented variance)
- 8 inventory rows stamped
- Single batched commit

## Boundary + Estimated effort

ONLY 8 surfaces. ~2-5 min wall clock.

## Goal / Acceptance gate

See body above.
