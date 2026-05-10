---
bead_id: flywheel-wbnb
task_id: flywheel-wbnb-dc6099
worker_identity: MistyCliff
ts: 2026-05-10T04:42:00Z
mission_fitness: adjacent
commit_sha: pending
linked_incidents: []
linked_l_rules:
  - L63
linked_skills:
  - cross-collection-fanout
  - jeff-issue-chain
narrative_tags:
  - producer-then-consumer-split
  - mcp-only-substrate-architectural-constraint
  - opt-in-axis-backwards-compat
  - stale-gating-dep-corrected
---

Two interesting decisions shaped this bead.

First, the gating-dep claim was stale. The bead body said "currently
85/177 indexed; 92 skipped_budget" — but a live probe of
`mcp__socraticode__codebase_list_projects` showed 177/177 jeff-corpus
repos fully indexed, all complete. So the bead was actually
dispatchable, just not in the way the bead author thought. The
canonical recovery: probe live state before honoring the dep claim.

Second, the architectural constraint. The bead body's AG1 said
the rubric script "Runs `mcp__socraticode__codebase_search` across
all indexed Jeff repos" — but that's an MCP-only tool, not callable
from a Python CLI. socraticode is a node MCP server with no exposed
HTTP port and no CLI search interface. So the rubric *cannot* do the
search itself.

The right answer was the produce-then-consume split: the rubric
becomes a deterministic checker of citations *already in the draft
body*, and the actual MCP-driven search is owned by an
orchestrator-side producer (a companion bead spec, filed as AG8).
This honors the bead's "leverage cross-collection-fanout skill —
DON'T reinvent the cross-corpus query" directive. The producer's
output is the consumer's input; the rubric never crosses the
MCP boundary.

The opt-in design (`--corpus-scan` flag) was the load-bearing
backwards-compat decision. Adding the 8th axis as always-evaluated
broke 4 existing rubric tests because none of the existing fixtures
have corpus citations (and shouldn't — they predate this bead). So
`corpus_aware` evaluates only when the flag is set; the schema still
enumerates all 8 supported axes for discoverability, but the runtime
default is the original 7-axis behavior. Existing fixtures + tests
pass without modification (only schema-introspection assertions
needed updating to match the new 8-axis schema).

The exit-code-4 carve-out for `same_issue_already_filed` is the
one place where this rubric departs from "deterministic check, no
side effects." When the draft cites an existing issue against the
same gap, the operator should amend that issue rather than file new.
A rubric-fail would be confusing (the draft might score 7/8 on the
other axes); a hard exit code makes the disposition unambiguous.
The orchestrator/issue-chain skill can branch on rc=4 specifically
to route the draft to amend-or-withdraw.

The pre-existing `live draft` test fail (the file
`/tmp/jeff-issue-runtime-handoff-singleton.md` doesn't exist locally)
is unrelated to this bead — verified via stash round-trip. Worth
noting in evidence so the next worker doesn't chase a phantom
regression. The fragility is the test depending on session-scoped
fixtures in `/tmp`; flagging it but not fixing it (out of scope).

The categorize-by-window heuristic in
`categorize_corpus_citations` is the one piece that might need
tuning post-burn-in. It looks at a 5-line window around each
`Dicklesworthstone/...` anchor for category cues. Uncategorized
hits default to `prior_art` (so author still gets credit). If
real drafts produce false categorization in practice, the
heuristic moves to per-line-only or the cue regexes get tightened.
The doctrine doc names this so the next reader knows where to
look.
