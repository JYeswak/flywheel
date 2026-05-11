# L157 — OUTBOX-DISCIPLINE-CROSS-ORCH-SHIP-NOTIFICATION

---
id: L157
title: Every orch that codifies doctrine OR ships fleet-affecting substrate MUST send ntm notification to every sister-orch BEFORE declaring closeout
status: long_term
shipped: 2026-05-11
review_due: 2026-11-11
trauma_class: outbox-discipline-missed-when-codifying-doctrine-same-session
---

Every orchestrator pane (`flywheel:1`, `skillos:1`, `mobile-eats:1`, peer orchs in the ZestStream fleet) MUST, before declaring closeout on any tick that codified a `.flywheel/doctrine/*.md` file OR shipped fleet-affecting substrate (installer / hook / canonical script / cross-orch contract), **send an ntm notification to every sister-orch**. This is the **outbox-discipline 0th probe** of closeout — outgoing half of the bilateral cross-orch protocol whose incoming half is L156 (inbox-discipline-0th-probe).

Workers are NOT subject to this rule (workers report via dispatch-callback to their dispatching orchestrator only; the orch decides whether to ntm sister-orchs).

**Trigger condition:** orchestrator about to declare closeout (commit + br close) on any tick that landed:
- A new file under `.flywheel/doctrine/*.md`, OR
- A new or modified file under `.flywheel/scripts/<canonical>.sh` / `.flywheel/lib/<canonical>.sh` / `.flywheel/rules/L*.md` / any cross-orch-contract file
- Any installer/hook change that sister orchs may inspect, depend on, or replicate

**Result if violated:** new doctrine or fleet substrate ships **silo'd**; sister orchs continue operating on stale assumptions; coordination drift accumulates until external surface (Joshua probe via `/login`, peer-orch detection via routine `ls .flywheel/handoffs/`) catches the gap. This is the **inverse of L156**: L156 catches incoming-handoffs missed during deep burndown; L157 catches outgoing-ship-notifications missed during high-velocity codification sessions.

**How to apply (closeout 0th-step outbox probe):**

```bash
# Detect codified-doctrine or fleet-substrate landing in this tick
DOCTRINE_DIFF="$(git diff --name-only HEAD~1 -- .flywheel/doctrine/ 2>/dev/null)"
SUBSTRATE_DIFF="$(git diff --name-only HEAD~1 -- .flywheel/scripts/ .flywheel/lib/ .flywheel/rules/ 2>/dev/null)"

if [[ -n "$DOCTRINE_DIFF$SUBSTRATE_DIFF" ]]; then
  # Compose handoff message + ntm-send to each sister orch
  for SISTER in skillos mobile-eats; do
    /Users/josh/.local/bin/ntm send "$SISTER" --pane=1 --no-cass-check \
      "WAVE-COMPLETION: <bead-id> codified <doctrine-name> + shipped <substrate>; see .flywheel/handoffs/<ts>-from-<this-orch>-to-<sister>-WAVE-<wave>-COMPLETE.md"
  done

  # Always file a filesystem handoff (fallback for unresponsive recipient pane)
  HANDOFF_TS="$(date -u +%Y%m%dT%H%M%SZ)"
  echo "<handoff body>" > .flywheel/handoffs/${HANDOFF_TS}-from-<this-orch>-to-<sister>-WAVE-<wave>-COMPLETE.md
fi
```

For high-velocity codification sessions (≥2 doctrine docs landed in <30 minutes): force-send outbox notification even if no new substrate ship; the codification IS the ship.

If `ntm send` returns `context deadline exceeded` (recipient pane unresponsive per session-map `orchestrator_pane: null`), the filesystem-handoff fallback (per L107 sister discipline) is the canonical alternative — write to `.flywheel/handoffs/<ts>-from-<this>-to-<sister>-*.md` and continue. Recipient orch picks up on its next L156 inbox-discipline 0th probe.

**Reason:** On 2026-05-11T22:30:00Z, `skillos:1` had a high-velocity codification session:

| Time | Event |
|---|---|
| 22:15Z | started codifying `hook-chain-extend-vs-replace.md` doctrine |
| ~22:20Z | shipped installer v2 with `--chain-extend` mode |
| ~22:25Z | ran live (4/4 success) |
| 22:25Z | declared closeout (commit + br close) |
| 22:30Z | Joshua probe via `/login` channel: **"did you let mobile-eats know?"** |
| 22:30Z | gap acknowledged + ntm-send issued + fuckup-log row + durable rule |

mobile-eats:1 had been running its own ticks for 5+ minutes WITHOUT awareness of the new doctrine or shipped substrate. The hook-chain-extend-vs-replace pattern is fleet-affecting — installer v2 changes substrate that mobile-eats:1 may install / inspect / depend on. Silent ship → coordination drift. Resolution: skillos:1 acknowledged at 22:30Z + logged durable rule + ntm-sent mobile-eats:1.

**Sister rule (inverse direction):** L156 (inbox-discipline-0th-probe) is the **incoming** complement. When an orch starts a heartbeat tick, it MUST check `.flywheel/handoffs/*from*.md` BEFORE work selection. Together L156 + L157 bind the bilateral cross-orch communication protocol in both directions: L156 catches what sister-orchs sent IN; L157 ensures what THIS orch sends OUT is not silo'd.

**Dogfooded by its own promotion wave:** the v38e1 wave-completion handoff (`flywheel/.flywheel/handoffs/20260511T233036Z-from-flywheel-1-to-skillos-1-WAVE-v38e1-COMPLETE.md`) was sent from `flywheel:1` to `skillos:1` per this rule applied recursively to the wave that includes the rule itself. The `ntm send` to skillos returned `context deadline exceeded` (recipient unresponsive); filesystem-handoff fallback was the canonical alternative. Sister orch picks up on next L156 inbox check.

**Evidence:** doctrine doc `.flywheel/doctrine/outbox-discipline-cross-orch-ship-notification.md` (240 lines; promoted_from skillos-fuckup-log 2026-05-11T22:30:00Z); first instance `skillos:1 2026-05-11T22:15Z-22:25Z codifying hook-chain-extend-vs-replace.md + shipping installer v2 without ntm-send to mobile-eats:1`; parent bead `flywheel-v38e1.4`; promotion bead `flywheel-jzj45`.

**Companion rules:**
- L52 (issues-to-beads-or-explicit-no-bead-receipt) — orch-side bead-receipt discipline that ntm-send complements
- L61 (doctrine-landing-wires-into-agents-and-readme) — orch-side artifact-wiring discipline that ntm-send completes
- L70 (orch-no-punt) — next-actionable runs same tick (outbox-send is one such next-actionable when doctrine/substrate landed)
- L96 (doctrine-lands-as-3-surface-diff-or-does-not-land) — the 3-surface discipline that the codified doctrine satisfied; outbox notification is the 4th cross-orch surface
- L107 (shared-surface-writes-must-reserve-across-panes) — sister cross-orch coordination discipline
- L154 (closure-evidence-contract-version-anchor) — cohort sister (closure-evidence integrity)
- L155 (closure-evidence-public-lens-anchor) — cohort sister (closure-evidence integrity)
- L156 (inbox-discipline-0th-probe) — the bilateral protocol's INCOMING half
- L157 (this rule) — the bilateral protocol's OUTGOING half

**Canonical source:** `.flywheel/doctrine/outbox-discipline-cross-orch-ship-notification.md`
(schema_version: `outbox-discipline-cross-orch-ship-notification/v1`)

**Sister rules / cohort:** Final member of the 4-rule v38e1 cohort promoted to flywheel canonical from skillos:1 fuckup-log. Cohort L-rule promotion status (post this rule):
- L154 (closure-evidence-contract-version-anchor, 12:12Z; doctrine v38e1.1; L-rule nerln) — SHIPPED
- L155 (closure-evidence-public-lens-anchor, 14:50Z; doctrine v38e1.2; L-rule a38zz) — SHIPPED
- L156 (inbox-discipline-0th-probe, 17:00Z; doctrine v38e1.3; L-rule o3sqj) — SHIPPED
- L157 (this rule — outbox-discipline-cross-orch-ship-notification, 22:30Z; doctrine v38e1.4; L-rule jzj45) — **THIS RULE**

4-of-4 cohort L-rule promotions COMPLETE with this bead. The bilateral cross-orch protocol (L156 inbox + L157 outbox) + closure-evidence integrity (L154 contract-version + L155 public-lens-anchor) are now fully L-canonicalized.
