---
bead: flywheel-2xdi.99
title: wired-but-cold fix — cubcloud-ops SKILL.md documents setup-cubcloud-wireguard.sh
worker: MistyCliff (flywheel:0.4)
date: 2026-05-11
status: shipped
priority: P3
mission_fitness: adjacent
parent: flywheel-2xdi
sister: flywheel-2xdi.105 (same unmanaged-skill SKILL.md doc-fix recipe)
---

# Journey: flywheel-2xdi.99

## What the bead asked for

`~/.claude/skills/cubcloud-ops/scripts/setup-cubcloud-wireguard.sh`
not referenced by recent flywheel jsonl ledgers in 30d.

## Investigation (N=20 bead-hypothesis META-rule)

- Script exists, WireGuard tunnel bring-up + secrets-aware
  (self-chmod 600, owner-readable only)
- ZERO references across 5 corpora
- One legacy-doc reference (`LATEST.md.legacy`) — not a current corpus
- `jsm show cubcloud-ops` → "not found" → unmanaged
- File mode `-rw-------` (not executable; operator must chmod +x first)

## What I shipped

Per cross-repo-consumer-vs-mutator doctrine: unmanaged → direct mutation
+ paired jsm-import-ready patch.

### Direct mutation

`~/.claude/skills/cubcloud-ops/SKILL.md` — added a WireGuard subsection
inside the existing "### Access Patterns" section. Updated access-
methods list from 2 to 3 (added "3. WireGuard tunnel"). Subsection
covers bring-up + reinstall + secrets handling + when-to-invoke.

### Paired patch artifact

`.flywheel/audit/flywheel-2xdi.99/patches/`:
- SKILL.md.original (850 lines)
- SKILL.md.proposed (864 lines)
- SKILL.md.patch (25-line unified diff)
- apply-instructions.md

## Verification

- SKILL.md now cites the script (corpus #4 hit)
- Fresh probe: gap cleared

## L112 probe

    grep -q "scripts/setup-cubcloud-wireguard.sh" ~/.claude/skills/cubcloud-ops/SKILL.md \
      && bash .flywheel/scripts/gap-hunt-probe.sh --json \
        | jq '.gap_ids[] | select(test("wired-but-cold.*setup-cubcloud-wireguard"))' | wc -l | tr -d ' '

Expected: `literal:0`.

## Pattern note

11th distinct fix shape in 2xdi.* cluster (same as 2xdi.105):
unmanaged-skill direct mutation + paired jsm-import patch.

Cross-repo-mutator pattern N=7 instances this session (xhevf, b6p1m,
n4gt1, myfak.1, d6zk1.1, 105, 99). At N=10 promote to doctrine
sub-section.
