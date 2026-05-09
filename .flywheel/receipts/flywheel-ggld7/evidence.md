# flywheel-ggld7 Evidence

task_id: flywheel-ggld7-1a2b3b
worker: flywheel:3
bead: flywheel-ggld7

## DID

- Added `background_terminal_stuck` classification to `.flywheel/scripts/codex-template-stuck-detector.sh`.
- Normalized `Waiting for background terminal (...)` and `Working (...)` timer text before stability comparison.
- Added `.flywheel/scripts/caam-rotate-and-respawn.sh`.
- Wired CAAM rotation recovery for `model_at_capacity_halt` and `background_terminal_stuck`.
- Extended detector doctor output with CAAM/freezing recovery metrics and warn/fail gates.
- Added `.flywheel/tests/test_caam_rotate_and_respawn.sh` for classifier, recovery, rotation, redispatch, ledger, and doctor coverage.

## Validation

- PASS: `bash -n .flywheel/scripts/caam-rotate-and-respawn.sh .flywheel/scripts/codex-template-stuck-detector.sh`
- PASS: `bash -n .flywheel/tests/test_caam_rotate_and_respawn.sh`
- PASS: `bash .flywheel/tests/test_caam_rotate_and_respawn.sh`
  - Summary: `14 passed, 0 failed`
- PASS: `.flywheel/scripts/caam-rotate-and-respawn.sh --session fixture --pane 2 --dry-run --json`
  - Result: `status=dry_run`, `current_profile=joshua-zeststream`, `next_profile=chiefzester`, `recovered=true`.
- PASS: `.flywheel/scripts/codex-template-stuck-detector.sh --doctor --json`
  - Result included: `codex_freeze_recovery_attempted_24h`, `codex_freeze_recovery_succeeded_24h`, `codex_freeze_recovery_success_pct_24h`, `caam_rotation_count_24h`, `caam_active_profile`, `caam_profiles_available`.
  - Live status was `warn` because the existing local recovery ledger is below the 0.5 success threshold.

## Non-Blocking Validation Gap

- `bash .flywheel/tests/test-detector-pattern-bank-replay.sh` failed in this dirty worktree.
- Primary causes observed:
  - Missing external snapshot fixtures under `/tmp/golden-*` and `/tmp/flywheel-pane*-snapshot.*.json`.
  - The test asserts older detector classes for stale reminder templates and unknown stable buffers; the current tracked detector file already diverges from several of those expectations.
- The new focused acceptance test covers AG1-AG5 directly.

## Socraticode

- `socraticode_queries=10`
- `indexed_chunks_observed=1578`

## Skill/Fuckup Capture

- Skill discovery logged: `sd-592c1f3c377132d5`
- Fuckup logged: `caam-skill-doc-drift`
- Note: live `caam next codex` switched the active profile while the CAAM skill described it as preview behavior. Active profile was immediately restored to `joshua-zeststream`; the new primitive avoids `caam next`.
