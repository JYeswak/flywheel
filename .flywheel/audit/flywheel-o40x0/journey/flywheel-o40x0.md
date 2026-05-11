# Journey: flywheel-o40x0

Bead hypothesis: race condition between sync and concurrent shard regen.
Investigation: NO race — deterministic canonicalization mismatch.

`SOURCE_HASH` was being computed via `canonicalize_source_for_hash` (markers-stripped, ~5ea3af49…) because the root_block path needs it. But the same `SOURCE_HASH` was reused at the canonical-sync cp+verify path, where target is bit-for-bit raw cp of source (raw sha ~696248f1…). The two domains never match → 145 false-positive `post_copy_hash_mismatch` errors per `--apply` run.

Fix: 13-line two-hash-domain split. Add `SOURCE_RAW_HASH` for the raw cp+verify path; leave `SOURCE_HASH` (canonicalized) for the root_block extract path.

AG3 ("status=warn instead of error for worktrees") was made unnecessary — fix the root cause, not the proxy (Meadows #5).

5/5 regression test PASSES + 9/9 + 7/7 existing tests PASS. Verified end-to-end against alpsinsurance fixture: `errors_count: 0`, `canonical_drifted_count: 0` (down from 145).
