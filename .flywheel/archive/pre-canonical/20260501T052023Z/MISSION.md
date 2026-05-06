# Flywheel Mission

schema_version: 1
doc_type: mission
status: locked
repo: /Users/josh/Developer/flywheel
repo_realpath: /Users/josh/Developer/flywheel
installed_from: /Users/josh/Developer/flywheel/templates/flywheel-install
template_version: "0.1.0"
template_hash: b16c74ddcf48e94ccc0130a19b0fde842608f00da4136319727037ad893fc06f
rendered_at: 2026-05-01T01:25:43Z
rendered_by: template-live-doc-backfill
lock_hash: b7c93e0631d4ab78fbecdf2e4298b4cdb59fc8c193c1bd8fa6261ea45e4c8e18
locked_at: 2026-05-01T01:25:43Z
locked_by: template-live-doc-backfill
source_path: /Users/josh/Developer/flywheel/.flywheel/MISSION.md
source_sha256: cff6eb918478d7de08d9f3dd3b0b13221d6aa9acd930fadb45e045b095498551
source_section: legacy compact live doc
provenance_note: Backfilled from the flywheel legacy compact live mission without removing substance.

## Mission Source

Flywheel is the orchestration repo for ZestStream's agentic coding infrastructure. It coordinates bead-based task graphs, dispatches work to ntm workers, and houses plans, skills, templates, command contracts, audits, and cross-repo coordination artifacts.

Ecosystem-level mission and operating doctrine live under:

- /Users/josh/.claude/skills/.flywheel/GOAL.md
- /Users/josh/.claude/skills/.flywheel/WORK.md
- /Users/josh/.claude/skills/.flywheel/LOOP.md

## North-Star Outcome

A repo-scoped, self-improving flywheel substrate that keeps Joshua's agents coordinated, dispatchable, observable, and grounded in current doctrine without leaking state across repos.

## Primary Beneficiary

Joshua Nowak and the ZestStream agent fleet: orchestrator panes, worker panes, repo-local flywheel installs, and the downstream client/application repos they coordinate.

## Explicit Non-Goals

- This repo does not contain application product code.
- This repo must not become a dumping ground for global bead state or cross-repo task ownership.
- This repo must not bypass repo-local readiness, receipt, transport, doctrine, or bead isolation gates.

## Safety And Privacy Boundaries

- Keep source edits repo-scoped and bead- or loop-backed.
- Preserve canonical doctrine and do not silently mutate client/application repos from this substrate.
- Use ntm for pane operations and keep worker dispatches visible through callbacks and logs.
- Do not reintroduce global bead fallback, cross-repo bead recovery, or silent .beads walk-up leakage.

## Evidence That Would Change The Mission

Change this mission only if Joshua changes the orchestration ownership model, the flywheel substrate moves out of this repo, or repeated incidents show that a different source-of-truth layout better preserves repo isolation and agent coordination.

## Owner-Review Cadence

Review when the flywheel template contract changes, after major loop/autoloop architecture changes, after doctrine-drift repair batches, or at least quarterly during Sunday coffee review.

## Lock Receipt

Backfilled from the legacy compact live mission on 2026-05-01T01:25:43Z by template-live-doc-backfill. The lock_hash covers the body after this metadata block.
