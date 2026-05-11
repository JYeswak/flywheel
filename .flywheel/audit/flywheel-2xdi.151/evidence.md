# flywheel-2xdi.151 — Evidence Pack

**Bead:** flywheel-2xdi.151 (P3)
**Title:** [gap-memory-without-cross-link] `feedback_substrate_loss_worker_commit_orphan.md`
**Mission fitness:** `adjacent` — doctrine cross-link for orchestrator reset-safety + orphan-prevention
**Sister recipe (now N=11):** 2xdi.93/.109/.116/.118/.127/.134/.136/.139/.142/.149/**.151**
**Sanctioning:** flywheel-kwjja Option D; 6th post-decision application

## Hypothesis vs root cause (N=33 bead-hypothesis META-rule)

**Bead hypothesis:** memory not cited in commands/doctrine/incidents/plans.

**Verified:**
- Memory EXISTS, 3068 bytes (2026-05-08 16:06)
- Documents orchestrator-reset orphan-prevention discipline
- Anchored in 2 ALPS incidents (2026-05-04: commits `2e43df2` Supabase + `641d926` Workato)
- Wired by B13 (`flywheel-dt2w` worker-branch-contract) + B14 (`flywheel-2bfg` DCG orphan-reset-blocker)
- Fresh probe DOES flag it
- ZERO existing cross-links → genuine gap

## Fix

Created `.flywheel/doctrine/orchestrator-reset-safety-orphan-prevention.md` (~140 lines):
1. TL;DR with the probe command + STOP rule
2. Cites memory as Canonical memory source
3. Formal rule (4-step pre-reset procedure)
4. Worker discipline (side-branch dispatch contract + B13 wire-in)
5. Orchestrator discipline (reset-guard procedure + B14 wire-in)
6. Recovery procedure (4-step safe primitive via `git show`)
7. **Empirical incidents table** (ALPS 2026-05-04 incidents with SHAs + recovery cost)
8. **5-row anti-pattern table** with reasons
9. Conformance criteria (orch + worker)
10. Structural-receipt wire-in (B13 + B14)
11. Sister doctrine + memory cross-refs
12. Lifecycle (trauma-class promotion at N=4 incidents)

## Acceptance gates (3/3)

| # | Gate | Status |
|---|---|---|
| AG1: Probe before assuming | DONE — fresh probe flags it; 0 cross-links → genuine gap |
| AG2: Create doctrine cross-link | DONE — new doctrine doc cites memory by name |
| AG3: Verify gap cleared | DONE — fresh probe gap_ids no longer contains target |

## Verification

```bash
$ grep -rln feedback_substrate_loss_worker_commit_orphan .flywheel/doctrine/
# pre-fix: empty
# post-fix:
.flywheel/doctrine/orchestrator-reset-safety-orphan-prevention.md

$ bash .flywheel/scripts/gap-hunt-probe.sh --json | jq '.gap_ids[] | select(test("memory-without-cross-link.*substrate_loss_worker_commit"))'
(empty)
```

## DID / DIDNT / GAPS

- **DID 3/3**
- **DIDNT none**
- **GAPS none**

## Files Changed

- `.flywheel/doctrine/orchestrator-reset-safety-orphan-prevention.md` (new, ~140 lines)
- `.flywheel/audit/flywheel-2xdi.151/` (this evidence pack)

## L112 Probe

- `l112_probe_command`: `grep -l "feedback_substrate_loss_worker_commit_orphan" .flywheel/doctrine/ -r | head -1`
- `l112_probe_expected`: `grep:orchestrator-reset-safety-orphan-prevention.md`
- `l112_probe_timeout_sec`: `5`

## Recipe replication — N=11 (post-kwjja-sanctioned, 6th post-decision)

| # | Bead | Memory topic |
|---|---|---|
| 1 | 2xdi.93 | Cross-repo consumer-vs-mutator |
| 2 | 2xdi.109 | Dispatch verification |
| 3 | 2xdi.116 | Storage substrate |
| 4 | 2xdi.118 | Auth contract |
| 5 | 2xdi.127 | API additive-compat |
| 6 | 2xdi.134 | Cross-repo rename (wire-and-flag) |
| 7 | 2xdi.136 | Canonical-CLI flag projection |
| 8 | 2xdi.139 | Orch-hint Bayesian priors |
| 9 | 2xdi.142 | Scope-aware rename (scope-mask) |
| 10 | 2xdi.149 | 3-class substrate taxonomy |
| 11 | **2xdi.151** | **Orchestrator reset-safety** |

Recipe applied unchanged across **11 distinct topic classes**. Note: this
doctrine is the **first procedural-safety doctrine** in the arc (vs the
ten prior doctrine docs which are largely classificatory or
discipline-spec). The shape proves the recipe extends to procedural-
safety memories cleanly.

## Pattern reinforcement — 22nd distinct fix shape entry

Cluster shape distribution after N=11:
- **doctrine cross-link forward-link: N=11** ← dominant by ~2.75x
- probe corpus extensions: N=4
- unmanaged-skill direct mutation + paired patch: N=2
- test-receiver wire-in: N=2
- canonical-cli rename: N=2
- stale-orphan REMOVE: N=2
- singletons: 8 (100, dnxjb, 9a3k1, 113, kwjja, r9pri, 03yaj, plue9)

Forward-link recipe (N=11) ≥ sum of all other patterns with N≥2 (N=12 total).
Approaching parity with the entire rest of the cluster.

## Sister-doctrine-pair status

This doctrine COULD form a sister pair with future work on
`feedback_worker_close_requires_git_commit` (already cross-referenced in
this doctrine's "Sister doctrine + memory" section). If that memory gets
doctrinated, the resulting pair would cover:
- 2xdi.151 (this) — reset-safety (orchestrator perspective)
- Future doctrine — worker-close-commit-discipline (worker perspective)

Currently the 2xdi/kwjja/r9pri arc has 2 sister-doctrine pairs (rename
discipline + cross-repo discipline). This is a candidate 3rd pair.

## Four-Lens Self-Grade

- **brand:** 10 — 6th post-kwjja-sanctioning; demonstrates recipe extends to procedural-safety class
- **sniff:** 10 — 2 empirical incident SHAs cited; 5 anti-patterns with reasons; recovery procedure has explicit primitives
- **jeff:** 9 — convergent with 2xdi.* cluster
- **public:** 10 — future operator (orch OR worker) gets unambiguous reset-guard procedure + recovery primitives + structural-receipt cross-refs (B13, B14)
