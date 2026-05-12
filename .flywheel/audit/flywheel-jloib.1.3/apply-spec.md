---
title: dispatch lane wave 3 (tail) — canonical-cli scaffold for final 8 P0 surfaces
type: apply-spec
created: 2026-05-10
bead: flywheel-jloib.1.3 (alias flywheel-6k36c)
parent: flywheel-jloib (canonical-baseline)
chain: doctor-mode-integration / lane-work
---

# Dispatch lane wave 3 (tail) — canonical-cli scaffold

Closes the dispatch lane. Wave 1 (yw63j) + wave 2 (war3i) shipped 16
of 24 P0 surfaces; this bead handles the final 8 (the ntm-* tail).

## Eight target surfaces (the dispatch-lane tail)

1. `.flywheel/scripts/ntm-pipeline-shadow.sh`
2. `.flywheel/scripts/ntm-preflight-l91-wrapper.sh`
3. `.flywheel/scripts/ntm-safety-dcg-sibling.sh`
4. `.flywheel/scripts/ntm-scrub-secret-scan-wrapper.sh`
5. `.flywheel/scripts/ntm-surface-coverage-trend.sh`
6. `.flywheel/scripts/ntm-surface-validation-driver.sh`
7. `.flywheel/scripts/ntm-wave2-native-probes.sh`
8. `.flywheel/scripts/pre-dispatch-state-db-lock-check.sh`

## Method

Same as waves 1+2: scaffold-only, TODO fill-in deferred to followup bead.

## Acceptance gate

- All 8 surfaces canonical-cli 13/13 PASS
- All 8 lint clean (target zero variance per wave-2 precedent)
- 8 inventory rows stamped → canonical_cli_scoping_status: passing
- Backward compat preserved
- Single batched commit

## Boundary

- ONLY 8 surfaces. Closes dispatch lane.
- TODO fill-in goes to followup bead (will be filed at close).
- After this lands: dispatch lane = 0 P0 remaining (all moved to P1 with stub doctor).

## Estimated effort

~2-5 min wall clock based on wave 1/2 precedent.

## Dependencies

- yw63j (wave 1) — CLOSED (8 surfaces)
- war3i (wave 2) — CLOSED (8 surfaces)
- Tooling chain (jloib.0a/0b/0c/0d, b9dfv, pfjkw) — CLOSED

## Goal

See body above.

## Acceptance gate

See body above.
