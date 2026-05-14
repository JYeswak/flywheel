# Staging Review Signoff Packet

Schema: `flywheel.staging_review_signoff_packet.v0`
Status: `staging-review-ready-not-public-release`

This packet is the human review map for the staged Flywheel 2.0 surface. It
does not approve public GitHub, release assets, hosted runs, or final signoff.
It exists so the reviewer can inspect the story, install path, proof surfaces,
and remaining blockers in one place before authorizing any public cutover.

## Review Surfaces

| Surface | What to inspect | Evidence |
|---|---|---|
| Staged site | The SMB journey, Yuzu Method, trajectory rail, developer lane copy, about page, and safe contact path. | `https://flywheel.zeststream.ai/`; `state/private-live-site-deploy.receipt.json`; `bash tests/website-static.sh`; `bash tests/website-accessibility.sh`; `python3 scripts/live_site_probe.py --base-url https://flywheel.zeststream.ai/ --json` |
| Git-derived story | Whether the page tells the real trajectory, not only the latest sprint. | `docs/stories/flywheel-trajectory.md`; `docs/evidence/flywheel-trajectory.json`; `bash tests/git-story-extract.sh` |
| User journey contract | Whether every public asset has persona lane, stage, visible wording, visual cue, CTA, proof refs, signoff status, and blocker or skip receipt. | `docs/runbooks/public-user-journey-pack.md`; `python3 scripts/validate_user_journey_pack.py --json`; `bash tests/public-user-journey-pack.sh` |
| Public evidence | Whether claims point to proof and live blockers stay visible. | `docs/evidence/publication-evidence.md`; `docs/evidence/publication-blocker-coverage.md`; `python3 scripts/publication_readiness.py --json` |
| External developer path | Whether a developer can start from README and run reduced local mode without private state. | `README.md`; `docs/getting-started/first-run.md`; `bash tests/installer-smoke.sh`; `bash tests/journey-smoke.sh` |
| Agent lanes | Whether Claude Code, Codex CLI, Gemini CLI, and OpenClaw copy follows isolated runtime receipts. | `docs/runbooks/isolated-agent-lane-testing.md`; `state/isolated-agent-lane-smoke.receipt.json`; `bash tests/isolated-agent-lane-smoke.sh`; `bash tests/agent-lane-probe.sh` |

## Reviewer Questions

1. Does the staged site make an SMB owner feel the workflow problem before it
   asks them to care about the machinery?
2. Does the trajectory section explain how the work compounded from real repo
   history instead of sounding like a one-session rewrite?
3. Does the Yuzu Method wording feel ownable for the operator brand without copying the
   tone of the reference sites?
4. Does the developer path state what is proven, what is reduced local mode, and
   what still requires public GitHub/release evidence?
5. Is any claim too broad, too technical, or too close to operator-only substrate?

## Current Blockers

`python3 scripts/publication_readiness.py --json` must remain blocked until the
real public cutover happens. Current blocker codes:

- `remote_repo_private`
- `remote_workflows_missing`
- `remote_green_runs_missing`
- `github_release_missing_or_draft`
- `github_release_assets_missing`
- `joshua_release_signoff_missing`

The reviewer can approve the staged site direction while still withholding
public release approval. Public release approval requires the cutover runbook and
receipt bundle in `docs/runbooks/release-cutover-authorization.md`.

## Go / No-Go Meaning

| Review outcome | Meaning |
|---|---|
| Staged site approved | The story direction is acceptable for staged review and can be used as the basis for operator site work. |
| Public release approved | Not granted by this packet. Requires public repo, workflows, green hosted runs, release assets, and exact final signoff. |
| Changes requested | Keep GitHub unreleased, update the site or docs, re-run the checks above, and refresh this packet. |
