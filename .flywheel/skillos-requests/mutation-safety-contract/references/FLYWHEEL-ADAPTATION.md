# Flywheel Adaptation

## Why Skillos Owns This

The pattern crosses too many surfaces for a narrow repo patch: CLI flags,
repair scripts, cron jobs, Beads mutations, dispatch log backfills, storage
prune commands, and skill publication all need the same safety shape. Flywheel
stages the request; skillos owns final hardening and publication.

## Canonical CLI Scoping Alignment

The draft addresses:

- `--json` output and `schema_version` receipts.
- `--dry-run` / `--apply` mutation discipline.
- Idempotency key and request fingerprint conflict behavior.
- Lock-file metadata and stale-lock diagnosis.
- Append-only audit rows and rollback/no-op receipts.
- Refusal routing for host/external boundaries.

The doctor/health/repair triad is adjacent but not duplicated here. This skill
composes with `doctor-repair-triad`; doctor observes mutation safety posture,
and this skill defines the mutation contract when repair/apply is allowed.

## Beads Write Lane

L137 says repo-local Beads mutation is a serial write lane. Workers use bounded
`br` mutations or queue to the owner. They do not manually append
`.beads/issues.jsonl`, and they do not treat ordinary file reservations as the
database lock.

## Publication Boundary

This package is under `.flywheel/skillos-requests/`. It is not a live skill.
After skillos review, Joshua can decide whether to copy it into the live skill
library and run `jsm validate` / `jsm push`.
