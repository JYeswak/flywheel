---
bead: flywheel-2xdi.109
title: memory-without-cross-link fix — silent-deaf dispatch doctrine + faqj2 harvest
worker: MistyCliff (flywheel:0.4)
date: 2026-05-11
status: shipped
priority: P3
mission_fitness: adjacent
parent: flywheel-2xdi
sister_recipe: flywheel-2xdi.93 (same forward-link doctrine doc pattern)
faqj2_harvest: flywheel-xbsd8 (memory-without-cross-link blind-spot)
---

# Journey: flywheel-2xdi.109

## What the bead asked for

Memory `feedback_dispatch_post_send_verify_for_silent_deaf.md` not cited
by sampled commands/doctrine/incidents/plans. Orch hint: "Apply same
pattern as 2xdi.93 + harvest blind-spot finding into next-tick faqj2."

## Investigation (N=18 bead-hypothesis META-rule)

Memory documents Shape G silent-deaf class (transport ack ≠ worker
processed). Probe found 0 name-citations across all sampled corpora.

BUT — dispatch-template.md has **6 mentions** of `callback_delivery_verified`,
the very contract this memory documents. The discipline IS load-bearing
in runtime artifacts; the probe just can't see semantic-cross-link.

This dual state (real-gap-by-grep + load-bearing-in-practice) IS the
blind-spot the orch hinted at.

## What I shipped

### Primary: doctrine doc

`.flywheel/doctrine/dispatch-post-send-verification-silent-deaf.md`:
- Summarizes Shape G silent-deaf pattern at canonical-doctrine quality
- Cites the memory as "Canonical memory source"
- Documents post-send verification primitive + re-send mitigation
- Documents `callback_delivery_verified` field discipline
- Notes the behavioral-vs-name cross-linking distinction explicitly

### Harvest: faqj2 self-calibration

`flywheel-xbsd8` filed (P3):
- "memory-without-cross-link class is name-grep-only — misses
  semantically embedded discipline"
- Empirical evidence (callback_delivery_verified ×6 in dispatch template)
- 4 fix options (discipline-token extraction; widen corpus;
  semantic-cross-link metric; accept FP rate)
- Linked to flywheel-2xdi + flywheel-2xdi.93 + flywheel-2xdi.109

## Verification

- New doctrine doc cites memory by name
- Fresh probe: gap_ids no longer contains .109 target
- callback_delivery_verified appears 6 times in dispatch-template.md
  (confirms the faqj2 finding)

## L112 probe

    grep -l "feedback_dispatch_post_send_verify_for_silent_deaf" .flywheel/doctrine/ -r | head -1

Expected: `grep:dispatch-post-send-verification-silent-deaf.md`.

## Pattern note

9th distinct fix shape in 2xdi.* cluster:
- 47/49/64/66 = probe corpus extensions
- 93 = doctrine cross-link
- 90/92 = test-receiver wire-in
- 100 = INCIDENTS citation
- 101/102 = canonical-cli rename
- dnxjb = probe-finder path filter
- 9a3k1 = auto-bead-filer dedup
- **109 = doctrine cross-link + faqj2 harvest** (sister recipe to 93,
  enhanced with orch-hinted meta-finding)

Hint productivity arc N=2:
- 2xdi.101 (Joshua "dedup blind spot") → shipped 3 beads (101+9a3k1+dnxjb)
- 2xdi.109 (orch "harvest faqj2") → shipped 2 beads (109+xbsd8)

At N=3 hint-productivity instances, promote to skill:
`pattern-emerged-orch-hint-productivity-meta-issue-yields-2-to-3x-deliverable-footprint`.
