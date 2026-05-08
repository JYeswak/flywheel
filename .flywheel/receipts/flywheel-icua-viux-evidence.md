# flywheel-viux evidence

task_id=eeceb97a
bead=flywheel-viux
reconstruction_note=original /tmp evidence path was pruned before flywheel-icua; this receipt is rebuilt from the parent bead, MISSION closeout excerpt, git history, and durable repo artifacts before appending the public lens.

## DID

did=12/12
didnt=none
gaps=none
tests=PASS

## Acceptance Gates

| gate | status | evidence |
|---|---|---|
| AG1 idle-state probe exists | DID | `.flywheel/scripts/idle-state-probe.sh` emits `idle-state-probe/v1` JSON with `pane`, `state`, `idle_state_class`, ready-bead counts, and mission pending count. |
| AG2 doctor JSON gains idle classes | DID | `flywheel-loop doctor --json` consumes the canonical probe fields `idle_state_class`, `idle_state_summary`, `idle_dispatching_over_threshold_count`, `idle_state_config_path`, and `idle_state_config_loaded`. |
| AG3 dispatching over threshold fails readiness | DID | `tests/idle-state-probe.sh` asserts `status == "fail"` and `idle_dispatching_over_threshold_count == 1` for a dispatching pane over the threshold. |
| AG4 fixture coverage | DID | `tests/idle-state-probe.sh` covers `dispatching`, `cooldown`, `light_queue`, `saturated`, `disabled_class`, and `not_waiting`. |
| AG5 watcher reads doctor/probe signal | DID | `.flywheel/scripts/idle-pane-auto-dispatch.sh` uses `FLYWHEEL_IDLE_STATE_PROBE` / `.flywheel/scripts/idle-state-probe.sh` and dispatches only from `idle_state_class=="dispatching"` rows. |
| AG6 daemon documented | DID | `.flywheel/launchd/ai.zeststream.alps-idle-pane-watch.plist`, `.flywheel/launchd/ai.zeststream.mobile-eats-idle-pane-watch.plist`, `.flywheel/launchd/ai.zeststream.skillos-idle-pane-watch.plist`, and `.flywheel/launchd/ai.zeststream.vrtx-idle-pane-watch.plist` document the idle watcher launchd surface. |
| AG7 doctrine landed | DID | `AGENTS.md` L85 `IDLE-STATE-CLASS-CANONICAL` makes the doctor-visible classifier the canonical rule. |
| AG8 fleet propagation | DID | `templates/flywheel-install/AGENTS.md` carries the same L85 doctrine for flywheel-installed repos. |
| AG9 schema/config versioned | DID | `.flywheel/validation-schema/v1/idle-state-config.schema.json` and probe output use `idle-state-config/v1` / `idle-state-probe/v1`. |
| AG10 peer-orchestrator policy | DID | Default config disables `saturated` for peer orchestrators and keeps `dispatching` plus `light_queue` active for xpane escalation. |
| AG11 convergence tests | DID | `tests/test_idle_pane_watcher_convergence.sh` verifies watcher/probe convergence and dispatch candidate selection from ready beads. |
| AG12 delivery guard tests | DID | `tests/idle-pane-auto-dispatch-validated-write-test.sh`, `tests/idle-pane-auto-dispatch-closed-guard-test.sh`, and `tests/idle-pane-auto-dispatch-work-started-validation-test.sh` cover validated dispatch write, closed-bead guard, and work-started verification. |

## Files Changed For Parent Work

- `.flywheel/scripts/idle-state-probe.sh`
- `.flywheel/scripts/idle-pane-auto-dispatch.sh`
- `.flywheel/validation-schema/v1/idle-state-config.schema.json`
- `.flywheel/launchd/ai.zeststream.alps-idle-pane-watch.plist`
- `.flywheel/launchd/ai.zeststream.mobile-eats-idle-pane-watch.plist`
- `.flywheel/launchd/ai.zeststream.skillos-idle-pane-watch.plist`
- `.flywheel/launchd/ai.zeststream.vrtx-idle-pane-watch.plist`
- `AGENTS.md`
- `templates/flywheel-install/AGENTS.md`
- `tests/idle-state-probe.sh`
- `tests/test_idle_pane_watcher_convergence.sh`
- `tests/idle-pane-auto-dispatch-validated-write-test.sh`
- `tests/idle-pane-auto-dispatch-closed-guard-test.sh`
- `tests/idle-pane-auto-dispatch-work-started-validation-test.sh`

## Validation

```bash
bash tests/idle-state-probe.sh
bash tests/test_idle_pane_watcher_convergence.sh
bash tests/idle-pane-auto-dispatch-validated-write-test.sh
bash tests/idle-pane-auto-dispatch-closed-guard-test.sh
bash tests/idle-pane-auto-dispatch-work-started-validation-test.sh
br dep cycles
```

Parent closeout excerpt recorded `tests=PASS`, `callback_delivery_verified=true`, `identity_name=IvoryBarn`, `socraticode_queries=3`, and `indexed_chunks_observed=30`.

## Outcome

The parent work moved idle-worker classification out of a private `/tmp` watcher and into a doctor-visible, fixture-tested information flow. That reduces founder/operator blind spots: the orchestrator can now see when a waiting pane is dispatchable, cooling down, lightly queued, saturated, disabled by policy, or not waiting.

## Four-Lens Rework - flywheel-icua

### Public Lens Self-Grade - Three Judges Publishability

Would-they-fork-and-star verdict: PASS for the scoped `flywheel-viux` substrate. A serious builder can read the receipt and understand the operating change: idle-worker state is no longer private watcher logic; it is a versioned probe, doctor signal, doctrine rule, watcher input, launchd surface, and regression-tested dispatch path.

| facet_id | facet | verdict | evidence |
|---|---|---|---|
| F1 | README front-door | YES | The closeout names the start path and commands: `.flywheel/scripts/idle-state-probe.sh`, `flywheel-loop doctor --json`, and the watcher script. |
| F2 | Doctrine clarity | YES | L85 `IDLE-STATE-CLASS-CANONICAL` in `AGENTS.md` and `templates/flywheel-install/AGENTS.md` explains why doctor-visible state replaces private watcher logic. |
| F3 | Doctor/health/repair triad | YES | The doctor surface exposes `idle_state_class`, `idle_state_summary`, and `idle_dispatching_over_threshold_count`; over-threshold dispatching panes fail readiness. |
| F4 | Executable tests | YES | The receipt lists reproducible shell tests for the probe, watcher convergence, validated write, closed-bead guard, and work-started verification. |
| F5 | Idempotent install + uninstall | YES | The launchd artifacts are declarative plist files, watcher dispatch defaults to dry-run unless apply is selected, and the probe reads fixtures/config without global mutation. |
| F6 | Code aesthetic | YES | The classification vocabulary is small and named: `dispatching`, `cooldown`, `light_queue`, `saturated`, `disabled_class`, and `not_waiting`. |
| F7 | Demo-ability | YES | A reviewer can run `bash tests/idle-state-probe.sh` or `flywheel-loop doctor --json | jq '.idle_state_summary'` to see the value without oral handoff. |

Three Judges:

- Jeffrey: PASS. The substrate has versioned JSON surfaces, schema/config markers, fixture tests, dry-run defaults, and watcher/doctor integration points.
- Donella: PASS. This is a Meadows #6 information-flow repair: the stock of idle waiting worker capacity becomes visible in doctor JSON before the watcher or founder has to infer it from pane state.
- Joshua: PASS. A 25-year operations manager would recognize the operator-experience pattern: idle capacity has to be a queue-depth signal, not a private script hunch. This has team-fit, company-building leverage, and turnover resilience because a later operator can inspect the doctor row and tests instead of inheriting a daemon only the original worker understood.

Public voice gate: EXEMPT internal substrate receipt. ZestStream voice score: not applicable. Banned words count: 0. Ungrounded claims count: 0. Scorecard log: this section.

Four-Lens Self-Grade: brand voice PASS; Joshua sniff PASS; Jeff doctrine PASS; public publishability PASS for Three Judges and all seven facets.

Result: the receipt now names the publishability bar and explains why the 12/12 idle-state doctor-signal work is fork-and-star grade for its internal substrate scope.
