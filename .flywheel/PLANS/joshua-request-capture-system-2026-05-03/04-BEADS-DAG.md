---
title: "Phase 4 BEADS DAG"
type: plan
created: 2026-05-04
frontmatter_source: scaffold-doc-frontmatter
---

# Phase 4 BEADS DAG

> 15 beads, 17 dependencies, 0 cycles. Plan-space only — DO NOT DISPATCH yet (3 workers busy with other beads + meta-rule says drain ready queue first).

## Bead table

| ID | Title | P | Depends on |
|----|-------|---|------------|
| flywheel-wroj | [josh-req-1] author josh-request-schema.md canonical template | 0 | — (root) |
| flywheel-l6j2 | [josh-req-2] implement josh-request-capture.sh UserPromptSubmit hook | 0 | wroj |
| flywheel-2ps2 | [josh-req-3] update flywheel/.flywheel/MISSION.md add Joshua Requests section | 0 | wroj |
| flywheel-v9a8 | [josh-req-4] register hook in ~/.claude/settings.json UserPromptSubmit | 0 | l6j2 |
| flywheel-iaak | [josh-req-5] implement josh-requests CLI helper | 1 | wroj, j9fq |
| flywheel-j9fq | [josh-req-6] init JSONL substrate ~/.local/state/flywheel/josh-requests.jsonl | 1 | wroj |
| flywheel-a6ax | [josh-req-7] tick-path promotion script josh-request-tick-promote.sh | 1 | iaak, j9fq |
| flywheel-9wqw | [josh-req-8] wire promotion script into flywheel-loop-tick | 1 | a6ax |
| flywheel-3tzo | [josh-req-9] /flywheel:status dashboard surface for open Josh-requests | 1 | iaak |
| flywheel-sur0 | [josh-req-10] dispatch-template acceptance gate josh_request_id | 1 | iaak |
| flywheel-7elw | [josh-req-11] INCIDENTS doctrine promotion joshua-request-forgotten | 2 | 9wqw |
| flywheel-flmn | [josh-req-12] author canonical L-rule JOSHUA-REQUEST-CAPTURE-MANDATORY | 2 | 7elw |
| flywheel-cg9w | [josh-req-13] extend doctrine-sync hook to propagate josh-request-schema | 2 | wroj |
| flywheel-iyex | [josh-req-14] stamp 6 peer MISSION files with Joshua Requests section | 2 | cg9w |
| flywheel-ofwh | [josh-req-15] backfill today's flywheel orch transcript | 1 | l6j2, iaak |

## Wave plan (parallel-dispatchable)

```
Wave 1 (1 bead):    wroj                              # schema (root)
Wave 2 (3 beads):   l6j2, 2ps2, j9fq, cg9w            # parallel — all depend only on schema
Wave 3 (2 beads):   v9a8, iaak                        # hook reg + CLI helper
Wave 4 (4 beads):   a6ax, 3tzo, sur0, ofwh            # tick promote + status + gate + backfill (parallel)
Wave 5 (1 bead):    9wqw                              # wire into tick driver
Wave 6 (3 beads):   7elw, iyex                        # INCIDENTS + stamp peers
Wave 7 (1 bead):    flmn                              # canonical L-rule
```

Estimated: 15 dispatches over 7 waves, ~3-4 hours wall-time with 3 parallel codex workers.

## Audit findings → bead mapping

| Finding | Severity | Mitigated by |
|---------|----------|--------------|
| F1 noise/signal hook fires on every msg | medium | l6j2 (regex pattern-match acceptance gate) |
| F2 concurrent JSONL appends | medium | j9fq (atomic-append test) |
| F3 token leak via excerpt | HIGH | l6j2 (secret-scrub acceptance gate) |
| F4 closure without satisfaction | medium | iaak (--evidence flag enforcement) |
| F5 schema drift across peers | medium | cg9w + iyex (doctrine-sync extension + stamp) |

All 5 findings have mitigating beads. Phase 3 audit gate satisfied.
