# Upstream issue draft — Dicklesworthstone/ntm

**Repo:** github.com/Dicklesworthstone/ntm
**Title:** `ntm health` and `ntm activity` disagree on idle/working classification — health misses frozen codex spinners
**Filed:** drafted 2026-05-02, not yet submitted
**Severity:** medium (operational; orchestrators trust the wrong probe)

## Reproduction

ntm session with a codex pane that:
1. Is mid-`Working (Nm Ns • esc to interrupt)` spinner
2. Has a queued user prompt visible as `› <text>` below the spinner (text typed but Enter not pressed, or send-keys delivered without Enter)
3. Is genuinely frozen (timer not advancing)

```
Pane state observed today (skillos:0.1, codex 0.125.0):
  • Working (4m 04s • esc to interrupt)

  › Summarize recent commits
```

## Expected

`ntm health` and `ntm activity` agree on the pane's state — either both report it as active/thinking, or both report it as idle/queued. Operators script around `ntm health` because that's the documented status command.

## Actual

```
$ ntm health skillos --json | jq '.agents[] | select(.pane==1) | {activity, indicators: .progress.indicators}'
{
  "activity": "idle",
  "indicators": ["idle_prompt"]
}

$ ntm activity skillos --json | jq '.agents[] | select(.pane==1) | {state,velocity,duration}'
{
  "state": "THINKING",
  "velocity": 0,
  "duration": "0s"
}
```

`ntm activity` correctly catches the spinner. `ntm health` matches the trailing `›` as `idle_prompt` and stops there, missing the higher-up `Working (...)` line.

## Impact

Multi-agent orchestrators (in our case, the flywheel substrate) use `ntm health` to decide whether a pane is dispatchable. A frozen-but-queued codex pane reads as idle, so the orchestrator dispatches a new task into a wedged worker. Loss = the new dispatch is silently absorbed by the queued state.

## Suggested fix

Have `ntm health` consume `ntm activity`'s state machine as the source of truth for the `activity` field, OR add the spinner-pattern probe (`Working \([0-9]+m`) to health's detector hierarchy ahead of the `idle_prompt` rule.

Bonus: a third state `queued_not_submitted` would help orchestrators distinguish "idle and ready" from "idle but has unsubmitted text in the input box" — these need different remediation (dispatch new vs send-keys Enter).

## Workaround applied locally

Switching all flywheel pane-state checks from `ntm health` to `ntm activity --json` as primary truth source; `ntm health` becomes secondary cross-check only. Tracked in flywheel-terc + flywheel-7xxs.

## Versions

- ntm: (run `ntm version` to fill at submit time)
- codex: 0.125.0
- macOS Darwin 25.3.0
- tmux 3.6a
