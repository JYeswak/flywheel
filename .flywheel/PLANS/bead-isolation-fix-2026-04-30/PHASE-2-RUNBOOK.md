---
title: "Bead Isolation Phase 2 Runbook"
type: plan
created: 2026-05-07
frontmatter_source: scaffold-doc-frontmatter
---

# Bead Isolation Phase 2 Runbook

Source plan: `.flywheel/PLANS/bead-isolation-fix-2026-04-30.md`

Receipts:
- Backfill dry-run: `.flywheel/receipts/flywheel-1o0i-backfill-source-repo-dry-run.txt`
- Phase 2 audit: `.flywheel/receipts/flywheel-1o0i-phase2-audit.txt`

## Current Verdict

Phase 1 stop-bleed dependencies are closed:
- `flywheel-wrrf` closed: FM-6 checkpoint guard
- `flywheel-ldhr` closed: FM-5 workspace CM
- `flywheel-45tt` closed: FM-1 RunBdStrict

FM-8 schema-handoff work is closed as `flywheel-frov`; this runbook still files a follow-up child under `flywheel-1o0i` for runtime_handoff closeout guard coverage because the current Phase 2 audit only proves the `working_dir` column exists.

`tests/phase2-audit.sh` currently reports 5/8 passing. The three remaining blockers are documented below with planned-resolution paths:
- T2.3: repo-local databases still contain `source_repo='.'`
- T2.4: `br create` still writes a non-absolute temp repo name in the audit fixture
- T2.6: `bd` remains available on `PATH`

## Gate 1: Stale Global Beads

Plan Change 2.1 names 11 stale global bead IDs:

`fc-27i`, `fc-2pm`, `fc-1q9`, `fc-1sr`, `fc-7xm`, `fc-hci`, `fc-y3w`, `fc-135`, `fc-d9s`, `fc-3fv`, `fc-2m7`

Batch-close candidates:
- `fc-27i`
- `fc-2pm`
- `fc-1q9`
- `fc-1sr`
- `fc-7xm`
- `fc-hci`
- `fc-y3w`
- `fc-135`
- `fc-d9s`
- `fc-3fv`

Human-review candidate:
- `fc-2m7`: separate Terratitle migration reason in the plan; confirm it has a repo-local successor before closing if a tombstone DB is restored.

Observed state:
- `/Users/josh/Developer/.beads` is absent.
- `/Users/josh/Developer/.beads-tombstone` exists.
- T2.1 passes with marker-only tombstone state.

Execution order:
1. Capture a dry-run query of the tombstone/global source before any close.
2. Confirm each stale ID exists in the target DB, or mark it `already_absent`.
3. Close the 10 duplicate IDs in one batch only after the dry-run receipt is saved.
4. Close `fc-2m7` only after the Terratitle successor check is recorded.
5. Re-run T2.1 and append the output to a receipt.

Rollback:
- Reopen only the exact ID set changed in the batch.
- Restore the pre-close DB snapshot if any close hits the wrong DB.

## Gate 2: Active Repo Init List

Plan Change 2.2 candidate repos:

| Repo | Current confirmation | Action |
|---|---:|---|
| `/Users/josh/Developer/flywheel` | confirmed `.beads/beads.db` | no init |
| `/Users/josh/Developer/frankencoder` | repo path absent | human approval or topology correction required |
| `/Users/josh/Developer/clutterfreespaces` | confirmed `.beads/beads.db` | no init |
| `/Users/josh/Developer/vrtx` | confirmed `.beads/beads.db` | no init |
| `/Users/josh/Developer/blackfoot` | repo path absent | human approval or topology correction required |
| `/Users/josh/Developer/zeststream-v2` | confirmed `.beads/beads.db` | no init |

Approval marker:

`HUMAN_APPROVAL_GATE: br_init_absent_repo_paths = frankencoder, blackfoot`

No Phase 2 worker should initialize absent paths until topology confirms the canonical repo locations.

## Gate 3: source_repo Backfill Plan

Dry-run receipt:

`.flywheel/receipts/flywheel-1o0i-backfill-source-repo-dry-run.txt`

The helper `scripts/backfill-source-repo.sh` scanned 44 databases. It reported one update target:
- `/Users/josh/Developer/cfs-expo`: 98/98 issues need source_repo backfill

The Phase 2 audit also found:
- `/Users/josh/Developer/ntm/.beads/beads.db`: 195 rows with `source_repo='.'`
- `/Users/josh/Developer/cfs-expo/.beads/beads.db`: 98 rows with `source_repo='.'`

Planned resolution:
1. Snapshot each target `.beads/beads.db`.
2. Re-run the dry-run helper and record output.
3. Backfill all repo-local databases with canonical absolute repo paths.
4. Investigate why the dry-run helper reported `/Users/josh/Developer/ntm` as skipped while T2.3 found `source_repo='.'` rows; treat `ntm` as an explicit target until the discrepancy is explained.
5. Re-run T2.3. Close the blocker only when all repo-local databases return zero rows for `source_repo='.'`.

No active `.beads/issues.jsonl` file may be edited manually. Use `br` for issue mutations and SQLite only for the planned DB normalization after a backup receipt exists.

## Gate 4: Symlink Tombstone DP3

DP3 resolved symlink removal in Phase 2 with a tombstone guard. Current implementation differs from the original command sketch and is stricter:
- `/Users/josh/Developer/.beads` remains absent.
- `/Users/josh/Developer/.beads-tombstone` is the marker.
- T2.1 treats marker-only tombstone state as valid and global vault inactive.

Procedure if the symlink reappears:
1. Stop before mutation and capture `ls -ld /Users/josh/Developer/.beads /Users/josh/Developer/.beads-tombstone`.
2. Verify no current process is writing through `/Users/josh/Developer/.beads`.
3. Replace only the symlink path with the tombstone-marker state.
4. Run `br where` from `/Users/josh/Developer/flywheel` and confirm it resolves to the repo-local DB.
5. Re-run T2.1 and T2.5.

Rollback:
- Restore the captured pre-change filesystem state only if a verified consumer still needs the global path.
- File a follow-up blocker bead for that consumer; do not silently restore global walk-up behavior.

## Gate 5: bd/br-real Consolidation

Observed state:
- `br-real` is absent from `PATH`.
- `RunBrReal` is absent from `/Users/josh/Developer/ntm/internal`.
- `bd` remains available at `/Users/josh/.cargo/bin/bd`, so T2.6 fails.

Plan:
1. Keep `~/.cargo/bin/br` as the canonical binary.
2. Remove local `bd` exposure after confirming no active flywheel scripts depend on it.
3. Leave Jeff-owned repos untouched from this bead. Do not push to `ntm` or `beads_rust`.
4. If upstream code changes are still needed after local cleanup, file a GitHub issue with the Jeff issue-chain skill instead of patching/pushing.

Jeff issue status: not needed for this coordination bead because `RunBrReal` is already absent and the remaining failing surface is a local `bd` exposure.

## Gate 6: FM-8 Child Bead

FM-8 baseline is closed as `flywheel-frov`, but Phase 2 still needs closeout guard coverage:
- T2.8 currently checks only that `runtime_handoff` has a `working_dir` column.
- The plan's richer intent is multi-session, project-scoped runtime handoff state.

Filed child bead:
- ID: `flywheel-1o0i.1`
- Title: `[bead-isolation-P2] FM-8 runtime_handoff closeout guard`
- Parent: `flywheel-1o0i`
- Priority: P1
- Scope: additive tests and schema-proof receipts for runtime_handoff multi-row, multi-working-directory behavior.

Acceptance:
- Fixture proves distinct sessions or working directories do not collapse into a singleton handoff row.
- `tests/phase2-audit.sh` gains only additive coverage if needed.
- Any temporary scratch directory uses a `mktemp -d -t bead-isolation-p2.XXXXXX` style.
- No live `~/.config/ntm/state.db` mutation without backup receipt.

## Audit Status

`tests/phase2-audit.sh` receipt:

| Check | Status | Resolution path |
|---|---|---|
| T2.1 global vault tombstone + stale IDs closed | pass | keep marker-only tombstone state |
| T2.2 active repos have `.beads/beads.db` | pass | absent plan entries gated for human approval |
| T2.3 source_repo `.` count is zero | fail | backfill `ntm` and `cfs-expo`, then re-run |
| T2.4 br create writes absolute source_repo | fail | fix `br create` source_repo writer in beads_rust via issue or authorized upstream bead |
| T2.5 br where resolves local DB | pass | no action |
| T2.6 bd and br-real absent from PATH | fail | retire local `bd` exposure after dependency check |
| T2.7 RunBrReal not called in ntm/internal | pass | no action |
| T2.8 runtime_handoff has working_dir column | pass | child bead covers richer FM-8 behavior |

Phase 2 should not be declared fully closed until T2.3, T2.4, and T2.6 pass.
