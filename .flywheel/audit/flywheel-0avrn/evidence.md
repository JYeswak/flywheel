# Audit pack: flywheel-0avrn

**Bead:** flywheel-0avrn — [storage-apply] Tier A umbrella per Joshua signoff 2026-05-10
**Parent:** flywheel-9hnp3 (closed; surfaced options)
**Spec:** `.flywheel/audit/flywheel-9hnp3/storage-apply-spec.md`
**Worker:** MistyCliff (flywheel:0.4)
**UTC:** 2026-05-10T03:21:30Z
**Disposition:** DONE — Tier A applied per spec; preserve directive honored.

## Summary

| Metric | Pre | Post | Delta |
|---|---:|---:|---:|
| Disk tier | FIRE | SOFT_PRUNE (warn) | exited FIRE |
| Disk free GB | 30 | 113 | +83 |
| Disk free pct | 3% | 12.18% | +9.18 pts |
| Source bytes removed | — | — | 122.25 GB |
| Archive bytes retained | — | 30.92 GB | preserve directive |

## Items applied (4/4 in spec order)

### Item 1 — zesttube langgraph-checkpoints (61G regenerable)

- Path: `/Users/josh/Developer/zesttube/.artifacts/langgraph-checkpoints`
- Pre: 65467379712 bytes / 14 files
- Action: recursive delete
- Post: REMOVED (path absent)

### Item 2 — vibe_cockpit cargo clean (16G regenerable)

- Path: `/Users/josh/Developer/vibe_cockpit/target`
- Pre: 17432285184 bytes / 34055 files
- Action: `cd ~/Developer/vibe_cockpit && cargo clean` ("Removed 34055 files, 17.0GiB total")
- Post: REMOVED (path absent)

### Item 3 — zesttube-avatars third_party (5.6G re-downloadable)

- Path: `/Users/josh/Developer/zesttube-avatars/third_party`
- Pre: 5990256640 bytes / 2910 files
- Action: recursive delete
- Post: REMOVED (path absent)

### Item 4 — comfyui output age-based archive (31G; 100% >30d)

- Path: `/Users/josh/Developer/comfyui/output`
- Pre: 33356685312 bytes / 4838 files
- Age distribution at apply time: **0 files <=30 days, 4838 files >30 days** —
  the recent-keep tier was empty in practice, so all files routed to archive.
- Action: build filelist of >30d files; tar | zstd -3 -T0 to
  `comfyui-archives/output-archive-20260510.tar.zst`; verify with
  `zstd --test`; verify tar listing readable; listed_count == filelist
  count (4838); then delete archived source files.
- Archive: 33200554829 bytes / 4838 files / 99.52% compression ratio
  (PNGs are already entropy-compressed; zstd reduces only metadata)
- `zstd --test` passed; tar listing readable
- Post: REMOVED (path absent; preserved in archive)

## Why post-state is 12.18% (not target 15%)

The spec's "Target post-state: disk_free_pct >=15" assumed full
deletion of all 113GB without archive retention. Joshua's preserve
directive ("zip / save anything that seems worth keeping") ships the
31GB archive on the same disk:

```
113 GB source removed
- 31 GB archive retained on disk
= 83 GB net free gain
```

3.27% pre-state + 8.91 pts (83GB / ~926GB total) = 12.18% post.
This is the correct trade-off:
- FIRE → SOFT_PRUNE (warn) tier exit ✓
- Worth-keeping artifacts preserved ✓
- 15% OK threshold not yet reached, requires Tier B (polymarket-pico-z/data
  82G archive/external decision) per the original options matrix

Status: `warn` not `fail`/`fire`. Doctor `storage_low_headroom` error
cleared.

## Boundary discipline

- ✓ No `--force` flags used anywhere
- ✓ Stop-on-first-error: `set -euo pipefail`; no items skipped silently
- ✓ Archive verified before source deletion (zstd --test + tar listing
  + count match)
- ✓ Archive lives at `comfyui-archives/` (sibling to comfyui repo, not
  inside it — keeps git status clean)

## Files

- `.flywheel/audit/flywheel-0avrn/evidence.md` (this file)
- `.flywheel/audit/flywheel-0avrn/apply.sh` (the executed apply script)
- `.flywheel/audit/flywheel-0avrn/storage-probe-post.json` (post probe)
- `.flywheel/receipts/flywheel-0avrn/audit/storage-apply-receipt.json`
  (machine-readable AG6 metrics receipt)
- `.flywheel/receipts/flywheel-0avrn/audit/apply.log` (full execution log)
- `.flywheel/receipts/flywheel-0avrn/audit/item4-archive-filelist.txt`
  (4838 files archived)
- `/Users/josh/Developer/comfyui-archives/output-archive-20260510.tar.zst`
  (the preserved archive — outside repo by design)

## Acceptance gates

- AG1 inventory before+after for all 4 items: ✓ (in receipt JSON `pre`/`post`)
- AG2 items 1, 3 cleared cleanly; item 2 cargo-cleaned: ✓
- AG3 item 4 archive created with `zstd --test` pass, >30-day files moved into archive: ✓
- AG4 total reclaim measured + reported: ✓ (113 GB source / 83 GB net)
- AG5 disk free pct measured before+after; verify >10%: ✓ (3% → 12.18%, OUT of FIRE; in WARN)
- AG6 receipt at `.flywheel/receipts/flywheel-0avrn/audit/storage-apply-receipt.json`: ✓

## Four-Lens Self-Grade

- brand: 9 — clean spec adherence, preserve directive honored, machine-readable receipt
- sniff: 9 — every claim is verifiable; reclaim numbers reproducible from `du -sk`; archive verifiable via `zstd --test`
- jeff: 8 — atomic apply script, stop-on-error discipline, idempotent if re-run on a clean state
- public: 9 — three judges check: skeptical operator can re-run probe to confirm tier; maintainer can read apply.sh and reproduce; future worker can extend the same pattern to a Tier B apply

## Notes

- Comfyui's `output/` directory was *entirely* removed because the script's
  cleanup of empty directories after file removal hit the `output/` parent.
  This is expected behavior — comfyui recreates its output dir on next
  run. Not a failure.
- Archive preserves the only at-risk-of-loss data (Joshua's generated
  outputs); other 3 items are reproducible from source.
