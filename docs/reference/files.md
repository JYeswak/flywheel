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
| `receipts/agent-lanes/<lane>.json` | Strict `flywheel.agent_lane_runtime_receipt.v0` proof before an agent lane can move from compatibility target to supported copy, or `flywheel.agent_lane_blocker_receipt.v0` evidence naming why the lane remains blocked. |
| `docs/evidence/publication-evidence.md` | Public trust-claim evidence index. |
| `docs/evidence/publication-blocker-coverage.md` | Public blocker-code ownership and closure-proof map. |
| `docs/evidence/publication-goal-completion-audit.md` | Prompt-to-artifact audit for the active publication goal and remaining release blockers. |
| `docs/evidence/external-review-log.jsonl` | Sanitized external-review evidence used by the public release workflow. |
| `docs/getting-started/first-run.md` | First-run guide. |
| `docs/runbooks/public-user-journey-pack.md` | SkillOS-compatible public journey map requiring visible wording, visual cues, proof refs, signoff status, and blocker/skip receipt refs for each public asset. |
| `docs/runbooks/isolated-agent-lane-testing.md` | Runbook for proving or blocking Claude, Codex, Gemini, and OpenClaw in isolated environments. |
| `docs/runbooks/public-release-runbook.md` | Release operator runbook. |
| `docs/runbooks/release-cutover-authorization.md` | Final public cutover checklist and stop conditions. |

Private fleet ledgers, pane captures, local memory databases, and Agent Mail
archives are not public package inputs.
