# Command Reference

The public CLI starts with reduced-mode commands.

| Command | Purpose |
|---|---|
| `flywheel preflight --json` | Report dependency mode and next action. |
| `flywheel init --repo "$PWD" --json` | Create repo-local reduced-mode state. |
| `flywheel doctor --repo "$PWD" --json` | Check whether the repo can proceed. |
| `flywheel tick --repo "$PWD" --dry-run --json` | Preview the next loop action. |
| `flywheel dispatch --repo "$PWD" --simulate --json` | Write a simulated closeout receipt. |
| `flywheel validate-receipt --repo "$PWD" --file .flywheel/last_closeout_receipt.json --json` | Validate the closeout receipt. |
| `flywheel inspect --repo "$PWD" --json` | Read the next actionable step. |
| `flywheel quickstart --json` | Print the first-run command sequence. |
| `scripts/agent-lane-probe.sh --json` | Report default lane registry status without treating command presence as support proof. |
| `scripts/agent-lane-probe.sh --receipt-dir receipts/agent-lanes --json` | Recheck agent lanes against runtime or blocker receipts before changing support copy. |
| `scripts/isolated-agent-lane-smoke.sh --receipt-dir state/isolated-agent-lanes --json` | Create a disposable HOME, public export, install prefix, and target repo before writing per-lane runtime or blocker receipts. Add `--live-adapters` only when credentialed agent CLIs should spend a real runtime proof. |
| `scripts/local-actions-preflight.sh` | Run the local GitHub Actions gate with `actionlint` and `act` before spending hosted runner minutes. |
| `python3 scripts/publication_readiness.py --release --json` | Check live publication readiness against the real remote and public web surfaces. |
| `python3 scripts/live_site_probe.py --base-url https://flywheel.zeststream.ai/ --json` | Probe first-party pages and assets on the deployed site. |
| `python3 scripts/validate_cutover_receipts.py --receipt-dir <dir> --release --json` | Replay a saved cutover receipt bundle and return pass only when every required proof is present and current. |
| `python3 scripts/validate_user_journey_pack.py --json` | Validate the SkillOS-compatible public user journey pack fields, visual cues, proof refs, signoff status, and blocker/skip receipt refs. |
| `python3 scripts/validate_story_system_package.py --json` | Validate the reusable ZestStream story-system package against the generated repo message pack and static site token mirror. |
| `bash tests/zeststream-motion-package.sh` | Validate the reusable `@zeststream/motion` package, exported spring presets, reduced-motion docs, and frontend-gate recognition. |
| `bash scripts/zs-frontend-quality-gate.sh --repo /path/to/next-project --json --strict` | Run the reusable ZestStream frontend quality gate before a Next.js proof surface can claim story-system adoption. |
| `python3 scripts/extract_git_story.py --repo-label Flywheel --write-json docs/evidence/flywheel-trajectory.json --write-md docs/stories/flywheel-trajectory.md` | Regenerate the public trajectory story, `zeststream.repo_story_message.v0` owner message pack, and `zeststream.repo_frontend_story.v0` UI payload from git history instead of writing the journey from one session's memory. |
| `python3 scripts/extract_git_story.py --repo /path/to/repo --repo-label "Product Name" --redaction-table /path/to/table.yaml --json` | Probe another repo with an explicit redaction table; when omitted, the extractor uses the target repo table or falls back to `flywheel:de-personalization-table.yaml`. |
| `python3 scripts/probe_repo_story_portability.py --write-json docs/evidence/repo-story-portability.json` | Save a portability receipt proving the shared git-story/front-end payload contract across Flywheel and the available sibling proof-product repos without editing them. |
| `python3 scripts/render_repo_owner_brief.py --story-json docs/evidence/flywheel-trajectory.json --write-json docs/evidence/flywheel-owner-brief.json --write-md docs/stories/flywheel-owner-brief.md` | Render the SMB-owner page brief from generated repo trajectory evidence before building a public frontend surface. |

Full-mode harness dispatch through NTM and Agent Mail is intentionally not
claimed by the reduced public CLI.
