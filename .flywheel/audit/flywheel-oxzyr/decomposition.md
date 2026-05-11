# flywheel-oxzyr Decomposition Manifest

**Parent bead:** flywheel-oxzyr (P1) — `[doctor-mode-integration-3] flywheel-cli-doctor-upgrade: run ten-phase doctor-mode loop per state-mutating own-binary (flywheel-loop first)`

**Authored by:** flywheel-oxzyr-4a33a9 worker tick (MagentaPond / flywheel:0.3 / 2026-05-11T06:25Z)

## Why decomposition

The parent bead's scope is meta-orchestration:

- **N targets:** 155 own-binaries with `mutates_state=yes AND canonical_cli_scoping_status=passing` (39 P0 + 116 P1, per `.flywheel/audit/flywheel-cli-inventory/inventory.jsonl` snapshot 2026-05-11T06:13Z).
- **Per-binary work:** 10-phase doctor-mode loop per `~/.claude/skills/world-class-doctor-mode-for-cli-tools/SKILL.md` (~85KB methodology).
- **Multi-pass per binary:** AG5 explicitly says "one bead = one PR per pass; re-dispatch passes 2..N until termination threshold (median uplift <25 AND no regression >50)".

Total surface: 155 × 10 phases × N passes = literal months of orchestration arc. **Single worker-tick cannot ship the whole thing.** Per the `decompose-by-natural-unit-not-bundle` META-RULE (2026-05-10), file 1 bead per natural unit when total >1-2h.

## Natural unit

**Per binary, per pass.** AG5 confirms: "one worker dispatch per binary; use worktree mode (branch `doctor-mode-pass-<N>`)". Each pass closes one PR; re-dispatch happens on the same parent until termination threshold.

## Sub-bead naming convention

```
flywheel-oxzyr.<n>.pass-<p>
  where <n> = 1..155 (target ordinal; 1 = flywheel-loop per Joshua confirmation)
        <p> = 1..N (pass ordinal; re-dispatched until termination)
```

## Sub-bead dispatch model

- **Authored by orch** (`/flywheel:plan` decompose phase or manual `br create`).
- **Worker-tick scope:** one sub-bead = one pass on one binary. Phases 1+2 (archaeology + repair spec) are typically deliverable in one tick; Phases 3-10 may need follow-on passes (re-dispatch on same parent).
- **Worktree mode:** branch `doctor-mode-pass-<P>` per AG5; one PR per pass.

## First sub-bead (filed in this tick)

- **`flywheel-oxzyr.1`** = flywheel-loop pass-1 archaeology + repair spec
  - Target: `~/.claude/skills/.flywheel/bin/flywheel-loop` (852 lines, existing doctor with 22+ named scopes)
  - Mode: `upgrade` (existing doctor → upgraded doctor)
  - Phase 1 archaeology: `.flywheel/audit/flywheel-cli-doctor-upgrade/flywheel-loop-phase1-archaeology.md` (this tick)
  - Phase 2 repair spec: pending (next worker-tick on this sub-bead)

## Per-binary subset for follow-on filing

The orch (or `/flywheel:plan` decompose) should iterate the inventory subset and file `flywheel-oxzyr.2` through `flywheel-oxzyr.155`:

```bash
jq -r 'select(.ownership=="own" and .mutates_state=="yes" and .canonical_cli_scoping_status=="passing")|.name' \
  .flywheel/audit/flywheel-cli-inventory/inventory.jsonl
```

Order priority: P0 (39 binaries) before P1 (116 binaries). Within each priority tier, alphabetical.

## Termination threshold (per binary)

Per AG5: "Re-dispatch passes 2..N until termination threshold (median uplift <25 AND no regression >50)". Tracked in:

- `<workspace>/scorecard.json` (10 dimensions × 0-1000) — per pass
- `<workspace>/uplift_diff.md` (vs prior pass + vs bead-2 baseline)
- `<workspace>/fixtures/` (one per failure mode, round-trip verified)

## Hard gates (per pass; AG3)

- No dimension regressed >50pts → hard stop, investigate
- Two consecutive Phase-7 fresh-eyes passes clean
- Fixture round-trip: corrupt → `doctor --fix` → assert healthy → `doctor undo <run-id>` → byte-identical to corrupted state, per FM

## Boundary preservation (AG5 + apply-spec line 96-103)

- DO NOT run on jeff-stack binaries. File upstream issues with FM evidence (per `feedback_jeff_issue_chain`).
- DO NOT run on binaries that haven't passed bead 2's canonical baseline. (Inventory filter `canonical_cli_scoping_status=passing` enforces this.)
- One PR per binary per pass; never bundle multiple binaries' doctor work.

## Parent bead disposition

Parent bead `flywheel-oxzyr` stays OPEN as the meta-orchestration parent. Closes when:

1. All 155 sub-beads (`flywheel-oxzyr.<n>`) reach terminated state (median uplift <25 AND no regression >50)
2. AG4 daily-ops rollup is wired with `doctor_mode_scorecard_delta` column
3. AG6 receipt aggregates per-binary scorecards into the evidence pack

## Worker-tick disposition for THIS dispatch

**PARTIAL** — did=2/6 (AG1 inventory subset captured + AG2-Phase-1 archaeology for flywheel-loop authored + decomposition manifest authored). chain_blocked_reason: 153 remaining per-binary 10-phase loops are individual multi-tick orchestration scope; needs orch to dispatch `flywheel-oxzyr.<n>` series via `/flywheel:plan` decompose or manual filing. The first sub-bead `flywheel-oxzyr.1` (flywheel-loop pass-1) is filed in this tick for immediate orch dispatch.
