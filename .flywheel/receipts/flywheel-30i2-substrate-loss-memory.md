# flywheel-30i2 Substrate-Loss Memory Receipt

Task: `flywheel-30i2-13a582`
Bead: `flywheel-30i2`
Date: 2026-05-08

## Acceptance Evidence

1. Memory file exists and cites ALPS incidents plus B13/B14:
   `/Users/josh/.claude/projects/-Users-josh-Developer-flywheel/memory/feedback_substrate_loss_worker_commit_orphan.md`
   now cites fuckup-log row 578, ALPS orphan SHAs `2e43df2` and `641d926`,
   `flywheel-dt2w` (`commit_tag=[worker-branch-contract]`), and
   `flywheel-2bfg` (`commit_tag=[dcg-orphan-reset-blocker]`).

2. Fuckup row processed:
   `/Users/josh/.local/state/flywheel/fuckup-processed.jsonl` has a
   `substrate-loss-worker-commit-orphan-after-squash-merge` row for
   `fuckup_log_lines=[578]`, processed by `flywheel-30i2-13a582`.

3. Learn path references B13/B14:
   `.flywheel/validation-learn-ledger.jsonl` has dedupe key
   `substrate-loss-worker-commit-orphan-after-squash-merge:row578`, with
   `learn_route=promote` and explicit B13/B14 receipt references.

4. Skillos handoff receipt:
   `/Users/josh/.local/state/flywheel/skillos-pending-candidates.jsonl#ts=2026-05-08T22:06:42Z`
   records the substrate-loss trauma as `candidate_class=trauma-class`,
   `recipient=new-skill-suggestion`, `domain=substrate-loss`, with evidence
   pointing at row 578, the memory file, B13, and B14.

5. Doctrine decision:
   `explicit_no_doctrine_reason` is recorded in
   `/Users/josh/.local/state/flywheel/fuckup-processed.jsonl`: AGENTS.md L110
   already covers durable findings requiring consumer proof, and B13/B14 shipped
   the branch/reset mechanics. A new L-rule would duplicate doctrine.

6. Callback contract:
   Current DONE callback includes `substrate_loss_guard=PASS` for this
   implementation dispatch.

7. Source-of-truth discipline:
   No new skill-promotion substrate was created.
   `/Users/josh/.local/state/flywheel/wire-or-explain-ledger.jsonl#L1` is the
   canonical source row with
   `identity_key=flywheel-30i2-substrate-loss-row578-skill-candidate` and
   `artifact_class=skill_candidate`. The existing skillos pending candidate file
   is used as the handoff receipt.

## Verification

- `jq -e` over the appended fuckup-processed row: expected row 578 processed.
- `jq -e` over `.flywheel/validation-learn-ledger.jsonl`: expected dedupe key
  routed with `learn_route=promote`.
- `jq -e` over `/Users/josh/.local/state/flywheel/skillos-pending-candidates.jsonl`:
  expected `ts=2026-05-08T22:06:42Z`.
- `jq -e` plus chain verifier over
  `/Users/josh/.local/state/flywheel/wire-or-explain-ledger.jsonl`: expected
  row 1 with `artifact_class=skill_candidate` and intact hash chain.
- `br show flywheel-30i2` before close.

Result: `substrate_loss_guard=PASS`.
