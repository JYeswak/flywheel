# Compliance Evidence Pack — flywheel-5ke66.12

Surface: `.flywheel/scripts/fleet-process-gap-detector.sh`
Bead: flywheel-5ke66.12 (wave-2-general-12)
Parent bead: flywheel-5ke66 (jloib wave-2: P0 missing × general lane — 21 surfaces)
Identity: MagentaPond

## Summary

Second python-heredoc surface with pre-existing test suite (mirror of flywheel-5ke66.9 pattern). The script already exposed `--info`, `--examples`, `--schema` flag forms via python argparse, asserted by `tests/fleet-process-gap-detector.sh`. The bash scaffold intercepts `--info`/`--schema`/`--examples` with HAND-ROLLED hybrid envelopes preserving python-shape fields (`.name`, `.doctor_fields`, `.canonical_flags`, JSON-Schema shape) PLUS AG3 fields (`.version`, `.subcommands`). New no-dash subcommands add canonical substrate probes.

Size: 656 → 1200 lines (~1.8x growth). Test suite: 124 lines (20/20 PASS). Pre-existing tests: 22/22 PASS (zero regression).

## AG3 acceptance gates

| Gate | Command | Status |
|---|---|---|
| --info | `... --info --json \| jq -e '.name and .version and .subcommands'` | PASS |
| --schema | `... --schema --json \| jq -e '.schema_version'` | PASS (canonical + JSON-Schema shape preserved) |
| --examples | `... --examples --json \| jq -e '.examples \| length > 0'` | PASS (5 examples) |
| doctor (mutates_state=yes) | `... doctor --json \| jq -e '.checks'` | PASS (6 probes, status=pass) |

## Backward-compat envelopes (hand-rolled)

The bash `scaffold_emit_info` constructs envelope manually to include:
- AG3 fields: `.name`, `.version` ("scaffolded-v0"), `.subcommands`, `.sha256`
- python-shape fields preserved: `.doctor_fields` (5 fleet_process_* fields), `.canonical_flags`, `.summary`, `.mutation_requires`
- Existing test assertion `'.name == "fleet-process-gap-detector" and (.doctor_fields | index("fleet_process_health_score"))'` — PASS

The bash `scaffold_emit_schema` default branch preserves the full JSON Schema:
- `$schema`, `schema_version` (= `fleet-process-gap-detector/v1`), `type:object`, `required:[...]`
- `properties.process_health_score.maximum:100` — required by existing test:89 assertion — PASS

## Per-binary fillin coverage

- **doctor (6 probes)**: python3_on_path, jq_on_path, br_bin_executable (warn-not-fail when absent — br only invoked on --apply --idempotency-key path), fuckup_log_readable (with row_count), tick_dir_readable (with receipt_count), flywheel_root_resolvable.
- **health**: SCAFFOLD_AUDIT_LOG = `~/.local/state/flywheel/process-gap-detector/runs.jsonl`. Reports fuckup_log_rows + tick_dir_receipts as freshness signals (the two upstream sources the detector consumes).
- **repair (2 scopes + apply contract rc=3)**:
  - `audit-log-rotate` — rotates audit log when >5MB; `--apply` requires `--idempotency-key` (rc=3 verified by test #8).
  - `state-dir-prime` — read-only probe of DEFAULT_STATE_DIR (`~/.local/state/flywheel/process-gap-detector`) — counts run files.
- **validate (5 subjects)**: `row` (uses python's emit_schema contract: schema_version + checked_at + open_gap_count + top_gaps + stuck_class_count + process_health_score), `schema` (lists surfaces), `config` (probes python3/jq/br/fuckup-log/tick-dir/root), `fuckup-log` (probes fuckup-log.jsonl row count + last-row schema), `tick-dir` (probes tick-dir receipts).
- **audit**: cli_emit_audit_tail delegation.
- **why (3 states)**: greps audit log for id substring; status ∈ {found, not_found, unavailable}.

## Live signals

```
$ fleet-process-gap-detector.sh doctor --json | jq -c
status=pass, 6 probes pass
$ fleet-process-gap-detector.sh --info --json | jq -e '.name == "fleet-process-gap-detector" and (.doctor_fields | index("fleet_process_health_score"))'
true
$ fleet-process-gap-detector.sh --schema --json | jq -e '.properties.process_health_score.maximum == 100'
true
```

## Regression check vs pre-existing test

`tests/fleet-process-gap-detector.sh` baseline BEFORE scaffold: pass=22 fail=0.
After scaffold: **pass=22 fail=0** (zero regression). Both target assertions
(`info exposes doctor fields`, `schema exposes v1 score bounds`) continue passing.

## Test suite

`tests/fleet-process-gap-detector-canonical-cli.sh` — 20/20 PASS

Tests 1-13: AG1 canonical envelope shape.
Tests 14-15: backward-compat — `--info` doctor_fields includes fleet_process_health_score; `--schema` JSON-Schema preserves health_score.maximum=100.
Tests 16-20: doctor 5+ probes; repair state-dir-prime non-stub; validate row-json gap-row schema; validate fuckup-log; validate tick-dir.

## Compliance score (self-grade)

| Axis | Score | Notes |
|---|---:|---|
| AG1 envelope shape | 200/200 | All 13 canonical tests green |
| AG3 per-binary acceptance | 200/200 | --info/--schema/--examples + doctor 6 probes |
| Fillin completeness | 200/200 | 18 markers replaced; fuckup-log + tick-dir probes are upstream-source value-add |
| Heredoc fallback preserved | 150/150 | --apply / --dry-run / --idempotency-key / --json default flow falls through unchanged; pre-existing 22/22 tests still pass |
| Test coverage (20/20 PASS) | 100/100 | 13 AG1 + 2 backward-compat + 5 fillin-specific |
| Documentation | 50/50 | this file + 5 topic-help strings + coexistence design explained |
| Style / Bash hygiene | 100/100 | canonical-cli-lint RC=0; original `set -euo pipefail` already in place |
| **TOTAL** | **1000/1000** | strict-pass |

## Four-Lens Self-Grade

- **brand:10** — sister-pattern conformance; hand-rolled introspection envelopes follow flywheel-5ke66.9 precedent.
- **sniff:10** — python gap detector + br create flow untouched; pre-existing 22/22 tests still pass.
- **jeff:10** — single-purpose surfaces; validate --row-json maps to python's emit_schema contract (eats own dogfood); lint clean.
- **public:10** — Three Judges check: skeptical operator sees both old + new tests pass; maintainer has explicit coexistence comments; future worker has 5 worked examples.

## Skill auto-routes addressed

- `canonical-cli-scoping`: **yes** — full triad shipped; --json everywhere; --apply requires --idempotency-key (rc=3); --dry-run is default; canonical-cli-lint RC=0; backward-compat envelopes preserve python-shape fields.
- `rust-best-practices`: **n/a**
- `python-best-practices`: **n/a** — python heredoc untouched
- `readme-writing`: **n/a**

## Files reserved / released (L107)

- Reserved + released: `.flywheel/scripts/fleet-process-gap-detector.sh`.

## Backup

`.flywheel/scripts/fleet-process-gap-detector.sh.bak.scaffold-20260511T013219462147000Z-4635` (gitignored).
