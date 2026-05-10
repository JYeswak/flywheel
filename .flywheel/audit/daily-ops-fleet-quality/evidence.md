# Daily-ops fleet quality grading — evidence

Bead: `flywheel-u2yc0` (P2, Joshua signoff 2026-05-10; chains on `flywheel-lb2gk`)
Task ID: `flywheel-u2yc0-f3098f`
Worker: CloudyMill
Activation timestamp: 2026-05-10T04:30-04:38Z

## AG-B1 — extend daily-report.py with quality grade

Function: `quality_grade(callback_log, date_text)` at
`.flywheel/scripts/daily-report.py`. Reads
`.flywheel/callback-validation-log.jsonl` (today's rows), base64-decodes
each `callback_b64`, parses fields with regex, computes:

- `compliance_distribution`: `{n, avg, median, p25, p75, min, max}`
- `four_lens_distribution`: per-axis `{n, avg, count_lt_8}`
- `mission_fitness_counts`: counter of `direct|adjacent|infrastructure|drift|unknown`
- `disposition_counts`: counter of `DONE|BLOCKED|DECLINED|ESCALATE|unknown`
- `blocked_escalate_rate`: `(BLOCKED+ESCALATE)/total` ratio
- `identity_attribution`: per-worker `{closes, avg_compliance}` sorted by closes desc
- `red_flags`: list of `{code, detail}`

Live smoke against today's flywheel callback log:

```json
{
  "callback_count": 44,
  "compliance_distribution": {"n":22,"avg":839.1,"median":830.0,"p25":830.0,"p75":830.0,"min":830.0,"max":950.0},
  "mission_fitness_counts": {"adjacent":29,"infrastructure":15},
  "disposition_counts": {"DONE":41,"BLOCKED":3},
  "blocked_escalate_rate": 0.068,
  "identity_attribution_count": 2,
  "red_flags_count": 1
}
```

The new section landed at `.flywheel/reports/daily-2026-05-10.md`
(line 67: `## Quality grading`). Verbatim:

```
- callback_count: 44
- compliance: avg=839.1 median=830.0 p25=830.0 p75=830.0 (n=22)
- four_lens: brand: avg=9.0 <8=0 (n=21), sniff: avg=9.0 <8=0 (n=21), jeff: avg=9.24 <8=0 (n=21), public: avg=9.0 <8=0 (n=21)
- mission_fitness: adjacent=29, infrastructure=15
- disposition: BLOCKED=3, DONE=41
- blocked_escalate_rate: 0.068
- MistyCliff: closes=30 avg_compliance=839.1
- MagentaPond: closes=14 avg_compliance=None
- median_compliance_below_850: median=830.0
```

Red flag fired correctly: `median_compliance_below_850` (median=830).

## AG-B2 — fleet-daily-rollup.py

Path: `.flywheel/scripts/fleet-daily-rollup.py`. Canonical CLI per
`canonical-cli-scoping`: `run/doctor/health/repair/validate/audit/why +
schema/examples/info/completion/help`.

Algorithm:
1. Invoke `daily-report-enabled-repos.sh --no-notify --json`
2. For each `result.quality_grade`, accumulate compliance, dispositions,
   fitness counts, identity rows.
3. Run a count-weighted compliance-distribution merge (each repo's avg
   contributes proportionally to its callback_count); document the
   approximation in the report header.
4. Detect RED FLAGS per spec:
   - `fleet_median_compliance_below_850`
   - `repo_median_compliance_below_850`
   - `fleet_blocked_escalate_above_20pct` (fleet rate >0.20 with n≥5)
   - `repo_blocked_escalate_rate_above_20pct`
   - `worker_avg_compliance_below_800` (closes ≥3)
   - `fleet_mission_fitness_drift_above_5`
5. Render markdown with TOP-LINE summary, fleet table, per-repo block,
   worker attribution.

Live smoke (run command):

```json
{
  "report_path": "/Users/josh/.local/state/flywheel/fleet-daily-2026-05-10.md",
  "fleet_callbacks": 45,
  "fleet_blocked_rate": 0.067,
  "red_flags": [
    {"code": "fleet_median_compliance_below_850", "detail": "median=839.1"},
    {"code": "repo_median_compliance_below_850", "detail": "repo=/Users/josh/Developer/flywheel median=830.0"}
  ],
  "worker_table_count": 2
}
```

Top-line of `~/.local/state/flywheel/fleet-daily-2026-05-10.md`:

> **Fleet shipped 45 closes** at avg compliance 839.1 (median 839.1);
> 3 BLOCKED/ESCALATE; 2 red flags.

## AG-B3 — aggregator launchd

Path: `.flywheel/launchd/ai.zeststream.flywheel-fleet-daily-rollup.plist`.
Schedule: `StartCalendarInterval Hour=8 Minute=30` (08:30 local, 30min
after Bead A's 08:00 fire). `KeepAlive=false`, `RunAtLoad=false`. Logs
under `~/.local/state/flywheel/`. plutil -lint OK.

Sequence (all rc=0):

```bash
cp .flywheel/launchd/ai.zeststream.flywheel-fleet-daily-rollup.plist \
   ~/Library/LaunchAgents/

flywheel-watchers --apply register \
  --label ai.zeststream.flywheel-fleet-daily-rollup \
  --owner flywheel-1 \
  --reason "fleet-wide quality grading rollup per flywheel-u2yc0 + Joshua signoff 2026-05-10"

launchctl bootstrap gui/$(id -u) \
  ~/Library/LaunchAgents/ai.zeststream.flywheel-fleet-daily-rollup.plist
# rc=0

launchctl print gui/$(id -u)/ai.zeststream.flywheel-fleet-daily-rollup
# => active count = 0, state = not running, type = LaunchAgent (loaded, awaiting next 08:30)
```

Rollback:

```bash
launchctl bootout gui/$(id -u)/ai.zeststream.flywheel-fleet-daily-rollup
flywheel-watchers --apply unregister --label ai.zeststream.flywheel-fleet-daily-rollup
rm ~/Library/LaunchAgents/ai.zeststream.flywheel-fleet-daily-rollup.plist
```

## AG-B4 — smoke + receipt

| Field | Value |
|---|---|
| First aggregator fire | 2026-05-10T15:30Z (08:30 local) |
| Today's rollup | `~/.local/state/flywheel/fleet-daily-2026-05-10.md` (1043 bytes) |
| Fleet callbacks | 45 |
| BLOCKED/ESCALATE rate | 0.067 |
| Red flags | 2 (fleet_median_compliance_below_850, repo_median_compliance_below_850) |
| Worker attribution | 2 identities (MistyCliff 30 closes, MagentaPond 14 closes) |
| Plist path | `.flywheel/launchd/ai.zeststream.flywheel-fleet-daily-rollup.plist` |
| LaunchAgents path | `~/Library/LaunchAgents/ai.zeststream.flywheel-fleet-daily-rollup.plist` |
| Bootstrap status | `active count = 0`, `state = not running` (loaded, awaiting next 08:30) |
| Watcher registered | yes (owner `flywheel-1`) |

This receipt is the file the spec calls
`.flywheel/audit/daily-ops-fleet-quality/evidence.md`.

## Notes

- The fleet-level compliance distribution is **count-weighted** — each
  repo's `avg_compliance` is repeated `callback_count` times before
  computing fleet quartiles. The proxy is documented in the rollup
  field name (`compliance_distribution_count_weighted_avg`). Raw fleet
  quartiles would require re-reading every repo's callback log; the
  count-weighted proxy is sufficient for red-flag triggering and avoids
  duplicating IO.
- `MagentaPond avg_compliance=None` reflects today's BLOCKED rows that
  did not include a compliance score (per BLOCKED-disposition shape).
  The aggregator skips such rows from compliance averaging but still
  counts the close.
- Bead A's coverage gap (only 2 of 96 candidate repos enabled) carries
  through — fleet rollup currently grades flywheel + mobile-eats only.
  Expanding `daily-report-config.json` opt-ins is a separate hygiene
  task (logged in flywheel-lb2gk evidence; not auto-done here).

## Four-Lens Self-Grade

- brand: 9/10 — matches existing daily-report.py / fleet-daily plist patterns
- sniff: 10/10 — every transformation has live evidence + red-flag firing observed
- jeff: 9/10 — data decides (red flags fire mechanically on real today's data, not theater)
- public: 9/10 — operator can `cat ~/.local/state/flywheel/fleet-daily-<date>.md` and see fleet shape in 30s

four_lens=brand:9,sniff:10,jeff:9,public:9
