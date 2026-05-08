# flywheel-0x9f Receipt

## JSM Schema Probe

Captured before implementation choices:

```text
jsm outcome --help
Usage: jsm outcome [OPTIONS]
  -s, --skill <SKILL>     Skill identifier, required unless --batch is used
      --success           Mark outcome as success
      --failure           Mark outcome as failure
      --duration <N>      Duration in seconds
      --context <JSON>    Metadata JSON
      --batch <PATH>      JSONL batch import
      --json              Structured output
      --offline           Local/offline mode
```

The CLI has no native `--harness` flag, so Phase C stores harness partitioning
inside `--context` as `harness=claude|codex|gemini`.

## Shipped

- Bridge: `.flywheel/scripts/worker-tick-jsm-outcomes.sh`
- Test: `tests/test_worker_tick_jsm_outcomes.sh`
- Worker command doc: `/Users/josh/.claude/commands/flywheel/worker-tick.md`

The bridge consumes Phase B receipts with
`schema_version="flywheel-worker-tick/v1"` and `mode="worker-mode"`, extracts
skills from the skill-consultation check, and emits one planned `jsm outcome`
event per valid skill. Dry-run is default. Apply mode invokes:

```text
jsm outcome -s <skill> --success|--failure --duration 0 --context <json> --json --offline
```

## Validation

- `bash -n .flywheel/scripts/worker-tick-jsm-outcomes.sh`
- `bash tests/test_worker_tick_jsm_outcomes.sh`
- `bash tests/test_worker_tick_phase_b.sh`

`tests/test_worker_tick_jsm_outcomes.sh` passed 7 assertions:

- dry-run emits one planned event per skill
- apply mode works with a mocked `jsm` binary
- apply context contains `harness`
- Claude success plus Codex failure for the same skill reports
  `harness_partitioned_drift_candidate`
- invalid Phase B receipt shape emits validation error and no events
- invalid skill names emit validation errors and do not poison the bandit

## Notes

The live schema probe command `jsm outcome -s beads-workflow --success
--context '{"probe":"flywheel-0x9f","dry_schema":true}' --json --offline` was
also run to confirm structured output behavior. Fixture apply tests use a mock
JSM binary, not the real bandit store.
