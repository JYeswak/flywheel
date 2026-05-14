# Developer Page — Message Architecture

Decided 2026-05-14 by Joshua. The current `site/for-developers/index.html`
"reads like a bad book": wall-to-wall internal jargon ("reduced lane",
"4/4 supported agent lanes", "no ambient substrate", "isolated runtime
receipts"), meta-voice about its own proof machinery, the *SMB-owner* canon
line on a developer page, and — most telling — **it never mentions Jeffrey
Emanuel at all**, when his open-source substrate is the foundation the whole
ecosystem stands on.

## The reframe — this is study material, not a pitch

Joshua: "this is something we expect others to STUDY and learn from — coming
back to as they need to revisit a topic or learn more." The developer page is
**reference material**. It rewards depth and structure. A developer should be
able to land on it, understand the whole ecosystem, and come back later to
re-learn a specific piece. Pitch fluff fails this bar; real explanation passes
it. This principle applies to the methodology page too, and belongs in
`.flywheel/doctrine/frontend-design-and-story-principles.md` as a framing rule.

## Audience and job

A **developer** lands here. The job: they leave understanding that Joshua runs
a real, advanced, *open* agentic-coding ecosystem — built on the best
open-source agent tooling available — and that they can take it: use the same
open-source foundation, or download flywheel + skillos and run the whole thing
in their own environment, without Joshua. Framed by trust, not sales.

## Grounding constraints — non-negotiable

- **Attribution (brand-voice hard rule).** NTM, Agent Mail, beads, CASS are
  **Jeffrey Emanuel's** work (Dicklesworthstone) — always cited, never attributed
  to Joshua. flywheel and skillos are Joshua's, built *on top of* Jeffrey's
  substrate. Get this exactly right or the page is a hard reject.
- **Written for the public-repos state.** Joshua's decision: flywheel and
  skillos go public so they are downloadable — the page and the repo flip ship
  as one release. The page may truthfully say "clone it, run `install.sh`, use
  it without me" *because that is the state it ships into*. It must not ship
  before the repos are actually public.
- **No superlatives.** "The most advanced set of tools in the world" fails the
  brand-voice swap/specificity tests. Name the actual tools, say what each
  does, let the specifics carry the weight. Show, do not boast.
- **Developer register, first-person.** Still Joshua's "I", but the
  SMB-owner canon line ("I help SMB owners buy their time back") does NOT
  belong here — wrong audience. The developer canon is the ecosystem itself.
- **Receipts, not adjectives.** Where the page claims capability, it shows a
  real artifact: a repo link, a command, a named tool, a number.

## The spine — section order and the job each section does

1. **Hero — what this is, plainly.**
   This is the agentic-coding ecosystem Joshua runs every day — and it is
   open, and you can run it too. Establish in three seconds: real, advanced,
   working, open, curtain pulled back. Job: the developer knows they are
   looking at a working system they can take, not a brochure.

2. **The foundation — Jeffrey Emanuel's substrate.**
   Developers need to know about Jeffrey's body of work. Name the actual tools —
   NTM, Agent Mail, beads, CASS — credit Jeffrey Emanuel (Dicklesworthstone),
   note they are open source and downloadable, and explain in plain terms what
   each one does. "I did not build the foundation — Jeffrey Emanuel did, and it is
   the most capable agent substrate I have found. Here is what each piece does,
   and where to get it." Job: orient the developer to the real foundation;
   this is the first block of study material.

3. **What I built on top — flywheel + skillos.**
   The ecosystem Joshua built on Jeffrey's substrate. What it does: parallelizes
   work across multiple agents and multiple models, all feeding back into a
   common, locally-produced ecosystem; turns information found on the internet
   into **testable, reproducible knowledge packs** for agents; and wires
   operational protocols using the flywheel substrate. Job: the developer
   understands the thing that is uniquely Joshua's — and why it is more than
   the sum of Jeffrey's tools.

4. **How it works — the architecture.**
   The study-grade depth section. Walk the loop: parallel agents → multiple
   models → common feedback ecosystem → reproducible knowledge packs →
   operational protocols wired from the flywheel substrate. This is the
   section a developer comes back to re-read. It should be diagram-clear and
   genuinely explanatory — concrete, not abstract.

5. **Take it — the two open doors.**
   (a) Use the same open-source foundation Joshua uses, if you see fit — Jeffrey's
   tools, where to start. (b) Download flywheel + skillos into your own
   environment, usable without Joshua — clone, `install.sh` (scoped, dry-run
   capable, installs to `~/.flywheel/engine`, touches nothing else), run. Job:
   the developer has a concrete, real first step for each door.

6. **The deal — trust, not sales.**
   The philosophy, stated plainly: this largely follows Jeffrey's rulebook — give
   it away for free. When people get stuck, they can pay Joshua to come to the
   rescue — and that happens through trust earned by the work being good and
   open, never through sales pressure. Job: the soft, honest close — "it is all
   here; if you want a hand, I am here."

## Cuts from the current page

- The "reduced lane / 4 supported agent lanes / isolated runtime receipts"
  framing — that is internal operations vocabulary, not developer-facing study
  material. The *fact* that it runs across Claude / Codex / Gemini / OpenClaw
  is worth stating plainly in section 4; the receipt-machinery jargon is not.
- The SMB-owner canon line in the hero — wrong audience.
- "Open repository" / `git clone` links — fine *once the repo is public*; until
  then they are false claims (the home page has the same live bug — fix both
  when the repos flip).

## Adjacent fixes — resolved (history kept for traceability)

- **Home page proof block.** RESOLVED. The three "What I can show" examples
  Joshua confirmed real (the work behind CFS / VRTX / ALPS); the home proof
  section was rebuilt around three *anonymized* client stories — "a regional
  gym," "a regional insurance carrier," "a five-system custom app." The 910×
  cache receipt (0.007% → 6.37%, a 2-line regex) is real but wrong-audience for
  an SMB owner — it was relocated to the developer page, where a technical
  reader finds it compelling.
- **/about image.** RESOLVED. The recycled `loop-map.svg` was replaced with a
  purpose-built operator-arc visual on /about. `loop-map.svg` remains on
  /what-is, where an operating-loop diagram is contextually correct.

## Methodology page — next, its own focused spine

The methodology page rewrite (map the flywheel + skillos ecosystem surfaces,
center it on Donella Meadows systems thinking and how Joshua applies it,
cover the safety mechanisms in depth, all as study material) gets its own
architecture doc — Meadows-applied-properly is depth that should not be rushed
into a shared dispatch.
