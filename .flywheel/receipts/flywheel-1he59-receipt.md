# flywheel-1he59 Storage Prune Receipt

Bead: `flywheel-1he59`
Source: ALPS tick `alps_loop_20260508T012545Z`
Created: 2026-05-08T01:38:00Z

## Summary

ALPS reported 35.64 GB free, below the 50 GB fleet headroom threshold. Live
probe on this host measured worse pressure before pruning:

| Metric | Before | After |
|---|---:|---:|
| disk_free_gb | 34.60 | 37.29 |
| disk_free_pct | 3.74 | 4.03 |
| storage tier | FIRE | FIRE |
| storage status | fail | fail |

Result: applied the encoded safe prune path and reclaimed about 2.69 GB, but
storage remains below the 50 GB threshold. Further headroom work should use the
broader storage-headroom watcher categories rather than ad hoc cleanup.

## Dry-Run Candidate Inventory

Canonical storage-prune dry-run:

| Category | Candidate Count |
|---|---:|
| stale `.beads.bak.*` dirs | 0 |
| temp dispatch artifacts | 0 |
| br recovery archives | 0 |
| stale Beads sidecars | 0 |
| repo-local Jeff corpus archives | 0 |

Private temp dry-run:

| Category | Candidate Count |
|---|---:|
| allowlisted private temp dirs | 17 |
| too young | 1 |
| non-dir skipped | 6 |
| open handles skipped during dry-run | 0 |

Additional probes:

- `~/Developer/jeff-corpus` was not present; indexed data still exists at
  `~/.socraticode/qdrant-data`, `~/.knowledge/qdrant_server_storage`, and
  `~/.knowledge/qdrant_storage_openai`.
- `/private/tmp` dev-cache probe found stale mobile-eats cache dirs before
  apply; no dev-cache dirs remained after private temp apply.
- Storage-headroom watcher dry-run still sees safe categories available:
  model-runner image revert, unused Docker images, pnpm store, Go caches, and
  model-cache files. Docker volumes were not pruned.

## Apply Decision

Decision: `applied`.

Rationale: 34.60 GB free and 3.74 percent free is operator-pain territory. A
real ops team should not let write-heavy substrate continue below 50 GB without
running the safe encoded prune path. The canonical repo-local storage prune had
zero candidates, so it was applied as an idempotent no-op receipt. The
allowlist-gated private temp subprimitive had 17 stale class-1 candidates and
was applied to reclaim safe scratch space.

Idempotency key: `20260508T013616Z`.

## Candidate Categories Pruned

| Category | Result |
|---|---|
| storage-prune repo-local candidates | applied, no candidates |
| private temp allowlist candidates | applied, 17 candidates processed |
| Docker volumes | not touched |
| broader storage-headroom watcher categories | dry-run only, not applied in this bead |

## Validation

- `bash tests/storage-probe.sh` passed: 12 passed, 0 failed.
- Post-apply live storage probe still reports `storage_low_headroom`; this bead
  reduced pressure but did not clear the fleet headroom threshold.

## Joshua-Lens Check

Operator-grade durability: this follows the encoded prune path and records the
no-op repo-local result instead of pretending the threshold cleared. That is the
operating discipline a long-running ops team needs: safe action first, explicit
residual risk second.

Team-fit: the receipt is handoff-ready for the next operator. It names what was
safe, what ran, what stayed untouched, and what remains below threshold, so a
new senior ops hire would not have to reconstruct the decision from scrollback.

Company-building leverage: the useful second-order signal is that repo-local
storage-prune did not include the private temp class despite the memory saying
that subprimitive should be part of the storage-prune surface. That is a
follow-up substrate integration gap, not a one-off shell cleanup habit.
