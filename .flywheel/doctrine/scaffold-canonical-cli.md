---
title: "scaffold-canonical-cli doctrine"
type: doctrine
created: 2026-05-10
frontmatter_source: scaffold-doc-frontmatter
---

# scaffold-canonical-cli doctrine

**Bead origin:** flywheel-ws02m (depends on flywheel-tiugg helper lib).
**Apply spec:** `.flywheel/audit/flywheel-jloib.0b/apply-spec.md`.
**Pilot reference:** `.flywheel/scripts/daily-report-enabled-repos.sh`.

## Why this exists

The canonical-cli surface (doctor / health / repair / validate / audit /
why / quickstart / help / completion + --info / --schema / --examples)
is ~70% boilerplate per script. Hand-applying it across the P0 inventory
(395 scripts) at ~3.5h each is ~1300 hours. The scaffolder compresses
the boilerplate portion to ~30-60min per script, so per-surface upgrade
work shrinks to:

1. Run `scaffold-canonical-cli.sh <script> --dry-run --json` to preview
2. Review the unified diff
3. Run `--apply --idempotency-key=...` to mutate the target
4. Fill in TODO markers (per-surface doctor / repair / validate logic)
5. Run scaffolded `tests/<name>-canonical-cli.sh` (13/13 PASS for
   canonical surface assertions; per-surface TODO assertions added by
   operator)

## Architecture: top-injection + early-dispatch

Every targeted script gets the canonical surface injected near the top
(after shebang + initial `set` lines). The injected block defines all
canonical functions (`scaffold_emit_info`, `scaffold_cmd_doctor`, …) AND
runs an early-dispatch intercept:

```bash
if [[ $# -gt 0 ]] && _scaffold_is_canonical_arg "$@"; then
  scaffold_main "$@"
  exit $?
fi
```

The intercept fires ONLY for canonical subcommands (`doctor`, `health`,
`repair`, …) and canonical introspection flags (`--info`, `--schema`,
`--examples`). For everything else it returns false and falls through
to the target's original arg parser. This works for both:

- Targets with a `main "$@"` entry point at the bottom
- Targets with inline `while [[ $# -gt 0 ]]; do case "$1" in …` loops

The original behavior is preserved for the original flag space; the
canonical surface is additive and intercepts cleanly.

## Idempotency

The injected block leads with `# flywheel-cli-surface: true`. Subsequent
scaffolder runs detect the magic comment and return
`status: already_scaffolded` with zero changes. Re-running `--apply` on
an already-scaffolded target is a byte-identical no-op.

## Refusal classes (each emits canonical envelope + exit code)

| Refusal               | Exit | Trigger |
|-----------------------|------|---------|
| `apply_without_idempotency_key` | 3 | `--apply` without `--idempotency-key=KEY` |
| `jeff_stack_target`   | 66   | target path includes `/ntm/`, `/beads_rust/`, `/frankensqlite/`, etc. — file upstream, don't patch |
| `uninventoried_target`| 66   | target not in `.flywheel/audit/flywheel-cli-inventory/inventory.jsonl` (override with `--allow-uninventoried`) |
| `missing_helper_lib`  | 65   | `.flywheel/lib/canonical-cli-helpers.sh` missing or unreadable |

## Receipt JSONL (apply only)

Each `--apply` run appends one row to
`.flywheel/state/scaffold-runs.jsonl`:

```json
{
  "ts": "2026-05-10T15:00:16Z",
  "target": ".flywheel/scripts/foo.sh",
  "mode": "apply",
  "idempotency_key": "20260510T150015Z-flywheel-XXX",
  "before_lines": 85,
  "after_lines": 319,
  "lines_added_by_scaffolder": 234,
  "todo_count": 18,
  "test_scaffolded": true,
  "test_path": "tests/foo-canonical-cli.sh",
  "backup_path": "/Users/josh/Developer/flywheel/.flywheel/scripts/foo.sh.bak.scaffold-20260510T150016Z",
  "unified_diff_path": "/tmp/scaffold-canonical-cli.XXX/foo.sh.diff",
  "helper_lib_sha": "...",
  "scaffolder_sha": "...",
  "status": "apply_ok",
  "schema_version": "scaffold-canonical-cli/v1"
}
```

Dry-run rows are NOT appended (read-only invariant). The unified diff
path lives in tmp (it's tied to the run, not the target).

## Test scaffold

`--apply` also generates `tests/<name>-canonical-cli.sh` (13 canonical
assertions) when the test file does not already exist. Pre-existing
test files are left alone. The 13 assertions cover:

1. `bash -n` syntax check
2. `--info --json` envelope
3. `--schema` envelope
4. `--examples --json` envelope
5. `doctor --json` envelope
6. `health --json` envelope
7. `repair --dry-run --json` envelope
8. `repair --apply` rc=3 refusal (no idem key)
9. `validate --json` envelope
10. `audit --json` envelope
11. `why <id>` envelope
12. `help <topic>` returns text
13. `quickstart` envelope

TODO markers in the test scaffold guide the operator to add per-surface
assertions specific to the script's domain.

## Boundary discipline

- READ: target script, helper lib (`canonical-cli-helpers.sh`), inventory.jsonl
- WRITE: `<target>.bak.scaffold-<UTC>` (apply only), `<target>` (apply only),
  `tests/<name>-canonical-cli.sh` (apply, only if missing),
  `.flywheel/state/scaffold-runs.jsonl` (apply only)
- REFUSE: jeff-stack paths, uninventoried targets (default), missing
  helper lib, `--apply` without idempotency key
- IDEMPOTENT: re-running on a scaffolded target returns no-op

## Pilot vs scaffolded difference

The pilot (`daily-report-enabled-repos.sh`) is a HAND-CRAFTED canonical-cli
surface — every section bespoke for the script's domain (config validation,
per-repo health, etc.). The scaffolder produces the BOILERPLATE skeleton;
operator fills the TODO markers to reach pilot-quality content. The
scaffolder is the 70% solution, the operator is the 30%.

## Cross-references

- bead flywheel-tiugg (jloib.0a — helper lib, closed)
- bead flywheel-ws02m (jloib.0b — this scaffolder)
- bead flywheel-jloib.0c (linter — SHOULD precede; not a hard dep)
- pilot: `.flywheel/scripts/daily-report-enabled-repos.sh`
- inventory: `.flywheel/audit/flywheel-cli-inventory/inventory.jsonl` (395 entries)
