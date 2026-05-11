# Journey: flywheel-0u9ch

P0 bead titled `fix-t-1-l112-mismatch`. First glance: real production task to fix an L112 verification gap for some task `t-1`.

Investigation: `t-1` / `flywheel-test` / `foo` are test fixture values. The bead was filed by `callback-fix-bead-opener.sh` when the validator's `check` subcommand auto-invoked it during test line 40 of `tests/callback-receipt-validator-canonical-cli.sh`. The validator's `open_fix_bead()` calls the real opener against `$REPO_DEFAULT` (live flywheel), polluting prod beads.

Fix: 2-line env-override patch (`CALLBACK_RECEIPT_FIX_BEAD_OPENER=/bin/true`) on test lines 40 + 43. The validator sees /bin/true as executable + a no-op; no prod bead written.

Verified: post-fix test run → 0 row delta in `.beads/issues.jsonl`.

7th instance of bead-hypothesis-is-prior-not-posterior META-rule this session.
