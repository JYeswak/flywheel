# MP-86 - Clean-room reproduction before upstream action

**Discovered:** 2026-05-19T07:36Z
**Discovered by:** skillos:2
**Skills exemplifying:** 5+

## Essence

External issues, PRs, and generated fixes are only actionable after independent reproduction, fail-before/pass-after evidence, and maintainer-shaped output.

## Where it applies

GitHub issue triage, upstream PRs, security reports, AI-generated code validation, E2E bug reports, and local fixes prompted by third-party reports.

## Adoption signal

The workflow treats reports as hints, reproduces on a clean clone or current environment, writes a minimal test or fixture, verifies old/new behavior, and communicates in a bounded issue/PR template.

## Exemplar skills (>=5)

- `~/.claude/skills/gh-triage-ru/SKILL.md:10` - user reports are hints, not facts.
- `~/.claude/skills/gh-triage-ru/SKILL.md:70` - reproduction steps are not trusted by default.
- `~/.claude/skills/gh-triage-ru/SKILL.md:90` - security reports require code-path analysis and exploit testing.
- `~/.claude/skills/gh-triage-ru/SKILL.md:120` - PRs are mined for intel, not blindly merged.
- `~/.claude/skills/zeststream-pr/SKILL.md:50` - upstream brief includes exact reproduction commands.
- `~/.claude/skills/zeststream-pr/SKILL.md:65` - reproduction must work on a clean clone of upstream HEAD.
- `~/.claude/skills/zeststream-pr/SKILL.md:66` - tests must fail before patch and pass after.
- `~/.claude/skills/ubs/SKILL.md:13` - scanner findings need triage because false positives are common.
- `~/.claude/skills/e2e-testing-for-webapps/SKILL.md:138` - UI fixes loop through reload, snapshot diff, DOM health, screenshot, and verification.
- `~/.claude/skills/testing-e2e-shell-harness-skeleton/SKILL.md:37` - the skeleton has a one-shot test to verify the template still passes.

## Adoption recipes

**Recipe 1 - Reproduce away from your checkout:** use a clean clone, current HEAD, or isolated harness before declaring the report valid.

**Recipe 2 - Prove the delta:** capture fail-before/pass-after with a test, fixture, scan, or screenshot pair.

**Recipe 3 - Shape for maintainers:** write the issue or PR with problem, reproduction, root cause, minimal diff, tests, backward compatibility, and review concerns.

## Compliance test

```bash
grep -E "(repro|clean clone|fail-before|pass-after|fixture|triage|verify|PR|issue)" SKILL.md || exit 1
```

## Meta-Learning Cross-References (2026-05-19)
This flywheel doctrine shard was backfilled during batch-14 to keep MP adoption links navigable.
- Related: `.flywheel/doctrine/meta-learnings/MP-10-codebase-archaeology.md`
- Related: `.flywheel/doctrine/meta-learnings/MP-42-independent-evidence-convergence.md`
