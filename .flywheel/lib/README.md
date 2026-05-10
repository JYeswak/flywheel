---
title: Flywheel shell library helpers
type: readme
created: 2026-05-10
auto_generated: true
bead: flywheel-s8tdd
parent: filesystem-as-rag
---

# `.flywheel/lib/`

Reusable shell library helpers sourced by scripts in
`.flywheel/scripts/`. Drop-in pure-bash modules; no top-level side
effects beyond function definitions and `readonly` constants.

## Naming convention

`<topic-kebab>.sh` — one library file per topic. Each file SHOULD:

- Document its public API in a leading comment block
- Define functions only (no top-level execution beyond constant defs)
- Be `set -u` safe (use `${var:-default}` patterns)
- Source-test cleanly: `bash -c "set -euo pipefail; source <file>"`

## Listing

```bash
ls -1 .flywheel/lib/
```

## Authoring a new library

1. Author functions with the prefix `flywheel_<topic>_<verb>` to avoid
   global namespace collision
2. Export only the public API; document private helpers as such in
   leading comments
3. Add a smoke test under `tests/lib-<topic>.sh`
4. Lint with `.flywheel/scripts/file-rag-discipline-lint.sh` (this
   README enables F2 lint rule for the directory)

## Cross-references

- Sibling: `.flywheel/scripts/` — top-level scripts that source these
- Doctrine: `.flywheel/doctrine/filesystem-as-rag.md`
- Linter: `.flywheel/scripts/file-rag-discipline-lint.sh`
- Pre-commit: `.flywheel/hooks/file-rag-discipline-pre-commit.sh`
