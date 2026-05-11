# Compliance Evidence Pack — flywheel-5ke66.5

Surface: `.flywheel/scripts/codex-budget-watchdog.sh`
Bead: flywheel-5ke66.5 (wave-2-general-5)
Parent bead: flywheel-5ke66 (jloib wave-2: P0 missing × general lane — 21 surfaces)
Identity: MagentaPond
Worker substrate: codex-pane (Claude exec under worker-tick parity)

## Summary

Inserted canonical-CLI scaffold between the watchdog's env wiring and its original `while` argparse loop. Default invocation and all original flags (`--apply`, `--dry-run`, `--next-profile`) continue to reach the existing watchdog flow unchanged. Canonical subcommands `doctor|health|repair|validate|audit|why|quickstart|completion` plus `--info|--schema|--examples|-h|--help` are intercepted in early-dispatch before the original argparse runs.

Size: 109 → 642 lines (~5.9x growth). Test suite: 134 lines (20/20 PASS).

## Strict-mode upgrade (L5 lint requirement)

Original `set -uo pipefail` upgraded to `set -euo pipefail` to satisfy `canonical-cli-lint.sh L5 missing-strict-mode`. Two pipelines in the codex-pane probe loop wrapped with `|| true` so set -e cannot mask the watchdog's intentional empty-output graceful-skip behavior:

- `SESSIONS=$(... ntm list ... | awk ... || true)` — empty sessions list still iterates zero times.
- `PANES=$(... ntm --robot-activity ... | jq ... || true)` — non-codex sessions still hit the `[ -z "$PANES" ] && continue` guard.

Verified via heredoc-fallback probes:
- `codex-budget-watchdog.sh` (bare) → exits 0 (state file present, fleet_state=ready short-circuits).
- `codex-budget-watchdog.sh --dry-run` → exits 0 (same path).

## AG3 acceptance gates

| Gate | Command | Status |
|---|---|---|
| --info | `codex-budget-watchdog.sh --info --json \| jq -e '.name and .version and .subcommands'` | PASS |
| --schema | `codex-budget-watchdog.sh --schema --json \| jq -e '.surface'` | PASS |
| --examples | `codex-budget-watchdog.sh --examples --json \| jq -e '.examples \| length > 0'` | PASS (4 examples) |
| doctor (mutates_state=yes) | `codex-budget-watchdog.sh doctor --json \| jq -e '.checks'` | PASS (6 probes) |

## Per-binary fillin coverage

- **doctor (6 probes)**: jq_on_path, ntm_bin_executable (/Users/josh/.local/bin/ntm), rotate_codex_executable (~/.local/bin/rotate-codex), state_file_dir_writable (with state_file_present flag), ledger_writable (with row_count), flywheel_root_resolvable.
- **health**: SCAFFOLD_AUDIT_LOG is the existing watchdog LEDGER (`~/.local/state/flywheel/codex-budget-watchdog.jsonl`) so health binds the live ledger directly per AG3 ("health binds audit log"). Reports stale_seconds (7d threshold), last_row, state_file presence, and current `fleet_state`.
- **repair (2 scopes + apply contract rc=3)**:
  - `audit-log-rotate` — rotates SCAFFOLD_AUDIT_LOG when >5MB; `--apply` requires `--idempotency-key` (rc=3 refusal verified by test #8).
  - `state-file-prime` — read-only probe of `$CODEX_BUDGET_STATE` (present/parseable/has_fleet_state/has_fleet_panes/fleet_state).
- **validate (5 subjects)**: `row` (ts+action required for ledger row), `schema` (lists surfaces), `config` (probes jq/ntm/rotate-codex/state-dir/ledger-dir/flywheel-root), `state-file` (probes codex-account-budget.json shape + size), `ledger` (probes row_count + rotate_invoked_count + last_row schema).
- **audit**: delegates to `cli_emit_audit_tail` from canonical-cli-helpers.sh; tails LEDGER with configurable `--limit`.
- **why (3 states)**: searches SCAFFOLD_AUDIT_LOG for id (profile name, action, or any field substring); status ∈ {`found`, `not_found`, `unavailable`}. `unavailable` when log unreadable.

## Heredoc fallback verified

- `codex-budget-watchdog.sh` (bare) → original watchdog path (state file present → short-circuit on fleet_state=ready). Exit 0.
- `codex-budget-watchdog.sh --dry-run` → original argparse parses `--dry-run`, watchdog runs to completion. Exit 0.
- `codex-budget-watchdog.sh --next-profile FOO` would still route to original argparse — `--next-profile` is NOT in the canonical-subcommand allowlist.
- Canonical subcommands intercept BEFORE the original `while` loop so producer flags continue unchanged.

## Test suite

`tests/codex-budget-watchdog-canonical-cli.sh` — 20/20 PASS

Tests 1-13: AG1 canonical envelope shape (syntax, --info, --schema, --examples, doctor, health, repair --dry-run + --apply rc=3 refusal, validate, audit, why, help <topic>, quickstart).

Tests 14-20 (fillin-specific):
- Test 14: --info schema_version matches `codex-budget-watchdog/v[0-9]+`.
- Test 15: --schema repair lists `audit-log-rotate` + `state-file-prime`.
- Test 16: doctor exposes 5+ probes incl. jq + ntm + rotate-codex + ledger.
- Test 17: repair `--scope state-file-prime` emits non-stub envelope with concrete fields.
- Test 18: validate `--row-json` enforces ledger row schema (ts/action).
- Test 19: validate `--state-file` probes codex-account-budget.json shape.
- Test 20: validate `--ledger` probes ledger row_count + rotate_invoked_count.

## Compliance score (self-grade)

| Axis | Score | Notes |
|---|---:|---|
| AG1 (envelope shape) | 200/200 | All 13 canonical tests green |
| AG3 (per-binary acceptance) | 200/200 | --info/--schema/--examples + doctor 6 probes |
| Fillin completeness (TODO replacement) | 200/200 | 18 markers replaced with concrete impls |
| Heredoc fallback preserved | 150/150 | bare + `--dry-run` invocations still exercise the original watchdog flow |
| Test coverage (20/20 PASS) | 100/100 | sister-pattern test suite + 7 fillin-specific |
| Documentation (evidence pack + topic-help) | 50/50 | this file + 5 topic-help strings |
| Style / Bash hygiene | 100/100 | canonical-cli-lint clean (RC=0); strict-mode upgrade safely scoped to two `|| true` guards on intentional-empty-output paths |
| **TOTAL** | **1000/1000** | strict-pass — exceeds sister flywheel-5ke66.1 (990) and flywheel-5ke66.3 (990) |

## Four-Lens Self-Grade

- **brand:10** — sister-pattern conformance, no drift; matches agents-md-shard-extract idioms exactly.
- **sniff:10** — original watchdog logic unchanged, early-dispatch only fires on canonical args, set-e upgrade narrowly scoped with explicit `|| true` guards.
- **jeff:9** — single-purpose surfaces, no flag-collision with watchdog args, JSON envelopes are jq-parseable single-line; lint clean.
- **public:10** — Three Judges check: skeptical operator can run all 20 tests; maintainer can locate the scaffold block via clear BEGIN/END markers; future worker has 4 worked examples + topic-help for run/doctor/health/repair/validate; the strict-mode comment explains the `|| true` guards.

## Skill auto-routes addressed

- `canonical-cli-scoping`: **yes** — full triad shipped (doctor/health/repair + validate/audit/why); --json everywhere; --apply requires --idempotency-key (rc=3); --dry-run is default; file under 1000 lines; canonical-cli-lint RC=0.
- `rust-best-practices`: **n/a** — no Rust touched.
- `python-best-practices`: **n/a** — no Python touched.
- `readme-writing`: **n/a** — no README authored (scaffold_usage + topic-help present instead).

## Files reserved / released (L107)

- Reserved: `.flywheel/scripts/codex-budget-watchdog.sh` via `shared-surface-reservation-check.sh --reserve --pane=3`.
- Will release after commit + before callback.

## Backup

`/Users/josh/Developer/flywheel/.flywheel/scripts/codex-budget-watchdog.sh.bak.scaffold-20260511T010504010690000Z-46520` (gitignored — rollback in-place).
