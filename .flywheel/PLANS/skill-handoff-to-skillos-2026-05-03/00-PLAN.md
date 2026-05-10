---
title: "Converged plan: skill-handoff-to-skillos"
type: plan
created: 2026-05-04
frontmatter_source: scaffold-doc-frontmatter
---

# Converged plan: skill-handoff-to-skillos

> Phase 2 REFINE output. Self-authored. Single round (steady-state by construction).

## One-paragraph summary

Every skill created in any flywheel-managed session must flow into the skillos-curated canonical skill pack via a standardized fleet-mail handoff. The handoff carries the schema skillos already expects (proven by canonical-cli-scoping v0.2). Implementation: 1 message template, 1 helper script, 1 dispatch-template acceptance gate, 1 backfill-audit script, 1 fuckup class, 1 canonical L-rule, 1 cross-orch announcement to skillos. Total 7 deliverables across 8 beads. Plan-space tokens only this session; beads dispatched after current ready queue drains.

## Architecture

```
flywheel-orch session                     skillos-orch session
  │                                          │
  ├─ worker creates skill                    │
  ├─ worker reserves files (L51)             │
  ├─ worker writes ~/.claude/skills/<x>/     │
  ├─ worker releases files                   │
  ├─ worker runs handoff-script ─────────────┼─→ fleet-mail message lands
  │     ↓                                    │     ↓
  │   message_id logged in callback          │   skillos tick reads inbox
  │                                          │   skillos creates intake bead
  │                                          │   skillos hardens to v<next>
  │                                          │   skillos updates qdrant catalog
  │                                          │   skillos writes receipt JSON
  │                                          │
  └─ orchestrator audits handoff coverage    │
        nightly via cron                     │
```

## Decisions locked

1. **Information-flow framing (Meadows #6):** the gap is "skillos doesn't know what flywheel ships". Fix the channel, not the actor.
2. **Skillos owns hardening, flywheel owns notification.** Cross-orch boundary preserved.
3. **Fleet-mail (not ntm send) for the channel.** L61 says cross-session uses both; but the *handoff payload* is the message, not the worker invocation. ntm send carries pings/acknowledgements; fleet-mail carries the schema'd payload.
4. **Backfill audit runs nightly.** Cron entry, not one-shot. New skills miss the window 0-24h max.
5. **Ownership declaration mandatory.** Sender must declare local|upstream so skillos doesn't waste intake on forbidden-distribution skills.
6. **Self-author this plan, defer Phase 5 polish to worker.** Per Meadows analysis: prose-only synthesis where I have full context; worker fanout would not improve quality and would block 60-90min on pane capacity.

## Anti-decisions (explicit non-choices)

- **Not** auto-promoting skills to qdrant from flywheel side. Skillos is the catalog authority.
- **Not** modifying skillos's GOAL.md or rotating its mission. (Cross-orch boundary; we surface concerns via agent-mail, skillos orch decides.)
- **Not** using ntm send for the payload. Wrong substrate for schema'd messages.
- **Not** running adversarial review of info-source-watchtower itself. That's the skillos hardening cycle's job.
