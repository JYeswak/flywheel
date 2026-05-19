---
title: "Mission-Fidelity Substrate"
type: doctrine
created: 2026-05-08
frontmatter_source: scaffold-doc-frontmatter
---

# Mission-Fidelity Substrate

## Status

Canonical Stage B doctrine. Ratified from skillos:1 handoff
`2026-05-09T035705Z-from-skillos-1-mission-fidelity-substrate-and-l70-doctrine-canonical-ratification.md`.

## Pattern

Each flywheel-installed repo can declare structured mission claims in
`.flywheel/MISSION.md` frontmatter:

```yaml
mission_claims:
  - id: continuous-worker-productivity
    claim: The repo keeps worker capacity productively filled.
    evidence:
      - .flywheel/scripts/idle-pane-auto-dispatch.sh
      - .flywheel/scripts/l70-ticks-punted-counter.sh
    invariant: idle panes with ready unblocked work dispatch same tick
```

The substrate has four portable parts:

1. A mission-claim parser emits `skillos.mission_claim.v1` artifacts from
   `MISSION.md` frontmatter.
2. A `mission-claim-coverage` doctor invariant flags claims without wired
   evidence or validation commands.
3. An audit-to-pack-feedback bridge converts unwired claims into durable work
   rows for the dispatch loop.
4. A per-repo monitor runs the invariant at tick cadence so mission drift is
   detected during operation.

## Why

Mission drift is usually discovered during review, after the loop has already
spent hours or days operating from stale assumptions. This substrate turns
mission claims into executable feedback. Donella rank-4 self-organization is
the bar: the system generates corrective work from its own stated mission.

## Doctor Invariant

`mission-claim-coverage` must report:

- `mission_claim_count`
- `mission_claim_unwired_count`
- `mission_claim_unwired[]` with claim id, missing evidence, and suggested
  bead body
- `mission_claim_artifact_schema="skillos.mission_claim.v1"`
- `status=fail` when required claims have no wired evidence

Repos may stage this as `warn` during initial adoption, but production loops
must promote unwired required claims to `fail`.

## Audit-To-Pack-Feedback Bridge

Unwired claims should not disappear into prose. The bridge writes durable rows
with:

- source claim id
- source mission file path
- missing evidence path or missing invariant
- suggested owner surface
- bead-ready remediation text

The dispatch loop consumes those rows as candidate beads. This closes the delay
between "mission says this matters" and "the loop created work to protect it."

## Stage B Propagation

Stage B is propagation only:

- Add this doctrine pointer to client orchs.
- Ask each repo to declare its own mission claims.
- Ask each repo to run a parser/doctor dry-run before wiring hard gates.
- Add L70 ORCH-NO-PUNT doctrine and detector awareness.

Stage C hardens the substrate after the known durability risks are mitigated:

- canonical-files manifest so closeout auto-commits cannot delete substrate
  files without explicit override
- dispatch ID to bead-DB ID reconciliation before client repos inherit the
  callback-grade-dispatch-required divergence class

## Validation

For flywheel Stage B:

```bash
test -f .flywheel/doctrine/mission-fidelity-substrate.md
.flywheel/scripts/punt-phrase-detector.py doctor --repo "$PWD" --json
.flywheel/scripts/punt-phrase-detector.py scan --repo "$PWD" --json
```

## Four-Lens Self-Grade

four_lens=brand:8,sniff:8,jeff:8,public:8

Three Judges check: a skeptical operator can see the parser/doctor/bridge
contract, a maintainer can defer Stage C hardening without losing Stage B
propagation, and a future worker can turn unwired mission claims into beads.



## Meta-Learning Cross-References (2026-05-19)

This doctrine surface was backfilled during JSM fleet audit batch-3 so recent doctrine cites the relevant MP lessons directly.

- **MP-09 — info-source watchtower:** see `/Users/josh/Developer/skillos/.flywheel/doctrine/meta-learnings/MP-09-info-source-watchtower.md` for the canonical pattern.
- **MP-13 — living documentation:** see `/Users/josh/Developer/skillos/.flywheel/doctrine/meta-learnings/MP-13-living-documentation.md` for the canonical pattern.
- **MP-28 — checklist before claim:** see `/Users/josh/Developer/skillos/.flywheel/doctrine/meta-learnings/MP-28-checklist-before-claim.md` for the canonical pattern.
