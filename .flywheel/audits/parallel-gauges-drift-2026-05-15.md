# Parallel-gauges drift audit — 2026-05-15

**Bead:** flywheel-meadows-doctor-freshness-gauge-reverse-lookup-cy5ay (AC4)
**Goal anchor:** P1 of `~/Desktop/zeststream-goals/flywheel/substrate-compounding-v2-20260515.txt`
**Authored by:** flywheel:1 (Claude Opus 4.7, 1M ctx)

## Why this audit exists

cy5ay AC3 documented the josh-request gauge's CONSUMED-vs-QUEUED drift. AC4
asks: does the same META-PATTERN exist in the other freshness gauges
flywheel-loop doctor surfaces? Apply the AC3 lens to four parallel gauges.

Per cy5ay AC4 contract: audit `mission_lock_status`, `daily_report_age_hours`,
`canonical_doctrine_propagation`, `fleet_repo_l_rule_lag_count`. Surface drift
classes. Recommend reconcile paths.

## Live state at audit time (2026-05-15)

```
mission_lock_status                stale-warn age_hours=202.49  lock_hash_matches_lock_log=true
daily_report                       pass        age_hours=0.11   latest=daily-2026-05-15.md
canonical_doctrine_propagation     TIMEOUT     probe_exit_code=124  probe_timeout_seconds=0.2  syncer_loaded=false
fleet_repo_l_rule_lag_count        75          fleet_repo_l_rule_lag=[] (empty array)
```

3 of 4 gauges show drift. `daily_report` is the working-gauge control case.

## Per-gauge analysis

### 1. `mission_lock_status`

**What it claims to measure:** Whether the MISSION.md lock is current
(referenced as "stale-warn" past some threshold).

**What it actually measures:** Age of `locked_at` timestamp in
`.flywheel/MISSION.md` frontmatter. 202h = ~8.4 days.

**Drift class: `freshness-as-staleness`.** Same class as josh-requests
`unread: 1745`. The gauge reports AGE, not INVALIDITY. The lock hash matches
the lock log (`lock_hash_matches_lock_log=true`) — the lock IS valid, just
old by-design (mission re-lock is paradigm-class, Joshua-gated, not
auto-refreshable).

**Recommended reconcile:**
- Path A — Tune the gauge: change "stale-warn" threshold from current
  (apparently 168h / 7 days) to an explicit configurable budget. Distinguish
  `stale-by-age` (warn but not block) from `invalid-by-hash` (fail). Today
  these are conflated.
- Path B — Add a `mission_lock_refresh_path` field that names the Joshua
  action needed to re-lock (verify mission content still current; bump
  `locked_at`; new hash). Surface as next-action, not error.

**Mission-anchor tie:** mission lock IS the paradigm-class substrate (per
the goal's 6-class blocker list). The gauge should distinguish age-warnings
from paradigm-class blockers. Today it doesn't.

### 2. `daily_report` (control case — WORKING)

**Status:** `pass` at age_hours=0.11. Fresh daily report at
`.flywheel/reports/daily-2026-05-15.md`. No drift.

**Why it works:** the gauge has a clear pass/warn/fail threshold ON FRESHNESS
ONLY. It doesn't conflate "stale" with "invalid." There's a generator
(possibly launchd or `/flywheel:daily-report`) that produces a fresh report
each day. Consumers can rely on the gauge being a faithful signal.

**Use this as the pattern.** When fixing the other 3 gauges, copy this
shape: one clear measurement, named threshold, named producer, clean pass/
warn/fail bands.

### 3. `canonical_doctrine_propagation`

**What it claims to measure:** Whether canonical doctrine
(`.flywheel/AGENTS-CANONICAL.md` + flywheel-install template AGENTS.md) is
in sync across the fleet.

**What it actually measures:** Nothing. The probe times out before completing.
`syncer_loaded=false`. `probe_exit_code=124` (TIMEOUT signal).
`probe_timeout_seconds=0.2` is aggressive — the syncer probably needs longer
to enumerate fleet repos and compute hashes.

**Drift class: `probe-substrate-broken`.** Distinct from the josh-requests
class. Here the gauge ISN'T STALE — it's NEVER COMPLETING. The probe
infrastructure fails before any signal is emitted.

**Recommended reconcile:**
- Path A — Extend timeout: bump `probe_timeout_seconds` from 0.2 to 5.0
  or higher. Trial: does the syncer complete in <5s? Profile, then set
  budget.
- Path B — Async probe with cached result: the syncer runs on a launchd
  cadence; doctor reads the cache. Doctor never blocks on the syncer load.
- Path C — Graceful degrade: if probe fails, surface as
  `canonical_doctrine_propagation_state=probe_broken` with the error +
  recovery hint; don't conflate with `drift_detected`.

### 4. `fleet_repo_l_rule_lag_count`

**What it claims to measure:** Number of fleet repos lagging the canonical
L-rule set in `~/.claude/skills/.flywheel/AGENTS-CANONICAL.md`.

**What it actually measures:** A COUNT (75) without the corresponding
DETAIL (`fleet_repo_l_rule_lag=[]` — empty array). Same shape as
`josh_requests.unread=1745` vs `requests=[20]`. The headline number doesn't
reconcile with the surfaced detail.

**Drift class: `count-vs-detail-divergence`.** Same class as the
josh-requests gauge. Operator (or downstream consumer) sees "75 fleet repos
lagging" with no path to know which 75. Can't act on it.

**Recommended reconcile:**
- Path A — Reconcile count and array: fix the probe to return both the
  count AND the per-repo detail. If 75 are lagging, the array should have
  75 entries with `{repo, lag_distance, head, canonical_head}`.
- Path B — Audit the source of `count=75` vs `array=[]`. The 75 may be a
  stale cached value from a prior probe; the empty array may be from a
  timed-out current probe (similar to canonical_doctrine_propagation).
  Distinguish cached-but-stale from probe-currently-broken.

## Cross-gauge synthesis

| Gauge | Drift class | Path forward |
|---|---|---|
| `josh_requests` (AC3) | `consumed-vs-queued-blindspot` + schema-drift | Schema reconcile (Path B from AC3 audit) |
| `mission_lock_status` | `freshness-as-staleness` | Threshold tune + paradigm-class signal split |
| `daily_report` | — (working) | Use as the template |
| `canonical_doctrine_propagation` | `probe-substrate-broken` | Timeout tune OR async cache |
| `fleet_repo_l_rule_lag_count` | `count-vs-detail-divergence` | Count + array reconcile |

3 of 4 broken gauges fall into different classes. The META-pattern: doctor
freshness gauges measure HEADLINE NUMBERS without backing DETAIL, and
treat AGE as equivalent to INVALIDITY. The reverse-lookup probe pattern
from AC3 helps for the `consumed-vs-queued` class; the other classes need
their own dedicated fixes.

## Recommendation

**File 4 follow-up beads, one per gauge.** Each is a small targeted fix:

1. **flywheel-mission-lock-threshold-tune** — separate `stale-by-age` warn
   from `invalid-by-hash` fail. Surface mission-lock as next-action when
   age >168h, not as drift. ≤30 LOC.
2. **flywheel-canonical-doctrine-propagation-timeout-fix** — bump probe
   timeout OR move to async cache + doctor-read-only. ≤50 LOC.
3. **flywheel-fleet-l-rule-lag-count-detail-reconcile** — fix the probe
   to return count + array consistently. ≤80 LOC (probe is in
   `.flywheel/scripts/architecture-health-rollup.sh` or sibling).
4. **flywheel-doctor-gauge-pattern-extraction** — extract the
   working `daily_report` pattern (named producer, named threshold, clean
   bands) as a doctrine doc. Make new gauges follow the pattern. ≤100 LOC.

These four beads collectively close AC4. The goal anticipated this:
*"AC4 stalls on 4 sub-beads (hard, expected)."*

## AC4 closure evidence

This audit is the AC4 deliverable. Substrate-delta is the tracked
`.flywheel/audits/parallel-gauges-drift-2026-05-15.md` commit. cy5ay AC4
status: **audit-complete, 4 follow-up beads recommended, pending Joshua
filing or auto-filing.**

The AC4 stall is the right shape per the goal contract — surfacing 4
discrete fixes is the finding, not a failure.
