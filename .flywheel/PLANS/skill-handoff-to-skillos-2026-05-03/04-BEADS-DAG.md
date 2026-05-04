# Phase 4 BEADS DAG

> 8 beads, 14 dependencies, 0 cycles. Plan-space only — DO NOT DISPATCH until current ready queue (4 in-progress + 14 pre-existing ready) drains.

## Bead table

| ID | Title | Priority | Depends on |
|----|-------|----------|------------|
| flywheel-hrxp | [skillos-handoff-1] author skill-handoff-to-skillos.md fleet-mail template | 1 | — (root) |
| flywheel-g343 | [skillos-handoff-2] implement handoff-skill-to-skillos.sh helper | 1 | hrxp |
| flywheel-jrvh | [skillos-handoff-3] add handoff acceptance gate to flywheel canonical dispatch template | 1 | hrxp, g343 |
| flywheel-8bie | [skillos-handoff-4] implement audit-skill-handoff-coverage.sh backfill auditor | 2 | g343 |
| flywheel-m3ni | [skillos-handoff-5] backfill: handoff all 30d-flywheel-shipped skills missing skillos receipts | 2 | g343, 8bie |
| flywheel-4dpj | [skillos-handoff-6] register fuckup heuristic skill-shipped-without-skillos-handoff | 2 | jrvh |
| flywheel-w307 | [skillos-handoff-7] author canonical L-rule SKILL-CREATION-REQUIRES-SKILLOS-HANDOFF | 2 | jrvh, g343, 4dpj |
| flywheel-7ra1 | [skillos-handoff-8] agent-mail to skillos orch announcing new handoff contract | 2 | hrxp, g343, jrvh, w307 |

## Wave plan (parallel-dispatchable)

```
Wave 1 (1 bead):    hrxp                          # template authoring (root)
Wave 2 (1 bead):    g343                          # helper script (depends on template)
Wave 3 (3 beads):   jrvh, 8bie, m3ni              # parallel — gate, audit, backfill
                    [m3ni waits for 8bie completion within wave]
Wave 4 (1 bead):    4dpj                          # fuckup heuristic
Wave 5 (1 bead):    w307                          # canonical L-rule
Wave 6 (1 bead):    7ra1                          # skillos announcement (last — needs full contract live)
```

Estimated dispatch cost: 8 worker-dispatches over 6 waves.

## Audit findings → bead mapping (every finding mitigated)

| Finding | Severity | Mitigated by |
|---------|----------|--------------|
| F1 idempotency | medium | g343 (acceptance gate 2: re-run exits 4) |
| F2 file-reservation race | medium | jrvh (encodes sender_release → skillos_reserve sequence) |
| F3 forbidden-distribution leak | high | g343 (acceptance gate 3: jsm show, exit 3 if upstream_owned) |
| F4 audit signal/noise | low | 8bie (treats null+null as gap, populated reason as known-skip) |

All 4 findings have mitigating beads. Phase 3 audit gate satisfied.
