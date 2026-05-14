# Public User Journey Pack

Schema: `flywheel.public_user_journey_pack.v0`
Status: `pre-signoff-required`
Source pack ID: `user-journey-wireframe-pack`

This pack is the public-asset journey map for Flywheel v0.2. It exists so
SkillOS, Flywheel, reviewers, and Joshua can evaluate the same publication
surface before any final signoff. It is not a marketing plan; it is the journey
contract for what a real visitor should see, trust, run, and verify.

The SMB-facing site story is controlled by
`docs/runbooks/public-site-smb-journey-wireframe.md`. The machine-readable rows
in this pack are the validator surface behind that story, not a substitute for
the visitor journey.

## Pack Rules

- Every public claim must point to a proof asset, receipt, test, or live gate.
- A page cannot imply supported agent harnesses before strict runtime receipts.
- Private customer names, home-directory paths, pane state, and raw local
  ledgers stay out of the public journey.
- SkillOS is named only as the capability-control-plane integration point.
- The machine-readable table is required, not advisory. Each row must include
  `asset_id`, `persona_lane`, `journey_stage`, `entrypoint`,
  `visible_wording`, `visual_cue`, `primary_cta`, `required_proof_refs[]`,
  `signoff_status`, `blocker_or_skip_receipt_ref`, and
  `source_pack_id=user-journey-wireframe-pack`.
- The GitHub repository stays private until Joshua signs off on the site,
  repository copy, release assets, and first-run evidence together.

## Failure Codes

The validator aligns with SkillOS failure codes:

| Code | Meaning |
|---|---|
| `JOURNEY_SPEC_MISSING` | The pack, schema, source pack ID, required columns, row identity, or stage enum is missing or invalid. |
| `STEP_VISUAL_CUE_MISSING` | A public journey step has no required visual cue. |
| `E2E_MAPPING_MISSING` | A step has no entrypoint, primary CTA, or blocker/skip receipt reference. |
| `PRIVATE_STATE_LEAK` | A public pack row or narrative includes private state markers. |
| `CLAIM_WITHOUT_EVIDENCE` | A claim-bearing step has no required proof reference. |

## Persona Journeys

| Persona | Entry asset | Question they bring | Required next asset | Trust proof | Primary action |
|---|---|---|---|---|---|
| SMB owner | `site/index.html` | Can this operator connect messy systems safely? | `site/what-is/index.html` then `site/methodology/index.html` | Methodology metrics, publication evidence, visible blocker honesty. | Contact ZestStream. |
| Technical buyer | `site/methodology/index.html` | Is there real operating discipline behind the claim? | `docs/evidence/publication-evidence.md` | Receipts, readiness blockers, external review evidence, reduced-mode proof. | Review evidence or request a walkthrough. |
| Developer | `README.md` | Can I inspect and run this without private state? | `docs/getting-started/first-run.md` | Installer smoke, reduced journey smoke, public docs, depersonalization scan. | Run reduced mode. |
| Operator | `docs/runbooks/public-release-runbook.md` | What exact commands prove readiness? | `docs/runbooks/release-cutover-authorization.md` | Cutover receipt replay, publication readiness JSON, installer smoke artifacts. | Produce the release receipt bundle. |
| Contributor | `CONTRIBUTING.md` | How do I extend this without breaking the trust surface? | `docs/reference/commands.md` and `docs/reference/files.md` | Required tests, DCO, issue templates, public-surface scanner. | Open a signed contribution. |
| Signoff reviewer | `docs/runbooks/public-user-journey-pack.md` | Are all public assets coherent enough to approve? | `docs/evidence/publication-evidence.md` and `docs/evidence/publication-blocker-coverage.md` | This pack plus current blocker coverage and live cutover receipts. | Approve or block signoff. |

## Public Asset Wireframe

| Asset | Audience | Promise | Required proof | Call to action | Signoff status |
|---|---|---|---|---|---|
| `site/index.html` | SMB owner | Flywheel makes hidden manual work visible, bounded, and inspectable before AI changes anything larger. | Full-bleed operating-room scene, workflow slice beam, owner-recognition route, proof states, reduced-mode command, evidence link, blocker honesty, reusable ZestStream visual-system layer. | Map a workflow or inspect proof. | Needs live-site review. |
| `site/what-is/index.html` | SMB owner, technical buyer | Flywheel separates engine, capability control plane, and proof surfaces. | Shared room-system hero, control-room loop diagram, SkillOS boundary lane, and proof-state console. | Continue to methodology. | Needs live-site review. |
| `site/for-developers/index.html` | Developer | Developers can run reduced mode while agent lanes remain receipt-bound. | Shared room-system hero, terminal command stage, support-lane console, and local-before-hosted gate. | Open the repo and run commands. | Needs live-site review. |
| `site/methodology/index.html` | Technical buyer | The method compounds lessons without exposing private customer state. | Shared room-system hero, Yuzu Method cutline, owner-worry console, compounding-loop board, consent fallback, evidence index. | Inspect publication evidence. | Needs live-site review. |
| `site/about/index.html` | SMB owner | A real operator is accountable for the method. | Shared room-system hero, operator map, public contact, and privacy stance. | Contact ZestStream. | Needs live-site review. |
| `site/contact/index.html` | SMB owner, evaluator | Public inquiries route to Joshua without collecting secrets. | Shared room-system hero, safe intake console, redaction guidance, mailto route probe, and subject prefix. | Send a public-site inquiry. | Needs live-site review. |
| `README.md` | Developer | The repo is an installable public engine, not private fleet state. | Local evidence map and reduced-mode install path. | Run preflight and first-run docs. | Needs repo-copy review. |
| `CHARTER.md` | All readers | The mission, boundaries, and audience are explicit. | Objective, first-run bar, non-overclaiming rules. | Continue to persona-specific path. | Needs repo-copy review. |
| `docs/getting-started/first-run.md` | Developer, operator | A first run is complete only with state, doctor, closeout, and next action. | `tests/installer-smoke.sh`, `tests/journey-smoke.sh`. | Run reduced first-run. | Needs repo-copy review. |
| `docs/runbooks/public-release-runbook.md` | Operator | Publication can be replayed from commands and receipts. | `scripts/publication_readiness.py`, cutover receipt replay. | Produce the release bundle. | Needs operator review. |
| `docs/runbooks/public-site-smb-journey-wireframe.md` | SMB owner, designer, reviewer | The public site must walk an SMB owner from problem recognition to trust before technical proof. | `tests/public-docs.sh`, Joshua review, website static/accessibility checks after implementation. | Approve the journey before rebuilding pages. | Needs Joshua journey review. |
| `docs/evidence/publication-evidence.md` | Buyer, developer, reviewer | Trust claims are mapped to evidence and live blockers. | Current test counts and live blocker table. | Verify blockers before signoff. | Needs final refresh. |
| `docs/evidence/publication-blocker-coverage.md` | Reviewer | Every live blocker has owner and closure proof. | Registry validator and readiness blocker coverage. | Keep open blockers visible. | Needs final refresh. |
| Release assets | Operator, developer | Install script, checksum, and archive come from the same artifact set. | GitHub release assets and install proxy checksum. | Install from the public endpoint. | Blocked until release. |
| `flywheel.zeststream.ai` | SMB owner, technical buyer | The public story is navigable without GitHub depth. | Website static/accessibility/link checks and live HEAD. | Contact or inspect evidence. | Approved for private/live staging; not final signoff. |
| `site/visual-system.css` | Designer, operator | Public pages share reusable ZestStream visual variables instead of one-off page styling. | Visual-system literals enforced by `tests/website-static.sh`. | Reuse the visual system in the broader site rewrite. | Needs live-site review. |
| ZestStream visual primitives | Designer, operator | Future Next.js work should inherit operating-room, workflow-map, slice-workbench, proof-rail, Yuzu-rail, room-system, and technical-drawer primitives. | `docs/runbooks/public-site-smb-journey-wireframe.md` and private site screenshot checks. | Use primitives before page-specific styling. | Needs Joshua journey review. |

## Machine-Readable Journey Rows

The table below is intentionally redundant with the narrative wireframe. It is
the validator surface for SkillOS-compatible public asset review. Public assets
cannot pass signoff as prose only: visible wording, visual cue, evidence refs,
CTA mapping, signoff status, and blocker-or-skip receipt refs are mandatory.

| asset_id | persona_lane | journey_stage | entrypoint | visible_wording | visual_cue | primary_cta | required_proof_refs | signoff_status | blocker_or_skip_receipt_ref | source_pack_id |
|---|---|---|---|---|---|---|---|---|---|---|
| site-home | SMB owner | trigger | site/index.html | Your business already has the data. The work is just hidden between tools. | Full-bleed operating-room scene with SMB systems, manual route, yuzu slice beam, workflow slice definition, and proof states rail | Map my workflow | tests/website-static.sh; tests/website-accessibility.sh | needs-live-site-review | docs/evidence/publication-blocker-coverage.md | user-journey-wireframe-pack |
| site-what-is | SMB owner | orient | site/what-is/index.html | SkillOS is a capability control plane integration point | Shared immersive room hero, control-room loop diagram, three boundary lanes, and proof-state console | Continue to methodology | tests/website-static.sh; docs/concepts/skillos-boundary.md | needs-live-site-review | docs/evidence/publication-blocker-coverage.md | user-journey-wireframe-pack |
| site-developers | Developer | orient | site/for-developers/index.html | Reduced local mode | Shared immersive room hero, terminal command stage, support-lane route console, and local-before-hosted proof console | Run the first loop | tests/website-static.sh; tests/journey-smoke.sh | needs-live-site-review | receipts/agent-lanes/claude.json | user-journey-wireframe-pack |
| site-methodology | Technical buyer | decide | site/methodology/index.html | AI adoption without operational chaos. | Shared immersive room hero, Yuzu Method cutline, owner-worry console, compounding-loop board, and redaction boundary | Inspect publication evidence | tests/website-static.sh; docs/evidence/publication-evidence.md | needs-live-site-review | docs/evidence/publication-blocker-coverage.md | user-journey-wireframe-pack |
| site-about | SMB owner | retain | site/about/index.html | Public contact email | Shared immersive room hero, operator map, direct public contact, and I-will/I-will-not accountability lanes | Contact ZestStream | tests/contact-routing.sh; tests/website-accessibility.sh | needs-live-site-review | docs/evidence/publication-blocker-coverage.md | user-journey-wireframe-pack |
| site-contact | SMB owner | act | site/contact/index.html | Public site inquiry | Shared immersive room hero, safe intake console with redacted-message guidance, topic selector, and message field | Send a public-site inquiry | tests/contact-routing.sh | needs-live-site-review | docs/evidence/publication-blocker-coverage.md | user-journey-wireframe-pack |
| repo-readme | Developer | trigger | README.md | Why flywheel | Public extraction metrics block | Run preflight | tests/public-top-level-files.sh; tests/public-docs.sh | needs-repo-copy-review | docs/evidence/publication-blocker-coverage.md | user-journey-wireframe-pack |
| charter | Signoff reviewer | orient | CHARTER.md | Public project should be useful to a business owner | Audience section | Continue to journey pack | tests/public-top-level-files.sh; tests/public-docs.sh | needs-repo-copy-review | docs/evidence/publication-blocker-coverage.md | user-journey-wireframe-pack |
| first-run | Developer | act | docs/getting-started/first-run.md | You are done with the first run when | Journey checklist | Run reduced first-run | tests/installer-smoke.sh; tests/journey-smoke.sh | needs-repo-copy-review | docs/evidence/publication-blocker-coverage.md | user-journey-wireframe-pack |
| release-runbook | Operator | act | docs/runbooks/public-release-runbook.md | Final Publication Readiness And Signoff | Required evidence table | Produce the release receipt bundle | tests/publication-readiness.sh; tests/cutover-receipts.sh | needs-operator-review | docs/runbooks/release-cutover-authorization.md | user-journey-wireframe-pack |
| smb-journey-wireframe | SMB owner | orient | docs/runbooks/public-site-smb-journey-wireframe.md | Your business already has the data. It is just trapped in five systems that do not talk to each other. | Primary page journey table | Approve the journey before rebuilding pages | tests/public-docs.sh | needs-joshua-journey-review | docs/evidence/publication-blocker-coverage.md | user-journey-wireframe-pack |
| publication-evidence | Technical buyer | decide | docs/evidence/publication-evidence.md | Live Evidence Still Required | Local evidence table | Verify blockers before signoff | tests/public-docs.sh; tests/true-publication-registry-validate.sh | needs-final-refresh | docs/evidence/publication-blocker-coverage.md | user-journey-wireframe-pack |
| blocker-coverage | Signoff reviewer | recover | docs/evidence/publication-blocker-coverage.md | The public release is not complete while any row above remains blocked. | Blocker coverage table | Keep open blockers visible | tests/true-publication-registry-validate.sh | needs-final-refresh | docs/evidence/publication-blocker-coverage.md | user-journey-wireframe-pack |
| release-assets | Operator | act | release-assets | Required release assets are uploaded, non-empty, and expose sha256 digests. | Release asset checklist | Install from public endpoint | tests/release-assets.sh; scripts/publication_readiness.py | blocked-until-release | docs/evidence/publication-blocker-coverage.md | user-journey-wireframe-pack |
| live-site | SMB owner | retain | flywheel.zeststream.ai | The public story is navigable without GitHub depth. | Live site navigation | Contact or inspect evidence | tests/public-links.sh; tests/website-static.sh | private-live-staging-approved-not-final | docs/evidence/publication-blocker-coverage.md | user-journey-wireframe-pack |
| site-visual-system | Designer | retain | site/visual-system.css | --zs-lime: #d4f34a | Shared CSS custom-property visual system imported by every page | Reuse the visual system in the broader ZestStream rewrite | tests/website-static.sh | needs-live-site-review | docs/evidence/publication-blocker-coverage.md | user-journey-wireframe-pack |
| zeststream-visual-primitives | Designer | retain | docs/runbooks/public-site-smb-journey-wireframe.md | OperatingRoomHero, WorkflowMap, SliceWorkbench, ProofRail, TrustWorryMatrix, YuzuMethodRail, TechnicalDrawer, OperatorSignature, RoomSystem | Foundational primitive table for all ZestStream Next.js projects | Use primitives before page-specific styling | tests/public-docs.sh; tests/website-static.sh | needs-joshua-journey-review | docs/evidence/publication-blocker-coverage.md | user-journey-wireframe-pack |
| api-contract-pack | Operator | recover | docs/runbooks/public-user-journey-pack.md | API-facing repos require OpenAPI and drift gates. | Skip receipt row | File bead or skip receipt | docs/evidence/publication-blocker-coverage.md | skipped-not-api-facing | docs/evidence/publication-blocker-coverage.md | user-journey-wireframe-pack |
| ui-contract-pack | Operator | retain | docs/runbooks/public-user-journey-pack.md | UI-facing repos require Playwright and screenshot mapping. | Skip receipt row | File bead or skip receipt | tests/website-static.sh; tests/website-accessibility.sh | partially-applicable-static-site | docs/evidence/publication-blocker-coverage.md | user-journey-wireframe-pack |

## Signoff Gate

Before Joshua signoff, the reviewer must confirm:

1. The private/live site journey works from landing page to contact.
2. The developer path works from README to reduced first run.
3. The operator path can collect publication readiness and cutover receipts.
4. The evidence path names every live blocker without relying on private state.
5. SkillOS appears only as capability control plane, not copied private state.
6. Agent harness support copy must match runtime receipts; any lane without a
   current passing receipt stays a compatibility target.
7. Release assets and final install proxy checksum parity are reviewed before
   public install copy is promoted.
8. The GitHub repository remains private until Joshua approves the repo and site
   together.

## Current Blockers

- Live site review is still required after `flywheel.zeststream.ai` is wired.
- Private-live staging install checksum proof exists, but final public release
  asset parity is still absent.
- Joshua signoff JSON must not be created until the site, repo, release assets,
  and first-run evidence are reviewed together.
