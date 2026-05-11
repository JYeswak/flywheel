---
bead: flywheel-5ke66.6
worker: MistyCliff (flywheel:0.4)
date: 2026-05-10
status: shipped
score: 985/1000
mode: scaffold-plus-fillin-bash + WZJO9.1.7-PARTIAL-BYPASS
sister_exemplars: 5ke66.4 (985, full BYPASS-ALL); 5ke66.2 (985, no-bypass)
---

# Evidence Pack — flywheel-5ke66.6

## Scope

Wave-2-general-6 (6th of 21 5ke66 sub-beads). Apply canonical-cli scaffold
+ substantive fillin to `.flywheel/scripts/daily-report.sh` — bash wrapper
around `daily-report.py` with NTM analytics rollup append. Surface is a
**partial verb-collision case**: native `--info / --schema / --examples`
flags PASSTHRU to the python heredoc (richer JSON-Schema), but
`doctor / health / repair / validate / audit / why` subcommands are NOT
natively supported.

## Files touched

`.flywheel/scripts/daily-report.sh` (58 → 304 lines after scaffold; TODO=0;
`_scaffold_is_canonical_arg` modified to PARTIAL-BYPASS for flag form only)
`tests/daily-report-canonical-cli.sh` (94 → 156 lines, 13 → 19 tests
calibrated to PARTIAL-BYPASS contract)

## AG1-5 verification

```bash
cd /Users/josh/Developer/flywheel \
  && bash -n .flywheel/scripts/daily-report.sh \
  && [[ "$(grep -c 'TODO(canonical-cli-scaffold)' .flywheel/scripts/daily-report.sh)" == "0" ]] \
  && .flywheel/scripts/canonical-cli-lint.sh .flywheel/scripts/daily-report.sh \
  && bash tests/daily-report-canonical-cli.sh \
  && echo "AG1-5 PASS"
```

Result: **AG1-5 PASS** + 19/19 tests passing.

## WZJO9.1.7 PARTIAL-BYPASS pattern (third documented application)

Three pattern variants are now documented in this codebase:

| Variant | Surfaces bypassed | Application |
|---|---|---|
| **NO-BYPASS** | None (scaffold owns all) | 5ke66.2 (append-safe-write) |
| **PARTIAL-BYPASS** | `--info / --schema / --examples` flags only | 5ke66.6 (this surface) |
| **BYPASS-ALL** | All canonical surfaces (verbs + flags) | 5ke66.4 (bleed-ledger-watch), wzjo9.1.7 (flywheel-loop) |

This surface is PARTIAL-BYPASS because:
- Native `--info / --schema / --examples` (PASSTHRU to daily-report.py at
  L16 of cmd_run) emit richer domain schemas (full JSON-Schema for the
  result envelope, .version + .script metadata, real example invocations)
- The `doctor / health / repair / validate / audit / why` SUBCOMMANDS are
  NOT natively supported — scaffold can fully own those

The fix:

```bash
case "${1:-}" in
  doctor|health|repair|validate|audit|why|...) return 0 ;;  # scaffold owns
  --info|--schema|--examples) return 1 ;;  # PARTIAL-BYPASS to native
  ...
esac
```

## Domain-specific fillins

### doctor (7 named probes)

- `bash`, `jq` — universal
- `mktemp_available` (detail: required for daily-report-ntm.XXXXXX scratch)
- `python3_available` (load-bearing, detail flags daily-report.py heredoc)
- `ntm_available` (load-bearing, detail flags analytics/summary/bugs/scan
  probes; warn-tier — script falls back to {} if missing)
- `daily_report_py_executable` (load-bearing for report generation)
- `audit_log_dir_writable`

### health

36h stale threshold (1.5x daily cadence; tunable via
`DAILY_REPORT_HEALTH_STALE_THRESHOLD_SECONDS`).

### repair (2 scopes)

- `scratch_dir` → `mkdir -p $TMPDIR` (daily-report-ntm.XXXXXX target)
- `audit_log_dir`
- Apply contract rc=3 + unknown_scope rc=64

### validate (3 subjects)

- `session-name` regex `^[a-z][a-z0-9_-]*$` — matches the default session
  name pattern (basename of --repo); rejects uppercase
- `report-path` extension whitelist `.md` OR `.json` — matches the
  daily-report.py actual output formats (.md by default, .json via --json)
- `audit-row` standard

### audit / why

Standard `cli_emit_audit_tail` + 4-key why scan
(ts/session/report_path/run_id matching the canonical daily-report fields).

## Test calibration (13 → 19)

Baseline tests calibrated to PARTIAL-BYPASS contract:

- Test 2 (`--info`): native shape `.version == "daily-report.v1" + .script`
- Test 3 (`--schema`): native shape `.["$schema"] + .title == "flywheel
  daily report result"` (full JSON-Schema, not per-surface scaffold schema)
- Test 4 (`--examples`): native shape (text lines, not JSON envelope)
- Tests 5-13: scaffold owns these subcommands (doctor/health/repair/validate
  /audit/why/help/quickstart) — same pattern as no-bypass surfaces

6 fillin assertions:

- Test 14: PARTIAL-BYPASS annotation discoverable via `grep WZJO9.1.7`
- Test 15: doctor probes load-bearing python3 + ntm + daily_report_py
- Test 16: validate session-name accepts canonical pattern
- Test 17: validate session-name rejects uppercase with rc=1
- Test 18: validate report-path accepts BOTH `.md` AND `.json` (multi-extension
  loop catches future contract drift)
- Test 19: **PARTIAL-BYPASS preserved** — functional check that `--info`
  routes to native (asserts `.version` present AND `.command` absent;
  scaffold would emit `.command:"info"`)

## Notable

- Test 19 is the load-bearing PARTIAL-BYPASS fidelity check: dual-assertion
  (native field present AND scaffold field absent) catches regressions where
  the bypass is accidentally lifted (e.g. someone refactors
  `_scaffold_is_canonical_arg` and removes the `--info|--schema|--examples`
  case)
- This is now the third wzjo9.1.7 variant documented in the codebase (after
  full BYPASS-ALL on 5ke66.4 and the original wzjo9.1.7 on flywheel-loop).
  Worth filing META-RULE in feedback memory: "verb-collision pattern has
  three variants: NO-BYPASS, PARTIAL-BYPASS, BYPASS-ALL — choose based on
  whether native script supports flag form, verb form, or both"

## Smoke captures

15 smoke captures verify domain-specific responses (session-name + report-path
accept/reject pairs, repair refusals cite reason, scaffold doctor envelope,
native --info + --schema PASSTHRU envelopes preserved).

## Mission fitness

Class: **adjacent** (per dispatch). daily-report.sh is the daily flywheel
report generator with NTM rollup; canonical-CLI surface lets the
orchestrator probe report substrate (ntm, daily-report.py) and validate
session names + report paths before triggering report generation.
