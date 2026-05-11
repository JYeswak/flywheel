# Compliance Evidence Pack — flywheel-1hshd.1

Surface: `.flywheel/scripts/adversarial-orch-self-audit-probe.sh`
Bead: flywheel-1hshd.1 (wave-4-general-1 — FIRST sub-bead of wave-4)
Parent bead: flywheel-1hshd (jloib wave-4 decomposition, closed)
Identity: MagentaPond

## Summary — first wave-4 (partial baseline) surface

Wave-4 is **P0 partial** lane: surfaces already have SOME canonical-CLI bash code. This script had `--info` / `--schema` / `--doctor` / `--health` / `--help` / `--json` as legacy dash-flag canonical surfaces (canonical-cli-lint RC=0 pre-scaffold). Gap per inventory: `--examples` flag, no-dash subcommand family, repair/validate/audit/why surfaces.

The scaffold pattern is **additive coexistence** (similar to 5ke66.18 self-referential, but for general purpose): bash scaffold adds NEW dash flag (`--examples`) + NEW no-dash subcommand family (`doctor`/`health`/`repair`/`validate`/`audit`/`why`/`quickstart`/`help`/`completion`) WHILE preserving every existing dash-flag surface verbatim.

Size: 271 → 685 lines (~2.5x — smaller than wave-2 sister exemplars because the existing partial scaffold already provided baseline structure). 21/21 PASS, AG1+AG3 strict, lint RC=0. Step_4o read-only doctrine preserved.

## Coexistence design

| Surface form | Routes to | Notes |
|---|---|---|
| `--lookback-hours N --json` | legacy | original 4-axis probe (unchanged) |
| `--info --json` | legacy | reads_only + step_4o_compliance fields preserved |
| `--schema --json` | legacy | JSON-Schema with .properties.lookback_hours/punt_phrase_count etc. |
| `--doctor --json` | legacy | mode=doctor + reads_only + step_4o_compliance |
| `--health --json` | legacy | aliases to --doctor (existing behavior) |
| `-h` / `--help` | legacy | usage() output |
| `--examples --json` | bash | NEW |
| `doctor` (no-dash) | bash | NEW substrate-probe (different from legacy mode=doctor surface) |
| `health` (no-dash) | bash | NEW audit-log-tail health |
| `repair` (no-dash) | bash | NEW with audit-log-rotate + dispatch-log-prime scopes |
| `validate` (no-dash) | bash | NEW with row/schema/config/dispatch-log/evidence-dir subjects |
| `audit` (no-dash) | bash | NEW cli_emit_audit_tail |
| `why` (no-dash) | bash | NEW 3-state grep |
| `quickstart` / `help <topic>` / `completion` | bash | NEW |

`_scaffold_is_canonical_arg` excludes `--info`/`--schema`/`--doctor`/`--health`/`-h`/`--help` so legacy fall-through.

## AG3 acceptance gates

| Gate | Status |
|---|---|
| `--info --json \| jq -e '.schema_version'` | PASS (legacy) |
| `--schema --json \| jq -e '.properties'` | PASS (legacy JSON Schema preserved) |
| `--examples --json \| jq -e '.examples \| length >= 5'` | PASS (NEW; 7 examples) |
| `doctor --json \| jq -e '.checks'` | PASS (6 probes via bash scaffold) |

## Per-binary fillin coverage

- **doctor (6 substrate probes via bash)**: jq_on_path, dispatch_log_readable (with row_count), evidence_dir_readable (with subdir_count), br_bin_executable, tmp_dispatch_dir_present, flywheel_root_resolvable.
- **health**: tracks dispatch_log_rows + evidence_subdir_count as freshness signals; SCAFFOLD_AUDIT_LOG separate from probe output.
- **repair (2 scopes)**: `audit-log-rotate` (5MB; rc=3 refusal) + `dispatch-log-prime` (read-only — probes .flywheel/dispatch-log.jsonl size).
- **validate (5 subjects)**: `row` (probe-output schema: schema_version + lookback_hours + punt_phrase_count + mission_drift_count = 4 required fields), `schema`, `config`, `dispatch-log`, `evidence-dir`.
- **audit**: cli_emit_audit_tail.
- **why**: 3 states.

## Live signals

```
$ adversarial-orch-self-audit-probe.sh doctor --json | jq -c
status=pass, 6 probes pass

$ adversarial-orch-self-audit-probe.sh --info --json | jq '.mode'
"info"
(legacy --info still works)

$ adversarial-orch-self-audit-probe.sh --examples --json | jq '.examples | length'
7
(NEW; previously --examples was rejected as "unknown arg")
```

## Test suite

`tests/adversarial-orch-self-audit-probe-canonical-cli.sh` — 21/21 PASS:
- 10 bash canonical surfaces (doctor/health/repair/validate/audit/why/help/quickstart + repair rc=3 + --examples)
- 4 BACKWARD-COMPAT (legacy --info/--schema/--doctor/--health shapes preserved)
- 7 fillin-specific (doctor probes, --schema legacy properties, repair dispatch-log-prime, validate row/dispatch-log/evidence-dir)

## Pre-existing test regression

No `tests/adversarial-orch*.sh` file in the repo — wave-4 surfaces don't all ship with pre-existing tests. Backward-compat verified by my new test file's 4 legacy-shape assertions.

## Compliance score

| Axis | Score |
|---|---:|
| AG1 envelope shape | 200/200 |
| AG3 per-binary acceptance | 200/200 |
| Fillin completeness | 200/200 (--examples + no-dash subcommand family added; legacy preserved) |
| Heredoc fallback preserved | 150/150 — all legacy dash-flag surfaces unchanged; step_4o read-only doctrine intact |
| Test coverage (21/21) | 100/100 |
| Documentation | 50/50 |
| Style / Bash hygiene | 100/100 (lint RC=0) |
| **TOTAL** | **1000/1000** |

## Four-Lens Self-Grade

- **brand:10** — wave-4 partial→passing baseline.
- **sniff:10** — step_4o read-only doctrine + all legacy surfaces preserved; 4 backward-compat tests pass.
- **jeff:10** — single-purpose surfaces; coexistence routing documented; lint clean.
- **public:10** — Three Judges check: skeptical operator can run all 21 tests including 4 legacy backward-compat; future worker sees explicit routing table.

## Skill auto-routes addressed

- `canonical-cli-scoping`: **yes** — full triad (NEW dash flag + no-dash subcommand family + legacy preserved); lint RC=0
- `rust-best-practices`: **n/a**
- `python-best-practices`: **n/a** — no python in this script
- `readme-writing`: **n/a**

## Files reserved/released (L107)

`.flywheel/scripts/adversarial-orch-self-audit-probe.sh` reserved + released.

## Backup

`.flywheel/scripts/adversarial-orch-self-audit-probe.sh.bak.scaffold-20260511T022835003934000Z-54837` (gitignored).
