# Companion bead spec — cross-collection-fanout corpus citation producer

**Filed by:** flywheel-wbnb (this bead, AG8) for orchestrator routing.
**Status:** PROPOSED — orchestrator should file this as a follow-up P2 bead.

## Goal

Build the *producer* half of the bead flywheel-wbnb produce-then-consume
architecture: an orchestrator-side tool that runs MCP-driven socraticode
search across the 177 Jeffrey-corpus collections and emits a categorized
citation block ready for injection into a Jeff issue draft.

## Context

flywheel-wbnb shipped the *consumer* half: `jeff-issue-rubric.py
--corpus-scan` reads the draft body, categorizes corpus citations into
4 buckets (prior_art / shape_precedent / anti_pattern /
same_issue_already_filed), and gates the rubric on same-issue presence.

The consumer cannot directly call MCP socraticode (Python CLI cannot
reach an MCP server). So citations need to land in the draft *before*
the rubric runs. That's the producer's job.

## Acceptance gates (proposed)

### AG1: producer script `.flywheel/scripts/jeff-corpus-citation-producer.{sh,py}`

Reads:
- a draft path or draft-glob (canonical: `/tmp/jeff-issue-*.md`)
- key terms from the draft body (primitive name, feature keywords —
  same extraction logic as the rubric's `categorize_corpus_citations`
  in reverse)

For each draft:
- Calls `mcp__socraticode__codebase_search` against each
  Dicklesworthstone collection (177 collections after the
  flywheel-9nhx ingestion; producer iterates via the
  `cross-collection-fanout` skill's RRF-merge pattern)
- Surfaces top 10 hits per category
- Emits a citation block matching the rubric's expected format:

```markdown
## Corpus-aware citations (cross-collection-fanout)

### Prior Art (N)
- <Dicklesworthstone/repo>: <file>:<line>: <snippet>

### Shape Precedent (N)
- <Dicklesworthstone/repo>: <file>:<line>: <snippet>

### Anti Pattern (N)
- <Dicklesworthstone/repo>: <file>:<line>: <snippet>
```

### AG2: insertion point

The producer offers two insertion modes:
- `--inject` — appends/replaces the `## Corpus-aware citations` section
  in the draft file in-place
- `--emit` — writes the citation block to stdout for piped insertion

### AG3: cross-collection-fanout integration

Uses the existing `cross-collection-fanout` skill at
`~/.claude/skills/cross-collection-fanout/` (DON'T reinvent the
fan-out query). The skill's contract:
- Per-source timeout
- Embedding-parity invariant
- RRF score normalization
- Surface partial-result state

### AG4: same-issue heuristic

When a hit's repo+title+body is suspicious of being an existing issue
about the same gap, the producer marks it as `### Same Issue Already Filed`
in the citation block. The rubric (consumer) then sees this and triggers
the rc=4 blocker.

This requires the producer to also query GitHub `/search/issues`
against the draft's primary repo for similarity (Levenshtein on title +
body keyword overlap). Out-of-bounds may be acceptable to defer to a
sub-bead.

### AG5: tests

Fixture corpus query against `Dicklesworthstone/ntm` (small, focused,
well-indexed). Assertions:
- producer emits a non-empty citation block when relevant terms exist
- producer emits an empty block (with explanatory marker) when no hits
- consumer rubric (already shipped in flywheel-wbnb) passes the produced
  block round-trip

### AG6: cadence

- On-demand: workers/orchestrators run the producer before invoking
  the rubric on a draft
- Optional launchd: nightly producer run against any unscanned drafts
  in `/tmp/jeff-issue-*.md`, injecting citation blocks; doctor
  emits unscanned_count separately

## Why P2 (not P1)

flywheel-wbnb's deliverable (the consumer + threshold + doctor signal)
already bites: workers' issue drafts now flunk `corpus_aware` until they
include citations. Joshua can manually invoke `cross-collection-fanout`
(or any MCP search) and paste citations until this producer lands. The
producer is force-multiplier, not gating.

## Cross-references

- bead flywheel-wbnb (this bead) — consumer half
- skill `cross-collection-fanout` — query mechanism
- skill `jeff-issue-chain` — issue-filing pipeline
- L63 — corpus is canonical substrate; this producer is the rubric-side
  consumer of L63's daily intel
