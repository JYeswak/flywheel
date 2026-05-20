# MP-43 — Release installability gate

**Discovered:** 2026-05-19T08:05Z
**Discovered by:** skillos:2
**Skills exemplifying:** 5+

## Essence

A release is not shipped when code builds; it is shipped when the artifact installs, self-tests, and proves its published contents from a clean consumer environment.

## Where it applies

Installers, npm/PyPI packages, binaries, GitHub releases, CLI distribution, docs snippets, and any packaged artifact handed to another operator.

## Adoption signal

Skill has preflight checks, artifact content inspection, clean-environment install verification, and post-install diagnostics before publishing is accepted.

## Exemplar skills (≥5)

- `~/.claude/skills/installer-workmanship/SKILL.md:16` — every installer must include all required pieces.
- `~/.claude/skills/installer-workmanship/SKILL.md:49` — installation sequence is exact and must not be skipped or reordered.
- `~/.claude/skills/installer-workmanship/SKILL.md:77` — post-install diagnostics and self-test are mandatory.
- `~/.claude/skills/installer-workmanship/SKILL.md:454` — preflight checks disk, write access, network, and existing install state.
- `~/.claude/skills/release-preparations/SKILL.md:15` — test gate is mandatory before release.
- `~/.claude/skills/release-preparations/SKILL.md:377` — verify the release was created with expected assets.
- `~/.claude/skills/package-publishing/SKILL.md:88` — verify published package in a clean environment.
- `~/.claude/skills/package-publishing/SKILL.md:105` — dry-run and inspect the tarball before publish.

## Adoption recipes

**Recipe 1 — Artifact manifest:** every release receipt lists expected files, hashes, size, and install command.

**Recipe 2 — Clean consumer:** validate in a fresh temp directory or container, installing only from the published artifact.

**Recipe 3 — Self-test hook:** artifact installs must run a diagnostic command that proves runtime dependencies and entrypoints resolve.

## Compliance test

```bash
grep -E "(dry-run|tarball|clean env|post-install|self-test|expected assets)" SKILL.md || fail
```

## Meta-Learning Cross-References (2026-05-19)
This flywheel doctrine shard was backfilled during batch-14 to keep MP adoption links navigable.
- Related: `.flywheel/doctrine/meta-learnings/MP-54-template-publish-gate.md`
- Related: `.flywheel/doctrine/meta-learnings/MP-68-schema-executable-validator-pair.md`
