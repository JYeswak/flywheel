# MP-111 - Screenshot-backed visual acceptance loop

**Discovered:** 2026-05-19T07:46Z
**Discovered by:** skillos:2
**Skills exemplifying:** 4+

## Essence

User-facing visual work is not done until it has a repeatable capture, explicit expectations, viewport-aware review, and a recapture proving the fix.

## Where it applies

Frontend polish, web app QA, Remotion renderers, documentation sites, mobile/desktop responsive flows, visual regression suites, and any UI work where code review cannot see the result.

## Adoption signal

The workflow defines capture profiles, expectation checklists, desktop/mobile or before/after coverage, mechanical score/fail gates, and a recapture step after fixes.

## Exemplar skills (>=5)

- `~/.claude/skills/web-visual-qa/SKILL.md:15` - visual QA is a capture, review, diagnose, fix, recapture, compare, sign-off loop.
- `~/.claude/skills/web-visual-qa/SKILL.md:75` - each visual profile has an expectations checklist.
- `~/.claude/skills/web-visual-qa/SKILL.md:118` - frontend beads with visual QA close only after capture and expectation review pass.
- `~/.claude/skills/zs-frontend-quality-gate/SKILL.md:11` - the frontend bar is a machine-readable 10-check feedback loop.
- `~/.claude/skills/zs-frontend-quality-gate/SKILL.md:15` - a frontend is unverified if the gate has not run.
- `~/.claude/skills/ui-polish/SKILL.md:92` - desktop and mobile optimization are considered separately.
- `~/.claude/skills/web-renderer-test/SKILL.md:8` - renderer behavior is covered by visual snapshot testing.
- `~/.claude/skills/web-renderer-test/SKILL.md:75` - every new renderer test needs a fixture, preview route, test, and documentation update.

## Adoption recipes

**Recipe 1 - Capture profile:** name the page, state, viewport, data fixture, and target expectation list.

**Recipe 2 - Recapture gate:** after any visual fix, capture the same profile again and compare against expectations.

**Recipe 3 - Score closeout:** report before/after gate score or checklist pass count; open follow-up work for warnings.

## Compliance test

```bash
grep -E "(screenshot|capture|recapture|visual|expectations|viewport|desktop|mobile|snapshot|gate)" SKILL.md || exit 1
```
