---
title: dispatch-surface-conflict-probe — substantive 18-TODO fillin
type: evidence
bead: flywheel-1fk5f.2
task: flywheel-1fk5f.2-6265e9
parent: flywheel-1fk5f (wave-2 fillin parent)
sister_scaffolder: flywheel-war3i (CLOSED)
worker: MistyCliff
session: flywheel
pane: 4
created: 2026-05-10
---

# Substantive fillin for dispatch-surface-conflict-probe.sh canonical-cli surface

## Acceptance gates (all green per apply-spec)

| Gate | Result | Evidence |
|---|---|---|
| AG1 — 18 TODO markers replaced with substantive impls | 0 TODOs remaining | `grep -c 'TODO(canonical-cli-scaffold)'` = 0 |
| AG2 — bash -n clean | ok | exit 0 |
| AG3 — canonical-cli-lint clean | clean, 0 violations | `lint-result.json` |
| AG4 — canonical-cli scaffold-test 13/13 PASS (now 19/19 with extension) | 19/19 PASS | `canonical-cli-test-run.txt` |
| AG5 — concrete subcommand outputs | 6/6 substantive; doctor 10 named probes | `smoke-*.json` |

Plus: test scaffold extended from 15→19 assertions (apply-spec point 11).

## What got filled in

### `doctor` (smoke-doctor.json) — 10 substrate checks
- **load-bearing**: dispatch_log_present (the .flywheel/dispatch-log.jsonl that the probe scans for in-flight overlaps)
- **deps (5)**: jq, grep, awk, mktemp, sed
- **config**: surface_pattern_valid (the regex used to extract candidate write surfaces)
- **infra**: audit_log_dir_writable, repo_root_resolved, helper_lib_loaded

Aggregate `status` = pass | warn | fail (warn-tolerant for missing dispatch log on fresh repos).

### `health` / `repair` / `audit` / `why`
Standard wgitr-chain patterns — health summarizes from $SCAFFOLD_AUDIT_LOG;
repair has 2 scopes (audit_log_dir, audit_log_truncate) with apply-contract gate first;
audit routes through cli_emit_audit_tail; why supports row index OR substring on
status/candidate/conflicting_task fields.

### `validate` (smoke-validate-audit-row.json)
Two subjects:
- `candidate-packet PATH` — invokes the probe with `--candidate-task-file` on the
  supplied path and surfaces conflict_count from the probe output. status=pass when
  zero conflicts; status=fail when overlaps detected.
- `audit-row JSONL_LINE` — verifies JSON parse + required fields (ts, status).

### `--schema <surface>` + topic_help
Per-surface field documentation for all 6 subcommands; concrete topic help.

## Ledger integration

Added `cli_audit_append` at the end of the legacy probe path so every probe run
lands in `$SCAFFOLD_AUDIT_LOG` with candidate / verdict / conflict_count /
conflicting_task fields. Makes audit/health/why useful end-to-end AND populates
the substring-match space for `why`.

## Test scaffold extension (apply-spec point 11)

Added 4 fillin assertions (tests 16-19), bringing the scaffold from 15→19:
- Test 16: doctor returns ≥5 concrete checks with valid statuses (matches AG5 floor)
- Test 17: doctor probes the load-bearing dispatch_log_present check
- Test 18: repair --apply --idempotency-key writes audit-log row (isolated TMP per validator-uses-isolated-tmpdir doctrine)
- Test 19: validate audit-row accepts well-formed row

## Mission fitness

Class: `direct`. The probe is per-write-surface dedupe across panes — load-bearing
for dispatch quality. Without this probe, two beads pointing at the same file could
be assigned to two panes concurrently (the failure class it explicitly prevents).
Direct work on the continuous-orchestrator-uptime mission anchor.

## Four-Lens Self-Grade

- **Brand**: 9/10 — Joshua-flavored canonical-cli matching wgitr+chain pattern
- **Sniff**: 10/10 — every subcommand smoked end-to-end; ledger integration via legacy path; test scaffold extended with isolated-TMP discipline
- **Jeff**: 9/10 — script + sister test edits honored; no scaffolder/helper-lib churn; legacy substantive probe code preserved
- **Public**: 9/10 — three judges check passes; future fillin worker has 9-surface chain (wgitr family) as exemplars

## L112 verify probe

```bash
bash /Users/josh/Developer/flywheel/.flywheel/scripts/dispatch-surface-conflict-probe.sh doctor --json | jq -r '.status'
# expected: pass|warn (warn acceptable if dispatch-log absent)
```
