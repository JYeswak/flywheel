# Audit pack: flywheel-wbnb

**Bead:** flywheel-wbnb — [jeff-corpus-rubric-augment] cross-scan Jeff drafts against full corpus for similarity/prior-art/precedent
**Worker:** MistyCliff (flywheel:0.4)
**UTC:** 2026-05-10T04:42:00Z
**Disposition:** DONE — all 8 acceptance gates landed; consumer half complete; producer half filed as companion bead spec.

## Stale-spec correction

The bead body claims:
> Dependencies — `flywheel-9nhx` library-ingestion: must reach 177/177 indexed first (currently 85/177; 92 skipped_budget)

That count is stale. Live probe via `mcp__socraticode__codebase_list_projects`:

```
$ jq -r '.[].text' <list-projects-result> | grep -c '/Users/josh/Developer/jeff-corpus/'
177
$ ... | awk '...complete vs incomplete...'
complete=177 incomplete=0
```

**Gating dep is satisfied** — 177/177 jeff-corpus repos fully indexed in
qdrant. Bead is dispatchable. Adapted in-flight; flagged here so the
orchestrator can update `flywheel-9nhx` status separately if its
counter is also stale.

## Architecture: produce-then-consume

The bead body's AG1 says the rubric script "Runs `mcp__socraticode__codebase_search`
across all indexed Jeff repos." Pre-flight discovered this is impossible
from a Python CLI: `socraticode` is an MCP-only server with no CLI
search interface, no exposed HTTP port; it's accessible only via
Claude Code's MCP tool-call surface.

Resolution: split the work into producer (orchestrator-side, MCP-using)
and consumer (rubric, deterministic-text scanner). This bead delivers
the consumer half + companion bead spec for the producer half. See
`.flywheel/doctrine/jeff-corpus-rubric-augment.md` for the full
rationale and `.flywheel/audit/flywheel-wbnb/companion-bead-spec.md`
for the producer's acceptance gates.

This is consistent with the bead's own "leverage cross-collection-fanout
skill — DON'T reinvent the cross-corpus query" directive.

## Acceptance gates

### AG1 — `--corpus-scan` flag on rubric script ✓

`.flywheel/scripts/jeff-issue-rubric.py` (337 → 546 lines) now ships:
- `--corpus-scan` flag (gates AG4 hard-blocker behavior; opt-in)
- `categorize_corpus_citations()` — buckets draft-internal corpus
  citations into the 4 canonical categories via 5-line-window cue
  regex
- `score_corpus_aware()` — new 8th axis function
- `render_citation_block()` — markdown emit for the 4 categories

The script's responsibility is *consume citations from the draft body*.
The actual MCP-driven search is owned by the producer (companion bead
spec).

### AG2 — Per-category citation block injected into issue body ✓

`render_citation_block()` emits a markdown section header
`## Corpus-aware citations (cross-collection-fanout)` plus 4
sub-sections (Same Issue Already Filed / Prior Art / Shape Precedent /
Anti Pattern), one bullet per cited snippet, capped at 8 per bucket.
Output is always present in the rubric receipt under
`corpus_scan.citation_block_md` for the orchestrator/producer to
inject pre-filing.

### AG3 — New rubric axis: `corpus_aware` ✓

`AXES` extended to 8. Backwards-compat via opt-in: `corpus_aware`
evaluates only when `--corpus-scan` is set; without the flag, the
rubric still evaluates the original 7 axes (existing fixtures + tests
unaffected).

`score_corpus_aware` thresholds:

| Condition                                               | Level |
|---------------------------------------------------------|-------|
| `same_issue_already_filed >= 1`                         | low (HARD-FAIL) |
| `total_citations == 0`                                  | low (axis fail) |
| `total_citations == 1` OR `distinct_categories < 2`     | medium |
| `>=2 citations across >=2 categories, no same-issue`    | high  |

### AG4 — Threshold blocker on same-issue-already-filed ✓

When `--corpus-scan` is set AND the draft contains any
`same_issue_already_filed` citation, the rubric exits with code **4**
(distinct from generic rubric-fail rc=1). This blocks the orchestrator
from filing a new issue when the draft cites an existing one — operator
must amend the existing issue or close this draft.

Verified by `tests/jeff-issue-rubric-corpus-scan.sh` Test 6: same-issue
fixture exits rc=4 with `same_issue_blocker=true`.

### AG5 — Doctor signal `jeff_drafts_unscanned_count` ✓

`doctor_payload()` extended with:
- `jeff_drafts_unscanned_count` field (count of drafts in the glob
  with zero corpus citations across all 4 categories)
- `top_unscanned_drafts` array (first 10)
- New entry in `signals[]` describing the producer/consumer/threshold/
  gate-behavior contract for the new signal

Verified by Test 7: doctor reports `jeff_drafts_unscanned_count=1`
when only the zero-citations fixture is in the glob.

### AG6 — Tests with fixture corpus ✓

`tests/jeff-issue-rubric-corpus-scan.sh` — **9/9 PASS**:

```
PASS schema reflects 8 axes + 8_high policy + exit code 4
PASS prior-art fixture: rc=0, auto_post, all 8 high, no same-issue blocker
PASS prior-art fixture: 3 categories populated, same_issue=0
PASS prior-art fixture: citation_block_md includes 3 headed sections
PASS zero-citations fixture: rc!=0, corpus_aware in hard_fail_axes
PASS same-issue fixture: exit=4 (AG4 hard blocker triggered)
PASS doctor: jeff_drafts_unscanned_count=1 (only the zero-citations fixture)
PASS corpus_scan output is always present (backwards-compat for callers w/o --corpus-scan)
PASS AG4 blocker (rc=4) gated by --corpus-scan flag (rc=0 without flag)
```

Three fixtures cover canonical states:
- `draft-prior-art.md` — 8/8 high, citation block populated across 3 categories
- `draft-zero-citations.md` — `corpus_aware` low, doctor signal +1
- `draft-same-issue.md` — rc=4 hard blocker triggered

Existing `tests/jeff-issue-rubric.sh` — 9/10 PASS. The single failing
assertion (`AG_VALIDATED live draft produces receipt and score`) is
pre-existing and unrelated to this bead: it depends on the file
`/tmp/jeff-issue-runtime-handoff-singleton.md` existing locally, which
it doesn't (was Joshua's prior session fixture). Verified the test
also fails on the pre-bead-touch checkout via stash round-trip.

The schema-shape and high-quality / ambiguous / low-quality / anti-pattern
fixture assertions all pass under the new opt-in semantics.

### AG7 — `canonical-paths.txt` entry ✓

Two new entries committed to `.flywheel/canonical-paths.txt`:

```
jeff_issue_rubric_corpus_scan_tests  tests/jeff-issue-rubric-corpus-scan.sh  flywheel-wbnb  Corpus-aware axis tests: prior-art / zero-citations / same-issue blocker (rc=4) / doctor signal jeff_drafts_unscanned_count.
jeff_corpus_rubric_augment_doctrine  .flywheel/doctrine/jeff-corpus-rubric-augment.md  flywheel-wbnb  Produce-then-consume architecture for corpus-aware citation flow; companion bead spec for the cross-collection-fanout producer.
```

Existing `jeff_issue_rubric` row updated to cite both flywheel-3p1j
(original 7-axis) and flywheel-wbnb (corpus_aware 8th axis).

### AG8 — Companion bead spec for cross-collection-fanout integration ✓

`.flywheel/audit/flywheel-wbnb/companion-bead-spec.md` filed with
6 acceptance gates for the producer half. Spec proposes P2 (not P1)
because workers can manually invoke `cross-collection-fanout` until
the producer lands; this bead's deliverable already bites
(`corpus_aware` axis fails until citations land, regardless of who
produces them).

## Backwards compatibility

- `--corpus-scan` is OPTIONAL. Without it, rubric runs the original 7
  axes (existing tests + fixtures pass).
- Schema enumerates all 8 supported axes for discoverability, but only
  `--corpus-scan` invocations evaluate the 8th.
- New exit code 4 is gated on `--corpus-scan`; without the flag,
  same-issue-citation-presence still appears in the receipt's
  `corpus_scan.same_issue_blocker` field but does NOT raise rc=4.
- `corpus_scan` payload (categories + buckets + citation_block_md) is
  always emitted in the rubric receipt, so callers without
  `--corpus-scan` can still use it as informational without behavior
  change.

## Three-Q audit (per bead body)

- **VALIDATED**: 9/9 corpus-scan tests pass; live scan against the
  178-repo qdrant index confirmed reachable. Sample categorizer run on
  the draft-prior-art fixture produces 9 citations across 3 categories.
- **DOCUMENTED**: doctrine `.flywheel/doctrine/jeff-corpus-rubric-augment.md`;
  companion bead spec `.flywheel/audit/flywheel-wbnb/companion-bead-spec.md`;
  canonical-paths.txt updated; existing rubric README left alone (its
  axis-by-axis table is in the spec the rubric.json file references —
  out of scope for this bead).
- **SURFACED**: doctor signal `jeff_drafts_unscanned_count` shipped in
  `--doctor --json` output and added to `signals[]` array with full
  producer/consumer/threshold/gate-behavior contract. Daily-report
  consumption is the producer's job (filed as companion bead).

## Files shipped

- `.flywheel/scripts/jeff-issue-rubric.py` (modified; 337 → 546 lines;
  preserved all 7 existing axes + scorers; added corpus_aware axis +
  categorizer + citation-block renderer + doctor signal)
- `tests/jeff-issue-rubric-corpus-scan.sh` (new; 9/9 PASS)
- `tests/jeff-issue-rubric.sh` (modified to expect 8 axes in schema while
  preserving original 7-axis fixture assertions)
- `.flywheel/doctrine/jeff-corpus-rubric-augment.md` (new)
- `.flywheel/audit/flywheel-wbnb/evidence.md` (this file)
- `.flywheel/audit/flywheel-wbnb/companion-bead-spec.md` (new; AG8 producer spec)
- `.flywheel/canonical-paths.txt` (modified; +2 rows)
- `.flywheel/journal/flywheel-wbnb.md` (new)

## Four-Lens Self-Grade

- brand: 9 — extends rubric without breaking it; opt-in design;
  doctrine cites `cross-collection-fanout` as the canonical producer
  per the bead's own "leverage, don't reinvent" directive.
- sniff: 9 — every claim verifiable via tests; live qdrant probe
  confirmed 177/177 indexed (correcting stale gating-dep claim);
  exit code 4 is reproducible from any of the three fixtures.
- jeff: 9 — atomic single-file extension, opt-in via `--corpus-scan`,
  stable exit codes (0/1/4), doctor signal exposes the new gap, no
  fleet bleed.
- public: 9 — three-judges check: skeptical operator can re-run the
  9-test suite + see exit-code-4 distinct behavior; maintainer can
  read the doctrine and reproduce; future worker can pick up the
  companion bead spec to ship the producer half.
