# flywheel-g01ke Compliance Pack

Task: `flywheel-g01ke-736784`

## Deliverable Checklist

1. Cross-orch idle watchtower nudge protocol: done.
   - Artifact: `.flywheel/scripts/cross-orch-idle-watchtower.sh`
   - Evidence: focused test proves `--mode nudge --dry-run` records `would-nudge` without transport, and `--mode nudge --apply` sends exactly one `ntm send <session> --pane=1 --no-cass-check ORCH-IDLE NUDGE...`.

2. Launchd cadence installed: done.
   - Artifact: `.flywheel/launchd/ai.zeststream.cross-orch-idle-watchtower.plist`
   - Evidence: `launchctl print gui/501/ai.zeststream.cross-orch-idle-watchtower` reports `state = running`, `run interval = 300 seconds`, and arguments include `--mode nudge --apply --json`.
   - Registry: `flywheel-watchers register --label ai.zeststream.cross-orch-idle-watchtower --owner flywheel-orch --bead flywheel-g01ke --apply --idempotency-key flywheel-g01ke-cross-orch-idle-watchtower --json`.

3. Canonical CLI / mutation discipline: done.
   - Artifact: watchtower supports `run`, `doctor`, `health`, `validate plist`, `schema`, `info`, `examples`.
   - Mutation guard: default is read-only; nudge transport requires `--apply`.
   - File length: script is 340 lines, under the 500-line shell threshold used by the dispatch's route discipline.

4. Verification and packet audit: done.
   - `bash -n .flywheel/scripts/cross-orch-idle-watchtower.sh`
   - `bash -n .flywheel/tests/test-cross-orch-idle-watchtower.sh`
   - `plutil -lint .flywheel/launchd/ai.zeststream.cross-orch-idle-watchtower.plist`
   - `.flywheel/tests/test-cross-orch-idle-watchtower.sh`: `SUMMARY pass=10 fail=0`
   - `.flywheel/scripts/cross-orch-idle-watchtower.sh validate plist --json`: `status=pass`
   - `.flywheel/scripts/cross-orch-idle-watchtower.sh doctor --json`: `status=pass`
   - `.flywheel/validation-schema/v1/dispatch-template-audit.sh .flywheel/dispatches/codex-flywheel-g01ke-736784.md`: `valid=true`

## Artifact Checks

- `.flywheel/scripts/cross-orch-idle-watchtower.sh`: exists
- `.flywheel/launchd/ai.zeststream.cross-orch-idle-watchtower.plist`: exists
- `.flywheel/tests/test-cross-orch-idle-watchtower.sh`: exists
- `~/Library/LaunchAgents/ai.zeststream.cross-orch-idle-watchtower.plist`: installed
- `gui/501/ai.zeststream.cross-orch-idle-watchtower`: loaded and running

## L52 / Skill Discovery

- Beads filed: none.
- Beads updated: `flywheel-g01ke` will be closed after commit.
- No new gap bead reason: no uncovered follow-up gap found during implementation; the missing cadence/register/load path was handled in this task.
- Skill discoveries: 0. No reusable skill gap or broken skill surfaced.
- Fuckups logged: none. The launchd guard refusal was resolved by the existing `flywheel-watchers register` path and did not require new incident classification.

## Skill Auto Routes

- `canonical-cli-scoping=yes`: doctor/health/validate/schema/info/examples surfaces added; `--json`, stable validation output, and `--dry-run`/`--apply` mutation discipline present.
- `rust-best-practices=n/a`: no Rust touched.
- `python-best-practices=n/a`: no Python source touched.
- `readme-writing=n/a`: no README/public docs touched.

## Four-Lens Self-Grade

`four_lens=brand:9,sniff:9,jeff:9,public:9`

- Brand: narrow operational substrate fix, no product-facing voice risk.
- Sniff: real guard was hit and handled through the registry rather than bypass.
- Jeff: information flow upgraded from ad hoc nudge to recurring, registered launchd watchtower with ledger rows.
- Public: Three Judges check passes for a skeptical operator, maintainer, and future worker because the mutation gate, launchd state, and fake-substrate test are all re-runnable.

## Compliance Score

`compliance_score=920/1000`

Residual risk: `classify_pane_state` still treats `goal-completing` as nudge-worthy, preserving prior behavior. That can over-nudge completed goals, but the task scope was cadence + nudge installation, and changing idle taxonomy would be a separate behavioral policy change.
