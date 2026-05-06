# Flywheel Goal

schema_version: 1
doc_type: goal
status: locked
repo: /Users/josh/Developer/flywheel
repo_realpath: /Users/josh/Developer/flywheel
installed_from: /Users/josh/Developer/flywheel/templates/flywheel-install
template_version: "0.1.0"
template_hash: 43d3b3f39af636be079de8e8d2728360fced885e6438c26afd88f5e461a17ebf
rendered_at: 2026-05-01T01:25:43Z
rendered_by: template-live-doc-backfill
lock_hash: 834e060c1eb7c62e5fa110d29fecb25f9d63269373587e74c41681283d690b4b
locked_at: 2026-05-01T01:25:43Z
locked_by: template-live-doc-backfill
source_path: /Users/josh/Developer/flywheel/.flywheel/GOAL.md
source_sha256: 576e5bb5975e223e3fb10e498a9d405f0d38ee56df7352dbaa3513af9d91fc03
source_section: legacy compact live doc
provenance_note: Backfilled from the flywheel legacy operational goal without removing live sections.

## Current Goal

Keep Phase A autoloop, loop architecture, repo-local bead isolation, and doctrine alignment testable and converged across Joshua's active repos.

Current post-isolation priority stack:

1. Beads DB health automation: add flywheel doctor checks for repo-local DB existence, integrity_check, WAL/freelist risk, source_repo normalization, and global-vault tombstone integrity.
2. AM service reliability fix: stabilize Agent Mail availability and stale reservation handling so worker dispatch, callbacks, and file reservations remain dependable.
3. joshua_verdicts feedback loop activation: connect explicit Joshua keep/drop/promote/defer decisions into flywheel outcomes, proposal lifecycle, and future prioritization.
4. Template contract / live doc alignment: keep repo-local .flywheel templates, command definitions, doctor checks, and live docs in sync so install/reconcile/lock behavior stays testable.
5. README.md maintenance: keep the repo README accretive, concise, and current with shipped substrate behavior, validation commands, and operational boundaries.

## Measured Acceptance Criteria

- br where from /Users/josh/Developer/flywheel resolves to /Users/josh/Developer/flywheel/.beads, not a global vault.
- Repo-local DBs have source_repo='.' count of 0.
- br create writes absolute source_repo.
- bd and br-real are absent from PATH.
- ntm spawn recovery skips cross-project beads.
- tests/phase2-audit.sh passes.
- flywheel-loop doctor --strict --repo /Users/josh/Developer/flywheel --json returns status ok.
- MISSION.md, GOAL.md, STATE.md, and loop.json remain aligned with the template contract and lock validation.

## Validation Commands

- shasum -a 256 /Users/josh/Developer/flywheel/AGENTS.md /Users/josh/Developer/alpsinsurance/AGENTS.md /Users/josh/Developer/skillos/AGENTS.md
- /Users/josh/.claude/skills/.flywheel/bin/flywheel-loop doctor --strict --repo /Users/josh/Developer/flywheel --json | jq '.status'
- /Users/josh/Developer/flywheel/tests/phase2-audit.sh

## Current Blockers

- Agent Mail service reliability and stale reservation handling still need hardening.
- Beads DB health automation is not yet fully encoded in flywheel doctor checks.
- Template/live doc alignment is in progress and must avoid losing operational sections.
- Upstream fixes in Jeff Emanuel's repos are tracked separately from local working patches.

## Safe Next Action

Run strict doctor after this backfill, then dispatch the next bounded bead from the post-isolation priority stack if worker capacity exists.

## Out Of Scope

- Application-code changes in downstream repos.
- Opinionated PRs against Jeff Emanuel's repos; local patches can be evidence, but upstream issues carry the request.
- Reintroducing global bead fallback, cross-repo bead recovery, or silent .beads walk-up leakage.
- Weakening the template contract to fit legacy compact docs.

## Lock Receipt

Backfilled from the legacy compact live goal on 2026-05-01T01:25:43Z by template-live-doc-backfill. The lock_hash covers the body after this metadata block.

## Operational Addenda

### Immediate: Bead Isolation Fix (COMPLETED)

Completed 2026-04-30. The 21-bead, 4-phase bead isolation fix closed all 8 bead-ecosystem cross-project leakage failure modes (FM-1 through FM-8).

Delivered scope:

1. Phase 1 stop-the-bleed defenses in ntm: strict bead invocation, spawn recovery provenance checks, CM workspace scoping, and checkpoint path validation.
2. Phase 2 clean state work: binary consolidation, repo-local .beads initialization, source_repo normalization, Developer/.beads tombstone, bd/br-real removal, and runtime handoff working_dir scoping.
3. Phase 3 SQL and command hardening in beads_rust: source-repo filters, absolute source_repo at create time, last-touched repo guard, and authority diagnostics.
4. Phase 4 guardrails: runtime provenance assertion, hook audit/guards, CI/data audit coverage, and Phase 2 audit script.

Boundary going forward: preserve repo-local bead ownership. New flywheel work must not reintroduce global bead fallback, cross-repo bead recovery, or silent .beads walk-up leakage.

### Upstream Issue Chain (Jeff / Dicklesworthstone)

NTM, BR, and frankensqlite are Jeff Emanuel's repos. Issues we find go through a prescribed chain:

- File GitHub Issues on Dicklesworthstone/{repo} with problem statement and repro steps.
- Reference our local commit as evidence, not as prescriptive fix.
- Jeff's agents work his issues; do not derail with opinionated PRs.
- Keep our local patches as the working solution regardless of upstream resolution.
- Subscribe to repos for notification when Jeff addresses issues.

Filed upstream issues on 2026-04-30:

1. frankensqlite#85: Arc<[u8]> Blob iteration break; cargo install fails.
2. beads_rust#269: NULL notes constraint violation in beads.db.
3. beads_rust#270: WAL wedging under concurrent multi-agent SQLite access.

### Ongoing: Flywheel Orchestrator Responsibilities

This repo is the substrate that controls all other NTM sessions. The orchestrator must:

1. Monitor beads DB health: recurring integrity_check sweep across repo-local DBs, automated repair for known patterns, WAL/freelist monitoring, and source-repo drift detection.
2. Manage worker dispatch lifecycle: monitor pane completions, dispatch next wave, track callbacks, enforce transport gates, and prevent silent drops.
3. Track errors and trends: cargo/go build breaks from upstream deps, new repos without .beads initialization, WAL wedge frequency, hook regressions, and recurring failed doctor checks.
4. Maintain ecosystem documentation and test coverage: keep audit reports current, grow shell/database/hook coverage, and ensure tests encode every closed failure mode.
5. Run Sunday coffee review for Petal 9: what shipped, patterns emerged, upstream issues for Jeff, open substrate risks, and next week's focus.
