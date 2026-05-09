## L57 — LOOP-STATE-MARKER-NOT-DRIVER

---
id: L57
title: Loop state marker is not a driver
status: long_term
shipped: 2026-05-02
review_due: 2026-11-02
trauma_class: loop-state-without-driver
---

**Rule:** A flywheel loop is not active until its driver has been verified; `~/.flywheel/loops/<project>.json active=true`, doctor receipts, and tick receipts are markers, not drivers.

**Why:** Marker-only loops silently fail. A repo can claim `active=true` and emit `tick_complete` receipts while no orchestrator pane receives prompts and no work advances. Mobile-eats hit this on 2026-05-02: the launchd script ran doctor/tick but never called `ntm send`, so the Codex pane sat idle while the substrate claimed the loop was active.

**How to apply:**
- CC orchestrator panes require proof that `Skill("loop", args="<interval> /flywheel:tick")` was invoked from inside the live pane.
- Codex, web, shell, and other non-CC orchestrator panes require an external driver: launchd plist plus a tick script that writes a prompt file and calls `ntm send <session> --pane=<N> --file <prompt> --no-cass-check`.
- For launchd prompt mode, verify all three before saying "loop active": plist loaded, tick script contains `ntm send`, and the recent log contains `event:"ntm_dispatch_sent"`.
- Verify prompt delivery at the pane as a second truth source; `ntm_dispatch_sent` without recent pane evidence is a stale-driver warning.
- Doctor/tick receipts without a driver are observation-only and MUST NOT be reported as an active loop.

**Doctor invariant:** `flywheel-loop doctor --repo <repo>` should report `driver_status=verified|marker_only|stale|missing`. If loop state is active and no driver proof exists, the doctor emits SOFT violation `loop_state_without_driver`; strict mode may fail.

## Audit Playbook

Run this when L57 is suspected or after any loop-driver doctrine change:

1. Enumerate `~/.flywheel/loops/*.json`.
2. For each `active=true` marker, read the loop state and classify orchestrator kind from latest `~/.local/state/flywheel/session-topology.jsonl` plus `ntm health <session> --json`.
3. For Codex, web, shell, or other non-CC orchestrators, require all driver proof: plist loaded, executable tick script, `ntm send --file` in the script, recent `event:"ntm_dispatch_sent"` within 2 cadence windows, and prompt evidence in the target pane.
4. Return exactly one verdict per project:
   - `VERIFIED`: active marker plus live driver proof.
   - `MARKER_ONLY`: active marker exists, but only state files, doctor receipts, or tick receipts exist.
   - `STALE`: driver exists, but send or pane evidence is older than 2 cadence windows.
   - `MISSING_DRIVER`: active non-CC marker and no plist/script/equivalent driver candidate found.
   - `NOT_APPLICABLE_CC`: CC/Claude loop where `Skill("loop")` proof is expected instead of launchd prompt proof.
   - `UNKNOWN`: topology, health, config, or pane evidence contradict each other.
5. Treat `MARKER_ONLY` and `MISSING_DRIVER` as critical silent-failure regressions. Treat `STALE` as high severity until an intentional pause is proven.

First proven canonical: the 2026-05-02 fleet audit caught ALPS as `MARKER_ONLY` within 30 minutes of L57 promotion. See `/tmp/loop_driver_audit_fleet_findings.md` for the initial proof corpus and `~/.claude/skills/flywheel-end-to-end/references/INCIDENTS.md` for the doctrine entry. The launchd prompt reference implementation is `/Users/josh/.local/bin/mobile-eats-flywheel-loop-tick`.

**Forbidden outputs:**
- "Loop active" based only on `active=true`
- "Loop running" based only on `tick_complete` or closeout receipts
- Installing a launchd plist that runs doctor/tick but lacks an `ntm send --file` prompt dispatch
- Hardcoding a pane number without topology/config lookup and pane health cross-check

**Evidence:** `~/.local/state/flywheel/fuckup-log.jsonl:201`; `~/.claude/skills/flywheel-end-to-end/references/INCIDENTS.md#loop-state-without-driver-2026-05-02`; `~/.claude/commands/flywheel/loop.md` Codex orchestrator pattern; `/Users/josh/.local/bin/mobile-eats-flywheel-loop-tick`; `/Users/josh/Developer/skillos/.flywheel/run-30m-loop.sh`.

**Companion rules:** L29 (NTM-only doctrine) governs the pane transport; L50 makes dispatches survey existing loop substrate; L56 defines the promotion ladder used to lift this incident into canonical doctrine.


