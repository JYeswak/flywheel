# xAI Retired Model Drift Live Delta Route

**From:** flywheel:1 / Codex
**To:** skillos:1, zesttube owner lane, terratitle owner lane
**Real-word prefix:** ORBIT
**Mission anchor (sender):** `bb5b92c08ea5df4006b87b8233ee78adf0950baf`
**Companion plan:** `/tmp/goal-mode-worker-test-cycle-1023-act-xai-retired-model-drift-live-delta-route/receipt.json`
**Posture:** STATUS
**Block:** owner-lane edits required in `/Users/josh/Developer/zesttube` and `/Users/josh/Developer/terratitle`

## TL;DR

SkillOS refreshed `xai-retired-model-drift` and the live active count is now 17, not the earlier 18. The ClutterFreeSpaces hit is no longer active. Flywheel is routing only; it did not mutate ZestTube or TerraTitle because the receiver repos have no `.flywheel/handoffs` directory and both working trees are already dirty.

## Live Doctor Evidence

Command run from `/Users/josh/Developer/skillos`:

```bash
PATH="$PWD/bin:$PATH" bin/skillos doctor --scope xai-retired-model-drift --json
```

Observed summary:

```json
{
  "status": "DOWN",
  "active_match_count": 17,
  "counts_by_repo": {
    "terratitle": 1,
    "zesttube": 16
  },
  "counts_by_model": {
    "grok-4-1-fast-non-reasoning": 1,
    "grok-4-1-fast-reasoning": 4,
    "grok-imagine-image-pro": 12
  },
  "redirect_target": "grok-4.3",
  "image_redirect_target": "grok-imagine-image-quality",
  "tracking_bead": "skillos-85oy"
}
```

## Active Refs

```text
terratitle        Developer/terratitle/scripts/grok_grade_file.py:236                         grok-4-1-fast-non-reasoning
zesttube          Developer/zesttube/src/video/xai_image_gen.py:76                            grok-imagine-image-pro
zesttube          Developer/zesttube/src/video/script_gen.py:48                               grok-4-1-fast-reasoning
zesttube          Developer/zesttube/src/video/script_gen.py:51                               grok-4-1-fast-reasoning
zesttube          Developer/zesttube/src/video/generated_asset.py:101                         grok-imagine-image-pro
zesttube          Developer/zesttube/src/video/asset_provider_router.py:61                    grok-imagine-image-pro
zesttube          Developer/zesttube/src/video/storyboard_gen.py:44                           grok-4-1-fast-reasoning
zesttube          Developer/zesttube/src/video/storyboard_gen.py:47                           grok-4-1-fast-reasoning
zesttube          Developer/zesttube/scripts/gen_zf001_evidence.py:48                         grok-imagine-image-pro
zesttube          Developer/zesttube/scripts/gen_zf001_old_tv_evidence.py:50                  grok-imagine-image-pro
zesttube          Developer/zesttube/scripts/gen_zf001_hero_v2.py:41                          grok-imagine-image-pro
zesttube          Developer/zesttube/scripts/gen_zf001_hero_candidates.py:55                  grok-imagine-image-pro
zesttube          Developer/zesttube/scripts/gen_zf001_problem_setup.py:48                    grok-imagine-image-pro
zesttube          Developer/zesttube/scripts/yuzu-gen.py:33                                   grok-imagine-image-pro
zesttube          Developer/zesttube/scripts/yuzu-gen.py:88                                   grok-imagine-image-pro
zesttube          Developer/zesttube/scripts/gen_zf001_mechanism_reveal.py:48                 grok-imagine-image-pro
zesttube          Developer/zesttube/visual/scenes/s1-intro-hook.json:5                       grok-imagine-image-pro
```

## Receiver Action

For each owner lane:

1. Replace active retired text slugs with `grok-4.3`, or write per-path skip receipts.
2. Replace active retired image slugs with `grok-imagine-image-quality`, or write per-path skip receipts.
3. From `/Users/josh/Developer/skillos`, rerun:

```bash
bin/skillos doctor --scope xai-retired-model-drift --json
```

4. Callback to `skillos-85oy` with repo-local receipt paths and the post-check output.

## Routing Notes

- No active NTM panes were present for `zesttube` or `terratitle`.
- `/Users/josh/Developer/zesttube/.flywheel/handoffs` was absent.
- `/Users/josh/Developer/terratitle/.flywheel/handoffs` was absent.
- Flywheel therefore kept the durable route in `/Users/josh/Developer/flywheel/.flywheel/handoffs/` and did not create new handoff directories inside dirty owner repos.

## Provenance

- Incoming SkillOS receipt: `state/xai-retired-model-drift-live-delta-20260516T073238Z.json`
- Prior Flywheel route: `.flywheel/handoffs/20260515T235900Z-from-flywheel-to-skillos-xai-retired-model-drift-corrected-active-route.md`

— flywheel:1 / Codex

Mission anchor: `bb5b92c08ea5df4006b87b8233ee78adf0950baf`
