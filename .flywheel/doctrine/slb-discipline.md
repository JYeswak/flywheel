# SLB Discipline

SLB is the execution layer between DCG and Joshua. DCG identifies commands that
deserve friction. SLB decides whether a known dangerous shape can be executed
with machine-verifiable safety: pre-snapshot, bounded execution, post-verify,
and audit.

The order is:

1. PreToolUse Bash hook receives a command.
2. DCG-class danger is routed to SLB first.
3. SLB looks up `~/.flywheel/slb-recipes.json`.
4. A recipe match runs `pre_snapshot`, `execute`, and `post_verify`.
5. SLB writes `~/.local/state/flywheel/slb-execution-audit.jsonl`.
6. On success, the hook replaces the original Bash command with a no-op so the
   dangerous command is not run twice.
7. On missing recipe, failed snapshot, failed verify, or failed scope check, the
   hook falls through to DCG. Joshua-prompt remains the escape hatch for novel
   patterns, not the default for known patterns.

DCG, SLB, and UBS are separate layers:

- DCG: pattern-match dangerous commands.
- SLB: execute known dangerous commands safely by recipe.
- UBS: recover from bad state when a safety layer still fails.

Pre-authorized scopes from flywheel-8iook are recipe coverage. They say which
classes are eligible to stop asking Joshua. SLB is recipe execution. It proves
the operation through artifacts and a ledger row.

Initial recipes cover the current friction set:

- `git-branch-delete-with-sha-suffix`
- `git-worktree-remove-tmp`
- `rm-rf-tmpdir`
- `rm-rf-stale-mktemp-dirs`
- `gh-api-delete-branch-protection`
- `git-stash-drop-older-than-30d`
- `git-reset-hard-to-origin`
- `find-delete-stale-temp`

The recipe bar is intentionally high. Every recipe must declare a command regex,
`pre_snapshot`, `execute`, `post_verify`, and fallback conditions. Recipes that
cannot prove target scope or recovery evidence must fall through to DCG.

Related memory anchors:

- `feedback_data_decides_orch_gates_not_vibes`
- `feedback_auto_push_blocked_worker_abandonment`
- `feedback_dcg_prose_trigger_strip_dangerous_substrings`
