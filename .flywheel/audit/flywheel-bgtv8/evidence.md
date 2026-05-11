# Evidence Pack — flywheel-bgtv8

**Bead:** flywheel-bgtv8 — `[1hshd.5-followup] 2 pre-existing failures in tests/auto-l112-gate-orch-adoption-test.sh (verified via bak revert; not introduced by 1hshd.5 fillin)`
**Identity:** MagentaPond | **Pane:** flywheel:0.3 | **Date:** 2026-05-11

## Disposition: TRIAGED + FIXED — 2/2 failures resolved via test calibration

The dispatch packet flagged 2 pre-existing failures in `tests/auto-l112-gate-orch-adoption-test.sh` with the explicit context "verified via bak revert; not introduced by 1hshd.5 fillin". This bead's triage:

- **Both failures are stale test envelopes** (not script bugs).
- **Root cause:** `br-close-with-gate.sh` now invokes `callback-envelope-schema-validator` which requires 8 quality-bar fields the test envelope didn't write.
- **Fix:** test calibration to current canonical contract — exactly the META-RULE 2026-05-09 pattern (`feedback_calibrate_test_to_actual_contract_before_filing_upstream`).

## Diagnosis

Reproduced the failure directly:

```bash
.flywheel/scripts/br-close-with-gate.sh --bead flywheel-pass --task-id task-pass \
  --callback-envelope-file pass.env --reason "fixture pass" --json
```

Output:
```json
{"status":"blocked","bead":"flywheel-pass",
 "failure_class":"callback_envelope_schema_failed",
 "schema_exit_code":3,
 "missing_fields":["quality_bar_passed","composite_score","jeff_score",
                   "donella_score","joshua_score","rust/python_clean",
                   "cli_canonical","readme_quality"]}
```

The gate emits `status:blocked` with `failure_class:callback_envelope_schema_failed` because the envelope is missing 8 required schema fields. The L112 probe (the actual unit-under-test) never gets a chance to run — the schema gate refuses earlier.

The test's `write_envelope` function only wrote 4 fields (`l112_probe_command`, `l112_probe_expected`, `l112_probe_timeout_sec`, `skill_auto_responses_addressed`). The 8 quality-bar fields the validator requires were added/extended after the test was authored.

## Fix

Extended `write_envelope` (single function-body edit at `tests/auto-l112-gate-orch-adoption-test.sh:21-30`) to write all 8 required quality-bar fields with default-pass values:

```diff
 write_envelope() {
   local file="$1" command="$2" expected="$3" timeout="${4:-5}"
+  # bead flywheel-bgtv8 (META-RULE 2026-05-09 calibrate-test-to-actual-contract):
+  # br-close-with-gate.sh now invokes callback-envelope-schema-validator which
+  # requires 8 quality-bar fields ... Write default-pass values so the gate
+  # exercise probes the L112 probe (the unit-under-test) rather than the
+  # schema-completeness gate (which is a separate concern).
   {
     printf 'l112_probe_command=%s\n' "$command"
     printf 'l112_probe_expected=%s\n' "$expected"
     printf 'l112_probe_timeout_sec=%s\n' "$timeout"
     printf 'skill_auto_routes_addressed=%s\n' "$SKILL_ROUTES"
+    printf 'quality_bar_passed=yes\n'
+    printf 'composite_score=9.5\n'
+    printf 'jeff_score=9.5\n'
+    printf 'donella_score=9.5\n'
+    printf 'joshua_score=9.5\n'
+    printf 'rust/python_clean=n/a\n'
+    printf 'cli_canonical=yes\n'
+    printf 'readme_quality=n/a\n'
   } >"$file"
 }
```

Default-pass values chosen to keep the test focused on the L112 PROBE behavior (which IS what these tests are exercising) rather than the schema-completeness gate (which is a separate concern with its own tests).

For the failing-probe test (`grep:OK` against `printf 'NO\n'`), the L112 probe still correctly fails after the schema gate passes — `gate_status:gate_fail` + `close_allowed:false` + `fix_bead_id:flywheel-fixmock` all assert correctly.

## Verification

| Metric | Before | After |
|---|---|---|
| `tests/auto-l112-gate-orch-adoption-test.sh` | pass=1 fail=2 | pass=3 fail=0 |
| Failures cleared | — | passing_probe_allows_close_and_logs_gate_pass + failing_probe_blocks_close_and_logs_fix_bead |
| Script behavior | unchanged | unchanged (test calibration only) |

Evidence: `test-run-before.txt` + `test-run-after.txt` + `test-calibration.diff`.

## What was NOT changed

- `.flywheel/scripts/br-close-with-gate.sh` — untouched (its current behavior IS the canonical truth)
- `.flywheel/scripts/callback-envelope-schema-validator.sh` — untouched (validator's 8-field schema is the canonical contract)
- `.flywheel/scripts/auto-l112-gate.sh` — untouched (the actual gate behavior is what the test was supposed to exercise)
- Anything else — pure test-side calibration

## AG receipt

Implicit acceptance criteria from bead title:
- AG1: triage 2 pre-existing failures — DONE (root cause: schema validator's 8-field requirement post-dates the test)
- AG2: verify zero delta to scripts under test — DONE (only `tests/auto-l112-gate-orch-adoption-test.sh` touched; gate + validator + close-with-gate untouched)
- AG3: fix the failures or document why deferred — SHIPPED (2/2 cleared in this tick)

did=3/3

## Skill Auto-Routes

| Skill | Status | Evidence |
|---|---|---|
| canonical-cli-scoping | n/a | test calibration only |
| rust-best-practices | n/a | bash test |
| python-best-practices | n/a | bash test |
| readme-writing | n/a | no README |

## Doctrine reference

`feedback_calibrate_test_to_actual_contract_before_filing_upstream.md` (META-RULE 2026-05-09): when a flywheel test fails because upstream behavior diverges, calibrate test to upstream's actual current contract first; "our test fails" is not "upstream bug"; cite contract or file documentation issue, not "fix it".

This bead is the second clean instance of that META-RULE in this session (after `flywheel-llud2`). The "upstream" here is the script under test (which evolved to require schema fields the test wasn't writing). Both were correct at their current states; the test was stale.

## Compliance Score

| Dimension | Points | Evidence |
|---|---|---|
| Both failures triaged | 200/200 | root cause identified (schema validator's 8-field requirement post-dates test) |
| Both failures fixed | 300/300 | 3/0 PASS post-fix (was 1/2) |
| Test calibration discipline (no script change) | 200/200 | only `tests/auto-l112-gate-orch-adoption-test.sh` touched; scripts untouched |
| META-RULE 2026-05-09 cited inline | 100/100 | comment + commit + evidence |
| Diff has explanatory inline comments | 100/100 | function-body comment explains rationale |
| Default-pass values keep test focus on L112 probe | 50/50 | rationale documented in comment |
| Reservations released; no peer collisions | 50/50 | L107 release receipts |
| **TOTAL** | **1000/1000** | |

`compliance_score=1000/1000`

## L112 Verify Probe

```bash
bash tests/auto-l112-gate-orch-adoption-test.sh 2>&1 | grep -E '^SUMMARY'
```
Expected: `grep:pass=3 fail=0`. Timeout 30s.
