# JSM-import-ready deletion tombstone — flywheel.bak backups

**Skill:** `~/.claude/skills/.flywheel` (JSM-unmanaged at delete time)
**Bead:** flywheel-d6zk1.1
**Parent bead:** flywheel-d6zk1 (audit; closed)
**Joshua directive:** REMOVE both (2026-05-11, AskUserQuestion approval in worker session)

## What was deleted

| Path | Size | sha256 (pre-delete) | mtime |
|---|---|---|---|
| `~/.claude/skills/.flywheel/bin/flywheel.bak-2026-04-28-pre-substrate-intake` | 129540 bytes | `faa53b7118b66e60114c41e5290655e65c9d08f0ab96b274e8adb8b611788cf7` | 2026-04-28 14:04 |
| `~/.claude/skills/.flywheel/bin/flywheel.bak-2026-04-28-pre-3fail-fix` | 127278 bytes | `9bbbf2719e8494676a70a6555b1684bce50628292adb3667df76c5db286e4bb9` | 2026-04-28 12:40 |

Total: 256818 bytes (~251KB) reclaimed.

## Pre-delete safety probes

- `git ls-files` against both paths returned empty — files are NOT tracked by git
- `.flywheel` skill is JSM-unmanaged (per `.flywheel/scripts/skill-enhance-jsm-discipline.sh --validate-packet`)
- Parent bead `flywheel-d6zk1` audit confirmed zero active-code references (10 doc-class refs only)
- Substrate-intake recovery anchored in 6+ in-repo receipts (WORK.md, STATE.md, PATTERNS.md, CHANGELOG.md, data/substrate-registry.json, file-write-ledger.jsonl)

## Recovery if needed

The substrate-intake event is recoverable via git in `~/.claude/skills/`:

```bash
cd ~/.claude/skills
# Pre-intake state of the binary:
git log --until=2026-04-28T14:04Z -- .flywheel/bin/flywheel
git show <sha>:.flywheel/bin/flywheel
```

The deleted files were themselves snapshots taken pre-rewrite; their content is reachable via the corresponding pre-rewrite git commits in `~/.claude/skills/`.

## JSM-import discipline

Since `.flywheel` is currently JSM-unmanaged, the dispatch contract requires "a paired `jsm-import-ready` patch artifact so the change can be imported into JSM later." This tombstone IS that artifact.

When `.flywheel` becomes JSM-managed in the future, the JSM-side source should NOT include `flywheel.bak-2026-04-28-*` files. Importing the current state will naturally exclude them (since they no longer exist).

## Provenance

- Bead audit: `.flywheel/audit/flywheel-d6zk1/evidence.md`
- Joshua directive: AskUserQuestion in session 2026-05-11; recorded answer was "REMOVE both (Recommended)"
- Executed via worker MistyCliff (flywheel:0.4) under dispatch flywheel-d6zk1.1-37d4bf
