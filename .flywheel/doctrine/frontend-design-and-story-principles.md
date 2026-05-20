# Frontend Design & Story Principles — Research-Backed Foundation

Canonical 2026-05-14. The single source of truth for what makes a ZestStream
web page magnificent. The frontend quality gate, the `zeststream-brand-voice`
skill, the `@zeststream/story-system` package, and the `journey-architect`
skill all draw from this file — it is the foundational layer, not a style
opinion. When the research and a habit disagree, the research wins.

Synthesized from four independent research streams (2026-05-14): conversion &
persuasion, narrative & storytelling, visual craft, and a teardown of four
reference sites (frankentui.com, asupersync.com, agent-flywheel.com,
jeffreyemanuel.com). ≥2 independent sources back every core claim.

## How to read this

Each principle: **the rule**, *Why* (research basis), *Check* — tagged
**[M]** mechanical (a gate check can decide it) or **[E]** editorial (a human
or rubric judges it). [M] checks are FQ-15+ candidates for the quality gate.
[E] checks are the rubric the brand-voice and journey-architect skills apply.

**Applicability** follows the two-tier brand model. Parts III & V (visual
craft, motion) and the craft half of Part II are **Tier-1 — every project,
ZestStream or client**. Part I (message architecture), the operator/voice
half of Part II, and Part IV (trust & proof) are **strongest on
ZestStream-brand surfaces** — a client product tells its own story, but still
meets the craft bar.

## Grounding rule — read before using any example

Research agents and drafts will reach for plausible numbers and client names
("412 teams," "Blackfoot Telecom saved 40%"). **Every number and every named
client on a public surface must be real and, for clients, consent-cleared per
the named-client-consent rule.** A fabricated proof point is worse than no
proof point. This rule overrides every persuasion principle below: when the
research says "show a receipt" and no real receipt exists, the answer is to
get one or omit — never to invent one.

---

## Part I — Message Architecture (the persuasive spine of a page)

**I-1. The customer is the hero; the operator is the guide.**
The page's protagonist is the SMB owner and their goal — not ZestStream, not
Joshua, not the method. *Why:* StoryBrand (Miller); customer-as-hero narratives
drive far better recall and emotional commitment than company-as-hero. *Check
[E]:* the headline and value prop name the customer's problem or outcome, not
the company's process or features.

**I-2. One villain, one stake.** Name the single central problem the page
addresses. *Why:* multiple competing problems diffuse emotional investment
(narrative transportation; Hero's Journey). *Check [E]:* you can state the one
problem in a sentence; the page does not list three.

**I-3. Name the problem at three levels.** External (the surface issue),
internal (how it makes the owner feel — behind, stretched, unable to step
away), philosophical (the principle at stake). *Why:* StoryBrand — all three
present is what makes a problem land. *Check [E]:* all three are findable
above the fold.

**I-4. Stakes before solution.** Establish *why it matters* before *what you
do*. *Why:* a reader must care before they will attend to features; leading
with capability gives no reason to keep reading. *Check [E]:* the opening
says why this matters to the owner before describing the offer.

**I-5. The headline names the customer's outcome, not the company's process.**
*Why:* conversion research + StoryBrand; process-first headlines confuse
buyers. *Check [E]:* headline contains a customer segment, a number, or a
measurable outcome — not a method name.

**I-6. The 5-second test.** Stripped of design, the headline + subhead alone
make a fresh reader name the customer outcome. *Why:* first impression forms
in ~50ms, the stay/leave decision in ~5s (eye-tracking research). *Check [E]:*
hide the design; show only the text; a stranger names the outcome.

**I-7. Five elements above the fold, no more.** Specific headline, focused
subhead, one primary CTA, one trust signal, one supporting visual. *Why:*
landing-page research; more than five fractures the first decision. *Check
[M]:* count above-fold primary elements.

**I-8. Message hierarchy: outcome → proof → plan → CTA.** *Why:* StoryBrand +
conversion research; tech/process detail early loses buyers. *Check [E]:*
reading only section headers + one proof point still delivers the value.

**I-9. One primary CTA, named as an outcome.** ≤1 primary call to action;
button text names a result ("Map my workflow," "Get a 30-min Peel session"),
not "Learn more." Secondary CTAs sit lower in the visual hierarchy. *Why:*
choice overload depresses conversion. *Check [M]:* count primary CTAs; >2 =
fail. Never "Contact sales."

**I-10. A simple plan the owner can see themselves finishing.** 3–4 visible
steps, low-friction entry. *Why:* StoryBrand; a plan reduces the perceived
risk of the first step. *Check [E]:* the plan is stated and feels achievable.

**I-11. Every feature maps to an owner benefit.** Each capability mention
carries a "so that [outcome]" translation. *Why:* B2B buyers buy outcomes,
not features. *Check [E]:* every feature line has a visible benefit link.

**I-12. Paint the after-state.** Show what the owner's week looks like once
the work is done — concretely. *Why:* StoryBrand success/stakes; a vivid
"after" gives the reader something to move toward. *Check [E]:* a section
paints a specific post-engagement picture.

---

## Part II — Story Craft (how the copy is written)

**II-1. Narrative transportation beats argument.** Show a person, a moment, a
scene before pivoting to the solution. *Why:* Green & Brock (2000) + 2024
meta-analysis — transported readers adopt story-consistent beliefs far more
durably than readers of argument alone. *Check [E]:* the page opens on a
specific situation, not a list of company facts.

**II-2. Concrete over abstract — every claim is a number, a named thing, or a
specific scene.** Never a category abstraction ("powerful," "enterprise-grade,"
"reliable"). *Why:* dual-coding theory — concrete language is recalled ~40–50%
better. *Check [M]:* grep for adjectives/superlatives without an adjacent
number or named thing. (Existing gate: FQ-13.)

**II-2a. The story is the arc, not the stats.** A number from a single project
is a data point; the *arc* is the throughline that data point sits on. Tell
the underlying growth and compounding progress — then let specific numbers
make the arc concrete (II-2). A pile of pinned project numbers without an arc
is not a story; it does not tell the reader who is growing or where the work
is going. *Why:* Joshua, 2026-05-14 — "the story isn't about the commits
themselves, it's about the underlying growth and progress." *Check [E]:* can
you state the arc — the direction of growth — in one sentence? If the section
is only isolated stats, it has no arc.

**II-3. Absolute numbers over percentages and ratios.** "5 companies merged
into one" lands harder than "an 80% consolidation." *Why:* numerical-cognition
research (Kansas State) — absolute frequencies are judged larger and more
persuasive than mathematically identical ratios. *Check [E]:* metrics use
whole numbers and a reference class.

**II-4. Beat the curse of knowledge.** A newcomer to the domain understands
paragraph one without a dictionary. *Why:* Camerer/Loewenstein/Weber (1989) —
experts overestimate audience understanding by 20–30%. *Check [E]:* a reader
outside the domain can restate the first paragraph.

**II-5. No jargon without immediate plain-language translation.** *Why:*
curse of knowledge + conversion failure-mode research. *Check [M]:* a jargon
wordlist; each hit must be followed by a plain-language gloss. (Pairs with the
brand-voice banned-words list.)

**II-6. Customer-perspective pronoun ratio.** "you/your" outnumbers "we/our"
in body copy. *Why:* self-reference effect — readers attend to information
about themselves; customer-centric framing outperforms company-centric.
*Check [M]:* count pronouns in body copy; target you/your ≥ 60%. (On the
ZestStream brand, "I" is the operator voice and is allowed — see brand-voice
posture; "we/our" is still banned.)

**II-7. No meta-voice — the subject is never the page, the site, the company,
or the process.** Copy that says "this page explains," "our process is," "the
story shows" inverts focus from customer to company introspection. *Why:*
curse of knowledge + customer-centric copywriting; research-confirmed failure
mode. *Check [M]:* meta-voice pattern grep. (Existing gate: FQ-11.)

**II-8. Origin and case stories include the struggle, not just the victory.**
A "we tried X, it failed, then Y worked" arc is more credible than a clean
win. *Why:* origin-story trust research — vulnerability and transparency build
trust; clean-victory narratives read as self-indulgent. *Check [E]:* each
origin/case story names a real setback.

**II-9. SUCCESs as the editorial rubric.** Simple, Unexpected, Concrete,
Credible, Emotional, Stories. *Why:* Heath brothers, *Made to Stick* — these
six predict whether an idea sticks. *Check [E]:* a page review scores all six;
a section failing 3+ is rewritten.

---

## Part III — Visual Craft (magnificent, not template) — Tier-1, every project

**III-1. Modular type scale.** Every font size derives from one base
(16–18px) × a fixed ratio (1.2–1.333 common; 1.618 premium). No one-off sizes.
*Why:* Bringhurst/Tim Brown; every major design system uses a modular scale.
*Check [M]:* extract all type sizes; each = base × ratio^n (±1px rounding).

**III-2. Vertical rhythm.** All vertical spacing is a multiple of one baseline
unit. *Why:* baseline-grid research; rhythm is load-bearing for perceived
order. *Check [M]:* all margin/padding/gap ∈ {unit, 2×unit, 3×unit, …}.

**III-3. Spacing scale.** All spacing values come from a 4/8px base scale
(8, 16, 24, 32, 40, 48, 64). No arbitrary one-offs. *Why:* the 8pt grid is
adopted by Apple/Google/Atlassian. *Check [M]:* lint numeric spacing; reject
values not on the scale. (Generalizes existing FQ-03 token purity.)

**III-4. Line length / measure.** Continuous prose is 45–80 characters per
line (≈66 ideal); 30–50 on mobile. *Why:* typography consensus
(Butterick, Baymard, WCAG); measure is load-bearing for comprehension.
*Check [M]:* measure rendered text-container width at each breakpoint.

**III-5. Line-height.** ≥1.5 for body, ≥1.7 for long-form. *Why:* readability
research; tight leading degrades scan and comprehension. *Check [M]:* extract
line-height on body text blocks.

**III-6. Contrast — WCAG AA floor, AAA target.** Normal text ≥4.5:1 (AA),
≥7:1 (AAA, premium). Large text ≥3:1 (AA). *Why:* WCAG 2.2 — accessibility
law, not preference. *Check [M]:* automated contrast check on every
text/background pair. (Real gap — the gate currently only checks aria-label
presence.)

**III-7. Color restraint.** ≤3 primary colors + neutrals; one accent for
CTAs/highlights. *Why:* >3–4 hues degrades perceived harmony; luxury brands
use restraint. *Check [M]:* count distinct hues in the compiled CSS.

**III-8. Type pairing.** ≤2 font families, deliberately paired (compatible
x-height). *Why:* pairing research; more than two families reads as
unintentional. *Check [M]:* count @font-face / font-family declarations.

**III-9. Weight & size contrast across the hierarchy.** Consecutive heading
levels are distinct by size *and/or* weight; body is the lightest weight,
headings 600+. *Why:* hierarchy must survive the squint/grayscale test.
*Check [M]:* extract h1–h6 size+weight; no two consecutive levels within ~10%.

**III-10. Whitespace.** >30% negative space; content fills <70% of a
container. *Why:* whitespace research — uncluttered layouts improve
comprehension ~20%; restraint reads as confidence. *Check [M]:* content-area
ratio per major section.

**III-11. Gestalt proximity.** Inter-group spacing ≥2× intra-group spacing —
silence does the grouping. *Why:* NN/G — proximity is the primary grouping cue
and overrides other signals. *Check [M]:* compare group gaps to element gaps.

**III-12. Component consistency.** Identical components (buttons, cards,
inputs) share exact size, padding, type, color — one rule per component type.
*Why:* consistency-enforcement (not luck) is what separates premium from
template. *Check [M]:* extract all variants of each component; assert shared
specs.

**III-13. Decoration restraint.** ≤3 shadow depths; borders only where they
do real work (card edges, focus rings). *Why:* "border on everything" reads as
template. *Check [M]:* count shadow definitions and border coverage.

**III-14. Real artifacts over mockups.** Screenshots of actual output, real
diagrams, real data — not abstract illustration. *Why:* exemplar teardown —
"screenshot of the real thing" beats any designed visualization for
credibility. *Check [E]:* hero/proof visuals are real, not decorative.

---

## Part IV — Trust & Proof — strongest on ZestStream-brand surfaces

**IV-1. Receipts over adjectives.** Specificity and transparency outperform
persuasion words. *Why:* every reference site (frankentui, asupersync,
agent-flywheel, jeffreyemanuel) earns trust through specifics, not
superlatives; Cialdini. *Check [E]:* each proof claim carries a real number, a
named thing, or a verifiable link.

**IV-2. Named operator, not a faceless author.** A real person, ideally with a
photo and links. *Why:* exemplar teardown — bidirectional author links are a
trust signal; "we" hides accountability. *Check [E]:* the operator is named.
(Pairs with brand-voice three-moves: name Joshua.)

**IV-3. Radical transparency builds trust.** Honest cost, honest "this is not
for you if…" exclusion criteria. *Why:* agent-flywheel and frankentui both do
this — confidence enough to repel a misfit buyer reads as credibility. *Check
[E]:* the page tells the reader who it is *not* for.

**IV-4. Live, verifiable artifacts.** Links resolve to real repos, real demos,
real work. *Why:* "click here and inspect it yourself" outranks a curated
portfolio. *Check [M]:* every artifact link resolves (no 404s).

**IV-5. Social proof carries name + metric + timeframe — or it is omitted.**
And it is never fabricated or used without consent. *Why:* Cialdini social
proof + the grounding rule above. *Check [E]:* every testimonial/result has
≥2 of {named source, measurable result, timeframe} and is consent-cleared.

---

## Part V — Motion — Tier-1, every project

**V-1. Reduced motion respected.** `prefers-reduced-motion: reduce` snaps to
the end state. *Why:* ~35% of adults over 40 have a vestibular condition —
medical accessibility. *Check [M]:* existing gate FQ-06.

**V-2. Purposeful motion only.** Animation serves feedback, state change, or
guidance — never decoration. ≤300ms micro-interactions, ≤600ms macro; no loops
unless user-triggered. *Why:* motion research; decorative motion is noise.
*Check [M]:* audit animation durations and loop declarations.

**V-3. No parallax or scroll-jacking.** *Why:* every reference site avoids it;
restraint reinforces technical credibility. *Check [E]:* no scroll-hijacking
behavior.

---

## Gate mapping — what exists, what is new

Already in the frontend quality gate: II-2 (FQ-13), II-7 (FQ-11), V-1 (FQ-06),
III-3 partial (FQ-03). FQ-08/09/12 cover Tier-2 storytelling surfaces.

**FQ-15+ candidates (all [M], wire in after the flywheel site is the
calibration fixture):** III-1 type scale, III-3 spacing scale, III-4 line
length, III-5 line-height, III-6 contrast ratios, III-7 color restraint,
III-8 type pairing, III-9 weight contrast, III-10 whitespace, III-11 proximity,
III-12 component consistency, III-13 decoration restraint, II-5 jargon-gloss,
II-6 pronoun ratio, I-7 above-fold element count, I-9 primary-CTA count,
IV-4 link resolution, V-2 motion budget.

**Editorial rubric (the [E] checks):** owned by the `zeststream-brand-voice`
and `journey-architect` skills. The gate is the floor; the rubric is the
ceiling; Joshua's eye is final sign-off.

The sequencing discipline holds: do not author an [M] gate check without a
known-good fixture to calibrate against. The flywheel public site, once it
passes Joshua's eye, becomes that fixture.


## Meta-Learning Cross-References (2026-05-19)

This doctrine surface was backfilled during JSM fleet audit batch-3 so recent doctrine cites the relevant MP lessons directly.

- **MP-09 — info-source watchtower:** see `/Users/josh/Developer/skillos/.flywheel/doctrine/meta-learnings/MP-09-info-source-watchtower.md` for the canonical pattern.
- **MP-13 — living documentation:** see `/Users/josh/Developer/skillos/.flywheel/doctrine/meta-learnings/MP-13-living-documentation.md` for the canonical pattern.
- **MP-28 — checklist before claim:** see `/Users/josh/Developer/skillos/.flywheel/doctrine/meta-learnings/MP-28-checklist-before-claim.md` for the canonical pattern.
