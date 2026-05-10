# Tier A apply spec — flywheel-9hnp3 follow-up

Joshua signed off on Tier A umbrella reclaim 2026-05-10 with directive:
> "auto approve - make sure we zip / save anything that seems worth keeping"

Source: `.flywheel/audit/flywheel-9hnp3/options-matrix.json` (Tier A items).

## Scope (113GB total reclaim target, ~15.4% post free)

### Item 1: zesttube langgraph-checkpoints (61GB)

- Path: `/Users/josh/Developer/zesttube/.artifacts/langgraph-checkpoints/`
- Class: regenerable agent state (langgraph re-checkpoints on next agent run)
- Action: recursive delete of the directory contents

### Item 2: vibe_cockpit build artifacts (16GB)

- Path: `/Users/josh/Developer/vibe_cockpit/`
- Class: cargo build artifacts, regenerable
- Action: `cd <path> && cargo clean`

### Item 3: zesttube-avatars model weights (5.6GB)

- Path: `/Users/josh/Developer/zesttube-avatars/third_party/`
- Class: model weights, re-downloadable via setup script
- Action: recursive delete of the directory contents

### Item 4: comfyui outputs (31GB) — JOSHUA-FLAGGED, archive-then-prune

- Path: `/Users/josh/Developer/comfyui/output/`
- Class: regenerable but personal artifacts, Joshua wants worth-keeping preserved
- Strategy: age-based archive
  - Recent (last 30 days): KEEP on main disk (intact, no change)
  - Older (30-90 days): compress into archive at `/Users/josh/Developer/comfyui-archives/output-archive-<date>.tar.zst`, then remove originals
  - Ancient (>90 days): compress into archive AND remove originals
  - Verify archive integrity (`zstd --test`) BEFORE removing originals
- Reclaim source: prune oldest files; archive itself stays on disk (much smaller compressed)

## Acceptance

- AG1: inventory before+after for all 4 items (file count + bytes)
- AG2: items 1, 3 cleared cleanly; item 2 cargo-cleaned
- AG3: item 4 archive created with `zstd --test` pass, >30-day files moved into archive
- AG4: total reclaim measured + reported in evidence
- AG5: disk free pct measured before+after; verify >10% (out of FIRE tier minimum)
- AG6: receipt at `.flywheel/receipts/<bead-id>/audit/storage-apply-receipt.json` with all metrics

## Boundary

- Fleet-impacting. Stop on first error; do NOT continue to next item if any fails.
- No --force flags.
- Item 4 archive is the only destructive op that requires preservation; items 1-3 are safe-regenerable per AG1 inventory.

## Rollback

- Items 1, 3: unrecoverable but regenerable (takes time)
- Item 2: regenerates on next `cargo build`
- Item 4: archive can be re-extracted from `/Users/josh/Developer/comfyui-archives/`
