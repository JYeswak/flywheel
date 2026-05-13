# TP-019 Doctor Warning Disposition

Created: 2026-05-13T03:40Z
Refreshed: 2026-05-13T22:48Z
Status: closed for public v0.2 release gating
Registry row: TP-019
Bead: flywheel-2djra

## Decision

TP-019 is closed for the public v0.2 publication gate.

The latest full doctor has no hard errors. The remaining warnings are not
public installability blockers because they do not invalidate the installer,
doctor, reduced-mode first run, package surface, public naming gate,
depersonalization gate, context/model routing discipline, or SkillOS boundary.

The warnings remain visible in doctor output and stay owned by their existing
follow-up surfaces. They are not hidden or downgraded in code.

## Fixed Before Disposition

| Failure class | Disposition | Evidence |
|---|---|---|
| `brand_voice_banned_words` | Fixed | README wording changed from `public-safe artifacts` to `public-safe files`; `.flywheel/scripts/publishability-bar.sh --doctor --json --repo /Users/josh/Developer/flywheel` returned `status=pass`, `banned_words_count=0`, `errors=[]`. |
| `beads_db_health_failed` / `source_repo="flywheel"` leakage | Fixed | `scripts/backfill-source-repo.sh --repo /Users/josh/Developer/flywheel --json` repaired the latest recurrence in the DB; the JSONL mirror was mechanically canonicalized for the same five rows after the public-site/story closeouts reintroduced basename `source_repo` values; `bash tests/beads-source-repo-basename-normalization.sh` passed 6/0; JSONL has 2,117 canonical rows and DB leakage is 0. |
| `agent_mail_fd_doctor_fail` / `agent_mail_fd_doctor_warn` | Fixed | `.flywheel/scripts/agent-mail-restart.sh --apply --explain --json` restarted the LaunchAgent after FD pressure recurred; direct FD doctor reports `status=PASS`, `total_fds=9`, `lock_fd_count=0`, `warnings=[]`, `errors=[]`; full loop doctor reports `agent_mail_fd_status=ok`, `agent_mail_fd_total_fds=71`, `agent_mail_fd_lock_fd_count=6`, `errors=[]`. |
| `watcher_isomorphic_failed` / fast umbrella timeout false red | Fixed | `/Users/josh/.claude/skills/.flywheel/lib/recovery.sh` now gives watcher-isomorphic its own `FLYWHEEL_WATCHER_ISOMORPHIC_TIMEOUT_SECONDS` default of 5 seconds instead of inheriting the 0.2-second fast doctor umbrella; `FLYWHEEL_DOCTOR_PROBE_TIMEOUT_SECONDS=0.2 flywheel-loop doctor --repo /Users/josh/Developer/flywheel --json` reports `watcher_isomorphic.status=pass`, `watcher_reenable_recommendation=green`, and `errors=[]`. |

## Remaining Warning Classification

| Warning class | Latest count/status | Release disposition | Existing owner/evidence |
|---|---:|---|---|
| `callbacks_unvalidated_count` | 11 | Non-release for v0.2 public installability. This is historical/private fleet validation backlog, not a public first-run or installer failure. | Doctor signal documents producer/consumer path and keeps warning visible. |
| `callbacks_validated_with_failures_count` | 1 | Non-release for v0.2 public installability. Failed validation receipts remain operational debt; they do not block the public reduced-mode journey. | Doctor signal routes failed receipts to fix-bead/reopen consumers. |
| `closed_bead_artifact_missing_count` / `closed_bead_reopen_candidates_count` | 10 | Non-release for v0.2 public installability. These are historical closed-bead evidence hygiene candidates. | `.flywheel/scripts/closed-bead-artifact-scan.py --doctor --json` reports 200 checked, 10 reopen candidates, and planned `br reopen` actions. |
| `surfaces_unwired_count` | 11 | Non-release for v0.2 public installability. This is canonical-path/3-Q registry completeness debt, not a failure in the shipped public installer or reduced workflow. | Doctor warning points to `flywheel-m5kg` surface registry ownership. |
| `fleet_l_rule_lag_warn` | 3 on direct repo-root probe; full doctor warning remains fleet-scoped | Non-release for public v0.2. Lag is private fleet doctrine propagation across sibling repos, not public Flywheel package behavior. | `.flywheel/scripts/fleet-l-rule-lag-probe.sh --root /Users/josh/Developer/flywheel --json` reports ALPS, Mobile Eats, and VRTX missing L168. |
| `oversized_files_count` | 290 | Non-release for v0.2. File-length debt is real maintainability debt, but current public gates exercise the CLI/install/doctor paths and the largest files are mission/history or existing engine scripts. | `.flywheel/scripts/file-length-probe.sh --repo /Users/josh/Developer/flywheel --json` reports status `warn`, 290 oversized files, 41 allowed oversized files. |
| `watcher_isomorphic_fleet_not_green` | yellow/mixed | Non-release for v0.2. Fleet watcher apply-mode re-enable remains an operator/fleet decision and is not required for public non-NTM install or reduced-mode operation. The repo-local watcher probe itself is green. | `.flywheel/scripts/watcher-isomorphic-probe.sh --doctor --json` reports `status=pass`; `.flywheel/scripts/watcher-isomorphic-probe.sh --fleet --json` remains fleet-scoped mixed/yellow. |
| `orchs_with_capture_gap_count` | 7 | Non-release for v0.2. Capture parity is important private orchestrator governance debt; public users can run Flywheel without the private NTM/Joshua-input capture ledger. | `.flywheel/scripts/orch-capture-parity-probe.py --doctor --json` reports 7 rows and names `flywheel-xap2` remediation tracks. |
| `plan_state_quality_bar_failed_count` | 5 | Non-release for v0.2. The close gate is doing its job by preserving failed historical plan-state quality rows; the current publication bar passes 7/7. | `.flywheel/scripts/quality-bar-close-gate.sh --doctor --json` reports `status=warn`, `failed_count=5`; publishability bar reports `score=7`. |

## Release Gate Evidence

Commands run after the repairs:

```bash
bash tests/beads-source-repo-basename-normalization.sh
scripts/backfill-source-repo.sh --repo . --dry-run --json
.flywheel/scripts/agent-mail-fd-doctor.sh --doctor --json
.flywheel/scripts/publishability-bar.sh --doctor --json --repo /Users/josh/Developer/flywheel
FLYWHEEL_DOCTOR_NTM_HEALTH_DISABLED=1 /Users/josh/.claude/skills/.flywheel/bin/flywheel-loop doctor --repo /Users/josh/Developer/flywheel --json
bash tests/context-routing-discipline.sh
bash tests/true-publication-registry-validate.sh
```

Observed release-gate result:

- Full doctor status: `warn`, errors `[]`.
- Publishability bar: `pass`, score `7/7`.
- Beads source repo normalization: `pass=6 fail=0`.
- Beads source repo normalization: JSONL has 2,117 canonical rows and DB
  leakage is 0.
- Agent Mail FD pressure: `ok`, direct FD doctor `PASS`, `total_fds=9`,
  `lock_fd_count=0`; full loop doctor reports `total_fds=71`,
  `lock_fd_count=6`.
- Watcher isomorphic repo-local probe: `pass`, `watcher_reenable_recommendation=green`,
  even with `FLYWHEEL_DOCTOR_PROBE_TIMEOUT_SECONDS=0.2`; fleet watcher remains
  `yellow/mixed` and non-release for v0.2.
- Context/model routing discipline: `pass=24 fail=0`.
- Registry validator before TP-019 closure: `pass=4 fail=0`.

## Follow-Up Boundary

The remaining warnings should stay on the normal Flywheel backlog and should
not be represented as v0.2 public-install blockers unless they begin to fail
one of these public release gates:

- installer smoke
- journey smoke
- naming conventions
- depersonalization scans
- public surface gap scanner
- package/install metadata
- GitHub workflow contract
- reduced-mode doctor/first-run/tick/closeout path
