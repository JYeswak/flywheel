---
title: Flywheel doctrine catalog
type: readme
created: 2026-05-10
auto_generated: true
bead: flywheel-s8tdd
parent: filesystem-as-rag
---

# `.flywheel/doctrine/`

Canonical doctrine documents for the flywheel substrate. Each doc is
authoritative for its named topic and is the single source of truth
for downstream artifacts (skills, scripts, beads).

## Naming convention

`<topic-kebab>.md` — one doctrine per file, named for the topic.
Frontmatter required (per `filesystem-as-rag.md` Rule 2).

## Catalog

The catalog is materialized by `ls -1 .flywheel/doctrine/*.md` —
this README is intentionally not exhaustive so it doesn't drift.
For the live list:

```bash
ls -1 .flywheel/doctrine/*.md
```

Notable load-bearing doctrines (as of 2026-05-10):

- `filesystem-as-rag.md` — at-rest discoverability discipline (this dir's parent)
- `dispatch-author-skill-routing-contract.md` — orch dispatch path
- `skill-autoresearch-tooling-preference-class.md` — skill-target routing

## Lifecycle

- **active** — currently load-bearing
- **archived** / **superseded** — kept in tree for history; new work
  uses the named successor (named in frontmatter `superseded_by:`)

Per `filesystem-as-rag.md` Rule 7 (No Junk Drawers), superseded
doctrines stay in this directory with `status: superseded` rather than
being moved to `_archive/`.

## Authoring a new doctrine

1. Author the body
2. Add frontmatter via `.flywheel/scripts/scaffold-doc-frontmatter.sh`
3. Lint with `.flywheel/scripts/file-rag-discipline-lint.sh`
4. Commit with reference bead in trailer

## Cross-references

- Linter: `.flywheel/scripts/file-rag-discipline-lint.sh`
- Doctrine source rule: `.flywheel/doctrine/filesystem-as-rag.md`
