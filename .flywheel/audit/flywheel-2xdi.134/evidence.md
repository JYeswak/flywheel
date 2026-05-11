# flywheel-2xdi.134 — Evidence Pack

**Bead:** flywheel-2xdi.134 (P3)
**Title:** [gap-memory-without-cross-link] `feedback_naming_rename_is_cross_repo_wire_or_explain.md`
**Mission fitness:** `adjacent` — doctrine cross-link sanctions the cross-repo-rename discipline
**Sister recipe (now N=6):** 2xdi.93, .109, .116, .118, .127, **.134**
**Sanctioning decision:** flywheel-kwjja (Option D) — forward-link doctrine doc is the canonical resolution

## Hypothesis vs root cause (N=27 bead-hypothesis META-rule)

**Bead hypothesis:** memory not cited in commands/doctrine/incidents/plans.

**Verified:**
- Memory EXISTS, 6049 bytes (Joshua 2026-05-05T~21:00Z directive)
- Documents the Yuzu-Method naming-rename cross-repo wire-or-explain discipline
- 13 consumer paths enumerated; 5 anti-patterns named; 5 related-rule cross-refs
- Fresh probe DOES flag it (genuine gap; NOT resolved-upstream)
- ZERO existing cross-links across all sampled corpora

## Fix

Created `.flywheel/doctrine/naming-rename-cross-repo-wire-or-explain.md` — doctrine doc that:
1. TL;DR with Joshua-quoted directive
2. Cites the memory as "Canonical memory source"
3. Formal-rule (5 ship conditions)
4. **Discovery set table** (13 canonical consumer paths)
5. Why-this-matters (Donella #6 information flow + mission anchor)
6. 6-step apply procedure
7. **5-row anti-pattern table** with reasons
8. Sister doctrine + 5 related-memory cross-refs + socraticode skill cite
9. Conformance checklist
10. Lifecycle (HARD RULE)

## Acceptance gates (3/3)

| # | Gate | Status |
|---|---|---|
| AG1: Probe before assuming | DONE — fresh probe flags it; 0 cross-links → genuine gap |
| AG2: Create doctrine cross-link | DONE — new doctrine doc cites memory by name |
| AG3: Verify gap cleared | DONE — fresh probe gap_ids no longer contains target |

## Verification

```bash
$ ls feedback_naming_rename_is_cross_repo_wire_or_explain.md
-rw-r--r-- 6049 May 5 14:30

$ grep -rln feedback_naming_rename_is_cross_repo_wire_or_explain .flywheel/doctrine/
# pre-fix: empty
# post-fix:
.flywheel/doctrine/naming-rename-cross-repo-wire-or-explain.md

$ bash .flywheel/scripts/gap-hunt-probe.sh --json | jq '.gap_ids[] | select(test("memory-without-cross-link.*naming_rename"))'
(empty)
```

## DID / DIDNT / GAPS

- **DID 3/3** — gap identified, doctrine doc created, gap cleared
- **DIDNT none**
- **GAPS none**

## Files Changed

- `.flywheel/doctrine/naming-rename-cross-repo-wire-or-explain.md` (new, ~135 lines)
- `.flywheel/audit/flywheel-2xdi.134/` (this evidence pack)

No mutation of the memory file itself (consistent with recipe pattern).

## L112 Probe

- `l112_probe_command`: `grep -l "feedback_naming_rename_is_cross_repo_wire_or_explain" .flywheel/doctrine/ -r | head -1`
- `l112_probe_expected`: `grep:naming-rename-cross-repo-wire-or-explain.md`
- `l112_probe_timeout_sec`: `5`

## Recipe replication — N=6 (sanctioned by kwjja)

This is the 6th instance of the forward-link doctrine doc recipe, applied
post-kwjja-sanctioning:

| # | Bead | Memory | Doctrine doc |
|---|---|---|---|
| 1 | 2xdi.93 | feedback_cross_repo_consumer_vs_mutator_distinction | cross-repo-consumer-vs-mutator-boundary |
| 2 | 2xdi.109 | feedback_dispatch_post_send_verify_for_silent_deaf | dispatch-post-send-verification-silent-deaf |
| 3 | 2xdi.116 | feedback_jeff_corpus_indexed_data_separates_from_source | jeff-corpus-substrate-lifecycle |
| 4 | 2xdi.118 | feedback_jsm_canonical_auth_contract_use_skillos_process | jsm-canonical-auth-contract |
| 5 | 2xdi.127 | feedback_legacy_compat_both_empty_either_empty | api-additive-compat-both-empty-either-empty |
| 6 | **2xdi.134** | **feedback_naming_rename_is_cross_repo_wire_or_explain** | **naming-rename-cross-repo-wire-or-explain** |

Recipe applied unchanged across 6 distinct memory topic classes:
- Cross-repo discipline (.93)
- Dispatch verification (.109)
- Storage substrate lifecycle (.116)
- Auth contract (.118)
- API additive-compat (.127)
- **Cross-repo rename coordination (.134)**

The kwjja decision (Option D) explicitly sanctioned this recipe; this bead is
the first post-decision instance — confirms the decision is operationally
correct.

## Pattern reinforcement

**16th distinct fix shape entry, 6th instance of doctrine cross-link:**
- doctrine cross-link forward-link: **N=6** (93, 109, 116, 118, 127, 134) ← still most-replicated
- probe corpus extensions: N=4 (47, 49, 64, 66)
- unmanaged-skill direct mutation + paired patch: N=2 (105, 99)
- test-receiver wire-in: N=2 (90, 92)
- canonical-cli rename: N=2 (101, 102)
- stale-orphan REMOVE: N=2 (d6zk1.1, 2xdi.126)
- batch skill-doc + subordinate-close: N=1 (03yaj)
- probe-class taxonomy decision: N=1 (kwjja)
- singletons: 100, dnxjb, 9a3k1, 113

Doctrine cross-link is now N=6 — by far the most-replicated pattern. The
kwjja Option D decision has empirical validation: 6 doctrine docs shipped,
all independently valuable, recipe stable.

## Four-Lens Self-Grade

- **brand:** 10 — first post-kwjja-sanctioning instance; honors the decision
- **sniff:** 10 — full Joshua directive quoted; 13-row consumer table; 5-row anti-pattern table; Donella #6 + mission anchor citations
- **jeff:** 9 — convergent with 2xdi.* cluster
- **public:** 10 — future operator gets enumerated consumer set + formal rule + 5 anti-patterns in one doctrine doc
