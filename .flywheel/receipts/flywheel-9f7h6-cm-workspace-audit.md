# flywheel-9f7h6 CM Workspace Scoping Audit

Date: 2026-05-08
Worker: flywheel pane 4 codex
Source: Jeff ntm#132, commit `cb0a98de`

## Summary

Adopted the ntm#132 rule locally: CASS procedural-memory calls must pass an
explicit absolute workspace, and cross-project state must not rely on basename
keys when the row identifies a workspace.

## Socraticode

Required K=10 searches ran against `/Users/josh/Developer/flywheel`:

1. `cm get-context call sites workspace scoping CASS memory`
2. `cass skill cm wrapper workspace argument absolute path`
3. `basename project key collision project_path state JSONL`
4. `workspace scoping realpath pwd -P canonical project path`
5. `local state flywheel project_path project basename substrate`

Indexed chunks observed: 50.

## CM Callsites

Gate command:

```bash
rg -n 'cm\s+(get-context|context|recall)' /Users/josh/.claude/skills .flywheel/scripts tests | grep -v -- '--workspace'
```

Result after edits: zero hits.

Fixed callsites: 8 command/example lines:

- `/Users/josh/.claude/skills/cass-memory/SKILL.md`
- `/Users/josh/.claude/skills/cass-memory/references/ONBOARDING.md`
- `/Users/josh/.claude/skills/cass-memory/references/COMMANDS.md`
- `/Users/josh/.claude/skills/cass-memory/references/ARCHITECTURE.md`
- `/Users/josh/.claude/skills/cass-memory/references/MCP-SERVER.md`
- `/Users/josh/.claude/skills/worker-orchestration/SKILL.md`

Every executable `cm context` example now uses `--workspace "$(pwd -P)"` or
documents the required `--workspace <abs-path>` shape.

## CASS Skill Audit

`cass/SKILL.md` already used exact absolute `--workspace` examples for search.
Added a dated audit note to preserve physical path scoping and reject
basename-derived memory/cache keys.

`cass-memory/SKILL.md` was the direct risk surface. Its Quick Start, session
start prompt, command table, agent protocol, and references now require an
explicit workspace for `cm context`.

No breaking CASS behavior was changed.

## Local State Scan

Command required by dispatch was run:

```bash
ls ~/.local/state/flywheel/*.jsonl ~/.local/state/flywheel/*.json | xargs -I{} sh -c 'echo "=== {} ==="; head -3 "{}"' 2>&1 | head -50
```

Additional scan:

```bash
rg -n '"project"\s*:\s*"[^/"]+"' /Users/josh/.local/state/flywheel/*.jsonl /Users/josh/.local/state/flywheel/*.json
```

Findings:

- Basename-shaped `project` hits: 2,124.
- Files with basename-shaped project fields: 4.
- `loop-driver-runs.jsonl` dominates the count and uses labels such as
  `project:"flywheel"` alongside absolute loop/plist paths.
- `secret-leak-ledger.jsonl` has `project:"mobile-eats-dev"`, which appears to
  name an external service/project rather than a workspace.
- `gap-hunt.jsonl` and `cross-orch-coordination.jsonl` contain smaller
  basename-style project fields in historical rows.
- Current roster/topology state already carries absolute `repo_path` rows:
  `team-roster.jsonl` and `session-topology.jsonl`.

Risk judgment: the active CASS/CM regression is closed. The basename rows in
local flywheel state are mostly historical or display labels, but L136 now
defines the migration rule: rows that identify workspaces use `repo_path` or
`project_path`, not basename-only `project`.

Follow-up beads filed: 0. No immediate code mutation is required for this bead;
future substrate work should migrate basename workspace identifiers as it
touches each ledger.

## Doctrine

Added L136 to `.flywheel/AGENTS-CANONICAL.md`: absolute path keying for
cross-project state and `--workspace <abs-path>` for all `cm` calls.

## Skill Discovery

Emitted `sd-5ded1b9081be1939` for the reusable
`absolute-path-state-keying` pattern.
