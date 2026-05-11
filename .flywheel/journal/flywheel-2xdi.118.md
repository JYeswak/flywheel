---
bead: flywheel-2xdi.118
title: memory-without-cross-link fix — JSM canonical auth contract doctrine
worker: MistyCliff (flywheel:0.4)
date: 2026-05-11
status: shipped
priority: P3
mission_fitness: adjacent
parent: flywheel-2xdi
sister_recipe: 2xdi.93, 2xdi.109, 2xdi.116 (N=4 instance — pattern stable)
---

# Journey: flywheel-2xdi.118

## What the bead asked for

`feedback_jsm_canonical_auth_contract_use_skillos_process.md` not cited
by sampled commands/doctrine/incidents/plans.

## Investigation (N=23 bead-hypothesis META-rule)

Probed before assuming:
- Memory EXISTS, 3260 bytes (Joshua 2026-05-08T~23:30Z directive)
- Fresh probe DOES flag it (NOT resolved-upstream)
- 0 cross-links across doctrine/INCIDENTS/AGENTS/commands → genuine gap

Memory documents the JSM auth canonical contract: 4 invariants, anti-pattern
(NEVER manually `jsm login` without `JSM_DISABLE_KEYRING=1`), recovery
procedure, canonical setup recipe.

## What I shipped

`.flywheel/doctrine/jsm-canonical-auth-contract.md` — doctrine doc:
- TL;DR with Joshua-quoted directive
- Cites memory + skillos-canonical contract path
- 2-layer contract description (jsm itself + skillos guarded runner)
- 4-invariant probe table with concrete checks
- Anti-pattern (NEVER manual jsm login without keyring disable)
- 3-step recovery procedure
- Canonical setup recipe (5-line idempotent)
- Sister doctrine cross-refs + skillos canonical paths
- Conformance + lifecycle sections

## Verification

- Pre-fix: 0 doctrine references to memory
- Post-fix: doctrine doc cites memory + skillos contract
- Fresh probe: gap cleared

## L112 probe

    grep -l "feedback_jsm_canonical_auth_contract_use_skillos_process" .flywheel/doctrine/ -r | head -1

Expected: `grep:jsm-canonical-auth-contract.md`.

## Skill discovery — N=4 confirmation

The "forward-link doctrine doc" recipe has now shipped 4 times this session:
1. 2xdi.93 — consumer-vs-mutator → boundary doctrine
2. 2xdi.109 — silent-deaf → dispatch-post-send doctrine
3. 2xdi.116 — jeff-corpus → substrate-lifecycle doctrine
4. **2xdi.118 — JSM auth contract → canonical-auth-contract doctrine** (this)

N=4 confirms the N=3 promotion candidate from 2xdi.116. Recipe applied
unchanged across 4 distinct memory topics (cross-repo, dispatch,
storage, auth) — empirically stable.

Filed `pattern-emerged-forward-link-doctrine-doc-recipe-for-memory-without-cross-link-N4-confirmed`.

## Pattern note

14th distinct fix shape entry, 4th instance of "doctrine cross-link"
(now most-replicated pattern in 2xdi.* cluster — tied with corpus
extensions at 4 instances).

Cluster fix-shape distribution:
- **doctrine cross-link forward-link**: N=4 (93, 109, 116, 118)
- **probe corpus extensions**: N=4 (47, 49, 64, 66)
- unmanaged-skill direct mutation + paired patch: N=2 (105, 99)
- test-receiver wire-in: N=2 (90, 92)
- canonical-cli rename: N=2 (101, 102)
- other singletons: 100, dnxjb, 9a3k1, 113

The two most-replicated patterns are both probe-side fixes (extending
the corpus OR adding a doctrine entry that the corpus picks up).
Cluster work is converging on probe-side leverage.
