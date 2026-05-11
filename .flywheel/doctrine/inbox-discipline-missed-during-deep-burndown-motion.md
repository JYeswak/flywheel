---
title: "Inbox-Discipline: 0th Probe of Every Orchestrator Heartbeat"
type: doctrine
created: 2026-05-11
frontmatter_source: scaffold-doc-frontmatter
promoted_from: skillos-fuckup-log-2026-05-11T17:00:00Z
canonical_class: orchestrator-bilateral-protocol
status: canonical
---

# Inbox-Discipline: 0th Probe of Every Orchestrator Heartbeat

Version: `inbox-discipline-missed-during-deep-burndown-motion/v1`
Owner: every orchestrator pane (flywheel:1, skillos:1, mobile-eats:1, etc.)
Status: canonical, promoted 2026-05-11 from skillos fuckup-log 17:00Z
Source bead: flywheel-v38e1.3 (skillos fuckup-log promotion wave; sibling v38e1.1, v38e1.2, v38e1.4)
Promotion authority: Joshua-directive 14:45Z (META-doctrine to skillos:1) + 17:40Z (orchs coordinate directly)

## TL;DR

Every orchestrator heartbeat tick MUST start with an inbox check (`ls -la .flywheel/handoffs/*from*.md` filtered by mtime newer than the last closeout receipt). Inbox-check is the **0th step**, not a sub-step of mission-gate. Deep burndown chains (N>=3 consecutive same-pattern ticks) force-check the inbox even if no signal expected.

## Rule (canonical)

```text
Every orchestrator heartbeat tick MUST:
  1. (0th step) Run inbox check:
       ls -la .flywheel/handoffs/*from*.md
     filtered by mtime newer than the prior closeout receipt's ts.
  2. If new handoff files exist, READ them BEFORE any work selection.
  3. Inbox-check is not bolted onto the mission-gate probe; it precedes it.
  4. When a burndown chain takes ≥3 consecutive ticks on the same pattern,
     force-check the inbox even if no signal is expected.
```

## When to apply

- Every orchestrator tick (mandatory 0th probe)
- Especially during deep burndown chains (N>=3 same-shape ticks)
- After any extended single-pattern motion
- Before declaring a closeout receipt

## Why it exists

On 2026-05-11, `skillos:1` ran 9 consecutive Shape B chain-closure ticks (`2c8.1 → ltyc.1`) plus 1 Meadows L4 ship plus 1 closeout receipt across ~16 hours **without** checking `.flywheel/handoffs/` for new files from sister orchestrators. 5 mobile-eats:1 handoffs accumulated (TWO-LAYER-GITLEAKS-ALLOWLIST doctrine arc, security-hygiene + atomic-file-write substrate ships, fleet-audit sweep, 7 META-doctrine drops, routing-correction). Burndown-motion eclipsed inbox-discipline. **Joshua surfaced the gap directly via `/login` channel.**

The class is named `inbox-discipline-missed-during-deep-burndown-motion` to capture the failure mode: an orch in deep single-shape motion stops sampling sister-orch traffic, and the silent accumulation only surfaces when the human operator catches it externally.

## Sister rule (inverse direction)

`outbox-discipline-missed-when-codifying-doctrine-same-session` (logged 22:30Z same day) is the **outgoing** complement: when an orch codifies a doctrine or ships fleet-affecting substrate in-session, it MUST `ntm send` sister-orchs before closeout. Together they bind the bilateral cross-orch communication protocol in both directions.

## Mechanization

A recommended implementation for every orch tick:

```bash
# 0th probe — inbox check
LAST_CLOSEOUT_TS="$(jq -r '.ts' .flywheel/last_closeout_receipt.json 2>/dev/null || echo '1970-01-01T00:00Z')"
NEW_HANDOFFS="$(find .flywheel/handoffs -name '*from*.md' -newermt "$LAST_CLOSEOUT_TS" 2>/dev/null)"
if [[ -n "$NEW_HANDOFFS" ]]; then
  echo "INBOX: $(echo "$NEW_HANDOFFS" | wc -l | tr -d ' ') new handoff(s) since $LAST_CLOSEOUT_TS"
  echo "$NEW_HANDOFFS"
  # READ each one before selecting any work
fi
```

For deep-burndown safety, also track tick-shape count: if the same pattern hash repeats >=3 ticks, force the inbox-check regardless of prior result.

## Resolution path (when caught)

1. Acknowledge the gap explicitly (handoff back to sister orch)
2. Read all accumulated incoming handoffs
3. Process them in order before resuming the current burndown
4. Log a durable rule entry to `~/.local/state/flywheel/fuckup-log.jsonl`
5. Update the orch's heartbeat tick template to include the 0th probe

## Evidence

- First instance: `skillos:1 2026-05-11 09:30Z-16:35Z` accumulating 5 mobile-eats:1 handoffs during Shape B burndown chain
- Resolution receipt: `.flywheel/handoffs/20260511T170000Z-to-mobile-eats-1-orchestrator-inbox-failure-ack-plus-doctrine-mirror-plan.md` (skillos workspace)
- Bilateral hardening: mobile-eats:1 began pairing `ntm send` with every handoff write at 17:00Z+
- Sister rule: `outbox-discipline-missed-when-codifying-doctrine-same-session` (22:30Z)

## Cross-references

- `outbox-discipline-missed-when-codifying-doctrine-same-session.md` (inverse, target of v38e1.4)
- `closure-evidence-missing-contract-version.md` (sibling, target of v38e1.1)
- `closure-evidence-missing-public-lens-anchor.md` (sibling, target of v38e1.2)
- `session-handoff-v0.4-2026-04-27.md` (related: orchestrator-only handoff protocol)

## Status

Canonical for the flywheel-managed fleet. Every orchestrator pane (`flywheel:1`, `skillos:1`, `mobile-eats:1`, peer orchs in the ZestStream fleet) MUST observe this rule. Workers are not subject (workers do not own inbox-check responsibility; their dispatch packets carry context directly).
