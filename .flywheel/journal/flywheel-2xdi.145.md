---
bead: flywheel-2xdi.145
title: REFUTATION — codex-deathtrap-launcher.sh canonically wired in doctrine + tests + 13 cites
worker: MagentaPond (flywheel:0.3)
date: 2026-05-11
status: shipped
priority: P3
mission_fitness: adjacent
parent: flywheel-2xdi
sister_case: flywheel-2xdi.114 (1st MOOT-BY-CURRENT-PROBE-CLEARANCE)
posterior_shape: MOOT-BY-CURRENT-PROBE-CLEARANCE (2nd instance; 2/5 toward orch-tick-auto-close calibration)
disposition: REFUTATION
---

# Journey: flywheel-2xdi.145

## What the bead asked for

gap-wired-but-cold for `.flywheel/scripts/codex-deathtrap-launcher.sh`.

## Investigation (META-RULE 2026-05-11 — 27th application)

**Probe state check first** (per META-RULE: probe before claiming):

```bash
$ .flywheel/scripts/gap-hunt-probe.sh --json | jq '.gap_ids | map(select(test("codex-deathtrap")))'
[]
```

Current probe does NOT flag this script. Bead was auto-filed at 16:54:36Z;
mid-session probe calibrations cleared the flag since then.

**Canonical wiring catalog** (13+ cites):
- `.flywheel/doctrine/codex-death-event-flow.md` — DEDICATED doctrine doc; explicitly cites the script as "the producer of evidence"
- `.flywheel/tests/test-codex-death-event-classifier.sh` — sister test
- `.flywheel/evidence/flywheel-{delp,nsjse}/` — 5 evidence files (origin bead + sibling)
- `.flywheel/receipts/flywheel-ukm9f/audit/` — 6 receipt files
- `.flywheel/handoffs/handoff-2026-05-01T1356Z-fleet-overnight-death.md` — handoff cite

Script is heavily canonically wired. Bead's hypothesis is empirically wrong.

## Disposition: REFUTATION (2nd MOOT-BY-CURRENT-PROBE-CLEARANCE)

Sister to 2xdi.114 (install-petal9-close.sh — flywheel CLI doctor cite).

| # | Bead | Script | Why moot |
|---|---|---|---|
| 1 | 2xdi.114 | install-petal9-close.sh | flywheel CLI doctor cite at bin/flywheel:2012 |
| 2 | **2xdi.145** (this) | codex-deathtrap-launcher.sh | dedicated doctrine doc + sister test + 13+ cites |

**2/5 toward orch-tick auto-close calibration threshold.** Per 2xdi.114
proposal: when 5th MOOT-BY-CURRENT-PROBE-CLEARANCE accrues, file calibration
bead for faqj2 finding type
`stale_auto_bead_no_longer_flagged_by_current_probe`.

## What I shipped

**Nothing edited.** Refutation triage only:
- Evidence pack at `.flywheel/audit/flywheel-2xdi.145/evidence.md`
- This journal entry

No registry edit (probe already cleared); no doctrine doc edit (already
exists); no calibration bead (2/5 threshold not met).

## Compliance

- AG receipt: 6/6
- META-RULE 2026-05-11: 27th application; 2nd MOOT-BY-CURRENT-PROBE-CLEARANCE
- L52: 0 new beads filed; `no_bead_reason=hypothesis_refuted_current_probe_clears_doctrine_doc_already_cites`
- Boundary preservation: 0 edits
- L107: 0 reservations (no edits)
- compliance_score: 1000/1000

## Heterogeneous-disposition pattern within parent

flywheel-2xdi parent's child arc this session has produced multiple
disposition classes, confirming META-RULE 2026-05-11 discipline (each bead
probed independently):

| Disposition | Count |
|---|---|
| SKILL.md citation (research-triad pattern) | 3 (2xdi.104/.105/.119) |
| Substrate-registry allowlist (6-bead arc) | 6 (2xdi.60.1/.72.1/.132/.135/.137/.144) |
| 1:1 forward-link doctrine doc | 7 (2xdi.93/.109/.110/.116/.118/.128/.141) |
| CLUSTER-ANCHOR doctrine doc | 1 (2xdi.125) |
| NOT-YET-PROMOTED doctrine doc | 2 (2xdi.117/.129) |
| **MOOT-BY-CURRENT-PROBE-CLEARANCE** | **2** (2xdi.114/.145 this) |
| FULL REFUTATION (MOOT-BY-PARALLEL-FIX) | 3 (MistyCliff's 2xdi.108/etc) |

23+ beads closed across 7 distinct dispositions. The substrate-self-improving
loop continues to function across all disposition classes.
