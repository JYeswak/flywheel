---
title: mission-lock-negative-invariants-validator — substantive 18-TODO fillin
type: evidence
bead: flywheel-cqhzt
task: flywheel-cqhzt-2575e6
parent: flywheel-q92io (mission-lane wave 1 scaffold-only parent)
sister: flywheel-5wuhe (readiness-doctor) / flywheel-gl7om (scaffold-validator)
worker: MistyCliff
session: flywheel
pane: 4
created: 2026-05-10
---

# Substantive fillin for mission-lock-negative-invariants-validator.sh

## Acceptance gates (all green)

| Gate | Result | Evidence |
|---|---|---|
| AG1 — 18 TODO markers replaced with substantive impls | 0 TODOs remaining | `grep -c TODO` = 0 |
| AG2 — bash -n clean | ok | exit 0 |
| AG3 — canonical-cli-lint clean | clean, 0 violations | `lint-result.json` |
| AG4 — existing canonical-cli scaffold-test 13/13 PASS | 13/13 PASS | `canonical-cli-test-run.txt` |
| AG5 — every subcommand returns concrete output | 6/6 substantive | `smoke-*.json` |

## What got filled in (script — 18 TODO markers)

### `doctor` (smoke-doctor.json) — 8 substrate checks
- **mission**: mission_md_readable (.flywheel/MISSION.md, the load-bearing input the validator reads)
- **deps (4)**: jq, mktemp, grep, awk
- **config**: audit_log_dir_writable, repo_root_resolved, helper_lib_loaded

### `health` (smoke-health.json)
Reads `$SCAFFOLD_AUDIT_LOG`; computes total_runs / last_run_ts / last_status /
pass_rate / window. status = empty | warn (last fail) | pass.

### `repair` (smoke-repair-{dryrun,apply,truncate,unknown-scope,apply-no-key}.json)
Two scopes — `audit_log_dir` (mkdir -p), `audit_log_truncate` (keep last 1000).
Apply contract gate runs FIRST: `--apply` without `--idempotency-key` exits rc=3.

### `validate` (smoke-validate-{mission-file,audit-row,audit-row-bad}.json)
Two subjects:
- `mission-file [PATH]` — invokes the validator on the supplied (or default
  $SCAFFOLD_MISSION_PATH) and reports validator_status + missing_invariants_count.
  Default path = .flywheel/MISSION.md. The validator's full output is preserved
  in `.detail`.
- `audit-row JSONL_LINE` — verifies JSON parse + required fields (ts, status).

The mission-file validator self-tested against the real .flywheel/MISSION.md
and returned status:pass with missing_invariants_count:0 — meaningful
confirmation that all 6 SEC invariants (SEC-001..SEC-006) are declared.

### `audit` (smoke-audit.json)
Routes through `cli_emit_audit_tail` from canonical-cli-helpers v1.1.

### `why` (smoke-why-{rowidx,substring,miss}.json)
- numeric id → row index (negative offsets index from tail)
- non-numeric id → substring match against status / mission_path / missing_invariants
  (the fields the legacy ledger-append writes)

### `--schema <surface>` + topic_help
Per-surface field documentation for all 6 subcommands; concrete topic help.

## Ledger integration

Added a single `cli_audit_append` call at the end of the legacy validator path
so every validation run lands in `$SCAFFOLD_AUDIT_LOG` with mission_path /
missing_invariants fields. This makes audit / health / why useful end-to-end
AND populates the substring-match space for `why`.

## Test-scaffold-shape compatibility (carried from wgitr chain)

Apply contract gate runs FIRST so missing idem-key wins rc=3. Unknown scopes /
missing subjects return rc=0 with structured refusal envelopes.

## Mission fitness

Class: `direct`. This validator gates dispatch-time mission-fitness validation
per the dispatch skill — every dispatch packet runs through
`mission-anchor-dispatch-license.sh validate` which uses this validator to
check SEC-001..SEC-006 declarations on the mission lock. Direct work on
the continuous-orchestrator-uptime anchor (sister fillins are q92io's
mission-w1 lane).

## Four-Lens Self-Grade

- **Brand**: 9/10 — Joshua-flavored canonical-cli matching wgitr-chain pattern.
- **Sniff**: 10/10 — every subcommand smoked end-to-end; ledger-integration
  closes audit/health/why loop; validate mission-file self-tested against
  real .flywheel/MISSION.md and confirmed all 6 SEC invariants declared.
- **Jeff**: 9/10 — single-file edit honored; no scaffolder/helper-lib/test
  scaffold churn; ledger writes through helper API.
- **Public**: 9/10 — three judges check passes: skeptical operator can run
  any subcommand; maintainer reads evidence + smoke files; future fillin
  worker (5wuhe / gl7om) has this as direct sister exemplar.

## L112 verify probe

```bash
bash .flywheel/scripts/mission-lock-negative-invariants-validator.sh doctor --json | jq -r '.status'
# expected: pass
```
