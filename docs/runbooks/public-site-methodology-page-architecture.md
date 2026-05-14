# Methodology Page — Message Architecture

Decided 2026-05-14 by Joshua. The current `site/methodology/index.html` is
"really shitty" — thin, jargon-y, and it does not actually explain the method.
It should map the surfaces of the Flywheel + SkillOS ecosystem, center on
Donella Meadows systems thinking and how Joshua *applies* it, and cover the
safety mechanisms in real depth.

## The reframe — study material, not a pitch

Same framing as the developer page: "this is something we expect others to
STUDY and learn from — coming back to as they need to revisit a topic." The
methodology page is the intellectual spine of the whole site. It is where a
reader goes to understand *why* the work can be trusted — not because Joshua
says so, but because the method is inspectable. Depth and structure are the
bar. Pitch fluff fails it.

## Audience and job

A reader who wants to understand *how the work actually gets done* — a
developer evaluating the ecosystem, an SMB owner deciding whether the rigor is
real, a peer studying the approach. The job: they leave understanding that the
method is a coherent system — Meadows systems thinking as the lens, the
Flywheel + SkillOS surfaces as the structure, and defense-in-depth safety as
the guarantee — and that every part of it is inspectable.

## Grounding constraints — non-negotiable

- **Cite Donella Meadows.** Her framework is hers — "Meadows' twelve leverage
  points," "per *Thinking in Systems*," "the Meadows iceberg." Never present
  systems thinking as Joshua's invention. (Brand-voice attribution rule.)
- **Cite Jeff Emanuel** for any of his substrate named here (NTM, Agent Mail,
  beads, CASS) — Dicklesworthstone, never Joshua.
- **The worker must invoke the `donella-meadows-systems-thinking` skill** when
  writing this page's content. The skill carries the primary-source citations
  and verified ZestStream exemplars — methodology copy that gets Meadows wrong
  or shallow is a hard reject. The spine below is the architecture; the skill
  supplies the accurate substance.
- **Study-grade depth, no superlatives.** Explain mechanisms concretely. Every
  safety mechanism is named with the failure mode it exists to prevent.
- **First-person Joshua**, methodology register — neither the SMB-owner pitch
  voice nor raw internal ops jargon.

## The spine — section order and the job each section does

1. **Hero — what the methodology is.**
   Plainly: this is how Joshua thinks about the work. Systems thinking applied
   to agentic coding — not a process diagram, a way of seeing. Job: the reader
   knows they are about to study a coherent method, not read a pitch.

2. **The lens — Donella Meadows systems thinking.**
   The intellectual foundation. Explain, plainly and accurately (from the
   skill): stocks and flows, feedback loops (balancing vs reinforcing),
   leverage points, and the iceberg — events vs. patterns vs. structure. And
   *why* it matters: you do not fix the event, you find the structure that
   keeps producing it. Cite Meadows. Job: give the reader the lens before
   showing them what Joshua sees through it.

3. **Applied — how Meadows shows up in the actual work.**
   Concrete, not abstract. The quality gate is a *balancing feedback loop*.
   Doctrine accretion is a *stock* that needs a retention flow. A recurring
   dirty working tree is a *structure* problem, not an event problem. Joshua
   intervenes at *leverage points* — the rules of the system, the information
   flows — not at symptoms. Use real flywheel examples. Job: prove the lens is
   load-bearing, not decoration.

4. **The ecosystem surfaces — Flywheel + SkillOS mapped.**
   Map the actual surfaces so a reader can navigate them. **Flywheel:** the
   repo-local operating loop — mission, goal, state, the tick, dispatch, beads,
   doctrine, daily reports, closeout receipts. **SkillOS:** the capability
   layer beside it — skills as explicit, validated capabilities with adoption
   proof and pack-level status. How they relate, and how they sit on Jeff's
   substrate. Job: turn "an ecosystem" into a legible map the reader can hold.

5. **The safety mechanisms — defense-in-depth, in depth.**
   Joshua's explicit ask: cover these properly. Each mechanism named with the
   *observed failure mode* it exists to prevent — that is what makes it study
   material rather than a feature list. The destructive-command guard, the
   cross-repo write guards, the quality gates, recovery bundles before
   destructive operations, the repo-hygiene invariants. The principle:
   safety is layered (Axiom 6 — defense-in-depth) because no single gate is
   trusted alone. Job: the reader understands the safety net is shaped by real
   incidents, not theater.

6. **The throughline — why this produces trustworthy work.**
   Tie it together: a systems-thinking lens + mapped, inspectable surfaces +
   layered safety = work whose trustworthiness you can *verify*, not just take
   on faith. The methodology is the credibility. Job: the reader leaves
   understanding that "trust the method" means "inspect the method."

## Cuts from the current page

- The "reduced lane / support tiers / isolated runtime receipts" framing —
  internal ops vocabulary, not a methodology. The fact that it runs across
  multiple agents belongs in section 4, mapped, not as receipt jargon.
- The SMB-owner canon line — wrong register for this page.
- Any section that only describes machinery without connecting it to the
  systems-thinking lens or a real failure mode.

## Relationship to the other spines

This is the third site-architecture doc, alongside
`public-site-message-architecture.md` (home/operator spine) and
`public-site-developer-page-architecture.md`. Shared DNA: study-grade where
the audience is technical, the brand-voice gate as the floor, attribution
rules absolute, Joshua's eye as the ceiling. The "study material, not a pitch"
principle now spans two pages and belongs in
`.flywheel/doctrine/frontend-design-and-story-principles.md`.
