# Plan Intent — accretive-fix-mobile-eats-dispatch-health-gate-substrate

**Slug:** accretive-fix-mobile-eats-dispatch-health-gate-substrate-2026-05-04
**Started:** 2026-05-04T05:50:00Z
**Triggered by:** mobile-eats-orch ESCALATE capsule (2-tick blocker contract)
**SLA:** flywheel-orch responds within 1 tick of capsule arrival per `feedback_two_blocker_ticks_escalate_to_flywheel_plan` META-RULE

## Verbatim escalation capsule

> to: rubycastle@flywheel
> subject: ESCALATE blocker survived 2 ticks
> body:
>   blocker_id: mobile-eats-dispatch-health-gate-substrate
>   ticks_survived: 2+
>   first_seen: 2026-05-04T05:26:47Z
>   affected_beads: mobile-eats-nq5,mobile-eats-u7f,mobile-eats-vu8,mobile-eats-s6p
>   local_fix_attempts: doctor prelude; pane robot-activity gate; abort-on-errors contract; repeated blocked receipts /tmp/mobile-eats-dispatch-052647-blocked.md /tmp/mobile-eats-dispatch-053149-blocked.md /tmp/mobile-eats-dispatch-053652-blocked.md
>   evidence_paths: /tmp/mobile-eats-dispatch-052647-blocked.md,/tmp/mobile-eats-dispatch-053149-blocked.md,/tmp/mobile-eats-dispatch-053652-blocked.md
>   hypothesis: Mobile Eats dispatch path is structurally blocked by beads_db_health_failed leakage_count growth plus missing daily report; local retries keep idling pane 2.
>   asks: /flywheel:plan accretive-fix-mobile-eats-dispatch-health-gate-substrate

## What's actually happening

Three consecutive mobile-eats dispatch ticks (05:26Z, 05:31Z, 05:36Z) all fail-closed on the same two blockers:

1. **`beads_db_health_failed`** — `br doctor` reports integrity `ok` BUT `leakage_count=10` and `status=fail`. Doctor gate is fail-closed on any non-empty `.errors` array, so dispatch refuses to fire.
2. **`daily_report_missing`** — no daily report exists for mobile-eats. Doctor gate flags it as a hard error, not a warning.

Plus a climbing non-blocking warning:
3. **`agent_mail_fd_doctor_warn`** — `lock_fd_count` rose 26 → 27 across 3 ticks (warn threshold 25). Currently warning-only; could become a third blocker if it crosses an error threshold.

The orch is doing its job correctly (fail-closed; blocked receipts; structured fuckup log). The system above the orch is broken: there's no path for these blockers to clear without intervention. Workers idle. Joshua's time-saved-per-week metric goes negative.

## Reframing — this is a substrate problem, not a mobile-eats problem

The same two failure classes can — and probably will — block any fleet repo with bead-isolation leakage or missing daily report:

- **leakage**: bead-isolation cross-project leak counter is shared substrate; fixed in flywheel will propagate to all fleet repos via `flywheel-install` template per `feedback_no_ad_hoc_per_repo_doctrine_edits`.
- **daily report**: the daily-report skill exists (`flywheel:daily-report`) but isn't auto-wired into every repo's tick. Same propagation gap.
- **agent-mail FD**: substrate-level resource leak, NOT mobile-eats's fault; affects every fleet repo using mcp-agent-mail.

So this plan addresses: the **fail-closed gate trauma class** + the **two specific blockers** + the **propagation mechanism** so future repos don't hit the same wall.

## Goal

A converged plan that:

### A. Unblock mobile-eats THIS TICK (band-aid layer)
1. Determine if leakage_count=10 represents real isolation breaks or stale ledger entries
2. Generate a one-off mobile-eats daily report (or accept "first-day skip" semantics)
3. Document the manual unblock in fuckup-log
4. Mobile-eats:p2 dispatches the next ready bead (mobile-eats-nq5/u7f/vu8/s6p)

### B. Fix substrate (accretive layer)
5. **Bead-isolation leakage**: root-cause + auto-clear path; integrate with existing bead-isolation-fix plan; emit propagate-to-fleet bead
6. **Daily-report missing**: wire `flywheel:daily-report` into every fleet repo's tick (auto-bootstrap on first tick of day; "first-day skip" semantics)
7. **Agent-mail FD pressure**: track lock_fd_count over time; alert at warn (25) before hitting hard cap; doctor surfaces growth rate not just count

### C. Lift the gate trauma class (Meadows layer)
8. **Doctor gate semantics review**: separate "real failures" from "stale signals." Currently every non-empty `.errors` array hard-blocks dispatch. Some errors are recoverable (leakage on stale rows) and should be auto-clearable rather than human-only.
9. **Capsule schema codification**: this is the first ESCALATE capsule actually filed; codify schema in skill library so future escalations (skillos, cfs, alps) are machine-parseable.
10. **Joshua-notice-debt counter**: this blocker survived 3 ticks BEFORE the 2-tick rule fired (rule was just announced). Did mobile-eats's tick loop actually wire the counter, or did the orch escalate ad-hoc? If ad-hoc, the counter is debt.

## Acceptance for shipped fix

- mobile-eats:p2 dispatching ready beads within 2 flywheel ticks of plan ship
- `bead-isolation-fix` propagation includes auto-clear path for stale leakage rows
- `flywheel:daily-report` wired into every fleet repo's tick template
- agent-mail FD growth-rate signal in doctor JSON
- Doctor gate has explicit "auto-clearable vs human-required" classification
- Capsule schema codified in skill library; sister orchs reply `tick_counter_wired=true`

## Three-judges lens for this plan

- **Jeff**: doctor/health/repair triad — current gate is doctor + halt; missing repair. This plan adds repair path.
- **Donella**: stocks (leakage_count, FD count, daily-reports-written, blocker-tick-counter); flows (leakage emission, FD acquire/release, daily-tick events); gate is balancing feedback that's missing the negative-feedback completion (fix path); leverage point #6 INFORMATION FLOWS (escalation capsule) + #4 SELF-ORGANIZATION (auto-clear).
- **Josh**: does this give time back? YES — auto-clear means future blockers self-resolve at sister-orch tick rather than requiring escalate→plan→fix-bead wave. ZestStream voice on receipts.

## Constraints

- READ-ONLY through Phase 3
- Phase 4 mutates beads DB only (not source)
- Code edits via separate `/flywheel:dispatch` of polished beads
- Plan-space tokens 25× cheaper than code-space — converge here, ship cheap
- Compose-not-replace: every fix layers on existing skills (flywheel-doctor-author, beads-workflow, agent-mail FD doctrine)

## Pre-flight

- Capsule received: 2026-05-04T05:50Z (within SLA)
- mobile-eats orch: still idle, awaiting plan response
- flywheel pane capacity: TBD (will probe before dispatching lanes)
- Existing bead-isolation-fix plan active; this plan composes with it
- daily-report skill exists; wiring is the gap, not the skill itself
