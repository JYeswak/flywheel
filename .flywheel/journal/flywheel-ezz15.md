---
bead: flywheel-ezz15
title: doctrine-polish-bar-lint 8-dim rubric + tick-driver wire-in (Option D mechanization)
worker: MagentaPond (flywheel:0.3)
date: 2026-05-11
status: shipped
priority: P1
mission_fitness: adjacent
sister_arc_shape: pmg3c (Option C) + xn5bm (Option B) → ezz15 (Option D periodic-tick measurement)
baseline_avg: 0.766 (6.1/8 dims)
---

# Journey: flywheel-ezz15

## What the bead asked for

P1: Adapt the Polish Bar 8-dim rubric from
`documentation-website-for-software-project` skill to score
`.flywheel/doctrine/*.md` files. Heuristic-based (NOT LLM). Tick-driver
wire-in. Baseline + per-dim fail follow-up handling.

## What I shipped

### 1. `.flywheel/scripts/doctrine-polish-bar-lint.sh` (190 lines)

Canonical-CLI-scoped (5-surface triad: --help/--info/--schema/--examples/--doctor).

8 dimensions scored 0/1:
1. orientation (what/who/where in first ~800 chars)
2. motivation (why + failure-mode markers)
3. mental_model (mermaid OR ASCII diagram)
4. narrative_flow (≥3 prose paragraphs, avg 50-400 words)
5. concrete_example (code block)
6. pitfalls (anti-pattern / pitfall / gotcha / callout warning)
7. tips_tricks (tip / beyond / non-obvious / sister / harvest)
8. cross_links (markdown links to sister doctrine OR memory files)

Output: JSON with dimensions + pass_count (0-8) + overall_score (0.0-1.0).

### 2. `.flywheel/tests/test-doctrine-polish-bar-lint.sh` (10 AGs all pass)

Test covers: syntax, canonical-CLI triad, JSON shape, rich fixture (0.875),
minimal fixture (0.0), --apply-receipts ledger write, manifest entry, exit
codes, directory-input array.

### 3. Tick-driver-manifest wire-in

`.flywheel/scripts/tick-driver-manifest.json` `primitives` array (17 → 18):
entry inserted after `agents-md-fleet-propagator`. Args:
`[".flywheel/doctrine", "--apply-receipts"]`. Timeout 60s.

### 4. Baseline of 8 session-shipped doctrines

Average: **0.766** (6.1/8 dims). Highest: respawn-canonical-recovery
(0.875). Lowest: name-the-upward-walk-you-defeat (0.625).

Common failures:
- mental_model: **8/8 docs** fail (faqj2 harvest signal)
- orientation: 2/8 docs
- narrative_flow: 2/8 docs
- concrete_example: 1/8 docs

## Per-dim fail handling — faqj2 harvest, not per-fail beads

Per bead AG, chose faqj2 harvest path over per-fail bead filing because:
1. 8-instance recurrence at once would violate decompose-by-natural-unit
2. Substrate-self-improving loop already validates harvest pattern (xbsd8/ugali)
3. faqj2 finding-type candidate documented:
   `doctrine_polish_dim_below_threshold` (when N≥3 docs share a dim fail)

## Pattern reinforcement — 3rd mechanization arc this session

This bead is the 3rd mechanism-shipping bead in the substrate-self-improving
loop's mechanization phase:

| # | Bead | Pattern | Mechanism shipped | Timing axis |
|---|---|---|---|---|
| 1 | pmg3c | forward-link-doctrine-doc-recipe | Option C: dispatch packet auto-injection | per-dispatch |
| 2 | xn5bm | cluster-maintainer-pattern | Option B: probe gap clustering | per-probe-run |
| 3 | **ezz15 (this)** | **doctrine polish bar** | **Option D: tick-driver periodic scoring** | **per-tick** |

Three different timing axes, three different leverage shapes, same
underlying loop: pattern observed → doctrine canonicalized → mechanism ships.

## Compliance

- AG receipt: 5/5 bead AGs + 10/10 test AGs = 15 acceptance gates
- META-RULE 2026-05-11: 30th application
- L52: 0 new beads filed (faqj2 harvest captures per-fail class)
- Boundary preservation: scoring only; no doctrine mutation
- L107: MCP-skipped
- compliance_score: 1000/1000

## Operational impact

Future ticks will append per-doctrine-doc score rows to
`~/.local/state/flywheel/doctrine-polish-bar.jsonl`. Tick-over-tick
analysis can surface score drift (e.g., doctrine doc degrades due to
later edits). When a dim hits N≥3 across the corpus,
faqj2 surfaces it as a `doctrine_polish_dim_below_threshold` finding for
orch to dispatch a polish-pass calibration.

Current baseline: 0.766 avg. Future target: 0.85+ (after addressing
mental_model + orientation gaps across the doctrine corpus).
