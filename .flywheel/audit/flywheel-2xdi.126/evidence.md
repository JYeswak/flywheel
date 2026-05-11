# flywheel-2xdi.126 — Evidence Pack

**Bead:** flywheel-2xdi.126 (P3)
**Title:** [gap-wired-but-cold] `.claude/skills/restore-all-skills.sh`
**Mission fitness:** `adjacent` — stale-orphan removal; bead-DB and skills-tree hygiene
**Sister recipe:** flywheel-d6zk1.1 (earlier session, same stale-orphan REMOVE pattern)
**Disposition:** REMOVED via Joshua directive (AskUserQuestion)

## Hypothesis vs root cause (N=26 bead-hypothesis META-rule)

**Bead hypothesis:** script not referenced by flywheel ledgers in last 30d.

**Verified — stronger root cause:**
- Script targets `~/.opencode/skills/` (DIFFERENT from its location `~/.claude/skills/`)
- `~/.opencode/skills/` is EMPTY (no `_disabled/` subdir; no skills)
- Script is a defunct no-op from the `.opencode`-era predecessor system
- ZERO references across all 5 corpora
- Last modified 2026-01-14 (~4 months stale)
- Was git-tracked in `~/.claude` repo (different from d6zk1.1's untracked .bak files)

## Disposition decision

Surfaced via AskUserQuestion (3 options: REMOVE / RENAME-LEGACY / LEAVE-AS-IS).

Joshua selected **REMOVE** (recommended). Same pattern as flywheel-d6zk1.1 earlier this session.

## Acceptance gates (3/3)

| # | Gate | Status |
|---|---|---|
| AG1: Identify gap empirically + probe defunctness | DONE — `.opencode/skills/` empty; 0 corpus references; 4-month stale |
| AG2: Capture Joshua directive | DONE — AskUserQuestion approved REMOVE |
| AG3: Execute disposition + paired tombstone | DONE — `git rm` + commit in `~/.claude` (sha `a58579f`); tombstone written to `.flywheel/audit/flywheel-2xdi.126/patches/`; snapshot copy preserved |

## What I shipped

1. **`git rm skills/restore-all-skills.sh` + commit in `~/.claude`** (commit `a58579f`):
   - 229 bytes deleted, 10 lines removed
   - Pre-delete sha256 captured in tombstone
2. **JSM-import-ready tombstone artifact** at `.flywheel/audit/flywheel-2xdi.126/patches/deletion-tombstone.md`:
   - Path + size + sha256 + mtime
   - Why-removed rationale (5 reasons)
   - Pre-delete safety probes
   - Pre-delete git status (was tracked; recovery commands listed)
   - JSM-import discipline note
3. **Snapshot copy** at `.flywheel/audit/flywheel-2xdi.126/journey/restore-all-skills.sh.snapshot` for offline recovery

## Verification

```bash
$ ls -la ~/.claude/skills/restore-all-skills.sh
# No such file or directory

$ cd ~/.claude && git log -1 --oneline -- skills/restore-all-skills.sh
a58579f chore(skills): remove stale .opencode-era restore-all-skills.sh

$ bash .flywheel/scripts/gap-hunt-probe.sh --json | jq '.gap_ids[] | select(test("wired-but-cold.*restore-all-skills"))'
(empty)   # gap cleared
```

## DID / DIDNT / GAPS

- **DID 3/3** — gap probed, Joshua directive captured, deletion executed + tombstone written
- **DIDNT none**
- **GAPS none**

## Files Changed

Outside flywheel repo:
- `~/.claude/skills/restore-all-skills.sh` (DELETED via `git rm`; committed in `~/.claude` as `a58579f`)

Inside flywheel repo:
- `.flywheel/audit/flywheel-2xdi.126/patches/deletion-tombstone.md` (jsm-import-ready)
- `.flywheel/audit/flywheel-2xdi.126/journey/restore-all-skills.sh.snapshot` (offline recovery)
- `.flywheel/audit/flywheel-2xdi.126/evidence.md` (this file)
- `.flywheel/audit/flywheel-2xdi.126/compliance-pack.md`

## L112 Probe

- `l112_probe_command`: `test ! -e ~/.claude/skills/restore-all-skills.sh && bash .flywheel/scripts/gap-hunt-probe.sh --json | jq '[.gap_ids[] | select(test("wired-but-cold.*restore-all-skills"))] | length'`
- `l112_probe_expected`: `literal:0`
- `l112_probe_timeout_sec`: `60`

## Pattern reinforcement

**Same shape as flywheel-d6zk1.1** (stale-orphan REMOVE earlier this session). Two key differences:

1. **Git-tracked vs untracked:** d6zk1.1 deleted untracked .bak files (no commit); this bead deleted a tracked file (required `git rm` + commit in `~/.claude`)
2. **Targets a defunct sub-system:** the script's logic references `~/.opencode/skills/`, a predecessor tooling system. Removal isn't just "cold script" — it's "dead branch from defunct fork."

Pattern: **stale-orphan-removal in unmanaged-skill territory**:
- d6zk1.1 = untracked .bak files (rm only)
- 2xdi.126 = git-tracked .opencode-era script (`git rm` + commit + tombstone in audit pack)

Both followed: AskUserQuestion for Joshua directive → snapshot + tombstone → execute → verify probe clears.

This is the **2nd instance** of the stale-orphan-removal recipe this session. At N=3 → skill promotion candidate.

## Four-Lens Self-Grade

- **brand:** 10 — honored cross-repo-mutator destructive-action discipline (Joshua directive captured before mutation)
- **sniff:** 10 — investigated defunctness empirically (.opencode/skills empty); 4-month stale; sha256 captured
- **jeff:** 9 — convergent with d6zk1.1 pattern
- **public:** 10 — future operator gets git history + tombstone + snapshot = 3 recovery paths

`no_direct_skill_mutation_reason=jsm_unmanaged_with_import_ready_tombstone_artifact_written_and_committed_in_dotclaude_repo`
