---
title: dispatch-log-v2-violations-doctor — substantive 18-TODO fillin
type: evidence
bead: flywheel-hpirw
task: flywheel-hpirw-f670d2
parent: flywheel-wgitr (decomposition family)
sister: flywheel-tfgt3 / flywheel-bqvpa / flywheel-vc3zs / flywheel-5kjez (wgitr-chain prior)
chain_position: 6 of 8 (penultimate; q71jb=build-dispatch-packet remaining)
worker: MistyCliff
session: flywheel
pane: 4
created: 2026-05-10
---

# Substantive fillin for dispatch-log-v2-violations-doctor.sh canonical-cli surface

## Acceptance gates (all green)

| Gate | Result | Evidence |
|---|---|---|
| AG1 — 18 TODO markers replaced with substantive impls | 0 TODOs remaining | `grep -c TODO` = 0 |
| AG2 — bash -n clean | ok | exit 0 |
| AG3 — canonical-cli-lint clean | clean, 0 violations | `lint-result.json` |
| AG4 — existing canonical-cli scaffold-test 13/13 PASS | 15/15 PASS (>floor) | `canonical-cli-test-run.txt` |
| AG5 — every subcommand returns concrete output | 6/6 substantive | `smoke-*.json`, `smoke-help-*.txt` |

## What got filled in (script — 18 TODO markers)

### `doctor` (smoke-doctor.json) — 10 substrate checks
- **wrapped binary**: validator_executable (the load-bearing dispatch-log-schema-validator.sh)
- **input data**: dispatch_log_present (the .flywheel/dispatch-log.jsonl this surface analyzes)
- **deps (4)**: jq, mktemp, awk, grep
- **config**: audit_log_dir_writable, tail_n_sane, repo_root_resolved, helper_lib_loaded

### `health` (smoke-health.json)
Reads `$SCAFFOLD_AUDIT_LOG`; computes total_runs / last_run_ts / last_status /
pass_rate / window. status = empty | warn (last fail) | pass.

### `repair` (smoke-repair-{dryrun,apply,truncate,unknown-scope,apply-no-key}.json)
Two scopes — `audit_log_dir` (mkdir -p), `audit_log_truncate` (keep last 1000).
Apply contract gate runs FIRST: `--apply` without `--idempotency-key` exits rc=3.

### `validate` (smoke-validate-{dispatch-log,audit-row,audit-row-bad}.json)
Two subjects:
- `dispatch-log [PATH]` — invokes the wrapped validator (`dispatch-log-schema-validator.sh`)
  and reports invalid count + total. Default path = $SCAFFOLD_LOG_PATH. The validator's
  full JSON output is preserved in `.detail` for downstream consumers.
- `audit-row JSONL_LINE` — verifies JSON parse + required fields (ts, status).

The dispatch-log validator self-tests against the real .flywheel/dispatch-log.jsonl
on this repo and surfaces 100/100 invalid rows — meaningful signal that there are
real V2 violations in the current log. Doctor remains pass (substrate is healthy);
validate surfaces the data-level violation.

### `audit` (smoke-audit.json)
Routes through `cli_emit_audit_tail` from canonical-cli-helpers v1.1.

### `why` (smoke-why-{rowidx,substring,miss}.json)
- numeric id → row index (negative offsets index from tail)
- non-numeric id → substring match against status / log_path / violations_count fields
  (the fields the legacy ledger-append writes)

### `--schema <surface>` + topic_help
Per-surface field documentation for all 6 subcommands; concrete topic help.

## Ledger integration

Added a single `cli_audit_append` call at the end of the legacy doctor path so
every doctor run lands in `$SCAFFOLD_AUDIT_LOG` with log_path / violations_count
fields. This is what makes audit / health / why useful end-to-end AND populates
the substring-match space for `why`.

## Test-scaffold-shape compatibility (carried from wgitr chain)

Apply contract gate runs FIRST so missing idem-key wins rc=3. Unknown scopes /
missing subjects return rc=0 with structured refusal envelopes.

## Mission fitness

Class: `adjacent`. The wrapper exposes dispatch-log V2 violations to
flywheel-loop doctor (Step 4z.1) — orchestrator self-discipline upstream of
dispatch quality, which protects continuous-orchestrator-uptime.

## Four-Lens Self-Grade

- **Brand**: 9/10 — Joshua-flavored canonical-cli matching wgitr-chain pattern.
- **Sniff**: 10/10 — every subcommand smoked end-to-end; ledger-integration
  closes audit/health/why loop; validate dispatch-log self-tests against the
  real dispatch log and surfaces 100/100 invalid rows (meaningful signal, not
  false-clean).
- **Jeff**: 8/10 — single-file edit honored; no scaffolder/helper-lib/test
  scaffold churn; ledger writes through helper API.
- **Public**: 9/10 — three judges check passes: skeptical operator can run any
  subcommand; maintainer reads evidence + smoke files; future worker has
  the wgitr-chain (tfgt3/bqvpa/hpirw + others) as worked examples for
  the final q71jb bead.

## L112 verify probe

```bash
bash .flywheel/scripts/dispatch-log-v2-violations-doctor.sh doctor --json | jq -r '.status'
# expected: pass
```
