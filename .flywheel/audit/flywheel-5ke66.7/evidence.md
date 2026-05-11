# Compliance Evidence Pack — flywheel-5ke66.7

Surface: `.flywheel/scripts/disk-reclaim-batch-2026-05-07.sh`
Bead: flywheel-5ke66.7 (wave-2-general-7)
Parent bead: flywheel-5ke66 (jloib wave-2: P0 missing × general lane — 21 surfaces)
Identity: MagentaPond
Worker substrate: codex-pane (Claude exec under worker-tick parity)

## Summary

Inserted canonical-CLI scaffold between the reclaim helpers (`log`, `show_disk`, `confirm`, `remove_explicit`) and the interactive three-phase flow. The original `read -p` confirm-driven reclaim path is preserved verbatim and reachable as `cmd_run` (bare invocation). Canonical subcommands intercept BEFORE any `read -p` prompt or `rm -rf` runs, so the surface is safe to probe non-interactively from automation.

Size: 178 → 730 lines (~4.1x growth). Test suite: 144 lines (20/20 PASS).

## AG3 acceptance gates

| Gate | Command | Status |
|---|---|---|
| --info | `disk-reclaim-batch-2026-05-07.sh --info --json \| jq -e '.name and .version and .subcommands'` | PASS |
| --schema | `disk-reclaim-batch-2026-05-07.sh --schema --json \| jq -e '.surface'` | PASS |
| --examples | `disk-reclaim-batch-2026-05-07.sh --examples --json \| jq -e '.examples \| length > 0'` | PASS (4 examples) |
| doctor (mutates_state=yes) | `disk-reclaim-batch-2026-05-07.sh doctor --json \| jq -e '.checks'` | PASS (6 probes, status=pass) |

## Per-binary fillin coverage

- **doctor (6 probes)**: jq_on_path, du_on_path, df_on_path, ledger_writable (with row_count), indexed_data_preservation (the Phase 3 abort-guard — present_count/missing_count/total_count across the three qdrant paths the original script protects), flywheel_root_resolvable.
- **health**: SCAFFOLD_AUDIT_LOG is the existing reclaim LEDGER (`~/.local/state/flywheel/disk-reclaim-2026-05-07.jsonl`) so health binds the live ledger per AG3. Counts ledger rows with `action="removed"` vs `action="failed"` (`removed_count`/`failed_count`).
- **repair (2 scopes + apply contract rc=3)**:
  - `audit-log-rotate` — rotates ledger when >5MB; `--apply` requires `--idempotency-key` (rc=3 refusal verified by test #8).
  - `phase-paths-prime` — read-only probe of the 21 explicit reclaim targets (13 Phase 1 + 7 Phase 2 + 1 Phase 3); reports `{phase1:{present,total},phase2:{present,total},phase3:{present,total},total_present,total_targets}`. NO `rm` performed.
- **validate (5 subjects)**: `row` (ts+action required for ledger row), `schema` (lists surfaces), `config` (probes jq/du/df/ledger-dir/root), `indexed-data` (probes qdrant safety paths with per-path size_kb), `phase-paths` (counts Phase-1/2/3 targets).
- **audit**: delegates to `cli_emit_audit_tail`; tails LEDGER with configurable `--limit`.
- **why (3 states)**: searches LEDGER for id (path substring, action, or any field); status ∈ {`found`, `not_found`, `unavailable`}.

## Live signals (today's repo state)

```
$ disk-reclaim-batch-2026-05-07.sh doctor --json | jq -c
status=pass, 6 probes pass

$ disk-reclaim-batch-2026-05-07.sh validate --phase-paths --json
phase1=0/13, phase2=0/7, phase3=1/1
total_present=1/21
(jsm scratch + beads/mobile-eats/alps scratch already reclaimed; jeff-corpus still on disk)

$ disk-reclaim-batch-2026-05-07.sh validate --indexed-data --json
present=3/3, missing=0
  ~/.socraticode/qdrant-data        685 MB
  ~/.knowledge/qdrant_server_storage 1.7 GB
  ~/.knowledge/qdrant_storage_openai 720 MB
(Phase 3 guard satisfied — abort-on-missing condition NOT triggered)
```

## Heredoc fallback verification

The original interactive flow uses `read -p` so it cannot be exercised in this non-interactive automation context. The fallback is verified structurally:

- `_scaffold_is_canonical_arg` returns 1 for any non-canonical argv[0], so the bare invocation never enters `scaffold_main`.
- Canonical args (`doctor`, `validate --phase-paths`, etc.) all exit BEFORE the `echo "============"` banner that starts the reclaim flow.
- bash -n syntax check passes; canonical-cli-lint passes RC=0.
- 20/20 tests covering all canonical surfaces pass.

## Test suite

`tests/disk-reclaim-batch-2026-05-07-canonical-cli.sh` — 20/20 PASS

Tests 1-13: AG1 canonical envelope shape (syntax, --info, --schema, --examples, doctor, health, repair --dry-run + --apply rc=3 refusal, validate, audit, why, help <topic>, quickstart).

Tests 14-20 (fillin-specific):
- Test 14: --info schema_version matches `disk-reclaim-batch-2026-05-07/v[0-9]+`.
- Test 15: --schema repair lists `audit-log-rotate` + `phase-paths-prime`.
- Test 16: doctor exposes 5+ probes incl. jq + du + df + indexed_data_preservation.
- Test 17: repair `--scope phase-paths-prime` emits non-stub envelope with all three phase breakdowns.
- Test 18: validate `--row-json` enforces ledger row schema (ts/action).
- Test 19: validate `--indexed-data` probes qdrant safety paths.
- Test 20: validate `--phase-paths` counts Phase-1/2/3 targets.

## Compliance score (self-grade)

| Axis | Score | Notes |
|---|---:|---|
| AG1 (envelope shape) | 200/200 | All 13 canonical tests green |
| AG3 (per-binary acceptance) | 200/200 | --info/--schema/--examples + doctor 6 probes |
| Fillin completeness (TODO replacement) | 200/200 | 18 markers replaced with concrete impls; phase-paths and indexed-data probes are domain-specific value-add |
| Heredoc fallback preserved | 150/150 | Structural verification (interactive flow untouched; early-dispatch precedes any `read -p` or `rm -rf`) |
| Test coverage (20/20 PASS) | 100/100 | sister-pattern test suite + 7 fillin-specific |
| Documentation (evidence pack + topic-help + safety notes) | 50/50 | this file + 5 topic-help strings + DCG safety note in scaffold_usage |
| Style / Bash hygiene | 100/100 | canonical-cli-lint RC=0; original `set -euo pipefail` preserved (no upgrade needed) |
| **TOTAL** | **1000/1000** | strict-pass — matches sister flywheel-5ke66.5 |

## Four-Lens Self-Grade

- **brand:10** — sister-pattern conformance, matches agents-md-shard-extract + auto-refill-decision-log + codex-budget-watchdog idioms.
- **sniff:10** — original interactive flow untouched; canonical surfaces are entirely read-only (no rm, no read -p); DCG-safe; indexed_data_preservation probe surfaces the same Phase 3 safety guard the script enforces internally.
- **jeff:9** — single-purpose surfaces; phase-paths probe converts the script's hard-coded path lists into a queryable presence-map; JSON envelopes are jq-parseable single-line; lint clean.
- **public:10** — Three Judges check: skeptical operator can run `validate --phase-paths` to see what would be reclaimed; maintainer can locate the scaffold block via clear BEGIN/END markers; future worker has 4 worked examples + topic-help including the DCG-blocks-rm note for run mode.

## Skill auto-routes addressed

- `canonical-cli-scoping`: **yes** — full triad shipped (doctor/health/repair + validate/audit/why); --json everywhere; --apply requires --idempotency-key (rc=3); --dry-run is default; file under 1000 lines; canonical-cli-lint RC=0.
- `rust-best-practices`: **n/a** — no Rust touched.
- `python-best-practices`: **n/a** — no Python touched.
- `readme-writing`: **n/a** — no README authored (scaffold_usage + topic-help present instead).

## Files reserved / released (L107)

- Reserved: `.flywheel/scripts/disk-reclaim-batch-2026-05-07.sh` via `shared-surface-reservation-check.sh --reserve --pane=3`.
- Will release after commit + before callback.

## Backup

`/Users/josh/Developer/flywheel/.flywheel/scripts/disk-reclaim-batch-2026-05-07.sh.bak.scaffold-20260511T011126006412000Z-32406` (gitignored — rollback in-place).
