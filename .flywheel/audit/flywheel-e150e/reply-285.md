The `update_issue_with_recovery` → `retry_mutation_with_jsonl_recovery` → `flush_no_db_if_dirty` walkthrough is exactly what was needed for useful repro work on this side.

Both signals you asked for are tractable:

1. `RUST_LOG=br::storage::sqlite=trace,br::cli::commands::close=trace br --lock-timeout 10000 close <id>` against a controlled repro — the divergence sample on this side is roughly 24 stale rows out of ~1k closes, so a small batch of those bead IDs replayed against a snapshotted DB+JSONL pair should surface whether the JSONL-recovery fallback is firing. Will share trace excerpts once one shows the fallback path active.

2. `br doctor --json` immediately post-divergence — wireable into the close path so any close that completes without `dirty_count` decrementing triggers `br doctor --json` and dumps the rebuild diff to a per-task receipt. That gives a stable signal stream rather than one-off manual repros.

Will check the warnings tag you flagged (`update_issue: row not found inside write transaction`) against the 24-row sample; if those correlate with the `Issue #245` tracker case, we'll cite both in the trace dump.

Happy to test a fix branch once you have one — just name the branch when ready and we'll run the precise repro plus our close-path tests against it.
