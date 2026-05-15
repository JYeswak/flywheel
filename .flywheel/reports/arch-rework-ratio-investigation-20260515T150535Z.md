# Architecture Rework Ratio Investigation

bead: flywheel-arch-rework-ratio-3-72-red-s6onj
generated_at: 2026-05-15T15:05:35Z

## Trigger

The weekly founder-dispose report showed `architecture_health_status=red` with
`rework_ratio=3.72`. The bead described that number as reopened,
re-dispatched, or multi-cycle work.

## Finding

The rollup did not measure that definition. The script computed:

`rework_ratio = (validation_fail + fuckup_rows) / dispatches`

For the live 7-day window, that meant:

| Signal | Count |
|---|---:|
| Dispatches | 192 |
| Unique dispatch task IDs | 192 |
| Redispatched task IDs | 0 |
| Redispatch rows | 0 |
| Validation receipts | 0 |
| Validation failures | 0 |
| Fuckup-log observations | 713 |

The red signal was real, but it was an architecture-debt observation signal,
not measured rework. The old number was `713 / 192 = 3.7135`.

## Hypotheses

H1 — Dispatch packets under-specify scope.

Killed for this window. There were zero duplicate task IDs across 192
dispatches.

H2 — Callback validation gate too strict.

No current evidence. The rollup had zero validation receipts and zero
validation failures in the 7-day window.

H3 — Beads compliance surfaces false-closed beads that get reopened.

Not supported by the rollup evidence. The live red number was dominated by
untied fuckup-log rows; only 3 of 713 rows carried `bead_id`.

H4 — Formula mismatch / metric mislabel.

Confirmed. The metric mixed measured rework events with a stock of failure
observations. That made a debt-observation backlog look like 3.7x rework.

## Architecture Change

The rollup now separates the two loops:

- `rework_ratio`: measured rework events only, currently validation failures
  plus duplicate dispatch rows.
- `architecture_debt_observation_ratio`: fuckup-log observations divided by
  dispatches.

The red status remains red when debt observations are high. The system no
longer says workers are reworking 3.7x when the data actually says architecture
debt observations are accumulating faster than dispatch volume.

## Post-Change 7-Day Rollup

After the change:

| Metric | Value |
|---|---:|
| `rework_ratio` | 0.0 |
| `architecture_debt_observation_ratio` | 3.7135 |
| `architecture_health_status` | red |

Dashboard line:

`Architecture Health: red | leverage_trend=+3693%/30d | rework_ratio=0.00 | debt_observation_ratio=3.71 | founder_dispose_pct=0%`

## Decision

Close this bead as a metric-contract repair, not a green architecture-health
claim. The red work now points at the right system: reduce recurring
architecture-debt observations, not chase nonexistent redispatch rework.
