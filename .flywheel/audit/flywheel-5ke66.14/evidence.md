# Compliance Evidence Pack — flywheel-5ke66.14

Surface: `.flywheel/scripts/orch-worker-identity-manifest.sh`
Bead: flywheel-5ke66.14 (wave-2-general-14)
Parent bead: flywheel-5ke66 (jloib wave-2: P0 missing × general lane — 21 surfaces)
Identity: MagentaPond

## Summary

Third python-heredoc surface with pre-existing test suite (mirror of flywheel-5ke66.{9,12} pattern). Bash scaffold intercepts `--info`/`--schema`/`--examples` with hand-rolled hybrid envelopes preserving python-shape fields (`.dry_run_supported`, `.apply_supported`, `.no_raw_tokens`, JSON-Schema shape, `.examples` length≥3) plus AG3 fields (`.version`, `.subcommands`). New no-dash subcommands add canonical substrate probes.

Size: 337 → 878 lines (~2.6x growth). Test suite: 92 lines (20/20 PASS). Pre-existing tests: 10/10 PASS (zero regression).

## Coexistence design

Same routing pattern as 5ke66.9 / 5ke66.12:
- `doctor`, `health`, `repair`, `validate`, `audit`, `why` (no-dash) → bash scaffold
- `--info`, `--schema`, `--examples` → bash hand-rolled hybrid envelopes
- All other flags (`--fleet`, `--session`, `--apply`, `--dry-run`, `--json`) → python heredoc unchanged

## Backward-compat envelopes preserved

| Existing test assertion | Bash envelope field | Status |
|---|---|---|
| `tests:51 .dry_run_supported == true and .apply_supported == true and .no_raw_tokens == true` | All three present and true in scaffold_emit_info | PASS |
| `tests:53 .examples \| length >= 3` | 5 examples (3 original + 2 canonical) | PASS |
| `tests:55 .properties.workers.type == "array" and .properties.schema_version.const == "orch-worker-identity/v1"` | Default --schema branch preserves JSON-Schema with both fields | PASS |

## AG3 acceptance gates

| Gate | Status |
|---|---|
| `--info --json \| jq -e '.name and .version and .subcommands'` | PASS |
| `--schema --json \| jq -e '.surface and .properties.schema_version.const == "orch-worker-identity/v1"'` | PASS |
| `--examples --json \| jq -e '.examples \| length > 0'` | PASS (5 examples) |
| `doctor --json \| jq -e '.checks'` | PASS (7 probes, status=pass) |

## Per-binary fillin coverage

- **doctor (7 probes)**: python3_on_path, jq_on_path, loop_dir_readable (with marker_count), topology_readable (with row_count), agent_mail_dir_present, out_dir_writable (with manifest_count), flywheel_root_resolvable.
- **health**: tracks `manifest_count` (files in `~/.local/state/flywheel/orch-worker-identity/`) + `topology_row_count` as freshness indicators. SCAFFOLD_AUDIT_LOG separate from out_dir.
- **repair (2 scopes)**: `audit-log-rotate` + `out-dir-prime` (read-only probe of out-dir manifest count).
- **validate (5 subjects)**: `row` (uses python's emit_schema's 6 required fields: schema_version + session + generated_at + orchestrator + workers + validation), `schema`, `config`, `topology` (probes session-topology.jsonl row schema), `manifests` (probes out-dir manifest files + extracts session names).
- **audit**: cli_emit_audit_tail.
- **why**: 3 states {found, not_found, unavailable}; greps audit log for id substring (session/pane/identity).

## Live signals

```
$ orch-worker-identity-manifest.sh doctor --json | jq -c '{status, check_count: (.checks|length)}'
{"status":"pass","check_count":7}

$ orch-worker-identity-manifest.sh validate --manifests --json | jq -c
{"status":"pass","present":true,"manifest_count":5,
 "sessions":["skillos","alpsinsurance","flywheel","vrtx","mobile-eats"]}
(5 fleet sessions currently have manifests under out-dir)
```

## Regression check

`tests/orch-worker-identity-manifest.sh` baseline: 10/10 PASS before scaffold.
After scaffold: **10/10 PASS** (zero regression). All three target assertions (info_surface line 51, examples_surface line 53, schema_surface line 55) still pass.

## Compliance score (self-grade)

| Axis | Score | Notes |
|---|---:|---|
| AG1 envelope shape | 200/200 | 13 canonical tests green |
| AG3 per-binary acceptance | 200/200 | --info/--schema/--examples + doctor 7 probes |
| Fillin completeness | 200/200 | 18 markers replaced; manifests + topology probes are domain-specific |
| Heredoc fallback preserved | 150/150 | All 10 pre-existing tests pass; --fleet/--session/--apply/--dry-run flow untouched |
| Test coverage | 100/100 | 13 AG1 + 3 backward-compat + 4 fillin-specific |
| Documentation | 50/50 | this file + 5 topic-help strings + coexistence comments |
| Style / Bash hygiene | 100/100 | lint RC=0 |
| **TOTAL** | **1000/1000** | strict-pass |

## Four-Lens Self-Grade

- **brand:10** — sister-pattern conformance with 5ke66.{9,12}.
- **sniff:10** — pre-existing 10/10 tests pass unchanged; live signals show 5 sessions still produce manifests cleanly.
- **jeff:10** — validate row contract maps to python's emit_schema (6 required fields); lint clean.
- **public:10** — Three Judges check: existing tests + new tests both green; future worker has 5 worked examples including original 3.

## Skill auto-routes addressed

- `canonical-cli-scoping`: **yes** — full triad; --json everywhere; --apply requires --idempotency-key (rc=3); --dry-run is default; lint RC=0; backward-compat envelopes preserve 3 distinct python-shape assertions.
- `rust-best-practices`: **n/a**
- `python-best-practices`: **n/a** — python untouched
- `readme-writing`: **n/a**

## Files reserved/released (L107)

`.flywheel/scripts/orch-worker-identity-manifest.sh` reserved + released.

## Backup

`.flywheel/scripts/orch-worker-identity-manifest.sh.bak.scaffold-20260511T013748425007000Z-6759` (gitignored).
