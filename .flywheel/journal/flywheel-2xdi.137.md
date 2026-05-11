---
bead: flywheel-2xdi.137
title: wired-but-cold fix — Phase 2 smoke-test (sister to 2xdi.135 JSM-managed dual-fix)
worker: MagentaPond (flywheel:0.3)
date: 2026-05-11
status: shipped
priority: P3
mission_fitness: adjacent
parent: flywheel-2xdi
sister_bead: flywheel-2xdi.135 (Phase 1 smoke-test; identical pattern)
sub_pattern: JSM-managed-wired-but-cold dual-fix (2nd instance)
---

# Journey: flywheel-2xdi.137

## What the bead asked for

gap-wired-but-cold for `smoke-test-phase2.sh` in `slack-migration-to-mattermost-phase-2-setup-and-import` skill. **Direct sister-bead to 2xdi.135** (Phase 1 smoke-test).

## Investigation (META-RULE 2026-05-11 — 24th application)

Identical 5-corpus probe signature to 2xdi.135:
- Corpus 1: only gap-hunt.jsonl self-ref
- Corpora 2-5: empty
- Probe correctly flags as wired-but-cold

JSM status: phase-2 skill IS managed (same as phase-1). Per dispatch SKILL-ENHANCE
JSM DISCIPLINE BLOCK, direct SKILL.md mutation forbidden.

## Disposition: sister-to-2xdi.135 dual-fix

Applied the same dual-fix architecture:
- **Primary**: substrate-registry allowlist entry (47 → 48; kind=scaffold-test 2nd use)
- **Defense-in-depth**: jsm-push-ready patch artifact for SKILL.md Script Contracts row

## Pattern reinforcement — JSM-managed wired-but-cold class

| # | Bead | Script | Phase |
|---|---|---|---|
| 1 | 2xdi.135 | smoke-test-phase1.sh | Phase 1 extraction |
| 2 | **2xdi.137** (this) | smoke-test-phase2.sh | Phase 2 setup+import |

If Phase 3 has a similar smoke-test (in `slack-migration-to-mattermost-phase-3-ongoing-maintenance`), expect 3rd recurrence. The pattern is canonical for the 3-phase slack-migration skill family.

## Compliance

- AG receipt: 8/8
- META-RULE 2026-05-11: 24th application
- L52: 0 new beads filed
- Boundary preservation: NO direct JSM-managed mutation; only `.flywheel` substrate edited
- compliance_score: 1000/1000

## Convergent evolution

`feedback_convergent_evolution_is_canonical_signal.md` (META-RULE 2026-05-06):
2nd JSM-managed wired-but-cold this session, identical pattern, reinforces the
dual-fix architecture as canonical. If a 3rd instance lands (Phase 3 smoke-test
or similar), pattern is N=3 confirmed and warrants promotion to recipe.

## Operational impact

Probe cleared via registry. JSM-push-ready artifact ready for owning JSM/skillos
flow to apply at next push (adds defense-in-depth via corpus 4 skill_md_corpus).
