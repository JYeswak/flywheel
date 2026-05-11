---
bead: flywheel-2xdi.126
title: stale-orphan removal — .opencode-era restore-all-skills.sh (Joshua REMOVE)
worker: MistyCliff (flywheel:0.4)
date: 2026-05-11
status: shipped
priority: P3
mission_fitness: adjacent
parent: flywheel-2xdi
sister_recipe: flywheel-d6zk1.1 (1st instance of stale-orphan-removal pattern)
---

# Journey: flywheel-2xdi.126

## What the bead asked for

`~/.claude/skills/restore-all-skills.sh` wired-but-cold.

## Investigation (N=26 bead-hypothesis META-rule)

- 229-byte script at `.claude/skills/` ROOT (not under any specific skill)
- Operates on `~/.opencode/skills/` (different filesystem path than location!)
- `.opencode/skills/` is EMPTY (no _disabled/, no skills)
- Defunct: `.opencode` is the predecessor tooling for `.claude/skills/`
- 4-month stale (mtime 2026-01-14)
- 0 corpus references
- git-tracked in `~/.claude` repo (NOT untracked like d6zk1.1)

## AskUserQuestion → Joshua disposition

Three options surfaced:
- REMOVE (data-supported: empty `.opencode/skills/`, no-op behavior)
- RENAME-LEGACY (preserves discoverability; clears probe)
- LEAVE-AS-IS (harmless; document FP)

Joshua selected **REMOVE** — same pattern as d6zk1.1 earlier this session.

## What I shipped

1. **`git rm` + commit in `~/.claude` repo** (commit `a58579f`):
   - 229 bytes deleted, 10 lines removed
   - Pre-delete sha256: `3391ac03aec5353691b30e9bce4314cd7835abdceb8ebfd14a58ed083748f12f`
2. **JSM-import-ready tombstone** at
   `.flywheel/audit/flywheel-2xdi.126/patches/deletion-tombstone.md`
3. **Offline snapshot copy** at
   `.flywheel/audit/flywheel-2xdi.126/journey/restore-all-skills.sh.snapshot`

3 recovery paths preserved (git history + snapshot + tombstone metadata).

## Verification

- File deleted (`ls -la ~/.claude/skills/restore-all-skills.sh` → "No such file or directory")
- Committed in `~/.claude` repo (`a58579f`)
- Fresh probe: gap cleared

## L112 probe

    test ! -e ~/.claude/skills/restore-all-skills.sh \
      && bash .flywheel/scripts/gap-hunt-probe.sh --json \
        | jq '[.gap_ids[] | select(test("wired-but-cold.*restore-all-skills"))] | length'

Expected: `literal:0`.

## Pattern note

**2nd instance of stale-orphan-removal recipe** (sister to d6zk1.1).
Key difference from d6zk1.1:
- d6zk1.1: untracked .bak files (rm only)
- 2xdi.126: git-tracked .opencode-era script (`git rm` + commit
  in `~/.claude` + tombstone in flywheel audit)

Both follow: AskUserQuestion → snapshot + tombstone → execute → verify.

At N=3 → promote to skill: `pattern-emerged-stale-orphan-removal-with-joshua-directive-and-tombstone-artifact`.

`no_direct_skill_mutation_reason=jsm_unmanaged_with_import_ready_tombstone_artifact_written_and_committed_in_dotclaude_repo`
