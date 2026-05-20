# flywheel-r3gz8 Evidence Pack

Task: Merge-back-to-main daily cadence for long-lived review branches.

## Artifacts

| Artifact | Path | Status |
|---|---|---|
| Merge-back runner | `.flywheel/scripts/review-branch-mergeback.sh` | exists |
| Launchd installer | `.flywheel/scripts/install-review-branch-mergeback-launchd.sh` | exists |
| Fleet rollout wrapper | `.flywheel/scripts/review-branch-mergeback-fleet-rollout.sh` | exists |
| Smoke test | `tests/review-branch-mergeback-smoke.sh` | exists |
| Doctrine | `.flywheel/doctrine/review-branch-mergeback-discipline.md` | exists |
| Canonical registry | `.flywheel/canonical-paths.txt` | updated |

## Verification

```bash
bash -n .flywheel/scripts/review-branch-mergeback.sh \
  .flywheel/scripts/install-review-branch-mergeback-launchd.sh \
  .flywheel/scripts/review-branch-mergeback-fleet-rollout.sh \
  tests/review-branch-mergeback-smoke.sh
shellcheck .flywheel/scripts/review-branch-mergeback.sh \
  .flywheel/scripts/install-review-branch-mergeback-launchd.sh \
  .flywheel/scripts/review-branch-mergeback-fleet-rollout.sh \
  tests/review-branch-mergeback-smoke.sh
bash tests/review-branch-mergeback-smoke.sh
.flywheel/validation-schema/v1/dispatch-template-audit.sh \
  .flywheel/dispatches/codex-flywheel-r3gz8-6b5b90.md
```

Observed results:

- `bash -n`: PASS
- `shellcheck`: PASS
- `tests/review-branch-mergeback-smoke.sh`: PASS, 17 assertions / 0 failures
- Dispatch template audit: PASS, `valid=true`
- Live Flywheel dry-run before commit: `outcome=skipped`, `reason=dirty-tree`
- Launchd fleet dry-run: PASS, emits `review_branch_mergeback_fleet_rollout.v1`

## Acceptance Mapping

| Requirement | Evidence |
|---|---|
| End-of-day daily cron | Launchd installer emits `StartCalendarInterval` hour/minute, default 20:30. |
| Rebase review branch on main | Runner executes `git rebase <remote/main-or-main>` in apply mode. Smoke proves remote review contains main after run. |
| Push after rebase | Runner uses `git push --force-with-lease`; smoke proves push path. |
| Conflict follow-up | Runner aborts conflicted rebase and files a GitHub issue via `gh issue create` when `--conflict-action issue`; smoke proves fake-gh follow-up. |
| Prevent merge bankruptcy | Doctrine and canonical registry wire the cadence as a reusable substrate primitive. |
| Do not mutate dirty/conflict worktrees | Runner skips dirty trees and conflict-recovery states; smoke proves dirty skip. |

## Skill Routes

- `canonical-cli-scoping=yes`: runner includes doctor, health, repair, validate, audit, why, info, schema, examples, quickstart, JSON, dry-run/apply surfaces.
- `rust-best-practices=n/a`: no Rust touched.
- `python-best-practices=n/a`: no Python source touched.
- `readme-writing=n/a`: README untouched; doctrine is scoped operator guidance.

## Four-Lens Self-Grade

`four_lens=brand:8,sniff:8,jeff:8,public:8`

Three Judges check: a skeptical operator gets dry-run/apply, dirty-tree refusal,
and audit receipts; a maintainer gets shellcheck and fixture coverage; a future
worker gets doctrine and canonical path entries.

## Compliance Score

`compliance_score=875/1000`

Residual risk: live Flywheel dry-run reported `dirty-tree` before commit because
this worker's own scoped files were uncommitted. Re-run after commit should move
from `skipped` to planned action if no unrelated dirty paths remain.
