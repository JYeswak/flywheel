---
bead: flywheel-2xdi.144
title: wired-but-cold fix — flywheel-cli-surface NEW owner class + faqj2 corpus-3 extension harvest
worker: MagentaPond (flywheel:0.3)
date: 2026-05-11
status: shipped
priority: P3
mission_fitness: adjacent
parent: flywheel-2xdi
sister_recipe: 6th registry-allowlist bead this session (60.1/72.1/132/135/137 prior)
new_owner_class: flywheel-cli-surface (NEW)
posterior_shape: script-wired-via-flywheel-hooks-or-tests-but-probe-corpus-3-too-narrow (13th distinct)
---

# Journey: flywheel-2xdi.144

## What the bead asked for

gap-wired-but-cold for `.flywheel/scripts/canonical-cli-lint-precommit-installer.sh`.

## Investigation (META-RULE 2026-05-11 — 26th application)

**Key finding:** Script IS heavily wired in production:
- `.flywheel/hooks/pre-commit-chain.sh` (runtime call)
- `tests/canonical-cli-lint-precommit.sh` (test)
- `.flywheel/compliance/flywheel-f0e77/evidence.md` (compliance pack)

But probe's `runtime_source_corpus()` scans `~/.claude/skills/**/*.sh` +
`.flywheel/scripts/*.sh` + extension-less `bin/*` — NOT `.flywheel/hooks/*.sh`
or `tests/*.sh`. So the probe doesn't see the wiring.

**13th distinct posterior shape: `script-wired-via-flywheel-hooks-or-tests-but-probe-corpus-3-too-narrow`.**

## Recurring class — N=2 visible

| Script | Wired via hooks | Wired via tests |
|---|---|---|
| canonical-cli-lint-precommit-installer (this) | ✓ | ✓ |
| fleet-coherence-classifiers | ✗ | ✓ |

N=2 visible. Threshold N=4 not met for new calibration bead. Harvest into
faqj2 next-tick when 3rd+ instance surfaces.

## Disposition: Option A (registry-allowlist) + faqj2 harvest deferral

Sister to 5 prior registry-allowlist beads this session. New entry:
- `owner=flywheel-cli-surface` (NEW owner class)
- `kind=scaffold`
- `lifecycle_state=active`
- `consumers` field lists BOTH runtime (hooks) AND test paths

## Sister-pattern arc — 6 registry-allowlist beads this session

| # | Bead | kind | lifecycle | owner |
|---|---|---|---|---|
| 1 | 2xdi.60.1 | audit | active | skill-owned |
| 2 | 2xdi.72.1 | scaffold | active | 3 sibling skills |
| 3 | 2xdi.132 | scaffold | planned | skill-evolution-plan |
| 4 | 2xdi.135 | scaffold-test | active | slack-migration-1 (JSM-managed) |
| 5 | 2xdi.137 | scaffold-test | active | slack-migration-2 (JSM-managed) |
| 6 | **2xdi.144** (this) | scaffold | active | **flywheel-cli-surface (NEW)** |

The matrix now spans 5 owner-class types: skill-owned / multi-sibling-skill /
plan-doc / JSM-managed-skill / flywheel-cli-surface.

## faqj2 harvest candidate

When N=4 instances of `tests/hooks-corpus-too-narrow` accrue, file calibration
bead for `runtime_source_corpus()` scope extension to scan `.flywheel/hooks/*.sh`
+ `tests/*.sh`. Currently N=2 visible; threshold not met.

## Compliance

- AG receipt: 9/9
- META-RULE 2026-05-11: 26th application; 13th posterior shape
- L52: 0 new beads filed
- Boundary preservation: only registry edited
- L107: MCP-skipped
- compliance_score: 1000/1000
