# Evidence Contracts

Flywheel prefers receipts over memory. A claim is release-safe only when a test,
doctor, receipt, review row, or public run proves it.

Common evidence surfaces:

| Surface | What it proves |
|---|---|
| `scripts/preflight.sh --json` | Dependency mode and next action. |
| `scripts/journey-smoke.sh --json` | First-run lane status and support tier. |
| `flywheel doctor --json` | Repo-local health and stable failure codes. |
| `flywheel validate-receipt --json` | Closeout receipt validity. |
| `scripts/publication_readiness.py --json` | Final public release blocker list. |
| `scripts/live_site_probe.py --json` | Deployed first-party site pages and assets. |
| `scripts/validate_cutover_receipts.py --json` | Saved cutover receipt bundle replay for final release evidence. |
| `scripts/validate_user_journey_pack.py --json` | SkillOS-compatible public user journey pack validator with journey-step, visual-cue, evidence-ref, and skip/blocker receipt checks. |
| `scripts/validate_story_system_package.py --json` | Reusable public story-system package validator that checks story arc, trust objections, visual primitives, frontend story schema, excluded hype phrases, and CSS token parity. |
| `scripts/validate_installed_binary_source.py` | Installed-binary source manifest validator; blocks untracked full-substrate CLI closeout receipts unless they name a source-gap bead and evidence receipt. |
| `scripts/zs-frontend-quality-gate.sh --json` | Reusable frontend quality gate for Next.js projects; checks font loading, design tokens, motion, copy source, accessibility, proof states, story-system linkage, and shared package wiring. |
| `scripts/extract_git_story.py --json` | Git-derived trajectory, owner message pack, story dossier, and frontend UI payload so public copy can show the proof path instead of relying on one session's memory. |
| `scripts/probe_repo_story_portability.py --json` | Repo-story portability probe proving the same git-derived story contract can run against Flywheel, ClutterFreeSpaces, Mobile Eats, or another local repo without editing sibling repos. |
| `scripts/render_repo_owner_brief.py --json` | Owner-facing brief renderer that turns generated repo trajectory JSON into a de-slopified SMB page brief with method steps, trust answers, page rooms, CTA, and proof refs. |
| `docs/brand/naming-conventions.md` | Public naming contract separating company, method, engine, capability-control plane, upstream substrate, and proof surfaces. |
| `packages/zeststream-story-system/story-system.json` | Shared public story grammar for Flywheel, ClutterFreeSpaces, Mobile Eats, and future frontend surfaces. |
| `packages/zeststream-story-system/story-system.mjs` | Importable Next.js story-system module with runtime contract assertion. |
| `packages/zeststream-story-system/story-system.d.ts` | TypeScript story-system contract for frontend package consumers. |
| `packages/zeststream-story-system/tokens.css` | Shared visual tokens mirrored by the static Flywheel site and intended for Next.js package adoption. |
| `packages/zeststream-ui/` | Shared React primitives for proof rails, workflow maps, trust-worry matrices, and telemetry texture. |
| `packages/zeststream-motion/` | Shared React motion primitives and `@zeststream/motion/tokens` spring presets for living proof surfaces, with reduced-motion behavior documented. |
| `docs/evidence/publication-evidence.md` | Public index of trust claims, local receipts, and live evidence still required. |
| `docs/evidence/publication-blocker-coverage.md` | Public mapping from live readiness codes to owner and closure proof. |
| `docs/evidence/installed-binary-source-manifest.json` | Tracked source/status manifest separating the reduced public install binary from full-substrate local-only binaries such as `flywheel-lock-repair` and `flywheel-verdict`. |
| `docs/evidence/staging-review-signoff-packet.md` | Staging-review map for the site, story, evidence, developer path, agent-lane proof, and remaining public blockers; not public release approval. |
| `docs/evidence/flywheel-trajectory.json` | Machine-readable `zeststream.repo_git_story.v0` trajectory evidence with embedded `zeststream.repo_story_message.v0` owner message pack and `zeststream.repo_frontend_story.v0` UI payload generated from git history. |
| `docs/evidence/repo-story-portability.json` | Saved `zeststream.repo_story_portability_probe.v0` receipt showing Flywheel, ClutterFreeSpaces, and Mobile Eats passed the shared story/front-end payload contract. |
| `docs/evidence/flywheel-owner-brief.json` | Saved `zeststream.repo_owner_story_brief.v0` payload for the business-owner page message generated from repo trajectory evidence. |
| `docs/stories/flywheel-trajectory.md` | Owner-readable trajectory story used by the public site and reviewers. |
| `docs/stories/flywheel-owner-brief.md` | Generated owner-facing story brief for reviewers and Next.js page builders. |
| `docs/runbooks/public-user-journey-pack.md` | Public asset journey map for business-owner, developer, operator, contributor, and signoff paths. |
| `docs/runbooks/repo-trajectory-story-pack.md` | Reusable story-pack contract for applying the git-derived trajectory pattern to other repo surfaces. |
| `docs/evidence/asupersync-gated-adoption.md` | Public packet proving Asupersync remains a gated upstream candidate, not a Flywheel runtime dependency. |
| `docs/evidence/asupersync-poc-receipt.template.json` | Receipt shape for the cleared-executor Asupersync POC before any runtime promotion. |
| `docs/evidence/asupersync-poc-receipt.local.json` | Isolated local Asupersync crate-level POC receipt; not runtime promotion evidence. |
| `docs/evidence/external-review-log.jsonl` | Sanitized external-review evidence that the public release workflow can validate without private `.flywheel/PLANS` state. |

Public copy must follow the evidence. A compatibility target stays a
compatibility target until its runtime receipt proves the full path.
