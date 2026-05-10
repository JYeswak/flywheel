---
bead: flywheel-ou656
title: fleet-rotate-on-caam-swap.sh canonical-CLI scaffold + 15-TODO fillin (Python)
worker: MistyCliff (flywheel:0.4)
date: 2026-05-10
status: shipped
priority: P0
mission_fitness: direct
parent: flywheel-ok1sk (jloib wave-1; sub-bead 2 of 17)
sister: flywheel-0pkcf (985 — Python pattern proven)
---

# Journey: flywheel-ou656

## What Joshua asked for

Wave-1-agent-mail-2 — second of two Python scripts in the wave-1 set.
Sister flywheel-0pkcf shipped 985 minutes ago using the same py-scaffolder
pattern; sister-precedent applied.

## What I shipped

**Sister-pattern application (no regression catches needed):**
1. Used `scaffold-canonical-cli-py.sh` (sister precedent)
2. Extended `_SCAFFOLD_CANONICAL_SUBCOMMANDS_FALLBACK` to include `doctor` + `health`
3. Added dispatch lines in `_scaffold_main`
4. Normalized `_SCAFFOLD_SCHEMA_VERSION` to `<name>/v1`

**15 TODO fillins (substantive impl):**
- 6 topic helps (load-bearing surface contracts named, incl. LEDGER vs SCAFFOLD_AUDIT_LOG distinction)
- doctor: 6 named substrate probes (ntm_executable, caam_executable,
  topology_jsonl_readable, ledger_dir_writable, python3_version_ok,
  audit_log_dir_writable); tool_focus=fleet_rotation
- health: tails $SCAFFOLD_AUDIT_LOG; reports last_run_ts + age + recent + total
- audit: row_shape spec; LEDGER vs SCAFFOLD_AUDIT_LOG distinction documented
- why: matches ts/profile/run_id/idempotency_key; 3 states

**Test extension:** 10 → 14 (4 fillin assertions same shape as 0pkcf).
Orphan bash test replaced with thin pointer (sister 0pkcf precedent).

## AG verification

| Gate | Result |
|---|---|
| AG1: 15 TODO replaced | ✓ |
| AG2: python3 ast parse | ✓ |
| AG3: lint via py-test | ✓ |
| AG4: tests pass >= 13 | ✓ 14/14 |
| AG5a-f: per-surface impl | ✓ |

Strict apply-spec validation predicate (adapted for Python): **AG1-5 PASS**.

## Notable

- Sister-pattern fidelity: 0pkcf → ou656 transfer was clean (zero regression
  catches). Both required identical 4 fixes (use py scaffolder, extend
  intercept set, add dispatch lines, normalize schema_version). Confirms
  the pattern is now well-defined for Python-shebang surfaces in jloib waves.
- The script has TWO different audit ledgers:
  - `LEDGER` (`$HOME/.local/state/flywheel/fleet-rotate-on-caam-swap.jsonl`):
    per-rotation receipts emitted by the rotation execution path
  - `$SCAFFOLD_AUDIT_LOG` (`$HOME/.local/state/flywheel/fleet-rotate-on-caam-swap-runs.jsonl`):
    canonical-cli scaffold's own audit log
  - The `audit` topic_help and the `_scaffold_cmd_audit` envelope explicitly
    document this distinction so future operators don't conflate them.
- Doctor probes both `ntm_executable` AND `caam_executable` — load-bearing
  for the rotation workflow (caam swap triggers ntm rotate fleet-wide).

## Files touched

- `.flywheel/scripts/fleet-rotate-on-caam-swap.sh` (201 → 458 lines)
- `tests/fleet-rotate-on-caam-swap.sh-canonical-cli-py.sh` (10 → 14 tests)
- `tests/fleet-rotate-on-caam-swap-canonical-cli.sh` (replaced orphan with thin pointer)
- `.flywheel/audit/flywheel-ou656/{evidence,journey,compliance,smoke,test-run,diff,before}`
- `.flywheel/journal/flywheel-ou656.md`

## Mission fitness

Class: **direct**. P0 wave-1-agent-mail-2 sub-bead from ok1sk decomposition;
canonical-cli scaffold + fillin on the second Python recovery-class script
in the wave.
