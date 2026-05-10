---
title: flywheel-jloib decomposition receipt
type: decomposition-receipt
parent_bead: flywheel-jloib
priority: P1
worker: MistyCliff (flywheel:0.4)
date: 2026-05-10
sister_pattern: wzjo9 (4-wave decomposition; closed)
---

# flywheel-jloib Decomposition Receipt

**Mode:** DECOMPOSITION-ONLY (no implementation; sub-bead filing only)

## Inventory snapshot

Source: `.flywheel/audit/flywheel-cli-inventory/inventory.jsonl` (405 rows, from flywheel-c3w4h)

| Filter | Count |
|---|---|
| Total rows | 405 |
| ownership=own | 394 |
| ownership=jeff-stack-orchestrated | 11 (excluded — upstream issues, not patches) |
| **own + P0 + missing** | **42** |
| **own + P0 + partial** | **101** |
| own + P0 + passing | 9 (excluded — already meets baseline) |
| own + P1 + passing | 118 (excluded — already meets baseline) |
| own + P1 + missing/partial | 0 |
| **TOTAL IN SCOPE** | **143** |

## Wave decomposition (5 waves, 143 surfaces)

| Wave | Bead ID | Filter | Surfaces | Apply-spec |
|---|---|---|---|---|
| 1 | `flywheel-ok1sk` | P0 missing × non-general lanes | 21 | wave-1-apply-spec.md |
| 2 | `flywheel-ni92d` | P0 missing × general lane | 21 | wave-2-apply-spec.md |
| 3 | `flywheel-5ke66` | P0 partial × non-general lanes | 27 | wave-3-apply-spec.md |
| 4 | `flywheel-k8gcv` | P0 partial × general lane (split A) | 37 | wave-4-apply-spec.md |
| 5 | `flywheel-1hshd` | P0 partial × general lane (split B) | 37 | wave-5-apply-spec.md |
| **TOTAL** | | | **143** | |

All 5 wave beads created with `priority=P0 type=task` and `parent-child` dep
linking back to `flywheel-jloib`.

## Lane distribution per wave

### Wave 1 (P0 missing × non-general, 21 surfaces)
- jeff-corpus: 4
- doctrine: 4
- testing: 4
- recovery: 4
- beads: 2
- agent-mail: 2
- quality: 1

### Wave 2 (P0 missing × general, 21 surfaces)
- general: 21

### Wave 3 (P0 partial × non-general, 27 surfaces)
- jeff-corpus: 12
- capacity: 5
- orchestration: 2
- mission: 2
- doctrine: 2
- beads: 2
- testing: 1
- recovery: 1

### Wave 4 (P0 partial × general split A, 37 surfaces)
- general: 37 (alphabetic split A)

### Wave 5 (P0 partial × general split B, 37 surfaces)
- general: 37 (alphabetic split B)

## Decomposition rationale (natural-unit META-RULE)

Per the `feedback_decompose_by_natural_unit_not_bundle` META-RULE
(2026-05-10), every binary is a natural per-surface unit. Total scope of 143
surfaces exceeds bundle-tolerance — bundling forces over-tick or
refuse-decompose.

However, sister exemplars filed 4-8 sub-beads (wzjo9: 4 waves, 1fk5f: 8
sub-beads), not 143. The reconciling pattern from wzjo9 is **hierarchical
decomposition**: file wave-level parent beads now, defer per-binary sub-bead
filing until each wave is dispatched (matching `wzjo9.1 → wzjo9.1.{1..9}`).

Therefore this receipt files **5 wave beads**, each with an apply-spec naming
all in-scope binaries and the per-binary AG3 acceptance gate. At wave
dispatch, the worker will file N per-binary sub-beads (matching the
established `wzjo9.1.{1..9}` and `1fk5f.{1..8}` patterns).

## Why 5 waves and not 4 or 8

- **Status × lane is the natural axis.** Missing surfaces have heaviest
  per-binary lift (full scaffold + 18-marker fillin). Partial surfaces are
  lighter (gap-fill only). Splitting by status keeps wave-level effort
  estimates honest.
- **General lane dominates.** 95 of 143 surfaces are in the general lane.
  Forcing all into one wave creates a single 95-surface bead — refuse-
  decompose problem. Splitting general into 2 alphabetic halves (37+37)
  produces evenly-sized waves.
- **Non-general lanes group naturally by wave.** 7 lanes for missing × 8
  lanes for partial would explode bead count to 15 if filed per lane.
  Bucketing all non-general lanes into one wave per status (1 + 3) is the
  parsimonious shape.

## Sister-exemplar comparison

| Sister | Surfaces | Sub-beads filed | Status when closed |
|---|---|---|---|
| wzjo9 | 37 | 4 wave beads (decomposition-only); wzjo9.1 expanded to 9 sub-beads | parent closed |
| 1fk5f | 8 | 8 per-surface sub-beads (no wave layer needed at 8 surfaces) | 8/8 closed avg 974 |
| wgitr | 8 | 8 per-surface sub-beads | parent in_progress |
| **jloib** | **143** | **5 wave beads (this receipt)** | **closing this tick** |

## Helper primitives consumed (per wave apply-spec)

All 4 helper beads CLOSED before this decomposition tick:
- `flywheel-c3w4h`: inventory enumeration → produces `inventory.jsonl` filter source
- `flywheel-tiugg`: `canonical-cli-helpers.sh` drop-in lib
- `flywheel-ws02m`: `scaffold-canonical-cli.sh` parametric scaffolder
- `flywheel-etp5n`: `canonical-cli-lint.sh` violation detector
- `flywheel-3wxzi`: pilot refactor proving lib savings

## Boundary (echoing parent apply-spec)

- own-binaries only (jeff-stack 11 surfaces excluded — upstream issues per
  parent boundary)
- baseline only — doctor-mode hardening is bead 3 (`doctor-mode-integration-3`,
  not yet filed)
- one commit per binary; one PR per binary unless <20 lines single file
  (AGENTS.md exemption)
- inventory.jsonl row update is part of per-binary acceptance, not optional

## L112 verify probe

```bash
# 1. All 5 wave beads exist with parent-child link
for ID in flywheel-ok1sk flywheel-ni92d flywheel-5ke66 flywheel-k8gcv flywheel-1hshd; do
  br dep list "$ID" --json | jq -e --arg id "$ID" \
    '. | any(.issue_id == $id and .depends_on_id == "flywheel-jloib" and .type == "parent-child")'
done
# expected: true × 5

# 2. All 5 apply-specs exist and have ≥21 surface rows
for W in 1 2 3 4 5; do
  test -f .flywheel/audit/flywheel-jloib/wave-${W}-apply-spec.md && \
    grep -c '^| [0-9]' .flywheel/audit/flywheel-jloib/wave-${W}-apply-spec.md
done
# expected: 21 21 27 37 37

# 3. Sum equals 143
expr 21 + 21 + 27 + 37 + 37
# expected: 143
```

## Mission fitness

Class: **adjacent**. The decomposition itself doesn't ship canonical-cli
baselines (the parent goal); it sets up the dispatch surface so subsequent
worker ticks can ship them in parallel without re-doing the bucketing
analysis.
