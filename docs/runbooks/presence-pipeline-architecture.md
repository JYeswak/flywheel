# Presence Pipeline — Architecture

Decided 2026-05-14 by Joshua, as part of the ZestStream Public Launch Phase
goal. The flywheel already captures lessons inward — CASS, doctrine, skills,
beads. The presence pipeline is the **outward-facing half of the same loop**:
when work ships, it also becomes an on-brand public-presence update. Just as a
lesson becomes a skill or a doctrine internally, a shipped piece of work
becomes a post that points back to the canonical surface.

This is what makes the launch a *flywheel* and not a one-time push: every new
project keeps the public presence current, automatically, on-brand.

## The honest boundary — automate the toil, not the taste

"Automatically update our online presence" means automate the *toil*: drafting,
brand-gating, per-channel formatting, link-back wiring, queueing. It does NOT
mean unsupervised posting. Per the guardrails — AI proposes, Joshua disposes;
named-client-consent is per-surface; a fabricated claim is worse than silence.
So the pipeline generates and brand-gates a publish-ready queue; **Joshua
approves the publish.** The senior-dev-2026 take: the human stays on taste and
the publish button; everything before it is mechanical.

## The pipeline — six stages

1. **TRIGGER.** Not every commit. A *meaningful ship* — a project milestone, a
   shipped client outcome, a notable lesson promoted to a skill or doctrine, a
   public-surface launch. Curated, not firehose: a `presence-worthy` signal on
   the bead/closeout, or the petal-9 LEARN/REUSE artifact flagged for outward
   use. The flywheel surfaces candidates; it does not auto-fire on noise.

2. **DRAFT.** The brand-voice skill generates the copy from the real shipped
   work — what shipped, the arc it advances, the grounded receipt. One draft
   per target channel, each in that channel's format.

3. **BRAND-GATE.** Every draft passes the `zeststream-brand-voice` gate:
   composite >=95, no banned words, no superlatives, every claim grounded in
   `capabilities-ground-truth.yaml`. Arc not stats (doctrine II-2a). Jeffrey
   Emanuel cited + linked where his substrate is named. A draft that fails the
   gate is regenerated, not shipped.

4. **REVIEW.** The gated queue goes to Joshua. He approves, edits, or kills.
   This is the taste gate and the consent gate — client naming, anything
   sensitive, stops here unless he clears it per-surface.

5. **PUBLISH.** Approved drafts post to their channels. Initially this can be
   assisted-manual (the queue is publish-ready, Joshua posts); the wiring to
   post programmatically is a later increment, gated the same way.

6. **LINK-BACK.** Every post links to the canonical surface —
   flywheel.zeststream.ai or the relevant repo. Every channel bio points back.
   The whole point: all roads lead to the work.

## The channels

| Channel | Format | Role |
|---|---|---|
| Site (`flywheel.zeststream.ai`) | The canonical surface | Where everything points. Project work updates the site first. |
| X | Short, sharp, one receipt or one arc beat | Fast cadence; the operator's running log. |
| LinkedIn | Professional, longer-form, the arc | The operator credibility surface. |
| Instagram | Visual-first — the artifact, the before/after | Show the work, not describe it. |
| Facebook | Plain-language, owner-facing | The SMB-owner audience, least jargon. |

Each channel gets the *same* shipped fact, retold in that channel's register
and length — never copy-paste across channels (that fails the brand-voice
swap test and reads as a bot).

## Phase 0 — the social review (do this first)

Before the pipeline runs, the existing channels have to be made consistent:

1. **Inventory.** Joshua provides the live handles for X, LinkedIn, Instagram,
   Facebook (and any others). Do not guess or fabricate handles.
2. **Audit each channel** against the brand-voice skill and the design-and-
   story doctrine: is the bio on-brand? Is the operator arc consistent? Does it
   link back to the canonical surface? Is anything off-brand, stale, or
   contradicting the ground-truth?
3. **Punch-list per channel** — concrete fixes, surfaced to Joshua.
4. **Make every channel point back** — consistent bio, consistent link to
   flywheel.zeststream.ai, consistent operator framing.

The social review produces a per-channel punch-list; it is not the pipeline
itself, but the pipeline cannot ship on top of inconsistent channels.

## Grounding + brand constraints

- The `zeststream-brand-voice` gate is the floor for every draft — same as the
  site and the READMEs.
- No fabricated numbers, no client named without per-surface consent. The
  presence surface is *more* exposed than the site — the grounding rule is
  absolute here.
- Arc, not stats (II-2a). A post about a shipped project tells the arc it
  advances, not a pile of project numbers.
- First-person Joshua. Jeffrey Emanuel cited + linked (www.jeffreyemanuel.com)
  wherever his substrate is referenced.

## What this needs from Joshua

- The live channel handles (Phase 0 inventory).
- Taste sign-off on the first batch through the pipeline — calibrates the
  brand-gate against his eye, same way the flywheel site became the gate's
  fixture.

## Not done until

1. Phase 0 social review complete — every existing channel audited, punch-list
   delivered, channels made consistent and pointing back.
2. The pipeline's TRIGGER → DRAFT → BRAND-GATE → REVIEW path is built and one
   real shipped piece of work has gone through it end-to-end, on-brand.
3. The link-back is verified — every channel bio and the first batch of posts
   resolve to the canonical surface.

## Relationship to the other spines

Fifth architecture doc, alongside the home/operator, developer, methodology,
and repo-README spines. Same DNA: the brand-voice gate as the floor, II-2a,
attribution absolute, Joshua's eye as the ceiling. This one extends the set
outward — from the surfaces people land on to the channels that bring them.
