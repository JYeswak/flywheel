# Cross-Session Probe Canonical Truth Sources

Memory anchor:
`/Users/josh/.claude/projects/-Users-josh-Developer-flywheel/memory/feedback_cross_session_probe_canonical_truth_sources.md`

Before Flywheel decides whether a peer orchestrator is idle, blocked, or ready
for more work, it must check the canonical screen state, not only summarized
robot activity.

`ntm --robot-activity` is useful as a hint, but it can miss a running
orchestrator when agent-type filtering or capture provenance is incomplete.
The safer cross-session probe order is:

1. Capture the actual pane text with `tmux capture-pane`.
2. Read the repo-local or portable doctor for substrate state.
3. Use `ntm --robot-activity` as corroborating telemetry, not as sole truth.

## Why this is doctrine

The observed failure class was a near-miss: a SkillOS pane looked empty through
robot-activity, but pane capture showed an active `/goal` run. Treating the
hint as truth would have caused Flywheel to send extra work to a busy
orchestrator or build infrastructure for a false offline state.

This doctrine is the named cross-link for the feedback memory so gap-hunt and
future workers can find the rule from the repo, not only from private memory.



## Meta-Learning Cross-References (2026-05-19)

This doctrine surface was backfilled during JSM fleet audit batch-3 so recent doctrine cites the relevant MP lessons directly.

- **MP-09 — info-source watchtower:** see `/Users/josh/Developer/skillos/.flywheel/doctrine/meta-learnings/MP-09-info-source-watchtower.md` for the canonical pattern.
- **MP-13 — living documentation:** see `/Users/josh/Developer/skillos/.flywheel/doctrine/meta-learnings/MP-13-living-documentation.md` for the canonical pattern.
- **MP-28 — checklist before claim:** see `/Users/josh/Developer/skillos/.flywheel/doctrine/meta-learnings/MP-28-checklist-before-claim.md` for the canonical pattern.
