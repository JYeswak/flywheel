# State

status: locked
repo: /Users/josh/Developer/flywheel
lock_hash: bea6cb533ccb8c0dfb5126f66d2b7f932c487e5bd0043562a03e6afd09c615ba

## Completed

- Bead isolation is complete across all 21 planned beads and all four phases.
- Phase 1 stopped recovery bleed in ntm: strict bead lookup, recovery bead gating, checkpoint validation, and workspace-scoped context.
- Phase 2 consolidated binaries and normalized repo authority: local `.beads` confirmed, `source_repo` backfilled, global vault frozen, and Developer `.beads` symlink tombstoned.
- Phase 3 hardened beads_rust SQL and discovery: repo filters, `--repo`, last-touched guards, symlink rejection, and `BEADS_STRICT_LOCAL`.
- Phase 4 added CI/runtime guardrails: symlink bleed regression, recovery provenance assertions, authority diagnostics, hook guards, and project-scoped checkpoints.
- Final validation on 2026-04-30: `br where` resolves to `/Users/josh/Developer/flywheel/.beads`.
- `br list` in flywheel shows only local flywheel beads; cross-repo leakage count is 0.
- Global vault remains archival only and is protected by tombstone/frozen behavior.
- All 8 known bead failure modes, FM-1 through FM-8, are addressed.
- Upstream evidence chain is preserved through local commits and filed GitHub issues.

## Current Mission: Flywheel Substrate Audit & Hardening

- Full ecosystem audit completed with 3 Codex workers and 3 reports:
  - `/tmp/flywheel-audit-hooks-and-repo.md`
  - `/tmp/flywheel-audit-skills-system.md`
  - `/tmp/flywheel-audit-tests-proposals-db.md`
- Comprehensive `README.md` is being written for the repo so new workers can understand the local flywheel substrate without reading scattered audit artifacts first.
- Upstream issues filed and subscribed:
  - `frankensqlite#85` — `Arc<[u8]>` Blob iteration break causing cargo install failure.
  - `beads_rust#269` — NULL notes constraint violation in `beads.db`.
  - `beads_rust#270` — WAL wedging under concurrent multi-agent SQLite access.
- Next phase is hardening the flywheel repo itself as the local authority for orchestration state, audits, tests, proposals, hooks, and bead-health automation.

## Ecosystem Inventory

- Hooks and commands: 8 active flywheel hooks and 16 flywheel slash commands.
- Executables: 30+ binaries under the flywheel `bin/` surface.
- Tests and proposals: 57 tests and 59 proposals.
- Capability inventory: 21 skill packs.
- `state.db` shape: 9 tables.
- `state.db` current counts: 11,776 events, 1,233 sources, 808 snapshots, 396 deltas.

## Gaps Found

- Top-level `README.md` now exists as a draft/substrate map, but still needs completion and tracking as the reliable repo entrypoint.
- `joshua_verdicts` is active: verdict capture is wired through `flywheel-loop verdict`, and rows now land in `state.db`.
- AM service investigation closed the apparent failure as a diagnostic mismatch; local Agent Mail is healthy, so the remaining work is probe/runbook alignment rather than service repair.
- Template/live doc alignment report has been produced and recommends backfilling live repo-local docs to the richer template contract.
- Beads DB health automation is now part of doctor coverage for repo-local integrity, WAL health, NULL-note damage, and cross-repo leakage sentinels.
- Backup files in `bin/` still create inventory noise and make the executable surface harder to audit.

## Next Actions

1. AGENTS.md doctrine drift repair across fleet: complete the active dispatch and reconcile repo-local doctrine snapshots.
2. Template/live doc backfill: apply the alignment report recommendations to live `.flywheel` docs and templates.
3. Flywheel repo `README.md` completion: finish and track the top-level entrypoint for new workers.
4. STATE.md relock via `/flywheel:relock-state` Q&A with Joshua: replace this mechanical refresh with reviewed state lock when Joshua is available.
