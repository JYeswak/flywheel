---
bead: flywheel-2xdi.135
title: wired-but-cold fix — JSM-managed skill case (registry + jsm-push-ready dual-fix)
worker: MagentaPond (flywheel:0.3)
date: 2026-05-11
status: shipped
priority: P3
mission_fitness: adjacent
parent: flywheel-2xdi
sister_recipe: flywheel-2xdi.60.1 + 2xdi.72.1 + 2xdi.132 (registry-allowlist)
new_design_dimensions: kind=scaffold-test (NEW) + JSM-managed-skill case (NEW)
posterior_shape: wired-but-cold-with-JSM-managed-owning-skill
---

# Journey: flywheel-2xdi.135

## What the bead asked for

gap-wired-but-cold for `~/.claude/skills/slack-migration-to-mattermost-phase-1-extraction/scripts/smoke-test-phase1.sh` — end-to-end smoke test for the Phase 1 extraction pipeline. Operator-on-demand by design.

## Investigation (META-RULE 2026-05-11 — 23rd application)

5-corpus probe confirms genuine TP (corpus 1 only via gap-hunt.jsonl self-ref;
no canonical-doctrine citation in corpora 2-5).

**CRITICAL DECISION POINT**: `jsm list` shows the owning skill
`slack-migration-to-mattermost-phase-1-extraction` IS JSM-managed. Per dispatch
SKILL-ENHANCE JSM DISCIPLINE BLOCK, direct mutation under
`~/.claude/skills/<skill>/` is **forbidden**.

This BLOCKS the sister-precedent path from 2xdi.104/.105/.119 (research-triad
SKILL.md direct citation) — research-triad is UNMANAGED in JSM; this skill IS managed.

## Disposition: Dual-fix architecture

| Fix | Target | JSM status | Mutation type |
|---|---|---|---|
| **Primary** | `.flywheel/data/substrate-registry.json` | `.flywheel` UNMANAGED | Direct (allowed) |
| **Defense-in-depth** | slack-migration SKILL.md | **MANAGED** | jsm-push-ready artifact only |

Primary fix clears the probe immediately via registry on_demand allowlist.
JSM-push-ready artifact captures the SKILL.md Script Contracts row addition
for the owning JSM/skillos flow to apply at next push cycle.

## What I shipped

### Primary: substrate-registry entry (46 → 47)
- `kind=scaffold-test` (NEW use of existing _ON_DEMAND_VALIDATOR_KINDS member)
- `lifecycle_state=active`
- `owner=slack-migration-to-mattermost-phase-1-extraction`
- `effect=on_demand_smoke_test_phase1_extraction_pipeline`

### JSM-push-ready patch artifact
`.flywheel/audit/flywheel-2xdi.135/skill-md-jsm-push-ready-patch.md` — SKILL.md
Script Contracts table row addition. For owning JSM/skillos flow to apply via
`jsm push`. NOT a direct-mutation artifact.

### Paired jsm-import-ready patch + backup
- `.flywheel/audit/flywheel-2xdi.135/substrate-registry-patch.json`
- `.flywheel/audit/flywheel-2xdi.135/substrate-registry.before.json`

## Sister-pattern matrix extension — 4-dimension design space

| # | Bead | kind | lifecycle | JSM-owner | Mutation path |
|---|---|---|---|---|---|
| 1 | 2xdi.60.1 | audit | active | (operator-only) | direct registry |
| 2 | 2xdi.72.1 | scaffold | active | unmanaged (3 sibling skills) | direct registry + direct SKILL.md OK |
| 3 | 2xdi.132 | scaffold | **planned (NEW)** | (operator-only) | direct registry |
| 4 | **2xdi.135** (this) | **scaffold-test (NEW)** | active | **JSM-MANAGED (NEW)** | direct registry + **jsm-push-ready artifact only** |

Two NEW dimensions:
- `kind=scaffold-test` (existing _ON_DEMAND_VALIDATOR_KINDS member, first use)
- JSM-managed-skill case (forces jsm-push-ready path; not direct mutation)

5th instance recurrence could extend matrix with:
- `kind=validator` / `kind=self-test` (remaining _ON_DEMAND_VALIDATOR_KINDS values)
- `lifecycle_state={legacy, deprecated}` (per 2xdi.132 sister extension)
- mixed JSM-managed siblings (when one skill in a multi-skill add has different mgmt status)

## Probe verification

```bash
$ .flywheel/scripts/gap-hunt-probe.sh --json | jq -c '{flagged: ([.gap_ids[]? | select(test("smoke-test-phase1"))] | length > 0)}'
{"flagged":false}
```

Cleared via on_demand_script_allowlist (registry).

## JSM discipline observed

`no_direct_skill_mutation_reason=jsm_managed_patch_artifact_written`

This is the first wired-but-cold bead this session where the owning skill is
JSM-managed. The discipline BLOCKS the simpler direct-SKILL.md-cite path
that worked for research-triad (2xdi.104/.105/.119).

## Compliance

- AG receipt: 8/8
- META-RULE 2026-05-11: 23rd application
- L52: 0 new beads filed
- Boundary preservation: NO direct mutation of JSM-managed skill; only
  unmanaged `.flywheel` substrate edited
- compliance_score: 1000/1000

## Operational impact

When the JSM/skillos flow next processes the skill:
1. Apply the SKILL.md Script Contracts row from `.flywheel/audit/flywheel-2xdi.135/skill-md-jsm-push-ready-patch.md`
2. `jsm push` propagates to all install destinations
3. Defense-in-depth: probe corpus 4 (skill_md_corpus) now contains the script
   name, providing a second clearance path beyond the registry allowlist

The 4-dimension matrix is now a canonical decision template for future
registry-allowlist bead disposition: kind × lifecycle × JSM-managed.
