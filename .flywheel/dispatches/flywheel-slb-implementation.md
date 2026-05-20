# flywheel-slb-impl — Implement /slb (Safety Layer Block) for dangerous commands — replace "ask Joshua per prompt" with safe-execution-by-default

## Context

Joshua-direct 2026-05-20T07:42Z: "we need to implement /slb for dangerous commands instead of everything relying on me". This is the structural alternative to the current DCG-prompts-Joshua pattern that has been the dominant friction class today (Joshua approved git branch -D, gh api DELETE, rm -rf $TMPDIR, etc. many times).

Per memory + CLAUDE.md axiom 6: "Safety Defense-in-Depth — DCG + SLB + UBS". DCG = Dangerous Command Guard (current pattern-matching gate). SLB = Safety Layer Block (this bead — execute-safely-by-default for known patterns). UBS = Universal Backup Strategy (already in arsenal, ships via skill).

Pattern: when DCG flags a command as dangerous, route through SLB FIRST. If SLB has a safe-execution recipe for that command class, SLB executes it with snapshot + verify + audit-log. Joshua-prompt fallback ONLY when SLB has no recipe AND scope can't be pinned to a known-safe pattern.

## Design

### Architecture

```
PreToolUse Bash → DCG pattern match → flagged?
                                       ├─ no → pass through
                                       └─ yes → SLB lookup
                                                ├─ recipe match → execute via SLB (snapshot + verify + audit)
                                                └─ no recipe match → fall through to existing DCG prompt
```

SLB sits BETWEEN DCG and the human prompt. It's the "machine can decide safely" layer.

### Recipe schema

`~/.flywheel/slb-recipes.json`:

```json
{
  "schema_version": "flywheel.slb.recipes.v1",
  "recipes": [
    {
      "id": "git-branch-delete-with-sha-suffix",
      "command_pattern": "^git branch -D (deploy|feat|fix|wip|chore|test|review)/[a-z0-9-]+-[a-f0-9]{7,40}$",
      "safe_execution_protocol": {
        "pre_snapshot": "git rev-parse <branch>",
        "execute": "git branch -D <branch>",
        "post_verify": "git reflog show <branch> 2>/dev/null || echo recoverable_via_reflog",
        "audit_log_required": true
      },
      "fallback_to_prompt_if": ["pre_snapshot_fails", "execute_returns_nonzero_and_branch_was_not_merged"]
    },
    {
      "id": "rm-rf-tmpdir",
      "command_pattern": "^rm -rf \\$TMPDIR/.+",
      "safe_execution_protocol": {
        "pre_snapshot": "du -sk <target> 2>/dev/null",
        "execute": "rm -rf <target>",
        "post_verify": "test ! -e <target>",
        "audit_log_required": true
      },
      "fallback_to_prompt_if": ["target_resolves_outside_TMPDIR"]
    },
    {
      "id": "gh-api-delete-branch-protection",
      "command_pattern": "^gh api -X DELETE [\"']?repos/[^/]+/[^/]+/branches/[^/]+/protection[\"']?$",
      "safe_execution_protocol": {
        "pre_snapshot": "gh api repos/<owner>/<repo>/branches/<branch>/protection > .flywheel/audits/slb-snapshots/branch-protection-pre-<ts>.json",
        "execute": "gh api -X DELETE repos/<owner>/<repo>/branches/<branch>/protection",
        "post_verify": "gh api repos/<owner>/<repo>/branches/<branch>/protection 2>&1 | grep -q 'Branch not protected'",
        "audit_log_required": true
      },
      "fallback_to_prompt_if": ["pre_snapshot_fails", "post_verify_fails"]
    }
  ]
}
```

### Deliverables

#### A. ~/.claude/hooks/PreToolUse-bash-slb.sh
Wraps existing DCG hook chain:
1. Read tool_input.command
2. Probe ~/.flywheel/slb-recipes.json for matching recipe
3. If matched: run safe_execution_protocol (pre_snapshot → execute → post_verify → audit_log)
4. If snapshot/verify fails OR fallback_to_prompt_if triggers: skip SLB, fall through to existing DCG (which will prompt Joshua)
5. If matched + verified: PASS the command without prompting

#### B. ~/.flywheel/slb-recipes.json
Initial recipe set covering the patterns hit today:
- git-branch-delete-with-sha-suffix
- git-worktree-remove-tmp
- rm-rf-tmpdir
- rm-rf-stale-mktemp-dirs
- gh-api-delete-branch-protection
- git-stash-drop-older-than-30d
- git-reset-hard-to-origin (with own-branch scope check)
- find-delete-stale-temp

#### C. .flywheel/scripts/slb-recipe-add.sh
Helper to add new recipes to the registry. Idempotent. Validates JSON schema. Per recipe, requires pre_snapshot + execute + post_verify + fallback conditions specified.

#### D. .flywheel/scripts/slb-execution-audit-tail.sh
Probe `~/.local/state/flywheel/slb-execution-audit.jsonl` for recent SLB-executed commands. Useful for orch dashboards + retrospectives.

#### E. .flywheel/doctrine/slb-discipline.md
Document the design philosophy:
- DCG identifies dangerous (pattern match)
- SLB executes safely (snapshot + verify + audit)
- UBS recovers from broken state (separate skill, already in arsenal)
- Joshua-prompt is the ESCAPE HATCH for novel patterns, not the default for known patterns
- Pre-auth scopes (flywheel-8iook) are the recipe-COVERAGE layer; SLB is the recipe-EXECUTION layer

Cross-link to existing memory:
- feedback_data_decides_orch_gates_not_vibes (today's directive)
- feedback_auto_push_blocked_worker_abandonment (sister class)
- feedback_dcg_prose_trigger_strip_dangerous_substrings (related DCG class)

#### F. tests/slb-smoke.sh
- 10+ assertions:
  1. Recipe match + snapshot pass + execute pass + verify pass → SLB executes, no prompt
  2. Recipe match + snapshot fail → falls through to DCG prompt
  3. Recipe match + verify fail → audit logs failure, falls through to DCG
  4. No recipe match → falls through to DCG prompt (back-compat)
  5. Audit row written for every SLB execution (success + failure)
  6. Pre-snapshot artifacts saved per recipe schema
  7. Idempotent re-run produces no double-audit-rows
  8. Recipe added via slb-recipe-add.sh validates + writes correctly
  9. Schema validation rejects malformed recipes
  10. JSON envelope output parseable

## Acceptance

- 4 scripts + 1 recipes config + 1 doctrine + smoke ship
- shellcheck PASS on bash
- Smoke 10+ assertions PASS
- Initial recipes config seeded with 8 patterns from today's observed Joshua-friction
- Hook installed at ~/.claude/hooks/PreToolUse-bash-slb.sh (does NOT replace existing DCG hook — pre-empts it for known patterns)
- Audit ledger at ~/.local/state/flywheel/slb-execution-audit.jsonl initialized
- Bead flywheel-slb-impl closed

## Out of scope

- UBS (Universal Backup Strategy) implementation — separate skill, not this bead
- Modifying existing DCG hook — SLB pre-empts; DCG remains fallback
- Adding recipes that bypass legitimate security concerns (e.g., NEVER auto-execute `git push --force` to main, NEVER auto-execute `gh api -X DELETE` on a repo itself)

## Loop contract

- Track 3 only
- mcp-agent-mail file_reservation_paths before edits
- socraticode K>=10 with 2 phrasings on existing ~/.claude/hooks/*.sh patterns + DCG rule registry + 8iook pre-auth scopes config
- Bridge daemon LIVE
- SCR event: C6_trauma_outflow (kills the Joshua-keystroke-per-prompt class)
- STOP on Track 1/2 breach, BLOCKED, >3h hard cap

## FIRST ACTION

1. br show this bead.
2. Read ~/.claude/hooks/pretooluse-bash-cross-repo-guard.sh + dcg-related hooks for patterns.
3. Read ~/.flywheel/dcg-pre-authorized-scopes.json (8iook config) for recipe-shape inspiration.
4. Read .flywheel/doctrine/auto-push-blocked-worker-discipline.md for the sister class.
5. ACK row.
6. Implement 4 scripts + recipes + doctrine + smoke.
7. Self-validate.
8. Commit + close bead + DIRECT pane-1 ntm send.
