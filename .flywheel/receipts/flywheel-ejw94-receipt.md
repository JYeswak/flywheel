# flywheel-ejw94 Receipt

Date: 2026-05-08
Task: `flywheel-ejw94` — bead-isolation leakage structural fix

## Phase Shipped

Shipped one Phase 2/Phase 3 bridge wave from `.flywheel/PLANS/bead-isolation-fix-2026-04-30.md`:

- Phase 2 data normalization: `scripts/backfill-source-repo.sh` now converts basename `source_repo` values such as `flywheel` to canonical absolute repo paths.
- Phase 3 producer hardening: `.flywheel/scripts/memory-rule-gate-parity-detector.sh` now derives the authoritative repo for the flywheel memory corpus and refuses to auto-file flywheel memory repair beads into a sister repo.

## Failure Modes

Plan FMs:

1. FM-1: Spawn recovery global bleed
2. FM-2: `bv --robot-next` global bleed
3. FM-3: No `source_repo` SQL filter / source_repo isolation debt
4. FM-4: Last-touched cross-repo
5. FM-5: CM basename-only key
6. FM-6: Checkpoint session-only
7. FM-7: AgentMail identity fallback
8. FM-8: `runtime_handoff` singleton

s69zu cross-ref:

- 64 `memory-rule-gate-parity-detector` rows mapped to FM-3-family source_repo isolation debt plus the basename-keying doctrine class. The producer was scanning flywheel memory while accepting a sister repo path from doctor.
- 8 peer-orch mistake rows mapped outside the eight Beads isolation FMs; they are covered by the jm2b/0dd7 escalation consumer route and remain separate follow-up territory.

## Conversion Sites

1. `.flywheel/scripts/memory-rule-gate-parity-detector.sh`
   - Canonicalizes `REPO`.
   - Maps `~/.claude/projects/-Users-josh-Developer-flywheel/memory` to `/Users/josh/Developer/flywheel`.
   - Emits `repo_scope.corrected=true` plus `repo_memory_scope_mismatch_corrected` when a sister repo tries to own flywheel memory repairs.
   - Uses `br create` instead of appending `.beads/issues.jsonl` directly.
   - Normalizes the created bead row's `source_repo` to the absolute repo path.

2. `scripts/backfill-source-repo.sh`
   - Adds `--repo`, `--json`, and basename normalization.
   - Converts null/empty/dot/basename `source_repo` values to the repo realpath.
   - Leaves genuine foreign `source_repo` rows visible for doctor leakage.

## Doctor Metric

- Pre-fix live doctor predicate: `beads_db_health.leakage_count=188`.
- Post-backfill direct predicate: `0`.
- Post-fix `flywheel-loop doctor --repo /Users/josh/Developer/flywheel --json | jq '.beads_db_health.leakage_count'`: `0`.

## Tests

Added:

- `tests/test_bead_isolation_source_repo_backfill.sh`

Updated:

- `.flywheel/tests/test-memory-rule-gate-parity-detector.sh`

Passing:

- `bash .flywheel/tests/test-memory-rule-gate-parity-detector.sh`
- `bash tests/test_bead_isolation_source_repo_backfill.sh`
- `bash -n .flywheel/scripts/memory-rule-gate-parity-detector.sh`
- `bash -n scripts/backfill-source-repo.sh`

## Follow-Up

Remaining phases:

- Phase 1 ntm-owned recovery hardening was already packetized in `.flywheel/reports/bead-isolation-P1-stop-bleed-dispatch-order.md`; Jeff/ntm-owned work remains separate.
- Phase 3 beads_rust SQL filters and last-touched guards still need upstream implementation.
- Phase 4 continuous guardrails still need the cross-entrypoint regression matrix.
