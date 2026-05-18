# xAI Retired Model Drift Target Map Refresh

**From:** flywheel:1 / Codex
**To:** terratitle owner lane, zesttube owner lane, skillos:1
**Real-word prefix:** ORBIT
**Mission anchor (sender):** `bb5b92c08ea5df4006b87b8233ee78adf0950baf`
**Tracking bead:** `skillos-85oy`
**Companion receipt:** `/tmp/goal-mode-worker-test-cycle-1104-act-xai-retired-model-drift-target-map-refresh/receipt.json`
**Posture:** STATUS
**Block:** owner-lane edits or per-path skip receipts required in `/Users/josh/Developer/terratitle` and `/Users/josh/Developer/zesttube`

## TL;DR

SkillOS refreshed `xai-retired-model-drift` with model-specific replacement targets. The live scope still fails with 17 active refs, but the TerraTitle non-reasoning text target is now `grok-4.20-non-reasoning`; ZestTube reasoning refs target `grok-4.3`; ZestTube image refs target `grok-imagine-image-quality`.

## Live SkillOS Doctor Evidence

Command run from `/Users/josh/Developer/skillos`:

```bash
bin/skillos doctor --scope xai-retired-model-drift --json
```

Observed at `2026-05-16T11:46:43Z`:

```json
{
  "status": "FAIL",
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
  "non_reasoning_redirect_target": "grok-4.20-non-reasoning",
  "image_redirect_target": "grok-imagine-image-quality"
}
```

## Replacement Map

Use this SkillOS doctor map for owner-lane patches or per-path skip receipts:

```json
{
  "grok-3": "grok-4.3",
  "grok-4-0709": "grok-4.3",
  "grok-4-1-fast-non-reasoning": "grok-4.20-non-reasoning",
  "grok-4-1-fast-reasoning": "grok-4.3",
  "grok-4-fast-non-reasoning": "grok-4.20-non-reasoning",
  "grok-4-fast-reasoning": "grok-4.3",
  "grok-code-fast-1": "grok-4.3",
  "grok-imagine-image-pro": "grok-imagine-image-quality"
}
```

## Source Caveat

Flywheel checked the public xAI pages named by SkillOS:

- `https://docs.x.ai/developers/migration/may-15-retirement`
- `https://docs.x.ai/developers/models/grok-4.3`
- `https://docs.x.ai/developers/model-capabilities/images/generation`

The public retirement page lists the retired slugs and says non-reasoning retired text slugs redirect to `grok-4.3` with `none` reasoning effort, while the repaired SkillOS doctor now emits `grok-4.20-non-reasoning` as the explicit non-reasoning replacement target. Owner lanes should either follow the live SkillOS target map or write a per-path skip receipt if repo-local provider probes reject that target.

## Remaining Active Refs

TerraTitle:

```text
Developer/terratitle/scripts/grok_grade_file.py:236  grok-4-1-fast-non-reasoning -> grok-4.20-non-reasoning
```

ZestTube:

```text
Developer/zesttube/visual/scenes/s1-intro-hook.json:5                 grok-imagine-image-pro -> grok-imagine-image-quality
Developer/zesttube/src/video/xai_image_gen.py:76                      grok-imagine-image-pro -> grok-imagine-image-quality
Developer/zesttube/src/video/storyboard_gen.py:44                     grok-4-1-fast-reasoning -> grok-4.3
Developer/zesttube/src/video/storyboard_gen.py:47                     grok-4-1-fast-reasoning -> grok-4.3
Developer/zesttube/src/video/script_gen.py:48                         grok-4-1-fast-reasoning -> grok-4.3
Developer/zesttube/src/video/script_gen.py:51                         grok-4-1-fast-reasoning -> grok-4.3
Developer/zesttube/src/video/generated_asset.py:101                   grok-imagine-image-pro -> grok-imagine-image-quality
Developer/zesttube/src/video/asset_provider_router.py:61              grok-imagine-image-pro -> grok-imagine-image-quality
Developer/zesttube/scripts/gen_zf001_evidence.py:48                   grok-imagine-image-pro -> grok-imagine-image-quality
Developer/zesttube/scripts/gen_zf001_old_tv_evidence.py:50            grok-imagine-image-pro -> grok-imagine-image-quality
Developer/zesttube/scripts/gen_zf001_mechanism_reveal.py:48           grok-imagine-image-pro -> grok-imagine-image-quality
Developer/zesttube/scripts/gen_zf001_hero_v2.py:41                    grok-imagine-image-pro -> grok-imagine-image-quality
Developer/zesttube/scripts/gen_zf001_hero_candidates.py:55            grok-imagine-image-pro -> grok-imagine-image-quality
Developer/zesttube/scripts/gen_zf001_problem_setup.py:48              grok-imagine-image-pro -> grok-imagine-image-quality
Developer/zesttube/scripts/yuzu-gen.py:33                             grok-imagine-image-pro -> grok-imagine-image-quality
Developer/zesttube/scripts/yuzu-gen.py:88                             grok-imagine-image-pro -> grok-imagine-image-quality
```

## Receiver Action

For each owner lane:

1. Replace the active retired refs above, or write per-path skip receipts with repo-local rationale.
2. From `/Users/josh/Developer/skillos`, rerun:

```bash
bin/skillos doctor --scope xai-retired-model-drift --json
```

3. Callback to `skillos-85oy` with changed files, repo-local receipt paths, and whether the live scope is `OK` or still `FAIL`.

## Provenance

- Incoming SkillOS receipt: `state/xai-retired-model-drift-target-mapping-repair-20260516T1144Z.json`
- Prior stale-ish Flywheel route: `.flywheel/handoffs/20260516T1008Z-from-flywheel-to-skillos-xai-retired-model-drift-live-delta-route.md`
- Live SkillOS doctor timestamp: `2026-05-16T11:46:43Z`

— flywheel:1 / Codex

Mission anchor: `bb5b92c08ea5df4006b87b8233ee78adf0950baf`
