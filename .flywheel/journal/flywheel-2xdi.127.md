---
bead: flywheel-2xdi.127
title: memory-without-cross-link fix — additive-API compat doctrine (Jeff-precedent)
worker: MistyCliff (flywheel:0.4)
date: 2026-05-11
status: shipped
priority: P3
mission_fitness: adjacent
parent: flywheel-2xdi
sister_recipe: 2xdi.93, 2xdi.109, 2xdi.116, 2xdi.118 (N=5 instance — pattern empirically stable)
---

# Journey: flywheel-2xdi.127

## What the bead asked for

`feedback_legacy_compat_both_empty_either_empty.md` not cited by
sampled commands/doctrine/incidents/plans.

## Investigation (N=24 bead-hypothesis META-rule)

Probed before assuming:
- Memory EXISTS, 2295 bytes (2026-05-08)
- Fresh probe DOES flag it (genuine gap)
- 0 cross-links → load-bearing rule not yet doctrine-discoverable

Memory documents the both-empty / either-empty preservation discipline
for additive API extensions — Jeff's pattern from ntm#131
(working_dir) and ntm#132 (CM workspace). The rule:

```
if A != "" && B != "" && norm(A) != norm(B): reject
else: accept (pass through)
```

## What I shipped

`.flywheel/doctrine/api-additive-compat-both-empty-either-empty.md`:
- TL;DR with formal rule + anti-pattern (reject-when-empty)
- Cites memory as Canonical memory source
- Formal-rule pseudocode
- 6-step apply checklist
- Jeff-precedent quotes (ntm#131 + ntm#132 with commit SHAs)
- 3 named anti-patterns with reasons
- 3 flywheel applications (k4aeu /flywheel:respawn, m482 lint, nvny SD fields)
- Sister doctrine + memory cross-refs
- Conformance + lifecycle

## Verification

- Pre-fix: 0 doctrine references to memory
- Post-fix: doctrine doc cites memory + Jeff precedents by name
- Fresh probe: gap cleared

## L112 probe

    grep -l "feedback_legacy_compat_both_empty_either_empty" .flywheel/doctrine/ -r | head -1

Expected: `grep:api-additive-compat-both-empty-either-empty.md`.

## Skill discovery — N=5 (above promotion threshold)

The "forward-link doctrine doc" recipe is now N=5 instances:
1. 2xdi.93 — cross-repo discipline
2. 2xdi.109 — dispatch verification
3. 2xdi.116 — storage substrate lifecycle (promotion-filed)
4. 2xdi.118 — JSM auth contract (N=4 confirmation)
5. **2xdi.127 — API additive-compat (this)**

Recipe applied unchanged across 5 distinct memory topic classes.
Filed `pattern-emerged-forward-link-doctrine-doc-recipe-for-memory-without-cross-link-N5-empirically-stable`.

## Pattern note

2xdi.* cluster's shape distribution has shifted:
- **doctrine cross-link forward-link**: N=5 ← MOST replicated
- probe corpus extensions: N=4
- unmanaged-skill direct mutation: N=2
- test-receiver wire-in: N=2
- canonical-cli rename: N=2

Doctrine cross-link has overtaken probe corpus extensions as the
single most-replicated 2xdi cluster pattern. Both are probe-side
fixes (memory→doctrine name-cited; or source→corpus); the cluster
is converging on "make discipline grep-discoverable rather than
per-script allowlist" leverage.

This bead's Jeff-precedent anchoring (quoting ntm#131 + ntm#132 with
commit SHAs verbatim from the memory) reinforces the recipe's tier-1
public-lens score — future operators searching for additive-API
compat discipline find Jeff's exact shipped pattern with commit SHAs
for cross-reference.
