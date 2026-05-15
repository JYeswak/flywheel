# /goal-mode worker test — pane 1 runbook

End-to-end validation of the accretive /goal regime using a real Claude
or Codex worker on pane 1 of the flywheel ntm session. Complements the
automated tests in `tests/goal-mode.sh` (schema validator, goal-text
linter, cycle simulator, anti-spin assertion).

This runbook is the operator-driven step the simulator cannot cover:
proving the regime survives a live worker over multiple real turns.

## Prerequisites

- Flywheel session has a worker on pane 1 (Claude Code or Codex CLI).
- Pane 0 is the orchestrator (this Claude session, flywheel:1).
- `tests/goal-mode.sh` passes locally (T1–T4 green).

## Test goal text (paste into pane 1's `/goal` after worker is live)

A minimal test goal, ≤4k chars, that exercises every part of the regime:

```text
Steward this test repo with an accretive watch. Every cycle: ACT, ACCRETE, or STAND DOWN.

PER-CYCLE OUTPUT (one required):
- ACT: real event (new commit, CI change, operator input). Investigate, attach receipt.
- ACCRETE: no event → produce a named artifact (doctrine refinement, skill candidate, gate hardening, knowledge pack, decision record, coverage backfill).
- STAND DOWN: nothing to act on AND no accretive surface. One-line ack; event-driven only until next event or operator input.

WAKE TRIGGERS (priority):
1. Operator input.
2. New commit on either repo (HEAD moves).
3. CI state transition.

ANTI-SPIN:
- 3 identical no-delta cycles → STAND DOWN until event.

ACCRETION TARGETS:
- Visually: each page audited once per ship.
- Technically: CI baseline tracked.
- Operationally: H-1..H-4 transitions reported.

OUTPUT FORMAT PER CYCLE:
- ACT: "delta: X; receipt: <path>"
- ACCRETE: "no delta; harvested: <artifact>; reusable because <R>"
- STAND DOWN: "verified clean; standing down until event."

All cycle outputs append to /tmp/goal-mode-worker-test.jsonl.
```

(Save this as `/tmp/test-goal.txt` for easy paste.)

## Phases

### Phase A — bootstrap

1. **Operator**: on pane 1, set the goal with `/goal <paste-test-goal>`.
2. **Worker**: should emit cycle 1 = ACT (operator-input event); writes
   one row to `/tmp/goal-mode-worker-test.jsonl`.
3. **Operator on pane 0**: verify the row passes:
   ```bash
   python3 scripts/validate_watch_log.py --file /tmp/goal-mode-worker-test.jsonl --json
   ```
   Expect `status=pass`, 1 ACT row.

### Phase B — anti-spin live fire

1. **Wait three Stop-hook turns** with no operator input, no commits,
   no CI transitions.
2. **Worker** should emit:
   - Cycle 2: ACCRETE (streak=1)
   - Cycle 3: ACCRETE (streak=2)
   - Cycle 4: STAND DOWN (streak hit 3 → anti-spin fires)
3. **Operator on pane 0**: verify with:
   ```bash
   python3 scripts/validate_watch_log.py --file /tmp/goal-mode-worker-test.jsonl --json
   ```
   Expect `cycle_counts` includes `{"ACT":1,"ACCRETE":2,"STAND_DOWN":1}`
   (counts may have additional STAND_DOWN holds if more turns elapse).

### Phase C — event resumption

1. **Operator**: trigger a real event (e.g. a no-op commit on the test
   repo or send a message to pane 1).
2. **Worker** should emit cycle N+1 = ACT (new-commit or operator-input
   event); streak resets to 0.
3. **Operator on pane 0**: verify the new row passes schema; verify
   `cycle_counts.ACT >= 2`.

### Phase D — goal text lint

1. **Operator on pane 0**: lint the test goal text:
   ```bash
   python3 scripts/validate_goal_text.py --file /tmp/test-goal.txt
   ```
   Expect `status=pass`, 11/11 checks pass.

### Phase E — teardown

1. **Operator**: `/goal cancel` on pane 1.
2. **Operator on pane 0**: optionally archive
   `/tmp/goal-mode-worker-test.jsonl` to
   `.flywheel/evidence/goal-mode-worker-test-<TS>.jsonl`.

## Success criteria

The test PASSES when, end-to-end:

| # | Criterion | Verification |
|---|-----------|--------------|
| 1 | Worker writes one row per Stop-hook turn | `wc -l /tmp/goal-mode-worker-test.jsonl` ≥ turn count |
| 2 | Every row passes the schema | `validate_watch_log.py --file ... --json` returns `status=pass` |
| 3 | Anti-spin fires by cycle 4 (after 3 consecutive no-event turns) | `cycle_counts.STAND_DOWN >= 1` after Phase B |
| 4 | A real event resumes ACT cycles | `cycle_counts.ACT >= 2` after Phase C |
| 5 | Goal text linter passes | `validate_goal_text.py` exit 0, `status=pass` |

## Failure modes to watch for

- **Polling regression**: worker emits ACCRETE every turn forever
  without STAND DOWN. → check for anti-spin clause in goal text,
  verify the worker is reading it.
- **Schema drift**: rows missing required fields. → patch the worker
  prompt to emit the canonical row shape.
- **Cycle inflation**: worker emits multiple rows per turn. → goal
  text should specify one cycle per turn.
- **Event miss**: operator sends a message but worker keeps emitting
  STAND DOWN. → worker not reading operator input as a wake trigger.

## Test artifacts location

- Live worker log: `/tmp/goal-mode-worker-test.jsonl`
- Archived (post-test): `.flywheel/evidence/goal-mode-worker-test-<TS>.jsonl`
- Validators: `scripts/validate_watch_log.py`, `scripts/validate_goal_text.py`
- Simulator (for offline replay): `scripts/simulate_goal_cycles.py`
