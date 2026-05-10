---
title: "Mission-Lock Scaffold Validator Implementation"
type: plan
created: 2026-05-06
frontmatter_source: scaffold-doc-frontmatter
---

# Mission-Lock Scaffold Validator Implementation

Date: 2026-05-06
Bead: `flywheel-mission-lock-scaffold-validator-2026-05-06`
Wave: Phase 4 Wave 3 #2

## Scope

This implementation adds a read-only markdown-aware validator for
`.flywheel/MISSION.md` files. It does not modify `.flywheel/MISSION.md`, Wave 1
amendments, or the Wave 2 output schema. The Wave 2 JSON Schema remains the
machine contract for structured mission-lock output; this validator checks the
markdown scaffold that carries the lock in repo-local docs.

## Shipped Artifacts

- Validator: `.flywheel/scripts/mission-lock-scaffold-validator.sh`
- Golden test: `.flywheel/tests/test_mission_lock_scaffold_validator.sh`

The validator exposes five canonical verbs:

- `validate`
- `doctor`
- `health`
- `audit`
- `schema`

It also exposes the shared helper flags `--info`, `--help`, `--examples`,
`--json`, and `--quiet`, matching the sibling output-schema validator.

## Per-Finding Mitigation

| ID | Finding pressure | Mitigation |
|---|---|---|
| SEC-005 | Mission-lock must prove touched surfaces name least-privilege principal metadata before readiness. | The scaffold validator requires a non-empty `Negative invariants (security)` section and checks the required lock section set before downstream readiness-doctor work can treat the markdown as scaffold-complete. Semantic SEC-005 field validation stays with the Wave 2 JSON Schema and the security negative-invariants validator. |
| IDEM-006 | Scaffold/readiness receipts need lock hash and section hashes before any future apply mode can be replay-safe. | The validator reports `lock_hash_observed`, validates embedded `section_hash` comments when present, and documents a deterministic SHA-256 section-hash algorithm. It remains read-only and returns `incomplete` when optional hash or substrate sections are absent rather than inventing receipts. |

## Required Sections

The validator requires these current repo-local mission sections:

- `Mission Source`
- `North-Star Outcome`
- `Primary Beneficiary`
- `Explicit Non-Goals`
- `Safety And Privacy Boundaries`
- `Evidence That Would Change The Mission`
- `Owner-Review Cadence`
- `Lock Receipt`
- `Negative invariants (security)`

`Substrate inventory` is validated when present. It is not made a hard required
section in this bead because existing mission locks predate the substrate
inventory scaffold; the downstream readiness doctor owns policy for turning a
missing inventory into a blocked launch/readiness state.

## Hash Algorithm

Embedded section hashes use this comment shape:

```markdown
<!-- section_hash: Mission Source sha256:<64 hex> -->
```

For each embedded hash, the validator:

1. Finds the matching `## <section>` body.
2. Removes any `section_hash` comments.
3. Trims leading and trailing blank lines.
4. Joins with LF line endings.
5. Appends one final LF.
6. Computes SHA-256 over the resulting UTF-8 bytes.

This keeps hashes stable across comment placement and avoids hashing the receipt
that records the hash.

## Substrate Inventory

When a `## Substrate inventory` section exists, the validator extracts markdown
links, backtick-wrapped paths, and simple bullet `key: path` entries. Pointers
resolve relative to the mission file directory, repo root, or current working
directory. Unresolved pointers block the validator.

When the section is absent, `substrate_inventory_resolves` returns `skip`; that
produces `verdict=incomplete` only when all blocking checks pass.

## Readiness-Doctor Integration

Wave 3 readiness-doctor can consume this validator without reparsing markdown:

- `checks.required_sections_present`
- `checks.section_hashes_match`
- `checks.substrate_inventory_resolves`
- `checks.negative_invariants_non_empty`
- `checks.blocked_readiness_states[]`
- `lock_hash_observed`
- `details.required_sections`
- `details.substrate_pointers`

Recommended downstream rule: readiness doctor treats `blocked` as fail-closed,
`incomplete` as a legacy/backfill state with scaffold-bead suggestions, and
`ready` as scaffold-complete enough for the next readiness gates.

## Validation

Primary test:

```bash
bash .flywheel/tests/test_mission_lock_scaffold_validator.sh
```

Dispatch L112 gate:

```bash
test -x /Users/josh/Developer/flywheel/.flywheel/scripts/mission-lock-scaffold-validator.sh && \
  bash /Users/josh/Developer/flywheel/.flywheel/scripts/mission-lock-scaffold-validator.sh --info > /dev/null 2>&1 && \
  bash /Users/josh/Developer/flywheel/.flywheel/tests/test_mission_lock_scaffold_validator.sh > /dev/null 2>&1 && \
  test -f /Users/josh/Developer/flywheel/.flywheel/plans/mission-lock-paradigm-extension-2026-05-06/impl/mission-lock-scaffold-validator-impl.md && \
  grep -q "Phase 4 Wave 3 #2 shipped: mission-lock scaffold validator" /Users/josh/Developer/flywheel/INCIDENTS.md && \
  echo OK_wave3_mission_lock_scaffold_validator_shipped
```
