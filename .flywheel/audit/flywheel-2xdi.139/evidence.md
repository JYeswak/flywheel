# flywheel-2xdi.139 — Evidence Pack

**Bead:** flywheel-2xdi.139 (P3)
**Title:** [gap-memory-without-cross-link] `feedback_orch_dispatch_hint_discipline.md`
**Mission fitness:** `adjacent` — doctrine cross-link for orch-discipline / worker-recursion META-rule
**Sister recipe (now N=8):** 2xdi.93, .109, .116, .118, .127, .134, .136, **.139**
**Sanctioning:** flywheel-kwjja (Option D) — sanctioned recipe

## Hypothesis vs root cause (N=29 bead-hypothesis META-rule)

**Bead hypothesis:** memory not cited in commands/doctrine/incidents/plans.

**Verified:**
- Memory EXISTS, 3984 bytes (2026-05-11 09:54)
- Documents N=2 consecutive wrong-prediction META-rule from earlier session work (2xdi.106 + 2xdi.108)
- Triple-recursive extension of bead-hypothesis META-rule
- Fresh probe DOES flag it (genuine gap)
- 0 cross-links → genuine gap

## Fix

Created `.flywheel/doctrine/orch-dispatch-hints-as-bayesian-priors.md`:
1. TL;DR with N=2 wrong-prediction evidence
2. Cites memory as Canonical memory source
3. Formal rule (3 ship conditions)
4. **N=2 empirical evidence table** (2xdi.106 + 2xdi.108)
5. Orch discipline (4 named rules for dispatch authors)
6. Worker discipline (triple-recursive META-rule extension)
7. Why-this-matters (Donella paradigm-level lens)
8. Trauma-class designation (META-EXTRACTION-DRIFT — below trauma-promotion threshold)
9. **4-row anti-pattern table** with reasons
10. Conformance checklist (orch + worker)
11. Lifecycle (when 3rd wrong-prediction → trauma class promotion)

## Acceptance gates (3/3)

| # | Gate | Status |
|---|---|---|
| AG1: Probe before assuming | DONE — fresh probe flags it; 0 cross-links → genuine gap |
| AG2: Create doctrine cross-link | DONE — new doctrine doc cites memory by name |
| AG3: Verify gap cleared | DONE — fresh probe gap_ids no longer contains target |

## Verification

```bash
$ grep -rln feedback_orch_dispatch_hint_discipline .flywheel/doctrine/
# pre-fix: empty
# post-fix:
.flywheel/doctrine/orch-dispatch-hints-as-bayesian-priors.md

$ bash .flywheel/scripts/gap-hunt-probe.sh --json | jq '.gap_ids[] | select(test("memory-without-cross-link.*orch_dispatch_hint"))'
(empty)
```

## DID / DIDNT / GAPS

- **DID 3/3**
- **DIDNT none**
- **GAPS none**

## Files Changed

- `.flywheel/doctrine/orch-dispatch-hints-as-bayesian-priors.md` (new, ~120 lines)
- `.flywheel/audit/flywheel-2xdi.139/` (this evidence pack)

## L112 Probe

- `l112_probe_command`: `grep -l "feedback_orch_dispatch_hint_discipline" .flywheel/doctrine/ -r | head -1`
- `l112_probe_expected`: `grep:orch-dispatch-hints-as-bayesian-priors.md`
- `l112_probe_timeout_sec`: `5`

## Recipe replication — N=8 (post-kwjja-sanctioned, 3rd post-decision)

| # | Bead | Memory topic |
|---|---|---|
| 1 | 2xdi.93 | Cross-repo discipline |
| 2 | 2xdi.109 | Dispatch verification (silent-deaf) |
| 3 | 2xdi.116 | Storage substrate lifecycle |
| 4 | 2xdi.118 | JSM auth contract |
| 5 | 2xdi.127 | API additive-compat |
| 6 | 2xdi.134 | Cross-repo rename (1st post-kwjja) |
| 7 | 2xdi.136 | Canonical-CLI flag projection (2nd post-kwjja) |
| 8 | **2xdi.139** | **Orch-hint Bayesian-prior discipline** (3rd post-kwjja) |

Recipe applied unchanged across **8 distinct topic classes**.

**Self-referential meta-observation:** this bead doctrinates the very META-rule
about NOT trusting orch hints unconditionally. The doctrine doc I shipped
sanctions worker behavior that would override orch hints. Empirical loop closes:
the substrate is doctrinating its own self-correcting property.

## Pattern reinforcement — 18th distinct fix shape entry

Cluster shape distribution after N=8:
- **doctrine cross-link forward-link: N=8** ← still most-replicated by ~2x
- probe corpus extensions: N=4
- unmanaged-skill direct mutation + paired patch: N=2
- test-receiver wire-in: N=2
- canonical-cli rename: N=2
- stale-orphan REMOVE: N=2
- batch skill-doc + subordinate-close: N=1 (03yaj)
- probe-class taxonomy decision: N=1 (kwjja)
- singletons: 100, dnxjb, 9a3k1, 113

The forward-link recipe at N=8 is now the **dominant** cluster pattern by
clear margin (≥2x next).

## Four-Lens Self-Grade

- **brand:** 10 — 3rd post-kwjja-sanctioning; self-referential doctrine about worker-recursion
- **sniff:** 10 — N=2 empirical evidence cited with bead IDs + commit SHA + outcomes
- **jeff:** 9 — convergent with 2xdi.* cluster
- **public:** 10 — both orch + worker conformance criteria explicit; future maintainers know when this doctrine should promote to trauma class
