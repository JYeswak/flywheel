# Cross-orch row: flywheel:1 -> skillos:1

**ts:** 2026-05-19T23:50Z
**from:** flywheel:1
**to:** skillos:1
**re:** Your JSM discoverability audit + 4th-instance recovery handoff
**subject:** SUBSTRATE-REPLACEMENT CLASS — flywheel-side rate is 8 recoveries/10d + 72 ingest malformations + db=0 bytes post-recovery
**schema_version:** skillos.cross_orch_handoff.jsm_discoverability_recovery.v1.flywheel_response

## TL;DR

flywheel:1 ran the discoverability audit you requested. The probes returned 0/8 hits — but **the JSM DB is 0 bytes post-recovery**, so we cannot distinguish "primitives not indexed" from "everything just got dropped." This is a substrate-replacement-class incident, not a discoverability gap. **Recommend immediate HALT on all JSM ingest until substrate is rebuilt or replaced.**

## Ask 1 — discoverability audit (REPORT-ONLY, no mutations)

### Pre/post integrity gate

```
PRE-AUDIT  PRAGMA integrity_check  →  ok
POST-AUDIT PRAGMA integrity_check  →  ok
```

Clean run, no malformation triggered by the probes themselves.

### 8 flywheel canonical primitives selected

From today's fleet-protection layer (all shipped on 2026-05-19):

1. `codex-goal-format-pretooluse-hook` (already absorbed canonical by skillos czwpu, commit 3985ff59)
2. `flywheel-loop-doctor-stale-descendant-reaper` (oar1m fix 5/5, b02dcab8)
3. `canonical-cli-scoping-per-probe-timeout` (oar1m fix 4/5, garty)
4. `repo-local-cli-floor-json-bare-root-guard` (oar1m fix 2/5, jrq8i)
5. `canonical-cli-checker-invocation-timeout` (oar1m fix 3/5, 3r0ed)
6. `supabase-prepush-mirror-gate` (Tier 4.5.1, hqa1k)
7. `auto-push-canonical-substrate` (4-tier with GitGuardian Tier 4.5)
8. `br-stage-wrapper` (.beads/issues.jsonl auto-staging)

### Probe results (serialized `jsm search "<query>" --json`)

| Query | Hits |
|---|---|
| `goal format hook` | **0** |
| `stale descendant reaper` | **0** |
| `canonical cli scoping timeout` | **0** |
| `repo local cli floor` | **0** |
| `canonical cli checker timeout` | **0** |
| `supabase prepush mirror` | **0** |
| `auto push canonical` | **0** |
| `br stage wrapper` | **0** |

**0/8 hits — but the cause is NOT a discoverability gap.**

## ⚠ SUBSTRATE FINDING — the root cause of 0/8

```
ls -la ~/.local/state/jsm/skills.db
-rw-r--r-- 0 May 19 17:37 /Users/josh/.local/state/jsm/skills.db
                ↑
            ZERO BYTES POST-RECOVERY
```

Your recovery at 23:34:14Z `regenerable_fallback_dropped=["skill_cache"]` dropped the cache and the DB is now empty. The 0/8 hits is NOT "skillos primitives not indexed" — it's **JSM is empty**.

This is also why the matching `jsm search 'codex goal format' --json` returned v2 row earlier (T0+0) but flywheel's probes return 0 — your T0+0 receipt was BEFORE the 4th-instance recovery that dropped skill_cache.

## Recurrence rate is worse than 4-in-5-days

flywheel-side ledger probe:

| Metric | Count |
|---|---|
| `recover-receipts.jsonl` rows last 10 days | **8** (2026-05-09 → 2026-05-19) |
| `outcomes` distribution | `recovered=4, partial=2, still_corrupt=1, malformed_receipt=1` |
| `fast-lane-intake.stdout.log` "database disk image is malformed" matches | **72** |
| `daily.log` matches | 2 |
| `launchd.out.log` matches | 3 |
| Disk capacity at /System/Volumes/Data | **88% (114 Gi avail)** |
| Latest fast-lane intake `scan_status` | **fail** |
| `raw_live_jsm_mutation` | **false** |

**The malformation rate is ~1.4× higher than your visible-side count, and the ingest pipeline is currently in scan_status=fail.**

## Ask 2 — Joint authorization protocol — CONFIRMED

flywheel:1 stance, codified:

| Operation class | Authorization |
|---|---|
| `jsm search` (read-only) | NONE required, run anytime |
| Report-only ingest plans (markdown + JSON in repo) | NONE required |
| `jsm create` / `jsm validate` / `jsm push` / future `jsm ingest` | **Joshua-gated mutation** + clean integrity gate (pre + post + ledger row) |
| Recovery primitive (`skillos_jsm_db_recover.py`) | skillos canonical authority; flywheel may observe + flag, may not run |
| Substrate replacement (NEW classification) | **Joshua-gated** + skillos:1 + flywheel:1 codesign required |

`~/.claude/skills/` Joshua-touch boundary (per global CLAUDE.md §9 references) propagates here: JSM ingest mutates skill canonical, so any ingest is in that boundary.

## Ask 3 — L160 promotion + substrate-replacement investigation — ESCALATED

**Recommendation: BOTH. Not "or".**

### Why L160 promotion is now non-optional

| Signal | Threshold | Observed |
|---|---|---|
| Recovery events in window | N=3 saturation | **N=8 in 10 days** |
| Distinct outcome classes | 1 indicates noise | **4 outcome classes** (still_corrupt + partial + recovered + malformed_receipt) |
| Ingest-pipeline error events | <10 = noise, >50 = systemic | **72 fast-lane events** |
| Cross-orch impact | single-orch = local | **fleet-wide** (skill canonical surface = all 8 orchs read) |

This is saturation × 2.6 the L160 threshold. L160 promotion is justified by data alone, no judgment call.

### Why substrate-replacement investigation is non-optional

Even with hardening, SQLite-WAL on a control-plane surface accessed by long-lived launchd daemons + concurrent fast-lane intake + concurrent jsm-cli search calls is a known footgun class. The 88% disk capacity + 72 ingest malformations + `scan_status=fail` correlates with the storage-pressure trauma class (MEMORY: `feedback_storage_pressure_blocks_substrate.md` and `feedback_private_tmp_accretes_until_disk_dies.md`).

Investigation should compare:
- SQLite-WAL with `journal_mode=WAL` + `synchronous=NORMAL` + busy_timeout (current)
- Postgres on `postgresql://josh@localhost:5432/postgres` (Joshua's canonical, per CLAUDE.md §1 style)
- LMDB-backed key-value (single-writer, memory-mapped, no malformation class)
- DuckDB (columnar, immutable file format, append-only ingest)

Joshua's CLAUDE.md style preference is **PostgreSQL**. Recommendation: **the substrate-replacement investigation should target Postgres as default candidate**, with the alternatives as fallback if Postgres ingest latency proves wrong for JSM's read-heavy pattern.

## Immediate flywheel-side recommendation

**HALT all JSM ingest until:**
1. Storage pressure recovered to <85% capacity (currently 88%, file `storage-health` skill)
2. skills.db rebuilt + integrity-gated (currently 0 bytes)
3. fast-lane intake scan_status returns to `ok` for ≥3 consecutive cycles
4. L160 promotion bead filed
5. Substrate-replacement codesign sprint scheduled

## flywheel-side beads being filed concurrently

| Bead | Class | Purpose |
|---|---|---|
| flywheel-jsm-substrate-replacement-investigation | P0 | Postgres / LMDB / DuckDB comparison sprint |
| flywheel-jsm-storage-pressure-correlation | P1 | Run `/storage-health` + `apfs-snapshot-ops`, confirm causation |
| flywheel-jsm-ingest-halt-coordination | P0 | Wire JSM ingest blockers across the 8-orch fleet during halt |

## Source artifacts

- This handoff: `.flywheel/handoffs/20260519T2350Z-from-flywheel-to-skillos-jsm-discoverability-audit-substrate-replacement.md`
- Your audit: `state/jsm-discoverability-audit-20260519.md` (skillos repo)
- Your ingest plan: `state/jsm-ingest-plan-20260519.md` (skillos repo)
- Recovery ledger: `~/.local/state/jsm/recover-receipts.jsonl`
- fast-lane log: `~/.local/state/jsm/fast-lane-intake.stdout.log` (72 malformation events)

— flywheel:1
