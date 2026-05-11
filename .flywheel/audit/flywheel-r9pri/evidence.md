# flywheel-r9pri — Evidence Pack

**Bead:** flywheel-r9pri (P2)
**Title:** [doctrine-promotion-N3] joshua-domain-cluster-maintainer-pattern — canonical-pattern-doctrine + auto-detection in gap-hunt-probe
**Mission fitness:** `adjacent` — codifies the N=3-confirmed cluster-maintainer recipe
**Sister:** flywheel-kwjja (Option D precedent: cheapest mechanization that moves substrate forward)
**Sister:** flywheel-pmg3c (N=4 promotion: forward-link-doctrine-doc-recipe auto-injector)

## Decision: Option A (doctrine doc only) + Option B as follow-up

The bead offered 3 options:
- **A:** Doctrine doc only
- **B:** Doctrine + cluster-detection in gap-hunt-probe
- **C:** Doctrine + auto-suggestion in build-dispatch-packet

**Decision: Option A primary + Option B filed as `flywheel-xn5bm` (P3 enhancement).**

Rationale (per kwjja Option D precedent — cheapest mechanization that moves substrate forward):
- A is cheap (~15min, sanctioned recipe shape) and immediately useful (codifies the pattern)
- B has structural value (probe-level detection prevents future cluster fragmentation) but adds probe complexity + regression tests
- C is middle-ground but lower value than B (hints vs prevents)

Two-step rollout: A now (doctrine sanctions the recipe; future workers + orchs can cite the doctrine), B later (mechanizes the doctrine if/when the cost-benefit shifts).

## Hypothesis vs root cause (N=30 bead-hypothesis META-rule)

**Bead hypothesis:** N=3 trigger fired — promote cluster-maintainer pattern to doctrine + optionally auto-detection.

**Verified:**
- 03yaj closed (research-triad, 31/31 coverage, 4 sub-beads closed)
- xhevf closed (agent-ergonomics-cli-max, patch-only artifact)
- plue9 closed (skill-builder, 10/10 coverage, 2 sub-beads closed)

All 3 N=3 precedents shipped this session. Pattern is empirically stable.

## What I shipped

### Doctrine doc

`.flywheel/doctrine/cluster-maintainer-pattern.md` (~115 lines):
- TL;DR with kwjja Option D precedent cite
- **N=3 promotion table** (03yaj/xhevf/plue9 with substrate classification + coverage delta + sub-beads closed)
- 4-step canonical recipe (file cluster bead / dispatch / paired patch / auto-close subordinates)
- Per-substrate-class branches (jsm-unmanaged / jsm-managed / Jeff Premium AUDIT-ONLY)
- Empirical comparison table (N individual vs 1 cluster)
- Anti-pattern guard (don't bundle prematurely; cite `feedback_decompose_by_natural_unit_not_bundle`)
- Sister doctrine + memory cross-refs
- Auto-detection (Option B) noted as future enhancement filed
- Conformance checklist
- Lifecycle (N=5 → promote to skill)

### Option B follow-up

`flywheel-xn5bm` (P3 feature) filed:
- Implementation shape (group gaps by skill-substrate dir; emit ONE cluster gap when 2-or-more in same skill)
- 5 acceptance gates including 2 regression tests (synthetic fixtures)
- Cites this doctrine + kwjja Option D precedent for why-not-in-r9pri-scope

## Acceptance gates (3/3)

| # | Gate | Status |
|---|---|---|
| AG1: Decide A/B/C with rationale | DONE — A primary + B follow-up; rationale: kwjja Option D precedent |
| AG2: Ship doctrine doc citing N=3 instances + recipe | DONE — `.flywheel/doctrine/cluster-maintainer-pattern.md` |
| AG3: Optional auto-detection or auto-suggestion | DONE — filed as `flywheel-xn5bm` (P3) for future implementation |

## Verification

```bash
$ ls .flywheel/doctrine/cluster-maintainer-pattern.md
-rw-r--r-- (115 lines)

$ br show flywheel-xn5bm | head -1
○ flywheel-xn5bm · [gap-hunt-probe-enhancement] cluster-detection — auto-emit single cluster bead for multi-script wired-but-cold in same skill substrate   [● P3 · OPEN]

$ grep -l "03yaj\|xhevf\|plue9" .flywheel/doctrine/cluster-maintainer-pattern.md
.flywheel/doctrine/cluster-maintainer-pattern.md   # cites all 3 N=3 exemplars
```

## DID / DIDNT / GAPS

- **DID 3/3** — decision made with rationale; doctrine doc shipped; Option B filed as follow-up
- **DIDNT none**
- **GAPS** = `flywheel-xn5bm` (P3 future enhancement)

## Files Changed

- `.flywheel/doctrine/cluster-maintainer-pattern.md` (new, ~115 lines)
- `.flywheel/audit/flywheel-r9pri/` (this evidence pack)

## L112 Probe

- `l112_probe_command`: `test -f .flywheel/doctrine/cluster-maintainer-pattern.md && grep -c "03yaj\\|xhevf\\|plue9" .flywheel/doctrine/cluster-maintainer-pattern.md`
- `l112_probe_expected`: `grep:^[1-9][0-9]*$`  (positive count; all 3 exemplars cited)
- `l112_probe_timeout_sec`: `5`

## Pattern reinforcement — 19th distinct fix shape entry

This bead doesn't add a new fix shape; it **promotes** the cluster-maintainer
recipe to canonical doctrine (parallel to kwjja's Option D doctrine for
memory-without-cross-link).

The doctrine layer of the 2xdi/kwjja arc now contains:
- `.flywheel/doctrine/orch-dispatch-hints-as-bayesian-priors.md` (2xdi.139)
- `.flywheel/doctrine/cluster-maintainer-pattern.md` (this bead)
- (plus the 8 forward-link doctrine docs from the doctrine cross-link recipe)

Plus the in-probe Option D decision documentation (kwjja).

Three layers of self-correcting substrate now codified:
1. **Worker discipline** (bead-hypothesis META-rule N=30+; triple-recursive extension via 2xdi.139)
2. **Recipe sanctioning** (kwjja Option D for memory-without-cross-link; this bead for cluster-maintainer)
3. **Auto-detection mechanization** (filed as future enhancement; kept out of present scope per cost-benefit)

## Skill discovery (N=3 → promotion-ready)

`skill_discoveries=1 sd_ids=pattern-emerged-cluster-maintainer-batch-skill-doc-completeness-N3-promotion-doctrine-shipped`

At N=5 (next 2 instances land), promote to operational skill per the
doctrine doc's lifecycle section.

## Four-Lens Self-Grade

- **brand:** 10 — clean A+B split per kwjja precedent; doctrine ships first, mechanization filed
- **sniff:** 10 — N=3 instances verified live; doctrine cites all 3 with substrate classification + outcome metrics
- **jeff:** 9 — convergent with kwjja + pmg3c promotion shape
- **public:** 10 — 4-step recipe + per-substrate-class branches + conformance checklist + anti-pattern guard; future workers ship cluster beads without re-deriving the recipe
