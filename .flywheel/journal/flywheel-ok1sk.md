---
bead: flywheel-ok1sk
title: jloib wave-1 decomposition (P0 missing × non-general lanes)
worker: MistyCliff (flywheel:0.4)
date: 2026-05-10
status: shipped (decomposition-only)
priority: P0
mission_fitness: adjacent
sister_pattern: wzjo9.1 (8/9 closed avg 982)
followup_bead: flywheel-d6zk1 (backup file cleanup)
---

# Journey: flywheel-ok1sk decomposition

## What Joshua asked for

Wave-1 of the jloib parent (3-bead chain: flywheel-cli-inventory →
flywheel-cli-canonical-baseline → doctor-mode-upgrade). Wave-1 covers
P0 missing × non-general lanes (jeff-corpus, doctrine, testing, recovery,
beads, agent-mail, quality) — 21 surfaces per the wave-1 apply-spec.

DECOMPOSITION-ONLY tick. File 21 per-binary sub-beads with apply-specs.
Same shape as wzjo9.1 → wzjo9.1.{1..9}.

## Pre-decomposition audit caught 4 EXCLUSIONS

Before filing 21 sub-beads, ran a pre-flight existence + canonical-cli
fingerprint audit on all 21 paths. Found 4 to exclude:

| Surface | Exclusion |
|---|---|
| `bin/flywheel-summarize` | Already canonicalized + filled by sister wzjo9.1.1 (closed) |
| `bin/flywheel-sync` | Already canonicalized + filled by sister wzjo9.1.2 (closed; I shipped this earlier today) |
| `bin/flywheel-trauma-check` | Already canonicalized + filled by sister wzjo9.1.3 (closed) |
| `bin/flywheel.bak-2026-04-28-pre-substrate-intake` | Backup file (`.bak-` prefix), 2346 lines — should not get canonical-cli scaffold; filed cleanup follow-up bead `flywheel-d6zk1` |

Real decomposition target: **17 sub-beads** (not 21).

## What I shipped

1. Reserved `.flywheel/audit/flywheel-ok1sk` audit dir
2. Pre-flight audit on all 21 wave-1 surfaces (existence + scaffold-state)
3. Generated TSV of 17 in-scope surfaces
4. Filed 17 sub-beads via `br create --type task --priority P0`
5. Wired parent-child deps (17/17 verified via `br dep list`)
6. Wrote per-bead apply-spec template at
   `.flywheel/audit/flywheel-ok1sk/per-bead-apply-spec-template.md`
   (with lane-specific doctor probe hints)
7. Wrote decomposition receipt at
   `.flywheel/audit/flywheel-ok1sk/decomposition-receipt.md`
   (with full mapping table + 4 exclusions documented)
8. Filed `flywheel-d6zk1` (P3) for the backup file cleanup follow-up

## Sub-beads filed

- agent-mail (2): flywheel-0pkcf, flywheel-ou656
- beads (2): flywheel-lrdum, flywheel-gbfpo
- doctrine (4): flywheel-kz7o0, flywheel-bu0es, flywheel-05ost, flywheel-vs78t
- jeff-corpus (4): flywheel-x0k3j, flywheel-64hud, flywheel-ugjvq, flywheel-d80zq
- quality (1): flywheel-k46et
- testing (4): flywheel-vuc9c, flywheel-1l8yt, flywheel-8b90l, flywheel-oa23p

## Notable

- **Coordination artifact**: wave-1 (jloib status×lane) and wave-2.0a
  (wzjo9.1 lane×wave) overlap on the recovery lane. The pre-flight
  fingerprint audit caught 3 already-shipped sister surfaces. Without
  this audit, I would have filed 3 duplicate beads — wasting reviewer
  time + creating cleanup debt.
- **`.bak-` exclusion was load-bearing**: the 2346-line backup file
  would have been the largest single fillin in the wave (>3x the next
  largest), AND scaffolding a snapshot is doctrinally wrong (frozen
  artifacts shouldn't accumulate canonical-cli evolution).
- **Bead-create loop initially failed silently** when run as a single bash
  command with a multi-line heredoc inside — wrote it to /tmp/ok1sk-create-beads.sh
  and ran via `bash /tmp/...` instead. The single-script form works
  reliably; the inline-bash form had some parser issue I didn't fully
  diagnose (worth a META-RULE: "for >5-iteration bead-create loops, write
  to a script file rather than inline").
- Per-bead apply-spec template includes lane-specific doctor probe hints
  (e.g., agent-mail lane: agent-mail SQLite + ntm + identity registry
  probes; beads lane: br + .beads/issues.jsonl + sqlite3 probes; etc.) —
  pre-loads worker context for each per-bead dispatch.

## Mission fitness

Class: **adjacent**. The decomposition itself doesn't ship canonical-cli
baselines (the parent goal); it sets up the dispatch surface so subsequent
worker ticks can ship them in parallel.

## Files touched

- `.flywheel/audit/flywheel-ok1sk/decomposition-receipt.md` (NEW)
- `.flywheel/audit/flywheel-ok1sk/per-bead-apply-spec-template.md` (NEW)
- `.flywheel/audit/flywheel-ok1sk/compliance-pack.md` (NEW)
- `.flywheel/journal/flywheel-ok1sk.md` (NEW, this file)
- Beads filed (17): ok1sk children + 1 cleanup follow-up (d6zk1)
