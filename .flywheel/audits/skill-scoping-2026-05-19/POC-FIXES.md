# POC Skill Scoping Fix Proposals

Scope: read-only proposals. No files under `/Users/josh/.claude/skills` were edited.

Top-five source: highest-traffic skills classified BROAD in `CLASSIFIED.jsonl`.

## `flywheel`

- Current class: BROAD
- Traffic score: 922 (outcomes=922, loads=0)
- Decision: SCOPE-IN-PLACE proposal only

Before frontmatter:
```yaml
---
name: flywheel
description: >-
  Internal placeholder. This skill is intentionally withheld from distribution.
---
```
Proposed frontmatter:
```yaml
---
name: flywheel
description: >-
  Use only for Flywheel repo substrate operations. Triggers: flywheel loop, flywheel dispatch, substrate compounding, pane callback bridge, doctrine sync, fleet conformance.
triggers:
  - flywheel loop
  - flywheel dispatch
  - substrate compounding
  - pane callback bridge
  - doctrine sync
  - fleet conformance
applies_to:
  - /Users/josh/Developer/flywheel/**
  - /Users/josh/.claude/skills/.flywheel/**
---
```

## `goal-build`

- Current class: BROAD
- Traffic score: 61 (outcomes=61, loads=0)
- Decision: SCOPE-IN-PLACE proposal only

Before frontmatter:
```yaml
---
name: goal-build
description: Walk operator through a 6-section outcome-shaped goal template modeled on the canonical SkillOS goal Joshua authored 2026-05-14. Replaces the deprecated 10-dim rubric / residue-ledger / wave-matrix scaffolding that produced 5 failed substrate-state-machine goals.
---
```

Proposed frontmatter:
```yaml
---
name: goal-build
description: >-
  Use when drafting or repairing outcome-shaped GOAL.md contracts. Triggers: goal build, goal template, outcome-shaped goal, mission anchor, canonical gates, plain English version.
triggers:
  - goal build
  - GOAL.md rewrite
  - outcome-shaped goal
  - mission anchor
  - canonical gates
  - plain English version
applies_to:
  - '**/GOAL.md'
  - '**/.flywheel/GOAL.md'
  - '**/.flywheel/goals/**'
---
```

## `safe-migrations`

- Current class: BROAD
- Traffic score: 9 (outcomes=9, loads=0)
- Decision: SCOPE-IN-PLACE proposal only

Before frontmatter:
```yaml
---
name: safe-migrations
description: Activate when creating database schema changes, data migrations, or Snowflake DDL operations - zero-downtime patterns, rollback planning, data validation, backwards compatibility
allowed-tools: [Read, Write, Edit, Bash, mcp__snowflake__*]
---
```

Proposed frontmatter:
```yaml
---
name: safe-migrations
description: >-
  Use when creating database schema changes, data migrations, or Snowflake DDL. Triggers: migration, schema change, DDL, ALTER TABLE, backfill, rollback plan.
allowed-tools: [Read, Write, Edit, Bash, mcp__snowflake__*]
triggers:
  - database migration
  - schema change
  - Snowflake DDL
  - ALTER TABLE
  - data backfill
  - rollback plan
applies_to:
  - '**/migrations/**'
  - '**/schema/**'
  - '**/*.sql'
  - '**/db/**'
  - '**/supabase/**'
---
```

## `codex-cli-tracker`

- Current class: BROAD
- Traffic score: 4 (outcomes=4, loads=0)
- Decision: SCOPE-IN-PLACE proposal only

Before frontmatter:
```yaml
---
name: codex-cli-tracker
description: Track OpenAI Codex CLI upstream issues, pinned-version constraints, and local recovery patterns for Joshua's Codex panes.
---
```

Proposed frontmatter:
```yaml
---
name: codex-cli-tracker
description: >-
  Use when tracking OpenAI Codex CLI upstream issues, pinned-version constraints, and local recovery patterns. Triggers: codex freeze, codex upgrade, codex pinned version, openai/codex issue, Codex pane recovery.
triggers:
  - codex freeze
  - codex upgrade
  - codex pinned version
  - openai/codex issue
  - Codex pane recovery
applies_to:
  - /Users/josh/Developer/flywheel/.flywheel/scripts/codex-*
  - /Users/josh/.local/state/flywheel/codex-watchtower/**
  - /Users/josh/.codex/**
---
```

## `living-documentation`

- Current class: BROAD
- Traffic score: 3 (outcomes=3, loads=0)
- Decision: SCOPE-IN-PLACE proposal only

Before frontmatter:
```yaml
---
name: living-documentation
description: Activate after completing features, before marking tasks done - update README, API docs, changelog entries, inline comments for complex logic, architecture decisions
allowed-tools: [Read, Write, Edit, Grep, Glob]
---
```

Proposed frontmatter:
```yaml
---
name: living-documentation
description: >-
  Use after feature or API changes that require docs updates. Triggers: README update, API docs, changelog, ADR, documentation gate, docs drift.
allowed-tools: [Read, Write, Edit, Grep, Glob]
triggers:
  - README update
  - API documentation
  - changelog entry
  - architecture decision record
  - documentation gate
  - docs drift
applies_to:
  - '**/README.md'
  - '**/CHANGELOG.md'
  - '**/docs/**'
  - '**/adr/**'
  - '**/ARCHITECTURE.md'
---
```
