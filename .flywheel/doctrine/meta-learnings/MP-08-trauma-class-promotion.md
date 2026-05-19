# MP-08 — Trauma-class promotion

**Discovered:** 2026-05-19T01:00Z
**Skills exemplifying:** 5+

## Essence

The same failure class should not bite three times without promotion into a skill, test, pack, or doctrine record. Trauma becomes substrate after the 3rd instance (or after 1st instance for secret-class / irreversible classes).

## Where it applies

Incident postmortems, debugging, doctrine authoring, skill expansion, learning loops.

## Adoption signal

Repo has an INCIDENTS.md / trauma ledger AND doctrine files that explicitly cite specific trauma instances.

## Exemplar skills (≥5)

- `~/.claude/skills/trauma-guard-pattern/SKILL.md:1` — direct exemplar
- `~/.claude/skills/incident-replay-bundle/SKILL.md:1` — replay infrastructure
- `~/.claude/skills/agentic-coding-flywheel-setup/SKILL.md:1` — references trauma-to-skill loop
- `~/.claude/skills/all-the-receipts/SKILL.md:1` — receipts as trauma evidence
- `~/.claude/skills/incident-response/SKILL.md:1` — response framework
- `~/.claude/skills/.flywheel/doctrine/*.md` — flywheel ecosystem has dozens of trauma-derived doctrine files

## Adoption recipes

**Recipe 1 — Ledger:** every repo MUST have `INCIDENTS.md` or `.flywheel/INCIDENTS.md` with entries citing date + class + count + promotion-decision.

**Recipe 2 — Promotion rule:** doctrine file MUST exist for any trauma class hit ≥3 times. Secret-class trauma promoted immediately on N=1.

**Recipe 3 — Verification:** a script walks INCIDENTS.md and asserts every N≥3 class has a matching doctrine file.

## Compliance test

```bash
# Trauma-discipline repos MUST have INCIDENTS.md.
test -f INCIDENTS.md || test -f .flywheel/INCIDENTS.md || fail
```
