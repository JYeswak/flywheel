# flywheel-d6zk1.1 — Evidence Pack

**Bead:** flywheel-d6zk1.1 (P4)
**Title:** [d6zk1-execute] execute archive-or-remove of flywheel.bak-2026-04-28-pre-substrate-intake per Joshua directive
**Mission fitness:** `adjacent` — accreting-surface retention discipline
**Parent:** flywheel-d6zk1 (audit; closed)

## Joshua directive

Captured 2026-05-11 via AskUserQuestion in worker session — Joshua selected **"REMOVE both (Recommended)"**. Both target files deleted; tombstone written for future JSM-import discipline.

## Acceptance gates (3/3)

| # | Gate | Status |
|---|---|---|
| AG1 | Joshua directive captured (archive vs remove) | DONE — REMOVE chosen |
| AG2 | Execute on directive: delete or archive both backup files | DONE — both files removed |
| AG3 | Sister file (flywheel.bak-2026-04-28-pre-3fail-fix) covered in same pass | DONE — both deleted in one pass |

## Pre-delete safety probes (per CLAUDE.md "Executing actions with care")

- `git ls-files` for both paths in `~/.claude/skills/`: empty (files UNTRACKED — no git change introduced by delete)
- `.flywheel` skill JSM status: unmanaged (per `skill-enhance-jsm-discipline.sh --validate-packet`)
- Parent bead `flywheel-d6zk1` audit: zero active-code references; substrate-intake recovery anchored in 6+ in-repo receipts + git history
- Joshua directive: explicit REMOVE approval via AskUserQuestion

## Files removed

| Path | Size | sha256 (pre-delete) |
|---|---|---|
| `~/.claude/skills/.flywheel/bin/flywheel.bak-2026-04-28-pre-substrate-intake` | 129540 | `faa53b7118b66e60114c41e5290655e65c9d08f0ab96b274e8adb8b611788cf7` |
| `~/.claude/skills/.flywheel/bin/flywheel.bak-2026-04-28-pre-3fail-fix` | 127278 | `9bbbf2719e8494676a70a6555b1684bce50628292adb3667df76c5db286e4bb9` |

Total reclaimed: 256818 bytes (~251KB).

## Post-delete verification

```bash
ls -la ~/.claude/skills/.flywheel/bin/flywheel.bak-2026-04-28-pre-substrate-intake \
       ~/.claude/skills/.flywheel/bin/flywheel.bak-2026-04-28-pre-3fail-fix 2>&1
# → "No such file or directory" for both (expected; files removed)
```

## Recovery path (if ever needed)

Substrate-intake event content is reachable via `~/.claude/skills/` git history:

```bash
cd ~/.claude/skills
git log --until=2026-04-28T14:04Z -- .flywheel/bin/flywheel
git show <sha>:.flywheel/bin/flywheel
```

Plus the 6+ in-repo recovery receipts (WORK.md, STATE.md, PATTERNS.md, CHANGELOG.md, data/substrate-registry.json, file-write-ledger.jsonl) document the intake event itself.

## JSM-import discipline

`.flywheel` skill is unmanaged. Dispatch contract requires "paired `jsm-import-ready` patch artifact". Tombstone written at `.flywheel/audit/flywheel-d6zk1.1/patches/deletion-tombstone.md` — when `.flywheel` becomes JSM-managed, the import will naturally exclude these deleted paths.

## DID / DIDNT / GAPS

- **DID 3/3** — directive captured, deletion executed, both files covered
- **DIDNT none**
- **GAPS none** — clean execution; data + Joshua agreed

## Files Changed

Outside flywheel repo: 2 file deletions in `~/.claude/skills/.flywheel/bin/` (untracked; no git change).

Inside flywheel repo:
- `.flywheel/audit/flywheel-d6zk1.1/evidence.md` (this file)
- `.flywheel/audit/flywheel-d6zk1.1/compliance-pack.md`
- `.flywheel/audit/flywheel-d6zk1.1/patches/deletion-tombstone.md` (jsm-import-ready)
- `.flywheel/audit/flywheel-d6zk1.1/journey/...`

## L112 Probe

- `l112_probe_command`: `test ! -e ~/.claude/skills/.flywheel/bin/flywheel.bak-2026-04-28-pre-substrate-intake && test ! -e ~/.claude/skills/.flywheel/bin/flywheel.bak-2026-04-28-pre-3fail-fix && echo ok`
- `l112_probe_expected`: `literal:ok`
- `l112_probe_timeout_sec`: `5`

## Four-Lens Self-Grade

- **brand:** 9 — Joshua directive captured via canonical AskUserQuestion; no autonomous destruction
- **sniff:** 10 — pre-delete sha256s captured; recovery path documented; tombstone artifact for future JSM import
- **jeff:** 9 — JSM discipline preserved despite unmanaged skill
- **public:** 10 — future operator gets full provenance trail in tombstone + evidence

`no_direct_skill_mutation_reason=jsm_unmanaged_with_import_ready_tombstone_artifact_written`
