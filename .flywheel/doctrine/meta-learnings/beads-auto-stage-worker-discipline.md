# Worker Discipline — Beads JSONL Auto-Stage Is Forbidden

**Status:** RATIFIED 2026-05-20T20:15Z by flywheel:1 from skillos canonical
**Upstream source:** `/Users/josh/Developer/skillos/.flywheel/doctrine/meta-learnings/beads-auto-stage-worker-discipline.md` (skillos canonical-doctrine lane)
**Schema:** `skillos.beads_auto_stage_worker_discipline.v1`
**Trauma class:** `beads-jsonl-worker-auto-stage-contention`
**Promotion path:** L-rule lane if any of the 4 gates below trip

## Provenance

Authored by skillos:1 cc-opus-4-7 from root-cause diagnosis of fleet-wide Beads failure 2026-05-20. Joshua flagged the trauma; skillos diagnosed (commit `5c8527a2`, file `state/skillos-beads-jsonl-block-diagnosis-20260520.md`); skillos shipped the wrapper fix; flywheel:1 ratified for fleet propagation.

This doctrine is canonical at the skillos source-of-truth path. Consumer repos pull via `/flywheel:sync-doctrine` (per the upstream-never-writes-into-consumer-trees rule). flywheel maintains this ratified mirror for fleet-wide visibility + the pull mechanism's source.

## Genesis (verbatim from skillos canonical)

Joshua flagged a fleet-wide Beads failure on 2026-05-20: workers across repos were seeing blocks on `.beads/issues.jsonl`. The root cause was not JSONL truncation. The global `br` wrapper ran `git add .beads/issues.jsonl` after successful mutating Beads commands. Under parallel workers, the Beads mutation succeeded but the wrapper returned failure from `.git/index.lock` contention.

## Trauma Class

`beads-jsonl-worker-auto-stage-contention`: worker executes `br create`, `br close`, `br update`, `br comment`, or `br comments`; the Beads DB/JSONL mutation succeeds; a wrapper or worker then auto-stages `.beads/issues.jsonl`; Git index contention or stale `.git/index.lock` makes the whole command appear failed.

This presents as "blocked on `.beads/issues.jsonl`" even when the ledger parses cleanly.

## Worker Discipline Contract

Workers do not auto-stage `.beads/issues.jsonl`.

After a successful Beads mutation:

1. Treat the Beads mutation as complete if `br` itself returned success.
2. Do not run `git add .beads/issues.jsonl` from a worker unless the dispatch explicitly owns a Beads-ledger commit.
3. Leave Beads export staging to the orchestrator or a dedicated substrate sweep that stages only classified accreting paths.
4. If `.git/index.lock` blocks a Beads command, inspect for a live owner before classifying it as stale; preserve evidence when quarantining stale locks.
5. Verify `.beads/issues.jsonl` with `jq . < .beads/issues.jsonl` when JSONL corruption is suspected. Do not assume a Git-index failure means JSONL corruption.

## Wrapper Contract

The `br` wrapper may emit a note after successful mutating commands, but it must not run Git staging as a side effect. The canonical note is:

```text
beads file updated; orchestrator will commit when ready; do NOT auto-stage .beads/issues.jsonl from worker
```

Wrapper tests must prove:

- Concurrent mutating commands do not stage `.beads/issues.jsonl`.
- Failed `br` commands preserve the real failure and do not emit the success note.
- Read-only `br` commands do not emit the note.

## Sister Pattern

This is the Beads-layer sister of `.flywheel/doctrine/meta-learnings/auto-push-blocked-worker-discipline.md`. Both classes come from workers translating substrate status into broad Git actions. The antidote is the same: path-specific ownership, orchestrator-owned substrate sweeps, and no implicit worker-side Git side effects.

## Promotion Gates (any trip → L-rule lane promotion)

1. Any global wrapper reintroduces automatic `git add .beads/issues.jsonl`.
2. Any worker callback reports done after `br` succeeded but wrapper-side Git staging failed.
3. Any repo accumulates a stale `.git/index.lock` that blocks Beads mutation creation or closure.
4. Any fleet package ships a wrapper copy that stages Beads JSONL from workers.

## Cross-References

- Skillos canonical source: `/Users/josh/Developer/skillos/.flywheel/doctrine/meta-learnings/beads-auto-stage-worker-discipline.md`
- Diagnosis: `/Users/josh/Developer/skillos/state/skillos-beads-jsonl-block-diagnosis-20260520.md`
- P0 beads: `skillos-0i6tj` (upstream fix), `flywheel-tflv7` (flywheel-side tracking)
- Memory: skillos pin at `~/.claude/projects/-Users-josh-Developer-skillos/memory/feedback_beads_jsonl_workers_no_auto_stage.md`
- Wrapper test: `tests/unit/test_br_stage_wrapper_no_autostage.sh` (skillos)
- Sister: `.flywheel/doctrine/meta-learnings/auto-push-blocked-worker-discipline.md`

## Fleet Propagation Path

Consumer repos pull this doctrine via:

```bash
/flywheel:sync-doctrine --diff-only   # preview what would change
/flywheel:sync-doctrine --apply        # land into consumer .flywheel/doctrine/ (clean-WT gate enforced)
```

DOCTRINE-MANIFEST.json on each consumer repo can pin `tracked_doctrines: ["meta-learnings/beads-auto-stage-worker-discipline.md"]` to opt-in to receiving this doctrine on every sync.

## Standing Verification

Every orch's `/flywheel:tick` should periodically grep its own br-wrapper for `git add .beads/issues.jsonl` patterns. If found: alarm + auto-file `flywheel-tflv7` follow-up under the trauma class.
