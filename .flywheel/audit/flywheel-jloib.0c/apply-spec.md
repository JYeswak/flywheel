# Bead jloib.0c: canonical-cli-lint.sh

Linter detecting the 4 bash gotchas hit during pilot + canonical-cli
acceptance gate violations. Independent from helper lib (jloib.0a) —
can ship in parallel.

Pilot reference: bugs documented at
`.flywheel/audit/flywheel-cli-canonical-baseline/pilot-lessons.md` §
"Bugs hit during pilot".

## Goal

Ship `.flywheel/scripts/canonical-cli-lint.sh` that catches the bash
gotchas + canonical-cli acceptance failures BEFORE they reach review.
Wired as pre-commit hook + into the canonical-cli regression test
runner.

## Scope

### AG1: lint rules

The linter checks every script with `# flywheel-cli-surface: true` (or
optionally any script under `.flywheel/scripts/*.sh` with
`--scan-all`). For each script:

**Rule L1 — chained-local-set-u**:
```bash
local x="$1" y="$x/foo"   # FAILS under set -u
```
Detection: regex over function bodies for
`local\s+\w+="\$\d+"\s+\w+="\$\w+`. Hint: split into two `local` lines.

**Rule L2 — enumerator missing return 0**:
Functions whose last meaningful statement is `if/then/&&/||` and that
return their last command's exit status. Detection: parse function
definitions, check final non-comment line is not `return` and is not
`done` of a `while/for` loop with explicit trailer.
Hint: add explicit `return 0` at function end.

**Rule L3 — brace-default-ambiguity**:
```bash
local x="${3:-{}}"   # parses wrong
```
Detection: regex `\$\{[0-9]+:-\{\}\}`. Hint: use intermediate var with
`[[ -n "$x" ]] || x='{}'`.

**Rule L4 — short-circuit in helper**:
`[[ ]] && X || Y` patterns inside helper functions defined under
`set -e`. Detection: parse function bodies, flag the pattern when it's
the function's last expression. Hint: use `if/then/elif/fi`.

**Rule L5 — missing strict mode**:
Top-of-script missing `set -euo pipefail`. Hint: add as line 2.

**Rule L6 — missing magic comment**:
Mutating script (has `--apply` flag) missing
`# flywheel-cli-surface: true` at top. Hint: add to enable registry
auto-discovery.

**Rule L7 — apply without idempotency-key gate**:
Script that handles `--apply` but doesn't refuse without
`--idempotency-key`. Detection: scan for `--apply)` case arms, check
that they reference `--idempotency-key` or `IDEM_KEY` validation.
Hint: emit refusal envelope, exit 3.

**Rule L8 — backup before mutation**:
Script that writes to user-state paths (not /tmp) without first
creating a `.bak.<timestamp>` copy. Detection: scan for `>` redirects
to non-/tmp paths in `--apply` paths. Soft warning (some mutations
don't need backups).

### AG2: output

```bash
canonical-cli-lint.sh <script_path>
canonical-cli-lint.sh --scan-all
canonical-cli-lint.sh --scan-all --json
canonical-cli-lint.sh <script_path> --rule L1,L3,L7  # filter rules
```

Default text output: `<file>:<line>: <rule>: <message>`. JSON output:
schema `canonical-cli-lint/v1` with per-violation rows. Exit 0 if
clean, 1 if violations found.

### AG3: pre-commit wire

Ship `.flywheel/hooks/canonical-cli-lint-pre-commit.sh` that:
- Runs `canonical-cli-lint.sh` on every staged `.sh` file under
  `.flywheel/scripts/` or marked with the magic comment
- Refuses commit if violations found (exit 1)
- Allows `--no-verify` override (Joshua's prerogative)

Wired via `.flywheel/scripts/install-hooks.sh` if it exists, or shipped
as standalone instructions in the README.

### AG4: regression test

Ship `tests/canonical-cli-lint.sh` exercising:
- Each rule with a positive fixture (violation present → caught)
- Each rule with a negative fixture (clean code → not flagged)
- `--scan-all` mode produces consistent output for the pilot script
  (which should be clean)
- `--rule` filter respected
- `--json` output schema-valid

### AG5: dogfood

Run linter against the existing pilot
(`daily-report-enabled-repos.sh`). Should report ZERO violations
(since pilot was hand-fixed for all 4 bug classes).

Run linter against the 234 P0 surfaces with `--scan-all --json`. Output
becomes `flywheel-cli-canonical-baseline/lint-baseline.json` — bead 2.x
work uses this baseline to track progress.

## Boundary

- Static analysis only (no script execution).
- ZERO external deps beyond `bash`, `jq`, `grep`, `awk`/`sed`.
- Conservative on rule L4 (short-circuit) — flag only inside functions,
  not top-level (top-level `[[ ]] && X || Y` is idiomatic and safe).
- Per-rule false-positive rate target: <5%. If a rule fires too often
  on clean code, downgrade to soft warning.

## Acceptance gate

- `bash -n .flywheel/scripts/canonical-cli-lint.sh` passes
- `bash tests/canonical-cli-lint.sh` exits 0 with all rule fixtures
- `canonical-cli-lint.sh .flywheel/scripts/daily-report-enabled-repos.sh`
  exits 0 (pilot is clean)
- `canonical-cli-lint.sh --scan-all --json` produces lint-baseline.json
  with schema validity

## Estimated effort

~6 hours. ~300 lines linter + ~150 lines test fixtures + ~40 lines
pre-commit hook + ~30 lines docs.
