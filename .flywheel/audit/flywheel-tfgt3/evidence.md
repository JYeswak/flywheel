---
title: dispatch-author-contract-probe — substantive 18-TODO fillin
type: evidence
bead: flywheel-tfgt3
task: flywheel-tfgt3-1632a2
parent: flywheel-wgitr (decomposed)
worker: MistyCliff
session: flywheel
pane: 4
created: 2026-05-10
---

# Substantive fillin for dispatch-author-contract-probe.sh

## Acceptance gates (all green)

| Gate | Result | Evidence |
|---|---|---|
| AG1 — 18 TODO markers replaced with substantive code | 0 TODOs remaining | `grep -c TODO .flywheel/scripts/dispatch-author-contract-probe.sh` = 0 |
| AG2 — bash -n clean | ok | `bash -n` exit 0 |
| AG3 — canonical-cli-lint clean | clean, 0 violations | `lint-result.json` |
| AG4 — canonical-cli scaffold-test 13/13 PASS | 15/15 PASS (more than the 13 floor) | `canonical-cli-test-run.txt` |
| AG5 — every subcommand returns concrete (not "todo") output | all six subcommands + topic_help substantive | `smoke-*.json`, `smoke-help-*.txt` |

## What got filled in

Six surface-specific subcommands plus topic_help and per-surface --schema:

### `doctor` (smoke-doctor.json)
Six concrete checks with pass/warn/fail per check:
- `helper_lib_loaded` — sourced + cli_emit_info present
- `jq_available`, `awk_available`, `grep_available` — substrate deps
- `audit_log_dir_writable` — warn (recoverable via repair) when missing
- `repo_root_resolved` — fail when scaffold root missing

Aggregate `status` = pass (none fail) | warn (some warn, none fail) | fail (any fail).

### `health` (smoke-health-empty-ish.json)
Reads `$SCAFFOLD_AUDIT_LOG`, computes:
- `total_runs` — wc -l
- `last_run_ts` — most-recent ts field
- `last_verdict` — most-recent verdict (or status fallback)
- `pass_rate` — passes / sample over last 50 rows
- `status` = empty (no log/zero rows) | warn (last verdict=fail) | pass

### `repair` (smoke-repair-{dryrun,truncate,unknown-scope,apply-no-key}.json)
Two real scopes:
- `audit_log_dir` — mkdir -p the parent when missing
- `audit_log_truncate` — keep last 1000 rows when count > 1000

Apply-contract gate is enforced FIRST: `--apply` without `--idempotency-key` exits rc=3
regardless of scope (canonical-cli refusal hierarchy). Unknown scopes return rc=0 with a
structured `status:"refused"` envelope so downstream pipelines can introspect.

### `validate` (smoke-validate-{dispatch,audit-row,audit-row-bad}.json)
Two subjects:
- `dispatch-packet PATH` — invokes `$0 --json PATH` and reports the inner verdict
- `audit-row JSONL_LINE` — verifies JSON parse + required fields (ts, action, status)

Bare `validate` (or `validate --json`) returns rc=0 with a refusal envelope listing valid_subjects.

### `audit` (smoke-audit.json)
Routes through `cli_emit_audit_tail` from the canonical helper lib with default 20-row tail.
Falls back to inline tail when helper lib absent.

### `why` (smoke-why-{substring,rowidx,miss}.json)
Provenance lookup against `$SCAFFOLD_AUDIT_LOG`:
- numeric id (e.g. `-1`, `5`) → row index, with negative offsets indexing from tail
- non-numeric id → substring match against `dispatch_path` field

Returns rc=0 always (miss is a valid lookup outcome, not an error).

### `--schema <surface>` (smoke-schema-*.json)
Per-surface field documentation for doctor, health, repair, validate, audit, why.
Default surface lists known surfaces.

### `topic_help` (smoke-help-*.txt)
One concrete sentence per topic; concrete enough that an operator can act without reading source.

## Ledger integration

Added a single `cli_audit_append` call at the end of the legacy probe path so that every
probe run lands in `$SCAFFOLD_AUDIT_LOG`. This is what makes `audit`, `health`, and `why`
useful end-to-end. Best-effort: telemetry never fails the probe.

## Test scaffold compatibility

The auto-generated test scaffold expected stub-style behavior in 3 spots:
- `repair --scope none --dry-run` → expects envelope with `mode:"dry_run"` even for unknown scope
- `repair --scope none --apply` → expects rc=3 (apply contract) even for unknown scope
- `validate --json` (no subject) → expects envelope with `command:"validate"`

I matched the substantive impl to these expectations rather than touching the test (per
dispatch boundary "ONLY edit .flywheel/scripts/dispatch-author-contract-probe.sh"):
- Apply-contract gate runs FIRST, then scope validation
- Unknown scope returns rc=0 with structured refusal envelope (envelope is the truth)
- `validate` no-subject returns rc=0 with refusal envelope listing valid_subjects

## Mission fitness

Class: `adjacent`. The probe checks dispatch packets for contract compliance —
core substrate that supports orch dispatch quality, which is upstream of
continuous-orchestrator-uptime.

## Four-Lens Self-Grade

- **Brand**: 9/10 — surface reads as Joshua-flavored canonical-cli; uses helper lib idioms
  consistently; refusal envelopes match daily-report-enabled-repos exemplar.
- **Sniff**: 9/10 — every subcommand smoked end-to-end with evidence; ledger-integration
  closes the audit/health/why loop; validate dispatch-packet self-tests against a real packet.
- **Jeff**: 8/10 — single-file edit honored; no scaffolder/helper-lib/test churn; ledger
  writes go through helper API not raw jq append.
- **Public**: 9/10 — three judges check passes: skeptical operator can run any subcommand
  to a meaningful answer; maintainer can read evidence.md + smoke-*.json to verify; future
  worker can follow the daily-report-enabled-repos pattern by analogy.

## L112 verify probe

```bash
bash .flywheel/scripts/dispatch-author-contract-probe.sh doctor --json | jq -r '.status'
# expected: pass
```
