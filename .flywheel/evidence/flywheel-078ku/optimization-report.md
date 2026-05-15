# flywheel-078ku Optimization Report

## Baseline

- Command:
  `.flywheel/scripts/bead-quality-mining.sh --repo /Users/josh/Developer/flywheel --dry-run --scan-open-ag-format --json`
- Output receipt: `.flywheel/evidence/flywheel-078ku/baseline-output.json`
- Timing: `real 60.55s`, `user 24.96s`, `sys 4.42s`
- Key result: `ag_format_gap_count=157`, `open_ag_format_rows=65`

## Profile

`cProfile` showed the hotspot was not AG parsing:

- `doctor_json()` / `flywheel-loop doctor`: `60.005s`
- `br_issues()`: `0.454s`
- `existing_gap_ids()`: `0.073s`
- `validate_ag_format()`: `0.007s`

Profile summary:
`.flywheel/evidence/flywheel-078ku/profile-summary.txt`

The open AG-format scan itself is fast. The long pole is the optional
flywheel-loop doctor probe used for closed-bead doctor-signal evaluation.

## Lever

Added first-class flag:

```bash
.flywheel/scripts/bead-quality-mining.sh \
  --repo /Users/josh/Developer/flywheel \
  --dry-run \
  --scan-open-ag-format \
  --skip-loop-doctor \
  --json
```

This exposes the existing environment fast path
`BEAD_QUALITY_MINING_SKIP_FLYWHEEL_DOCTOR=1` without requiring callers to know
the environment variable.

Default semantics are unchanged. The default command still runs
`flywheel-loop doctor` because skipping it by default could weaken
closed-bead doctor-signal checks in repos where those signals exist.

## Isomorphism Proof

- Ordering preserved: yes; issue iteration order is unchanged.
- Tie-breaking unchanged: yes; no sorting or grouping changed.
- Floating point: N/A.
- RNG seeds: N/A.
- Golden output: pass for the behavior-bearing fields:
  - `ag_format_gap_count`
  - `ag_format_warning_count`
  - `closed_bead_audit_gap_count`
  - `closed_bead_audit_pending_count`
  - `closed_beads_checked`
  - `open_ag_format_rows[].bead_id`
  - `rows[].{bead_id,audit_status,gap_beads}`

Golden files:

- `.flywheel/evidence/flywheel-078ku/baseline-golden.json`
- `.flywheel/evidence/flywheel-078ku/optimized-golden.json`

## Recheck

- Optimized output: `.flywheel/evidence/flywheel-078ku/optimized-output.json`
- Timing: `real 0.85s`, `user 0.50s`, `sys 0.03s`
- Speedup: `71.24x`

Validation:

- `bash tests/bead-quality-mining.sh`
- `bash -n .flywheel/scripts/bead-quality-mining.sh tests/bead-quality-mining.sh`
