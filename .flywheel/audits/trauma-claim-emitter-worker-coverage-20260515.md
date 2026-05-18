# trauma-claim-emitter worker coverage audit — 2026-05-15

Task: audit `.flywheel/scripts/trauma-claim-emitter.sh` for hook-detected
worker trauma coverage and N=3 MEMORY promotion.

Verdict: **gap confirmed.** The emitter can see `worker_` classes if they are
inside the recent fuckup-log tail, but it does not explicitly watch the
`worker_` namespace, does not count saturation, and never writes or triggers
`MEMORY.md` promotion.

## Evidence inspected

- `.flywheel/scripts/trauma-claim-emitter.sh`
- `tests/trauma-claim-emitter-canonical-cli.sh`
- `.flywheel/scripts/w1-r1-cadence-tick.sh`
- `.github/workflows/ci.yml`
- Live fuckup log: `/Users/josh/.local/state/flywheel/fuckup-log.jsonl`
- Socraticode search: `trauma claim emitter fuckup-log trauma_class worker_ MEMORY promotion saturation threshold N=3`

## What the emitter currently watches

The emitter is a recent-tail class candidate emitter:

- Input path defaults to `$HOME/.local/state/flywheel/fuckup-log.jsonl`.
- Scan window defaults to `TRAUMA_EMITTER_LIMIT=200`.
- It reads rows with `.class` or `.trauma_class`.
- It deduplicates by class with `seen_classes`, so each class emits at most one
  candidate row per run.
- It filters only `test-*`, `?`, and already-seen classes.
- It classifies disposition as `known` if the class string appears in
  `INCIDENTS.md` or `~/.claude/skills/flywheel-recovery/SKILL.md`; otherwise
  `new`.
- It appends candidates to `.flywheel/evidence/trauma-candidates.jsonl`.

Relevant code points:

- `.flywheel/scripts/trauma-claim-emitter.sh:31-35` sets fuckup log, incidents,
  recovery skill, output path, and `LIMIT=200`.
- `.flywheel/scripts/trauma-claim-emitter.sh:154-160` tails the log and extracts
  `.class // .trauma_class`.
- `.flywheel/scripts/trauma-claim-emitter.sh:172-186` uses `seen_classes`, so it
  cannot compute N-per-class saturation.
- `.flywheel/scripts/trauma-claim-emitter.sh:188-194` only checks text
  absorption in incidents/recovery skill.
- `.flywheel/scripts/trauma-claim-emitter.sh:251-258` appends candidate rows to
  `OUT_PATH`; no memory path is touched.

The hourly cadence wrapper does not add promotion:

- `.flywheel/scripts/w1-r1-cadence-tick.sh:81-96` runs emitter `check`, then
  `emit`, then appends a cadence ledger row. It does not write MEMORY.

The CI coverage also stops at candidate emission:

- `.github/workflows/ci.yml:82` runs `tests/trauma-claim-emitter-canonical-cli.sh`.
- `tests/trauma-claim-emitter-canonical-cli.sh` fixtures three classes, asserts
  `candidate_count=3`, validates row shape, and checks known/new disposition.
  It has no `worker_`, N=3, saturation, or MEMORY assertion.

## Live data check

Current live counts from `/Users/josh/.local/state/flywheel/fuckup-log.jsonl`:

| class | observed count | sessions | first | last |
|---|---:|---|---|---|
| `coordination-collision-detected` | 393 | `clutterfreespaces`, `flywheel` | 2026-05-07T13:50:39Z | 2026-05-15T13:00:08Z |
| `worker_low_socraticode_K` | 6 | `unknown`, `vrtx` | 2026-05-09T05:00:25Z | 2026-05-15T19:01:54Z |
| `worker_skipped_skill_lookup` | 6 | `unknown`, `vrtx` | 2026-05-09T05:00:25Z | 2026-05-15T19:01:54Z |
| `worker_skipped_ubs_on_critical_surface` | 6 | `unknown`, `vrtx` | 2026-05-09T05:00:25Z | 2026-05-15T19:01:54Z |
| `worker_unreserved_edit` | 6 | `unknown`, `vrtx` | 2026-05-09T05:00:25Z | 2026-05-15T19:01:54Z |

Within the latest 200 valid JSON rows, 141 rows matched either
`coordination-collision-detected` or one of the four worker classes. That means
the current default tail window can see today's `worker_` rows, but the emitter
still treats them as unique candidate classes, not saturated hook classes.

Manual memory entries now exist:

- `~/.claude/projects/-Users-josh-Developer-flywheel/memory/feedback_coordination_collision_detected_saturated_unpromoted.md`
- `~/.claude/projects/-Users-josh-Developer-flywheel/memory/feedback_worker_discipline_classes_unmapped_in_memory.md`
- `~/.claude/projects/-Users-josh-Developer-flywheel/memory/MEMORY.md`

Those entries are not produced by `trauma-claim-emitter.sh`; they were filed
outside the emitter path.

## Specific gap

Answering the operator questions directly:

1. **Does it watch fuckup-log.jsonl for trauma_class values starting with
   `worker_`?**

   **Partially, accidentally.** It watches recent fuckup-log rows for any
   `.class` or `.trauma_class`, so `worker_` rows are included if they are in
   the last `LIMIT` rows. It does not explicitly filter, count, or route
   `worker_` classes.

2. **Does auto-promotion to MEMORY.md fire at N=3 saturation for hook-detected
   classes?**

   **No.** There is no count aggregation, no N threshold, no hook-class
   namespace logic, and no MEMORY writer or memory-promotion command in the
   emitter or its hourly wrapper.

3. **Where is the gap?**

   Primary gap: **promotion path is manual-only.** The emitter is a candidate
   JSONL emitter, not a saturation-to-memory promoter.

   Secondary gaps:

   - **No explicit worker namespace coverage.** `worker_` classes are only
     captured by generic `.class // .trauma_class` extraction.
   - **No N=3 threshold.** Dedupe by `seen_classes` throws away recurrence
     counts before any policy can inspect them.
   - **Recent-tail only.** Default `LIMIT=200` can miss older saturation windows
     and cannot reason over 8-day class history.
   - **Tests encode the gap.** The canonical test proves only candidate emission
     and known/new disposition. It does not assert worker hook rows or MEMORY
     promotion.

## Proposed fix scope

Minimal fix should be additive, not a rewrite.

Files:

- `.flywheel/scripts/trauma-claim-emitter.sh`
- `tests/trauma-claim-emitter-canonical-cli.sh`
- Optional schema/docs touch if a new row type is added:
  `.flywheel/validation-schema/v1/trauma-candidate.schema.json`

Approximate scope:

- **Script:** ~70-110 LOC.
  - Add a saturation aggregation pass over a configurable window
    (`TRAUMA_EMITTER_PROMOTION_LIMIT`, default large enough for 8d or explicit
    all-log mode).
  - Count classes matching `^worker_` plus configured hook classes such as
    `coordination-collision-detected`.
  - For classes with `count >= 3` and no memory-index hit, emit a distinct
    promotion-ready record or invoke a controlled memory promotion helper.
  - Include `count`, `first_ts`, `last_ts`, `sessions`, `example_refs`, and
    `promotion_target=MEMORY`.
  - Do not rely on `seen_classes` for saturation mode.

- **Tests:** ~45-80 LOC.
  - Fixture three `worker_low_socraticode_K` rows and assert an N=3
    promotion-ready output.
  - Fixture two rows and assert no promotion-ready output.
  - Fixture an existing `MEMORY.md` hit and assert no duplicate promotion.
  - Assert ordinary candidate emission remains unchanged.

Recommended implementation shape:

1. Keep current `emit/check` behavior for `trauma-candidates.jsonl`.
2. Add `scan-saturation` or `emit --promotion-ready` so MEMORY promotion is a
   separate, testable path.
3. Route actual MEMORY mutation through the existing memory tooling or an
   explicit idempotent helper rather than appending prose directly inside the
   emitter.

This is a small-to-medium patch, roughly **115-190 total LOC** including tests.

