# MP-118 - Documentation lifecycle feedback loop

**Discovered:** 2026-05-19T07:46Z
**Discovered by:** skillos:2
**Skills exemplifying:** 4+

## Essence

Documentation is a lifecycle system: audience and information architecture first, tested examples and rendered artifacts next, then freshness, search, feedback, and release coupling keep it true.

## Where it applies

Documentation sites, technical writing, API docs, README/runbook work, PDF/report generation, generated docs, changelogs, tutorial/reference sites, and any publishable artifact that can drift from code or data.

## Adoption signal

The docs classify page type and audience, include copy-pasteable examples, render or smoke-test output, link freshness to CI or release train, and collect reader/search feedback into the next revision.

## Exemplar skills (>=5)

- `~/.claude/skills/documentation-website-for-software-project/SKILL.md:13` - docs are narrative plus reference, not method dumps.
- `~/.claude/skills/documentation-website-for-software-project/SKILL.md:79` - the docs pipeline runs research, draft, synthesize, polish, build, deploy, E2E, and user-lens phases.
- `~/.claude/skills/documentation-website-for-software-project/SKILL.md:156` - audience, lifecycle, and feedback are planned cross-cutting concerns.
- `~/.claude/skills/documentation-website-for-software-project/SKILL.md:199` - every page belongs to tutorial, how-to, reference, or explanation.
- `~/.claude/skills/technical-writing/SKILL.md:26` - documentation types differ by purpose, audience, structure, and update cadence.
- `~/.claude/skills/technical-writing/SKILL.md:52` - every code example should be tested, complete, copy-pasteable, and version-pinned.
- `~/.claude/skills/technical-writing/SKILL.md:209` - docs verification includes fresh reader, runnable examples, links, diagrams, search, mobile, stale references, and version match.
- `~/.claude/skills/pdf-generation/SKILL.md:210` - generated PDFs are verified with min/max data, special characters, missing fields, multiple viewers, file size, accessibility, and print checks.

## Adoption recipes

**Recipe 1 - Audience/IA declaration:** tag each page by persona and documentation quadrant before writing content.

**Recipe 2 - Rendered artifact test:** run examples, links, diagrams, screenshots, PDFs, or smoke tests in CI.

**Recipe 3 - Feedback/freshness hook:** wire search logs, thumbs, release version, or stale-page checks into the next edit queue.

## Compliance test

```bash
grep -E "(documentation|audience|tutorial|how-to|reference|explanation|example|freshness|feedback|smoke|PDF)" SKILL.md || exit 1
```
