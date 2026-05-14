# File Reference

Flywheel keeps public state repo-local.

| Path | Purpose |
|---|---|
| `.flywheel/GOAL.md` | The repo-local goal. |
| `.flywheel/STATE.md` | Current loop state and next action. |
| `.flywheel/last_closeout_receipt.json` | Latest closeout receipt. |
| `install.sh` | Public installer entry point. |
| `uninstall.sh` | Public uninstaller entry point. |
| `scripts/preflight.sh` | Dependency and mode detector. |
| `scripts/journey-smoke.sh` | First-run lane verifier. |
| `scripts/agent-lane-probe.sh` | Agent-lane support-copy guard for Claude, Codex, Gemini, and OpenClaw. |
| `scripts/isolated-agent-lane-smoke.sh` | Disposable public-export and clean-HOME lane smoke harness for per-lane receipts. |
| `scripts/publication_readiness.py` | Final publication gate. |
| `scripts/live_site_probe.py` | First-party deployed site page and asset probe. |
| `scripts/validate_cutover_receipts.py` | Saved release cutover receipt bundle verifier. |
| `scripts/validate_user_journey_pack.py` | Public user journey pack verifier. |
| `scripts/validate_story_system_package.py` | Shared story-system package verifier. |
| `scripts/extract_git_story.py` | Git-history trajectory and owner message-pack extractor for public story evidence. |
| `scripts/probe_repo_story_portability.py` | Portability probe for the git-history story contract across Flywheel, ClutterFreeSpaces, Mobile Eats, and future repos. |
| `scripts/render_repo_owner_brief.py` | Renderer that converts generated repo trajectory evidence into an SMB-owner story brief. |
| `packages/zeststream-story-system/story-system.json` | Reusable owner-message, proof-state, visual-primitive, and blocked-phrase contract for ZestStream frontend surfaces. |
| `packages/zeststream-story-system/tokens.css` | Reusable CSS token package mirrored by `site/visual-system.css`. |
| `packages/zeststream-ui/` | Reusable React component package for `ProofRail`, `WorkflowMap`, `TrustWorryMatrix`, and `TelemetryBar`. |
| `packages/zeststream-motion/` | Reusable React motion package for `SpringChip`, `SpringSheet`, `ConfidenceBadge`, `StreamingText`, `SkeletonMatch`, and `@zeststream/motion/tokens`. |
| `scripts/zs-frontend-quality-gate.sh` | Reusable Next.js frontend quality gate for story-system adoption, token discipline, proof states, motion, and accessibility. |
| `receipts/agent-lanes/<lane>.json` | Strict `flywheel.agent_lane_runtime_receipt.v0` proof before an agent lane can move from compatibility target to supported copy, or `flywheel.agent_lane_blocker_receipt.v0` evidence naming why the lane remains blocked. |
| `docs/brand/naming-conventions.md` | Public naming contract separating ZestStream, the Yuzu Method, Flywheel, SkillOS, upstream substrate, and proof surfaces. |
| `docs/evidence/publication-evidence.md` | Public trust-claim evidence index. |
| `docs/evidence/publication-blocker-coverage.md` | Public blocker-code ownership and closure-proof map. |
| `docs/evidence/staging-review-signoff-packet.md` | Human staging-review packet that maps site, story, evidence, developer path, agent-lane proof, and remaining public blockers without granting public release approval. |
| `docs/evidence/publication-goal-completion-audit.md` | Prompt-to-artifact audit for the active publication goal and remaining release blockers. |
| `docs/evidence/flywheel-trajectory.json` | Machine-readable `zeststream.repo_git_story.v0` trajectory evidence with embedded `zeststream.repo_story_message.v0` owner message pack, `zeststream.repo_story_dossier.v0` story brief, and `zeststream.repo_frontend_story.v0` UI payload. |
| `docs/evidence/repo-story-portability.json` | Saved `zeststream.repo_story_portability_probe.v0` receipt proving the story contract is not Flywheel-only. |
| `docs/evidence/flywheel-owner-brief.json` | Saved `zeststream.repo_owner_story_brief.v0` owner-facing message payload. |
| `docs/evidence/external-review-log.jsonl` | Sanitized external-review evidence used by the public release workflow. |
| `docs/stories/flywheel-trajectory.md` | Owner-readable generated trajectory story for reviewers and the public site. |
| `docs/stories/flywheel-owner-brief.md` | Generated SMB-owner story brief for page design and signoff review. |
| `docs/getting-started/first-run.md` | First-run guide. |
| `docs/runbooks/public-user-journey-pack.md` | SkillOS-compatible public journey map requiring visible wording, visual cues, proof refs, signoff status, and blocker/skip receipt refs for each public asset. |
| `docs/runbooks/repo-trajectory-story-pack.md` | Reusable contract for applying git-derived story extraction to other public repo surfaces. |
| `docs/runbooks/isolated-agent-lane-testing.md` | Runbook for proving or blocking Claude, Codex, Gemini, and OpenClaw in isolated environments. |
| `docs/runbooks/public-release-runbook.md` | Release operator runbook. |
| `docs/runbooks/release-cutover-authorization.md` | Final public cutover checklist and stop conditions. |

Private fleet ledgers, pane captures, local memory databases, and Agent Mail
archives are not public package inputs.
