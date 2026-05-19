# MP-114 - Tiered pressure recovery ladder

**Discovered:** 2026-05-19T07:46Z
**Discovered by:** skillos:2
**Skills exemplifying:** 4+

## Essence

Machine pressure recovery should be tiered by measured severity, start with read-only probes, climb cheapest-first, re-probe between levels, and require approval before invasive actions.

## Where it applies

Storage pressure, CPU/load saturation, Python environment bloat, ballast daemons, Docker.raw growth, cache cleanup, agent swarms, and any recovery system where an over-eager fix can destroy useful state.

## Adoption signal

The skill defines severity tiers with exit codes, safe recovery levels, forbidden actions, cross-couplings, re-probe requirements, and explicit approval gates for high-risk levels.

## Exemplar skills (>=5)

- `~/.claude/skills/storage-health/SKILL.md:12` - every cleanup primitive gates on a health probe and never auto-fires destructive volume prune.
- `~/.claude/skills/storage-health/SKILL.md:35` - recovery captures exit code, free percentage, and top bloaters before action.
- `~/.claude/skills/storage-health/SKILL.md:82` - recovery is a cheapest-to-nuclear ladder from probe to nuclear cleanup.
- `~/.claude/skills/storage-ballast-helper/SKILL.md:56` - ballast uses predictive monitoring, sacrificial space, cleanup scoring, and zero-write emergency mode.
- `~/.claude/skills/storage-ballast-helper/SKILL.md:144` - predictive ballast and reactive storage-health compose rather than compete.
- `~/.claude/skills/system-health/SKILL.md:48` - CPU/load health uses a five-tier doctrine with exit codes and action class.
- `~/.claude/skills/system-health/SKILL.md:81` - system recovery climbs from probe to pause, renice, kill, and nuclear levels.
- `~/.claude/skills/python-health/SKILL.md:37` - Python recovery captures cache, broken venv, orphan venv, and version distribution before escalation.

## Adoption recipes

**Recipe 1 - Exit-coded probe:** define status tiers, machine-readable fields, and which tier blocks new work.

**Recipe 2 - Ladder table:** list each level, action, typical recovery, risk, and auto-allowed status.

**Recipe 3 - Re-probe brake:** after each recovery action, re-run the probe and stop after bounded escalations.

## Compliance test

```bash
grep -E "(health-probe|exit code|tier|ladder|re-probe|approval|critical|fire|cleanup|pressure)" SKILL.md || exit 1
```
