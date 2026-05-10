---
title: Flywheel audit directories
type: readme
created: 2026-05-10
auto_generated: true
bead: flywheel-s8tdd
parent: filesystem-as-rag
---

# `.flywheel/audit/`

Per-bead audit/apply-spec directories. Each subdirectory is named for
the bead it serves and contains the planning artifacts (apply-spec,
research notes, baseline data) authored before the bead's worker tick.

## Naming convention

`<bead-id>/` or `<topic-slug>/` — one directory per logical effort.
Bead-named dirs use the form `flywheel-<id>/` exactly matching the
bead's beads-br ID.

## Canonical contents

Each audit dir SHOULD contain at least one of:

- `apply-spec.md` — the work specification (authoritative for the
  worker dispatch). Must have canonical H2 sections (`## Goal`,
  `## Scope`, `## Boundary`, `## Acceptance gate`) per F7 lint rule.
- `evidence.md` — post-completion receipt (filed by the worker tick)
- `baseline.json` — pre-work data snapshot (e.g., lint scan output)
- `STATE.json` — multi-phase plan state (per `/flywheel:plan` skill)
- `README.md` — directory-level catalog if multiple sub-artifacts

## Lookup

Find the bead behind any audit dir:

```bash
br show flywheel-<id>          # if dir name is bead-id form
ls .flywheel/audit/<dir>/      # otherwise inspect for evidence.md or apply-spec.md
```

## Lifecycle

Audit dirs are append-only by convention. After bead close, the
directory remains as historical receipt. Per F7 lint rule, the
apply-spec.md must conform to canonical H2 structure.

## Cross-references

- Doctrine: `.flywheel/doctrine/filesystem-as-rag.md`
- Linter: `.flywheel/scripts/file-rag-discipline-lint.sh`
- Sibling doctrine: `.flywheel/audit/flywheel-fs-rag-discipline/apply-spec.md` (this README's authoring spec)
