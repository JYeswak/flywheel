# Compliance Evidence Pack — flywheel-5ke66.20

Surface: `.flywheel/scripts/topology-tick-refresh.sh`
Bead: flywheel-5ke66.20 (wave-2-general-20)
Parent bead: flywheel-5ke66 (jloib wave-2)
Identity: MagentaPond

## Summary

Python heredoc had a stub `--info` (primitive_invoked + refusal_reasons) and NO other canonical surfaces. `tests/topology-tick-refresh.sh` (16 tests) asserts on refresh/refusal behavior and ledger row shape, NOT on `--info`/`--schema` — so the bash scaffold cleanly REPLACES the stub `--info` with AG3 envelope and adds full canonical surfaces.

Size: 149 → 665 lines (~4.5x). 20/20 PASS, AG1+AG3 strict, lint RC=0. Pre-existing 16/16 PASS (zero regression).

## AG3 acceptance gates

| Gate | Status |
|---|---|
| `--info --json \| jq -e '.name and .version and .subcommands'` | PASS |
| `--schema --json \| jq -e '.surface'` | PASS |
| `--examples --json \| jq -e '.examples \| length > 0'` | PASS (4 examples) |
| `doctor --json \| jq -e '.checks'` | PASS (6 probes, status=pass) |

## Per-binary fillin coverage

- **doctor (6 probes)**: python3_on_path, jq_on_path, ntm_bin_executable (required to probe live pane shape), topology_readable (with row_count), ledger_writable (with row_count), flywheel_root_resolvable.
- **health**: SCAFFOLD_AUDIT_LOG = `~/.local/state/flywheel/topology-tick-refresh.jsonl`. Counts `refresh_count` ("status":"refreshed") + `refusal_count` ("status":"refused") from ledger.
- **repair (2 scopes)**: `audit-log-rotate` (5MB; rc=3 refusal verified by test #8) + `topology-prime` (read-only — probes session-topology.jsonl row count + size_bytes).
- **validate (5 subjects)**: `row` (uses python's LEDGER_SCHEMA: schema_version + ts + status + run_id = 4 required fields), `schema`, `config` (python3/jq/ntm/topology/ledger/root), `topology` (probes session-topology.jsonl shape), `ledger` (probes refresh ledger with refresh/refusal distribution).
- **audit**: cli_emit_audit_tail.
- **why (3 states)**: greps audit log for id substring (run_id / refusal_reason / session).

## Live signals

```
$ topology-tick-refresh.sh doctor --json | jq -c
status=pass, 6 probes pass

$ topology-tick-refresh.sh validate --topology --json
status=pass present=true row_count=1809
(session-topology.jsonl has 1809 rows currently)
```

## Test suite

`tests/topology-tick-refresh-canonical-cli.sh` — 20/20 PASS (13 AG1 + 7 fillin-specific).

## Pre-existing test regression

`tests/topology-tick-refresh.sh` baseline before scaffold: 16/16 PASS.
After scaffold: **16/16 PASS** (zero regression). The python refresh flow including --apply, --dry-run, and all 7 refusal classes (extra_agent_pane, malformed_topology_row, missing_live_session, no_topology_row, pane_count_changed, worker_kind_changed, worker_pane_missing) work identically.

## Compliance score

| Axis | Score |
|---|---:|
| AG1 envelope shape | 200/200 |
| AG3 per-binary acceptance | 200/200 |
| Fillin completeness | 200/200 |
| Heredoc fallback preserved | 150/150 |
| Test coverage (20/20) | 100/100 |
| Documentation | 50/50 |
| Style / Bash hygiene | 100/100 (lint RC=0) |
| **TOTAL** | **1000/1000** |

## Four-Lens Self-Grade

- **brand:10** — sister-pattern conformance.
- **sniff:10** — python refresh flow + 7 refusal classes untouched; pre-existing 16/16 tests pass; --info replacement is intentional (no test asserts on old stub).
- **jeff:10** — validate row schema maps to python's LEDGER_SCHEMA (4 fields); lint clean.
- **public:10** — Three Judges check: existing + new tests both green; future worker has 4 worked examples + topic-help.

## Skill auto-routes addressed

- `canonical-cli-scoping`: **yes**
- `rust-best-practices`: **n/a**
- `python-best-practices`: **n/a** — python untouched
- `readme-writing`: **n/a**

## Files reserved/released (L107)

`.flywheel/scripts/topology-tick-refresh.sh` reserved + released.

## Backup

`.flywheel/scripts/topology-tick-refresh.sh.bak.scaffold-20260511T020545943495000Z-76101` (gitignored).
