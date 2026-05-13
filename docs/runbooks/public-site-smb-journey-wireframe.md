# Public Site SMB Journey Wireframe

Schema: `flywheel.public_site_smb_journey_wireframe.v0`
Status: `pre-build-required`
Source pack ID: `user-journey-wireframe-pack`

This wireframe controls the public-facing Flywheel site story before any page
implementation is accepted. The public user journey pack and readiness tests
prove that the journey exists. This document defines what the visitor should
experience.

The primary reader is an SMB owner who found ZestStream through social media,
then reached the Flywheel site or repository. They do not want to become an AI
tooling expert. They want to know whether ZestStream understands the practical
problem: five systems do not talk to each other, manual work keeps piling up,
and every software decision feels risky because nobody can see the full
operating picture.

## Reference Pattern

The Jeff-style pattern to adapt is not the visual skin alone. The useful pattern
is:

- a strong first concept, not generic platform copy;
- an immediate visual model that makes the concept feel alive;
- proof surfaces that get deeper as the reader scrolls;
- a clear path for the casual reader and the technical reader;
- live or inspectable artifacts close to each major claim;
- a named method that feels durable enough to revisit.

Flywheel should adapt that pattern for SMB operators, not Rust runtime buyers
or developer-tool evaluators. The site can acknowledge the upstream AI coding
ecosystem and Jeff's public work, but the page must sound like ZestStream:
practical, direct, operator-minded, and careful about claims.

Reference surfaces reviewed:

- `https://asupersync.com/`
- `https://frankentui.com/`
- `https://agent-flywheel.com/`
- `https://www.jeffreyemanuel.com/`

## Story Rule

Do not lead with receipt machinery, blocker counts, agent lane nuance, release
gates, or GitHub Actions. Those are proof layers for reviewers and technical
buyers.

Lead with the business owner's lived problem:

> "Your business already has the data. It is just trapped in five systems that
> do not talk to each other."

Then explain the operating method in plain language:

> "ZestStream maps the handoffs, builds the first safe automation slice, proves
> what changed, and captures the lesson so the next project starts smarter."

## Page Promise

The Flywheel page should make three things believable:

1. ZestStream understands messy SMB operations.
2. ZestStream uses advanced AI coding systems inside a controlled operating
   method, not as unmanaged speed theater.
3. Every project improves the reusable substrate without exposing private
   client state.

## Primary Page Journey

| Stage | Visitor question | Page job | Visible cue | Primary CTA | Proof layer |
|---|---|---|---|---|---|
| Trigger | "Is this about my problem?" | Name disconnected systems and manual work in plain SMB language. | Full-bleed operations map with email, CRM, calendar, invoices, docs, and handoffs. | Map my workflow | No proof wall; only a small private-review notice if needed. |
| Orient | "What does ZestStream actually do?" | Show the five-step Flywheel loop. | Animated or static loop: Map, Slice, Build, Verify, Reuse. | See how the loop works | Link to method section, not GitHub first. |
| Decide | "Why should I trust AI in this?" | Explain guarded adoption of AI coding agents. | Split view: unmanaged AI chaos vs controlled operating loop. | See the safeguards | Reviewer proof link to publication evidence. |
| Act | "What could we do first?" | Offer a first-workflow mapping path. | Intake panel with safe examples and no-secret warning. | Map my workflow | Contact route and redaction rules. |
| Recover | "What if something is not proven yet?" | Show that unsupported claims stay blocked. | Small proof drawer or technical appendix, not hero copy. | Inspect technical proof | Readiness blockers, receipts, support tiers. |
| Retain | "Is this a real operating method?" | Show compounding lessons across projects. | Substrate timeline: every project leaves reusable checks, skills, and runbooks. | Follow the evolution | GitHub, docs, changelog, SkillOS boundary. |

## Section Wireframe

### 1. Hero: Recognition First

Goal: make the SMB owner feel understood within five seconds.

Required elements:

- Headline about disconnected systems and manual work.
- Subheadline explaining that ZestStream connects the work with a visible,
  tested operating loop.
- Visual: a ZestStream operations map, not a generic abstract grid.
- CTA: `Map my workflow`.
- Secondary CTA: `Inspect the technical proof`.

Do not use:

- "receipts" as the headline concept;
- blocker counts;
- agent harness names;
- public release status as the main emotional payload;
- generic "AI-powered automation" copy.

### 2. The Pain: What Breaks In Real SMB Operations

Goal: name the workflow shapes the owner recognizes.

Content:

- customer request arrives in email;
- status lives in CRM;
- appointment lives on a calendar;
- invoice is in another tool;
- owner manually reconciles everything;
- reporting depends on memory and screenshots.

Visual:

- before-state map with broken handoffs;
- short labels, not paragraphs.

### 3. The Method: Flywheel In Five Moves

Goal: explain the method without requiring developer context.

Moves:

1. Map the workflow.
2. Pick one safe slice.
3. Build with agent-assisted engineering.
4. Verify with tests, checks, and human review.
5. Capture the lesson for the next project.

Visual:

- central loop with one-line explanation per move;
- no code block in this section.

### 4. The AI Stance: Advanced, But Controlled

Goal: be honest about using fast-moving AI systems without sounding reckless.

Message:

- ZestStream uses advanced AI coding agents and keeps up with the fast-moving
  ecosystem.
- New tools are investigated, isolated, tested, and promoted only when evidence
  supports the claim.
- The owner does not need to run the tooling. They need a clear path from
  problem to verified improvement.

Visual:

- "adopt, test, promote" control strip;
- proof link tucked beneath the section.

### 5. The Compounding Advantage

Goal: explain why every project makes the ecosystem stronger.

Message:

- reusable checks;
- reusable runbooks;
- reusable integration patterns;
- reusable user journey packs;
- reusable safety gates.

Visual:

- timeline or stack of project lessons becoming substrate.

### 6. Proof For Two Audiences

Goal: separate owner trust from reviewer evidence.

Owner-facing proof:

- the method has gates;
- private state is protected;
- unsupported claims remain visibly blocked;
- the first slice is scoped before implementation.

Technical proof:

- GitHub;
- first-run docs;
- publication evidence;
- readiness blockers;
- SkillOS boundary;
- agent lane support tiers.

Visual:

- two-column "Owner view" and "Technical view" with a clear divider.

### 7. CTA: Start With A Workflow Map

Goal: move the SMB owner to a safe next action.

Primary CTA:

- `Map my workflow`

Secondary CTA:

- `Inspect technical proof`

Form or contact copy must warn:

- do not send secrets;
- do not send raw customer data;
- redacted examples are enough for the first pass.

## Page-To-Page Journey

| Page | Primary reader | Job |
|---|---|---|
| `site/index.html` | SMB owner | Recognize the problem, understand the method, start a workflow map. |
| `site/what-is/index.html` | SMB owner, technical buyer | Explain Flywheel as ZestStream's operating method in plain language. |
| `site/methodology/index.html` | Technical buyer | Show the guarded adoption, proof, and compounding substrate model. |
| `site/for-developers/index.html` | Developer | Keep reduced-mode install and agent support claims precise. |
| `site/about/index.html` | SMB owner | Make ZestStream and Joshua accountable without over-centering biography. |
| `site/contact/index.html` | SMB owner | Route safe workflow mapping requests without collecting secrets. |

## Reusable Design Requirements

- Use the ZestStream fleet token layer, not per-page color decisions.
- Keep visual language transferable to the future `zeststream.ai` rewrite.
- Use existing ZestStream logo and favicon assets where appropriate.
- Keep components generic: hero, operations map, loop strip, proof drawer,
  CTA panel, technical appendix.
- Avoid one-off page-specific CSS unless the component is intentionally unique.
- Do not make cards inside cards.
- Use proof links and technical detail as progressive disclosure.

## Copy Bar

Good copy sounds like:

- "You already have the data. It is just trapped in tools that do not talk."
- "We map the work before we automate it."
- "The first slice is small on purpose."
- "Every project leaves behind checks the next project can reuse."
- "If a claim is not proven, it stays out of the public promise."

Bad copy sounds like:

- "AI-powered transformation platform."
- "Unlock seamless innovation."
- "Receipts, blockers, and agent lanes" in the hero.
- "Commercial-ready" without explaining what that means to the owner.
- "Trust us because the stack is advanced."

## Build Gate

Before rebuilding the public site, this wireframe must be reviewed against:

- `docs/runbooks/public-user-journey-pack.md`;
- `docs/stories/public-journey-and-redaction.md`;
- `tests/website-static.sh`;
- `tests/website-accessibility.sh`;
- `scripts/validate_user_journey_pack.py`;
- the current publication evidence index.

Implementation should not be accepted if the page can pass tests while still failing this journey.
Static tests verify required surfaces; this wireframe defines the visitor
experience those surfaces must serve.
