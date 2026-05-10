---
title: beads-db-recover — substantive 18-TODO fillin
type: evidence
bead: flywheel-qprlj
task: flywheel-qprlj-adeb63
parent: flywheel-gf2rj (beads-substrate lane wave 1)
sister: flywheel-eqcsa / flywheel-dsrq1 / flywheel-ut3ng (other gf2rj children)
worker: MistyCliff
session: flywheel
pane: 4
created: 2026-05-10
---

# Substantive fillin for beads-db-recover.sh canonical-cli surface

## Acceptance gates (all green)

| Gate | Result | Evidence |
|---|---|---|
| AG1 — 18 TODO markers replaced with substantive impls | 0 TODOs remaining | `grep -c TODO` = 0 |
| AG2 — bash -n clean | ok | exit 0 |
| AG3 — canonical-cli-lint clean | clean, 0 violations | `lint-result.json` |
| AG4 — existing canonical-cli scaffold-test 13/13 PASS | 13/13 PASS | `canonical-cli-test-run.txt` |
| AG5 — every subcommand returns concrete output | 6/6 substantive | `smoke-*.json` |

## What got filled in (script — 18 TODO markers)

### `doctor` (smoke-doctor.json) — 13 substrate checks
- **binary**: br_executable (the load-bearing binary the recovery primitive delegates to)
- **input data**: beads_jsonl_present (.beads/issues.jsonl, the source of truth for recovery rebuild)
- **ledgers (2)**: recovery_ledger_dir_present, contract_ledger_dir_present
- **lib**: jsonl_append_lib_readable
- **deps (5)**: jq, sqlite3, mktemp, grep, awk
- **config**: audit_log_dir_writable, repo_root_resolved, helper_lib_loaded

### `health` (smoke-health.json)
Reads `$SCAFFOLD_AUDIT_LOG`; computes total_runs / last_run_ts / last_status /
pass_rate / window. status = empty | warn (last fail) | pass.

### `repair` (smoke-repair-{dryrun,apply,truncate,unknown-scope,apply-no-key}.json)
Two scopes — `audit_log_dir` (mkdir -p), `audit_log_truncate` (keep last 1000).
Apply contract gate runs FIRST: `--apply` without `--idempotency-key` exits rc=3.

### `validate` (smoke-validate-{beads-db,audit-row,audit-row-bad}.json)
Two subjects:
- `beads-db [PATH]` — runs `sqlite3 PRAGMA integrity_check` on the .beads/beads.db
  file (default $SCAFFOLD_BEADS_DB) and reports integrity + issue_row_count.
- `audit-row JSONL_LINE` — verifies JSON parse + required fields (ts, status).

The beads-db validator self-tested against the real .beads/beads.db on this
repo and returned status=pass with integrity=ok, issue_row_count=1592 —
meaningful signal that the substrate it's designed to recover is currently
healthy AND that the validate subject runs end-to-end (not stubbed).

### `audit` (smoke-audit.json)
Routes through `cli_emit_audit_tail` from canonical-cli-helpers v1.1.

### `why` (smoke-why-{rowidx,substring,miss}.json)
- numeric id → row index (negative offsets index from tail)
- non-numeric id → substring match against status / repo / scope fields

### `--schema <surface>` + topic_help
Per-surface field documentation for all 6 subcommands; concrete topic help.

## Architecture note: scaffold layer vs legacy substantive code

beads-db-recover.sh already had substantive doctor/health/repair/validate/
audit/why implementations in legacy code (~lines 600+). Same approach as
sister surfaces s0c53 (storage-headroom-watcher) and hpirw (dispatch-log-v2):
the scaffold-stub canonical-cli surface above provides the canonical envelope
shape (.command, .checks[], .status) that matches the 13/13 test contract.
The legacy code stays intact and remains reachable through the dash-prefix
forms (--doctor) which bypass the scaffold intercept. Operators reaching for
the rich legacy behavior (recovery flows, contract-self-row management) still
get it via dash-prefix; operators using canonical doctor/health/etc. get the
structured envelope.

## Mission fitness

Class: `direct`. The recovery primitive is what restores .beads/beads.db when
SQLite integrity_check fails — load-bearing for orchestrator workflow when
the substrate corrupts. Direct work on the continuous-orchestrator-uptime
mission anchor (matches gf2rj parent's direct fitness).

## Four-Lens Self-Grade

- **Brand**: 9/10 — Joshua-flavored canonical-cli matching wgitr+mission-chain.
- **Sniff**: 10/10 — every subcommand smoked end-to-end; validate beads-db
  self-tested against real .beads/beads.db (integrity=ok, 1592 rows confirmed).
- **Jeff**: 9/10 — single-file edit honored; no scaffolder/helper-lib/test
  scaffold churn; legacy substantive recovery code preserved.
- **Public**: 9/10 — three judges check passes: skeptical operator can run
  any subcommand (validate beads-db gives a quick health probe); maintainer
  reads evidence + smoke files; future fillin worker (eqcsa / dsrq1 / ut3ng)
  has this as direct sister exemplar for the beads-substrate lane.

## L112 verify probe

```bash
bash .flywheel/scripts/beads-db-recover.sh doctor --json | jq -r '.status'
# expected: pass
```
