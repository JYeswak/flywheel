---
bead: flywheel-2xdi.150
title: wired-but-cold fix — fs-rag-sibling-rollout (test-receiver recipe extension to mutation tool)
worker: MistyCliff (flywheel:0.4)
date: 2026-05-11
status: shipped
priority: P3
mission_fitness: adjacent
parent: flywheel-2xdi
sister_recipe: 2xdi.90/.92/.146/.147 (N=5 instance; FIRST extension to mutation-tool shape)
---

# Journey: flywheel-2xdi.150

## What the bead asked for

`.flywheel/scripts/fs-rag-sibling-rollout.sh` wired-but-cold.

## Investigation (N=36 bead-hypothesis META-rule)

Probed empirically:
- Script exists (6333 bytes, 2026-05-11 00:54)
- **NOT a probe** (no -probe.sh suffix, no canonical-cli triad: --info returns ERR)
- Is a **mutation tool**: --apply/--idempotency-key/--dry-run default
- Owns flywheel-uwqf0 (sibling fs-rag rollout)
- Parent bead flywheel-hi4e6 (Meadows #5 refinement)
- 0 active corpus receivers; all hits are audit-pack docs

## Recipe-extension decision

The test-receiver wire-in recipe was promoted at N=4 (2xdi.146) for
probe-class scripts. This bead is a non-probe; the recipe SHAPE applies
(test file under canonical-cli naming = corpus #5 hit) but assertions
must adapt.

Adapted assertions (vs probe-class):
- Drop: canonical-cli triad envelope checks (--info/--schema/--doctor)
- Drop: schema_version stability
- Drop: READ-ONLY anti-pattern
- Add: --apply refuses without --idempotency-key (mutation discipline)
- Add: stable exit codes documented (0/1/64)
- Add: default --dry-run discipline
- Add: bead-citation chain (owner + parent + doctrine cross-ref)
- Add: defensive arg parse (unknown arg rejected)

## What I shipped

`tests/fs-rag-sibling-rollout-canonical-cli.sh` (112 lines, 12/12 PASS):
- Syntax + VERSION + --help
- Mutation discipline (--apply gating)
- Exit codes documented
- --dry-run default documented
- Bead-citation chain (uwqf0 + hi4e6 + apply-spec.md)
- Defensive arg parse
- --json flag accepted (no parse error)

## Verification

- 12/12 PASS
- Fresh probe: fs-rag-sibling-rollout cleared

## L112 probe

    bash tests/fs-rag-sibling-rollout-canonical-cli.sh | tail -1

Expected: `grep:pass=12 fail=0`.

## Pattern note — first mutation-tool extension (N=5 recipe-extension)

Recipe progression:
- 2xdi.90 (operator-fatigue-probe) — probe, 9 assertions
- 2xdi.92 (public-artifact-pipeline-probe) — probe, 10 assertions
- 2xdi.146 (codex-pane-path-probe) — probe, 10 assertions (N=3 promotion)
- 2xdi.147 (cross-repo-fmh-probe) — probe, 12 assertions (N=4 post-promotion)
- **2xdi.150 (fs-rag-sibling-rollout) — mutation tool, 12 assertions (N=5 EXTENSION)**

Stronger signal than mere count: recipe is now **template-extensible**,
not just template-stable. Future non-probe cold-script fixes inherit
a clearer path.

Filed `pattern-emerged-test-receiver-wire-in-recipe-N5-extends-to-mutation-tool-shape-not-just-probe-shape`.

## Cluster shape after N=5

- doctrine cross-link forward-link: N=11
- **test-receiver wire-in: N=5** ← outright 2nd-most-replicated
- probe corpus extensions: N=4
- (everything else N≤2)

25th distinct fix shape entry in 2xdi/kwjja/r9pri arc. The top 3 patterns
(doctrine cross-link + test-receiver wire-in + probe corpus extensions)
account for 20/25 (~80%) of all cluster work.
