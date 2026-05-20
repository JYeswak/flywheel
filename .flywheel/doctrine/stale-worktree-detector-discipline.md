# Stale Worktree Detector Discipline

Joshua's 2026-05-20 07:42Z question was why SLB plus DCG cannot simply clean
stale worktrees. The answer is that the safety layers exist, but a detector has
to choose the right layer before a destructive command appears in a shell.

The detector routes four classes:

- `DISPOSABLE`: worktree paths under `/tmp`, `$TMPDIR`, or macOS per-user temp
  route to 8iook pre-authorized DCG scope (`git-worktree-remove-tmp`).
- `REVERSIBLE_RECIPE`: clean sibling-suffix worktrees that are merged, pushed,
  and older than the age threshold route to daeqx SLB recipe
  `git-worktree-remove-sibling-merged-pushed`.
- `PEER_REVIEW`: detached heads, dirty worktrees, duplicate branch worktrees,
  uncertain merge/push state, or partial state route to the zesttube SLB
  peer-approval surface with a `context_check`.
- `HUMAN_FALLBACK`: only fundamentally unclassifiable states reach Joshua.

The detector reads zesttube's `.flywheel/config/slb-tier-mapping.yaml` when it
exists. If that routing table is absent, the detector emits
`routing_table.status=missing` and uses the dispatch contract's three route
names: `8iook`, `daeqx`, and `zesttube-slb`.

This pairs with:

- 8iook DCG pre-authorized scopes in `~/.flywheel/dcg-pre-authorized-scopes.json`
- daeqx recipe-based SLB execution in `~/.flywheel/slb-recipes.json`
- zesttube's SLB peer-approval surface for context-checked complex cases
- zesttube-owned 24kdr hook enrichment, which surfaces SLB on DCG block

Fleet launchd rollout is dry-run first. `--apply` on
`stale-worktree-detector-fleet-rollout.sh` requires `--joshua-approved`; the
detector itself does not remove worktrees during validation.
