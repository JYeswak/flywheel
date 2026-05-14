# Repo Trajectory Story Pack

Schema: `zeststream.repo_git_story_pack.v0`
Status: `candidate-shared-foundation`

This pack turns a repository's git history into an owner-readable story. It is
for public pages, case-study drafts, launch reviews, and Next.js project
foundations where the copy needs to show proof instead of selling a dream.

The failure it prevents is familiar: a project gets a good-looking page, but the
story only reflects the last build session. The real trust signal is the path:
where the work started, what broke, what changed, what got blocked, and which
lessons became reusable.

## Contract

Every repo-facing public story must have three layers:

| Layer | Audience | Job |
|---|---|---|
| Generated trajectory | Reviewer, operator | Extract sanitized chapters from git history with commit evidence. |
| Owner message pack | SMB owner, buyer | Translate the trajectory into promise, objections, page arc, CTA, and visual primitives. |
| Designed story surface | SMB owner, buyer | Translate the trajectory into plain language, visual rhythm, and CTA flow. |

The generated layer is produced with:

```bash
python3 scripts/extract_git_story.py \
  --repo-label Flywheel \
  --write-json docs/evidence/flywheel-trajectory.json \
  --write-md docs/stories/flywheel-trajectory.md
```

For another repo, run the same script with that repo as `--repo` and write the
artifacts into that repo's evidence/story folders.

```bash
python3 /path/to/flywheel/scripts/extract_git_story.py \
  --repo /path/to/repo \
  --repo-label "Public Product Name" \
  --write-json docs/evidence/repo-trajectory.json \
  --write-md docs/stories/repo-trajectory.md
```

If the target repo has its own `de-personalization-table.yaml`, the extractor
uses it. If it does not, the extractor falls back to Flywheel's public redaction
table so the pack can still run against early ClutterFreeSpaces, Mobile Eats,
and other frontend repos before they have adopted the full publication scaffold.
Use `--redaction-table /path/to/table.yaml` when a repo needs a stricter
project-specific table.

## Story Chapters

The extractor groups commits into five public chapters:

| Chapter | Owner-facing meaning |
|---|---|
| Foundation | The team mapped the work before promising automation. |
| Proof loop | Activity turned into tests, receipts, blockers, and replayable checks. |
| Friction | Red evidence exposed what was not ready instead of hiding it. |
| Reuse | Lessons moved into scripts, runbooks, docs, packages, or shared design grammar. |
| Story | The final surface translates the machinery into a buying journey. |

These chapters are deliberately not raw commit counts. Counts are useful to
reviewers, but owners need movement: start, friction, control, reuse, outcome.

## Message Pack

The extractor also emits `message_pack` with schema
`zeststream.repo_story_message.v0`. This is the reusable bridge from repo
history to ZestStream page language. It is intentionally generic enough to use
in Flywheel, ClutterFreeSpaces, Mobile Eats, ZestTube, and future proof-product
repos.

Required message fields:

| Field | Purpose |
|---|---|
| `core_offer` | One plain-language sentence that names the bounded business outcome. |
| `owner_promise` | The page-level promise in ZestStream voice. |
| `voice_rules[]` | Editorial constraints that prevent AI hype and generic SaaS language. |
| `story_arc[]` | The reusable page journey: recognize, bound, control, remember, act. |
| `trust_objections[]` | The ten SMB objections the page must answer visibly. |
| `visual_primitives[]` | Shared design objects the site must render, not merely describe. |
| `proof_translation[]` | Mapping from commit/proof signals to owner-readable meaning. |
| `nextjs_storytelling_targets[]` | The implementation affordances the Next.js foundation should inherit. |
| `must_not_say[]` | Blocked language that sells the dream instead of showing proof. |

The owner message is not a summary of commits. It is a packaging layer that
answers a business question: "Why should I trust this person with my workflow?"

## 2026 SMB Language Rules

Current SMB adoption research points to the same useful language pattern:
owners want time back, simpler operations, human approval, privacy clarity,
training, and proof from businesses that look like theirs. They do not need a
tour of the agent stack before they understand the offer.

Use these translations:

| Do not lead with | Lead with |
|---|---|
| autonomous agents | human-approved slices |
| AI transformation | hours, follow-up, cash flow, and customer experience |
| model/tool names | the manual workflow being fixed |
| raw receipt counts | the control the receipt proves |
| generic innovation | what changes in the owner's week |
| everything integrated | one inspected workflow path |

Source anchors reviewed for this wording:

- Business.com 2026 Small Business AI Outlook: adoption is rising, but workers
  still worry about reputation, over-implementation, and whether work stays
  human-led.
- inTandem/vcita 2026 SMB adoption report: SMB owners prefer AI that drafts,
  suggests, organizes, and waits for approval before execution.
- Connected Commerce Council 2026 SMB study: small-business leaders are
  investing in AI training and adoption, with time savings and productivity as
  the practical frame.
- Dun & Bradstreet 2025 and 2026 AI data-quality research: trust depends on the
  reliability, readiness, and governance of the data feeding AI systems.

## Copy Rule

Use this line as the editorial filter:

> Show the proof, do not sell the dream.

Good public copy says:

- what changed in the workflow;
- what risk was controlled;
- what evidence exists;
- what stayed blocked;
- what lesson carries into the next project.

Weak copy says:

- AI will transform everything;
- the system is powerful because it has many commits;
- the work is complete because the page looks finished;
- the owner should trust hidden machinery.

## Visual Rule

The trajectory should appear as a living system, not a changelog pasted into a
landing page.

Required visual primitives:

| Primitive | Purpose |
|---|---|
| `TrajectoryRail` | Shows origin, friction, proof, reuse, and current arc as one connected path. |
| `FrictionBand` | Makes blocked or red evidence visible without turning it into failure theater. |
| `LessonLedger` | Shows how lessons become reusable checks, copy, components, or runbooks. |
| `ProofDrawer` | Lets reviewers inspect generated artifacts after the owner story lands. |

For Next.js projects, these should live in the shared design foundation beside
`OperatingRoomHero`, `WorkflowMap`, `SliceWorkbench`, `ProofRail`, and
`YuzuMethodRail`.

The same primitives should be package/global-config material. A project should
not rediscover the ZestStream page grammar from scratch. New frontend repos
should inherit:

- shared design tokens for proof states, yuzu accents, owner-safe warning
  colors, and room layouts;
- shared React components for `OperatingRoomHero`, `WorkflowMap`,
  `SliceWorkbench`, `ProofRail`, `TrustWorryMatrix`, `YuzuMethodRail`,
  `TrajectoryRail`, and `ProofDrawer`;
- shared Playwright screenshot gates that fail blank, overlapping, or
  generic-card pages;
- shared copy lint that rejects blocked phrases from `message_pack.must_not_say`;
- a repo-local generated story artifact wired into the page, not manually
  copied from the last session.

## Acceptance Gate

A repo trajectory story is acceptable when:

1. `scripts/extract_git_story.py --json` emits `zeststream.repo_git_story.v0`.
2. Generated JSON includes `message_pack.schema_version` equal to
   `zeststream.repo_story_message.v0`.
3. The message pack contains owner promise, story arc, trust objections, visual
   primitives, proof translations, and blocked phrases.
4. The extractor records which `redaction_table` was used and works when the
   target repo has not adopted a repo-local table yet.
5. Generated JSON and Markdown contain no private paths, client names, or
   unsupported claims.
6. The public page includes the trajectory as a buyer journey, not a developer
   changelog.
7. The page links to the generated story artifact for reviewers.
8. Any claim based on runtime support, release status, or public availability
   still points to its own proof receipt.

Flywheel's current generated artifacts:

- `docs/evidence/flywheel-trajectory.json`
- `docs/stories/flywheel-trajectory.md`
