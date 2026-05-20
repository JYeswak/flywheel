# MP-117 - Journey registry to executable gate

**Discovered:** 2026-05-19T07:46Z
**Discovered by:** skillos:2
**Skills exemplifying:** 4+

## Essence

User journeys become operational only when declared in a registry, grounded in specific context, validated against a schema, compiled to executable checks, and blocked from downstream work until gates pass.

## Where it applies

Product journey docs, SaaS support flows, ISP subscriber activation, ZestStream consumer repos, Playwright journey testing, customer onboarding, and service workflows where "happy path" prose drifts from what users actually do.

## Adoption signal

The journey has a specific persona and moment, observable success metrics, registry row, schema validation, generated or hand-promoted executable tests, and downstream gates for beads, CI, billing, or closure.

## Exemplar skills (>=5)

- `~/.claude/skills/journey-architect/SKILL.md:15` - each journey names a specific human, moment, and geographic or temporal context.
- `~/.claude/skills/journey-architect/SKILL.md:17` - success metrics must be observable from logs, analytics, or journey-spec assertions.
- `~/.claude/skills/journey-architect/SKILL.md:20` - beads are blocked until user story and benchmark exist and validate.
- `~/.claude/skills/journey-architect/SKILL.md:111` - validation must pass before scorecard update.
- `~/.claude/skills/zs-journey-bootstrap/SKILL.md:9` - repos get a declarative `.zs-journeys.yaml` registry compiled to Playwright.
- `~/.claude/skills/zs-journey-bootstrap/SKILL.md:75` - existing journey registries are canonical declarations and should not be overwritten casually.
- `~/.claude/skills/subscriber-activation/SKILL.md:20` - activation ends only with verified measurable confirmation that service works.
- `~/.claude/skills/user-support-ticketing-system-for-saas/SKILL.md:183` - support implementations require state-machine conformance fixtures.

## Adoption recipes

**Recipe 1 - Context row:** define persona, trigger moment, target outcome, and measurable success.

**Recipe 2 - Registry declaration:** record the journey in YAML/scorecard/schema before tests or beads.

**Recipe 3 - Executable gate:** compile or author tests and block downstream closure until they pass.

## Compliance test

```bash
grep -E "(journey|registry|persona|success metric|validate|Playwright|scorecard|state-machine|activation)" SKILL.md || exit 1
```
