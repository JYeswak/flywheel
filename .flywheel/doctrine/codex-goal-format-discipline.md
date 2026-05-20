# Codex Goal-Format Discipline

Every Codex-pane dispatch sent through `ntm send --pane=N --file=FILE` must use
a dispatch packet whose first line starts with `/goal `.

The worker kind is not inferred from command text. It is read from the latest
row for the target session in:

`~/.local/state/flywheel/session-topology.jsonl`

Specifically, the enforcement hook reads `.worker_kinds["N"]`. Non-Codex panes
are allowed without `/goal`; Codex panes are fail-closed when the topology row,
pane kind, or dispatch file cannot be read.

## Hook

The live hook path is:

`~/.claude/hooks/PreToolUse-codex-goal-format-enforcement.sh`

The installed hook is a symlink to:

`~/.claude/skills/codex-goal-format-enforcement/scripts/hook.sh`

Install or remove it with:

```bash
.flywheel/scripts/install-goal-format-hook.sh --json
.flywheel/scripts/install-goal-format-hook.sh --uninstall --json
```

## Override

Exceptional non-goal Codex dispatches require:

```bash
CODEX_GOAL_FORMAT_BYPASS=<reason>
```

The hook writes a structured audit row to:

`.flywheel/runtime/goal-format-override-ledger.jsonl`

The override is not silent. Rows include timestamp, session, pane, file, reason,
invoker, worker kind, and topology path.
