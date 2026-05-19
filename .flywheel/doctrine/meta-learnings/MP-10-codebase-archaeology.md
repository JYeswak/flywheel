# MP-10 — Codebase archaeology before mutation

**Discovered:** 2026-05-19T01:00Z
**Skills exemplifying:** 5+

## Essence

Before mutating ANY non-trivial file, archaeology: read the file's history, intent, and surrounding doctrine — never write blind based on context window state alone.

## Where it applies

Refactors, doctrine updates, schema changes, multi-file edits, any cross-orch work.

## Adoption signal

Skill explicitly cites pre-edit reads (Read tool / git blame / socraticode search) before any Edit/Write.

## Exemplar skills (≥5)

- `~/.claude/skills/codebase-archaeology/SKILL.md:1` — direct exemplar
- `~/.claude/skills/codebase-pattern-extraction/SKILL.md:1` — pattern mining via archaeology
- `~/.claude/skills/socraticode/SKILL.md:1` — K≥10 socraticode-first pre-edit discipline
- `~/.claude/skills/codebase-audit/SKILL.md:1` — audit-before-mutate
- `~/.claude/skills/codebase-report/SKILL.md:1` — read-only structured report
- `~/.claude/skills/multi-pass-bug-hunting/SKILL.md:1` — bug hunt pre-fix archaeology

## Adoption recipes

**Recipe 1 — Pre-edit gate:** every Edit/Write tool call preceded by ≥1 Read OR socraticode search of the target file.

**Recipe 2 — Cite-as-receipt:** edit receipts include `pre_edit_reads: [path1, path2, ...]` + `socraticode_queries: [...]`.

**Recipe 3 — Doctrine forbid:** explicit "no blind edits" rule in skill or repo CLAUDE.md.

## Compliance test

```bash
# Skills authoring mutations MUST cite socraticode or archaeology.
grep -E "(socraticode|archaeology|pre.edit|read.first|K.{0,3}10)" SKILL.md || fail
```
