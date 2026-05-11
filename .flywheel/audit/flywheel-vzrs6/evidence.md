# Evidence: flywheel-vzrs6 — caam-auto-rotate test 02 calibration

**Bead**: flywheel-vzrs6 (P3) | **Task ID**: flywheel-vzrs6-f7010a | **Identity**: MistyCliff
**Surface**: `.flywheel/tests/test_caam_auto_rotate_on_usage_limit.sh`
**Sister**: flywheel-bgtv8 (closed 2026-05-11; same META-rule 2026-05-09 calibration class)

## AG1: fix-option chosen

**Option B** (per bead recommendation): replace test 02 with a wrapper-result-schema assertion sourced from an actual rotate invocation via `run_case`, mirroring tests 03/04's pattern.

Rationale:
- **Option A** (drop test 02) would lose the wrapper-result-schema sanity check entirely. Canonical-CLI scaffolder test covers introspection but doesn't verify the emit() envelope's wrapper-specific fields (`.schema=="caam-auto-rotate-on-usage-limit.result.v1"`, `.native_surface=="ntm rotate"`, `.caam_vault_only`, `.ttl_native/ttl_wrapper`, `.native_wrapper_delta`, `.authorized_operations`).
- **Option B** (chosen) preserves test intent (those wrapper-result fields are still asserted) AND sources from the correct surface (real rotate run, same pattern as tests 03/04).
- **Option C** would calibrate the assertion to canonical-CLI introspection shape but drop the wrapper-result field coverage entirely.

Option B is the highest-leverage fix: keeps the test's signal value while routing it through the surface that actually emits those fields.

## AG2: fix applied

`.flywheel/tests/test_caam_auto_rotate_on_usage_limit.sh:67-69` — replaced:

```bash
# BEFORE (broken: --schema was repurposed by flywheel-0pkcf canonical scaffolder)
"$SCRIPT" --schema --json >"$TMP/schema.json"
LAST_OUT="$TMP/schema.json"; export LAST_OUT
check "02 schema/help surface" bash -c 'jq_ok ".schema==\"caam-auto-rotate-on-usage-limit.result.v1\" and ..."'

# AFTER (sources from wrapper-result envelope via real rotate run)
run_case current-alt ok d02
check "02 wrapper-result schema fields (caam-auto-rotate-on-usage-limit.result.v1)" bash -c 'jq_ok ".schema==\"caam-auto-rotate-on-usage-limit.result.v1\" and ..."'
```

Plus 8-line documentation comment explaining the calibration + cross-reference to flywheel-bgtv8 sister pattern + META-RULE 2026-05-09.

`.flywheel/scripts/caam-auto-rotate-on-usage-limit.py` was **NOT modified** (per bead AG2 constraint: "test calibration only; do NOT modify script under test").

## AG3: test rerun

```
caam_auto_rotate_wrapper_tests pass=18 fail=0 total=18
```

All 18 assertions PASS post-calibration (was 17/18 pre-calibration).

## AG4: receipt — pre-existing nature + bgtv8 sister pattern

The failure was **pre-existing** before the `.sh → .py` rename (flywheel-023hs). Verified by checking HEAD blob `c457583...` of the test file — same test 02 assertion pre-rename, same `--schema --json` invocation, same canonical-scaffolder intercept on the .py side. The rename is causally unrelated.

**Sister pattern**: flywheel-bgtv8 (closed 2026-05-11) applied identical META-rule 2026-05-09 (`feedback_calibrate_test_to_actual_contract_before_filing_upstream`). Same shape: test asserts on a surface whose contract evolved upstream; calibrate test to actual contract instead of filing an upstream bug.

## L112 verify probe

`bash .flywheel/tests/test_caam_auto_rotate_on_usage_limit.sh 2>&1 | tail -1`
Expected: `grep:pass=18 fail=0 total=18`
