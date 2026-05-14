# Public Site SMB Journey Wireframe

Schema: `flywheel.public_site_smb_journey_wireframe.v0`
Status: `private-review-implementation-active`
Source pack ID: `user-journey-wireframe-pack`

This wireframe replaces the rejected placeholder page. It is the governing
story, visual system, and implementation target for the private
`flywheel.zeststream.ai` review surface. The current public page should be
treated as scrapped unless a section below explicitly preserves it.

The reader is an SMB owner who found Joshua through social media, clicked
through to Flywheel, and is deciding whether this is the person to hire. They
are not shopping for agent tooling. They are living with email, CRM, calendar,
invoice, document, and reporting work that does not line up. They want to know
whether AI can help without turning the business into chaos.

The page must answer that in one sentence:

> "I help SMB owners buy their time back."

## Reference Distillation

The Jeff Emanuel reference pattern is not a component library. It is a way of
making a technical idea feel alive before the reader has to understand the
details.

Current reference surfaces reviewed on 2026-05-13:

- `https://www.jeffreyemanuel.com/`
- `https://asupersync.com/`
- `https://frankentui.com/`
- `https://agent-flywheel.com/`

The useful pattern to adapt:

| Jeff pattern | What it does | ZestStream translation |
|---|---|---|
| A named world appears immediately. | The reader lands inside a system, not a brochure. | The first viewport is the ZestStream operating room: disconnected SMB tools, manual glue, and one bounded workflow slice under inspection. |
| The first concept is sharp. | "Cancel-correct runtime" and "Monster terminal kernel" make the product memorable. | "Your business already has the data. The work is hidden between tools." |
| The machinery is visible. | Architecture diagrams, terminal renders, project graphs, counters, and live demos make depth tangible. | Show the workflow map, slice boundary, proof trail, and blocked claims as on-screen instruments. |
| Proof escalates by scroll depth. | Casual readers get the idea; technical readers can keep drilling. | SMB owners see the method in plain language; reviewers can open proof drawers and evidence links. |
| The maker is accountable. | Jeff's name, work volume, project graph, and contact path sit near the surface. | Joshua is the operator. The page should not hide behind a corporate voice. |
| The style is advanced but not timid. | Big type, coded status language, instrument panels, and live-feeling visuals signal seriousness. | Use strong ZestStream visual primitives: operating map, yuzu slice, proof rail, blocked-over-bluffing status, not stock SaaS cards. |

What not to copy:

- developer-first density in the opening;
- big unverifiable volume claims;
- a dark mono-palette that would make ZestStream feel like a clone;
- "AI infrastructure" language that does not speak to owners.

### Visual Source Receipt

Local Playwright review on 2026-05-13 captured the current reference surfaces
into `/tmp/flywheel-jeff-deep/`. The takeaway is not "make a darker SaaS
site." The takeaway is that every page must feel like the reader has stepped
into a real operating system for the work.

| Reference | Observable move | Flywheel requirement |
|---|---|---|
| `asupersync.com` | Oversized named premise with instrument-like proof around it. | The hero must show the operating room and one selected slice before asking the owner to trust the method. |
| `frankentui.com` | A live-feeling interface that makes the product feel tangible before the prose explains it. | Workflow maps, proof rails, and blocked states should be on-screen objects, not claims in paragraph copy. |
| `jeffreyemanuel.com` | Personal accountability is close to the technical depth. | Joshua's owner-facing promise and public email stay visible without turning the page into a resume. |
| `agent-flywheel.com` | The system language is memorable because the visual world reinforces it. | `slice`, `proof rail`, `blocked`, and `Peel. Press. Pour.™` must become repeated visual grammar across Flywheel and later ZestStream pages. |

The ZestStream translation must be brighter, more practical, and less
developer-dense than the references. The reader should leave thinking: "he sees
my workflow mess, he has controls for AI risk, and I can start with one small
piece."

### Multi-Page Implementation Rule

The visual grammar cannot live only on `site/index.html`. Every public page must
reuse the same core primitives so the visitor experiences one system:

| Page | Required room in the system | Required visible object |
|---|---|---|
| `site/index.html` | Owner operating room | Workflow map, selected slice, proof rail, and SMB promise. |
| `site/what-is/index.html` | Control-room explainer | Loop diagram, boundary lanes, and proof-state console. |
| `site/methodology/index.html` | Yuzu method room | Peel/Press/Pour rail, owner-worry console, and compounding loop board. |
| `site/for-developers/index.html` | Local run room | Terminal command panel, support-lane console, and local-before-hosted gate. |
| `site/about/index.html` | Operator room | Joshua/ZestStream accountability, public contact, and privacy stance. |
| `site/contact/index.html` | Safe intake room | Redacted-message guidance and direct operator routing. |

Jeff's strongest surfaces make each page feel like a different instrument in
the same system. Flywheel must do the same for SMB adoption: the tone is less
developer-dense, but the depth and designed-world feeling should remain.

## SMB Trust Research

The story must address what owners actually worry about. 2025 SMB research
clusters around the same concerns: data privacy and security, data quality,
accuracy, lack of training, cost, integration with existing systems, and
uncertainty about whether AI belongs in the real workflow. Sources reviewed
include SMB Group 2025 AI adoption research, Dun & Bradstreet's 2025 AI trust
and data-quality survey, Paychex's 2025 small-business AI survey, NFIB's 2025
Small Business and Technology survey, and Homebase's 2025 small-business AI
report.

The page should not argue that owners are behind. It should show that their
caution is rational, then show the ZestStream method that makes the caution
workable.

## The Foundational Visual System

Every ZestStream Next.js project should inherit these primitives before it gets
page-specific styling.

| Primitive | Job | Required behavior |
|---|---|---|
| `OperatingRoomHero` | First-viewport proof of a living system. | Full-bleed scene, no split card hero, no abstract gradient-only hero. |
| `WorkflowMap` | Make hidden manual work visible. | Shows named business systems, the manual path between them, and the selected slice boundary. |
| `SliceWorkbench` | Define and inspect one bounded improvement. | Shows before, slice, proof, and stop condition in one visual unit. |
| `ProofRail` | Keep evidence close without making it the headline. | Each claim has a proof state: proven, blocked, skipped-with-reason, or private. |
| `TrustWorryMatrix` | Respect owner objections. | Maps each owner worry to the visible control that answers it. |
| `YuzuMethodRail` | Make the named method memorable. | Uses `Peel. Press. Pour.™` as the visual rhythm: map, prove, reuse. |
| `TechnicalDrawer` | Give reviewers a path without hijacking the SMB story. | Opens proof, commands, receipts, and support tiers only after the owner story lands. |
| `OperatorSignature` | Make Joshua accountable. | First-person singular, public email, no faceless corporate "we." |

These primitives should become shared package or global-config material for the
larger ZestStream site rewrite. Static Flywheel HTML can prove the design, but
the Next.js version should express the same primitives as reusable components.

Recommended Next.js target:

| Capability | Next.js primitive | ZestStream use |
|---|---|---|
| Fast first impression | App Router layouts and static shell | Render the operating room and core promise immediately. |
| Proof without clutter | Server Components | Read proof manifests and blocker receipts without shipping raw private state to the client. |
| Progressive evidence | Suspense and route-level loading states | Let proof drawers stream after the owner story is visible. |
| Inspectable story pages | Route groups | Separate SMB routes, reviewer routes, and developer routes without duplicating layout code. |
| Visual consistency | Shared CSS tokens package | Colors, status chips, proof rails, and workbench layouts travel across all ZestStream projects. |
| Screenshot accountability | Playwright projects | Desktop and mobile screenshots must be checked before private review. |

## Core Story

The page should move through seven scenes.

### Scene 1: Operating Room

Goal: recognition in five seconds.

Owner question: "Is this about the mess I am actually dealing with?"

Visible wording:

> "Your business already has the data. The work is just hidden between tools."

Visual:

- full-bleed operating map;
- named tools: email, CRM, calendar, invoices, documents, reports;
- one highlighted manual route;
- one yuzu-colored slice boundary;
- proof rail tucked into the scene, not a separate card stack.

Primary CTA:

- `Map my workflow`

Secondary CTA:

- `Inspect the proof`

Forbidden:

- receipt counts in the hero;
- GitHub-first story;
- generic "AI automation" claims;
- split hero with text on one side and a decorative image on the other.

### Scene 2: The Mess Has A Shape

Goal: make the owner feel that Joshua sees the real workflow.

Show the repeated SMB pattern:

1. customer request starts in email;
2. status lives somewhere else;
3. appointments and payments create follow-up work;
4. documents arrive late or in the wrong place;
5. reporting depends on memory, screenshots, and one tired owner.

Visual:

- a horizontal manual route with visible friction points;
- red or amber only for risk, not decoration;
- short labels instead of paragraph blocks.

### Scene 3: One Slice First

Goal: define the word `slice` so it becomes common knowledge.

Required copy:

> "A slice is one bounded workflow improvement: useful enough to feel, small
> enough to inspect, and clear enough to stop if the proof is not there."

Examples:

- route an email request into the right follow-up list;
- update the place the owner already checks when an appointment changes;
- mark the next task ready when an invoice is paid;
- create the checklist item the team would have made by hand.

Visual:

- the selected slice is physically pulled out of the operating map;
- before, slice, and proof are shown in one bench;
- no code block in this section.

### Scene 4: The Yuzu Method

Goal: make the method memorable without sounding like another consultant
framework.

First use:

> "The Yuzu Method ®"

Motto:

> "Peel. Press. Pour.™"

Plain-language meaning:

- `Peel`: map the work before touching the business.
- `Press`: build and verify one useful slice.
- `Pour`: keep the lesson so the next build starts smarter.

Required stance:

> "The first slice is small on purpose."

Visual:

- a rail or cutline, not three generic cards;
- each move connected to the operating map and proof rail.

### Scene 5: Advanced AI, Controlled Loop

Goal: be honest about AI without making the owner evaluate tooling.

Message:

- Joshua uses current AI coding systems and watches the field move quickly.
- New tools are isolated, tested, and promoted only when proof supports them.
- The owner does not need to run NTM, Agent Mail, Beads, SkillOS, Claude,
  Codex, Gemini, or OpenClaw to benefit from the method.
- Jeff Emanuel's public work can be attributed where it informs the substrate.
  ZestStream must never claim Jeff's work as Joshua's.

Owner-facing control language:

- "Blocked is better than bluffing."
- "Private work stays private."
- "The work stays inspectable."
- "You approve the slice; I manage the machinery."
- "If a claim is not proven, it stays blocked."

Visual:

- controlled loop with gates: map, build, test, review, reuse;
- unproven claims visibly blocked instead of hidden.

### Scene 6: Two Proof Paths

Goal: avoid forcing SMB owners into developer evidence while keeping reviewers
fully served.

Owner path:

- what work is in scope;
- what will not be touched yet;
- what proof they will see;
- what happens if the proof fails.

Reviewer path:

- public user journey pack;
- publication evidence;
- readiness blockers;
- reduced local first-run commands;
- support-tier language for agent harnesses.

Visual:

- one proof rail with owner labels on top and technical receipts beneath;
- drawers, accordions, or route links for deeper review.

### Scene 7: Hire Joshua For The Map

Goal: turn trust into a safe next action.

CTA:

- `Map my workflow`

Required warning:

- do not send secrets;
- do not send raw customer data;
- redacted examples are enough for the first pass.

Tone:

- direct invitation;
- no "contact sales";
- no pressure.

## Ten Owner Objections The Page Must Answer

| Owner objection | Visible answer | Proof behavior |
|---|---|---|
| AI will make a mess. | The map comes before automation. | First slice must have a boundary. |
| I will not know what changed. | Every slice has a proof rail. | Claim links to evidence or stays blocked. |
| My data will leak. | Private work stays private. | Public proof is redacted, consented, or replaced. |
| AI makes things up. | Blocked is better than bluffing. | Unsupported claims show as blocked. |
| This will replace people before it understands the work. | The first slice is small on purpose. | Human approval remains part of the slice. |
| My tools already do not talk. | The operating map starts with disconnected tools. | Integration is scoped to one workflow path first. |
| Every consultant has a framework. | The method is visible enough to inspect. | Public runbooks and checks sit behind the story. |
| AI changes too fast. | Fast tools go through a controlled loop. | Tool claims require current receipts. |
| If it fails, I will be stuck. | Stop conditions are named up front. | Failed proof does not become a public claim. |
| I do not want to become an AI expert. | You approve the slice; Joshua manages the machinery. | Technical proof is available but not required to understand the offer. |

## Page-To-Page Journey

| Page | Primary reader | Job |
|---|---|---|
| `site/index.html` | SMB owner | Recognize the problem, see the operating map, understand one slice, and contact Joshua. |
| `site/what-is/index.html` | SMB owner, technical buyer | Explain Flywheel as the method behind ZestStream's work. |
| `site/methodology/index.html` | Technical buyer | Show guarded adoption, proof, privacy boundaries, and compounding lessons. |
| `site/for-developers/index.html` | Developer | Keep reduced-mode install and agent support claims precise. |
| `site/about/index.html` | SMB owner | Make Joshua accountable without burying the method in biography. |
| `site/contact/index.html` | SMB owner | Route safe workflow mapping requests without collecting secrets. |

## Build Acceptance

The implementation is not acceptable unless all of these are true:

- the first viewport is an operating map, not a decorative card layout;
- `The Yuzu Method ®` and `Peel. Press. Pour.™` appear with correct trademark
  rendering;
- `I help SMB owners buy their time back.` appears verbatim;
- `A slice is one bounded workflow improvement` appears verbatim or as the
  first clause of a longer definition;
- every claim-bearing section has an owner-facing proof state;
- no private customer names, local paths, pane state, or raw private ledgers
  appear;
- technical proof is available without becoming the hero;
- desktop and mobile screenshots show no overlapping text, blank hero, or
  off-screen CTAs;
- `tests/website-static.sh`, `tests/website-accessibility.sh`, and
  `scripts/validate_user_journey_pack.py` pass.

Implementation should not be accepted if tests pass while the page still feels
like a generic SaaS landing page.

Implementation should not be accepted if the page can pass tests while still failing this journey.
