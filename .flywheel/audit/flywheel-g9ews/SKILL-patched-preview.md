---
name: beads-br
description: "Beads Rust issue tracker (br) for agent task graphs. Triggers: 'br create', 'br ready', 'br close', 'br update', 'br dep add', 'br dep cycles', 'br sync', 'br doctor', 'br list', 'br show', 'br skills sync-status', 'JSONL issue export', 'beads workflow', 'tracking tasks', 'managing dependencies', 'finding ready work'. NEVER run bare bv (TUI blocks); sync is EXPLICIT via --flush-only or --import-only; git is YOUR responsibility."
---

<!-- TOC: Critical Rules | THE EXACT PROMPT | Quick Workflow | Essential Commands | bv Integration | Anti-Patterns | References -->

# beads-br — Beads Rust Issue Tracker

> **Non-invasive:** br NEVER runs git commands. Sync and commit are YOUR responsibility.

## Critical Rules for Agents

| Rule | Why |
|------|-----|
| **ALWAYS use `--json`** | Structured output for parsing |
| **NEVER run bare `bv`** | Blocks session in TUI mode |
| **Sync is EXPLICIT** | `br sync --flush-only` after changes |
| **Git is YOUR job** | br only touches `.beads/` directory |
| **No cycles allowed** | `br dep cycles` must return empty |

## THE EXACT PROMPT

When starting work on a bead, paste this verbatim into the worker's session prompt to invoke the canonical br lifecycle:

```
You are working on bead <id>. Your contract:

1. Confirm context: br show <id> --json && br dep tree <id>
2. Claim: br update <id> --status in_progress
3. Do the work named in the bead body. Edit only files named in scope.
4. Validate: run the bead's verification command.
5. Close BEFORE callback: br close <id> --reason "<one-line summary>"
6. Sync: br sync --flush-only && git add .beads/ && git commit
7. Send DONE callback per dispatch contract.

Hard rules:
- ALWAYS use --json for any br query you parse.
- NEVER run bare bv — it launches an interactive TUI and blocks.
- Sync is EXPLICIT — never automatic. Use --flush-only (DB → JSONL) before commit; --import-only (JSONL → DB) after pull.
- No cycles. After any br dep add, run br dep cycles (must be empty).
- Git is YOUR responsibility. br only writes .beads/.
```

## Quick Workflow

```bash
# 1. Find work
br ready --json

# NOTE (br 0.1.8): `br ready` is currently broken in some workspaces due to an
# internal SQL bug. Workaround: use `bv --recipe actionable --robot-plan` (or
# `bv --robot-triage`) + `br list --json`.

# 2. Claim it
br update <id> --status in_progress

# 3. Do work...

# 4. Complete
br close <id> --reason "Implemented X"

# 5. Sync to git (EXPLICIT!)
br sync --flush-only
git add .beads/ && git commit -m "feat: X (<id>)"
```

## Essential Commands

```bash
# Lifecycle
br init                              # Initialize .beads/
br create "Title" -p 1 -t task       # Create (priority 0-4)
br update <id> --status in_progress  # Claim work
br close <id> --reason "Done"        # Complete
br reopen <id>                       # Reopen if needed

# Querying (always use --json for agents)
br ready --json                      # Actionable work (not blocked)
br list --json                       # All issues
br blocked --json                    # What's blocked
br search "keyword"                  # Full-text search
br show <id> --json                  # Issue details

# Dependencies
br dep add <child> <parent>          # child depends on parent
br dep cycles                        # MUST be empty!
br dep tree <id>                     # Visualize dependencies

# Sync (EXPLICIT - never automatic)
br sync --flush-only                 # DB → JSONL (before git commit)
br sync --import-only                # JSONL → DB (after git pull)

# Skills sync status (canonical vs global skills)
br skills sync-status --json         # JSON summary of drift
br skills sync-status --verbose      # Per-skill details

# System
br doctor                            # Health check
br config list                       # Show configuration
```

## Priority Scale

| Priority | Meaning |
|----------|---------|
| 0 | Critical |
| 1 | High |
| 2 | Medium (default) |
| 3 | Low |
| 4 | Backlog |

## bv Integration

**CRITICAL:** Never run bare `bv` — it launches interactive TUI and blocks.

```bash
# Always use --robot-* flags:
bv --robot-next                      # Single top pick
bv --robot-triage                    # Full triage
bv --robot-plan                      # Parallel execution tracks
bv --robot-insights | jq '.Cycles'   # Check graph health
```

## Agent Mail Coordination

Use bead ID as thread_id for multi-agent coordination:

```python
file_reservation_paths(..., reason="br-123")
send_message(..., thread_id="br-123", subject="[br-123] Starting...")
# Work...
br close br-123 --reason "Completed"
release_file_reservations(...)
```

## Session Ending Pattern

```bash
git pull --rebase
br sync --flush-only
git add .beads/ && git commit -m "Update issues"
git push
git status  # Verify clean
```

## Anti-Patterns

| Anti-Pattern | Why it fails | Fix |
|---|---|---|
| Running `br sync` without `--flush-only` or `--import-only` | Ambiguous direction can corrupt sync state between DB and JSONL | Always specify direction: `--flush-only` (DB → JSONL) or `--import-only` (JSONL → DB) |
| Forgetting `br sync --flush-only` before `git commit` | DB and JSONL drift; commits show no `.beads/` changes despite real work | Run `br sync --flush-only && git add .beads/` as a unit before every commit |
| Creating circular dependencies | `br dep cycles` non-empty breaks `br ready`/`br blocked` semantics | Always run `br dep cycles` after `br dep add`; halt and unwind if non-empty |
| Running bare `bv` | Launches interactive TUI and blocks the session indefinitely | Use `bv --robot-next`, `bv --robot-triage`, `bv --robot-plan`, or `bv --robot-insights` exclusively |
| Assuming auto-commit behavior | br is non-invasive by design — no git commands run automatically | Manual `git add .beads/ && git commit` after `br sync --flush-only` is YOUR responsibility |

## Storage

```
.beads/
├── beads.db        # SQLite (primary)
├── issues.jsonl    # Git-friendly export
└── config.yaml     # Optional config
```

## Troubleshooting

```bash
br doctor                    # Full diagnostics
br dep cycles                # Must be empty
br config list               # Check settings
```

**Worktree error** (`'main' is already checked out`):
```bash
git branch beads-sync main
br config set sync-branch beads-sync
```

---

## References

| Topic | File |
|-------|------|
| Full command reference | [COMMANDS.md](references/COMMANDS.md) |
| Configuration details | [CONFIG.md](references/CONFIG.md) |
| Troubleshooting guide | [TROUBLESHOOTING.md](references/TROUBLESHOOTING.md) |
| Multi-agent patterns | [INTEGRATION.md](references/INTEGRATION.md) |
