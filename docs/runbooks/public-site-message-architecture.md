# Public Site Message Architecture — Operator Spine

Decided 2026-05-14 by Joshua. Every prior rewrite of the public site was
rejected because it had no spine — it sold the *method* (Yuzu / Flywheel /
proof-path / trust-controls, described four times) and never sold the
*outcome* or *why Joshua*.

The strategic constraint: Flywheel is pre-customer (the "internal proof first"
decision), and clients cannot be named without per-surface consent. So the
proof that carries "why work with me" is **Joshua's operating background** —
not a client outcome, not the method.

This v2 folds in the real operator bio from zeststream.ai/about and the
`zeststream-brand-voice` skill's enforceable constants. The rewrite passes
through the brand-voice gate — it is not optional.

## Operator bio — grounded facts (use these, not a thin summary)

Source: zeststream.ai/about (live, public) + Joshua direct, 2026-05-14.
The earlier draft used a thin "12 years, MBA, ran ZIRKEL." The real story is
far stronger and is the actual spine:

- **25+ years in the operational trenches** — started working at 15; ~17 years
  in banking & finance, then business management and team-building.
  Finance → banking → energy → telecom → now AI.
- Graduated into the 2008 crash as a fresh-licensed financial advisor in
  Michigan. Six figures of student debt, no family money. Licensed banker by
  day, kept a preschool's books at night. Then started his own accounting firm.
- Director of Financial Operations at an energy consulting company — **cut his
  own role from 40 hours a week to 15.** This is the receipt for the canon
  line: he has been buying back time his entire career.
- **12 years at ZIRKEL** (wireless ISP) — took it paper-to-digital, built the
  ops team, earned the MBA while running the business full-time, **led the
  sale in 2024** (1 successful exit).
- Stayed through a **5-company merger**, became Director of Operations at the
  combined entity (ElektraFi). Offered President of Operations in late 2025 —
  turned it down to build with AI full-time.
- **4.0 MBA, Jack Welch Management Institute.**
- Now: own time, own money, no investors, no partners.

The throughline — and the spine of the whole page: **"Most of my life,
something has broken and I've had to build the thing that fixes it."** Cutting
his own 40-hour role to 15 is the pattern of his whole career. That pattern
*is* "I help SMB owners buy their time back."

## Brand-voice gate — non-negotiable (from the zeststream-brand-voice skill)

The rewrite is invalid if it violates any of these. Run the skill's gate
before handing to Joshua.

- **BANNED WORD — "handoff" / "handoffs".** It is a consultant tell on the
  banned list. The current draft is built around it ("fixing the handoffs")
  and would auto-reject. Replace with: *the work between the tools*, *the route
  between them*, *what happens between the software*, *the copy-check-chase-
  remember work*.
- **Other banned words** present-risk in the draft: "transformation" (banned —
  even when quoting the bad pitch; rephrase to "a big change"), "platform",
  "seamless", "robust", "enterprise", "leverage" (verb), "streamline" (verb),
  "deliverable", "stakeholder". Full list lives in the skill's `voice.yaml`.
- **Canon line, verbatim, at least once:** `I help SMB owners buy their time
  back.` A hero variant ("get their Saturdays back") is fine as the headline,
  but the verbatim canon must appear somewhere on the page.
- **First-person singular only.** No "we", "our", "our team", "us". ZestStream
  is Joshua, solo.
- **Three moves, mandatory on every conversion section:** (1) name Joshua —
  never a faceless "we"; (2) show a receipt — a number, a benchmark, a real
  fact (25+ years, 5 companies merged, 4.0 MBA, 40→15 hours, 1 exit); (3)
  invite, don't pitch — end with a low-friction ask, never "Contact sales."
  If a section can't carry all three, shrink it until it can.
- **Trademark rendering:** `The Yuzu Method ™` and `Peel. Press. Pour.™` —
  ™ not ®, the mark is pending.
- **The four tests, per sentence:** swap test (could a competitor's name swap
  in? then it's too generic), specificity test (names real tools/numbers?),
  differentiation test (ties to something only Joshua does?), business-type
  test (register matches an SMB owner?).
- **No hype framing:** no "transformation", "revolutionize", "game-changing".
  No enemy/doomer framing about AI — partnership frame only.

## Voice exemplars — the register to match (verbatim from /about)

- "I'm Joshua. I build things that work."
- "Most consultants hand you a slide deck and leave. I hand you a working
  system."
- "Most of my life, something has broken and I've had to build the thing that
  fixes it."
- "I cut my own role from forty hours a week to fifteen ... that's the pattern
  of my whole career."
- "The work ships. Receipts over promises."
- "If any of that sounds like a fit, the consult link is below. If not, thanks
  for reading this far."

Plain, direct, first-person, earned. No throat-clearing, no hype, no abstraction.

## The spine — section order and the job each section does

1. **Hero — who Joshua is, and what it is costing them.**
   First sentence establishes Joshua as a 25+-year operator, not an AI vendor.
   Then the owner's real stake — the felt cost: working Saturdays, can't step
   away without becoming the backup system, a job fell through a crack and
   cost a customer. Job: in three seconds the owner knows who this is and that
   he understands their problem.

2. **The turn — it is not your software, it is the work between it.**
   "You already bought the tools. The expensive part is the copy, check,
   chase, and remember work *between* them. That is an operations problem —
   and operations is what I have fixed for 25 years." Job: bridge Joshua's
   background to their pain. (Note: "the work between" — NOT "handoffs".)

3. **Why me — the differentiator.** (Currently the strongest part of the
   worker's draft — keep the structure.) Joshua versus the typical AI
   consultant: most people selling AI have never run a P&L; Joshua has run
   operations for 25 years and owned the consequences when the route was
   wrong. He does not start with a model — he triages the route eating your
   week. The Yuzu Method appears *here*, as evidence of how an operator works.
   Carry a receipt: 5 companies merged, 4.0 MBA, the 40→15-hour cut.

4. **What you get — the outcome.**
   Concrete and outcome-framed: in weeks, not a [big change] project — one
   route mapped, one fix shipped, a clear before/after of what it saved.
   "You keep the operating judgment; I wire the system." "The work ships.
   Receipts over promises."

5. **Why you can trust it.**
   Fold the old "trust controls" here, reframed per-fear: the owner's actual
   worry, then why it does not apply to working with Joshua. "Blocked is
   better than bluffing" is the trust anchor. Public-git-history collapses to
   ONE line. Job: dissolve the risk of hiring an AI person.

6. **The offer and next step.**
   Keep — it is close. Low-friction invitation: "Send me one workflow that
   keeps getting copied or chased. Redacted is fine." A 20-minute Peel session
   is the canonical ask. Never "Contact sales."

## Cuts

- **"A real slice, from this repo" — CUT entirely.** The website talking about
  its own quality gate. The purest "words on the page to put words on the
  page." No replacement until a real *client* slice exists to tell.
- **"Proof path" (Map / Block / Verify / Reuse) — CUT or fold.** The method
  described again. The one usable idea — git history survives inspection —
  becomes a single line in section 5.
- **"For reviewers" — SHRINK** to a minimal footer-adjacent block.
- **Hero "scene" (Email / CRM / Calendar / Invoice nodes) — REDESIGN.** It is
  method-theater, and the absolutely-positioned nodes overlap the hero text on
  wide viewports ("words on words" — Joshua flagged it). The worker's v2
  replaced it with an operator-board aside, which is the right direction —
  verify it never collides with text at any width.

## Gate follow-up (not now)

FQ-11 catches "subject = the page." It does NOT catch "subject = the method,
on loop", "section with no persuasive job", or banned-word/voice violations —
which is why the page scored 12/0/0 and was still rejected. The fix is to wire
the `zeststream-brand-voice` skill's gate into the frontend quality gate as
FQ-15, *after* this page is fixed and can serve as the calibration fixture.
