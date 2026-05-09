## L120 — DISPATCH-CALLBACK-MUST-INCLUDE-BR-CLOSE-EXECUTED

---
id: L120
title: Dispatch callback must include br close executed
status: long_term
shipped: 2026-05-06
review_due: 2026-11-06
trauma_class: bg-agent-close-miss
---

Every DONE callback MUST include br_close_executed=<yes|failed|not_applicable>.
Workers MUST run br close BEFORE ntm send DONE; close-step before callback-step
is the canonical worker-tick ordering.

**Why:** Five-instance same-session validation showed `bg-agent-close-miss`
when `br close` came after callback or was absent. Callback transport is a
terminal signal; cleanup listed after `ntm send` is routinely skipped.

**Validation:** skillos was 3-for-3 post-fix after adding the required callback
field and step 8b ordering, versus 4-of-5 missed pre-fix. Flywheel
SHIP-runbook line 45 independently already used `br_close_executed=yes`, so
the field emerged twice as the same substrate shape.

**How to apply:**
- Every DONE envelope contains `br_close_executed=yes` when `br close` exited
  0 before callback, or `br_close_executed=failed` when close was attempted and
  failed.
- `br_close_executed=not_applicable` is valid only for BLOCKED/DECLINED paths
  where ownership returns to the orchestrator instead of closing the bead.
- Worker-tick ordering is close first, callback second; dispatch templates must
  encode that order structurally, not in prose after the callback command.

**Forbidden outputs:**
- DONE callback without `br_close_executed`.
- Worker-tick that closes after callback.
- Treating DONE transport-ack as proof of bead close.

**Evidence:** Source proposal
`~/.claude/skills/.flywheel/proposals/P-bg-agent-close-miss-2026-05-06.md`;
skillos commits `d4ac88e` and `4e129fd`;
`~/.claude/commands/flywheel/worker-tick.md` step 8b;
`~/.claude/commands/flywheel/_shared/dispatch-template.md` callback contract;
`.flywheel/PLANS/orch-uptime-2026-05-06/SHIP-runbook.md` line 45.

**Cross-references:** L91 (dispatch four-state receipt), L119
(templates-name-sources-not-values), L57 (marker-not-driver), and SEC-002
(credential receipts).

