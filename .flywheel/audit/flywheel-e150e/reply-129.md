`ntm unlock /abs/path --session --pane --task-id --json` is a near-1:1 substitution for downstream release callsites. The shape works.

Both your design points match the use case:

1. Idempotent `state: already_released` on free paths — strong yes. Worker close paths can crash mid-cycle and the rerun re-tries release on already-freed paths. Today wrappers hand-roll this idempotency by checking `--list` before `--release`; native `state: already_released` collapses two calls into one and removes the TOCTOU window between them.

2. Mismatched-holder fail-loud (`state: not_held`) — strong yes. Silent no-op masks the worst-case bug: a worker on one pane calling release on a path another pane still holds because of a registry-key mismatch. Loud failure with `state: not_held` + `holder` populated is the only response that surfaces the wrapper bug rather than concealing it.

One observation: aligning the return envelope keys with #127's lock-check shape (`state, holder, reservation_id, task-id`) means the wrapper uses the same JSON parser for both directions. Worth a short consistency note in the CHANGELOG.

Coordinated four-issue ship matches what we want. Holding.
