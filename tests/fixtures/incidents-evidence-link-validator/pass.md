# INCIDENTS fixture: pass

## dispatch-transport-denial-loop

Date: 2026-05-05

Promotion Action: NEW

Class: `dispatch-transport-denial-loop`

Severity: medium

Cost: Repeated dispatch denials consumed operator time and delayed worker routing.

Root Cause: Dispatch payloads included unsafe transport examples without a durable
gate citation.

Forever-Rule: Dispatch examples must cite the transport gate evidence before
they can become doctrine.

Evidence:
- `~/.local/state/flywheel/fuckup-log.jsonl#L5-L7`: repeated dispatch gate
  denials for the same transport class.

## bead-backed-doctrine-fix

Date: 2026-05-05

Promotion Action: UPDATE

Class: `bead-backed-doctrine-fix`

Severity: low

Cost: A documentation-only fix would not have created a durable execution path.

Root Cause: The doctrine update lacked a task substrate.

Forever-Rule: Recurring doctrine fixes need a bead or a no-bead reason.

Evidence:
- Bead `flywheel-abc1`: validator implementation task.

