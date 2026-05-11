---
bead: flywheel-xhevf
title: agent-ergonomics SKILL.md hygiene — JSM-push-ready patch + sub-gap discoveries
worker: MistyCliff (flywheel:0.4)
date: 2026-05-11
status: shipped
priority: P3
mission_fitness: adjacent
parent: flywheel-2xdi (probe corpus parent)
sub_gaps: flywheel-b6p1m (P4 tools/ sister), flywheel-zsk2d (P2 probe per-file-cap regression)
---

# Journey: flywheel-xhevf

## What the bead asked for

Audit agent-ergonomics SKILL.md vs scripts/, add missing references to
eliminate the wired-but-cold FP cluster (10+ flagged).

## What I shipped

A **JSM-push-ready patch artifact**, not a direct SKILL.md mutation.

The skill is JSM-managed (per `jsm list` + `skill-enhance-jsm-discipline.sh
--validate-packet`). The dispatch packet's SKILL-ENHANCE JSM DISCIPLINE
BLOCK explicitly forbids direct mutation; the owning JSM/skillos flow must
apply the patch and `jsm push`.

Artifact at `.flywheel/audit/flywheel-xhevf/patches/`:
- SKILL.md.original (748 lines)
- SKILL.md.proposed (770 lines, +22)
- SKILL.md.patch (31-line unified diff, applies clean via `patch -p1`)
- apply-instructions.md (apply + verify + rollback)

## Findings

- 47 scripts/ files; 26 already in SKILL.md; 21 missing → added by patch
- 14 currently flagged wired-but-cold by gap-hunt-probe (13 scripts/ + 1 tools/)
- Proposed SKILL.md covers 13 of 14 (the 14th is tools/audit-narrative.sh — out-of-scope; sister bead `b6p1m`)

## Sub-discoveries (2 beads filed)

**flywheel-b6p1m (P4)** — `tools/` directory has 17 utilities, only 7 documented in SKILL.md. Same pattern as this bead but for tools/. Will require a sister patch artifact.

**flywheel-zsk2d (P2)** — gap-hunt-probe's skill_md_corpus has a 4KB per-file cap (introduced by 2xdi.66 to fit ~5500 files in 32MB budget). For large SKILL.md files (this one is 748 lines), content past byte-4096 is truncated. The Scripts table starts at line 596, well past the cap — so even scripts ALREADY documented in SKILL.md (audit-readme-vs-help, build-canonical-tasks, measure-help-readtime, run_simulation, sw-self-audit, verify-determinism, verify-non-tty-discipline) show as cold.

This is a regression introduced by 2xdi.66. The empirical proof for THIS bead's AG3 ("re-run probe, 10+ scripts unflag") therefore requires BOTH (a) JSM push of this patch AND (b) `zsk2d` probe fix.

## L112 probe

    patch -p1 --dry-run \
      < /Users/josh/Developer/flywheel/.flywheel/audit/flywheel-xhevf/patches/SKILL.md.patch \
      < ~/.claude/skills/agent-ergonomics-and-agent-intuitiveness-maximization-for-cli-tools/SKILL.md

Expected: `grep:patching file` (verifies the patch still applies clean).

## Pattern note

This bead surfaces a meta-pattern: the 4-step `bead-hypothesis-is-prior` META-rule
(N=11 instances this session) applies even to operator-on-demand SKILL.md
hygiene. The bead's premise was "add SKILL.md mentions, gap clears". Investigation
showed (a) some target scripts were ALREADY mentioned (probe-side issue), and (b)
the skill is JSM-managed (process-side discipline). Both shifted the deliverable
shape from direct edits to a patch artifact + two sub-bead surfacings.
