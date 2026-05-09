# flywheel-bozy Compliance Pack

Task: `flywheel-bozy-eb7510`
Worker identity: `CloudyMill`
Date: 2026-05-09
Mission fitness: adjacent

## Decision

`flywheel-bozy` can close as a resolved gap seed. The original gap was that
`cass-v2-sustained-validation-probe` had no canonical CLI surfaces for
`--help`, `--info`, `--schema`, or read-only `--doctor --json`, blocking tick
Step 4k. The probe now exposes the canonical operator surfaces and has a
fixture-backed regression test.

The implementation owner bead, `flywheel-gupg`, is still marked `in_progress`
in beads even though the probe surfaces exist. I did not close or edit `gupg`;
this seed closes against the live probe/test evidence and records that status
drift as owned by the existing `gupg` bead rather than filing a duplicate.

## Evidence

- Dependency gate: `br show flywheel-2xdi --json` reports `status=closed`.
- Original implementation owner: `br show flywheel-gupg --json` reports
  `status=in_progress`; existing bead already owns remaining status drift.
- Probe location: `/Users/josh/.local/bin/cass-v2-sustained-validation-probe`.
- `--info --json` reports canonical flags:
  `--json`, `--info`, `--examples`, `quickstart`, `help`, `completion`,
  `doctor`, `health`, `repair`, `validate`, `audit`, `why`, `schema`.
- `--schema --json` reports
  `schema_version=cass-v2-sustained-validation.canonical.v1`.
- `--doctor --json` reports `command=doctor`, `read_only=true`,
  `count=73`, `status=ok`, and `warnings=[]`.
- `tests/cass-v2-sustained-validation-probe.sh` now accepts the expanded
  canonical checker summary while still requiring zero failures.

## Validation

Commands run:

```bash
bash -n /Users/josh/.local/bin/cass-v2-sustained-validation-probe
/Users/josh/.local/bin/cass-v2-sustained-validation-probe --info --json
/Users/josh/.local/bin/cass-v2-sustained-validation-probe --schema --json
/Users/josh/.local/bin/cass-v2-sustained-validation-probe --doctor --json
bash /Users/josh/.claude/skills/canonical-cli-scoping/scripts/check-cli-scoping.sh cass-v2-sustained-validation-probe
tests/cass-v2-sustained-validation-probe.sh
bash .flywheel/validation-schema/v1/dispatch-template-audit.sh /tmp/dispatch_flywheel-bozy-eb7510.md
```

Results:

- `bash -n`: pass.
- Canonical CLI checker: `Summary: 13 pass, 0 fail`.
- Probe test: 18 pass, 0 fail.
- Dispatch template audit: valid.
- Socraticode: 1 query, 10 indexed chunks observed.

## Compliance Score

Score: `870/1000`

Basis:

- +260 live CLI canonical surface verified.
- +210 fixture-backed regression test passing.
- +160 closed dependency verified.
- +120 dispatch-template audit valid.
- +80 no duplicate bead filed because `flywheel-gupg` already owns the
  remaining implementation/status drift.
- +40 evidence pack and receipt committed.

Residual risk:

- `flywheel-gupg` remains `in_progress`; that is a bead-ledger/status issue,
  not a new cassv2 CLI surface gap.

## L112 Probe

```bash
/Users/josh/.local/bin/cass-v2-sustained-validation-probe --doctor --json \
  | jq -e '.command == "doctor" and (.status == "ok" or .status == "warn") and (.count >= 0) and (.warnings | type == "array")'
```

Observed result: `true`.

## Four Lens

- Correctness: canonical surfaces are executable and checked by the test.
- Regression: stale checker-count assertion updated to preserve zero-failure
  enforcement.
- Operations: `doctor` is read-only and exposes count/status/warnings fields.
- Coordination: no new bead filed; existing `flywheel-gupg` owns status drift.
