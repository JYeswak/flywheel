---
title: "Phase 4 Decomposition — Agent Security Controls Fleet-Wide"
type: plan
created: 2026-05-08
frontmatter_source: scaffold-doc-frontmatter
---

# Phase 4 Decomposition — Agent Security Controls Fleet-Wide

Bead: `flywheel-cnw0`
Task: `flywheel-cnw0-b9e30d`
Plan source: `/Users/josh/Developer/flywheel/.flywheel/PLANS/agent-security-controls-fleet-wide-2026-05-04/00-PLAN.md`
Generated: 2026-05-08T17:45Z

## Created Beads

| Plan node | Bead | Priority | Title |
|---|---|---:|---|
| B01 | `flywheel-m0v31` | P0 | `fix(security-contract): define agent-security-control/v1 and canonical deny template` |
| B02 | `flywheel-oxr6e` | P0 | `fix(security-scanner): define synthetic pattern corpus and redacted scanner` |
| B03 | `flywheel-vl9of` | P0 | `fix(security-propagation): extend ft04 sync for settings deny rollout receipts` |
| B04 | `flywheel-qegt3` | P0 | `fix(security-doctor): expose security posture signals in flywheel-loop doctor` |
| B05 | `flywheel-98t5l` | P1 | `fix(security-promotion): route security doctor drift to beads and daily report` |
| B06 | `flywheel-x3n1n` | P0 | `fix(security-fixtures): standardize .env.test and runtime-output safety` |
| B07 | `flywheel-1w0ep` | P0 | `fix(security-hooks): install committed secret pre-commit dispatcher` |
| B08 | `flywheel-mzvd0` | P1 | `fix(security-sandbox): define prod-credential container isolation profile` |
| B09 | `flywheel-1gyiv` | P0 | `fix(security-e2e): run conformance harness and fleet dry-run smoke` |
| B10 | `flywheel-03uki` | P1 | `fix(security-doctrine): wire L74, README, skill draft, and canonical paths` |

Every created bead body references the plan source path above.

## Dependencies

Forward-only DAG, matching the converged plan:

```text
B01 -> B03
B01 -> B04
B02 -> B04
B03 -> B04
B04 -> B05
B02 -> B06
B02 -> B07
B02 -> B08
B03 -> B09
B04 -> B09
B06 -> B09
B07 -> B09
B08 -> B09
B05 -> B10
B09 -> B10
```

Implemented with `br dep add <issue> <depends-on>`, where the left side depends on the right side.

## Verification

Required checks:

```bash
br dep cycles --json
# {"cycles":[],"count":0}
```

```bash
for id in flywheel-m0v31 flywheel-oxr6e flywheel-vl9of flywheel-qegt3 flywheel-98t5l flywheel-x3n1n flywheel-1w0ep flywheel-mzvd0 flywheel-1gyiv flywheel-03uki; do
  br show "$id" | rg -q '/Users/josh/Developer/flywheel/.flywheel/PLANS/agent-security-controls-fleet-wide-2026-05-04/00-PLAN.md'
done
# 10
```

`br show flywheel-cnw0` was OPEN before this artifact was created, satisfying the open-until-evidence gate.

## Socraticode

- Queries run: 3
- Canonical project path: `/Users/josh/Developer/flywheel`
- Indexed chunks observed: 1469

## Close Decision

`flywheel-cnw0` can close after cycle validation because the converged plan is now represented as executable beads, dependency wiring is cycle-free, and this plan artifact records the created bead IDs, edges, checks, and source plan path.
