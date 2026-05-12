# flywheel-ei5fp Compliance Pack

## Summary

Status: BLOCKED on upstream fix/version absorption  
Compliance score: 880/1000  
Mission fitness: adjacent to `continuous-orchestrator-uptime-self-sustaining-fleet`

## Live Upstream Probe

Command:

```bash
gh issue view 285 --repo Dicklesworthstone/beads_rust \
  --json number,state,title,author,createdAt,updatedAt,closedAt,comments,url
```

Observed on 2026-05-09:

| Field | Value |
|---|---|
| Issue | `Dicklesworthstone/beads_rust#285` |
| State | `OPEN` |
| Updated | `2026-05-08T23:34:52Z` |
| Owner comment | `Dicklesworthstone`, 2026-05-08T23:34:52Z |

Jeffrey acknowledged the repro and identified the dirty tracker silence as the
smoking gun. He left the issue open while investigating.

## Requested Diagnostics

Jeffrey asked for two follow-up artifacts if the precise repro is available:

1. Run the close repro with trace logging:

   ```bash
   RUST_LOG=br::storage::sqlite=trace,br::cli::commands::close=trace \
     br --lock-timeout 10000 close <id>
   ```

2. Run immediately after observing divergence:

   ```bash
   br doctor --json
   ```

The current flywheel repo `br doctor --json` is recoverable, with
`sqlite.integrity_check=ok`, `counts.db_vs_jsonl=ok`, and DB/JSONL both at 1253
records. It still reports stale recovery artifacts and truncated WAL sidecars,
which are adjacent but not a fresh reproduction of issue 285.

## Local Bead Action

`flywheel-ei5fp` was moved from `open` to `in_progress` with a note containing:

- upstream ack timestamp,
- upstream issue still open,
- the two requested diagnostics,
- the local lifecycle condition not to close until upstream closes/fix ships and
  local `br` version is absorbed.

## Socraticode Survey

Queries: 10  
Indexed chunks observed: 100

Useful hits:

- `INCIDENTS.md` `br-sync-stale-db-export-blocked`: preserve DB truth and do not
  force lossy JSONL export.
- `INCIDENTS.md` `br-db-wedge-recurrence`: route integrity failures through
  Beads recovery/rebuild owners.
- `jeff-issue-chain` skill: tracking bead remains open while waiting, moves
  in-progress once Jeff acknowledges, and closes only after upstream close plus
  local absorption.

## Verification

```bash
br show flywheel-ei5fp
br doctor --json
```

Expected L112 token:

```text
status=in_progress
```

## Four-Lens Self-Grade

`four_lens=brand:8,sniff:9,jeff:9,public:8`

Three Judges check: a skeptical operator can see the exact upstream state and
next requested diagnostics; a maintainer can reproduce the live probe; a future
worker has the lifecycle reason for not closing this tracking bead yet.
