# DCG Worker Freeze Discipline

Trauma class: `worker-freeze-on-dcg`

DCG is a checkpoint, not a stop sign. A worker that hits a destructive-command prompt must keep the work moving through one of three bounded paths:

1. If the command matches `~/.flywheel/dcg-pre-authorized-scopes.json`, route it through `~/.claude/hooks/pretooluse-bash-dcg-with-pre-auth.sh` and let the wrapper audit the auto-approval.
2. If the command is safe but not covered, propose the narrowest new scope with a rationale, expected regex, and whether it needs `with_orch_attestation`; do not hand-run a bypass.
3. If the command is genuinely outside policy, switch to a non-destructive alternative or callback with the exact command, reason DCG blocked it, and the next safe action.

Workers must not abandon a task, idle indefinitely, or ask Joshua to clear a prompt while safe local work remains. The existing `dcg` hook remains authoritative for anything not explicitly pre-authorized.

Cross-references:

- `feedback_auto_push_blocked_worker_abandonment.md`
- `feedback_codex_goal_mode_runtime_enforcement.md`
