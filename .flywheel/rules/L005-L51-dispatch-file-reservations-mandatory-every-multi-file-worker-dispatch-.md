## L51 — DISPATCH-FILE-RESERVATIONS-MANDATORY (every multi-file worker dispatch reserves files via agent-mail before edits)

---
id: L51
title: Dispatch file reservations mandatory
status: long_term
shipped: 2026-04-30
review_due: 2026-10-30
trauma_class: concurrent-worker-drift
---

**Rule:** Every NTM dispatch that asks a worker to edit 1+ files MUST include an agent-mail file reservation step in its pre-flight section. Worker reserves files BEFORE first edit, releases on completion (DONE) or release-on-blocked (BLOCKED). Dispatch packets that name file paths but lack a reservation step are non-compliant per L51.

**Why:** Concurrent workers across multiple panes of a single NTM session, OR across multiple NTM sessions sharing a working tree, race on the same files. The picoz-specific `PICOZ_WORKER_FILES` pathspec hook (per local AGENTS.md and bd-rqrsr) catches one shape of this — accidental cross-attribution at commit time. But it doesn't prevent the underlying race; two workers can edit the same function in parallel and the second commit wins silently. Agent-mail file reservations make the lock explicit and pane-attributable BEFORE edits begin.

**Mechanism:**
- Skill: `agent-mail` is already installed; verbs include `reserve-files`, `release`, `renew_file_reservations`, `force_release_file_reservation`
- Pre-flight in dispatch packet: `mcp__mcp-agent-mail__macro_file_reservation_cycle` with declared file paths
- Worker callbacks must include `files_reserved=<comma-list>` and `files_released=<comma-list>`
- Orchestrator releases held reservations on dispatch timeout (default 60min) via `force_release_file_reservation` per agent-mail SETUP

**Forbidden orchestrator outputs:** dispatch packets that list `PICOZ_WORKER_FILES=...` without a paired `mcp__mcp-agent-mail__reserve_files` step. Pathspec discipline catches collisions at commit; reservation prevents collisions at edit. Both layers needed.

**Override:** `JOSHUA_OVERRIDE='<reason>'` permits one ledger-less dispatch (rare; reserved for trivial single-file orchestrator-pane work where reservation overhead exceeds work).

**Cost citation:** ~3 incidents over the last 60 days where worker-A and worker-B both edited the same file region; second commit silently overwrote first; bug surfaced 2-3 days later when the missing logic was needed in production. The pathspec hook flagged the cross-attribution but the *content drift* was already merged.

**Companion rules:** L50 (socraticode-mandatory) is dispatch-time substrate awareness; L51 (this) is dispatch-time concurrency safety. Both required for every multi-file dispatch.


