# Audit pack: flywheel-ws02m

**Bead:** flywheel-ws02m — [doctor-mode-tooling-0b] scaffold-canonical-cli.sh: parametric scaffolder for P0 surface upgrades
**Apply spec:** `.flywheel/audit/flywheel-jloib.0b/apply-spec.md`
**Pilot reference:** `.flywheel/scripts/daily-report-enabled-repos.sh` (817 lines hand-crafted)
**Helper-lib dep:** flywheel-tiugg `.flywheel/lib/canonical-cli-helpers.sh` (382 lines, closed)
**Worker:** MistyCliff (flywheel:0.4)
**UTC:** 2026-05-10T15:04:00Z
**Disposition:** DONE — scaffolder ships, 20/20 e2e PASS, dogfood verified 13/13 canonical-cli assertions on real fixture target.

## Summary

| Metric | Value |
|--------|-------|
| Scaffolder script | `.flywheel/scripts/scaffold-canonical-cli.sh` (797 lines) |
| E2E test | `tests/scaffold-canonical-cli-e2e.sh` (20/20 PASS) |
| Dogfood target | `.flywheel/scripts/callback-fix-bead-opener.sh` (85 → 319 lines, 18 TODOs) |
| Dogfood result | scaffolded target's `tests/<name>-canonical-cli.sh` 13/13 PASS |
| Doctrine | `.flywheel/doctrine/scaffold-canonical-cli.md` |
| Runs log | `.flywheel/state/scaffold-runs.jsonl` (cleaned post-dogfood; live receipts append on real applies) |

## Acceptance gates

### AG1 — Input + analysis modes ✓

`.flywheel/scripts/scaffold-canonical-cli.sh` ships with:
- `<script_path> --dry-run --json` (default; emits unified diff path + JSON receipt)
- `<script_path> --apply --idempotency-key=KEY` (mutation gate)
- `--info --json` / `--schema [<surface>]` / `--examples --json` (canonical introspection)

Inventory check uses `.flywheel/audit/flywheel-cli-inventory/inventory.jsonl`
(395 entries) by default; override via `--inventory PATH` or
`SCAFFOLD_INVENTORY` env. Targets not in inventory are refused with
`status: refused, reason: uninventoried_target` (rc=66) unless
`--allow-uninventoried` is passed.

### AG2 — Scaffold injection ✓

Scaffolder uses **top-injection + early-dispatch** strategy (deviation
from spec which assumed `main "$@"` final-line wrapping; the inline-
arg-parsing case in real targets needed early intercept). Block lands
after shebang + initial `set` lines and:

1. Magic comment `# flywheel-cli-surface: true` ✓
2. Schema/version metadata header ✓
3. Source line `source "$_SCAFFOLD_HELPER_LIB"` ✓
4. `scaffold_main` wraps original main when present; original arg
   parser handles non-canonical args via fall-through ✓
5. `scaffold_usage` (canonical structure) ✓
6. `scaffold_emit_info / emit_examples / emit_quickstart / emit_topic_help / emit_completion` (helper-lib-backed) ✓
7. `scaffold_cmd_doctor` stub with TODO marker ✓
8. `scaffold_cmd_health` stub with TODO marker ✓
9. `scaffold_cmd_repair` with `--scope` / `--dry-run` / `--apply` /
   `--idempotency-key` plumbing already correct + TODO markers ✓
10. `scaffold_cmd_validate` stub with TODO marker ✓
11. `scaffold_cmd_audit` (audit log path templated) ✓
12. `scaffold_cmd_why` stub with TODO marker ✓
13. New main dispatch via `scaffold_main` with --help routing per
    subcommand (lazy: each subcommand intercepts `--help` before parsing) ✓
14. TODO markers grep-able as `# TODO(canonical-cli-scaffold): <what>` ✓

The dogfood scaffold of callback-fix-bead-opener.sh contains 18 TODO
markers, all matching `TODO(canonical-cli-scaffold)`.

### AG3 — Test scaffold ✓

`emit_test_scaffold` generates `tests/<name>-canonical-cli.sh` with 13
canonical-cli assertions (one for each canonical surface). Test scaffold
is created on `--apply` only when the test file does NOT already exist;
pre-existing tests are left alone (so manually-authored tests for the
pilot are preserved).

Per the test scaffold's TODO marker:
> `# TODO(canonical-cli-scaffold): add per-surface assertions here.`

### AG4 — Idempotency ✓

`is_already_scaffolded` greps for `^# flywheel-cli-surface: true`. Re-run
on a scaffolded target returns:

```json
{"status":"already_scaffolded","reason":"target carries # flywheel-cli-surface: true magic comment"}
```

Verified by e2e Tests 16-17:
- Test 16: dry-run on scaffolded target returns `already_scaffolded`
- Test 17: apply on already-scaffolded target leaves file byte-identical (sha256 match before/after)

### AG5 — Dogfood ✓

Ran scaffolder against `.flywheel/scripts/callback-fix-bead-opener.sh`
(85 lines, P0, inventoried). Result:

```
status:        apply_ok
before_lines:  85
after_lines:   319
scaffold_lines_added: 234
todo_count:    18
test_scaffolded: true
```

Scaffolded target's generated test (`tests/callback-fix-bead-opener-
canonical-cli.sh`) ran 13/13 PASS:

```
PASS syntax
PASS --info emits canonical envelope
PASS --schema emits canonical envelope
PASS --examples emits canonical envelope
PASS doctor emits canonical envelope
PASS health emits canonical envelope
PASS repair --dry-run emits canonical envelope
PASS repair --apply without --idempotency-key returns rc=3 (canonical refusal)
PASS validate emits canonical envelope
PASS audit emits canonical envelope
PASS why <id> emits canonical envelope
PASS help repair returns topic header
PASS quickstart emits canonical envelope
SUMMARY pass=13 fail=0
```

Backwards-compat verified separately: invoking the scaffolded target
with `--task-id … --reason …` (the original flags) still creates a
fix-bead via the original arg-parsing logic. This created a real test
bead (`flywheel-k9p92`) which I closed with reason cite as
"test fixture from flywheel-ws02m scaffolder dogfood".

**Production cleanup**: the dogfood scaffolded version of
callback-fix-bead-opener.sh was reverted from the live tree post-
verification (TODOs unfilled = not ship-ready). The unified diff
that would have been applied is preserved at
`.flywheel/audit/flywheel-ws02m/dogfood-diff.patch` (243 lines, full
reproducible record). Real apply receipts snapshot at
`dogfood-receipt-snapshot.jsonl` (2 rows). Production
`.flywheel/state/scaffold-runs.jsonl` reset to empty so future real
applies start clean.

### AG6 — Receipt JSONL ✓

`.flywheel/state/scaffold-runs.jsonl` row schema (verified by e2e Test 11):

```json
{
  "ts": "2026-05-10T15:00:16Z",
  "target": ".flywheel/scripts/foo.sh",
  "mode": "apply",
  "idempotency_key": "20260510T150015Z-bead-id",
  "before_lines": 85,
  "after_lines": 319,
  "lines_added_by_scaffolder": 234,
  "todo_count": 18,
  "test_scaffolded": true,
  "test_path": "tests/foo-canonical-cli.sh",
  "backup_path": ".../foo.sh.bak.scaffold-...",
  "unified_diff_path": "/tmp/.../foo.sh.diff",
  "helper_lib_sha": "...",
  "scaffolder_sha": "...",
  "status": "apply_ok",
  "schema_version": "scaffold-canonical-cli/v1"
}
```

Dry-run does NOT append a row (e2e Test 7).

## Refusal classes (verified by e2e)

| Class | Trigger | RC | Test |
|-------|---------|----|------|
| `apply_without_idempotency_key` | `--apply` without `--idempotency-key=KEY` | 3 | Test 8 |
| `jeff_stack_target` | path matches `/ntm/`, `/beads_rust/`, `/frankensqlite/`, etc. | 66 | Test 18 |
| `uninventoried_target` | not in inventory.jsonl (override with `--allow-uninventoried`) | 66 | Test 19 |
| `--allow-uninventoried` bypass | env override | 0 | Test 20 |

## Boundary discipline

- ✓ READ target + helper-lib + inventory; NEVER edit jeff-stack paths
- ✓ WRITE only to `<target>` (apply), `<target>.bak.scaffold-<UTC>` (apply),
  `tests/<name>-canonical-cli.sh` (apply, only if missing),
  `.flywheel/state/scaffold-runs.jsonl` (apply only)
- ✓ Idempotent via magic-comment detection
- ✓ Helper lib version pinned via SHA in receipt
- ✓ Scaffolder self-pinned via SHA in receipt
- ✓ Dry-run is read-only (e2e Tests 6 + 7 enforce)

## E2e test breakdown (20 assertions)

```
PASS scaffolder bash -n
PASS --info emits canonical envelope
PASS --schema emits canonical envelope
PASS --examples emits canonical envelope with examples array
PASS dry-run emits dry_run_ok envelope with positive scaffold_lines_added + todo_count
PASS dry-run leaves target untouched (no magic comment)
PASS dry-run does not write runs log (read-only invariant)
PASS --apply without --idempotency-key returns rc=3 (canonical refusal)
PASS --apply mutates target + magic comment present
PASS apply created backup file
PASS receipt JSONL appended with apply_ok + idempotency_key
PASS scaffolded target syntax_ok
PASS scaffolded target --info works
PASS scaffolded doctor/health/audit emit canonical envelopes
PASS scaffolded target preserves backwards-compat (--input flag falls through)
PASS re-run on scaffolded target returns already_scaffolded
PASS apply on already-scaffolded target leaves file byte-identical
PASS scaffolder refuses jeff-stack target with rc=66
PASS scaffolder refuses uninventoried target with rc=66
PASS --allow-uninventoried bypasses uninventoried refusal
SUMMARY pass=20 fail=0
```

## Files shipped

- `.flywheel/scripts/scaffold-canonical-cli.sh` (new; 797 lines)
- `tests/scaffold-canonical-cli-e2e.sh` (new; 20/20 PASS)
- `.flywheel/doctrine/scaffold-canonical-cli.md` (new; architecture +
  refusal classes + receipt schema + pilot-vs-scaffolded distinction)
- `.flywheel/canonical-paths.txt` (modified; +4 rows)
- `.flywheel/state/scaffold-runs.jsonl` (new; empty, ready for real apply receipts)
- `.flywheel/audit/flywheel-ws02m/evidence.md` (this file)
- `.flywheel/audit/flywheel-ws02m/dogfood-diff.patch` (243-line proof of
  what scaffolder would emit on the dogfood target)
- `.flywheel/audit/flywheel-ws02m/dogfood-test-scaffold.sh` (the
  generated 13-assertion test scaffold for the dogfood target)
- `.flywheel/audit/flywheel-ws02m/dogfood-receipt-snapshot.jsonl` (the
  2 real apply receipt rows from dogfood; reverted post-verification)
- `.flywheel/journal/flywheel-ws02m.md` (new)

## Spec deviations

1. **Top-injection vs `main "$@"` wrapping**: spec assumed targets have
   a `main "$@"` final line that the scaffolder comments out. Real
   targets (callback-fix-bead-opener.sh, the dogfood) use inline
   `while [[ $# -gt 0 ]]; do case "$1" in` arg parsing instead — no
   `main` function exists. Top-injection + early-dispatch handles BOTH
   styles cleanly without parsing the target's structure. Spec assumed
   complexity that wasn't load-bearing.
2. **Subcommand `--help` routing**: implemented as per-subcommand
   intercept in `scaffold_main` (each subcommand's first arg is checked
   for `--help`/`-h` before parsing further). Bare `help` without a
   topic is NOT intercepted (could clash with a target's legacy `help`
   subcommand); `help <topic>` form is required.
3. **`--examples` as opt-in flag rather than full-script generation**:
   the e2e test treats `--examples --json` identically; no functional
   gap.
4. **Pilot integration**: dogfood verifies output passes 13/13
   canonical-cli surface assertions; pilot-quality (filled-in TODOs)
   is operator's job, not scaffolder's. Spec AG6 ("Linter (jloib.0c)
   reports zero violations on scaffolder output") deferred to when 0c
   ships — not gating per spec ("not strictly required if scaffolder
   author follows the patterns").

## Cross-references

- bead flywheel-tiugg (closed) — helper lib (jloib.0a)
- bead flywheel-ws02m (this) — scaffolder (jloib.0b)
- bead flywheel-jloib.0c (TBD) — linter for scaffolder output
- pilot: `.flywheel/scripts/daily-report-enabled-repos.sh` (817 lines hand-crafted)
- doctrine: `.flywheel/doctrine/scaffold-canonical-cli.md`

## Four-Lens Self-Grade

- brand: 9 — top-injection+early-dispatch handles both `main "$@"` AND
  inline-arg-loop targets; helper-lib pinning via SHA; pilot vs
  scaffolded distinction explicit in doctrine.
- sniff: 9 — every claim verifiable; 20/20 e2e + 13/13 dogfood;
  refusal classes assertable; backwards-compat verified empirically.
- jeff: 9 — refuses jeff-stack paths by default; receipt JSONL
  contract; idempotent via magic-comment detection; dry-run is
  read-only (asserted).
- public: 9 — three-judges check: skeptical operator can re-run
  scaffolder on any P0 target; maintainer reads doctrine to
  understand the top-injection contract; future worker fills in
  per-surface TODOs in <30min and ships.
