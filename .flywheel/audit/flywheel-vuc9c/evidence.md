---
bead: flywheel-vuc9c
worker: MistyCliff (flywheel:0.4)
date: 2026-05-10
status: shipped
score: 985/1000
mode: scaffold-plus-fillin-bash
sister_exemplars: d80zq (985), ugjvq (985), 64hud (985), x0k3j (985), vs78t (985), lrdum (985), gbfpo (985), kz7o0 (985), bu0es (985), 05ost (985)
---

# Evidence Pack — flywheel-vuc9c

## Scope

Wave-1-testing-14 (14th of 17 ok1sk sub-beads; first testing-lane). Apply
canonical-cli scaffold + substantive fillin to
`.flywheel/scripts/test-fuckup-join.sh` — synthetic-fixture test that
verifies fuckup-log + processed-ledger JOIN logic excludes 3 aggregate-
processed rows (asserts old=10 / new=7 / not 6 negative-guard).

## Files touched

`.flywheel/scripts/test-fuckup-join.sh` (76 → 322 lines after scaffold; TODO=0)
`tests/test-fuckup-join-canonical-cli.sh` (94 → 154 lines, 13 → 19 tests)

## AG1-5 verification

```bash
cd /Users/josh/Developer/flywheel \
  && bash -n .flywheel/scripts/test-fuckup-join.sh \
  && [[ "$(grep -c 'TODO(canonical-cli-scaffold)' .flywheel/scripts/test-fuckup-join.sh)" == "0" ]] \
  && .flywheel/scripts/canonical-cli-lint.sh .flywheel/scripts/test-fuckup-join.sh \
  && bash tests/test-fuckup-join-canonical-cli.sh \
  && echo "AG1-5 PASS"
```

Result: **AG1-5 PASS** + 19/19 tests passing.

## Domain-specific fillins

### doctor (6 named probes — test-script focus)

- `bash`, `jq`, `mktemp` — universal
- `jq_slurpfile_supported` — **load-bearing**: the `joined_count()` jq
  filter literally requires the `--slurpfile` flag to load the processed
  ledger; without it the entire test logic is non-functional. Detail
  field annotates the dependency.
- `scratch_dir_writable` — `$TMPDIR` (default `/tmp`); the test creates
  a mktemp scratch dir for fixture files
- `audit_log_dir_writable` — `~/.local/state/flywheel`

### health

Reads `$SCAFFOLD_AUDIT_LOG`; status=warn at >7d stale (test surface,
weekly grace; tunable via TEST_FUCKUP_JOIN_HEALTH_STALE_THRESHOLD_SECONDS).

### repair (2 scopes, apply contract)

- `scratch_dir` → `mkdir -p $TMPDIR` (test fixture scratch)
- `audit_log_dir` → `mkdir -p $(dirname $SCAFFOLD_AUDIT_LOG)`
- `--apply` requires `--idempotency-key` (rc=3 refusal)
- Unknown scope rc=64 + `unknown_scope`

### validate (3 subjects, domain-precise)

- `jsonl-path` extension whitelist `.jsonl` only — matches the canonical
  fixture file names (test-fuckup-log.jsonl, test-fuckup-processed.jsonl)
  the test script writes
- `trauma-class` regex `^[a-z][a-z0-9_-]*$` — matches the fixture-
  generated values (class-1, class-2, ... class-5 per source L12);
  rejects uppercase / leading-digit
- `audit-row` — JSONL `ts` + `action` standard

### audit / why

audit uses `cli_emit_audit_tail`. why scans 3 keys (ts/test_name/run_id).

## Test extension (13 → 19, calibrated)

- Test 7 calibrated to `--scope scratch_dir` (was `none` rc=64)
- Test 9 calibrated to bare `validate` rc=64 + `missing_subject`
- 6 fillin assertions: jq_slurpfile_supported probe presence,
  jsonl-path accept canonical fixture name, jsonl-path reject .txt (rc=1),
  trauma-class accept class-1, trauma-class reject uppercase (rc=1),
  **backward-compat run-mode** verifying the original synthetic JOIN
  test still passes via cmd_run (old=10 new=7)

## Notable

- Test 19 (backward-compat) is the load-bearing fidelity check for this
  test surface — confirms that the canonical-cli scaffold does NOT break
  the original synthetic-fixture JOIN test that the script's primary
  purpose is to run. Without this test, the scaffold could pass all
  19/19 canonical-cli assertions while silently breaking the actual
  test the script exists to perform.
- jq_slurpfile_supported probe is the load-bearing diagnostic — older
  jq versions or stripped-down builds may lack `--slurpfile`, in which
  case the JOIN test would fail with cryptic errors; doctor surfaces
  this as a named explicit fail.

## Smoke captures

15 smoke captures verify domain-specific responses (jsonl-path rejection
lists valid_extensions, trauma-class rejection cites lowercase-prefix
contract, repair refusals cite reason, audit/why work against missing log).

## Mission fitness

Class: **adjacent** (per dispatch). test-fuckup-join.sh is a fleet
fuckup-log substrate verifier; making it canonical-CLI inspectable lets
the orchestrator probe the verifier's substrate before triggering test
runs and validate fixture-file paths/labels in dispatch packets.
