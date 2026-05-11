# flywheel-2xdi.118 — Evidence Pack

**Bead:** flywheel-2xdi.118 (P3)
**Title:** [gap-memory-without-cross-link] `feedback_jsm_canonical_auth_contract_use_skillos_process.md`
**Mission fitness:** `adjacent` — doctrine cross-link for the JSM auth contract makes the discipline grep-discoverable
**Sister recipe (now N=4):** 2xdi.93, 2xdi.109, 2xdi.116, **2xdi.118**

## Hypothesis vs root cause (N=23 bead-hypothesis META-rule)

**Bead hypothesis:** memory not cited in commands/doctrine/incidents/plans.

**Verified:**
- Memory EXISTS, 3260 bytes (Joshua 2026-05-08T~23:30Z directive)
- Documents JSM auth contract (4 invariants + canonical setup recipe + anti-pattern + recovery procedure)
- Fresh probe DOES flag it (NOT resolved-upstream)
- ZERO existing cross-links in `.flywheel/doctrine/`, `INCIDENTS.md`, `AGENTS.md`, or `~/.claude/commands/flywheel/`

Genuine memory-without-cross-link gap. Memory is operationally critical (workers call `jsm list`/`jsm show` regularly for JSM-managed-skill discipline; bad auth state stalls worker-tick).

## Fix

Created `.flywheel/doctrine/jsm-canonical-auth-contract.md` — doctrine doc that:
1. Summarizes the 2-layer contract (jsm itself + skillos guarded runner) at canonical-doctrine quality
2. **Cites the memory as "Canonical memory source"** + the skillos-owned canonical contract at `/Users/josh/Developer/skillos/docs/jsm-auth-contract.md`
3. Documents the 4 invariants with checks
4. Documents anti-pattern (`NEVER manually jsm login without JSM_DISABLE_KEYRING=1`)
5. Documents recovery procedure (3 steps: process context / keychain coexistence / skillos doctor)
6. Documents canonical setup recipe (5-line idempotent block)
7. Cross-refs sister doctrine (cross-repo-consumer-vs-mutator-boundary) + skillos canonical paths
8. Conformance + lifecycle sections

## Acceptance gates (3/3)

| # | Gate | Status |
|---|---|---|
| AG1: Probe before assuming | DONE — fresh probe flags it; 0 existing cross-links → genuine gap |
| AG2: Create doctrine cross-link | DONE — new doctrine doc cites memory + skillos contract by name |
| AG3: Verify gap cleared | DONE — fresh probe gap_ids no longer contains target |

## Verification

```bash
$ ls feedback_jsm_canonical_auth_contract_use_skillos_process.md
-rw-r--r-- 3260 May 8 20:29

$ grep -rln feedback_jsm_canonical_auth_contract_use_skillos_process .flywheel/doctrine/ INCIDENTS.md AGENTS.md ~/.claude/commands/flywheel/
# pre-fix: empty
# post-fix:
.flywheel/doctrine/jsm-canonical-auth-contract.md

$ bash .flywheel/scripts/gap-hunt-probe.sh --json | jq '.gap_ids[] | select(test("memory-without-cross-link.*jsm_canonical_auth"))'
(empty)
```

## DID / DIDNT / GAPS

- **DID 3/3** — gap identified, doctrine doc created, gap cleared
- **DIDNT none**
- **GAPS none**

## Files Changed

- `.flywheel/doctrine/jsm-canonical-auth-contract.md` (new, doctrine canonical, ~125 lines)
- `.flywheel/audit/flywheel-2xdi.118/` (this evidence pack)

No mutation of the memory file itself (consistent with 2xdi.93/.109/.116 pattern).

## L112 Probe

- `l112_probe_command`: `grep -l "feedback_jsm_canonical_auth_contract_use_skillos_process" .flywheel/doctrine/ -r | head -1`
- `l112_probe_expected`: `grep:jsm-canonical-auth-contract.md`
- `l112_probe_timeout_sec`: `5`

## Recipe replication — N=4 → SKILL PROMOTION DUE

The "forward-link doctrine doc" recipe has now shipped **4 times** this session:

1. **2xdi.93** — feedback_cross_repo_consumer_vs_mutator_distinction.md → cross-repo-consumer-vs-mutator-boundary.md
2. **2xdi.109** — feedback_dispatch_post_send_verify_for_silent_deaf.md → dispatch-post-send-verification-silent-deaf.md
3. **2xdi.116** — feedback_jeff_corpus_indexed_data_separates_from_source.md → jeff-corpus-substrate-lifecycle.md
4. **2xdi.118** — feedback_jsm_canonical_auth_contract_use_skillos_process.md → jsm-canonical-auth-contract.md

N=4 instances. The N=3 promotion candidate was filed at 2xdi.116; this 4th instance reinforces. Filed:
`pattern-emerged-forward-link-doctrine-doc-recipe-for-memory-without-cross-link-N4-confirmed`.

Recipe is now demonstrably stable across 4 distinct memory topics:
- Cross-repo discipline
- Dispatch verification
- Storage substrate lifecycle
- Auth contract (this one)

The 5-step canonical procedure (documented in 2xdi.116 evidence) holds without modification. Ready for skill extraction.

## Pattern reinforcement

**14th distinct fix shape entry, 4th instance of "doctrine cross-link":**
- 47/49/64/66 = probe corpus extensions (4 instances)
- **93/109/116/118 = doctrine cross-link forward-link (N=4) ← most-replicated**
- 90/92 = test-receiver wire-in
- 100 = INCIDENTS citation
- 101/102 = canonical-cli rename
- dnxjb = probe-finder path filter
- 9a3k1 = auto-bead-filer dedup
- 105/99 = unmanaged-skill direct mutation + paired patch
- 113 = resolve-upstream-no-mutation

## Four-Lens Self-Grade

- **brand:** 10 — N=4 instance reinforces the promoted skill discovery; faithful sister-pattern
- **sniff:** 10 — probed BEFORE mutation; confirmed genuine gap; recipe is now empirically stable across 4 memory topics
- **jeff:** 9 — convergent with 2xdi.* cluster
- **public:** 10 — future operator gets the canonical 4-invariant table + anti-pattern + recovery + setup recipe in one doctrine doc
