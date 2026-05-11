---
bead: flywheel-1hshd.11
worker: MistyCliff (flywheel:0.4)
date: 2026-05-10
status: shipped
score: 985/1000
mode: scaffold-plus-fillin-bash + WZJO9.1.7-NUANCED-PARTIAL-BYPASS + REPORT-ONLY-REPAIR-SCOPE
sister_exemplars: 5ke66.8 (985, same NUANCED variant from wave-2)
---

# Evidence Pack — flywheel-1hshd.11

## Scope

Wave-4-general-11 (FIRST wave-4 surface — under flywheel-1hshd parent
which is the "P0 partial × general lane split A — 37 surfaces" wave;
lighter than wave-2 missing baseline because some surfaces already have
partial canonical scaffold).

Apply canonical-cli scaffold + substantive fillin to
`.flywheel/scripts/canonical-root-drift-fleet-check.sh` — per-fleet
probe of canonical AGENTS.md drift; calls `sync-canonical-doctrine.sh`
per repo root and aggregates drift signals; bounded with --timeout.

## Files touched

`.flywheel/scripts/canonical-root-drift-fleet-check.sh` (215 → 461 lines
after scaffold; TODO=0)
`tests/canonical-root-drift-fleet-check-canonical-cli.sh` (94 → 162
lines, 13 → 19 tests)

## AG1-5 verification

```bash
cd /Users/josh/Developer/flywheel \
  && bash -n .flywheel/scripts/canonical-root-drift-fleet-check.sh \
  && [[ "$(grep -c 'TODO(canonical-cli-scaffold)' .flywheel/scripts/canonical-root-drift-fleet-check.sh)" == "0" ]] \
  && .flywheel/scripts/canonical-cli-lint.sh .flywheel/scripts/canonical-root-drift-fleet-check.sh \
  && bash tests/canonical-root-drift-fleet-check-canonical-cli.sh \
  && echo "AG1-5 PASS"
```

Result: **AG1-5 PASS** + 19/19 tests passing.

## Variant choice — NUANCED-PARTIAL-BYPASS

Per-flag baseline probe pre-scaffold confirmed:
- Native `--info` emits canonical envelope (`canonical-root-drift-fleet-check/v1`
  + `canonical_source` + `exit_codes` per the script's existing argparse)
- Native `--examples` emits text invocation lines
- Native `--schema` does NOT exist (errors `unknown argument`)
- Native verbs do NOT exist

Bypass list: `{--info, --examples}` only — scaffold owns `--schema` AND verbs.
This is the SAME nuanced shape as wave-2's 5ke66.8 freshness-probe; pattern
transferred mechanically.

## NEW canonical pattern — REPORT-ONLY repair scope

This surface introduces the **REPORT-ONLY repair scope** pattern. The
`sync_helper_path` scope:
- Does NOT install the helper (installation is outside this surface's
  authority — helper lives elsewhere in the repo and may have its own
  install workflow)
- Reports `.status=report` (not the usual `.status=ok`) with two
  diagnostic boolean fields: `.existed` + `.executable`
- The mode-aware `cli_audit_append --status report` distinguishes
  report-only repairs from actual mutations in the audit log

Test 19 codifies this with the `.status == "report" and has("existed")
and has("executable")` assertion. Worth a META-RULE: when a repair
scope cannot safely install/mutate (e.g. external authority owns the
target), use REPORT-ONLY contract instead of ok-with-no-action.

## Domain-specific fillins

### doctor (6 named probes)

- `bash`, `jq`, `mktemp` — universal
- `sync_helper_executable` — **load-bearing** (script invokes
  `$CANONICAL_ROOT_DRIFT_SYNC` per repo for drift detection)
- `canonical_source_readable` — `AGENTS.md` baseline; warn-tier
- `audit_log_dir_writable`

### health

12h stale threshold (intra-day drift cadence; tunable via
`CANONICAL_ROOT_DRIFT_FLEET_CHECK_HEALTH_STALE_THRESHOLD_SECONDS`).

### repair (2 scopes — first surface with REPORT-ONLY scope)

- `audit_log_dir` → standard mkdir
- `sync_helper_path` → **REPORT-ONLY**; emits `.status=report` with
  `.existed` + `.executable` booleans
- Apply contract rc=3 + unknown_scope rc=64

### validate (3 subjects, domain-precise)

- `root-path` — must be absolute (matches --root arg semantic;
  consistent with 5ke66.{2,19} absolute-only pattern)
- `timeout-seconds` — integer in `[1, 300]` matching --timeout arg
  semantic (default 10 from native usage)
- `audit-row` standard

### audit / why

Standard `cli_emit_audit_tail` + 4-key why scan
(ts/root_path/repo/run_id matching the per-repo drift row schema).

## Test calibration (13 → 19)

Baseline tests calibrated to NUANCED-PARTIAL-BYPASS:

- Test 2 (`--info`): native shape (canonical-root-drift-fleet-check/v1 +
  .canonical_source, no .command field)
- Test 3 (`--schema`): scaffold shape (.command=schema; NOT bypassed)
- Test 4 (`--examples`): native text invocations
- Tests 5-13: scaffold owns subcommands

6 fillin assertions:

- Test 14: NUANCED-PARTIAL-BYPASS annotation grep-discoverable
- Test 15: dual-direction fidelity check (--info native, --schema scaffold)
- Test 16: validate root-path rejects relative
- Test 17: validate timeout-seconds accepts default 10
- Test 18: validate timeout-seconds rejects 999 (out of [1,300])
- Test 19: **NEW REPORT-ONLY repair scope contract** assertion
  (`.status==report` + `.existed` + `.executable`)

## Notable

- First wave-4 surface shipped. Confirms wave-4 partial-baseline scripts
  apply the same recipe pattern as wave-2 missing-baseline scripts —
  the only difference is that some wave-4 scripts already have native
  flag-form introspection (this one had `--info` + `--examples`
  pre-scaffold)
- REPORT-ONLY repair scope is the first canonical pattern beyond
  the standard mkdir-based scopes. Worth formalizing in feedback memory:
  "when a repair scope's target is owned by an external authority (e.g.
  a separate install workflow), use REPORT-ONLY contract instead of
  faking a successful mkdir"
- root-path absolute-only validator is the THIRD occurrence of the
  path-arg-validators-should-be-absolute pattern (after 5ke66.2 +
  5ke66.19) — three-occurrence pattern is now mature enough for
  formal META-RULE entry

## Smoke captures

15 smoke captures verify all four route directions (--info native,
--examples native, --schema scaffold, doctor scaffold) plus all
validate subjects accept+reject pairs + REPORT-ONLY repair scope.

## Mission fitness

Class: **adjacent** (per dispatch). canonical-root-drift-fleet-check.sh
is the per-fleet probe of canonical AGENTS.md drift; canonical-CLI
surface (mixed scaffold + native) lets orchestrator probe substrate
(sync helper + canonical source) and validate root-path + timeout args
before triggering drift detection.
