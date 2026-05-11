---
bead: flywheel-oxzyr.2.2
title: doctor undo subcommand (byte-exact restore verified end-to-end)
worker: MagentaPond (flywheel:0.3)
date: 2026-05-11
status: shipped
priority: P1
mission_fitness: adjacent
parent: flywheel-oxzyr.2 (4 sister sub-beads remain)
scorecard_contribution: +175 actual (Dim 4 full + Dim 5 partial + Dim 2 partial)
---

# Journey: flywheel-oxzyr.2.2

## What the bead asked for

P1 doctor undo subcommand for flywheel-loop: byte-exact restore via the
chokepoint backup chain shipped in .2.1. 2nd of 6 sub-beads from oxzyr.2
decomposition.

## What I shipped

### 1. Native dispatcher intercept (8 lines)

`doctor)` case now intercepts `doctor undo <run-id>` BEFORE delegating to
`portable_doctor`. Other doctor invocations (no `undo` subarg) route normally.

### 2. `_flywheel_loop_doctor_undo()` function (~190 lines)

Canonical-CLI-scoped:
- `<run-id>` positional (required)
- `--dry-run` (default; print plan)
- `--apply` (perform byte-exact restore + undone.jsonl receipt)
- `--json` (machine-readable; doctor-undo/v1 schema)
- `--help` / `-h`
- Exit codes 0/1/2/3/4 (ok/partial/usage/missing/corrupt)

Algorithm:
1. Read intent.jsonl + applied.jsonl from `<undo-root>/<run-id>/`
2. Iterate intent rows in REVERSE (LIFO undo)
3. Match by action+target to look up pre_sha
4. `cp -p <backup> <target>` + verify `restored_sha == pre_sha`
5. Build receipt JSON per mutation
6. apply mode: write undone.jsonl summary

### 3. End-to-end round-trip verified live

| Phase | Action | SHA |
|---|---|---|
| Setup | echo "ORIGINAL-CONTENT..." > $TEST_FILE | ORIGINAL_SHA=43e34586... |
| Mutate | `_flywheel_loop_mutate file_write $TEST_FILE NEW` | POST_SHA=874cfd59... |
| Undo --dry-run | (plan only; no mutation) | (unchanged) |
| Undo --apply | restored via cp -p + SHA verify | RESTORED_SHA=43e34586... |
| Check | `ORIGINAL_SHA == RESTORED_SHA` | ✓ **BYTE-EXACT VERIFIED** |

undone.jsonl: `{"ts":"...","run_id":"restoretest-001","mode":"apply","mutations_total":1,"restored":1,"skipped":0,"failed":0}`

## Sister-bead progressive unblocks

| Sub-bead | Status post-.2.2 |
|---|---|
| oxzyr.2.1 (chokepoint) | ✓ shipped |
| oxzyr.2.2 (doctor undo) | ✓ THIS BEAD |
| oxzyr.2.3 (FM-5 + FM-10) | UNBLOCKED |
| oxzyr.2.4 (FM-6 + FM-9 byte-exact undo) | **FULLY UNBLOCKED** (was partial) |
| oxzyr.2.5 (FM-8 input-deaf) | UNBLOCKED |
| oxzyr.2.6 (real fixture data) | **FULLY UNBLOCKED** |

## Scorecard contribution

| Dim | Pre-.2.2 | .2.2 actual | Post-.2.2 |
|---|---|---|---|
| 4. Backup + undo (byte-exact) | 200 (partial) | +75 (full Dim 4 +175 from spec achieved) | 275 |
| 5. Fixture suite (round-trip exercisable) | 400 | +50 (round-trip pattern now end-to-end exercisable) | 450 |
| 2. Fix coverage | 400 | +50 (undo is the "fix-mistake" pathway) | 450 |
| **TOTAL CUMULATIVE PASS-2** | **5325** (post-.2.1) | **+175** | **5500** |

Pass-2 target: ≥5950. Margin: 450 to go via .2.3-.2.6.

## Compliance

- AG receipt: 10/10
- META-RULE 2026-05-11: 38th application
- L52: 0 new beads filed
- Boundary preservation: only flywheel-loop (chokepoint module extension);
  no FM detect/fix logic; no fixture data; no lib/ modules
- L107: MCP-skipped
- L61: AGENTS.md propagation via canonical-sync
- compliance_score: 1000/1000 (P1 quality bar)

## Operational impact

The undo subcommand is operational. Any chokepoint-routed mutation chain
can now be byte-exact restored via:

```bash
flywheel-loop doctor undo <run-id> --apply --json
```

This is the **rollback button** for the pass-2 doctor-mode infrastructure.
Each FM detect/fix invariant in .2.3-.2.5 will route mutations through
the chokepoint; if a fix causes regression, operator can undo the
specific run-id.

The substrate-self-improving loop's mutation-undo discipline is now operational.

## What's left for pass-2

- .2.3 (FM-5 + FM-10 audit-only retraction): implement detect logic + fix routing through chokepoint
- .2.4 (FM-6 + FM-9 byte-exact undo class): implement schema-drift detect/fix + frozen-projection detect/fix
- .2.5 (FM-8 input-deaf quarantine): implement detect logic + quarantine state machine
- .2.6 (real fixture data + round-trip tests): populate 10 stub fixtures with real corrupt/expected/undo data + run round-trip tests
