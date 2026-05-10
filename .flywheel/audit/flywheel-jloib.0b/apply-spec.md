# Bead jloib.0b: scaffold-canonical-cli.sh

Scaffolder that takes any P0 surface and emits the canonical-cli +
doctor-mode upgrade as a unified diff. Depends on jloib.0a (helper lib).

Pilot reference: `.flywheel/scripts/daily-report-enabled-repos.sh` is
the canonical example of post-scaffold output.

## Goal

Ship `.flywheel/scripts/scaffold-canonical-cli.sh` that compresses
per-surface upgrade effort from ~3.5h to ~30-60min by templating
the ~70% boilerplate portion of canonical-cli + doctor-mode work.

## Scope

### AG1: input + analysis

```bash
scaffold-canonical-cli.sh <script_path> --dry-run --json   # default
scaffold-canonical-cli.sh <script_path> --apply --idempotency-key KEY
scaffold-canonical-cli.sh <script_path> --json --info      # what would scaffolder do
```

Analysis phase:
- Parse existing `--help`, arg-parsing loops, main dispatch
- Detect: existing subcommand surface (doctor/health/repair? what flags?)
- Detect: `--apply` / `--dry-run` patterns + their state-mutation paths
- Detect: existing test coverage (`tests/<name>-canonical-cli.sh`)
- Read inventory.jsonl row for this script (priority, lane, signals)

### AG2: scaffold injection

The scaffolder produces a unified diff that:

1. **Adds magic comment** at top: `# flywheel-cli-surface: true`
2. **Adds metadata header** with schema version + tier annotation
3. **Sources helper lib**: `source "$REPO/.flywheel/lib/canonical-cli-helpers.sh"`
4. **Wraps existing `main`/dispatch** as `cmd_run` (preserving backward
   compat when first arg looks like an old flag)
5. **Inserts `usage()`** with the canonical structure
6. **Inserts emit_info / emit_schema / emit_examples / emit_quickstart /
   emit_topic_help / emit_completion** using helper-lib calls
7. **Inserts `cmd_doctor` stub** with TODO markers naming the substrate
   to probe (heuristic from script content)
8. **Inserts `cmd_health` stub** with TODO markers
9. **Inserts `cmd_repair` stub** with --scope/--dry-run/--apply/
   --idempotency-key plumbing already correct, TODO markers for
   per-scope actions
10. **Inserts `cmd_validate` stub** if script handles state, else
    documents `validate_out_of_scope=true` in schema
11. **Inserts `cmd_audit`** (almost-pure template; just file path varies)
12. **Inserts `cmd_why` stub** if script has clear ID semantics, else
    documents `why_out_of_scope=true`
13. **New main dispatch** with --help routing per subcommand
14. **TODO markers** are bracketed and grep-able:
    `# TODO(canonical-cli-scaffold): <what to fill in>`

### AG3: test scaffold

Generates `tests/<name>-canonical-cli.sh` from a template that:
- Imports the same 22-assertion structure as the pilot test
- Replaces `daily-report-enabled-repos` with the target name
- Adds TODO markers for surface-specific assertions
- Always passes the canonical-cli-scoping checker assertion

### AG4: idempotency

Running scaffolder on an already-scaffolded script (one that already
sources canonical-cli-helpers.sh) is a no-op. Detection: presence of
the magic comment + sourcing line. Output: `status: already_scaffolded`.

### AG5: dogfood

After scaffolder ships:
- Run on a known-clean P0 surface (e.g.,
  `.flywheel/scripts/callback-fix-bead-opener.sh` — 85 lines, simple
  scope) and verify the diff produces canonical-cli-passing surface
  with TODOs only in per-surface logic
- Operator fills TODOs in <30min (target)
- Regression test passes

### AG6: receipt

Each scaffolder run records to `.flywheel/state/scaffold-runs.jsonl`:
```json
{
  "ts": "<UTC>",
  "target": "<script_path>",
  "mode": "dry_run|applied",
  "idempotency_key": "...",
  "before_lines": <n>,
  "after_lines": <m>,
  "lines_added_by_scaffolder": <delta>,
  "todo_count": <count of TODO markers inserted>,
  "test_scaffolded": true|false
}
```

## Boundary

- ONLY templates the boilerplate. Surface-specific logic (doctor checks,
  repair actions, validate logic, why provenance) stays as TODO markers
  for human/agent fill-in.
- DOES NOT remove or rewrite existing logic — only wraps and supplements.
- Diff is reviewable by `git diff` after apply; backup goes to
  `<script>.bak.scaffold-<ts>` for byte-exact rollback.
- Refuses scaffolding on any script NOT in `.flywheel/audit/flywheel-cli-inventory/inventory.jsonl`
  (must be inventoried first).
- Refuses on jeff-stack-orchestrated paths (per
  `feedback_jeff_issue_chain` — file upstream, don't patch).

## Acceptance gate

- `bash -n .flywheel/scripts/scaffold-canonical-cli.sh` passes
- Smoke test: scaffold a fresh fixture script → resulting diff applied →
  canonical-cli checker reports 13/13 PASS (with TODO-stub doctor/health/
  repair returning valid envelopes even before fill-in)
- Idempotency: running twice produces identical second-run diff (zero
  changes)
- Receipt JSONL row appended on each run
- Linter (jloib.0c) reports zero violations on scaffolder output

## Estimated effort

~12 hours. ~600 lines scaffolder (largest of the 4) + ~150 lines test
+ ~80 lines docs. The bulk of work is parsing existing scripts safely
and emitting clean diffs.

## Dependencies

- jloib.0a (helper lib) MUST land first
- jloib.0c (linter) SHOULD land first to validate scaffolder output;
  not strictly required if scaffolder author follows the patterns
