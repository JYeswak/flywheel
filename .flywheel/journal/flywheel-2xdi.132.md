---
bead: flywheel-2xdi.132
title: wired-but-cold fix — substrate-registry allowlist with lifecycle_state=planned innovation
worker: MagentaPond (flywheel:0.3)
date: 2026-05-11
status: shipped
priority: P3
mission_fitness: adjacent
parent: flywheel-2xdi
sister_recipe: flywheel-2xdi.60.1 (1-entry kind=audit) + flywheel-2xdi.72.1 (6-entry kind=scaffold)
new_design_dimension: lifecycle_state=planned (1st use; was implicitly active before)
posterior_shape_refined: script-planned-in-doctrine-doc-but-launchd-plist-never-deployed
---

# Journey: flywheel-2xdi.132

## What the bead asked for

gap-wired-but-cold for `~/.claude/skills/scripts/skill-evolution-weekly.sh` —
auto-filed by gap-hunt-probe ("script not referenced by recent flywheel
jsonl ledgers modified in last 30d").

## Investigation (META-RULE 2026-05-11 — 22nd application)

5-corpus probe surfaced a NUANCED state:

| Corpus | Match? |
|---|---|
| 1. recent_ledger | ✓ via gap-hunt.jsonl (self-ref) |
| 2. sibling-repo | ✗ |
| 3. runtime_source | ✗ (no other .sh references; only itself) |
| 4. SKILL.md | ✗ |
| 5. launchd_plist | ✗ |

BUT: the script IS documented in `~/.claude/skills/SKILL-EVOLUTION-PLAN.md`
(a plan doc, NOT a SKILL.md) with a FULL launchd plist config. The plist
config exists in the plan doc; the actual plist at `~/Library/LaunchAgents/`
was never deployed.

**Refined posterior shape:**
`script-planned-in-doctrine-doc-but-launchd-plist-never-deployed`.

Probe IS correct (script is genuinely cold). Decision tree:

| Option | Description | Cost / Risk |
|---|---|---|
| A | Cite in a SKILL.md | No owning skill; script lives at top-level skills/scripts/ |
| **B** ★ | substrate-registry allowlist with lifecycle_state=planned | Read-only edit; clears probe; preserves planned-status |
| C | Create the launchd plist (activate weekly cron) | Recurring system-level action — requires Joshua authorization |

Selected B — Option C requires Joshua decision on whether the SKILL-EVOLUTION-PLAN
is still active doctrine or legacy.

## What I shipped

### Primary: substrate-registry allowlist entry

`~/.claude/skills/.flywheel/data/substrate-registry.json` — 45 → 46 entries.
**NEW design innovation:** `lifecycle_state=planned` (previously all entries
were implicitly active).

```json
{
  "name": "skill-evolution-weekly-orchestrator",
  "kind": "scaffold",
  "lifecycle_state": "planned",
  "lifecycle_stage": "on-demand-planned-not-deployed",
  "where": "/Users/josh/.claude/skills/scripts/skill-evolution-weekly.sh",
  "effect": "planned_weekly_orchestrator_not_yet_launchd_scheduled"
}
```

### Paired jsm-import-ready patch artifact + backup
- `.flywheel/audit/flywheel-2xdi.132/substrate-registry-patch.json`
- `.flywheel/audit/flywheel-2xdi.132/substrate-registry.before.json` (285KB)

### Follow-up question surfaced for orch

A) Activate (deploy launchd plist)
B) Remove (delete script + remove plan doc cite)
C) Preserve as planned-only (this patch's status quo)

## Sister-pattern extension — lifecycle_state design dimension

| # | Bead | Scripts | lifecycle_state |
|---|---|---|---|
| 1 | 2xdi.60.1 | agentmail-fd-pressure-probe | active |
| 2 | 2xdi.72.1 | render_scorecard_html + migrate-scores × 3 | active |
| 3 | **2xdi.132** (this) | skill-evolution-weekly-orchestrator | **planned (NEW)** |

If 4th instance recurs with another lifecycle state, consider expanding to:
- `lifecycle_state=legacy` (script was active but deprecated)
- `lifecycle_state=deprecated` (script slated for removal)

## Substrate-self-improving loop interaction

This bead is NOT a memory-without-cross-link instance (wired-but-cold class
instead). The pmg3c auto-injection correctly passed through (0 FORWARD-LINK
blocks in dispatch packet — correct passthrough behavior for non-trigger
class). Validates the inject-forward-link-recipe.sh trigger-detection
discipline.

## Compliance

- AG receipt: 8/8
- META-RULE 2026-05-11: 22nd application
- L52: 0 new beads filed; `no_bead_reason=substrate_registry_allowlist_clears_probe_orch_decides_activation_via_followup_dispatch`
- Boundary preservation: only registry + audit + journal; no launchd activation
- L107: MCP-skipped (unique-per-bead paths)
- compliance_score: 1000/1000

## Operational impact

Probe-cleared via Meadows #5 (fix the property `script-not-in-on-demand-allowlist`).
Meadows #6 (`missing-launchd-plist`) deferred to Joshua decision through
orch follow-up dispatch if warranted.

The 3-option triage (A activate / B remove / C preserve) is captured in the
patch artifact + this journal for next orchestrator tick to surface.
