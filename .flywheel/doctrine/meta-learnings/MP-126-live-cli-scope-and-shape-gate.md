# MP-126 - Live CLI scope and shape gate

**Discovered:** 2026-05-19T07:56Z
**Discovered by:** skillos:2
**Skills exemplifying:** 4+

## Essence

CLI automation needs explicit scope boundaries, flag-order discipline, read-first state checks, machine-readable output, and shape verification before consuming or mutating results.

## Where it applies

Live APIs, archived datasets, GitHub automation, social monitoring, release workflows, local editor commands, optimized toolchains, and scripts that pipe CLI output into agents.

## Adoption signal

The skill states whether the CLI is live or archived, authenticates before use, puts global flags where the parser expects them, prefers JSON for scripting, reads state before mutation, and verifies feature or output shape.

## Exemplar skills (>=5)

- `~/.claude/skills/x-cli/SKILL.md:8` - x-cli hits the live API and every invocation costs quota.
- `~/.claude/skills/x-cli/SKILL.md:11` - x-cli is live X while `/xf` is archived X conversations.
- `~/.claude/skills/x-cli/SKILL.md:61` - output flags should be explicit, with JSON for jq or agents.
- `~/.claude/skills/x-cli/SKILL.md:66` - global flags must appear before the subcommand.
- `~/.claude/skills/x-cli/SKILL.md:80` - misplaced flags caused silent empty results and quota loss.
- `~/.claude/skills/gh-cli/SKILL.md:145` - PR state, CI state, issues, and API shape are read before action.
- `~/.claude/skills/gh-cli/SKILL.md:156` - merging from memory is an anti-pattern; read SHA, checks, and merge state first.
- `~/.claude/skills/rg-optimized/SKILL.md:31` - the optimized ripgrep build verifies features after install.
- `~/.claude/skills/cursor/SKILL.md:20` - editor automation can target an exact file and line.

## Adoption recipes

**Recipe 1 - Scope header:** declare live versus archived source, quota cost, auth state, and mutation boundary.

**Recipe 2 - Shape-safe invocation:** put global flags first, use JSON for scripts, and test output with `jq` or equivalent before piping.

**Recipe 3 - Read before write:** fetch current state, identifiers, checks, or feature flags before posting, merging, deleting, installing, or opening.

## Compliance test

```bash
grep -E "(live|archive|quota|auth|json|global flag|before the subcommand|read.*before|verify|shape)" SKILL.md || exit 1
```
