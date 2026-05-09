## L60 — LOOP-INTEGRITY-5-SIGNAL-CONTRACT

---
id: L60
title: Loop integrity 5 signal contract
status: long_term
shipped: 2026-05-03
review_due: 2026-11-09
trauma_class: loop-integrity-liveness
---


A flywheel-managed session is HEALTHY only when ALL FIVE driver-output signals
fire within the loop interval. `active=true` in `~/.flywheel/loops/<project>.json`
plus a registered launchd plist is necessary but NOT sufficient — those are markers
(L57). Liveness is proven by output, not by configuration.

**The 5 signals (per loop, AND not OR):**
1. `ledger_writes_since_last_tick > 0` — product loop ledger OR canonical `~/.local/state/flywheel-loop/last_tick_<project>.json`; mtime within interval
2. `pane_state_changed_since_last_tick` — any worker pane `state_since` age < interval
3. `receipt_files_written_since_last_tick` — `<repo>/.flywheel/ticks/*.json` OR product-specific receipt path
4. `callback_received_in_last_2_ticks` — `<repo>/.flywheel/dispatch-log.jsonl` `callback_received_at` newer than 2*interval
5. `fuckup_log_decisions_made_since_last_tick` — new rows in `~/.local/state/flywheel/fuckup-processed.jsonl`

**Verdicts:**
- HEALTHY = all 5 fire
- LIMPING = 1-2 signals zero
- DEAD = ≥3 signals zero

**How to apply:**
- `gap-hunt-probe.sh` 9th class `loop-integrity` enforces this on every doctrine tick
- A LIMPING/DEAD loop with `launchd active=true` is a higher-priority repair than a missing-driver loop
- Mobile-eats reference 4-5/5 = HEALTHY proof pattern
- Skillos reference 2/5 → LIMPING proof case 2026-05-03 → fixed via mobile-eats-pattern apply (callback ts 08:10Z, 84 routed decisions, canonical receipt now written)

**Forbidden outputs:**
- Declaring a loop "running" because plist is loaded — must verify ≥3/5 signals
- IDLE_CLEAN tick decision while loop-integrity reports LIMPING|DEAD elsewhere in fleet
- Designing a new product loop without all 5 signal write-paths in the launchd payload

**Evidence:** bead `flywheel-aucl` (loop-integrity gap class shipped 2026-05-03);
`/tmp/loop-integrity-gap-class_findings.md`;
`/tmp/skillos-limping-diagnostic_findings.md` (proof case);
`~/Developer/flywheel/.flywheel/scripts/gap-hunt-probe.sh` 9th class function;
skillos jsm_sync first callback `~/.local/state/flywheel-loop/last_tick_skillos.json` 2026-05-03 ~08:10Z;
`feedback_loop_state_without_driver` memory entry.

**Companion rules:** L57 (loop-state markers ≠ driver); L52 (issues-to-beads-or-no-bead-reason — applies to LIMPING signal decisions); fleet-onboarding tier 4 health probes (flywheel-vhl5) consume this contract.

