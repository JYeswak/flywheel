# flywheel-2xdi.150 — Evidence Pack

**Bead:** flywheel-2xdi.150 (P3)
**Title:** [gap-wired-but-cold] `.flywheel/scripts/fs-rag-sibling-rollout.sh`
**Mission fitness:** `adjacent` — recipe-extension: test-receiver wire-in for **mutation tool** (not probe)
**Sister recipe:** flywheel-2xdi.90 / .92 / .146 / .147 (probe-class N=4); **this is the first mutation-tool extension**

## Hypothesis vs root cause (N=36 bead-hypothesis META-rule)

**Bead hypothesis:** script not referenced by flywheel ledgers in 30d.

**Verified:**
- Script EXISTS, 6333 bytes, mtime 2026-05-11 00:54
- Different shape than prior 4 instances of test-receiver wire-in:
  - **NOT a probe** (no `-probe.sh` suffix, no canonical-cli triad)
  - Is a **mutation tool** (`--apply` + `--idempotency-key` + `--dry-run` default)
  - Owns `flywheel-uwqf0` (sibling fs-rag rollout deliverable)
  - Parent bead `flywheel-hi4e6` (Meadows #5 refinement context)
- ZERO active corpus references; all hits are audit-pack docs

## Recipe extension decision

The test-receiver wire-in recipe (N=4 promoted at 2xdi.146) applies the recipe-SHAPE (test file under canonical-cli naming = corpus #5 hit), but the **test ASSERTIONS** must differ:

| Prior recipe (probes) | This bead (mutation tool) |
|---|---|
| Canonical-cli triad (--info/--schema/--doctor/--health) | NOT applicable (mutation tool, not probe) |
| `--json` envelope schema_version | VERSION constant assertion only |
| READ-ONLY anti-pattern (no notification/mutating calls) | NOT applicable (intentional mutator) |
| status field in run output | NOT applicable |
| | **NEW:** `--apply` requires `--idempotency-key` (mutation discipline) |
| | **NEW:** stable exit codes (0/1/64) documented |
| | **NEW:** default `--dry-run` discipline documented |
| | **NEW:** owner-bead + parent-bead + doctrine cross-ref preserved |

The recipe is template-extensible: same naming convention (corpus #5 wire-in) + adapted assertions for non-probe shapes.

## What I shipped

`tests/fs-rag-sibling-rollout-canonical-cli.sh` (112 lines, **12/12 PASS**):

1. syntax
2. VERSION constant (fs-rag-sibling-rollout/v1)
3. --help shows usage
4. `--apply` refused without `--idempotency-key` (mutation discipline)
5. `--apply --idempotency-key` accepted (passes arg-parse)
6. default `--dry-run` discipline documented
7. stable exit codes documented (0 ok / 1 rollout / 64 usage)
8. owner-bead `flywheel-uwqf0` citation preserved
9. parent-bead `flywheel-hi4e6` citation preserved (Meadows #5 context)
10. doctrine cross-ref (`apply-spec.md` AG3) preserved
11. unknown arg rejected (defensive arg parse)
12. `--json` flag accepted (no parse error)

## Acceptance gates (3/3)

| # | Gate | Status |
|---|---|---|
| AG1: Identify gap empirically | DONE — 0 corpus receivers; mutation-tool shape (not probe) |
| AG2: Wire receiver (with recipe extension) | DONE — test file under canonical-cli convention; mutation-discipline assertions |
| AG3: Verify gap cleared | DONE — fresh probe `fs-rag-sibling-rollout` cleared |

## Verification

```bash
$ bash tests/fs-rag-sibling-rollout-canonical-cli.sh
SUMMARY pass=12 fail=0

$ bash .flywheel/scripts/gap-hunt-probe.sh --json | jq '.gap_ids[] | select(test("fs-rag-sibling-rollout"))'
(empty)
```

## DID / DIDNT / GAPS

- **DID 3/3**
- **DIDNT none**
- **GAPS none**

## Files Changed

- `tests/fs-rag-sibling-rollout-canonical-cli.sh` (new, 112 lines, 12/12 PASS)
- `.flywheel/audit/flywheel-2xdi.150/` (this evidence pack)

## L112 Probe

- `l112_probe_command`: `bash tests/fs-rag-sibling-rollout-canonical-cli.sh | tail -1`
- `l112_probe_expected`: `grep:pass=12 fail=0`
- `l112_probe_timeout_sec`: `30`

## Recipe extension — 5th instance via shape-adaptation

| # | Bead | Script | Shape | Assertions |
|---|---|---|---|---|
| 1 | 2xdi.90 | operator-fatigue-probe | probe | 9 |
| 2 | 2xdi.92 | public-artifact-pipeline-probe | probe | 10 |
| 3 | 2xdi.146 | codex-pane-path-probe (N=3 promotion) | probe | 10 |
| 4 | 2xdi.147 | cross-repo-fmh-probe (N=4 post-promotion) | probe | 12 |
| 5 | **2xdi.150** | **fs-rag-sibling-rollout (mutation tool)** | **mutation tool** | **12** |

**First non-probe extension.** The recipe's SHAPE (test file under canonical-cli naming = corpus #5 receiver) generalizes; assertions adapt to script-class. This validates the recipe as TEMPLATE-EXTENSIBLE, not just template-stable.

Filed skill discovery:
`pattern-emerged-test-receiver-wire-in-recipe-N5-extends-to-mutation-tool-shape-not-just-probe-shape`

## Pattern reinforcement — 25th distinct fix shape entry

Cluster shape distribution after this bead:
- doctrine cross-link forward-link: N=11
- **test-receiver wire-in: N=5** ← outright 2nd-most-replicated now
- probe corpus extensions: N=4
- (everything else N≤2)

Test-receiver wire-in (N=5) > probe corpus extensions (N=4) — clear 2nd
place. The recipe-extension to non-probe shapes opens up future
mutation-tool / install-script / scaffold-tool cold-flag resolution
without requiring substrate-registry mutation.

## Four-Lens Self-Grade

- **brand:** 10 — clean recipe-extension decision; preserved template + adapted assertions
- **sniff:** 10 — 12 assertions cover mutation-discipline (--apply gating) + exit codes + bead-citation chain (owner + parent + doctrine cross-ref) + defensive arg parsing
- **jeff:** 9 — convergent with 2xdi.* cluster
- **public:** 10 — future workers shipping similar fixes for non-probe scripts have a template + assertion-adaptation example
