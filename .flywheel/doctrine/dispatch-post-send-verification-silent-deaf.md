---
title: "Dispatch Post-Send Verification (Silent-Deaf Class)"
type: doctrine
created: 2026-05-11
frontmatter_source: scaffold-doc-frontmatter
---

# Dispatch Post-Send Verification (Silent-Deaf Class)

Version: `dispatch-post-send-verification-silent-deaf/v1`
Owner: orchestrator (dispatcher) + worker (callback-sender)
Status: canonical, shipped 2026-05-11
Source bead: flywheel-2xdi.109 (memory-without-cross-link wire-in)

## TL;DR

After `ntm send <session> --pane=N`, the "Sent to pane N" transport ack
does NOT guarantee the worker actually processed the dispatch. Poll
robot-tail within 5–30s post-send to confirm worker transitioned out of
idle chevron. Re-send same packet (same task_id) if pane idle. This is
Shape G in the audit-machinery-hygiene cluster (transport-layer
distinct from classification-layer parser-artifacts).

## Canonical memory source

This doctrine summarizes two canonical memory sources:

- `feedback_dispatch_post_send_verify_for_silent_deaf.md` — the META-RULE
  memory documenting the Shape G silent-deaf class. Known exemplar:
  flywheel-bg06b first dispatch (2026-05-10). Joshua flagged manually
  ("pane 3 is idle") after ~6 min phantom occupied state.
- `feedback_verify_ntm_send.md` — the older dispatch discipline memory that
  names the same operator rule in plainer terms: after `ntm send`, verify the
  target pane is working on the intended task, not stale previous work.

Read the memories for full pattern detail and below-trauma-class tracking
context.

## The pattern

### Why it happens

The codex/claude worker pane can receive an `ntm send` packet at the
transport layer (text echoed in scrollback) without the agent's input
handler picking it up. The orchestrator records a `dispatch_sent` log
row, but the worker never activates. To the saturation tracker, the
pane appears occupied; to a human observer, it's idle at the chevron.

### Post-send verification primitive

After every dispatch (orch-side OR worker-side callback resend):

```bash
ntm send <session> --pane=N "<packet>"
sleep 5-10
ntm --robot-tail=<session> --panes=N --lines=10
```

Inspect output: worker should have transitioned to a working state
(`Bootstrapping...`, `Searching for pattern...`, `Reading file...`).
If still at bare chevron with dispatch text echoed but no agent
processing, the dispatch was silent-deaf.

### Re-send mitigation

Re-send the SAME packet — same task_id, same path. Don't rebuild;
don't escalate. If re-send also fails, escalate to respawn via
`/flywheel:respawn <session> --panes=N`.

### Callback envelope discipline

Workers MUST include `callback_delivery_verified=true|false|unknown`
in DONE/BLOCKED/DECLINED callbacks. The `true` value asserts the
worker explicitly verified callback delivery post-send (not just that
transport returned success). The dispatch template's
`VERIFY-CALLBACK BLOCK` enforces this contract.

## Anti-pattern

Trusting "Sent to pane N" transport ack alone and walking away.
Symptoms: phantom `dispatch_sent` log entries; saturation tracker
reports occupied panes that are actually idle; tick-cycle delays as
"in-flight" dispatches stall silently.

## Behavioral vs name cross-linking

This doctrine doc gives the memory a **name cross-link** so
gap-hunt-probe's memory-without-cross-link class clears. The memory's
discipline was ALREADY embedded behaviorally — the dispatch template
references `callback_delivery_verified` ≥6 times — but the probe's
name-grep didn't see that as a citation.

See `.flywheel/doctrine/cross-repo-consumer-vs-mutator-boundary.md`
for sister doctrine pattern.

## Sister doctrine

- Dispatch template's `VERIFY-CALLBACK BLOCK` (runtime enforcement of
  this contract): `~/.claude/commands/flywheel/_shared/dispatch-template.md`
- Sister cluster doctrine: `audit-machinery-hygiene-discipline.md`
  (Shape G transport-layer is distinct from classification-layer
  parser-artifacts)
- Memory `feedback_dispatch_post_send_verify_for_silent_deaf` (above-cited
  canonical source)
- Memory `feedback_verify_ntm_send.md` (plain-language predecessor: verify
  `ntm send` landed and the pane is working on the right task)

## Conformance

A bead's dispatch + worker callback prove conformance via:
- Worker callback includes `callback_delivery_verified=true`
- Worker performed robot-tail check before sending callback
- If re-send was needed, callback notes evidence

## Below-trauma-class tracking

Currently one confirmed exemplar (flywheel-bg06b 2026-05-10). 4-instance
trauma class promotion threshold not met. Track via fuckup-log if
recurs: `failure_class=dispatch_silent_deaf_shape_g`.


## Meta-Learning Cross-References (2026-05-19)

This doctrine surface was backfilled during JSM fleet audit batch-3 so recent doctrine cites the relevant MP lessons directly.

- **MP-09 — info-source watchtower:** see `/Users/josh/Developer/skillos/.flywheel/doctrine/meta-learnings/MP-09-info-source-watchtower.md` for the canonical pattern.
- **MP-13 — living documentation:** see `/Users/josh/Developer/skillos/.flywheel/doctrine/meta-learnings/MP-13-living-documentation.md` for the canonical pattern.
- **MP-28 — checklist before claim:** see `/Users/josh/Developer/skillos/.flywheel/doctrine/meta-learnings/MP-28-checklist-before-claim.md` for the canonical pattern.
