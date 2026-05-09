## L67 — TRUTH-SOURCE-MUST-BE-LIVE-NOT-CACHED

---
id: L67
title: Truth source must be live not cached
status: long_term
shipped: 2026-05-03
review_due: 2026-11-09
trauma_class: cached-truth-drift
---


When `feedback_two_truth_sources_before_decide` requires cross-checking pane
state, the second source MUST be verified-live. `ntm --robot-tail` returns
cached scrollback that may be hours stale and identical across panes; using
it as a truth source produces FALSE second-source confirmation and triggers
spurious recovery actions. Live truth comes from process inspection
(`pgrep -f codex`, `lsof -p <pid>`), agent-mail callbacks landing
in dispatch-log, or scrollback-byte-delta from sequential probes.

**Reason:** Tick 14+15 2026-05-03 ~10:00-11:50Z observed all 4 panes returning
identical stale scrollback from prior day via `--robot-tail`. Misdiagnosed as
"codex-cli-exited" trauma class. Fired 3 spurious codex relaunches into
actually-working panes. Pane 2's jeff-intel-clone-and-index callback at 11:50Z
(177 repos cloned + 79 indexed = 30+ minutes of real work) PROVED pane was
working all along. Two-truth-sources rule is only valid if BOTH sources are
live, not when one is a cached snapshot.

**How to apply:**
- Before declaring a pane "frozen" or "exited", verify with at least one
  live signal:
  - `pgrep -f "codex --dangerously"` to confirm codex process exists
  - Check dispatch-log.jsonl for recent callbacks from that pane
  - Sample `--robot-tail` twice with 30s gap; compare for actual delta
  - Use `frozen-pane-detector.sh` (already does scrollback delta correctly)
- Treat `--robot-tail` output as POSSIBLY stale until proven live by delta
- If only stale truth sources are available, defer-to-human, do not auto-recover
- Do NOT fire codex relaunch based on single `--robot-tail` snapshot —
  scrollback may be cached

**Forbidden outputs:**
- "Pane is frozen because scrollback shows shell prompt" without delta evidence
- Auto-firing codex relaunch when only single `--robot-tail` snapshot supports it
- Adding new fuckup-log trauma class without verifying the trauma is real

**Evidence:** Tick 14 deferred-to-human due to false ambiguity; tick 15 fired
3 spurious codex relaunches into working panes; jeff-intel callback at 11:50Z
(177 repos cloned, 79 indexed, 379400 chunks) proved pane 2 was working;
fuckup-log row class `ntm-robot-tail-returns-stale-cached-scrollback`
2026-05-03 logged this turn.

**Companion rules:** L57 (loop-state markers ≠ driver — same pattern);
L60 (5-signal contract — uses live signals); `feedback_two_truth_sources_before_decide`;
`feedback_pane_state_ntm_health`; frozen-pane-detector.sh script (already
implements scrollback-byte-delta correctly).


