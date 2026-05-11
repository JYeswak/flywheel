# Evidence: flywheel-0u9ch — test pollution: validator auto-opener wrote prod bead from test fixture

**Bead**: flywheel-0u9ch (P0) | **Task ID**: flywheel-0u9ch-9b2f5b | **Identity**: MistyCliff
**Created**: 2026-05-11T03:27:26Z

## Bug shape

The bead `flywheel-0u9ch` titled `fix-t-1-l112-mismatch` was **NOT a real production task**. It was a **test-pollution artifact** filed by `callback-fix-bead-opener.sh` when invoked indirectly by the test `tests/callback-receipt-validator-canonical-cli.sh:40`.

Evidence chain:
1. Test line 40 pipes a fake DONE callback through `$SCRIPT check --callback-stdin --dispatch-file /tmp/dispatch_nonexistent.md --json` with fixture values `task_id=t-1`, `flywheel-test` bead, `l112_observed=foo`.
2. The validator's `check` subcommand detects `dispatch_file_missing` (the `/tmp/dispatch_nonexistent.md` path is intentionally missing — it's testing the REFUSE path).
3. On REFUSE, `callback-receipt-validator.sh:181` calls `open_fix_bead()` which invokes `$FIX_BEAD_OPENER` (default: `$SCRIPT_DIR/callback-fix-bead-opener.sh`) with the fixture values:
   ```bash
   $FIX_BEAD_OPENER --repo "$REPO" --task-id "t-1" --bead "flywheel-test" --reason "dispatch_file_missing" --expected "foo" --actual "" --json
   ```
4. The test did NOT override `REPO` or `CALLBACK_RECEIPT_FIX_BEAD_OPENER`, so the validator used `$REPO_DEFAULT` (the live flywheel repo) and invoked the real opener.
5. The opener called `br create` against the live `.beads/issues.jsonl` and produced bead `flywheel-0u9ch`.
6. Ledger row at `~/.local/state/flywheel/callback-fix-beads.jsonl` confirms: `{"task_id":"t-1","bead":"flywheel-test","reason":"dispatch_file_missing","expected":"foo","actual":"","dedupe_key":"t-1:dispatch_file_missing","fix_bead_id":"flywheel-0u9ch"}`.

Same root cause likely affects test line 43 (`echo "DONE bad" | ...wrapper.sh`) — the wrapper invokes the validator, same auto-opener chain.

## Fix applied

`tests/callback-receipt-validator-canonical-cli.sh` lines 40 + 43: prefixed each invocation with `CALLBACK_RECEIPT_FIX_BEAD_OPENER=/bin/true`. The validator at line 179 checks `[[ -x "$FIX_BEAD_OPENER" ]]`; `/bin/true` is executable + a no-op; the output parse at line 184 falls through to `created_unparsed` without writing any prod bead.

Added 8-line documentation comment explaining the isolation pattern for future maintainers.

## Verification

Before fix: running the test polluted the prod `.beads/issues.jsonl` (added 1 row per test run, dedupe'd on re-runs via `dedupe_lookup`).

After fix:
- Test still PASSES (21/22; pre-existing lint failure unrelated)
- Prod `.beads/issues.jsonl` row count: 1839 → 1839 (Δ=0)
- BACKWARD-COMPAT assertions on the validator's decision envelope still PASS

## Bead disposition

`flywheel-0u9ch` is a **phantom bead** representing nothing real. Closing as `no_action / test_pollution_stale_artifact`. The actual fix is the test isolation patch (above).

## Follow-up signals (out-of-scope for this bead)

1. **Validator-side defensive guard** (Meadows leverage): `callback-receipt-validator.sh` `open_fix_bead()` should refuse to invoke the real opener when:
   - `REPO` looks like a production path (e.g., `/Users/josh/Developer/flywheel`) AND
   - `task_id` matches a test-fixture shape (e.g., `^t-\d+$`, `^idem-\w+$`, `^test-`) OR
   - `bead` matches `flywheel-test` or `flywheel-parent` or other known test fixtures

   This would prevent ANY future test from polluting prod beads via the validator chain.

2. **Opener-side defensive guard**: `callback-fix-bead-opener.sh` should refuse to write to live `.beads/` when env `FLYWHEEL_TEST_MODE=1` set, OR when task_id matches test-fixture patterns.

3. **Audit pass**: scan `.beads/issues.jsonl` for other phantom `fix-*-l112-mismatch` beads created from test runs. Same fix applied here closes the leak going forward but historical pollution may exist.

## L112 verify probe

`bash -c 'BEFORE=$(wc -l < .beads/issues.jsonl); bash tests/callback-receipt-validator-canonical-cli.sh >/dev/null 2>&1; AFTER=$(wc -l < .beads/issues.jsonl); echo "delta=$((AFTER - BEFORE))"'`
Expected: `grep:delta=0`
