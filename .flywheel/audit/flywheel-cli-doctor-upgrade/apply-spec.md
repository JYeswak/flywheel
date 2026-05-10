# Bead 3: flywheel-cli-doctor-upgrade

Depends on flywheel-cli-canonical-baseline (bead 2). Runs the
world-class-doctor-mode-for-cli-tools ten-phase loop on every P0/P1 own-binary
that mutates state.

## Goal

Every state-mutating own-CLI's `doctor` subcommand passes the
world-class-doctor-mode rubric: detect-then-fix invariant, single mutate()
chokepoint, content-hashed backups, byte-exact `doctor undo <run-id>`,
idempotence, fixture suite per failure mode, scorecard ≥ baseline+250pts.

## Scope

### AG1: read inventory + select first target

Source: updated inventory.jsonl from bead 2.
Filter: `ownership=own AND mutates_state=yes AND canonical_cli_scoping_status=passing`.
Order by P0 then P1.

**First target (Joshua-confirmed): `flywheel-loop`** — load-bearing surface
for every repo's tick; existing `doctor` makes this `mode=upgrade`; ten
seed failure modes already in MEMORY (see /world-class-doctor-mode-for-cli-tools
SKILL.md integration plan).

### AG2: ten-phase loop per binary

Run the canonical phase loop from
`~/.claude/skills/world-class-doctor-mode-for-cli-tools/SKILL.md`:

1. PROJECT ARCHAEOLOGY + FAILURE-MODE INVENTORY
2. REPAIR SPECIFICATION
3. SYNTHESIS + HARMONIZATION
4. IMPLEMENTATION
5. SAFETY HARNESS
6. AGENT-ERGONOMIC SURFACE + SCORECARD
7. MULTI-PASS FRESH-EYES REVIEW
8. INTEGRATION + DOGFOODING
9. REAL-WORLD FIXTURE SUITE
10. FINAL AGENT-UX PASS

Pre-seed Phase 1 with MEMORY-aware failure modes by passing
`--cass-extra-memory ~/.claude/projects/-Users-josh-Developer-flywheel/memory/`
to `cass-mine.sh`. For flywheel-loop specifically, seed:
- loop-state-without-driver (2026-05-02 trauma)
- pulse-stale → DEAD misclassification
- stale-error preflight bypass
- worker callback never reaches orch (Monitor not armed)
- orch wakes on time-based heartbeat with stale prompt
- legacy `~/.flywheel/loops/<project>.json` schema drift
- topology-resolved-pane mismatch
- watcher dispatching during input-deaf
- frozen-projection-of-mutable-state in tick prompts
- recovery probe stale-chevron false-positive

### AG3: scorecard + uplift

Each binary produces:
- `<workspace>/scorecard.json` (10 dimensions × 0-1000)
- `<workspace>/uplift_diff.md` (vs. baseline established in bead 2)
- `<workspace>/fixtures/` (one per failure mode, round-trip verified)

Hard gates:
- No dimension regressed > 50pts → hard stop, investigate
- Two consecutive Phase-7 fresh-eyes passes clean
- Fixture round-trip: corrupt → `doctor --fix` → assert healthy →
  `doctor undo <run-id>` → byte-identical to corrupted state, per FM

### AG4: wire scorecard into daily-ops rollup

After each binary's doctor-mode pass closes:
- Append `doctor_mode_scorecard_delta` to the binary's row in
  fleet-daily-rollup.py output
- RED FLAG if median scorecard regresses >50pts week-over-week
- Surface in `~/.local/state/flywheel/fleet-daily-<date>.md`

### AG5: dispatch model

One worker dispatch per binary. Use `worktree` mode (the doctor-mode
default) so each pass lives on `doctor-mode-pass-<N>` branch, one bead =
one PR. Re-dispatch passes 2..N on the same bead until termination
threshold (median uplift <25pts AND no regression >50pts).

### AG6: receipt

Write `.flywheel/audit/flywheel-cli-doctor-upgrade/evidence.md`:
- Per-binary scorecard JSON paths
- Per-binary uplift diff summary
- Fixture suite line counts per binary
- RED FLAG entries (regressions caught)
- Updated inventory.jsonl with `doctor_subcommand_status=upgraded`
- Daily-ops rollup integration receipt (one row showing the new column)

## Boundary

- DO NOT run on jeff-stack binaries. File upstream issues with the
  failure-mode evidence (per `feedback_jeff_issue_chain`).
- DO NOT run on a binary that hasn't passed bead 2's canonical baseline.
  Phase 0 (`scripts/discover-cli.sh --probe-doctor`) refuses cleanly but
  burns dispatch capacity.
- One PR per binary per pass; never bundle multiple binaries' doctor work.

## Success criteria

- flywheel-loop scorecard ≥ baseline+250pts (locked-in first deliverable)
- All P0 own-mutating binaries reach upgraded status
- Fleet-daily rollup carries doctor scorecard column
- Zero regressions >50pts in fixture suite
