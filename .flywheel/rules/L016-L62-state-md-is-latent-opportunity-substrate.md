## L62 — STATE-MD-IS-LATENT-OPPORTUNITY-SUBSTRATE

---
id: L62
title: STATE.md is latent opportunity substrate
status: long_term
shipped: 2026-05-03
review_due: 2026-11-09
trauma_class: latent-state-amnesia
---


`/flywheel:learn` MUST mine `.flywheel/STATE.md` files across the fleet roster
daily for improvement opportunities. STATE.md "Next Actions", "Known Gaps",
"Deferred", and "Resume Context" rows are durable signal that the operator
already documented but the learn loop never consumed. Treating fuckup-log as
the only learn input makes STATE.md content invisible to the system that's
supposed to act on it.

**Reason:** Joshua observed 2026-05-03 ~09:30Z that improvement opportunities
documented in STATE.md across repos get manually rediscovered every few days
because nothing automatically extracts them. Same ecosystem-touch failure mode
as L61 (META-RULE without mechanical gate) applied at the data-source level.

**How to apply:**
- `/flywheel:learn --mine-state` extracts opportunities from all fleet
  roster repos' `.flywheel/STATE.md` (and root `STATE.md` if present)
- 5 discovery classes with per-class action shape:
  1. **UNRESOLVED** — "Next Actions" row with no open bead → file P3 bead
  2. **STALE** — "Deferred" row older than 14d → ping with age + cost-of-defer
  3. **PATTERN** — same gap appearing in 3+ repos → file P2 systemic bead
  4. **RECURRING** — gap closed and reopened → trauma-class promotion candidate
  5. **ORPHANED** — "Known Gaps" entry with no bead reference → wire-into-ecosystem
- Each discovery results in one durable decision: bead OR no-bead reason
  (same shape as L52 fuckup-bead-or-no-bead-reason)
- Cap auto-bead at 5/day per repo to prevent ideation flood
- Daily launchd cron at 06:00 local matches morning-review cadence
- Wire into `/flywheel:tick` Step 4q so daily extraction surfaces in tick receipt

**Forbidden outputs:**
- Calling `/flywheel:learn --review` "complete" while STATE.md content unmined for >24h
- Operator manually re-reading STATE.md across repos to find opportunities (=
  the system failed to mine for them; file fuckup-log row class
  `orch_state_md_unmined`)
- Filing the same opportunity-bead twice for the same STATE.md row (idempotency
  via STATE.md-row hash)

**Evidence:** Joshua directive 2026-05-03 ~09:30Z;
bead `flywheel-b6zk` ([flywheel:learn STATE.md miner]);
sibling `flywheel-1rmp` (value-gap-hunter — paradigm-tier scan); 8 fleet repos
each with `.flywheel/STATE.md` containing untapped Next Actions.

**Companion rules:** L52 (durable decision per finding); L61 (every doctrine
landing wires into AGENTS+README — this rule is itself an instance);
`/flywheel:learn` skill at `~/.claude/commands/flywheel/learn.md` is the
extension surface.

