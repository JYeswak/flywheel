---
title: fleet-rotate-on-caam-swap.sh canonical-CLI scaffold + 15-TODO fillin (PYTHON variant)
type: evidence
bead: flywheel-ou656
task: flywheel-ou656-5ed714
priority: P0
worker: MistyCliff (flywheel:0.4)
date: 2026-05-10
parent: flywheel-ok1sk (jloib wave-1; sub-bead 2 of 17)
sister: flywheel-0pkcf (just shipped 985 — Python pattern proven)
interpreter: python3 (despite .sh extension)
---

# Evidence — flywheel-ou656

## Surface

| Attribute | Value |
|---|---|
| Path | `.flywheel/scripts/fleet-rotate-on-caam-swap.sh` |
| Shebang | `#!/usr/bin/env python3` |
| Lines (before) | 201 |
| Lines (after) | 458 |
| Pre status | canonical_cli_scoping=missing |
| Post status | canonical_cli_scoping=passing |
| Scaffolder used | `scaffold-canonical-cli-py.sh` (sister 0pkcf precedent) |
| TODO markers | 15 |

## Sister-pattern application (0pkcf precedent)

flywheel-0pkcf shipped earlier today (985/1000) for the OTHER Python script
in this wave (caam-auto-rotate-on-usage-limit.sh). This bead applied the
SAME 4 fixes proactively (no regression catches needed):

1. **Used `scaffold-canonical-cli-py.sh`** instead of `scaffold-canonical-cli.sh` (Python interpreter)
2. **Extended `_SCAFFOLD_CANONICAL_SUBCOMMANDS_FALLBACK`** to include `doctor` + `health`
3. **Added `doctor` + `health` dispatch lines** in `_scaffold_main`
4. **Normalized `_SCAFFOLD_SCHEMA_VERSION`** to `<name>/v1` (dropped `.sh` to satisfy `^[A-Za-z0-9_-]+/v1$` regex)

Caught zero regressions live — sister-pattern memory paid off.

## Domain-specific fillins (15 TODOs)

- **Topic helps (6)**: load-bearing surface contracts named (incl. distinction
  between `$SCAFFOLD_AUDIT_LOG` and the per-rotation `LEDGER` ledger)
- **`_scaffold_cmd_doctor`**: 6 named substrate probes (ntm_executable,
  caam_executable, topology_jsonl_readable, ledger_dir_writable,
  python3_version_ok, audit_log_dir_writable) with overall rollup; tool_focus=fleet_rotation
- **`_scaffold_cmd_health`**: tails `$SCAFFOLD_AUDIT_LOG`; reports last_run_ts,
  age_seconds, recent_runs (last 20), total_runs; >24h stale → warn
- **`_scaffold_cmd_audit`**: tails `$SCAFFOLD_AUDIT_LOG` (limit=20); documents
  row_shape; explicitly notes the LEDGER vs SCAFFOLD_AUDIT_LOG distinction
- **`_scaffold_cmd_why`**: provenance lookup against `$SCAFFOLD_AUDIT_LOG`;
  matches against ts/profile/run_id/idempotency_key; 3 states

## Acceptance gates

| Gate | Result | Evidence |
|---|---|---|
| AG1: 15 TODO markers replaced | ✓ | TODO 15→0 (incl. meta-comment paraphrased) |
| AG2: Python syntax valid | ✓ | python3 ast parse-ok |
| AG3: bash lint N/A; py-test serves | ✓ | 14/14 pass |
| AG4: tests >= 13 PASS | ✓ | 14/14 PASS (10 baseline + 4 fillin) |
| AG5a: doctor 5+ named probes | ✓ | 6 probes |
| AG5b: health binds audit log | ✓ | last_run_ts + age_seconds + recent + total |
| AG5c: repair concrete | ✓ | Native argparse `--apply` path |
| AG5d: validate concrete | ✓ | Native argparse `--dry-run` mode |
| AG5e: audit cli_emit_audit_tail | ✓ | tails ledger with row_shape spec |
| AG5f: why provenance | ✓ | found / not_found / unavailable |

## L112 verify probe

```bash
cd /Users/josh/Developer/flywheel \
  && python3 -c "import ast; ast.parse(open('.flywheel/scripts/fleet-rotate-on-caam-swap.sh').read())" \
  && grep -c 'TODO(canonical-cli-scaffold)' .flywheel/scripts/fleet-rotate-on-caam-swap.sh | grep -qx 0 \
  && bash tests/fleet-rotate-on-caam-swap.sh-canonical-cli-py.sh \
  && echo "AG1-5 PASS"
# expected: AG1-5 PASS + SUMMARY pass=14 fail=0
```
