# flywheel-8iook — DCG pre-authorized-scopes + worker-side bypass protocol

## Context

Joshua-direct 2026-05-20T02:55Z (screenshot of clutterfreespaces blocked on `git branch -D deploy/ux-fix-b9b3ec03` after worktree-remove): workers freeze on DCG confirmation prompts for legitimate cleanup ops, turning Joshua into human-in-the-loop on every command. Observed N times today across multiple sessions:

- DCG blocked rm of $TMPDIR/tmp.* (cleanup)
- DCG blocked gh api DELETE branches/protection (revert)
- DCG blocked git branch -D deploy/<sha> (cleanup after worktree-remove)
- DCG matched literal text in bead descriptions as if it were executable commands

Workers see the modal prompt, can't proceed, freeze. Joshua becomes the only path forward. Anti-flywheel.

## Deliverables

### A. ~/.flywheel/dcg-pre-authorized-scopes.json
Schema:
```json
{
  "schema_version": "dcg_pre_authorized_scopes.v1",
  "scopes": [
    {
      "id": "git-worktree-remove-tmp",
      "command_pattern": "^git worktree remove /(?:tmp|var/folders/.+/T)/.+",
      "rationale": "tmp worktrees are by-definition disposable",
      "auto_approve": "always",
      "audit_log": true
    },
    {
      "id": "git-branch-delete-with-sha-suffix",
      "command_pattern": "^git branch -D (deploy|feat|fix|wip|chore|test|review)/[a-z0-9-]+-[a-f0-9]{7,40}$",
      "rationale": "short-lived branch with sha suffix; recoverable via reflog",
      "auto_approve": "always",
      "requires_context": "worktree_remove_in_recent_steps OR pr_merged_recently",
      "audit_log": true
    },
    {
      "id": "gh-api-delete-branch-protection",
      "command_pattern": "^gh api -X DELETE [\"']?repos/[^/]+/[^/]+/branches/[^/]+/protection[\"']?$",
      "rationale": "branch protection is reversible config metadata, not data",
      "auto_approve": "with_orch_attestation",
      "audit_log": true
    },
    {
      "id": "rm-rf-tmpdir-and-stale",
      "command_pattern": "^(?:rm -rf|find .+ -delete) \\$TMPDIR/.+",
      "rationale": "TMPDIR is by-definition disposable; ensure rm -rf rule already allows TMPDIR per core.filesystem rule",
      "auto_approve": "always",
      "audit_log": true
    }
  ]
}
```

### B. ~/.claude/hooks/pretooluse-bash-dcg-with-pre-auth.sh
Wraps the existing DCG check:
1. Receive command
2. Read pre-authorized-scopes.json
3. For each scope: if command matches pattern AND (auto_approve=always OR requires_context satisfied OR has orch_attestation):
   - emit audit ledger row at `~/.local/state/flywheel/dcg-pre-auth-audit.jsonl`
   - PASS the command without prompting
4. Else fall through to existing DCG prompt

Audit ledger schema:
```json
{
  "schema_version": "dcg_pre_auth_audit.v1",
  "ts": "...",
  "scope_id": "git-branch-delete-with-sha-suffix",
  "command_summary": "git branch -D deploy/ux-fix-b9b3ec03",
  "rationale": "...",
  "context_satisfied": "...",
  "outcome": "auto_approved|fall_through"
}
```

### C. .flywheel/doctrine/dcg-worker-freeze-discipline.md
Document the trauma class. Worker protocol when hitting DCG block:
1. CHECK pre-authorized-scopes.json — if match, request auto-approve via wrapped hook
2. If no match, ESCALATE via callback with rationale + proposed-action — NEVER freeze
3. NEVER abandon: same class as auto-push-blocked-abandonment

### D. .flywheel/scripts/dcg-pre-auth-add-scope.sh
Helper for orchs/workers to add new scopes to the config:
```
dcg-pre-auth-add-scope.sh --pattern '^X' --rationale 'Y' --auto-approve always --apply
```
Idempotent. Validates JSON. Updates ~/.flywheel/dcg-pre-authorized-scopes.json.

### E. tests/dcg-pre-auth-smoke.sh
- 8+ assertions:
  1. Empty scopes file → all commands fall through
  2. Matching scope + auto_approve=always → PASS without prompt
  3. Matching scope + requires_context unsatisfied → fall through
  4. Non-matching command → fall through
  5. Audit row written on every auto-approve
  6. Invalid JSON in scopes file → fall through (safe default)
  7. Idempotent add-scope.sh apply
  8. Schema validation rejects malformed entries

## Acceptance

- 4 artifacts + smoke ship
- shellcheck PASS
- Smoke 8+ assertions PASS
- Hook installed locally at ~/.claude/hooks/pretooluse-bash-dcg-with-pre-auth.sh (does NOT replace existing DCG hook — wraps it; existing hook unchanged)
- Initial scopes config seeded with the 4 patterns from Deliverable A
- Doctrine doc covers worker-freeze trauma class with cross-refs to:
  - feedback_auto_push_blocked_worker_abandonment.md
  - feedback_codex_goal_mode_runtime_enforcement.md
- Bead flywheel-8iook closed

## Loop contract

- Track 3 only
- mcp-agent-mail file_reservation_paths before edits
- socraticode K>=10 with 2 phrasings on existing claude PreToolUse hooks + DCG rule patterns + ~/.claude/hooks/ structure
- Bridge daemon LIVE
- SCR event: C6_trauma_outflow (worker-freeze-on-DCG class)
- STOP on Track 1/2 breach, BLOCKED, >3h hard cap
- DEEP-WORK validate: shellcheck + smoke + 2 manual DCG-trigger-class tests (one auto-approve hit, one fall-through)
- DO NOT modify the existing DCG hooks — only wrap them. Existing safety contract preserved.
- DO NOT add scopes that bypass legitimate security concerns (e.g., NEVER auto-approve push --force, NEVER auto-approve gh api DELETE on a repo itself)

## FIRST ACTION

1. br show flywheel-8iook.
2. socraticode existing ~/.claude/hooks/*.sh patterns + DCG rule registry.
3. Read .flywheel/doctrine/auto-push-blocked-worker-discipline.md as pattern reference.
4. ACK row.
5. Implement 4 artifacts + smoke.
6. Self-validate.
7. Commit + close bead + DIRECT pane-1 ntm send.
