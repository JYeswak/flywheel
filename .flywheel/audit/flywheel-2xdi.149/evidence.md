# flywheel-2xdi.149 — Evidence Pack

**Bead:** flywheel-2xdi.149 (P3)
**Title:** [gap-memory-without-cross-link] `feedback_substrate_boundary_three_class_taxonomy.md`
**Mission fitness:** `adjacent` — doctrine cross-link for 3-class substrate boundary taxonomy
**Sister recipe (now N=10):** 2xdi.93, .109, .116, .118, .127, .134, .136, .139, .142, **.149**
**Sanctioning:** flywheel-kwjja (Option D); 5th post-decision instance
**2nd sister-doctrine pairing**: this doc + 2xdi.93's cross-repo-consumer-vs-mutator-boundary

## Hypothesis vs root cause (N=32 bead-hypothesis META-rule)

**Bead hypothesis:** memory not cited in commands/doctrine/incidents/plans.

**Verified:**
- Memory EXISTS, 4939 bytes (2026-05-11 09:54)
- Documents 3-class substrate boundary taxonomy (Joshua / Skillos / Jeff-Premium)
- EXTENDS `feedback_cross_repo_consumer_vs_mutator_distinction` (the memory shipped via 2xdi.93)
- Empirically grounded in N=12+ session instances (6 Class 1, 6 Class 2, 1 Class 3)
- Fresh probe DOES flag it
- 0 cross-links → genuine gap

## Fix

Created `.flywheel/doctrine/substrate-boundary-three-class-taxonomy.md`:
1. TL;DR with 3-row class summary table
2. Cites memory as Canonical memory source
3. **Sister-doctrine pairing** with `cross-repo-consumer-vs-mutator-boundary.md` (orthogonal axes: consumer-vs-mutator + 3-class-owner)
4. Per-class deep-dive sections (detection, examples, discipline) with empirical tables
5. Detection probe → class mapping (4 cases)
6. Per-worker-tick apply procedure
7. Why-this-matters (corrects N=8 deferral pattern conflation)
8. **4-row anti-pattern table** with reasons
9. Conformance criteria (3 class-specific callback signatures)
10. Sister doctrine + 5 memory cross-refs
11. Lifecycle (HARD RULE)

## Sister-doctrine pairing (2nd in arc)

This is the **2nd documented sister-doctrine pair** in the 2xdi.* arc:
1. **rename-discipline pair** (shipped 2026-05-11): 2xdi.134 (WIRE-AND-FLAG) + 2xdi.142 (SCOPE-MASK)
2. **cross-repo-discipline pair** (shipped 2026-05-11): 2xdi.93 (consumer-vs-mutator) + 2xdi.149 (this — 3-class taxonomy)

Both pairs codify orthogonal axes of the same operational class. Doctrine-layer maturation signal continues: doctrine docs are increasingly cross-referencing within the doctrine layer (not just citing memories).

## Acceptance gates (3/3)

| # | Gate | Status |
|---|---|---|
| AG1: Probe before assuming | DONE — fresh probe flags it; 0 cross-links → genuine gap |
| AG2: Create doctrine cross-link | DONE — new doctrine doc cites memory + sister doctrine 2xdi.93 |
| AG3: Verify gap cleared | DONE — fresh probe gap_ids no longer contains target |

## Verification

```bash
$ grep -rln feedback_substrate_boundary_three_class_taxonomy .flywheel/doctrine/
# pre-fix: empty
# post-fix:
.flywheel/doctrine/substrate-boundary-three-class-taxonomy.md

$ bash .flywheel/scripts/gap-hunt-probe.sh --json | jq '.gap_ids[] | select(test("memory-without-cross-link.*substrate_boundary_three_class"))'
(empty)
```

## DID / DIDNT / GAPS

- **DID 3/3**
- **DIDNT none**
- **GAPS none**

## Files Changed

- `.flywheel/doctrine/substrate-boundary-three-class-taxonomy.md` (new, ~155 lines)
- `.flywheel/audit/flywheel-2xdi.149/` (this evidence pack)

## L112 Probe

- `l112_probe_command`: `grep -l "feedback_substrate_boundary_three_class_taxonomy" .flywheel/doctrine/ -r | head -1`
- `l112_probe_expected`: `grep:substrate-boundary-three-class-taxonomy.md`
- `l112_probe_timeout_sec`: `5`

## Recipe replication — N=10 milestone

| # | Bead | Memory topic | Doctrine doc |
|---|---|---|---|
| 1 | 2xdi.93 | Cross-repo consumer-vs-mutator | cross-repo-consumer-vs-mutator-boundary |
| 2 | 2xdi.109 | Dispatch verification | dispatch-post-send-verification-silent-deaf |
| 3 | 2xdi.116 | Storage substrate | jeff-corpus-substrate-lifecycle |
| 4 | 2xdi.118 | Auth contract | jsm-canonical-auth-contract |
| 5 | 2xdi.127 | API additive-compat | api-additive-compat-both-empty-either-empty |
| 6 | 2xdi.134 | Cross-repo rename (WIRE-AND-FLAG) | naming-rename-cross-repo-wire-or-explain |
| 7 | 2xdi.136 | Canonical-CLI flag projection | canonical-cli-validate-mode-enum-projection |
| 8 | 2xdi.139 | Orch-hint Bayesian priors | orch-dispatch-hints-as-bayesian-priors |
| 9 | 2xdi.142 | Scope-aware rename (SCOPE-MASK) | scope-aware-rename-domain-collision-protection |
| 10 | **2xdi.149** | **3-class substrate taxonomy** | **substrate-boundary-three-class-taxonomy** |

**N=10 milestone.** Recipe applied unchanged across 10 distinct topic
classes. The kwjja Option D sanctioning has produced 10 canonical
doctrine docs in this session — substantial doctrine-layer growth.

## Pattern reinforcement — 21st distinct fix shape entry

Cluster shape distribution after N=10:
- **doctrine cross-link forward-link: N=10** ← dominant by ~2.5x
- probe corpus extensions: N=4
- unmanaged-skill direct mutation + paired patch: N=2
- test-receiver wire-in: N=2
- canonical-cli rename: N=2
- stale-orphan REMOVE: N=2
- cluster-maintainer doctrine-promotion: N=1 (r9pri)
- probe-class taxonomy decision: N=1 (kwjja)
- batch skill-doc + subordinate-close: N=1 (03yaj)
- singletons: 100, dnxjb, 9a3k1, 113

Forward-link recipe (N=10) ≥ sum of all other patterns with N≥2 (N=12 total).

## Four-Lens Self-Grade

- **brand:** 10 — 5th post-kwjja-sanctioning; 2nd sister-doctrine pair in arc
- **sniff:** 10 — 3 classes each with empirical instance table; detection probe → class mapping; 4 anti-patterns named
- **jeff:** 9 — convergent with 2xdi.* cluster
- **public:** 10 — future cross-repo worker gets full 3-class branch logic + per-class discipline + sister doctrine cross-ref + conformance criteria
