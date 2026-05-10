---
bead: flywheel-wzjo9.1.2
title: flywheel-sync canonical-CLI scaffold + 18-TODO fillin
worker: MistyCliff (flywheel:0.4)
date: 2026-05-10
status: shipped
priority: P0
mission_fitness: direct
parent_wave: flywheel-wzjo9.1
sister_exemplars: 1fk5f.{1..8} (8/8 closed avg 974/1000)
---

# Journey: flywheel-wzjo9.1.2

## What Joshua asked for

Wave 2.0a-b sub-bead: scaffold + 18-TODO fillin for `flywheel-sync` (128 lines,
P0, missing-status, has_doctor=false). Per established sister pattern (1fk5f.x).

## What I shipped

1. **Dry-run scaffold + apply** with idempotency key `flywheel-wzjo9.1.2-pilot`
2. **18 TODO markers replaced** with substantive impl (128→657 lines):
   - 7 per-surface schemas in `scaffold_emit_schema`
   - 8 single-printf topic helpers in `scaffold_emit_topic_help`
   - 8 named substrate probes in `scaffold_cmd_doctor`
   - audit-log binding in `scaffold_cmd_health` (last_run_ts, age, recent, total)
   - 2 surface-specific scopes in `scaffold_cmd_repair` (log_dir, stale_lock)
   - 3 subjects in `scaffold_cmd_validate` (config, manifest, audit-row)
   - cli_emit_audit_tail wiring in `scaffold_cmd_audit`
   - Provenance lookup in `scaffold_cmd_why` (found/not_found/unavailable)
3. **Run-side wiring**: cli_audit_append at terminal envelope (action="run"
   with mode, dry_run, force, files extras + proper exit code propagation)
4. **Test extension**: 13 → 19 tests
   - Calibrated 2 baseline tests to actual contract (sister-pattern
     `feedback_calibrate_test_to_actual_contract_before_filing_upstream` META-RULE)
   - Added 6 fillin-specific assertions (concrete checks count, flock_available
     probe presence, validate config rejection, repair concrete action, why
     canonical state, schema concrete shape)

## AG verification (all green)

| Gate | Result |
|---|---|
| AG1: 18 TODO markers replaced | ✓ (TODO count 18→0) |
| AG2: bash -n exits 0 | ✓ syntax-ok |
| AG3: canonical-cli-lint exits 0 | ✓ 0 violations |
| AG4: tests >= 13 PASS | ✓ 19/19 PASS |
| AG5a: doctor >=5 named probes | ✓ 8 probes |
| AG5b: health binds audit log | ✓ |
| AG5c: repair scope-specific | ✓ 2 scopes |
| AG5d: validate per-subject schema | ✓ 3 subjects |
| AG5e: audit cli_emit_audit_tail | ✓ |
| AG5f: why provenance | ✓ |

## Notable

- **No `[[ ]] && X || Y` last expressions** per L4 lint discipline — all
  used `if/then/else/fi` instead.
- **Doctor's `sync_remote_set` probe uses `grep`, not `source`** — extracting
  config values via `source` would execute arbitrary code if the file is
  malformed; grep is safe.
- **`stale_lock` repair uses `lsof -F p`** to identify the lock holder
  PID and `kill -0` to test if the process is alive (POSIX-portable).
- **gl7om SIGPIPE/pipefail discipline**: every topic_help body is a single
  printf (no chained printfs that would trip SIGPIPE under `set -o pipefail`).
- **Verb-collision detection**: scaffolder reported no collision (flywheel-sync
  is purely a sync tool; no doctor/health/repair existed pre-scaffold).
- **Live smoke**: doctor returns status=fail (real state — SYNC_REMOTE
  unconfigured on this machine + WAL writer-active). The fillin surfaces
  REAL substrate state rather than masking it.

## Files touched

- `~/.claude/skills/.flywheel/bin/flywheel-sync` (scaffold + 18-TODO fillin; 128→657 lines)
- `tests/flywheel-sync-canonical-cli.sh` (13 → 19 tests)
- `.flywheel/audit/flywheel-wzjo9.1.2/evidence.md` (NEW)
- `.flywheel/audit/flywheel-wzjo9.1.2/compliance-pack.md` (NEW)
- `.flywheel/audit/flywheel-wzjo9.1.2/{flywheel-sync.before,flywheel-sync.diff,smoke-doctor.json,smoke-health.json,smoke-schema-doctor.json,test-run.txt,lint.json}`
- `.flywheel/journal/flywheel-wzjo9.1.2.md` (NEW)

## .claude side note

The fix to `~/.claude/skills/.flywheel/bin/flywheel-sync` lives in the .claude
git repo. flywheel-sync IS tracked in HEAD (unlike the doctor.d/ extraction
in 9vb9i), so a clean commit is possible. Will commit ONLY this file in the
.claude repo (preserving any unrelated peer-orch in-flight work).

## Mission fitness

Class: **direct**. P0 wave-2.0a sub-bead per the wzjo9 recovery lane plan;
ships canonical-cli baseline + has_doctor on a previously-missing surface.
