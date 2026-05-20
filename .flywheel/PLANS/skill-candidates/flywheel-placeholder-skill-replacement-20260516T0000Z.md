# Skill Candidate: replace placeholder Flywheel skill

created: 2026-05-16T00:00:00Z
source_cycle: goal-mode-worker-test cycle 600
candidate_owner: SkillOS / JSM lane
status: proposed

## Trigger

The active watch cycle loaded `/Users/josh/.claude/skills/flywheel/SKILL.md`
because the current work is explicitly Flywheel-domain work. The skill body is
only:

```text
Internal placeholder. This skill is intentionally withheld from distribution.
```

Joshua also flagged the product question directly: if the Flywheel skill is a
placeholder, perhaps it should change.

## Gap

Flywheel has many canonical repo-local surfaces, but the user-facing skill
named `flywheel` does not teach an agent how to select among them. That makes
agents fall back to memory, scattered AGENTS.md doctrine, or ad hoc shell
probing for routine Flywheel work.

The placeholder particularly fails these recurring tasks:

- choose `flywheel-loop doctor`, `tick`, `init`, `cron`, `adopt`, or
  repo-local scripts by intent;
- distinguish direct Joshua sessions from NTM worker dispatches;
- emit structured closeout receipts instead of prose-only handoffs;
- route skill creation and JSM-managed updates through SkillOS instead of
  editing managed skills directly;
- avoid using the global Flywheel repo state as a substitute for repo-local
  `.flywheel/MISSION.md`, `.flywheel/GOAL.md`, and `.flywheel/STATE.md`.

## Proposed Minimal Skill Body

Create a distributable `flywheel` skill that is an operator router, not a full
doctrine dump:

1. Start with repo-local state:
   `flywheel-loop doctor --repo "$PWD" --json`.
2. For loop work, dry-run first:
   `flywheel-loop tick --repo "$PWD" --dry-run --json`.
3. For adoption, use:
   `.flywheel/scripts/flywheel-adopt.sh --repo "$PWD" --dry-run --json`
   before any apply.
4. For cron, use the Flywheel script surfaces and record labels, owner,
   command, interval, and max runtime.
5. For NTM worker dispatches, follow the dispatch packet first; do not run
   session-start orientation as if working directly with Joshua.
6. For skill changes, file a SkillOS/JSM handoff or `jsm push` path instead of
   editing managed skill files in place.
7. Close non-trivial loop work with `.flywheel/last_closeout_receipt.json` and
   validate it with `flywheel-loop validate-receipt`.

## Reuse Value

This candidate is reusable because it turns a high-frequency placeholder skill
into a stable routing surface for Flywheel operators without copying the entire
canonical doctrine into every prompt.

## Next Action

Route this candidate to SkillOS/JSM for implementation or explicit rejection.
Do not directly patch `/Users/josh/.claude/skills/flywheel/SKILL.md` from the
Flywheel repo without the managed-skill lane confirming ownership.
