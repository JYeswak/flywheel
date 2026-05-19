# MP-45 — Reversible cleanup bundle

**Discovered:** 2026-05-19T08:05Z
**Discovered by:** skillos:2
**Skills exemplifying:** 3+

## Essence

Cleanup is only safe when every deletion or rationalization has a byte-for-byte recovery path, an individual decision record, and a round-trip verification.

## Where it applies

Branch and worktree rationalization, stale artifact cleanup, temp lifecycle, installer replacement, path deduplication, and generated-file removal.

## Adoption signal

Skill requires backups, bundles, reversible branches, one-row-per-target triage, and halt-on-missing-recovery before deleting shared surfaces.

## Exemplar skills (≥5)

- `~/.claude/skills/git-worktree-branch-rationalization/SKILL.md:19` — every removal must be reversible byte-for-byte with backup refs or bundles.
- `~/.claude/skills/git-worktree-branch-rationalization/SKILL.md:46` — five reversibility layers must agree or the workflow halts.
- `~/.claude/skills/git-worktree-branch-rationalization/SKILL.md:52` — apply rationalization on a separate branch, not canonical.
- `~/.claude/skills/git-worktree-branch-rationalization/SKILL.md:64` — no batch deletion; each target is restated and logged.
- `~/.claude/skills/git-worktree-branch-rationalization/SKILL.md:145` — triage TSV has one row per branch/worktree.
- `~/.claude/skills/git-worktree-branch-rationalization/SKILL.md:735` — bundle, byte-equality, and round-trip are verified.
- `~/.claude/skills/path-rationalization/SKILL.md:201` — stale copies are removed after canonical install.
- `~/.claude/skills/installer-workmanship/SKILL.md:454` — preflight detects existing installs before mutation.

## Adoption recipes

**Recipe 1 — Recovery artifact:** before deletion, write a bundle, backup ref, or manifest that can restore the exact bytes.

**Recipe 2 — Per-target row:** no aggregate cleanup command without a triage row for each object and its recovery path.

**Recipe 3 — Round-trip proof:** test restore in a scratch location, then record command, checksum, and result.

## Compliance test

```bash
grep -E "(reversible|bundle|backup ref|round-trip|one row per|byte)" SKILL.md || fail
```
