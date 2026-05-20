---
title: "JSONL `effective_at` Sort Discipline (accretive-corrections-rows take-latest)"
type: doctrine
created: 2026-05-11
frontmatter_source: scaffold-doc-frontmatter
---

# JSONL `effective_at` Sort Discipline

Version: `jsonl-effective-at-sort-discipline/v1`
Owner: any worker/orchestrator/script that reads accretive JSONL state
Status: canonical, shipped 2026-05-11 (1:1 forward-link sub-pattern per pmg3c recipe)
Source bead: flywheel-2xdi.153
Canonical memory source: `feedback_topology_jsonl_take_latest_effective_at.md`

## ★ ORIENT

When reading accretive JSONL state files where multiple rows can exist per
key (session, loop, identity, allowlist row), **always sort by
`effective_at` descending and take the latest row per key**. The first
row in the file is the OLDEST. Naive `head -1` after grep/filter grabs
the stale row.

This doctrine applies to ANY JSONL where rows are appended as corrections,
not replacements:
- `~/.local/state/flywheel/session-topology.jsonl` (topology drift corrections)
- `~/.local/state/flywheel/loops/*.json` (loop state transitions)
- identity registries
- allowlist files with `superseded_by` semantics

## ✦ MOTIVATE

Why this discipline exists: 2026-05-05T02:48Z trauma — Joshua asked
"fix mobile-eats orch". Worker read session-topology.jsonl with naive
`jq | head -1`, grabbed the OLDEST row (orch=pane 2 from 12:04). The
file actually had 3 rows for mobile-eats:

| Row | effective_at | orch | Note |
|---|---|---|---|
| 1 | 2026-05-02T12:04 | 2 | original |
| 2 | 2026-05-02T12:08 | 2 | unchanged |
| 3 | 2026-05-02T15:22 | **1** | "topology drift correction" |

Row 3 IS the truth. Worker dispatched reorient to pane 2 (stale). Joshua
corrected: "pane 1 IS the orch — pane 2 was sent reorient already."

**Same shape as L66 meat-puppet-orchestrator-decision-on-partial-state:**
read first available state surface without checking for newer rows.

## ◐ MENTAL-MODEL

```
JSONL file (accretive, append-only):
  row 1: {key: X, effective_at: 12:04, value: A}     ← OLDEST
  row 2: {key: X, effective_at: 12:08, value: A}     ← (no change)
  row 3: {key: X, effective_at: 15:22, value: B}     ← LATEST (truth)
                                       ^
                                       └─ "drift correction" / "superseded the original"

Naive read: head -1 = row 1 = STALE
Canonical read: sort by effective_at desc + head -1 = row 3 = TRUTH
```

## ⬡ EXEMPLIFY

### Canonical: sort by effective_at desc + take latest

```bash
# Filter by session, sort by effective_at desc, take latest row
jq -c 'select(.session=="mobile-eats")' \
  ~/.local/state/flywheel/session-topology.jsonl \
  | sort -t'"' -k14 -r \
  | head -1

# OR jq slurp + sort_by + last:
jq -s '[.[] | select(.session=="mobile-eats")] | sort_by(.effective_at) | last' \
  ~/.local/state/flywheel/session-topology.jsonl
```

### Generic helper (works for any accretive JSONL)

```bash
jsonl_latest_by_key() {
  local file="$1" key="$2" value="$3"
  jq -s --arg k "$key" --arg v "$value" \
    '[.[] | select(.[$k] == $v)] | sort_by(.effective_at) | last' \
    "$file"
}

# Usage
jsonl_latest_by_key ~/.local/state/flywheel/session-topology.jsonl session mobile-eats
```

## ⚠ WARN — Anti-patterns

- **DO NOT** `jq 'select(.key=="X")' file.jsonl | head -1` — grabs first/oldest row, ignores drift corrections.
- **DO NOT** assume "the latest row is at the bottom of the file" — file may have been compacted, archived, or split; `effective_at` is the only reliable timestamp.
- **DO NOT** use `tail -1` for accretive files — same issue: ordering by file position, not by effective_at semantics. A correction might be inserted out-of-order during recovery.
- **DO NOT** read accretive JSONL without verifying the `effective_at` field exists. If the file doesn't carry `effective_at`, this discipline doesn't apply (use `ts` or document why ordering is implicit).

## ⇄ CROSS-LINK

### Sister doctrine / disciplines

- `~/.claude/projects/-Users-josh-Developer-flywheel/memory/feedback_topology_jsonl_take_latest_effective_at.md` (canonical memory source)
- L66 meat-puppet-orchestrator-decision-on-partial-state (same trauma class: read first surface without checking for newer state)
- `.flywheel/doctrine/forward-link-doctrine-doc-recipe.md` (the recipe used to author this doc)
- `.flywheel/doctrine/operator-library-recipe.md` (operator pipeline used in this doc per vbk3h)

### Surfaces where this discipline IS load-bearing

- `~/.local/state/flywheel/session-topology.jsonl` (3+ rows per session post-drift-correction)
- `~/.local/state/flywheel/loops/*.json` (state transitions)
- `~/.local/state/flywheel/lock-log.jsonl` (reserve → release sequence; latest action wins per path)
- any allowlist file with `superseded_by` semantics

### Surfaces NOT covered

- Append-only LEDGERS where every row is a distinct event (e.g.,
  `gap-hunt.jsonl` per-run results, `dispatch-log.jsonl` per-tick rows) —
  every row matters; `effective_at` doesn't supersede prior rows.

## Conformance (proof contract)

This doctrine is considered live when ALL of these hold:

1. ✓ Doctrine doc exists at `.flywheel/doctrine/jsonl-effective-at-sort-discipline.md`
2. ✓ Memory cross-link visible via `grep -l 'feedback_topology_jsonl_take_latest' .flywheel/doctrine/*.md`
3. ✓ Sister doctrine docs cited in cross-link section (L66 + forward-link-doctrine-doc-recipe + operator-library-recipe)
4. ✓ Canonical jq one-liner is copy-pasteable from `## ⬡ EXEMPLIFY`
5. ✓ Anti-pattern table covers the 4 documented failure modes

## Below-trauma-class tracking

| Instance | Date | Discipline-bypass cost | Outcome |
|---|---|---|---|
| 1 | 2026-05-05T02:48Z | dispatched reorient to wrong pane (mobile-eats orch confusion) | Joshua corrected; trauma recorded; memory authored |
| (future) | — | — | open: monitor for 2nd instance to flag as 2-strike pattern |

**Promotion threshold:** if a 2nd instance fires in the next 90 days,
file a sister bead for stronger mechanization (e.g., shell wrapper
`jsonl-latest-by-effective-at` exported on PATH, OR `dispatch-and-verify.sh`
auto-uses-latest-effective-at semantics by default).

## Sub-pattern (per forward-link-doctrine-doc-recipe)

This is a **1:1 forward-link** instance: single memory documents single
discipline that's load-bearing in 4 surfaces (topology + loop + lock-log +
allowlists). Sister-class-bundle is N/A (no cluster of related memories
discovered yet).

## Cross-references

- Source bead: flywheel-2xdi.153 (P3 gap-memory-without-cross-link)
- Canonical memory: `feedback_topology_jsonl_take_latest_effective_at.md`
- Sister recipe: `.flywheel/doctrine/forward-link-doctrine-doc-recipe.md` (pmg3c)
- Operator pipeline source: `.flywheel/doctrine/operator-library-recipe.md` (vbk3h — used for this doc's structure)
- Trauma anchor: L66 meat-puppet-orchestrator-decision-on-partial-state


## Meta-Learning Cross-References (2026-05-19)

This doctrine surface was backfilled during JSM fleet audit batch-3 so recent doctrine cites the relevant MP lessons directly.

- **MP-09 — info-source watchtower:** see `/Users/josh/Developer/skillos/.flywheel/doctrine/meta-learnings/MP-09-info-source-watchtower.md` for the canonical pattern.
- **MP-13 — living documentation:** see `/Users/josh/Developer/skillos/.flywheel/doctrine/meta-learnings/MP-13-living-documentation.md` for the canonical pattern.
- **MP-28 — checklist before claim:** see `/Users/josh/Developer/skillos/.flywheel/doctrine/meta-learnings/MP-28-checklist-before-claim.md` for the canonical pattern.
