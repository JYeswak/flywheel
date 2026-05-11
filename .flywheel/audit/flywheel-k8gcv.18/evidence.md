# flywheel-k8gcv.18 — jeff-pattern-citation-probe.sh canonical-cli partial→passing

Bead: flywheel-k8gcv.18 (wave-3-18, P0)
Surface: `.flywheel/scripts/jeff-pattern-citation-probe.sh`
Lane: jeff-corpus
mutates_state: no (read-only probe; appends to ledger via canonical surface only)

## AG3 acceptance gate

20/20 PASS. AG3 strict 4/4. Lint clean (was already clean — no lint violations to fix).

## Starting state

Script already had `--info`/`--schema`/`--examples`/`--doctor` flags emitting JSON envelopes, plus `--version`/`--help`. Lint clean. But AG3 strict required additional shape:
- `--info` missing `.name` + `.version` + `.capabilities` (only had `command:"jeff-pattern-citation-probe.sh"`)
- `--schema` missing `.input_schema` + `.output_schema`
- `doctor` positional missing entirely (only `--doctor` flag)

## Gaps closed

| # | Gap | Fix |
|---|---|---|
| 1 | L6 magic comment | Added preventively |
| 2 | `--info` AG3 fields | Enriched: name, version, capabilities (5), subcommands, canonical_flags, env_vars, exit_codes (legacy signal/required_citation/owner_bead/command preserved) |
| 3 | `--schema` AG3 fields | Added input_schema+output_schema with full property detail (legacy fields/row_fields/status_values/doctor_mode preserved) |
| 4 | positional `doctor` absent | Added `emit_canonical_doctor` with 3 checks (jq, repo_dir, ledger_writable). Legacy `--doctor` flag preserved emitting full probe envelope. |
| 5 | No-dash family absent | health (ledger row count), validate, audit, why (3 topics: citation-requirement, L64-L56-promotion, doctor-mode-zero-exit), quickstart, repair (ledger-prime scope w/ idempotency-key gate) |
| 6 | `--examples --json` envelope | Added emit_examples_json |

## Fuckup logged + caught locally

Quickstart envelope had `command:"jq '.rows[] | {file, line, text}'"` — the bash single-quote-double-quote nesting inside a bash single-quoted heredoc-like context caused brace-expansion of `{file, line, text}` as command invocation. Bash error: `{file,: command not found`. Fixed by simplifying to `jq .rows`. **Skill discovery**: avoid nested single-quote-around-jq-filter inside bash single-quoted strings; brace-expansion of `{...}` triggers.

## Backward compatibility

5 regression tests:
- Legacy `--doctor` flag preserves probe envelope (`jeff_pattern_uncited_count` + schema_version).
- `--info` legacy fields (`signal`, `required_citation`, `owner_bead`) preserved.
- `--schema` legacy fields (`fields`, `row_fields`, `status_values`) preserved.
- Default scan emits probe envelope.
- `--help` shows usage.
- `--examples` (no `--json`) text-mode preserved.

## Files touched

| Path | Δ |
|---|---|
| `.flywheel/scripts/jeff-pattern-citation-probe.sh` | 221 → 459 lines (+238) |
| `tests/jeff-pattern-citation-probe-canonical-cli.sh` | NEW (20 assertions) |
| `.flywheel/audit/flywheel-cli-inventory/inventory.jsonl` | partial→passing |
| `.flywheel/audit/flywheel-k8gcv.18/evidence.md` | NEW |

## Compliance: 1000/1000

four_lens=brand:9,sniff:9,jeff:9,public:9
