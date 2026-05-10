---
title: "Intent — /flywheel:recovery"
type: plan
created: 2026-05-04
frontmatter_source: scaffold-doc-frontmatter
---

# Intent — /flywheel:recovery

## Original prompt (Joshua, 2026-05-01)

> I think we need to use ntm's commands to save all of our sessions and have a recovery process that we run nightly - we need to ensure that if we reboot our system - it all comes back up like it is now

## Topic slug
recovery-system-2026-05-01

## Decision needed
Design and implement /flywheel:recovery so that all 8 active ntm sessions (flywheel, alpsinsurance, clutterfreespaces, picoz, skillos, vrtx, zeststream-v2, zesttube) plus their orchestration state survive a Mac Studio reboot.

## Constraints
- ntm primitives are canonical — extend Jeff's patterns, don't replace
- Joshua-disposes on launchd plist install (touches system-level resources)
- Zero tolerance for losing in-flight worker callbacks during reboot
- Cost-conscious: snapshot job should not run during active worker generation

## Success criteria
1. Reboot Mac Studio → all 8 sessions auto-recreate within 60s of login
2. Last orchestrator handoff per session can be replayed into pane 1
3. Nightly snapshot runs unattended with retention policy
4. Recovery procedure documented + tested end-to-end

## Out of scope (this plan)
- Cross-machine session sync (single Mac Studio only)
- Worker conversation context restoration (cold-start fresh after reboot is acceptable)
- Linux portability
