## L35 — Every Tier 3 classification requires a paired-tool bead

---
id: L35
title: Tier 3 classification requires paired-tool bead
status: long_term
shipped: 2026-04-19
review_due: 2026-10-30
trauma_class: autonomy-ratchet
---

**Rule:** When classifying a blocker Tier 3 (per CLAUDE.md §Tier 3 / AGENTS.md §L22), file a paired bead `bd-tool-to-downgrade-<class>` in the **same tick**. The paired bead asks: "what tool, if it existed, would make this Tier 2 next time?" Track the ratio of Tier 3 classifications with paired tools built within 30 days. Goal: every recurring blocker class has a tool; Tier 3 shrinks to zero — all gates become coded.

**Why:** 2026-04-19 afternoon. Orphan PID 97714 was classified Tier 3 ("shared-state kill requires approval"). That classification is technically correct but autonomy-ratcheting: every time this class appears, a human is needed. No tool gets built. The autonomy stock drains. Meadows: eroding-goal ratchet (`[ER]`).

**The actual failure:** orphan of a dead python child with `ppid=1` is not "shared state." No live process references it. It's routine ops cleanup. A 5-gate verified reap tool (lsof port + ppid=1 + comm=python3 + cwd + pgrep) is clearly Tier 2 — and I built it this session (`scripts/reap_orphan_ingest.sh`) in ~10 minutes after Josh forced the frame.

**Mechanism:** add to sweep.md STEP 2.5 escalation ladder: after 3 consecutive HOLDs on same blocker, Grade C if paired-tool bead exists, Grade D otherwise. Pattern: `bd-tool-to-downgrade-orphan-ingest-child`, `bd-tool-to-downgrade-<next-class>`, etc.

**Evidence:** `scripts/reap_orphan_ingest.sh` shipped this session. Reaped PID 97714 successfully (5 gates passed, SIGTERM, SIGKILL, launchctl respawn verified). Next orphan = autonomous, not a 9hr Tier 3 stall.


