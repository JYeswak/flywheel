## L108 — META-RULE-CACHE-IS-CACHE-NOT-CONVERGENCE-GATE

---
id: L108
title: META-RULE cache is cache, not convergence gate
status: long_term
shipped: 2026-05-04
review_due: 2026-11-04
trauma_class: cache-freshness-mistaken-for-convergence
---

`META-RULE-CACHE.md` proves cache freshness, not 3-surface convergence.
`sync.sh --check-three-surface` is the convergence gate;
`sync.sh --apply-three-surface` backfills missing canonical L-rules. Tick
checks and logs drift, onboard auto-applies, and the hourly launchd watchdog
logs fleet drift to
`~/.local/state/flywheel/canonical-meta-rules-watchdog.jsonl`. Never conflate
cache mtime with doctrine alignment.

**How to apply:**
- Use `/Users/josh/.flywheel/canonical-meta-rules/sync.sh --check-three-surface --target <repo> --json`
  before reporting doctrine convergence.
- Use `--apply-three-surface` only in onboarding or an explicit repair bead;
  tick and watchdog paths are read-only drift detectors.
- Doctor consumers use `fleet_three_surface_drift_per_session`,
  `fleet_three_surface_drift_total_count`,
  `fleet_three_surface_drift_max_count`, and
  `fleet_three_surface_drift_worst_session`.

**Forbidden outputs:**
- Reporting a repo doctrine surface clean because `META-RULE-CACHE.md` is fresh.
- Auto-applying 3-surface doctrine drift from a normal tick.
- Closing a three-surface drift bead without a machine-readable
  `--check-three-surface` receipt.

**Evidence:** sync gate `/Users/josh/.flywheel/canonical-meta-rules/sync.sh`;
tick wiring `.flywheel/flywheel-loop-tick`; onboard repair
`.flywheel/scripts/flywheel-onboard.sh`; watchdog
`~/Library/LaunchAgents/ai.zeststream.canonical-meta-rules-sync-watchdog.plist`;
doctor fields in `~/.claude/skills/.flywheel/bin/flywheel-loop`.

**Cross-references:** L50 (Socraticode preflight), L51 (file reservations),
L61 (ecosystem wire-in), L96 (3-surface diff), L102 (META-RULE cache refresh),
L105 (process gaps measured), L107 (shared-surface reservations), and
`.flywheel/scripts/doctrine-3-surface-divergence-probe.sh` (repo_role scoping:
template surface is active only for `flywheel_origin` repos).

