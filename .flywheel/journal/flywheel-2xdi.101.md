---
bead: flywheel-2xdi.101
title: probe-without-receiver + sister-FP — single git mv resolves both via canonical-cli rename
worker: MistyCliff (flywheel:0.4)
date: 2026-05-11
status: shipped
priority: P3
mission_fitness: adjacent
sister: flywheel-2xdi.102 (false-positive, closed in same tick)
meta_gaps_filed: flywheel-9a3k1 (P2 auto-filer dedup), flywheel-dnxjb (P3 probe-finder FP)
joshua_hint: "flywheel-2xdi.102 has identical title — surface as gap-hunt-probe dedup-blind-spot finding"
---

# Journey: flywheel-2xdi.101

## What the bead asked for

probe-without-receiver gap on state-store-authority-probe.sh.
PLUS: Joshua hint about duplicate title at 2xdi.102 — surface dedup blind spot.

## Investigation (N=16 bead-hypothesis META-rule)

Found TWO files with identical basename:
- `.flywheel/scripts/state-store-authority-probe.sh` — real probe
- `tests/state-store-authority-probe.sh` — test for the probe (invokes
  the real probe via absolute path)

Gap-hunt-probe's `*-probe.sh` rglob picks up both. The test was a real
receiver for the probe, but its filename didn't match the
`test_files_corpus` glob (`test-*.sh`/`test_*.sh`/`*-canonical-cli*.sh`).
Net: real probe genuinely lacked corpus-matched receiver (gap real),
AND test file got falsely flagged as a probe (gap false-positive).

## What I shipped

Single `git mv`:

    git mv tests/state-store-authority-probe.sh \
           tests/state-store-authority-probe-canonical-cli.sh

Effect:
- Tests file now matches `*-canonical-cli*.sh` → probe gets a receiver → .101 clears
- Tests file no longer matches `*-probe.sh` → not scanned as probe → .102 clears
- 14/14 test assertions still PASS (test invokes probe via absolute path)

## Meta-beads filed

Per Joshua hint, surfaced the TWO underlying root causes:

- **flywheel-9a3k1** (P2): auto-bead-filer doesn't dedup on
  identical-title. Two beads (.101 + .102) with same title were
  filed even though gap_ids collided on basename.
- **flywheel-dnxjb** (P3): probe-finder rglobs `*-probe.sh` against
  REPO_ROOT, picking up test files in tests/ that aren't actually
  probes.

Both linked to flywheel-2xdi.

## Verification

- 14/14 test PASS after rename
- Fresh gap-hunt-probe: both `state-store-authority-probe` gaps cleared
- probe-without-receiver count 16 → 14

## L112 probe

    bash .flywheel/scripts/gap-hunt-probe.sh --json |
      jq '[.gap_ids[] | select(test("state-store-authority"))] | length'

Expected: `literal:0`.

## Pattern note

7th distinct fix shape in 2xdi.* cluster:
- 47/49/64/66 = probe corpus extensions
- 93 = doctrine cross-link
- 90/92 = test-receiver wire-in (new file)
- 100 = INCIDENTS citation
- **101/102 = git rename to canonical-cli convention (resolves real + sister-FP in one move)**

Joshua-hint productivity pattern: when orch surfaces a dispatch note
about a sister/dup bead, ALWAYS file at least one meta-gap. The
duplicate-looking bead pair is almost always evidence of an auto-filer
or probe-finder blind spot. Recorded as worker-discipline note.
