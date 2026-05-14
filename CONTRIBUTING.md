# Contributing

Flywheel is early public infrastructure. Good contributions make the agentic
workflow loop easier to install, easier to inspect, or safer to adapt without
copying private operator state.

## Before Work

1. Read `README.md`, `CHARTER.md`, and `ARCHITECTURE.md`.
2. Pick or file a Bead for non-trivial work, then read it with `br show <id>`.
3. Survey the existing implementation before editing. Use Socraticode when it
   is available; otherwise use `rg`, tests, and nearby code.
4. Reserve owned paths through Agent Mail when working with other agents.
5. Keep reduced mode honest: if NTM, Agent Mail, Beads, or Socraticode are not
   installed, docs and code must say what still works instead of pretending the
   full substrate exists.

## Full-Substrate Operator Quickstart

This path is for maintainers running the full local substrate. It is not
required for the public first run in `README.md`.

For the coordinator:

```bash
$HOME/.local/bin/ntm health flywheel
~/.claude/skills/.flywheel/bin/flywheel-loop doctor --repo <flywheel-repo> --json
br ready --json
```

For a worker:

```bash
br show <bead-id>
~/.claude/skills/.flywheel/bin/flywheel-loop doctor --repo <flywheel-repo> --json
```

Then read the task packet, reserve owned paths, use Socraticode before edits,
ship with explicit path staging, and callback with the required fields below.
Receipts beat memory.

## New Worker Checklist

Before editing:

1. Run orientation:

   ```bash
   ~/.claude/skills/.flywheel/bin/flywheel-codex-orient
   ```

2. Survey existing substrate with Socraticode for any non-trivial change:

   ```text
   mcp__socraticode__codebase_search projectPath="<flywheel-repo>" query="<domain>" limit=10
   ```

3. Read the matching skill when the task names a domain, especially
   `canonical-cli-scoping`, `beads-workflow`, `agent-mail`, `dcg`, or
   `dicklesworthstone-stack`.

4. Reserve files through Agent Mail before editing:

   ```text
   project_key=<flywheel-repo>
   reserve only the files you will touch
   release on DONE or BLOCKED
   ```

5. Keep Beads repo-local. From this repo, `br where` must resolve to
   `<flywheel-repo>/.beads`.

6. Validate with the smallest relevant command before callback.

7. Callback through `ntm send`, using the callback pane from
   `~/.local/state/flywheel/session-topology.jsonl`.

## Worker Callback Fields

Worker callbacks are claims until validated. A non-trivial callback should
include:

- `task_id=<id>`;
- `status=done|blocked`;
- `bead=<id>` or `no_bead_reason=<reason>`;
- `files_reserved=<paths>` and `files_released=<paths>`;
- `socraticode_queries=<N>`;
- `validation=<command-or-receipt>`;
- `evidence=<path>`;
- `callback_delivery_verified=true`;
- `evidence_redacted=yes|no|n/a` for evidence-class paths.

If the callback reports `blocked`, include the exact blocker, the last command
or receipt that proves it, and the next safe local action.

## Developer Certificate Of Origin

This project uses the Developer Certificate of Origin instead of a contributor
license agreement. Every commit must include a DCO trailer:

```text
Signed-off-by: Your Name <you@example.com>
```

Use `git commit -s` to add it automatically. By signing off, you certify that
you have the right to submit the contribution under this repository's license.

## Beads Workflow

Use Beads for multi-file or behavior-changing work:

```bash
br ready --json
br show <id>
br update <id> --status in_progress
```

Do not edit `.beads/issues.jsonl` directly. `br` owns the task database and its
JSONL migration surface.

## Pull Requests

Keep pull requests small enough to review. Include:

- the Bead id or a short `no_bead_reason`;
- the mode affected: reduced, full, or both;
- validation commands and relevant receipt paths;
- any known follow-up that should remain open, including its TP row or Bead id.

Use Conventional Commits when practical:

```text
docs(repo): polish public contribution path [<bead-id>]
```

## Safety

Do not include secrets, token fragments, raw environment output, private pane
scrollback, client data, or local operator state. Prefer synthetic fixtures and
redacted evidence. Destructive changes must use explicit paths and a clear
rollback story.

## Validation

Run the narrowest command that proves the change. For public-surface changes,
also run:

```bash
bash tests/public-top-level-files.sh
```

If a validation command cannot run, say why and leave enough evidence for the
next contributor to reproduce the issue.
