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
