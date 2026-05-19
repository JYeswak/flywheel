# MP-70 — Reviewed machine plan before apply

**Discovered:** 2026-05-19T06:53Z
**Discovered by:** skillos:2
**Skills exemplifying:** 5+

## Essence

Dangerous or bulk operations generate a machine-readable plan first, then a human or agent reviews that plan, and only then does the apply step mutate state.

## Where it applies

Process triage, bulk cleanup, CLI automation, database migrations, auth exchanges, debt cleanup, release preparation, and any operation where retrying or broad mutation can amplify damage.

## Adoption signal

The skill separates `plan` from `apply`, emits structured JSON for review, forbids apply without inspection, scopes mutation tightly, and treats unsafe retries as failures.

## Exemplar skills (≥5)

- `~/.claude/skills/process-triage/SKILL.md:51` — robot mode emits a structured JSON plan.
- `~/.claude/skills/process-triage/SKILL.md:115` — triage starts by generating the plan.
- `~/.claude/skills/process-triage/SKILL.md:122` — application is a later step after review.
- `~/.claude/skills/process-triage/SKILL.md:152` — do not run apply without reviewing the plan.
- `~/.claude/skills/saas-cli-auth-flow/SKILL.md:127` — auth exchange retries can enable replay attacks and should fail permanently.
- `~/.claude/skills/tech-debt-management/SKILL.md:113` — cleanup work is timeboxed and escalated to debt when it exceeds scope.
- `~/.claude/skills/cfs-cli-discipline/SKILL.md:48` — JSON and robot modes make planned operations inspectable.
- `~/.claude/skills/schema-validator-duo/SKILL.md:69` — validators define stable parse, semantic, JSON, and exit behavior.

## Adoption recipes

**Recipe 1 — Dry plan:** generate JSON listing target files, operations, risk class, expected deltas, and commands to run.

**Recipe 2 — Review gate:** require explicit review of the plan artifact before apply, especially for destructive, replayable, or bulk operations.

**Recipe 3 — Scoped apply:** apply consumes the reviewed plan, refuses new targets, and writes a receipt comparing planned versus actual changes.

## Compliance test

```bash
grep -E "(plan|apply|review|--json|robot|dry-run|receipt|replay|scope)" SKILL.md || fail
```
