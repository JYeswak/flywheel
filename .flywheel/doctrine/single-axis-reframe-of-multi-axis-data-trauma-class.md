---
title: "Single-Axis Reframe of Multi-Axis Data (Recurring Trauma Class)"
type: doctrine
created: 2026-05-11
frontmatter_source: scaffold-doc-frontmatter
n_trigger: 2
trauma_class: meta-extraction-drift
instance_1: feedback_continuation_vs_new_pivot_framing_discipline (2026-05-11 Joshua-correction to skillos:1)
instance_2: feedback_bimodal_data_both_and_reading_not_single_axis_reframe (2026-05-11 skillos:1 partial-accept of my reframe)
status: canonical
canonical_class: trauma-class-meta-pattern
---

# Single-Axis Reframe of Multi-Axis Data (Recurring Trauma Class)

Version: `single-axis-reframe-of-multi-axis-data/v1`
Owner: every orchestrator + worker drafting cross-orch packets or reframing measurement data
Status: canonical, N=2 trigger fired 2026-05-11
Source bead: `flywheel-0mw8v`
Trauma class: META-EXTRACTION-DRIFT

## TL;DR

When you encounter data with **multiple independent axes**, the temptation to compress it into a **single-axis reframe** is a recurring cognitive trauma class. Both observed instances on 2026-05-11 collapsed multi-axis information into a single-axis narrative; both required external correction. The discipline: **name the axes first, then reason axis-by-axis** before drafting any reframe.

## The META-pattern

A reframe is **single-axis** when it answers "what is this data telling us?" with one explanation that covers all dimensions. It is **multi-axis** when it acknowledges that distinct dimensions carry distinct stories that are not substitutable.

Single-axis reframes feel cleaner. Multi-axis reads feel messier. The data structure decides which is honest, not the writer's appetite for tidiness.

## N=2 instances (2026-05-11 same session)

| # | Instance | Axes that exist | Single-axis collapse | Correction source |
|---|----------|-----------------|----------------------|--------------------|
| 1 | `continuation-vs-new-pivot` (skillos:1 → mobile-eats:1) | CONTINUATION / NEW-PIVOT / REFRAME-WITHOUT-HALT (3-class taxonomy) | Framed already-ratified Rust direction as NEW-STRUCTURAL-DECISION | Joshua mid-tick: "this is continuation, not new pivot" |
| 2 | `bimodal-both-and` (my reframe → skillos:1) | substance-quality (87.5%) / form-mismatch (3%) — bimodal | Reframed 45.3% as "HEURISTIC-MISMATCH not authoring-quality" (rubric-bias-only) | Skillos:1 PARTIAL-ACCEPT: "BOTH-AND not single-axis" |

Both instances share the META-shape: **the data had structure with N≥2 axes; the reframe compressed to N=1; the corrector restored N≥2.**

## Rule (canonical)

```text
Before drafting any reframe of structured data, run the 3-step axis probe:

  1. ENUMERATE: what dimensions/axes does this data have?
     (taxonomic classes / score dimensions / cohort splits / etc.)

  2. PROBE EACH AXIS: does each carry independent signal,
     or are they substitutable for one explanation?

  3. CLASSIFY THE REFRAME:
     - SINGLE-AXIS-HONEST: data is genuinely 1-dim; reframe stays 1-axis
     - MULTI-AXIS-COLLAPSE: data has ≥2 axes; reframe must preserve them
     - PARTIAL-MERGE: some axes substitutable, others independent;
                      reframe must name which is which

When in doubt, write the reframe in BOTH-AND form. Single-axis collapses
are recoverable by adding axes back; honest multi-axis reads cannot be
shortened without losing signal.
```

## When to apply

- Drafting cross-orch packets that re-frame an in-flight or just-decided topic
- Interpreting measurement output (rubric scores, calibration ceilings, cohort distributions)
- Replying to handoffs that surface bimodal/multi-modal data
- Authoring evidence packs that summarize partial-success outcomes
- Any moment a single-word/single-phrase reframe feels tempting

## Why it exists

The pattern fires twice in one day across two different orchestrators (skillos:1 + me). That's the canonical N=2 trauma-class trigger — pattern is durable, not coincidental.

The cognitive shortcut: multi-axis data is harder to hold; a single-axis reframe makes it portable. But portability comes at the cost of accuracy when the axes carry independent signal. In cross-orch communication especially, the single-axis collapse propagates: the receiver inherits the compressed frame and the original axes are silently dropped.

## Sister rules / memory crosslinks

- `feedback_continuation_vs_new_pivot_framing_discipline.md` (instance 1)
- `feedback_bimodal_data_both_and_reading_not_single_axis_reframe.md` (instance 2)
- `inbox-discipline-missed-during-deep-burndown-motion.md` (cross-orch hygiene; related)
- `outbox-discipline-cross-orch-ship-notification.md` (cross-orch hygiene; related)

## Mechanization

Embed the 3-step axis probe as a worker self-check before any cross-orch packet send:

```bash
# Pre-send axis probe (informal)
echo "AXIS PROBE for $packet_id:"
echo "  1. Axes enumerated: <list each>"
echo "  2. Independent signal per axis: <yes/no per axis>"
echo "  3. Reframe class: <single-axis-honest|multi-axis-collapse|partial-merge>"
echo "  4. If multi-axis-collapse risk: rewrite in BOTH-AND form"
```

At N=3 (next instance lands), promote to skill: `pattern-emerged-multi-axis-data-discipline-3-step-probe`.

## Conformance

A reframe conforms via:
- Cited axes (≥2 if multi-axis data) named in evidence pack
- Reframe class explicitly stated (single/multi/partial)
- BOTH-AND form used when multi-axis-collapse risk is present
- Original data structure preserved in the evidence trail (not lossy)

## Lifecycle

Trauma-class doctrines escalate to skill at N=3+ recurrences. Current N=2 (this doctrine codifies the pattern at the empirically-observed threshold).

## Cross-references

- `cluster-maintainer-pattern.md` (sister meta-pattern: N=3 batch fix recurrence)
- `option-e-cross-orch-fuckup-log-fold-up.md` (sister meta-pattern: cross-orch promotion wave)
- `bead-hypothesis-starting-point.md` (sister discipline: probe before conclude)

## Public-lens self-check (Three Judges)

- **Skeptical operator:** "Does this name a concrete failure mode?" Yes — both instances cited with specific 2026-05-11 ts + corrector identity.
- **Maintainer:** "Can the rule extend to new instances?" Yes — 3-step probe + N=3 promotion path explicit.
- **Future worker:** "Can I apply this before sending a packet?" Yes — mechanization snippet copy-pasteable.


## Meta-Learning Cross-References (2026-05-19)

This doctrine surface was backfilled during JSM fleet audit batch-3 so recent doctrine cites the relevant MP lessons directly.

- **MP-17 — secret emission discipline:** see `/Users/josh/Developer/skillos/.flywheel/doctrine/meta-learnings/MP-17-secret-emission-discipline.md` for the canonical pattern.
- **MP-29 — production safety guardrails:** see `/Users/josh/Developer/skillos/.flywheel/doctrine/meta-learnings/MP-29-production-safety-guardrails.md` for the canonical pattern.
- **MP-30 — human-gated invasiveness:** see `/Users/josh/Developer/skillos/.flywheel/doctrine/meta-learnings/MP-30-human-gated-invasiveness.md` for the canonical pattern.
