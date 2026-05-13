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
| `scripts/agent-lane-probe.sh --json` | Report Claude, Codex, Gemini, and OpenClaw as compatibility targets until strict runtime receipts exist. |
| `scripts/agent-lane-probe.sh --receipt-dir receipts/agent-lanes --json` | Recheck agent lanes against runtime or blocker receipts before changing support copy. |
| `scripts/isolated-agent-lane-smoke.sh --receipt-dir state/isolated-agent-lanes --json` | Create a disposable HOME, public export, install prefix, and target repo before writing per-lane runtime or blocker receipts. Add `--live-adapters` only when credentialed agent CLIs should spend a real runtime proof. |
| `scripts/local-actions-preflight.sh` | Run the local GitHub Actions gate with `actionlint` and `act` before spending hosted runner minutes. |
| `python3 scripts/publication_readiness.py --release --json` | Check live publication readiness against the real remote and public web surfaces. |
| `python3 scripts/live_site_probe.py --base-url https://flywheel.zeststream.ai/ --json` | Probe first-party pages and assets on the deployed site. |
| `python3 scripts/validate_cutover_receipts.py --receipt-dir <dir> --release --json` | Replay a saved cutover receipt bundle and return pass only when every required proof is present and current. |
| `python3 scripts/validate_user_journey_pack.py --json` | Validate the SkillOS-compatible public user journey pack fields, visual cues, proof refs, signoff status, and blocker/skip receipt refs. |

Full-mode harness dispatch through NTM and Agent Mail is intentionally not
claimed by the reduced public CLI.
