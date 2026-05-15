# Worker Tick Shared Append Stable Tail

Shared append files are coordination surfaces, not scratchpads. A worker tick
that touches `INCIDENTS.md`, `.beads/issues.jsonl`, AGENTS surfaces, or shared
JSONL ledgers must treat the tail as live state until the final write is
verified.

Apply this checklist before DONE, BLOCKED, or callback:

1. Reserve the shared path before editing.
2. Re-read the tail immediately before appending.
3. Append only at EOF.
4. Verify the appended marker is present after the write.
5. Run the relevant dispatch/close validation.
6. Release reservations.
7. Report reserved paths, released paths, and the stable-tail method in the
   callback.

This doctrine anchors the memory rule
`feedback_worker_tick_shared_append_stable_tail_checklist.md`. The point is not
extra paperwork; it prevents correct-looking callbacks from hiding stale-tail
writes or unreleased shared reservations.
