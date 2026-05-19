# Pane-1 Callback Bridge Regression

Date: 2026-05-19

Scope: scoped to bridge regression fix only.

## Diagnosis

The pane-1 sprint-complete bridge was attached to the append primitive, not to the durable callback ledger. The function exists at `.flywheel/scripts/append-safe-write.sh` as `maybe_emit_pane1_sprint_complete(...)`, and it only fires when that script appends to a target named `dispatch-log.jsonl`.

That hook is not the canonical writer for all callback rows. Current write paths found by grep:

```text
.flywheel/scripts/dispatch-and-log.sh: dispatch send rows; appends directly with printf >> "$LOG".
/Users/josh/.claude/commands/flywheel/dispatch.md: dispatch send rows; appends directly with printf >> "${REPO:-$PWD}/.flywheel/dispatch-log.jsonl".
/Users/josh/.claude/commands/flywheel/dispatch.md: mutates existing dispatch rows with Python path.write_text(...).
.flywheel/scripts/dispatch-log-backfill-v2.sh: backfill utility; rewrites dispatch-log.jsonl on --apply.
.flywheel/scripts/auto-refill-decision-log.sh: auto-refill decision rows; writes to dispatch-log.jsonl on --apply.
worker callback closeouts: callback-envelope/v1 rows are appended directly by workers during closeout.
```

The bridge ledger stopped at `2026-05-19T07:34:36Z` because subsequent workers wrote valid `worker_callback` rows directly to `.flywheel/dispatch-log.jsonl`, bypassing the append-safe post hook while still claiming `pane1_callback:"sent"`.

## Canonical Writer Verdict

There is no single enforced canonical writer for `.flywheel/dispatch-log.jsonl` today. The canonical dispatch-send wrapper is `.flywheel/scripts/dispatch-and-log.sh` for repo-local scripted dispatch, while `/Users/josh/.claude/commands/flywheel/dispatch.md` remains an external command writer for Claude command dispatch. Worker callback rows are a closeout contract, not a single script call path.

Therefore `.flywheel/dispatch-log.jsonl` itself is the canonical source of truth for sprint-complete callback rows.

## Fix Shape

Chosen option: **B, tail-watcher bridge**.

New surface: `.flywheel/scripts/pane1-bridge-tailer.sh`.

Why this survives respawn and writer diversity:

- It observes the durable callback ledger instead of depending on one append helper.
- It deduplicates with a `callback_key` derived from the exact callback row.
- It writes the same bridge ledger schema used by the original hook:
  `pane1-sprint-complete-bridge/v1`.
- It supports `--once` for replays/backfills and `--follow` for a daemon-style tailer.
- It can be run after a respawn without resending already-ledgered callbacks.

The old append-safe hook remains useful for append-safe writers, but it is no longer the only path capable of bridging sprint completion.

## Operating Contract

Every goal sprint closeout callback row must be:

```json
{"schema_version":"callback-envelope/v1","event":"worker_callback","mode":"goal","status":"DONE","pane1_callback":"sent"}
```

The bridge tailer detects those rows and sends:

```bash
ntm send flywheel --pane=1 --no-cass-check "SPRINT DONE: sprint=<id> task=<id> ..."
```

Fallback if the bridge is suspected broken:

```bash
ntm send flywheel --pane=1 "DONE: <task> commit=<sha> tests=<PASS|FAIL> evidence=<path>"
```

Workers must run the fallback directly when the bridge itself is the sprint under repair.

## Backfill Command

The missed 2026-05-19 callbacks can be replayed idempotently with:

```bash
.flywheel/scripts/pane1-bridge-tailer.sh \
  --repo /Users/josh/Developer/flywheel \
  --since-ts 2026-05-19T07:34:36Z \
  --once \
  --json
```

## Validation

Fixture:

```bash
bash tests/pane1-callback-bridge.sh
```

Manual bridge health:

```bash
.flywheel/scripts/pane1-bridge-tailer.sh --repo /Users/josh/Developer/flywheel --since-ts 2026-05-19T07:34:36Z --once --json
tail -n 3 ~/.local/state/flywheel/pane1-sprint-complete-bridge.jsonl
```
