## L124 — SUBSTRATE-DISCIPLINE-NO-ORCHESTRATOR-PAUSE

---
id: L124
title: Substrate discipline no orchestrator pause
status: long_term
shipped: 2026-05-07
review_due: 2026-11-07
trauma_class: substrate-discipline
---

Beads substrate corruption, stale recovery debris, and low-disk write pressure
are flywheel-owned auto-ops conditions. The orchestrator does not pause for
manual direction when the safe repair class is already encoded: use `br` as the
only Beads writer, rebuild disposable DB state from clean JSONL, and prune
repo-local substrate bloat before WAL/JSONL writes degrade.

**How to apply:**
- `.beads/issues.jsonl` is written only through `br create`, `br update`, or
  `br close`. Manual append fallback is a violation even when a callback or
  fix-bead path is under pressure.
- `beads.db` and its sidecars are disposable indexes. When
  `br doctor --json` reports `workspace_health=unsafe` and the class is
  rebuildable, run
  `~/.claude/skills/.flywheel/scripts/beads-auto-rebuild-from-jsonl.sh --repo
  <repo> --apply --json` after backing up to `/tmp`.
- `flywheel doctor` exposes three substrate discipline scopes:
  `beads.jsonl.write_discipline`, `beads.recovery.bloat`, and
  `beads.sidecar.staleness`.
- `.flywheel/scripts/storage-prune.sh` archives `.br_recovery/` bloat to
  `/tmp`, removes stale `.beads/*.aside.*` and `.beads/*.bak.*` by exact path,
  and archives old `jeff-corpus/*` entries.
- `/flywheel:tick` enforcement is process-wired through
  `.flywheel/scripts/tick-driver-manifest.json` entries for `storage-prune` and
  `beads-auto-rebuild-from-jsonl`; prose-only wiring does not count.

**Forbidden outputs:**
- Asking Joshua whether to run a clean JSONL-backed Beads DB rebuild.
- Appending issue rows, event rows, fallback close rows, or fix-bead rows
  directly to `.beads/issues.jsonl`.
- Treating `.br_recovery/`, stale sidecars, or low disk as a dashboard warning
  without a doctor field and an auto-prune path.
- Calling substrate recovery shipped without tick-driver manifest evidence.

**Evidence:** memory rules
`feedback_beads_jsonl_writes_via_br_only.md`,
`feedback_substrate_rebuild_is_disposable_not_class_5.md`, and
`feedback_storage_pressure_blocks_substrate.md`; doctor scopes in
`~/.claude/skills/.flywheel/bin/flywheel`; primitive
`~/.claude/skills/.flywheel/scripts/beads-auto-rebuild-from-jsonl.sh`; storage
primitive `.flywheel/scripts/storage-prune.sh`; tick manifest
`.flywheel/scripts/tick-driver-manifest.json`; Jeff WAL/lock prior-art receipt
`/tmp/jeff-wal-lock-prior-art-2026-05-07.md`; storage correlation receipt
`/tmp/storage-substrate-correlation-2026-05-07.md`.

Mission-anchor: continuous-orchestrator-uptime-self-sustaining-fleet.

**Cross-references:** L48, L50, L52, L53, L56, L60, L70, L71, L72, L96, L110,
L116, and L120.

