# Journey: flywheel-vzrs6

Test 02 failed because canonical-CLI scaffolder (flywheel-0pkcf) repurposed --schema to emit canonical-CLI introspection. The script's native --schema handler at line 519-524 became dead code. Test was asserting on stale contract.

Bead recommended Option B (replace test 02 with run_case + wrapper-result assertion). Confirmed: emit() envelope at line 454-464 contains ALL the fields test 02 was asserting (schema, native_surface, caam_vault_only, ttl_native, ttl_wrapper, native_wrapper_delta, authorized_operations).

Applied Option B. Test 02 now sources from a real rotate run (run_case current-alt ok d02) instead of --schema introspection. All 6 wrapper-result field assertions preserved.

18/18 PASS post-calibration (was 17/18). Sister of bgtv8.
