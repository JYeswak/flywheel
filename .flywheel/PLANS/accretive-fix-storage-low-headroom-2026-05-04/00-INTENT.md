# Plan Intent — accretive-fix-storage-low-headroom

**Slug:** accretive-fix-storage-low-headroom-2026-05-04
**Started:** 2026-05-04T06:05:00Z
**Triggered by:** skillos-orch ESCALATE capsule (2-tick blocker contract)
**SLA:** flywheel-orch responds within 1 tick of capsule arrival per `feedback_two_blocker_ticks_escalate_to_flywheel_plan` META-RULE

## Verbatim escalation capsule

> Subject: ESCALATE blocker survived 2 ticks
> repo: /Users/josh/Developer/skillos
> session: skillos
> origin_pane: skillos:1
> owning_bead: skillos-e2n
> blocker_id: storage_low_headroom
> tick_counter: 2
> requested_owner: RubyCastle@flywheel
> requested_action: /flywheel:plan accretive-fix-storage-low-headroom-skillos
>
> Current proof:
> - flywheel-loop doctor returned status fail, action repair_storage_headroom
> - disk_free_pct=9.92, threshold_pct=10.0, tier CRITICAL
> - Bounded repo-local prune planned_count=0, actions_count=0 (nothing reclaimable in repo)
> - skillos-e2n already records repeated local-prune exhaustion + prior owner deferral
> - safe_local_work_remaining=false until RubyCastle returns plan or threshold strategy

## What's actually happening

skillos's doctor is correctly fail-closed on `disk_free_pct=9.92 < threshold_pct=10.0`. Local prune already tried and found nothing reclaimable inside the repo. **The bytes aren't in skillos.**

Host-level evidence (probed 2026-05-04T06:05Z from flywheel-orch):
```
/dev/disk3s5  926Gi  811Gi   92Gi  90%  /System/Volumes/Data
```

So the headroom problem is **host-wide**, not skillos-specific:
- 811 GiB used on the Data volume; only 92 GiB free
- Threshold is `disk_free_pct < 10.0` of the volume — currently 9.92%
- Repo-local prune was a structurally correct first attempt but mathematically can't fix a host-volume issue
- **Every fleet repo's doctor will hit this same gate** until host bytes are reclaimed, regardless of which repo's prune ran

## Reframing — substrate problem, not skillos problem

This is the second ESCALATE capsule today and the second case where the local orch did the right thing fail-closed but the path to clear the gate isn't local. Pattern:

| Capsule | Local fix tried | Local fix mathematically possible | Real fix lives at |
|---|---|---|---|
| mobile-eats `dispatch-health-gate-substrate` | doctor prelude, leakage prune | NO (leakage shared substrate) | substrate (bead-isolation, daily-report, FD growth) |
| skillos `storage_low_headroom` | repo-local prune (planned_count=0) | NO (host-volume bytes) | host (Apple Silicon storage triage) |

Sister orchs are locked out of the leverage point. flywheel-orch is the right place to handle host-tier work because:
1. flywheel owns the doctor threshold (sets it across fleet)
2. flywheel can dispatch the cross-repo prune wave (`dev-cache-janitor`, `apfs-snapshot-ops`, `orbstack-migration` skills exist)
3. flywheel can adjust the threshold transiently with override receipt while a real plan converges
4. flywheel can codify the "host-tier vs repo-tier blocker" classification so future capsules are pre-tagged

## Goal

Converged plan that:

### A. Unblock skillos THIS TICK (band-aid layer)
1. Probe top consumers of host storage (`du`, OrbStack, Docker, ~/Library caches, ~/.npm, ~/.cargo, /tmp)
2. Run cross-repo bounded prune via existing skills (`dev-cache-janitor`, `apfs-snapshot-ops`, `orbstack-migration`)
3. Goal: bring `disk_free_pct >= 12%` (5 percentage-point buffer above threshold)
4. Issue **temporary** doctor threshold override with explicit expiry receipt if reclaim < 12%
5. skillos-orch resumes; tick passes; bead `skillos-e2n` (owning bead) updates with reclaim receipt

### B. Substrate fix (accretive layer)
6. **Doctor threshold semantics**: separate "host-volume free" from "repo-volume free"; sister-orch shouldn't be the one alarming on host metrics it can't fix
7. **Storage-tier-aware blocker classification**: `host_tier_blocker` (escalate immediately, don't tick-wait) vs `repo_tier_blocker` (local fix path expected)
8. **Cross-fleet storage observatory**: weekly `du`-snapshot ledger so growth-rate trends surface BEFORE hitting threshold
9. **Auto-prune cadence**: nightly cross-repo prune wave (`dev-cache-janitor` etc.) wired to launchd so headroom maintains itself
10. **OrbStack/Docker recovery**: probe whether OrbStack disk image is a major consumer (common Apple-Silicon-Mac trauma class); adopt orbstack-migration skill if so

### C. Trauma class lift (Meadows layer)
11. **Capsule schema v0 → v1**: this is the second capsule; codify `tier=host|repo|fleet`, `mathematically_local=true|false`, `pre_classification=immediate_escalate|tick_wait`. Both today's capsules would have `mathematically_local=false`.
12. **Threshold delay parameter** (#9 in Meadows hierarchy): doctor's 10% threshold is a magic number. What's the actual safe number? Apple's APFS reserve is non-trivial; mac dev tooling needs ~50GiB headroom for builds. Plan probes the right number.
13. **Information flow #6**: storage-growth-rate signal in fleet-conductor Layer 6 (continuous landscape ingestion); fleet conductor should know this is happening before sister orchs do.

## Acceptance for shipped fix

- skillos doctor `repair_storage_headroom` clears within 2 flywheel ticks (either reclaim succeeds OR explicit override receipt issued)
- Cross-fleet storage observatory ledger live (weekly `du` snapshots)
- Auto-prune cadence wired (launchd plist; uses existing skills)
- Doctor threshold `host_tier` vs `repo_tier` classification shipped
- Capsule schema v1 with tier + mathematically_local fields codified in skill library
- skillos-e2n owning bead receives reclaim receipt and progresses

## Three-judges lens for this plan

- **Jeff:** doctor/health/repair triad — current gate has doctor + halt; missing repair pathway when fix isn't local. Plan adds repair (cross-repo prune wave) and graceful override receipt.
- **Donella:** stocks (host_disk_free_bytes, fleet_disk_growth_rate_per_day, prunes_executed, override_receipts_issued); flows (build artifacts created, caches written, snapshots taken, prunes executed); leverage point #9 DELAY (doctor threshold value), #6 INFORMATION FLOWS (growth-rate signal), #5 RULES (host-tier vs repo-tier classification).
- **Josh:** does this give time back? YES — auto-prune cadence + storage observatory means future skillos ticks self-heal instead of escalating; saves human and orch capacity per week. Receipts in ZestStream voice.

## Constraints

- READ-ONLY through Phase 3
- Phase 4 mutates beads DB only
- Code edits via separate /flywheel:dispatch
- Compose-not-replace: layer on existing `dev-cache-janitor`, `apfs-snapshot-ops`, `orbstack-migration`, `storage-health` skills

## Pre-flight (probed 2026-05-04T06:05Z)

- Host: `/dev/disk3s5  926Gi  811Gi  92Gi  90%  /System/Volumes/Data`
- skillos disk_free_pct=9.92 (host-wide, not repo-specific)
- Compaction context tight; sequential lane dispatch acceptable
- Compose siblings: `dev-cache-janitor`, `apfs-snapshot-ops`, `orbstack-migration`, `storage-health`, `disk-observer`, `container-orphan-detector`, `docker-storage-ops`, `docker-volume-ops`, `storage-ballast-helper`
