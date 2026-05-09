## L68 — NO-SILENT-DARKNESS-GOAL-CONTRACT

---
id: L68
title: No silent darkness goal contract
status: long_term
shipped: 2026-05-03
review_due: 2026-11-03
trauma_class: silent-darkness
---

**Rule:** The flywheel loop optimizes for `NO_SILENT_DARKNESS`, not merely
"frozen pane detected." A fleet or repo loop is not healthy unless the
measurement loop proves all five L60 signals and all four goal-quality metrics:

1. `silent_dark_minutes=0`
2. `blackout_detection_latency_p95<=2m`
3. `false_recovery_count=0`
4. `unknown_autorecovery_count=0`
5. `L60_signals_present=5/5` for every active loop interval

**Why:** The 2026-05-03 Codex fleet stuck THINKING RCA found that pane-freeze
detection was a symptom frame. The real failure was silent darkness: active loop
markers, stale pane state, missing callbacks, missing receipts, or unprocessed
fuckup decisions could coexist while the system appeared "running." Meadows #3
requires changing the goal before tuning detectors.

**How to apply:**
- Run `.flywheel/scripts/no-silent-darkness-probe.sh --doctor --json` before any
  dispatch/recovery decision that depends on loop liveness.
- Treat `orch_silent_darkness_breach` as a SOFT halt: stop new dispatch and
  recovery actions until the missing L60 signals have a bead, update, or explicit
  no-bead reason.
- Frozen-pane detector output is an input to this contract, not the contract
  itself. A pane can be unfrozen while the loop is still LIMPING or DEAD.
- C5 and later tick consumers MUST preserve the five metric fields in receipts
  and promote repeated SOFT breaches to a fail gate after the consumer is wired.

**Forbidden outputs:**
- Declaring "all clear" because no pane is classified frozen while any L60 signal
  is missing.
- Auto-recovering an UNKNOWN source or a loop with fewer than 5/5 L60 signals.
- Reporting loop health without `silent_dark_minutes`,
  `blackout_detection_latency_p95`, `false_recovery_count`,
  `unknown_autorecovery_count`, and `L60_signals_present`.

**Evidence:** bead `flywheel-o499`; RCA Rev 2 DAG at
`.flywheel/PLANS/codex-fleet-stuck-thinking-RCA-2026-05-03/04-BEADS-DAG-rev2.md`;
probe `.flywheel/scripts/no-silent-darkness-probe.sh`; C10 commit `0cff2d5`;
C11 commit `bb328f8`.

**Companion rules:** L57 (markers are not drivers), L60 (five-signal contract),
L61 (doctrine must wire into AGENTS/README), L67 (truth source must be live),
and `flywheel-doctor-author` producer/measurement/consumer/promotion doctrine.


