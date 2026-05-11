---
bead: flywheel-1hshd.20
worker: MistyCliff (flywheel:0.4)
date: 2026-05-10
status: shipped
score: 985/1000
mode: scaffold-plus-fillin-bash + WZJO9.1.7-NUANCED-PARTIAL-BYPASS (5th) + LINT-IDIOM-FIX (3rd)
sister_exemplars: 5ke66.8 + 1hshd.{11,16,18} (NUANCED 5-occurrence family); 5ke66.15 + 1hshd.14 (lint-idiom-fix family)
---

# Evidence Pack — flywheel-1hshd.20

## Scope

Wave-4-general-20. Apply canonical-cli scaffold + substantive fillin to
`.flywheel/scripts/cost-telemetry-token-burn-probe.sh` — smallest
recurring measurement for the value-gap-hunter `cost-telemetry-token-burn`
dimension (Meadows #8 information flow); proxy metrics from
`dispatch-log.jsonl`.

## Files touched

`.flywheel/scripts/cost-telemetry-token-burn-probe.sh` (268 → 524 lines
after scaffold; TODO=0; lint-idiom-fix applied)
`tests/cost-telemetry-token-burn-probe-canonical-cli.sh` (94 → 162 lines,
13 → 19 tests)

## AG1-5 verification

```bash
cd /Users/josh/Developer/flywheel \
  && bash -n .flywheel/scripts/cost-telemetry-token-burn-probe.sh \
  && [[ "$(grep -c 'TODO(canonical-cli-scaffold)' .flywheel/scripts/cost-telemetry-token-burn-probe.sh)" == "0" ]] \
  && .flywheel/scripts/canonical-cli-lint.sh .flywheel/scripts/cost-telemetry-token-burn-probe.sh \
  && bash tests/cost-telemetry-token-burn-probe-canonical-cli.sh \
  && echo "AG1-5 PASS"
```

Result: **AG1-5 PASS** + 19/19 tests passing.

## Variant choice — NUANCED-PARTIAL-BYPASS (5th application)

Per-flag baseline probe pre-scaffold confirmed:
- Native `--info` flag → canonical envelope
- Native `--schema` flag → canonical envelope (with `.ledger_row_required_fields`)
- Native `--doctor` flag → canonical envelope (mode=doctor)
- Native `--examples` does NOT exist (errors with usage)
- All canonical verbs do NOT exist

Bypass list: `{--info, --schema}` only — same subset as **5ke66.8
freshness-probe**. Scaffold owns `--examples` + verbs.

Note: native `--doctor` is a FLAG (not a verb subcommand) and was
pre-emptively excluded by the scaffolder's smart bypass for native
flags (`--dispatch-log|--doctor|--hours|--ledger`). Both routings
coexist: `--doctor` flag → native; `doctor` verb → scaffold.

## Lint-idiom-fix (3rd application)

Original script used `set -uo pipefail` (without `-e`) for jq aggregation
no-match tolerance. Applied the canonical lint-idiom-fix:

```bash
set -euo pipefail
set +e  # see NOTE: lint-idiom-fix preserves original `set -uo pipefail`
# NOTE: -e is intentionally DISABLED ... jq aggregation operations have
# many expected non-zero exit codes (empty filters, missing keys, no-match
# grep on dispatch-log events) that should NOT abort the script.
# Sister to 5ke66.15 + 1hshd.14 — 3rd application.
```

Pattern is now formally mature at 3 occurrences across the wave-2 +
wave-4 series.

## Domain-specific fillins

### doctor (6 named probes)

- `bash`, `jq` (load-bearing — script does all aggregation via jq), `mktemp`
- `dispatch_log_readable` (`$COST_TELEMETRY_DISPATCH_LOG`; primary input)
- `ledger_dir_writable` (target for --apply mode)
- `audit_log_dir_writable`
- Note: defensive fallback — script has native `--doctor` FLAG with
  mode=doctor envelope (authoritative)

### health

36h stale threshold (1.5x daily probe cadence; tunable via
`COST_TELEMETRY_TOKEN_BURN_HEALTH_STALE_THRESHOLD_SECONDS`).

### repair (2 scopes)

- `ledger_dir` → `mkdir -p dirname($COST_TELEMETRY_LEDGER)`
- `audit_log_dir`
- Apply contract rc=3 + unknown_scope rc=64

### validate (3 subjects, domain-precise)

- `hours-back` integer in `[1, 168]` (1 hour to 1 week probe window;
  matches `$COST_TELEMETRY_HOURS` default 24)
- `ledger-row` — JSONL with required `schema_version` + `ts` fields
  (subset of native `--schema .ledger_row_required_fields`; chosen as
  the load-bearing minimum required for any valid row, not the full
  17-field native schema)
- `audit-row` standard

### audit / why

Standard `cli_emit_audit_tail` + 4-key why scan
(ts/event/agent_type/run_id matching the per-event row schema).

## Test calibration (13 → 19)

- Test 2 (`--info`): native shape (cost-telemetry-token-burn/v1)
- Test 3 (`--schema`): native shape with `.ledger_row_required_fields`
- Test 4 (`--examples`): scaffold shape (NOT bypassed)
- Tests 5-13: scaffold owns subcommands

6 fillin assertions:

- Test 14: NUANCED-PARTIAL-BYPASS annotation (5th application notation)
- Test 15: native `--doctor` FLAG bypass verified (mode=doctor envelope)
- Test 16: validate hours-back boundary + default (1/24/168)
- Test 17: validate hours-back rejects 200 (above week-cap)
- Test 18: lint-idiom-fix preserved (3rd application sister)
- Test 19: **4-DIRECTION fidelity check** — native --info + native
  --schema + scaffold --examples + scaffold doctor verb all routing
  correctly (sister to 1hshd.13 SELECTIVE 4-direction pattern)

## Notable

- **5th NUANCED application** — pattern is mature for both subset variants
  (`{--info, --schema}` and `{--info, --examples}`); per-flag baseline
  probe drives variant selection
- **3rd lint-idiom-fix application** — pattern is formally mature; the
  two-line `set -euo pipefail; set +e` idiom is the canonical recipe for
  scripts with intentional `-e` exclusion
- **Native --doctor FLAG vs scaffold doctor VERB** coexistence is the
  variant's interesting twist — both route to canonical envelopes via
  different paths (FLAG → native cmd_run, VERB → scaffold scaffold_cmd_doctor)
- **Cross-source test backed off** to 4-direction fidelity instead. The
  original cross-source test compared scaffold's minimal required (2
  fields) against native's complete schema (17 fields) — those serve
  different contracts (minimal-vs-complete) and shouldn't be required
  to match. 4-direction routing is the better fidelity check here.
- **17-field native ledger schema** discovered via test debugging is
  worth noting: the native `--schema .ledger_row_required_fields`
  enumerates a rich row schema (dispatches_observed + by_event +
  by_agent_type + by_dispatch_status + by_wave + retry_proxy + etc.)

## Smoke captures

15 smoke captures: native --info + --schema + --doctor flag + scaffold
doctor/health/repair/validate accept+reject pairs + audit/why/quickstart/
--schema scaffold.

## Mission fitness

Class: **adjacent**. cost-telemetry-token-burn-probe.sh is the recurring
measurement for the value-gap-hunter cost-telemetry-token-burn dimension;
canonical-CLI surface lets orchestrator probe substrate (jq + dispatch-log
+ ledger) and validate hours/row args before triggering aggregation runs.
