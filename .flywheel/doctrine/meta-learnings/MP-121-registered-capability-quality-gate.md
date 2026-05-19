# MP-121 - Registered capability quality gate

**Discovered:** 2026-05-19T07:56Z
**Discovered by:** skillos:2
**Skills exemplifying:** 4+

## Essence

Production-facing capabilities need a registry identity, owner, rendered or deployed artifact, quality thresholds, and audit evidence before they are treated as available.

## Where it applies

Agent registries, expert directories, public docs cards, model-backed workflows, deployable agents, operator catalogs, performance-sensitive services, and any capability users can invoke or trust.

## Adoption signal

The workflow adds a structured registry row, renders or deploys the visible artifact, measures against explicit thresholds, binds policy, and leaves an audit trail that can be monitored after release.

## Exemplar skills (>=5)

- `~/.claude/skills/add-expert/SKILL.md:8` - expert onboarding touches both docs and promo-page surfaces.
- `~/.claude/skills/add-expert/SKILL.md:14` - the experts array requires slug, socials, since, and description metadata.
- `~/.claude/skills/add-expert/SKILL.md:42` - the card render command produces the public artifact.
- `~/.claude/skills/add-expert/SKILL.md:48` - verification distinguishes newly rendered output from an already existing card.
- `~/.claude/skills/agent-evaluation/SKILL.md:27` - no agent ships without quality gates and measured evidence.
- `~/.claude/skills/agent-evaluation/SKILL.md:45` - the lifecycle is eval set, run, score, gate, deploy, monitor, improve.
- `~/.claude/skills/agent-governance/SKILL.md:27` - production agents must be registered, policy-bound, and auditable.
- `~/.claude/skills/agent-governance/SKILL.md:124` - every agent action produces an audit record.
- `~/.claude/skills/performance-review/SKILL.md:29` - performance gates measure, check, optimize, and verify before commit.

## Adoption recipes

**Recipe 1 - Registry first:** add the capability identity, owner, version, policy, and public artifact path before implementation is called complete.

**Recipe 2 - Artifact gate:** render, deploy, or publish the user-visible artifact and verify that the run created or refreshed the intended output.

**Recipe 3 - Continuous quality:** define pre-release thresholds, runtime audit records, and post-release monitoring as one lifecycle instead of separate chores.

## Compliance test

```bash
grep -E "(registry|owner|render|artifact|quality gate|threshold|audit|monitor|policy)" SKILL.md || exit 1
```
