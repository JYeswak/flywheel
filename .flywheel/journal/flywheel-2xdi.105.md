---
bead: flywheel-2xdi.105
title: wired-but-cold fix — research-triad SKILL.md documents check-goldens.sh
worker: MistyCliff (flywheel:0.4)
date: 2026-05-11
status: shipped
priority: P3
mission_fitness: adjacent
parent: flywheel-2xdi
---

# Journey: flywheel-2xdi.105

## What the bead asked for

`~/.claude/skills/research-triad/scripts/check-goldens.sh` not referenced
by recent flywheel jsonl ledgers (5-corpus check returned 0).

## Investigation (N=19 bead-hypothesis META-rule)

- Script exists, operator-on-demand utility (UPDATE_GOLDENS=1 hint)
- ZERO references in any corpus, including its own SKILL.md
- `jsm show research-triad` → "not found" → unmanaged skill

Per cross-repo-consumer-vs-mutator doctrine (shipped 2xdi.93):
unmanaged → direct mutation + paired jsm-import-ready patch artifact.

## What I shipped

### Direct mutation

`~/.claude/skills/research-triad/SKILL.md` — new "## Operator scripts"
section after the existing "## Substrate" section. Documents
check-goldens.sh with citation (Bachmann & Bird-Gennrich 2018,
Beck 2002 TDD §3) and when-to-invoke discipline.

### Paired patch artifact

`.flywheel/audit/flywheel-2xdi.105/patches/`:
- SKILL.md.original (200 lines)
- SKILL.md.proposed (208 lines)
- SKILL.md.patch (14-line unified diff)
- apply-instructions.md (apply + verify + rollback)

`no_direct_skill_mutation_reason=jsm_unmanaged_with_paired_jsm_import_ready_patch_artifact_written`

## Verification

- SKILL.md now cites check-goldens.sh (corpus #4 hit)
- Fresh probe: `wired-but-cold:check-goldens.sh` cleared

## L112 probe

    grep -q "scripts/check-goldens.sh" ~/.claude/skills/research-triad/SKILL.md \
      && bash .flywheel/scripts/gap-hunt-probe.sh --json \
        | jq '.gap_ids[] | select(test("wired-but-cold.*check-goldens"))' | wc -l | tr -d ' '

Expected: `literal:0`.

## Pattern note

10th distinct fix shape in 2xdi.* cluster: unmanaged-skill direct
mutation + paired jsm-import patch. Sister to agent-ergonomics
SKILL.md hygiene (xhevf/b6p1m/2m2cs) but smaller scale + unmanaged.

Cross-repo-mutator pattern now N=6 instances this session
(xhevf, b6p1m, n4gt1, myfak.1, d6zk1.1, 105). Pattern is well-
established + canonically documented in
`.flywheel/doctrine/cross-repo-consumer-vs-mutator-boundary.md`.
