---
title: "jeff-corpus-rubric-augment doctrine"
type: doctrine
created: 2026-05-09
frontmatter_source: scaffold-doc-frontmatter
---

# jeff-corpus-rubric-augment doctrine

**Bead origin:** flywheel-wbnb (extends flywheel-3p1j jeff-issue-rubric).
**Joshua trigger:** 2026-05-04 — "once we get jeff's entire library indexed,
we can add some commentary about scanning his entire repo looking for
similarities, etc. to provide even more accretive value to our issue process".

## Goal

Before we file an issue against any Dicklesworthstone repo, we cross-check
the draft against the full Jeffrey corpus (now 177/177 indexed in qdrant
via socraticode) for:

- **Similar issue patterns** that might already be filed (amend vs file new)
- **Prior art** (Jeff already solved this shape somewhere)
- **Shape precedent** (Jeff's actual API convention for this primitive class)
- **Anti-patterns** Jeff has explicitly rejected

The result lands in the issue body as a citation block, and the rubric
verifies the draft author actually cited the corpus before approving the
issue for filing.

## Architecture: produce-then-consume

Socraticode is an MCP server with no CLI search interface. A Python rubric
script cannot directly call `mcp__socraticode__codebase_search`. So this
bead splits the work:

```
                                          Issue draft
                                              │
                                              ▼
   ┌─────────────────────────────────┐
   │  PRODUCER (orchestrator-side)   │
   │  cross-collection-fanout skill  │  ← runs MCP search across 177 repos,
   │  invoked from Claude Code       │     emits citation block, injects
   │  (or any MCP-capable client)    │     into draft body
   └────────────────┬────────────────┘
                    │
                    ▼
                 draft body now contains
                 ## Corpus-aware citations
                 ### Prior Art / Shape Precedent / Anti Pattern
                    │
                    ▼
   ┌─────────────────────────────────┐
   │  CONSUMER (rubric-side)         │
   │  jeff-issue-rubric.py           │  ← deterministic checker, scans
   │     --corpus-scan --json        │     draft body for citations,
   │                                 │     categorizes them, gates on
   │                                 │     same-issue-already-filed
   └─────────────────────────────────┘
                    │
                    ▼
              Decision: auto_post / revise / withdraw
              + exit code 4 if same-issue blocker present
```

The producer half (`cross-collection-fanout` skill) is OUT OF SCOPE for
this bead — its companion bead spec is at
`.flywheel/audit/flywheel-wbnb/companion-bead-spec.md`. This bead delivers
the consumer half: rubric extension + categorization + threshold +
doctor signal.

## Rubric changes (this bead's deliverable)

- **New axis:** `corpus_aware` (8th axis; promotes the rubric from 7 to 8 axes)
- **New flag:** `--corpus-scan` — gates the AG4 hard-blocker behavior on
  same-issue-already-filed citations (without the flag, rubric still
  reports `corpus_scan` payload but rc=4 is not raised)
- **New exit code:** `4` — same-issue-already-filed citation present
  (operator must amend existing issue rather than file new); distinct
  from generic rubric-fail (rc=1)
- **New doctor signal:** `jeff_drafts_unscanned_count` — drafts in the
  glob with zero corpus citations across all 4 categories
- **New policy:** `8_high → auto_post`, `7_high → revise`,
  `0_to_6_high → withdraw` (was `7_high / 6_high / 0_to_5_high`)

## Categorization heuristics (rubric.py:`categorize_corpus_citations`)

Each draft line containing a `Dicklesworthstone/<repo>` or
`github.com/Dicklesworthstone/...` anchor is categorized by inspecting a
5-line window for category cues:

| Category                    | Cue regex highlights                                   |
|-----------------------------|--------------------------------------------------------|
| `same_issue_already_filed`  | `see (?:also )?issue #N`, `already filed`, `duplicate of #N` |
| `prior_art`                 | `prior art`, `Jeff already solved`, `consistent with X in repo Y` |
| `shape_precedent`           | `Jeff's idiom`, `matches the pattern in`, `API convention` |
| `anti_pattern`              | `Jeff explicitly rejected`, `anti-pattern in`, `removed in upstream` |

Uncategorized citations default to `prior_art` so the author still gets
credit for citing the corpus. Each bucket is capped at 8 snippets to keep
the citation block readable.

## Threshold (`score_corpus_aware`)

| Condition                                               | Level    |
|---------------------------------------------------------|----------|
| `same_issue_already_filed >= 1`                         | low (HARD-FAIL; rc=4 with `--corpus-scan`) |
| `total_citations == 0`                                  | low (axis fail) |
| `total_citations == 1` OR `distinct_categories < 2`     | medium |
| `>=2 citations across >=2 categories, no same-issue`    | high   |

## CLI doctrine (canonical-cli-scoping)

Existing rubric triad preserved (`--info` via argparse `-h`,
`--schema`, `--examples`). New entries:

```
--corpus-scan         enable AG4 same-issue blocker (rc=4)
--doctor [--strict]   doctor signal includes jeff_drafts_unscanned_count
```

Schema-emitted exit-code map:
```
0  rubric pass
1  rubric fail (one or more axes < high)
4  same-issue-already-filed corpus citation present (--corpus-scan; AG4 blocker)
```

## Backwards compatibility

- `--corpus-scan` flag is OPTIONAL. Without it, the rubric still reports
  the `corpus_scan` payload (categories + buckets + citation_block_md) but
  does NOT raise the rc=4 blocker. Callers that don't want the blocker
  behavior simply omit the flag.
- The `corpus_aware` axis is mandatory (always evaluated). Drafts that
  haven't been corpus-scanned will fail `corpus_aware` with level=low,
  the same way unrubricd drafts fail today.
- Existing 7-axis decision policy keys (`7_high`, `6_high`,
  `0_to_5_high`) replaced with computed-from-AXES-length keys
  (`8_high`, `7_high`, `0_to_6_high`). Schema reflects the new keys.

## Tests

`tests/jeff-issue-rubric-corpus-scan.sh` — 9/9 PASS:

```
PASS schema reflects 8 axes + 8_high policy + exit code 4
PASS prior-art fixture: rc=0, auto_post, all 8 high, no same-issue blocker
PASS prior-art fixture: 3 categories populated, same_issue=0
PASS prior-art fixture: citation_block_md includes 3 headed sections
PASS zero-citations fixture: rc!=0, corpus_aware in hard_fail_axes
PASS same-issue fixture: exit=4 (AG4 hard blocker triggered)
PASS doctor: jeff_drafts_unscanned_count=1 (only the zero-citations fixture)
PASS corpus_scan output is always present (backwards-compat for callers w/o --corpus-scan)
PASS AG4 blocker (rc=4) gated by --corpus-scan flag (rc=1 without flag)
```

Three fixtures cover the canonical states: prior-art (8/8 high), zero-
citations (corpus_aware low), same-issue (rc=4 hard blocker).

## Cross-references

- L63 jeff-intel-network: this rubric extension consumes the indexed
  corpus that L63 mandates be daily-monitored
- skill `cross-collection-fanout`: producer for the citations the rubric
  consumes (existing skill — leverage, don't reinvent)
- skill `jeff-issue-chain`: this rubric is the gate before issue-chain
  filing
- bead flywheel-3p1j (closed): the original 7-axis rubric this extends
- bead flywheel-9nhx: library-ingestion (177/177 indexed; gating dep
  satisfied — bead body's "85/177" claim was stale)
