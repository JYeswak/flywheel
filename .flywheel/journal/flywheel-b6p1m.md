---
bead: flywheel-b6p1m
title: agent-ergonomics SKILL.md tools/ hygiene — JSM-push-ready patch (sister to xhevf)
worker: MistyCliff (flywheel:0.4)
date: 2026-05-11
status: shipped
priority: P4
mission_fitness: adjacent
sister: flywheel-xhevf (scripts/ side)
related: flywheel-zsk2d (probe per-file-cap regression — unchanged)
---

# Journey: flywheel-b6p1m

## What the bead asked for

Same pattern as xhevf but for `tools/`. Audit + JSM-push-ready patch
for the 10+ undocumented utilities in agent-ergonomics tools/.

## What I shipped

- Audit: 17 tools/, 7 mentioned, 10 missing
- Patch: `.flywheel/audit/flywheel-b6p1m/patches/SKILL.md.patch` (19-line diff)
- Apply-instructions: includes ordering notes — patches are order-independent
  with xhevf (touch different table; `patch` fuzz tolerates the context shift)
- Verified clean against fresh copy of live SKILL.md

## Sister coordination

- xhevf (scripts/) and b6p1m (tools/) are independent JSM patches
- Combined, they bring the SKILL.md script-vs-doc coverage from 33 of 64 to 64 of 64
  (47 scripts + 17 tools)
- Both gated on same probe fix (zsk2d) for empirical wired-but-cold flag clearance

## L112 probe

    patch -p1 --dry-run \
      < /Users/josh/Developer/flywheel/.flywheel/audit/flywheel-b6p1m/patches/SKILL.md.patch \
      < ~/.claude/skills/agent-ergonomics-and-agent-intuitiveness-maximization-for-cli-tools/SKILL.md

Expected: `grep:patching file`.

## Pattern note

This bead is a clean sister application of the xhevf recipe — same JSM
discipline, same patch artifact shape, same verification. No new emergence;
the pattern (JSM-managed-skill SKILL.md hygiene via push-ready patch) is now
proven across two beads.
