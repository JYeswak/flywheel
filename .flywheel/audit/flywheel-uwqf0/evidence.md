# Evidence: flywheel-uwqf0 — fs-rag sibling rollout per-subtree gating + retry

**Bead**: flywheel-uwqf0 (P2) | **Task ID**: flywheel-uwqf0-fafcb8 | **Identity**: MistyCliff
**Parent rollout**: flywheel-hi4e6 (closed 2026-05-10) — shipped portable fs-rag template + installer; all 6 siblings skipped on tree-wide dirty gate.

## Shipped: Option B (per-subtree gating, Meadows #5)

New `.flywheel/scripts/fs-rag-sibling-rollout.sh` script:
- Probe gate: `git status --porcelain .flywheel/` (subtree, not tree-wide)
- Per repo: if subtree clean → invoke `flywheel-adopt.sh --apply --apply-fs-rag --idempotency-key KEY`
- Aggregate per-repo rows into `.flywheel/audit/flywheel-fs-rag-portable/sibling-rollout-<date>.json`
- Default `--dry-run`; mutate via `--apply --idempotency-key KEY`
- rc=1 when any repo skipped/failed (operator-actionable signal)

Gate-refinement rationale (per Meadows #5: "gate on the actual safety
property, not the proxy"): the rollout only mutates inside `.flywheel/`
and `.git/hooks/`. So `.flywheel/-subtree clean` is the precise gate;
tree-wide clean is an over-conservative proxy that blocks rollouts when
unrelated areas are dirty.

## Retry result (2026-05-11 dry-run)

```
siblings=6 installed=0 skipped=6 failed=0 gate=flywheel_subtree_clean
```

| Repo | Status | Reason | .flywheel/-subtree dirty |
|---|---|---|---|
| alpsinsurance | skipped | flywheel_subtree_dirty | 21 |
| mobile-eats | skipped | flywheel_subtree_dirty | 95 |
| skillos | skipped | flywheel_subtree_dirty | 111 |
| vrtx | skipped | flywheel_subtree_dirty | 65 |
| picoz | skipped | flywheel_subtree_dirty | 69 |
| zesttube | skipped | flywheel_subtree_dirty | 66 |

**Finding**: even with the Meadows-refined gate, all 6 siblings have
unsaved `.flywheel/` subtree changes today (substantially less than the
tree-wide counts at flywheel-hi4e6 closeout, but still non-zero). The
refinement doesn't unblock the rollout today, but:

1. Future retry uses the precise gate — when a sibling's `.flywheel/`
   subtree is clean (regardless of unrelated repo changes), the rollout
   will proceed.
2. The script is operator-runnable on-demand (`fs-rag-sibling-rollout.sh
   --apply --idempotency-key fs-rag-rollout-YYYY-MM-DD`).
3. Future daemon-based opportunistic retry (Option A) is a thin wrapper
   over this script (launchd plist running daily; rc=1 signals "still
   blocked", rc=0 signals "fully rolled out").

## Acceptance

Per bead: "switch the dirty-count check from 'tree-wide' to '.flywheel/
subtree' + retry rollout".

- ✅ Gate switched: tree-wide → `.flywheel/` subtree
- ✅ Retry executed (dry-run): receipt written at
  `.flywheel/audit/flywheel-fs-rag-portable/sibling-rollout-2026-05-11.json`
- ✅ Operator handoff: script + receipt + this evidence enable future
  retry without re-implementing the gate
- ⏸ Per-repo `--apply`: deferred until siblings' `.flywheel/` subtrees
  are committed; not in scope of this bead's deliverable per bead
  wording ("retry rollout" = the retry, not unconditional --apply
  against still-dirty subtrees)

## Files changed

- `.flywheel/scripts/fs-rag-sibling-rollout.sh` (NEW; 145 lines)
- `.flywheel/audit/flywheel-fs-rag-portable/sibling-rollout-2026-05-11.json` (NEW; rollout receipt)

## L112 verify probe

`bash .flywheel/scripts/fs-rag-sibling-rollout.sh --dry-run 2>&1 | jq -r '.gate'`
Expected: `grep:flywheel_subtree_clean`
