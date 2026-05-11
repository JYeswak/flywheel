---
bead: flywheel-2xdi.148
title: wired-but-cold fix — fleet-coherence-classifiers (sister to 2xdi.144 flywheel-cli-surface; N=3 class reinforcement)
worker: MagentaPond (flywheel:0.3)
date: 2026-05-11
status: shipped
priority: P3
mission_fitness: adjacent
parent: flywheel-2xdi
sister_bead: flywheel-2xdi.144 (canonical-cli-lint-precommit-installer; same flywheel-cli-surface owner + same tests/hooks-corpus-too-narrow class)
class_reinforcement: tests-and-hooks-corpus-too-narrow N=3 visible (faqj2 harvest candidate; threshold N=4 not met)
---

# Journey: flywheel-2xdi.148

## What the bead asked for

gap-wired-but-cold for `.flywheel/scripts/fleet-coherence-classifiers.sh`.
This is the **2nd visible instance of the `tests/hooks-corpus-too-narrow`
class** I identified in 2xdi.144's evidence pack — auto-bead-filer caught
up to the prediction.

## Investigation (META-RULE 2026-05-11 — 29th application)

Script is canonical-CLI-scoped (`--info/--schema/--doctor/--health/--validate/--audit/--why/--repair`)
and IS wired via `tests/fleet-coherence-classifiers.sh` (test sister).

But probe's `runtime_source_corpus()` scope:
- ✓ `~/.claude/skills/**/*.sh`
- ✓ `.flywheel/scripts/*.sh`
- ✓ extension-less `bin/*` wrappers
- ✗ `tests/*.sh` (NOT scanned)
- ✗ `.flywheel/hooks/*.sh` (NOT scanned)

→ Probe correctly flags wired-but-cold per its current corpus-3 scope.

## Disposition: substrate-registry allowlist (sister to 2xdi.144)

Same recipe as 2xdi.144:
- Primary: registry-allowlist entry with `owner=flywheel-cli-surface`
  (reinforces NEW owner class introduced in 2xdi.144; 2nd use)
- No SKILL.md edit (no owning skill; flywheel-internal script)
- No probe modification (corpus-3 extension deferred to faqj2 harvest at N=4)

## What I shipped

`~/.claude/skills/.flywheel/data/substrate-registry.json` — 49 → 50 entries:

```json
{
  "name": "fleet-coherence-classifiers",
  "kind": "scaffold",
  "lifecycle_state": "active",
  "owner": "flywheel-cli-surface",
  "where": "/Users/josh/Developer/flywheel/.flywheel/scripts/fleet-coherence-classifiers.sh",
  "consumers": ["tests/fleet-coherence-classifiers.sh (canonical-CLI scoped)"]
}
```

Plus paired jsm-import-ready patch + backup.

## Tests/hooks-corpus-too-narrow class — N=3 visible

| # | Bead | Script | tests/ cite | hooks/ cite |
|---|---|---|---|---|
| 1 | 2xdi.144 | canonical-cli-lint-precommit-installer | ✓ | ✓ |
| 2 | (identified in 2xdi.144) | fleet-coherence-classifiers | ✓ | — |
| 3 | **2xdi.148 (this)** | fleet-coherence-classifiers (auto-bead-filed) | ✓ | — |

Note: instance #3 is the same script as #2 — auto-bead-filer caught up to
the prediction. Effectively N=2 distinct scripts, dispatched as 3
historical bead-references. **Threshold N=4 distinct not met yet.** When
4th distinct instance accrues, file `runtime_source_corpus()` scope
extension calibration bead.

## 7-bead registry-allowlist arc — `flywheel-cli-surface` owner class reinforced

| # | Bead | Owner class |
|---|---|---|
| 1 | 2xdi.60.1 | skill-owned |
| 2 | 2xdi.72.1 | multi-sibling-skill |
| 3 | 2xdi.132 | plan-doc |
| 4-5 | 2xdi.135/.137 | JSM-managed-skill |
| 6 | 2xdi.144 | **flywheel-cli-surface (introduced)** |
| **7** | **2xdi.148 (this)** | **flywheel-cli-surface (reinforced; 2nd use)** |

5 distinct owner-class types now. flywheel-cli-surface is consolidating
into a canonical owner-class for flywheel-internal CLI scripts.

## Compliance

- AG receipt: 8/8
- META-RULE 2026-05-11: 29th application
- L52: 0 new beads filed (N=3 visible; threshold N=4 not met)
- Boundary preservation: only `.flywheel` substrate edited
- L107: MCP-skipped
- compliance_score: 1000/1000

## xn5bm clustering verification

Verified xn5bm's cluster-detection still functional post-patch:
```bash
$ .flywheel/scripts/gap-hunt-probe.sh --json | jq -e '[.gap_ids[]? | select(startswith("wired-but-cold-cluster:"))] | length > 0'
true
```

Clustering + allowlist coexist correctly.
