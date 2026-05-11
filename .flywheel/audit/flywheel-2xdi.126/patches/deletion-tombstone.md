# JSM-import-ready deletion tombstone — restore-all-skills.sh

**Skill:** `~/.claude/skills/` ROOT (top-level utility; not under a specific skill)
**Bead:** flywheel-2xdi.126
**Parent bead:** flywheel-2xdi (gap-hunt-probe wired-but-cold class)
**Joshua directive:** REMOVE (2026-05-11, AskUserQuestion approval in worker session)

## What was deleted

| Path | Size | sha256 (pre-delete) | mtime |
|---|---|---|---|
| `~/.claude/skills/restore-all-skills.sh` | 229 bytes | `3391ac03aec5353691b30e9bce4314cd7835abdceb8ebfd14a58ed083748f12f` | 2026-01-14 14:05 |

## Why removed

Script was a defunct `.opencode`-era utility:

```bash
#!/bin/bash
# Restore all disabled skills
cd ~/.opencode/skills
if [ -d "_disabled" ]; then
  mv _disabled/* . 2>/dev/null
  rmdir _disabled 2>/dev/null
  echo "All skills restored"
else
  echo "No disabled skills to restore"
fi
```

Problems:
1. **Targets `~/.opencode/skills/` which is empty** (no `_disabled/` subdir; no skills to restore).
2. **`.opencode/` is the predecessor tooling for the current `.claude/skills/` system** — not in active use.
3. **ZERO references in any active corpus** (flywheel ledgers / commands / dispatch templates / launchd / SKILL.md docs).
4. **Last modified 2026-01-14** — ~4 months stale at deletion time.
5. **At its current state the script is a no-op** (only prints "No disabled skills to restore").

## Pre-delete safety probes

- `git ls-files` in `~/.claude`: `skills/restore-all-skills.sh` (was tracked; deletion was via `git rm` + commit)
- `jsm show restore-all-skills` → "not found" → not JSM-managed
- `~/.opencode/skills/`: present but EMPTY (verified by `ls -la`)
- 5-corpus scan: 0 references

## Pre-delete git status

The file WAS git-tracked in the `~/.claude` repo (NOT untracked like flywheel-d6zk1.1's .bak file). Deletion executed via `git rm` + `git commit` in `~/.claude`, commit `a58579f`. History preserves the file content; recovery is `git show a58579f^:skills/restore-all-skills.sh`.

## Recovery (if ever needed)

```bash
cd ~/.claude
# Pre-delete content reachable via git history:
git show a58579f^:skills/restore-all-skills.sh
# Or:
git log --diff-filter=D -- skills/restore-all-skills.sh
# Then restore from the pre-delete commit
```

A snapshot is also stored alongside this tombstone at
`.flywheel/audit/flywheel-2xdi.126/journey/restore-all-skills.sh.snapshot`
for offline recovery.

## JSM-import discipline

`.claude/skills/` ROOT files are not part of any JSM-managed skill (the per-skill JSM management is keyed on the subdirectory name). The deletion is captured as a tombstone artifact for future JSM-import discipline: if the `~/.claude/skills/` top-level ever becomes JSM-managed in some umbrella form, this tombstone records the removal rationale + content sha256.

## Provenance

- Bead audit: this evidence pack (`.flywheel/audit/flywheel-2xdi.126/`)
- Joshua directive: AskUserQuestion in session 2026-05-11; recorded answer was "REMOVE (Recommended)"
- Sister pattern: `flywheel-d6zk1.1` (the prior stale-orphan removal earlier this session that established the pattern)
- Executed via worker MistyCliff (flywheel:0.4) under dispatch flywheel-2xdi.126-de7f18

`no_direct_skill_mutation_reason=jsm_unmanaged_with_import_ready_tombstone_artifact_written_and_committed_in_dotclaude_repo`
