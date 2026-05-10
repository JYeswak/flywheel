---
title: test-sync-canonical-doctrine — substantive 18-TODO fillin
type: evidence
bead: flywheel-zjm8v
task: flywheel-zjm8v-bd80de
parent: flywheel-frm53 (scaffold-only doctrine lane wave 1)
worker: MistyCliff
session: flywheel
pane: 4
created: 2026-05-10
---

# Substantive fillin for test-sync-canonical-doctrine.sh canonical-cli surface

## Acceptance gates (all green)

| Gate | Result | Evidence |
|---|---|---|
| AG1 — doctor returns substantive checks (≥3 per surface dimension) | 11 checks across 4 dimensions (binary, deps, dirs, helper-lib) | `smoke-doctor.json` |
| AG2 — health probe consults real signal (audit log freshness) | total_runs/last_status/pass_rate from $SCAFFOLD_AUDIT_LOG | `smoke-health-after-apply.json` |
| AG3 — repair --scope --dry-run lists planned actions; --apply --idem-key writes audit row | repair-apply wrote row; audit row_count=1 | `smoke-repair-apply.json`, `smoke-audit.json` |
| AG4 — validate <subject> has at least one runnable contract | 2 subjects: sync-binary (4 checks) + fixture-state (path layout) | `smoke-validate-sync-binary.json` |
| AG5 — tests/test-sync-canonical-doctrine-canonical-cli.sh per-surface assertions filled | 8 new assertions (tests 14-21); SUMMARY pass=21 fail=0 | `canonical-cli-test-run.txt` |
| AG6 — canonical-cli-scoping checker still 13/13 (now 21/21) PASS post-fillin | clean lint + 21/21 tests | `lint-result.json`, `canonical-cli-test-run.txt` |

## What got filled in (script — 18 TODO markers)

Six surface-specific subcommands plus per-surface --schema and topic_help:

### `doctor` (smoke-doctor.json)
11 concrete checks across 4 dimensions:
- **binary**: `sync_binary_executable` (the load-bearing target of this harness)
- **deps**: `jq_available`, `shasum_available`, `mktemp_available`, `diff_available`,
  `awk_available`, `grep_available` — every external tool the harness invokes
- **dirs**: `tmpdir_writable`, `audit_log_dir_writable`, `repo_root_resolved`
- **helper-lib**: `helper_lib_loaded` (warn-only fallback if symbols absent)

Aggregate `status` follows the canonical hierarchy: pass (none fail) | warn (some warn,
none fail) | fail (any fail).

### `health` (smoke-health-after-apply.json)
Reads `$SCAFFOLD_AUDIT_LOG`, computes:
- `total_runs` — wc -l
- `last_run_ts` + `last_status` — most recent row
- `pass_rate` — passes / sample over last 50 rows
- `status` = empty | warn (last fail) | pass

### `repair` (smoke-repair-{dryrun,apply,truncate,unknown-scope,apply-no-key}.json)
Two real scopes: `audit_log_dir` (mkdir -p the parent), `audit_log_truncate`
(keep last 1000 rows). Apply contract gate runs FIRST: `--apply` without
`--idempotency-key` exits rc=3 regardless of scope. Each `--apply` run writes
a row via `cli_audit_append`.

### `validate` (smoke-validate-{sync-binary,fixture-fail}.json)
Two subjects:
- `sync-binary` — verifies `.flywheel/scripts/sync-canonical-doctrine.sh` exists,
  is executable, parses as bash, and contains the `--apply` / `--dry-run` / `--json`
  flags this harness depends on. Returns syntax_ok + flags_ok + missing[].
- `fixture-state PATH` — verifies a TMP fixture has the expected
  `source/AGENTS.md` + `repos/` layout (matches the harness's setup).

### `audit` (smoke-audit.json)
Routes through `cli_emit_audit_tail` from canonical-cli-helpers v1.1 with default
20-row tail.

### `why` (smoke-why-{rowidx,substring,miss,substring-applied}.json)
- numeric id → row index (negative offsets index from tail)
- non-numeric id → substring match against status / action / outcome fields
- always returns rc=0 (miss is a valid lookup outcome)

### `--schema <surface>` (smoke-schema-*.json)
Per-surface field documentation for all six subcommands.

### Topic help (smoke-help-*.txt)
One concrete sentence per topic — concrete enough for an operator to act
without reading source.

## What got filled in (test scaffold — 8 new assertions)

Tests 14-21 in `tests/test-sync-canonical-doctrine-canonical-cli.sh`:
- 14: doctor returns ≥6 concrete checks with valid statuses
- 15: doctor probes the load-bearing `sync_binary_executable`
- 16: health envelope concrete (total_runs, pass_rate, window)
- 17: repair --scope audit_log_dir --dry-run lists planned actions
- 18: repair --apply --idempotency-key actually mutates AND writes audit row
  (uses isolated TMP audit log per L107 retention doctrine + memory feedback
  `feedback_validator_uses_isolated_tmpdir`)
- 19: validate sync-binary returns concrete contract envelope
- 20: audit envelope concrete (row_count + recent)
- 21: why with numeric id returns provenance envelope

Test summary: pass=21 fail=0.

## Ledger integration

Added a single `cli_audit_append` call at the end of the legacy harness path so
every test run lands in `$SCAFFOLD_AUDIT_LOG`. This is what makes audit / health /
why useful end-to-end. Best-effort: telemetry never fails the test.

## Test-scaffold-shape compatibility (carried from tfgt3)

The auto-generated 13-test scaffold expected stub-shape behavior in 3 spots
(repair refusal still emits mode field; apply contract checks idem-key BEFORE
scope validation; bare `validate --json` returns rc=0). Same reconciliation as
tfgt3: apply-contract gate runs first, refusal envelopes return rc=0 with
structured payload. The envelope is the contract; exit code is "did the process
run cleanly".

## Mission fitness

Class: `adjacent`. Doctrine sync is upstream of fleet-wide canonical AGENTS.md
freshness, which orchestrators depend on. Harden the test surface that protects
the sync = harden the substrate that protects the fleet.

## Four-Lens Self-Grade

- **Brand**: 9/10 — Joshua-flavored canonical-cli; matches mae86 / vc3zs / tfgt3
  pattern across daily-report-enabled-repos exemplar.
- **Sniff**: 10/10 — every subcommand smoked end-to-end with evidence; ledger-
  integration closes audit/health/why loop; validate sync-binary actually checks
  its real downstream dependency; test scaffold gained 8 substantive assertions
  with isolated TMP discipline (no global audit-log pollution).
- **Jeff**: 9/10 — 2-file edit honored (script + sister test only); no
  scaffolder/helper-lib changes; ledger writes through helper API.
- **Public**: 9/10 — three judges check passes: skeptical operator can run any
  surface to a meaningful answer; maintainer reads evidence.md + smoke files;
  future worker has tests 14-21 as worked examples for other doctrine-lane fillins.

## L112 verify probe

```bash
bash tests/test-sync-canonical-doctrine-canonical-cli.sh 2>&1 | tail -1
# expected: SUMMARY pass=21 fail=0
```
