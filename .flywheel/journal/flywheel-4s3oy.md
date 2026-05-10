---
bead_id: flywheel-4s3oy
task_id: flywheel-4s3oy-7f673e
worker_identity: MistyCliff
ts: 2026-05-10T04:31:30Z
mission_fitness: adjacent
commit_sha: pending
linked_incidents: []
linked_l_rules: []
linked_skills: []
narrative_tags:
  - donella-stock-vs-flow
  - latent-substrate-surfacing
  - canonical-cli-scoping-rc3-empty-week
  - heterogeneous-jsonl-normalization
---

The bead spec said "reads dispatch-log.jsonl + receipt.json + audit/
evidence.md files for sd_ids" — but pre-flight probing showed
dispatch-log.jsonl has zero `sd_ids` field occurrences. The actual
write path is `~/.local/state/flywheel/skill-discoveries.jsonl`,
which had 43 rows already. Spec drift on source-of-truth: I
adapted the aggregator to read the canonical jsonl as primary, and
relegated dispatch-log + audit dirs to optional cross-reference
checks via `--doctor`. This is a worker pattern Joshua's seen
before: when the spec names a source that doesn't carry the data,
follow the data.

The schema heterogeneity in the canonical jsonl was load-bearing.
Different rows have different keys: some use
`candidate_skill_name`, others use `topic`, still others have
`proposed_skill`; some have `worker_identity`, others have
`worker_pane`. The right answer is normalize-with-fallback:
`candidate_skill_name // .topic // .proposed_skill // "<unknown>"`
in jq, and document the priority in the doctrine. Don't fight the
heterogeneity, accept it as data.

The rc=3 empty-week exit class is the canonical-cli-scoping
reflex of the day. Internal errors are rc=1; missing dependencies
are rc=2; "the source had nothing in this week" is a different
disposition entirely — the operator wants to know about it but it's
not a *failure*. Carving out rc=3 (and asserting it in the e2e)
makes empty-week handling explicit instead of silent. Same shape
the jeff-daily-corpus-diff aggregator used yesterday.

The Donella framing in the bead body — "a stock nobody can query
is functionally not a stock" — is the load-bearing insight.
Skill-discovery filing without rollup was the same paradigm-tier
failure as L62 (state.md as latent-opportunity-substrate) and L63
(jeff-intel-network without a poller): the substrate exists but no
agent reads it back. The doctrine cross-references that paradigm
explicitly so the next worker who notices the same pattern (a
filed-but-unread surface somewhere else in the fleet) has a
canonical example to build on.

The cross-worker agreement detection bug in the e2e took a
second to spot — jq's `and` / `|` precedence bit me. The fix is to
bind the filter result via `as $h` and then test on `$h` — once
that's inside parens the operator precedence stops mattering. Folded
that pattern into the test, kept moving.

Inaugural week 2026-19 has 0 cross-worker agreements — itself a
useful signal about how diverse this week's discoveries were.
Three of the 15 entries came from this very session of dispatches
(t53xc, ys7em, r52ig), which means the rollup picks up live
state correctly. Mission anchor satisfied: latent value made
queryable.
