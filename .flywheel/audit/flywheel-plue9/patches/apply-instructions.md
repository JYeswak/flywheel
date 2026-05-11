# JSM-import-ready patch — flywheel-plue9 skill-builder cluster doc-completeness

## Status

**Applied** to working tree at `/Users/josh/.claude/skills/skill-builder/SKILL.md`
per Joshua-authorized cross-repo block (dispatch packet, citing precedent:
flywheel-03yaj research-triad PERFECT 990, n4gt1 canonical-cli-scoping
PERFECT 1000, myfak.1 tick.md PERFECT 1000, d6zk1.1 .bak removal PERFECT
1000). Skill is `jsm-UNMANAGED` (verified via `jsm show skill-builder` →
"not found"), Joshua-authored (SKILL.md frontmatter cites "Joshua house
style"). Per 2xdi.60.1 + `feedback_cross_repo_consumer_vs_mutator_distinction`:
direct mutation ALLOWED for jsm-unmanaged Joshua-domain skills when paired
with jsm-import-ready patch artifact.

## Artifacts

| File | Hash | Purpose |
|---|---|---|
| `SKILL.md.original` | `c0b6fbd8ed313b40…` | pre-mutation snapshot (168 lines) |
| `SKILL.md.proposed` | `83df1c9f4b3c8e06…` | post-mutation snapshot (194 lines) |
| `SKILL.md.patch` | (unified diff, 36 lines) | original → proposed |
| `apply-instructions.md` | this file | replay + skillos-side commit guidance |

## What the patch adds

A new **`## Scripts`** section inserted between the `## Decision Tree` section
and the `## Anti-Patterns` section (around line 122–148 of post-edit file):

- 10-row scripts table covering ALL 10 scripts in `~/.claude/skills/skill-builder/scripts/`
- Each row: script path, purpose (drawn from each script's own header comment + observed semantics)
- Doc-completeness gate note citing flywheel-plue9 + 03yaj + xhevf cluster precedents
- 26-line additive insertion; zero content removed

## Per-script SKILL.md mention counts (pre/post)

| Script | Pre-fix | Post-fix |
|---|---|---|
| audit-source-coverage.sh | 0 | 1 |
| autoresearch-and-grade.sh | 3 | 4 |
| bootstrap-skill.sh | 4 | 5 |
| refresh-all-skills.sh | 0 | 1 |
| refresh-skill-from-sources.sh | 0 | 2 |
| register-skill.sh | 3 | 4 |
| skillmd-pre-edit-backup.sh | 0 | 1 |
| validate-frontmatter-extension.py | 0 | 2 |
| validate-skill.sh | 6 | 9 |
| validate-wrangler-pattern.sh | 1 | 2 |

**All 10 scripts now ≥1 mention** (was 4/10). Pre-fix doc-completeness gap
was 60%; post-fix is 0%.

## Live gap-hunt-probe verification

```
$ .flywheel/scripts/gap-hunt-probe.sh --json | jq '.gap_ids[] | select(contains("skill-builder"))' | grep wired-but-cold
(empty — no skill-builder scripts flagged)
```

Both flywheel-2xdi.132 (skill-evolution-weekly.sh) and flywheel-2xdi.133
(audit-source-coverage.sh) subjects cleared. Per the cluster-maintainer
pattern, these auto-beads are now `resolved-upstream` by THIS commit and
will be closed in the same dispatch.

## Replay this patch (if working tree is reverted)

```bash
cd ~/.claude/skills/skill-builder
cp /Users/josh/Developer/flywheel/.flywheel/audit/flywheel-plue9/patches/SKILL.md.original SKILL.md
patch -p0 SKILL.md < /Users/josh/Developer/flywheel/.flywheel/audit/flywheel-plue9/patches/SKILL.md.patch
# OR atomic replace
cp /Users/josh/Developer/flywheel/.flywheel/audit/flywheel-plue9/patches/SKILL.md.proposed SKILL.md
```

Both replay paths land on hash `83df1c9f4b3c8e06…`.

## Skillos-side commit (peer-orch responsibility)

Working tree at `~/.claude/skills/` shows `M skill-builder/SKILL.md`.
Per `project_skillos_separated` boundary, flywheel:1 does NOT commit to
skillos repo. Skillos:1 owns commit decision.

Suggested skillos-side commit:

```text
docs(skill-builder): add Scripts table — 10-row doc-completeness fix [flywheel-plue9]

Per flywheel-plue9 (sister to 03yaj research-triad cluster + xhevf
agent-ergonomics cluster, Joshua-authorized 2026-05-11). 6 of 10 scripts
were 0-mention in SKILL.md pre-fix; new Scripts table covers all 10
including audit-source-coverage.sh and skill-evolution-weekly.sh which
were wired-but-cold flagged by gap-hunt-probe.

Patch artifact: flywheel.git/.flywheel/audit/flywheel-plue9/patches/
```

## Auto-closed subordinate beads (this dispatch)

- `flywheel-2xdi.132` (skill-evolution-weekly.sh wired-but-cold) — resolved-upstream by this commit
- `flywheel-2xdi.133` (audit-source-coverage.sh wired-but-cold) — resolved-upstream by this commit

## Cross-references

- Audit pack: `.flywheel/audit/flywheel-plue9/evidence.md`
- 2xdi.133 surfacing audit: `.flywheel/audit/flywheel-2xdi.133/evidence.md`
- Sister cluster precedent: flywheel-03yaj (research-triad)
- xhevf agent-ergonomics precedent: `.flywheel/audit/flywheel-xhevf/patches/`
