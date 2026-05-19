# Dispatch Template Contract

This repo-local template documents the worker callback bridge contract for
Flywheel dispatch packets. It complements the external Claude command template
at `/Users/josh/.claude/commands/flywheel/_shared/dispatch-template.md`.

## Pane-1 Sprint-Complete Bridge

Goal sprint closeout rows must be appended to `.flywheel/dispatch-log.jsonl`
using the callback envelope shape:

```json
{"schema_version":"callback-envelope/v1","event":"worker_callback","mode":"goal","status":"DONE","pane1_callback":"sent"}
```

The bridge reader is `.flywheel/scripts/pane1-bridge-tailer.sh`. It tails the
dispatch log, detects new goal `worker_callback` rows with done/pass status,
deduplicates them by callback row hash, sends a structured sprint-complete
message to pane 1, and records the result in
`~/.local/state/flywheel/pane1-sprint-complete-bridge.jsonl`.

Run once for backfill or health checks:

```bash
.flywheel/scripts/pane1-bridge-tailer.sh --repo "$PWD" --once --json
```

Run as a watcher:

```bash
.flywheel/scripts/pane1-bridge-tailer.sh --repo "$PWD" --follow --json
```

## Beads JSONL Auto-Staging

Worker dispatches that run `br` in this repo should resolve it through
`/Users/josh/.local/bin/br`, which is the flywheel dogfood wrapper
`.flywheel/scripts/br-stage-wrapper.sh`. Successful mutating Beads commands
(`create`, `close`, `update`, and `dep`) auto-stage `.beads/issues.jsonl` so the
worker's final commit can include the Beads mutation without carrying residual
unrelated dirt. If `command -v br` does not resolve to `/Users/josh/.local/bin/br`,
run the wrapper explicitly or report `beads_issues_autostage_missing`.

## Fallback

If the bridge is suspected broken, the worker MUST run the pane-1 notification
directly and must not rely on `pane1_callback:"sent"` alone:

```bash
ntm send flywheel --pane=1 "DONE: <task-id> commit=<sha> tests=<PASS|FAIL> evidence=<path>"
```

For bridge-repair sprints, the direct fallback is mandatory because the bridge
is the system under test.
