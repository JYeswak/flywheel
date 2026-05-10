---
title: dispatch lane wave 1 — canonical-cli + doctor-mode upgrade for 8 P0 surfaces
type: apply-spec
created: 2026-05-10
bead: flywheel-jloib.1.1
parent: flywheel-jloib (canonical-baseline)
chain: doctor-mode-integration / lane-work
---

# Dispatch lane wave 1 (8 surfaces)

First production wave of canonical-cli upgrade work using the proven
tooling chain (helper lib v1.1 + scaffolder + linter + pilot snapshot).

## Eight target surfaces

The 3 pilot targets (whose scaffolded snapshots are preserved at
`.flywheel/audit/flywheel-jloib.1.pilot/scaffolded-*.snapshot`) +
5 high-leverage dispatch-lane neighbors:

1. `.flywheel/scripts/build-dispatch-packet.sh` (315 lines → ~554 + fill-in)
2. `.flywheel/scripts/dispatch-and-log.sh` (108 → ~347 + fill-in)
3. `.flywheel/scripts/dispatch-author-contract-probe.sh` (~180)
4. `.flywheel/scripts/dispatch-canonical-cli-validator.sh` (212 → ~451 + fill-in)
5. `.flywheel/scripts/dispatch-deferral-lint.sh`
6. `.flywheel/scripts/dispatch-delivery-verify.sh`
7. `.flywheel/scripts/dispatch-log-backfill-v2.sh`
8. `.flywheel/scripts/dispatch-log-v2-violations-doctor.sh`

## Method (per surface)

Use the proven 6-step flow from pilot:

1. **Scaffold**: `.flywheel/scripts/scaffold-canonical-cli.sh <target> --apply --idempotency-key <surface>-jloib.1.1-2026-05-10`
   - For surfaces 1-3 (pilot trio), use the preserved snapshots as the
     starting point — they validated 13/13 — and fill in the TODO markers
     instead of re-scaffolding from scratch.
2. **Fill TODOs**: ~30-60 min per surface for the per-surface judgment
   work (cmd_doctor checks, cmd_repair scopes, cmd_validate logic,
   cmd_why provenance, topic-map sidecar)
3. **Lint**: `canonical-cli-lint.sh <target>` — must report zero violations
4. **Test**: scaffolded `tests/<basename>-canonical-cli.sh` — fill in
   the 2 deferred per-surface assertions to reach 15/15 target
5. **Canonical-CLI checker**: 13/13 PASS via the symlinked-PATH probe
6. **Commit per surface**: one commit per surface, conventional message

## Acceptance gate

For all 8 surfaces:
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
  `mutates_state` reaffirmed
  `priority` → `P1` if doctor-mode-tier still wants work, else closed-status

## Boundary

- ONLY 8 surfaces in this bead. Don't pull from wave 2 or 3.
- If a surface's fill-in exceeds 90 min, abort that surface and file a
  followup bead with the complexity classification.
- Production state must be FUNCTIONAL post-upgrade. The pilot deferred
  TODOs and reverted; this bead must FILL TODOs and SHIP.
- Each surface ships as its own commit so reverts are surface-scoped.

## Estimated effort

~5-8 hours total:
- 8 × 30-60 min per surface (scaffold + fill + test + commit)
- + 30 min for inventory.jsonl row updates
- + 30 min for receipt + bead close

The pilot proved scaffolding takes 1-2 min/surface. Fill-in is the
fixed cost (~30-60 min) — that's the per-surface judgment work the
helper lib intentionally doesn't cover.

## Dependencies

- jloib.0a/0b/0c/0d, b9dfv (tooling chain) — CLOSED
- pfjkw (lane pilot validation) — CLOSED, verdict=validated, snapshots preserved
- s8tdd (fs-rag-discipline) — CLOSED (so any new docs in this bead get
  frontmatter via the pre-commit hook)
