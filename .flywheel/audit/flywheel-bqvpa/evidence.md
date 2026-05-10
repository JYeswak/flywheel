---
title: dispatch-deferral-lint — substantive 18-TODO fillin
type: evidence
bead: flywheel-bqvpa
task: flywheel-bqvpa-849095
parent: flywheel-wgitr (decomposition family)
sister: flywheel-tfgt3 / flywheel-39vhm / flywheel-vc3zs (in-flight wgitr fillins)
worker: MistyCliff
session: flywheel
pane: 4
created: 2026-05-10
---

# Substantive fillin for dispatch-deferral-lint.sh canonical-cli surface

## Acceptance gates (all green)

| Gate | Result | Evidence |
|---|---|---|
| AG1 — 18 TODO markers replaced with substantive (non-stub) impls | 0 TODOs remaining | `grep -c TODO` = 0 |
| AG2 — bash -n clean | ok | exit 0 |
| AG3 — canonical-cli-lint clean | clean, 0 violations | `lint-result.json` |
| AG4 — existing canonical-cli scaffold-test 13/13 PASS | 15/15 PASS (>floor) | `canonical-cli-test-run.txt` |
| AG5 — every subcommand returns concrete output | 6/6 substantive | `smoke-*.json`, `smoke-help-*.txt` |

## What got filled in (script — 18 TODO markers)

### `doctor` (smoke-doctor.json) — 11 substrate checks
- **binaries (5)**: ntm_executable, br_executable, bv_executable, flywheel_loop_executable, bv_readiness_probe_executable
- **deps (3)**: jq, awk, grep
- **config**: audit_log_dir_writable, repo_root_resolved, helper_lib_loaded

Aggregate `status` follows canonical hierarchy: pass | warn | fail.

### `health` (smoke-health.json)
Reads `$SCAFFOLD_AUDIT_LOG`; computes total_runs / last_run_ts / last_status /
pass_rate / window. status = empty | warn (last fail) | pass.

### `repair` (smoke-repair-{dryrun,apply,truncate,unknown-scope,apply-no-key}.json)
Two scopes — `audit_log_dir` (mkdir -p), `audit_log_truncate` (keep last 1000).
Apply contract gate runs FIRST: `--apply` without `--idempotency-key` exits rc=3
regardless of scope (matches sister surfaces' canonical refusal hierarchy).

### `validate` (smoke-validate-{dispatch-draft,audit-row,audit-row-bad}.json)
Two subjects:
- `dispatch-draft PATH` — invokes `$0 --draft PATH --json` and reports the inner
  verdict + fail_reason (the lint's actual output fields)
- `audit-row JSONL_LINE` — verifies JSON parse + required fields (ts, status)

The dispatch-draft validator self-tests against any real packet — verified
against this very dispatch (which lints clean: status:pass, reason:ok).

### `audit` (smoke-audit.json)
Routes through `cli_emit_audit_tail` from canonical-cli-helpers v1.1.

### `why` (smoke-why-{rowidx,substring,miss}.json)
- numeric id → row index (negative offsets index from tail)
- non-numeric id → substring match against fail_reason / verdict / draft_path
  (mirrors the field names the legacy lint emits to the ledger)

### `--schema <surface>` + topic_help
Per-surface field documentation for all 6 subcommands; concrete topic help.

## Ledger integration

Added a single `cli_audit_append` call at the end of the legacy lint path so
every lint run lands in `$SCAFFOLD_AUDIT_LOG` with draft_path / verdict /
fail_reason fields. This is what makes audit / health / why useful end-to-end
AND populates the substring-match space for `why`.

## Test-scaffold-shape compatibility (carried from tfgt3 doctrine)

Apply contract gate runs FIRST so missing idem-key wins rc=3. Unknown scopes /
missing subjects return rc=0 with structured refusal envelopes. The envelope
is the contract; exit code is "did the process run cleanly".

## Mission fitness

Class: `adjacent`. The lint protects against question-shaped dispatches when
data already selects an action (canonical L70 enforcement at packet-author
time) — orchestrator self-discipline upstream of dispatch quality.

## Four-Lens Self-Grade

- **Brand**: 9/10 — Joshua-flavored canonical-cli matching tfgt3/zjm8v/s0c53 chain.
- **Sniff**: 10/10 — every subcommand smoked end-to-end; ledger-integration
  closes audit/health/why loop; validate dispatch-draft self-tests against the
  current dispatch packet; doctor probes the real downstream binaries the lint
  actually depends on.
- **Jeff**: 8/10 — single-file edit honored; no scaffolder/helper-lib/test
  scaffold churn; ledger writes through helper API.
- **Public**: 9/10 — three judges check passes: skeptical operator can run any
  subcommand; maintainer reads evidence + smoke files; future worker has
  tfgt3/zjm8v/s0c53/bqvpa as worked examples for wgitr-lane fillins.

## L112 verify probe

```bash
bash .flywheel/scripts/dispatch-deferral-lint.sh doctor --json | jq -r '.status'
# expected: pass
```
