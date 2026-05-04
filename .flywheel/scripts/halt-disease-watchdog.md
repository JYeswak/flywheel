# halt-disease-watchdog

`halt-disease-watchdog.sh` is the Phase 1 observer for
`halt-by-default-cascades-through-every-layer`. It measures whether a scoped
doctor or loop signal has turned into fleet idleness.

## Contract

Command:

```bash
/Users/josh/Developer/flywheel/.flywheel/scripts/halt-disease-watchdog.sh --once --json
```

Output ledger:

```text
/Users/josh/.local/state/flywheel/halt-disease-watchdog.jsonl
```

Schema: `halt-disease-watchdog/v1`.

The script is read-only except for its own append-only observation ledger. It
does not call `br`, does not mutate beads, and does not call raw pane tools. Pane
activity is measured only through:

```bash
/Users/josh/.local/bin/ntm --robot-activity=<session> --activity-type=codex,claude --json
```

Doctor probes run with `FLYWHEEL_DOCTOR_NTM_HEALTH_DISABLED=1` because this
watchdog already owns the live NTM activity measurement. That avoids recursive
pane-health probing turning the watchdog into a stalled loop.

Every external probe is capped by `FLYWHEEL_HALT_WATCHDOG_TIMEOUT_SECONDS`
(default `10`) and timeout rows are reported as HIGH observations instead of
blocking the watchdog itself.

## Invariants

`fleet_idle_with_ready_work_count` counts sessions with live idle panes over the
window while repo-local `.beads/issues.jsonl` has ready P0/P1 work.

`yellow_without_permitted_work_count` counts yellow doctor contracts that are
not followed by a dispatch within ten minutes, plus unscoped yellow contracts
that name no permitted actions.

`red_ignored_count` counts red doctor contracts followed by dispatch activity
within ten minutes. Red still blocks dangerous work.

`joshua_mornings_with_idle_fleet_risk` is true when at least two sessions are
idle with ready work. The intended pre-morning check is 12:55Z.

## Degraded Halt-Contract Mode

Until every doctor emits `halt-contract/v1`, the watchdog consumes plain
`.status`:

- `fail|error|red` becomes conservative inferred red with no permitted actions.
- `warn|warning|yellow` becomes inferred yellow with plan/validate/non-dangerous
  dispatch permitted.

Each inference is written in the JSONL row so Phase 2 can replace it with real
scoped contracts.

## Exit Codes

- `0`: healthy.
- `1`: HIGH alarm.
- `2`: CRITICAL alarm.

The one-line dashboard output is meant for `/flywheel:status`:

```text
halt_disease status=<status> idle_ready=<N> yellow_no_work=<N> red_ignored=<N> joshua_morning_risk=<true|false>
```

## Structural Story

The watchdog compiles the Lane B creed into measurement:

```text
Truth blocks lies; safety blocks risk; everything else becomes routed work.
```

If yellow signals stop the fleet, the watchdog fires. If red signals are ignored,
it also fires. The point is not to lower the bar; it is to require every bar to
say what it blocks and what work remains safe.
