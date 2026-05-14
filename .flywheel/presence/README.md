# Presence pipeline — working directory

The outward-facing half of the flywheel loop: when work ships, it also becomes
an on-brand public-presence update. Architecture and the six-stage spine live
in `docs/runbooks/presence-pipeline-architecture.md`.

## What is built

`scripts/presence_queue.py` implements the buildable-now path:
**TRIGGER → DRAFT → BRAND-GATE → REVIEW**. It takes a *ship descriptor* — a
curated, grounded JSON record of one meaningful ship — drafts one
channel-shaped post per channel (X, LinkedIn, Instagram, Facebook), runs every
draft through the mechanical brand gate (banned words/phrases,
first-person-singular pronouns, Jeffrey Emanuel attribution, link-back
presence, channel length, arc-not-stats per doctrine II-2a), and writes a
publish-ready queue file for review.

```bash
python3 scripts/presence_queue.py --ship ship.json --queue-dir .flywheel/presence/queue
```

A ship descriptor:

```json
{
  "title": "what shipped",
  "arc_beat": "the arc this advances — not a pile of numbers (II-2a)",
  "receipt": "the one grounded fact: a number, a repo, a SHA",
  "receipt_source": "ground-truth id, or a repo path / URL that grounds it",
  "link_back": "https://flywheel.zeststream.ai/...",
  "substrate_credit": ["NTM", "beads"]
}
```

`substrate_credit` is optional; naming any of Jeffrey Emanuel's tools (NTM,
Agent Mail, beads, CASS) — in the field or anywhere in the drafted text —
makes the attribution check mandatory.

## What is NOT built here — Joshua's gates

- **REVIEW / PUBLISH.** The queue is publish-ready; Joshua approves, edits, or
  kills. This is the taste gate and the per-surface consent gate.
- **The live social review (Phase 0).** Auditing the existing X / LinkedIn /
  Instagram / Facebook / YouTube channels needs the live handles. This pipeline
  never guesses or fabricates a handle.

## queue/

`queue/` holds generated, transient review artifacts — gitignored output, same
rule as every other regenerable output directory (see
`.flywheel/doctrine/repo-hygiene-operational-protocol.md`). Approved posts and
their link-back verification belong in a durable record, not here.
