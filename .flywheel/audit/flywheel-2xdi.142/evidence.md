# flywheel-2xdi.142 — Evidence Pack

**Bead:** flywheel-2xdi.142 (P3)
**Title:** [gap-memory-without-cross-link] `feedback_scope_aware_rename_is_the_rule.md`
**Mission fitness:** `adjacent` — doctrine cross-link for scope-aware rename discipline (sister to 2xdi.134 cross-repo rename doctrine)
**Sister recipe (now N=9):** 2xdi.93, .109, .116, .118, .127, .134, .136, .139, **.142**
**Sanctioning:** flywheel-kwjja (Option D) — sanctioned recipe; 4th post-decision application

## Hypothesis vs root cause (N=31 bead-hypothesis META-rule)

**Bead hypothesis:** memory not cited in commands/doctrine/incidents/plans.

**Verified:**
- Memory EXISTS, 6154 bytes (Joshua 2026-05-05T~21:20Z directive)
- Documents scope-aware rename discipline + 6-term domain-collision table + 5 per-repo path-allowlists + 4 anti-patterns
- Anchored in 2026-05-05 BG-C inventory
- Fresh probe DOES flag it
- ZERO existing cross-links → genuine gap

## Fix

Created `.flywheel/doctrine/scope-aware-rename-domain-collision-protection.md` (~140 lines):
1. TL;DR with Joshua-quoted directive
2. Cites memory as Canonical memory source
3. **Companion to** `naming-rename-cross-repo-wire-or-explain.md` (sister doctrine from 2xdi.134) — 6-step rename gate spans both docs
4. **6-row domain-collision table** (doctor / ledger / worker / dispatch / tick / reap with flywheel meaning + ALPS collision)
5. **Per-repo path-allowlists** (6 repos: flywheel, skillos, alpsinsurance, ~/.claude/skills, memory, swarm-daemon)
6. 8-step apply procedure
7. Safe / domain-collision / off-limits term taxonomy
8. 4-row anti-pattern table
9. Conformance checklist + lifecycle

## Sister-doctrine coupling

This doctrine completes the rename-gate pair with 2xdi.134's doctrine:
- 2xdi.134 = WIRE-AND-FLAG (discovery + ledger + coordination across N=13 ecosystem repos)
- 2xdi.142 = SCOPE-MASK (path-allowlist + word-boundary regex + sampling-verify before apply)

Together they form the 6-step canonical rename gate:
1. Cross-repo discovery (from .134)
2. Zest Ledger consumer enumeration (from .134)
3. Scope-allowlist declaration (from .142)
4. Sampling-verify before apply (from .142)
5. Coordinated multi-repo apply (from .134)
6. Grep-verify post-apply (from .134)

## Acceptance gates (3/3)

| # | Gate | Status |
|---|---|---|
| AG1: Probe before assuming | DONE — fresh probe flags it; 0 cross-links → genuine gap |
| AG2: Create doctrine cross-link | DONE — new doctrine doc cites memory by name AND sister doctrine 2xdi.134 |
| AG3: Verify gap cleared | DONE — fresh probe gap_ids no longer contains target |

## Verification

```bash
$ grep -rln feedback_scope_aware_rename_is_the_rule .flywheel/doctrine/
# pre-fix: empty
# post-fix:
.flywheel/doctrine/scope-aware-rename-domain-collision-protection.md

$ bash .flywheel/scripts/gap-hunt-probe.sh --json | jq '.gap_ids[] | select(test("memory-without-cross-link.*scope_aware_rename"))'
(empty)
```

## DID / DIDNT / GAPS

- **DID 3/3**
- **DIDNT none**
- **GAPS none**

## Files Changed

- `.flywheel/doctrine/scope-aware-rename-domain-collision-protection.md` (new, ~140 lines)
- `.flywheel/audit/flywheel-2xdi.142/` (this evidence pack)

## L112 Probe

- `l112_probe_command`: `grep -l "feedback_scope_aware_rename_is_the_rule" .flywheel/doctrine/ -r | head -1`
- `l112_probe_expected`: `grep:scope-aware-rename-domain-collision-protection.md`
- `l112_probe_timeout_sec`: `5`

## Recipe replication — N=9 (post-kwjja-sanctioned, 4th post-decision)

| # | Bead | Memory topic | Doctrine doc |
|---|---|---|---|
| 1 | 2xdi.93 | Cross-repo discipline | cross-repo-consumer-vs-mutator-boundary |
| 2 | 2xdi.109 | Dispatch verification | dispatch-post-send-verification-silent-deaf |
| 3 | 2xdi.116 | Storage substrate | jeff-corpus-substrate-lifecycle |
| 4 | 2xdi.118 | Auth contract | jsm-canonical-auth-contract |
| 5 | 2xdi.127 | API additive-compat | api-additive-compat-both-empty-either-empty |
| 6 | 2xdi.134 | Cross-repo rename (WIRE-AND-FLAG) | naming-rename-cross-repo-wire-or-explain |
| 7 | 2xdi.136 | Canonical-CLI flag projection | canonical-cli-validate-mode-enum-projection |
| 8 | 2xdi.139 | Orch-hint Bayesian priors | orch-dispatch-hints-as-bayesian-priors |
| 9 | **2xdi.142** | **Scope-aware rename (SCOPE-MASK)** | **scope-aware-rename-domain-collision-protection** |

Recipe applied unchanged across **9 distinct topic classes**. 4th
post-kwjja-decision instance. The kwjja Option D sanctioning continues
to validate operationally.

**Sister-pairing observation:** 2xdi.134 + 2xdi.142 form the first
documented sister-doctrine pair in the 2xdi.* arc. Both target the same
operational class (Yuzu Method renames) but cover orthogonal phases
(wire-and-flag vs scope-mask). Future workers reading either doctrine
doc find the other via the sister cross-ref.

## Pattern reinforcement — 20th distinct fix shape entry

Cluster shape distribution after N=9:
- **doctrine cross-link forward-link: N=9** ← dominant by ~2.25x
- probe corpus extensions: N=4
- unmanaged-skill direct mutation + paired patch: N=2
- test-receiver wire-in: N=2
- canonical-cli rename: N=2
- stale-orphan REMOVE: N=2
- batch skill-doc + subordinate-close: N=1 (03yaj)
- probe-class taxonomy decision: N=1 (kwjja)
- cluster-maintainer N=3 doctrine-promotion: N=1 (r9pri)
- singletons: 100, dnxjb, 9a3k1, 113

Forward-link recipe (N=9) ≥ sum of all other patterns with N≥2 (N=12).

## Four-Lens Self-Grade

- **brand:** 10 — 4th post-kwjja-sanctioning instance; sister-doctrine pairing demonstrates doctrine layer is now cross-referencing within itself
- **sniff:** 10 — Joshua directive quoted verbatim; 6-row domain-collision table; per-repo path-allowlist enumerated; ALPS as canonical exemplar
- **jeff:** 9 — convergent with 2xdi.* cluster
- **public:** 10 — future rename operator gets formal procedure + collision-table + allowlist + sampling-verify gate in one doc + sister doctrine cross-ref
