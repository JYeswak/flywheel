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
| `scripts/extract_git_story.py --json` | Git-derived trajectory story evidence so public copy can show the proof path instead of relying on one session's memory. |
| `docs/evidence/publication-evidence.md` | Public index of trust claims, local receipts, and live evidence still required. |
| `docs/evidence/publication-blocker-coverage.md` | Public mapping from live readiness codes to owner and closure proof. |
| `docs/evidence/private-review-signoff-packet.md` | Private-review map for the site, story, evidence, developer path, agent-lane proof, and remaining public blockers; not public release approval. |
| `docs/evidence/flywheel-trajectory.json` | Machine-readable `zeststream.repo_git_story.v0` trajectory evidence generated from git history. |
| `docs/stories/flywheel-trajectory.md` | Owner-readable trajectory story used by the public site and reviewers. |
| `docs/runbooks/public-user-journey-pack.md` | Public asset journey map for business-owner, developer, operator, contributor, and signoff paths. |
| `docs/runbooks/repo-trajectory-story-pack.md` | Reusable story-pack contract for applying the git-derived trajectory pattern to other repo surfaces. |
| `docs/evidence/asupersync-gated-adoption.md` | Public packet proving Asupersync remains a gated upstream candidate, not a Flywheel runtime dependency. |
| `docs/evidence/asupersync-poc-receipt.template.json` | Receipt shape for the cleared-executor Asupersync POC before any runtime promotion. |
| `docs/evidence/asupersync-poc-receipt.local.json` | Isolated local Asupersync crate-level POC receipt; not runtime promotion evidence. |
| `docs/evidence/external-review-log.jsonl` | Sanitized external-review evidence that the public release workflow can validate without private `.flywheel/PLANS` state. |

Public copy must follow the evidence. A compatibility target stays a
compatibility target until its runtime receipt proves the full path.
