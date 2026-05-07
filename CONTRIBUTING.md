# Contributing

This is a private ZestStream control-plane repo. Contributions are limited to
authorized operators and dispatched workers.

## Before Work

1. Read the bead body with `br show <id>`.
2. Survey existing substrate with Socraticode against the canonical path
   `/Users/josh/Developer/flywheel`.
3. Read the relevant skill before inventing a workflow.
4. Reserve owned paths through Agent Mail before editing.
5. Confirm the task does not overlap current pane reservations or concurrency
   notes.

## Beads Workflow

Use Beads for non-trivial work:

```bash
br ready --json
br show <id>
br update <id> --status in_progress
```

File new beads only when the task asks for it or when L52 requires a finding to
be captured. Otherwise, report `no_bead_reason` in the callback.

Do not mutate active `.beads/` files directly. `br` owns the database and the
JSONL migration surface.

## Slash Command Surface

The operator path is `/flywheel:*`:

| Command | Use |
|---|---|
| `/flywheel:tick` | One orchestration tick: reap callbacks, route work, refill hot panes. |
| `/flywheel:dispatch` | Build worker packets with dispatch-log rows and callback grammar. |
| `/flywheel:status` | Read fleet health, readiness, and callback state. |
| `/flywheel:loop` | Repeated event-driven loop execution. |
| `/flywheel:respawn` | Pane recovery with receipts. |
| `/flywheel:README` | Repo orientation and polish surface. |

## Dispatch Contract

L120-L128 are not optional. A DONE callback must include the required close,
evidence, Socraticode, file-reservation, DID/DIDNT/GAPS, compliance, and numeric
fields. Worker dispatches use `/flywheel:dispatch` so the dispatch ledger exists
before work starts.

Pane-state truth comes from:

- `ntm health <session>` for state truth
- `ntm copy <session>:<pane> -l <N>` for scrollback
- `ntm grep <session> <pattern>` for content search
- `ntm save <session>:<pane> <path>` for persistence

## DCG Discipline

Destructive Command Guard is part of the control plane. Keep commands and docs
DCG-clean:

- stage and commit with explicit paths
- use explicit-path delete patterns when removing files
- avoid force-style flags unless the task explicitly owns the destructive path
- keep risky shell snippets out of prose when a safer paraphrase works
- do not print secrets, token fragments, raw env output, or Agent Mail tokens

If DCG blocks a command, change the command shape. Do not retry the same blocked
shape.

## Commits

Use Conventional Commits with the bead id in the subject or body when the change
belongs to a bead:

```text
docs(repo): polish flywheel public surfaces [flywheel-wyxzx]
```

Commit only owned paths. In a dirty tree, review `git status --short` and stage
the exact files for this task. Do not sweep unrelated worker changes into your
commit.

## Validation

Run the narrowest command that proves the acceptance gates. Prefer shell tests
under `tests/` for substrate changes and JSON validation for receipts. If a test
cannot run, say why in the callback and leave the evidence path.
