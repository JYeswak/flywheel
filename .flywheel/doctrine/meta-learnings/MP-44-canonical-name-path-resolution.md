# MP-44 — Canonical name/path resolution

**Discovered:** 2026-05-19T08:05Z
**Discovered by:** skillos:2
**Skills exemplifying:** 5+

## Essence

Names, paths, and branches are operational contracts; resolve the canonical owner before mutation and remove stale aliases that can silently route work to the wrong surface.

## Where it applies

CLI installs, PATH hygiene, product naming, PR titles, package names, branch cleanup, worker identity, and any workflow with multiple plausible aliases.

## Adoption signal

Skill detects canonical location/name from source-of-truth metadata, verifies runtime resolution, and has an explicit stale-copy cleanup or rejection rule.

## Exemplar skills (≥5)

- `~/.claude/skills/path-rationalization/SKILL.md:88` — `~/.local/bin` is the canonical user binary location.
- `~/.claude/skills/path-rationalization/SKILL.md:172` — verify the binary exists and works at the resolved path.
- `~/.claude/skills/path-rationalization/SKILL.md:201` — remove stale copies after canonical install.
- `~/.claude/skills/path-rationalization/SKILL.md:229` — verify no temp paths remain in PATH.
- `~/.claude/skills/pr-name/SKILL.md:6` — PR title must follow a required format.
- `~/.claude/skills/pr-name/SKILL.md:18` — package name is sourced from package.json.
- `~/.claude/skills/product-naming/SKILL.md:94` — no viable domain path kills a candidate name.
- `~/.claude/skills/git-worktree-branch-rationalization/SKILL.md:49` — detect canonical branch; never assume.

## Adoption recipes

**Recipe 1 — Source field:** receipts include `canonical_source`, `resolved_value`, and `resolution_command`.

**Recipe 2 — Alias sweep:** after installing or renaming, search for stale copies, temp paths, and old labels.

**Recipe 3 — Viability gate:** reject names or paths that cannot be owned, resolved, or discovered by the intended operator.

## Compliance test

```bash
grep -E "(canonical|resolved path|PATH|package.json|domain path|canonical branch)" SKILL.md || fail
```
