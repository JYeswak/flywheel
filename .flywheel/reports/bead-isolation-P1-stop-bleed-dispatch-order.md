# Bead Isolation P1 Stop-Bleed Dispatch Order

Task: `flywheel_idle_flywheel-0cm9_p2_20260505T114129Z`
Bead: `flywheel-0cm9`
Captured: 2026-05-05T11:47Z

## Preflight

- Agent Mail identity resolved from durable registry: `CloudyMill`.
- Socraticode survey: 4 queries against `/Users/josh/Developer/flywheel`, `indexed_chunks_observed=694`.
- Child beads verified:
  - `flywheel-45tt` - `[bead-isolation-P1] stop-bleed/FM-1 RunBdStrict`
  - `flywheel-ldhr` - `[bead-isolation-P1] stop-bleed/FM-5 workspace CM`
  - `flywheel-wrrf` - `[bead-isolation-P1] stop-bleed/FM-6 checkpoint guard`
- Dependency graph check: `br dep cycles --json` returned `count=0`.
- Boundary: do not patch or push Jeff-owned `ntm` / `beads_rust` repos from flywheel. File issue/repro packets or prepare local-only ntm work packets for Jeff review.

## Baseline

Full `flywheel-loop doctor --repo /Users/josh/Developer/flywheel --json` timed out at 20s with no JSON. The required leakage baseline was captured with the same narrow SQLite source-repo predicate used by `check_beads_db_health`:

- Baseline file: `/tmp/flywheel-0cm9-doctor-baseline.json`
- `beads_db_health.status=fail`
- `integrity=fail` from existing freelist/page damage
- `leakage_count=0`
- `null_notes_count=0`
- `wal_size_bytes=0`

Expected Phase 1 direction: keep `leakage_count` at 0 by preventing new cross-project recovery ingestion. The existing SQLite integrity failure is a separate beads DB health substrate issue; Phase 1 stop-bleed does not mutate bead data.

## Dispatch Order

Use DP1 majority resolution: Phase 1 includes all three stop-bleed fixes, `FM-1`, `FM-5`, and `FM-6`.

Use DP2 behavior split throughout:

- strict/fail-fast at recovery write or strict lookup boundaries when a local `.beads/beads.db` is required
- graceful empty recovery/interactive presentation when a repo has no local bead substrate
- no parent/global `.beads` walk-up in any recovery context

Recommended sequencing:

1. `flywheel-45tt` / FM-1: add strict repo-local bead queries.
   - Target packet files in Jeff-owned `ntm`: `internal/bv/bv.go`, plus the recovery list call sites.
   - Include plan Change 1.1 and the local-DB gate from Change 1.2 in the issue/repro packet.
   - Required tests: T1.1, T1.2, T1.3, T1.4.

2. `flywheel-ldhr` / FM-5: scope CM recovery by absolute workspace.
   - Target packet files in Jeff-owned `ntm`: `internal/cm/client.go`, `internal/cli/spawn.go`.
   - Pass `workingDir` to the CM recovery call and invoke `cm context --workspace <abs_path>`.
   - Required tests: T1.5 plus same-basename regression.

3. `flywheel-wrrf` / FM-6: validate checkpoint project path.
   - Target packet file in Jeff-owned `ntm`: `internal/cli/spawn.go`.
   - Run after FM-5 or in the same ntm worker because both touch `spawn.go`.
   - Required tests: T1.6, T1.7, matching-ProjectPath regression.

Do not dispatch `flywheel-ldhr` and `flywheel-wrrf` to parallel workers unless their write reservations explicitly divide `spawn.go` regions. The lower-risk path is sequential dispatch or one ntm worker owning both `spawn.go` changes.

## Issue Packet Requirements

Every child packet should include:

- the canonical flywheel plan path: `/Users/josh/Developer/flywheel/.flywheel/PLANS/bead-isolation-fix-2026-04-30.md`
- the specific DP and FM list above
- a reproducer for the relevant leakage/collision class
- a no-push boundary for Jeff remotes
- a reservation step for the Jeff repo files before edits
- callback fields for Socraticode, file reservations, bead updates, and fuckup logging

## Unblock Condition

`flywheel-0cm9` is the only listed blocker for `flywheel-45tt`, `flywheel-ldhr`, and `flywheel-wrrf`. Once this coordination bead is closed, all three child beads become schedulable under the sequencing above.

## Closeout Evidence

- `br close flywheel-0cm9 --actor CloudyMill` succeeded at 2026-05-05T11:48:31Z.
- `br ready --json` now includes `flywheel-45tt`, `flywheel-ldhr`, and `flywheel-wrrf`.
- `br dep cycles --json` remains acyclic with `count=0`.
- `br sync --flush-only --json` was attempted after close and refused stale export because DB has 1055 issues, JSONL has 1024 unique issues, and export would lose 8 issue IDs. The close is visible through `br show` and child readiness is visible through `br ready`; JSONL flush requires separate beads DB repair/import handling before a safe commit.
