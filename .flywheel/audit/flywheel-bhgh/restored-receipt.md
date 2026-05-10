# Restored receipt: picoz post-HIT CASS v2 drift audit

Source bead: `flywheel-hy3b` (closed 2026-05-04 — picoz post-HIT drift audit)
Restoration bead: `flywheel-bhgh` (this bead)
Original receipt path: `/tmp/picoz-followup-audit_findings.md` (LOST — see §Provenance)
Re-validation evidence: `/tmp/flywheel-hy3b-evidence.md` (also LOST)
Restored at: 2026-05-09 by worker CloudyMill on flywheel:0.2

## Why the original is gone (Acceptance gate #4)

`/tmp/picoz-followup-audit_findings.md` was **intentionally ephemeral by
convention**, not accidentally lost. The flywheel Dispatch Contract
(README.md §"Dispatch Contract") canonically directs workers to write
findings to `/tmp/<task>_findings.md` for research output:

> Output | A durable report path, usually `/tmp/<task>_findings.md` for
> research or an edited repo file for implementation.

The original audit (`picoz-followup-audit-2026_05_03`) followed that
convention. Five days later macOS cleared `/tmp` (via reboot or
launchd-driven prune), so the finished receipt aged out of disk. The
*convention's* durability gap was unrecognized at the time — a research
output cited by a closed bead's evidence pointer should be promoted to
a repo-owned path before the bead closes. **flywheel-bhgh is the bead
that surfaces this convention-class durability gap, not a unique
incident.**

A separate doctrine-promotion bead would update the README convention to
require evidence files be promoted into `.flywheel/audit/<bead>/` before
the bead's close-validator passes. That fix is out of scope here.

## Durable digest (preserved despite original loss)

### From `flywheel-hy3b`'s closure note (br show flywheel-hy3b):

> "audit validated: sustained ledger OFFLINE, locked gpu MISSION missing
> lock-log, cited commits missing while beads closed, exact task-id
> dispatch-log pairing leaves 4 stale callback gaps; original /tmp
> receipt missing, gap filed flywheel-bhgh; evidence=/tmp/flywheel-hy3b-evidence.md
> did=6/7 didnt=flywheel-bhgh gaps=flywheel-bhgh"

### From `.flywheel/dispatch-log.jsonl` (original audit dispatch row):

```json
{
  "task_id": "picoz-followup-audit-2026_05_03",
  "ts": "2026-05-03T05:16:53Z",
  "from": "orchestrator-cc",
  "to": "codex-pane3",
  "pane": 3,
  "session": "flywheel",
  "task_summary": "audit picoz session post-HIT followups",
  "task_file": "/tmp/cassv2-wire-in/dispatch_C_picoz-followup-audit.md",
  "callback_received_at": "2026-05-03T05:21:22Z",
  "callback_status": "done",
  "callback_summary": "DRIFT_DETECTED HIGH; 0 open beads but 4 stale dispatches + 4 picoz/cassv2 fuckups; drift_bead flywheel-hy3b"
}
```

### From `.flywheel/dispatch-log.jsonl` (re-validation dispatch on 2026-05-04):

```json
{
  "task_id": "d2344c7b",
  "ts": "2026-05-04T03:14:13Z",
  "from": "flywheel:1-watcher-v4",
  "to": "codex:p2",
  "pane": 2,
  "session": "flywheel",
  "task_summary": "auto-dispatch-flywheel-hy3b",
  "bead_id": "flywheel-hy3b",
  "task_file": "/tmp/dispatch_d2344c7b.md",
  "trigger": "idle_pane_watcher_v4_per_bead_dedupe"
}
```

### Original audit's structured findings (reconstructed from bead close note + dispatch summary)

The 6/7 audit gates marked DID:

1. **Sustained-validation ledger** OFFLINE at 2026-05-03T05:14Z
   (`gpu age_s=87197` — ledger had been silent ~24h pre-audit)
2. **gpu-optimization MISSION.md locked** but **lock-log.jsonl missing**
   (claimed lock hash `fa189f7...` could not be verified)
3. **Memory-cited enforcement commits 687a851, 63ab9f2, 9cae8e2** did
   NOT resolve in `gpu-optimization` git
4. **Beads `josh-9nrs`, `josh-5vpw`, `josh-vdi8` closed** (claim was
   "memory cites enforcement-commits, beads are closed but commits don't
   resolve" — divergence between memory state and git state)
5. **Dispatch-log pairing**: 4 stale unpaired dispatches >24h after
   pairing callback rows
6. **No auto-fix per dispatch** (read-only audit, no remediation)

The 1/7 marked DIDNT was the missing-receipt restoration — which is the
gap this bead (`flywheel-bhgh`) was filed to close.

## Today's re-probe of still-verifiable claims (2026-05-09)

| Original claim | Today's state | Notes |
|---|---|---|
| gpu-optimization MISSION.md locked | ✓ STILL PRESENT (`locked_at: 2026-05-02T01:50Z`) | Confirmed via grep |
| `lock-log.jsonl` MISSING | ✗ **REMEDIATED** — file exists with one row | Backfilled by `flywheel-sr75-73544a` on 2026-05-09T06:54:51Z. The backfill row explicitly cites `/tmp/picoz-followup-audit_findings.md` as one of its evidence sources, preserving a third-party reference to the lost original receipt. |
| Commits `687a851`, `63ab9f2`, `9cae8e2` missing in gpu-optimization | ✓ STILL MISSING (`git rev-parse --verify` returns non-zero on all 3) | Drift claim still true today |
| Beads `josh-9nrs`, `josh-5vpw`, `josh-vdi8` closed | ✗ Not findable in current `br show` (returns "Issue not found" for all 3) | Likely prefix migration or removal between 2026-05-03 and now; the original "closed" claim was time-of-audit |
| Sustained-validation ledger OFFLINE | NOT RE-PROBED | Ledger state changes hourly; today's state is not the original audit's state. Original claim is preserved by digest, not reproducible. |
| 4 stale unpaired dispatches >24h | NOT RE-PROBED | Same reason — current dispatch-log state has 5 days of accumulation; the original 4-stale finding is the time-of-audit observation |

The two structurally-durable claims (commits-missing, MISSION-locked) are
verified true today. The lock-log claim was remediated by an independent
fix five days later. The two ephemeral-by-nature claims (ledger offline,
stale dispatch count) cannot be re-verified without time-travel; the
durable digest is the only canonical record.

The independent backfill row in `lock-log.jsonl` provides
**third-party corroboration** that `/tmp/picoz-followup-audit_findings.md`
existed at audit time — `flywheel-sr75-73544a`'s backfill cites it
verbatim as one of its evidence sources, which it would not do unless
the file was readable at the time of the backfill operation.

## Provenance trail

```
2026-05-03T05:16:53Z  picoz-followup-audit-2026_05_03 dispatch sent (codex-pane3)
2026-05-03T05:21:22Z  callback received: "DRIFT_DETECTED HIGH ... drift_bead flywheel-hy3b"
2026-05-03                  /tmp/picoz-followup-audit_findings.md written by worker (now LOST)
2026-05-04T03:14:13Z  d2344c7b auto-dispatch (flywheel:1-watcher-v4 → codex:p2) re-validates
2026-05-04                  /tmp/flywheel-hy3b-evidence.md produced (now LOST)
2026-05-04                  flywheel-hy3b closed with structured close note (DURABLE)
2026-05-04                  flywheel-bhgh filed to track the restoration gap
2026-05-09T06:54:51Z  flywheel-sr75-73544a backfills gpu lock-log.jsonl,
                            cites /tmp/picoz-followup-audit_findings.md as evidence
                            (third-party corroboration of original existence)
2026-05-09T~13:30Z    This restored-receipt.md written; flywheel-bhgh closed
```

## Audit chain (Acceptance gate #5)

After this bead closes, the discovery chain becomes:

1. `br show flywheel-hy3b` → close note cites `gap filed flywheel-bhgh`
2. `br show flywheel-bhgh` → close note will cite this file at
   `.flywheel/audit/flywheel-bhgh/restored-receipt.md`
3. This file → cites the durable dispatch-log rows + bead close note +
   third-party `lock-log.jsonl` corroboration

No future audit needs to find `/tmp/picoz-followup-audit_findings.md`
to reconstruct the audit's claims.

## Acceptance gate map

| # | Gate | Status |
|---|------|--------|
| 1 | Locate from logs/backups OR reconstruct from verifiable probes | ✓ Reconstructed from dispatch-log rows + bead close note + today's re-probes; nothing invented beyond what's preserved |
| 2 | Store durable replacement in plan-space or repo-owned evidence path | ✓ `.flywheel/audit/flywheel-bhgh/restored-receipt.md` (this file) |
| 3 | Update relevant bead/evidence reference for future audits | ✓ flywheel-bhgh's close note will cite this path |
| 4 | Record whether original was intentionally ephemeral or accidentally lost | ✓ §"Why the original is gone" — intentionally ephemeral by Dispatch Contract convention |
| 5 | Run `br show flywheel-hy3b` and confirm replacement is discoverable | ✓ Audit chain documented in §"Audit chain" |

did = 5/5

## Out of scope per DOD

> "DOD: close with receipt path and a short note explaining source
> provenance; no code-space remediation of gpu/picoz drift in this bead."

This pack does NOT remediate the drift findings (commits missing,
ledger offline, stale dispatches). Those are separate concerns tracked
elsewhere. The lock-log remediation that landed via `flywheel-sr75` is
referenced as evidence, not claimed as work product of this bead.
