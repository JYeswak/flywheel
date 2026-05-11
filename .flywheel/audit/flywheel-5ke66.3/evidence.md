# Compliance Evidence Pack — flywheel-5ke66.3

Surface: `.flywheel/scripts/auto-refill-decision-log.sh`
Bead: flywheel-5ke66.3 (wave-2-general-3)
Parent bead: flywheel-5ke66 (jloib wave-2: P0 missing × general lane — 21 surfaces)
Identity: MagentaPond
Worker substrate: codex-pane (Claude exec under worker-tick parity)

## Summary

Appended canonical-CLI scaffold + 18-TODO fillin ahead of the existing `python3 - <<'PY'` heredoc. The original `auto_refill_after_reap` decision producer is unchanged and still serves on non-canonical invocations. Early-dispatch intercept routes `doctor|health|repair|validate|audit|why|quickstart|completion` plus `--info|--schema|--examples|-h|--help` to the scaffold before argparse sees the args.

Size: 383 → 934 lines (~2.4x growth). Test suite: 134 lines (20/20 PASS).

## AG3 acceptance gates (parent spec, sister-pattern shape)

| Gate | Command | Status |
|---|---|---|
| --info | `auto-refill-decision-log.sh --info --json \| jq -e '.name and .version'` | PASS |
| --schema | `auto-refill-decision-log.sh --schema --json \| jq -e '.surface'` | PASS |
| --examples | `auto-refill-decision-log.sh --examples --json \| jq -e '.examples \| length > 0'` | PASS (5 examples) |
| doctor (mutates_state=yes) | `auto-refill-decision-log.sh doctor --json \| jq -e '.checks'` | PASS (6 probes) |

## Per-binary fillin coverage

- **doctor (6 probes)**: python3_on_path, jq_on_path, ntm_bin_executable (NTM_BIN=/Users/josh/.local/bin/ntm), br_bin_executable (BR_BIN=/Users/josh/.cargo/bin/br), dispatch_log_writable (.flywheel/dispatch-log.jsonl + row_count), flywheel_root_resolvable.
- **health**: binds SCAFFOLD_AUDIT_LOG + tails .flywheel/dispatch-log.jsonl for last `auto_refill_after_reap` row; reports stale_seconds with 7-day pass threshold.
- **repair (2 scopes + apply contract rc=3)**:
  - `audit-log-rotate` — rotates SCAFFOLD_AUDIT_LOG when >5MB; `--apply` requires `--idempotency-key` (rc=3 refusal verified by test #8).
  - `capacity-file-prime` — read-only probe of `~/.local/state/flywheel/fleet-capacity.json` shape (present/parseable/has_budget_field/max_in_flight).
- **validate (5 subjects)**: `row` (ts/event/schema_version required), `schema` (lists surfaces), `config` (probes python3/jq/ntm/br/dispatch-log dir), `dispatch-log` (probes ledger + last auto_refill_after_reap row schema), `capacity-file` (probes fleet-capacity.json shape).
- **audit**: delegates to `cli_emit_audit_tail` from canonical-cli-helpers.sh; tails SCAFFOLD_AUDIT_LOG with configurable `--limit`.
- **why (3 states)**: searches BOTH SCAFFOLD_AUDIT_LOG and `.flywheel/dispatch-log.jsonl` for the id; status ∈ {`found`, `not_found`, `unavailable`}. unavailable when neither source is readable.

## Heredoc fallback verified

- `auto-refill-decision-log.sh --pane 3 --role general --json` → original `auto_refill_after_reap` decision row envelope (unchanged).
- `auto-refill-decision-log.sh --idle-window-metric --json` → original `auto-refill-idle-window/v1` derived metric (unchanged).
- Canonical subcommands and intro flags are intercepted in early-dispatch BEFORE argparse parses the args, so `--apply`, `--dry-run`, etc. continue to mean what they meant for the producer.

## Test suite

`tests/auto-refill-decision-log-canonical-cli.sh` — 20/20 PASS

Tests 1-13: AG1 canonical envelope shape for syntax, --info, --schema, --examples, doctor, health, repair (--dry-run + --apply rc=3 refusal), validate, audit, why, help <topic>, quickstart.

Tests 14-20 (fillin-specific):
- Test 14: --info schema_version matches `auto-refill-decision-log/v[0-9]+`.
- Test 15: --schema repair lists `audit-log-rotate` + `capacity-file-prime`.
- Test 16: doctor exposes 5+ probes incl. python3 + ntm + br + dispatch_log.
- Test 17: repair `--scope capacity-file-prime` emits non-stub envelope with concrete fields.
- Test 18: validate `--row-json` enforces decision-row schema.
- Test 19: validate `--dispatch-log` probes ledger + auto_refill_row_count.
- Test 20: validate `--capacity-file` probes fleet-capacity.json shape.

## Mid-fix note

Initial `why` impl had a bash arithmetic trap: when `jq 'length'` output picked up a trailing newline from the `|| echo 0` fallback path, `total=$((n_audit + n_ledger))` errored at parse time. Fixed by computing `total_matches` inside the final `jq` envelope (`(.audit_matches|length) + (.ledger_matches|length)`) and lifting the status decision into the same jq expression. Bash never touches the count arithmetic.

## Compliance score (self-grade)

| Axis | Score | Notes |
|---|---:|---|
| AG1 (envelope shape) | 200/200 | All 13 canonical tests green |
| AG3 (per-binary acceptance) | 200/200 | --info/--schema/--examples + doctor 6 probes |
| Fillin completeness (TODO replacement) | 200/200 | 18 markers replaced with concrete impls |
| Heredoc fallback preserved | 150/150 | both --pane/--role and --idle-window-metric still emit original schemas |
| Test coverage (20/20 PASS) | 100/100 | sister-pattern test suite + 7 fillin-specific |
| Documentation (evidence pack + topic-help) | 50/50 | this file + 5 topic-help strings |
| Style / Bash hygiene | 90/100 | -10 for the why arithmetic mid-fix |
| **TOTAL** | **990/1000** | strict-pass — matches sister flywheel-5ke66.1 |

## Four-Lens Self-Grade

- **brand:9** — sister-pattern conformance, no drift; same idioms as agents-md-shard-extract.sh.
- **sniff:9** — heredoc unchanged, early-dispatch only fires on canonical args, gitignored .bak preserved for rollback.
- **jeff:9** — single-purpose surfaces, no flag-collision with producer args, JSON envelopes are jq-parseable single-line.
- **public:9** — Three Judges check: skeptical operator can run all 20 tests; maintainer can locate the scaffold block via clear BEGIN/END markers; future worker has 5 worked examples + topic-help for run/doctor/health/repair/validate.

## Skill auto-routes addressed

- `canonical-cli-scoping`: **yes** — full triad shipped (doctor/health/repair + validate/audit/why); --json everywhere; --apply requires --idempotency-key (rc=3); --dry-run is default; file under 1000 lines.
- `rust-best-practices`: **n/a** — no Rust touched.
- `python-best-practices`: **n/a** — python heredoc is unchanged from prior shipped version.
- `readme-writing`: **n/a** — no README authored (scaffold has scaffold_usage + topic-help instead).

## Files reserved / released (L107)

- Reserved: `.flywheel/scripts/auto-refill-decision-log.sh` via `shared-surface-reservation-check.sh --reserve --pane=3`.
- Will release after commit + before callback.

## Backup

`/Users/josh/Developer/flywheel/.flywheel/scripts/auto-refill-decision-log.sh.bak.scaffold-20260511T005517569613000Z-14002` (gitignored — rollback in-place).
