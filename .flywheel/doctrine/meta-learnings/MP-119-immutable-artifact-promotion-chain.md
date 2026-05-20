# MP-119 - Immutable artifact promotion chain

**Discovered:** 2026-05-19T07:46Z
**Discovered by:** skillos:2
**Skills exemplifying:** 4+

## Essence

Delivery pipelines should build or resolve an artifact once, verify it through ordered gates, promote the same artifact forward, and keep commit/PR metadata focused enough to audit.

## Where it applies

CI/CD, dependency updates, release PRs, monorepos, Remotion package bumps, generated artifacts, deployment pipelines, and any workflow where rebuilding or vague commits can hide drift.

## Adoption signal

The pipeline uses fail-fast checks, lockfile or version resolution, immutable artifacts, bounded job time, required gates, focused commits, and PR metadata that links changed files to validation.

## Exemplar skills (>=5)

- `~/.claude/skills/ci-cd-pipeline/SKILL.md:30` - standard delivery flows from commit through checks, build, integration, staging, smoke, and production.
- `~/.claude/skills/ci-cd-pipeline/SKILL.md:35` - cheapest checks run first.
- `~/.claude/skills/ci-cd-pipeline/SKILL.md:36` - hermetic builds produce the same artifact from the same commit.
- `~/.claude/skills/ci-cd-pipeline/SKILL.md:37` - artifacts flow forward; build once and deploy the same artifact.
- `~/.claude/skills/ci-cd-pipeline/SKILL.md:106` - deployment gates prevent bad code from reaching production.
- `~/.claude/skills/fix-dependabot/SKILL.md:26` - Dependabot updates one package and leaves lockfile/workspace drift that must be fixed together.
- `~/.claude/skills/fix-dependabot/SKILL.md:49` - verification confirms only expected package and lockfile changes occurred.
- `~/.claude/skills/commit/SKILL.md:55` - commit workflow reviews status and diffs before staging.

## Adoption recipes

**Recipe 1 - Artifact identity:** record commit SHA, dependency version, lockfile hash, build ID, or generated artifact checksum.

**Recipe 2 - Gate ladder:** run lint, unit, build, integration, staging, smoke, and approval gates in cost order.

**Recipe 3 - Focused metadata:** commit and PR text name scope, changed surfaces, tests, and any expected generated drift.

## Compliance test

```bash
grep -E "(artifact|build once|deploy|CI|lockfile|commit|PR|gate|smoke|version|checksum)" SKILL.md || exit 1
```
