# /flywheel:loop vs /goal-build efficacy audit — 2026-05-18

## Scope

Window: 2026-05-04T00:00:00Z through 2026-05-18T20:00:00Z.

Primary data source: `.flywheel/dispatch-log.jsonl` rows newer than 2026-05-04T00:00:00Z.

Classification is conservative because dispatch rows do not yet carry a stable `mode` field:

- Loop-mode ticks: `event="ntm_dispatch_sent"` with `task_id` starting `flywheel_loop_`.
- Goal-mode sprint rows: 2026-05-18 `codex-pane-2` Track 3/substrate-compounding rows with `bead_callback_received` and `bead_close_verified` outcomes.

## Data

| Metric | /flywheel:loop tick-driven | /goal-build sprint-driven |
|---|---:|---:|
| Dispatch-log rows in 14d window | 1531 total | 1531 total |
| Mode pulse count | 42 loop tick sends | 1 observed ACK continuation; 2 inferred sprint pulses including initial dispatch |
| First pulse/outcome row | 2026-05-04T00:27:34Z | 2026-05-18T19:11:30Z |
| Last pulse/outcome row | 2026-05-09T17:23:09Z | 2026-05-18T19:53:56Z |
| Active span measured | 136.926h | 0.707h |
| Productive callback rows directly tied to mode task ids | 0 | 8 |
| Productive-callback-per-pulse | 0.000 per loop tick | 8.000 per observed ACK; 4.000 per inferred sprint pulse |
| Callback reaper rows for loop tick ids | 11 | n/a |
| Callback reaper `callback_not_found` rows for loop tick ids | 11 | n/a |
| Bead closes inside measured span | 58 | 5 |
| Bead-close-per-hour inside span | 0.424/h | 7.070/h |

Supporting raw counts in the same 14d window:

- `dispatch_sent`: 188 rows
- `idle_pane_auto_dispatch`: 105 rows
- `close`/`closed`/`bead_close_verified`: 63 rows
- `ntm_dispatch_sent` loop ticks with `flywheel_loop_` task ids: 42 rows

Interpretation: loop-mode did ship work somewhere in the broader system, but the tick task itself is not an outcome-bearing contract. The clearest direct signal is negative: 11/11 loop callback reaper rows for loop task ids resolved to `callback_not_found`. Goal-mode rows are far denser because every pick had a falsifiable close path and explicit callback envelope.

## Structural Difference

### `/flywheel:loop` + `/flywheel:tick`

Read surfaces:

- `~/.claude/commands/flywheel/loop.md`
- `~/.claude/commands/flywheel/tick.md`

Observed structure:

- `/flywheel:loop` owns cadence/state/driver proof. For Codex it requires an external launchd/`ntm send` poker and says the loop must build a bounded tick prompt.
- `/flywheel:tick` reads repo state, doctor receipts, recent tick deltas, autoloop receipts, fuckup-log, inbox state, and then picks a phase.
- The tick command has many guardrails, but the work body is state/time driven: it asks what the loop should do now from mutable substrate state.
- Dispatch-log rows do not consistently label whether a worker dispatch came from loop-mode, goal-mode, manual build-dispatch, idle watcher, or continuation sprint.
- The loop tick task id is a scheduler/orchestrator event, not a bead-level contract. The callback reaper then looks for callback rows for the tick id and repeatedly finds none.

### `/goal-build`

Read surfaces:

- `~/.claude/commands/goal-build.md`
- `~/.claude/skills/goal-build/SKILL.md`
- `~/.claude/skills/goal-build/bin/goal-build`

Observed structure:

- Goal files have six required sections, including Canonical Gates and Plain English Version.
- Canonical Gates must be falsifiable, externally observable, artifact-anchored, and include explicit vanity-metric forbid clauses.
- The validator rejects known anti-patterns: substrate-state phrasing, OR-explanation escapes, weak self-producible bars, and missing sections.
- A goal-mode dispatch packet therefore starts from a contract: hard bars, forbidden edits, out-of-scope clauses, and completion evidence shape.

## Root Cause Hypothesis

The efficacy gap is not mainly worker quality. It is contract shape.

`/goal-build` gives the orchestrator a falsifiable target and forbids escape hatches before any worker starts. `/flywheel:loop` gives the orchestrator a cadence and a large substrate snapshot, then asks it to infer the next useful target from mutable state. That makes loop-mode good at observing and poking, but weak at converting observations into high-density closed beads.

The dispatch-log data matches that hypothesis:

- Loop-mode: 42 tick prompts, 0 direct productive callbacks to tick task ids, 11 callback reaper misses for loop task ids.
- Goal-mode: 5 bead closes in 42.4 minutes, 7.07 closes/hour, with every close row carrying explicit callback/close evidence.

## Ranked Repair Options

1. **Best leverage — add a loop goal-contract gate.** Every `/flywheel:tick` DISPATCH phase must carry a compact goal contract: active goal or mini-goal, hard bars, explicit forbid clauses, target beads, out-of-scope lanes, callback envelope, and stop conditions. If absent, tick may observe/diagnose but must not dispatch worker work.
2. **Second — add stable dispatch mode attribution.** Every dispatch/callback/close row should include `mode={loop,goal,manual,watcher}`, `origin_task_id`, `goal_id`, `sprint_id`, and `tick_id` where applicable. This makes future efficacy audits mechanical instead of heuristic.
3. **Third — split loop cadence from work selection.** Keep `/flywheel:loop` as an observer/driver, but require it to call a separate selector that either binds to a goal-build contract or emits `NO_DISPATCH: missing contract` with a repair bead.

Chosen repair: Option 1, with Option 2 as prerequisite instrumentation if implementation finds attribution too ambiguous.

## Follow-up Beads Filed

- `flywheel-loop-goal-contract-gate-makes-dispatch-falsifiab-yyrph`: implement the loop goal-contract gate.
- `flywheel-dispatch-mode-attribution-for-efficacy-audits-n04mc`: add stable mode attribution fields so the repair is measurable.

## SCR Event

Component: C8 self_reference + C2 capability_diversity.

Reason: The flywheel loop is evaluating and improving its own control policy, and the repair diversifies capability by separating cadence, selection, and outcome-contract primitives.
