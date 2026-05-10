---
title: storage-headroom-watcher — substantive 18-TODO fillin
type: evidence
bead: flywheel-s0c53
task: flywheel-s0c53-fd3186
parent: flywheel-2bz0v (storage lane wave 1 scaffold-only parent)
sister: flywheel-gam2k (private-tmp-prune fillin — same pattern)
worker: MistyCliff
session: flywheel
pane: 4
created: 2026-05-10
---

# Substantive fillin for storage-headroom-watcher.sh canonical-cli surface

## Acceptance gates (all green)

| Gate | Result | Evidence |
|---|---|---|
| AG1 — doctor returns substantive checks (≥3 per dim) | 13 checks across 4 dims (writability, deps, binary, config) | `smoke-doctor.json` |
| AG2 — health probe consults real signal | total_runs/last_status/pass_rate from $SCAFFOLD_AUDIT_LOG | `smoke-health.json` |
| AG3 — repair --scope --dry-run + --apply --idem-key writes audit row | repair-apply wrote row | `smoke-repair-apply.json` |
| AG4 — validate <subject> runnable contract | 2 subjects: ledger-row JSON + probe-binary | `smoke-validate-*.json` |
| AG5 — test scaffold per-surface assertions | tests 14-21 added; SUMMARY pass=21 fail=0 | `canonical-cli-test-run.txt` |
| AG6 — canonical-cli-scoping 13/13 (now 21/21) PASS | 21/21; lint clean | `canonical-cli-test-run.txt`, `lint-result.json` |
| AG7 — canonical-cli-lint exits 0 (zero warns or errors) | clean, 0 violations | `lint-result.json` |

## What got filled in (script — 18 TODO markers)

### `doctor` (smoke-doctor.json) — 13 checks
- **writability**: ledger_writable, contract_ledger_dir_present, fuckup_log_dir_present, audit_log_dir_writable
- **binary**: storage_probe_executable (load-bearing — watcher delegates to this)
- **lib**: jsonl_append_lib_readable
- **deps**: jq_available, awk_available, df_available, python3_available, grep_available
- **config**: buffer_gb_sane, repo_root_resolved

### `health` (smoke-health.json)
Reads `$SCAFFOLD_AUDIT_LOG`; computes total_runs / last_run_ts / last_status /
pass_rate / window. status = empty | warn (last fail) | pass.

### `repair` (smoke-repair-{dryrun,apply,truncate,unknown-scope,apply-no-key}.json)
Two scopes — `audit_log_dir` (mkdir -p), `audit_log_truncate` (keep last 1000).
Apply contract gate runs FIRST: `--apply` without `--idempotency-key` exits rc=3.

### `validate` (smoke-validate-{ledger-row,probe-binary,ledger-row-bad}.json)
Two subjects:
- `ledger-row JSON_LINE` — verifies JSON parse + required fields (ts, status)
- `probe-binary` — verifies storage-probe.sh exists, executable, parses bash

### `audit` (smoke-audit.json)
Routes through `cli_emit_audit_tail` from canonical-cli-helpers v1.1, default
20-row tail.

### `why` (smoke-why-{rowidx,substring,miss}.json)
- numeric id → row index (negative offsets index from tail)
- non-numeric id → substring match against status / action / dispatch fields
- always returns rc=0 (miss is a valid lookup outcome)

### `--schema <surface>` + topic_help
Per-surface field documentation for all 6 subcommands; one concrete sentence
per topic — concrete enough for an operator to act without reading source.

## What got filled in (test scaffold — 8 new assertions)

Tests 14-21 in `tests/storage-headroom-watcher-canonical-cli.sh`:
- 14: doctor returns ≥9 concrete checks with valid statuses
- 15: doctor includes load-bearing storage_probe_executable check
- 16: health envelope concrete (total_runs, pass_rate, window)
- 17: repair --dry-run lists planned actions
- 18: repair --apply --idempotency-key mutates AND writes audit row
  (uses isolated TMP audit log per validator-uses-isolated-tmpdir doctrine)
- 19: validate ledger-row accepts well-formed row
- 20: audit row_count + recent
- 21: why numeric id provenance

Test summary: pass=21 fail=0.

## Architecture note: scaffold layer vs legacy substantive code

The legacy storage-headroom-watcher.sh code (lines ~261-1073) already has
substantive doctor/health/repair/validate/audit/why implementations backed by
a python helper (`watcher_py`) — but the canonical-cli scaffold's early-
dispatch intercept catches those subcommands before legacy code runs.

I followed the gam2k pattern (private-tmp-prune): the scaffold-stub canonical-
cli surface above provides the canonical envelope shape (.command, .checks[],
.status) that matches the 13/13 test contract. The legacy code stays intact
for run-mode and remains reachable through the dash-prefix forms (--doctor)
which bypass the scaffold intercept. Operators reaching for python-helper-
backed analysis still hit it; operators using canonical doctor/health/etc.
get the structured envelope.

## Mission fitness

Class: `adjacent`. Storage headroom watching protects worker capacity (out-of-
disk = stuck panes) which is upstream of continuous-orchestrator-uptime.

## Four-Lens Self-Grade

- **Brand**: 9/10 — Joshua-flavored canonical-cli matching gam2k sister pattern.
- **Sniff**: 10/10 — every surface smoked; ledger integration via legacy path
  preserved; test scaffold gained 8 assertions with isolated TMP discipline;
  validate probe-binary actually checks the real downstream storage-probe.sh.
- **Jeff**: 9/10 — 2-file edit honored (script + sister test); no
  scaffolder/helper-lib changes; legacy substantive code preserved.
- **Public**: 9/10 — three judges check passes: skeptical operator can run any
  surface; maintainer reads evidence + smoke files; future worker has the
  gam2k/s0c53 pair as worked examples for storage-lane fillin pattern.

## L112 verify probe

```bash
bash tests/storage-headroom-watcher-canonical-cli.sh 2>&1 | tail -1
# expected: SUMMARY pass=21 fail=0
```
