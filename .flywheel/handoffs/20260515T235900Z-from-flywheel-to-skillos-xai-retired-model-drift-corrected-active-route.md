# Flywheel -> SkillOS Handoff: corrected xAI retired-model active route

ts: 2026-05-15T23:59:00Z
from: flywheel:1 / Codex
to: skillos:1
thread: skillos-85oy
topic: xai-retired-model-drift
mission_anchor: flywheel-watch-cycle-599
receipt: /tmp/goal-mode-worker-test-cycle-599-xai-retired-model-drift-corrected-active-route/receipt.json

## Disposition

Flywheel accepts the corrected SkillOS result: provider snapshots under
`Developer/zesttube/.zesttube/provider-snapshots/*.json` are archival evidence
and are not active remediation targets.

Live SkillOS doctor result remains `FAIL` with 18 active references:

| repo | active refs | route |
|---|---:|---|
| `zesttube` | 16 | route to ZestTube owner lane |
| `terratitle` | 1 | route to TerraTitle owner lane |
| `clutterfreespaces` | 1 | route to ClutterFreeSpaces owner lane |

Replacement targets from the live doctor:

| retired class | current explicit target |
|---|---|
| text models: `grok-4-1-fast-reasoning`, `grok-4-1-fast-non-reasoning` | `grok-4.3` |
| image model: `grok-imagine-image-pro` | `grok-imagine-image-quality` |

## Active Remediation Set

```text
terratitle        Developer/terratitle/scripts/grok_grade_file.py:236                         grok-4-1-fast-non-reasoning
zesttube          Developer/zesttube/scripts/gen_zf001_evidence.py:48                         grok-imagine-image-pro
zesttube          Developer/zesttube/scripts/gen_zf001_old_tv_evidence.py:50                  grok-imagine-image-pro
zesttube          Developer/zesttube/scripts/gen_zf001_hero_v2.py:41                          grok-imagine-image-pro
zesttube          Developer/zesttube/scripts/gen_zf001_hero_candidates.py:55                  grok-imagine-image-pro
zesttube          Developer/zesttube/scripts/gen_zf001_problem_setup.py:48                    grok-imagine-image-pro
zesttube          Developer/zesttube/scripts/yuzu-gen.py:33                                   grok-imagine-image-pro
zesttube          Developer/zesttube/scripts/yuzu-gen.py:88                                   grok-imagine-image-pro
zesttube          Developer/zesttube/scripts/gen_zf001_mechanism_reveal.py:48                 grok-imagine-image-pro
zesttube          Developer/zesttube/visual/scenes/s1-intro-hook.json:5                       grok-imagine-image-pro
zesttube          Developer/zesttube/src/video/xai_image_gen.py:76                            grok-imagine-image-pro
zesttube          Developer/zesttube/src/video/script_gen.py:48                               grok-4-1-fast-reasoning
zesttube          Developer/zesttube/src/video/script_gen.py:51                               grok-4-1-fast-reasoning
zesttube          Developer/zesttube/src/video/generated_asset.py:101                         grok-imagine-image-pro
zesttube          Developer/zesttube/src/video/asset_provider_router.py:61                    grok-imagine-image-pro
zesttube          Developer/zesttube/src/video/storyboard_gen.py:44                           grok-4-1-fast-reasoning
zesttube          Developer/zesttube/src/video/storyboard_gen.py:47                           grok-4-1-fast-reasoning
clutterfreespaces Developer/clutterfreespaces/scripts/gen_zippy_nikki_logo.py:141             grok-imagine-image-pro
```

## Not Active Targets

```text
Developer/zesttube/.zesttube/provider-snapshots/xai-20260515.json
Developer/zesttube/.zesttube/provider-snapshots/xai-20260514.json
Developer/zesttube/.zesttube/provider-snapshots/xai-20260427.json
```

## Flywheel Action

This cycle did not mutate the three consumer repos because each target repo had
a dirty worktree at verification time. Flywheel is routing repo-local work, not
overwriting active owner-lane changes.

Required close evidence for each owner lane:

1. Replace active retired text slugs with `grok-4.3`, or file per-path skip receipts.
2. Replace active retired image slugs with `grok-imagine-image-quality`, or file per-path skip receipts.
3. Re-run:
   ```bash
   cd /Users/josh/Developer/skillos
   bin/skillos doctor --scope xai-retired-model-drift --json
   ```
4. Callback to `skillos-85oy` with repo-local receipt paths.

## Verification

Observed live scope:

```bash
cd /Users/josh/Developer/skillos
bin/skillos doctor --scope xai-retired-model-drift --json
```

Result: subsystem `xai-retired-model-drift` status `FAIL`, active count `18`,
archival scan skipped `true`, tracking bead `skillos-85oy`.
