---
title: doctrine lane wave 1 — canonical-cli scaffold for 4 P0 doctrine surfaces
type: apply-spec
created: 2026-05-10
parent: flywheel-jloib (canonical-baseline)
chain: doctor-mode-integration / doctrine-lane
---

# Doctrine lane wave 1 (4 surfaces)

First doctrine-lane batch using the proven tooling chain (helper lib v1.1
+ post-x4e3s scaffolder + linter). Doctrine surfaces are high-leverage —
other agents read doctrine to align behavior, so canonical-cli on
doctrine surfaces makes the substrate self-describing.

## Four target surfaces (all P0, all bash)

1. `.flywheel/scripts/doctrine-broadcast-send.sh`
2. `.flywheel/scripts/doctrine-ladder-promote.sh`
3. `.flywheel/scripts/doctrine-sync.sh`
4. `.flywheel/scripts/test-sync-canonical-doctrine.sh`

## Method (per surface)

Use the proven 6-step flow with the post-x4e3s clean scaffolder:

1. **Scaffold**: `.flywheel/scripts/scaffold-canonical-cli.sh <target> --apply --idempotency-key <surface>-doctrine-w1-2026-05-10`
2. **Fill TODOs**: ~30-60 min per surface for substantive doctor/health/repair/validate/why
3. **Lint**: `canonical-cli-lint.sh <target>` — must report zero violations
4. **Test**: scaffolded `tests/<basename>-canonical-cli.sh` — fill in the deferred per-surface assertions
5. **Canonical-CLI checker**: 13/13 PASS via the symlinked-PATH probe
6. **Commit per surface**: one commit per surface, conventional message

Per the wgitr decomposition learning: if any surface's fillin >90 min,
abort and file a sub-bead.

## Acceptance gate

For all 4 surfaces:
- canonical-cli-scoping checker 13/13 PASS
- canonical-cli-lint.sh: zero violations
- regression test: ≥15 assertions, all-pass
- doctor subcommand returns valid envelope on real substrate
- repair --apply gated by --idempotency-key (refuses bare --apply with exit 3)
- backward compat: existing flag invocations continue to work
- one commit per surface
- inventory.jsonl row updated:
  `canonical_cli_scoping_status` → `passing`
  `doctor_subcommand_status` → `basic` or `upgraded`

## Boundary

- ONLY 4 surfaces in this bead. Don't pull P2 doctrine surfaces (drift-trend,
  surface-divergence-probe) — those go in wave 2 if needed.
- If any surface's fillin >90 min, abort and file sub-bead per wgitr learning.
- Each surface ships as its own commit so reverts are surface-scoped.

## Estimated effort

~3-5 hours total:
- 4 × 30-60 min per surface (scaffold + fill + test + commit)
- + 30 min for inventory.jsonl row updates
- + 30 min for receipt + bead close

## Dependencies

- jloib.0a/0b/0c/0d, b9dfv, x4e3s (tooling chain + scaffolder fix) — all CLOSED
- s8tdd (fs-rag-discipline) — CLOSED
