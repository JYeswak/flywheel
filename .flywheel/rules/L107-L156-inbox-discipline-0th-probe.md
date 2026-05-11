# L156 — INBOX-DISCIPLINE-0TH-PROBE

---
id: L156
title: Every orchestrator heartbeat tick MUST start with an inbox check (0th step) before mission-gate or work selection
status: long_term
shipped: 2026-05-11
review_due: 2026-11-11
trauma_class: inbox-discipline-missed-during-deep-burndown-motion
---

Every orchestrator pane (`flywheel:1`, `skillos:1`, `mobile-eats:1`, peer orchs in the ZestStream fleet) MUST run an inbox check as the **0th step** of every heartbeat tick, BEFORE mission-gate probes or work selection. The check filters `.flywheel/handoffs/*from*.md` by mtime newer than the prior closeout receipt's `ts`. If new handoff files exist, READ them BEFORE any work selection.

Workers are NOT subject to this rule (workers receive context via dispatch packets directly; orchs own inbox-check responsibility).

**Trigger condition:** orchestrator about to enter mission-gate or select work without running the 0th-step inbox check.

**Result if violated**: handoff accumulation goes unnoticed; sister-orch context backs up silently until external surface (e.g., Joshua via `/login`) catches the gap.

**How to apply (0th-step inbox check):**

```bash
LAST_CLOSEOUT_TS="$(jq -r '.ts' .flywheel/last_closeout_receipt.json 2>/dev/null || echo '1970-01-01T00:00Z')"
NEW_HANDOFFS="$(find .flywheel/handoffs -name '*from*.md' -newermt "$LAST_CLOSEOUT_TS" 2>/dev/null)"
if [[ -n "$NEW_HANDOFFS" ]]; then
  echo "INBOX: $(echo "$NEW_HANDOFFS" | wc -l | tr -d ' ') new handoff(s) since $LAST_CLOSEOUT_TS"
  echo "$NEW_HANDOFFS"
  # READ each one before selecting any work
fi
```

For deep-burndown safety: when the same tick-shape pattern repeats ≥3 consecutive ticks, force-check the inbox even if no signal expected.

**Reason:** On 2026-05-11, `skillos:1` ran 9 consecutive Shape B chain-closure ticks plus 1 Meadows L4 ship plus 1 closeout receipt across ~16 hours WITHOUT checking `.flywheel/handoffs/` for new files from sister orchestrators. 5 mobile-eats:1 handoffs accumulated (TWO-LAYER-GITLEAKS-ALLOWLIST doctrine arc, security-hygiene + atomic-file-write substrate ships, fleet-audit sweep, 7 META-doctrine drops, routing-correction). Burndown-motion eclipsed inbox-discipline. Joshua surfaced the gap via `/login` channel at ~16:50Z. Resolution: skillos:1 acknowledged at 17:00Z + logged durable rule + processed accumulated handoffs.

**Sister rule (inverse direction):** L157 (pending; outbox-discipline-cross-orch-ship-notification) is the **outgoing** complement. When an orch codifies a doctrine or ships fleet-affecting substrate in-session, it MUST `ntm send` sister-orchs before closeout. Together L156 + L157 bind the bilateral cross-orch communication protocol in both directions.

**Evidence:** doctrine doc `.flywheel/doctrine/inbox-discipline-missed-during-deep-burndown-motion.md` (94 lines; promoted_from skillos-fuckup-log 2026-05-11T17:00:00Z); first instance `skillos:1 2026-05-11 09:30Z-16:35Z` accumulating 5 mobile-eats:1 handoffs during Shape B burndown chain; parent bead `flywheel-v38e1.3`; promotion bead `flywheel-o3sqj`.

**Companion rules:**
- L52 (issues-to-beads-or-explicit-no-bead-receipt) — work-selection discipline that inbox-check precedes
- L70 (orch-no-punt) — next-actionable runs same tick (the 0th-step probe is one such next-actionable when inbox has new handoffs)
- L107 (shared-surface-writes-must-reserve-across-panes) — sister cross-orch coordination discipline
- L154 (closure-evidence-contract-version-anchor) — cohort sister (closure-evidence integrity)
- L155 (closure-evidence-public-lens-anchor) — cohort sister (closure-evidence integrity)
- L156 (this rule) — the inbox-check invariant
- L157 (pending) — the outbox-discipline mirror

**Canonical source:** `.flywheel/doctrine/inbox-discipline-missed-during-deep-burndown-motion.md`
(schema_version: `inbox-discipline-missed-during-deep-burndown-motion/v1`)

**Sister rules / cohort:** Part of the 4-rule v38e1 cohort promoted to flywheel canonical from skillos:1 fuckup-log. Cohort L-rule promotion status:
- L154 (closure-evidence-contract-version-anchor, 12:12Z; doctrine v38e1.1, L-rule nerln) — SHIPPED
- L155 (closure-evidence-public-lens-anchor, 14:50Z; doctrine v38e1.2, L-rule a38zz) — SHIPPED
- L156 (inbox-discipline-0th-probe, 17:00Z; doctrine v38e1.3, L-rule o3sqj) — THIS RULE
- `outbox-discipline-cross-orch-ship-notification` (22:30Z; doctrine v38e1.4; L-rule pending)

3-of-4 cohort L-rule promotions complete with this bead.
