---
title: "Jeff-Corpus Substrate Lifecycle: Indexed Data vs Source Bulk"
type: doctrine
created: 2026-05-11
frontmatter_source: scaffold-doc-frontmatter
---

# Jeff-Corpus Substrate Lifecycle: Indexed Data vs Source Bulk

Version: `jeff-corpus-substrate-lifecycle/v1`
Owner: storage-discipline + jeff-corpus indexing operators
Status: canonical, shipped 2026-05-11
Source bead: flywheel-2xdi.116 (memory-without-cross-link wire-in)

## TL;DR

The jeff-corpus has **two substrate classes with different lifecycle
discipline**:

| Substrate | Path | Class | Disposable? |
|---|---|---|---|
| Indexed embeddings (socraticode) | `~/.socraticode/qdrant-data/` | LOAD-BEARING | NO |
| Indexed embeddings (jeff-stack) | `~/.knowledge/qdrant_server_storage/` | LOAD-BEARING | NO |
| Indexed embeddings (openai) | `~/.knowledge/qdrant_storage_openai/` | LOAD-BEARING | NO |
| Source corpus | `~/Developer/jeff-corpus/<~180 repos>` | DISPOSABLE | YES (under invariant) |

Joshua's 2026-05-07 directive: *"we don't want to delete jeff-corpus —
we want the indexed stuff to stay but the bulk of the repos — as long
as our indexed data doesn't leave — can go."*

## Canonical memory source

This doctrine summarizes
`feedback_jeff_corpus_indexed_data_separates_from_source.md` — the
META-RULE memory documenting the dual-substrate discipline. Read the
memory for full table + doctor-invariant phrasing + reindex workflow.

## Why it works

`socraticode` and the knowledge stack mine source repos at indexing
time, embedding chunks into qdrant collections. After indexing, the
source repo on disk is **redundant** for socraticode lookups —
`mcp__socraticode__codebase_search` queries qdrant, not the original
files. Source disk only matters for:

1. **Modifying** a repo (rare for jeff-corpus — we don't push to Jeff's repos)
2. **Re-indexing** after upstream changes (re-clone first, then index)
3. **Reading raw source** for non-search tasks (browsing, manual grep)

Most jeff-corpus reads happen via socraticode. Source bulk is therefore
pruneable under the invariants below.

## Doctor invariants (canonical)

A `flywheel doctor` probe MUST emit these signals:

- `jeff-corpus on disk + indexed-data missing` → **ALERT** (embeddings
  lost; source is now load-bearing again, do NOT prune)
- `jeff-corpus missing + indexed-data present` → **GREEN** (correct
  steady-state after disk reclaim)
- `jeff-corpus present + indexed-data present` → **GREEN** (working
  state; source pruneable when storage pressure rises)
- `jeff-corpus missing + indexed-data missing` → **CRITICAL** (both
  substrates lost; re-clone + re-index required)

## Storage-prune integration

`flywheel:storage-prune` may include `~/Developer/jeff-corpus/` in
recurring auto-prune ONLY when **both** of these exist with non-zero size:
- `~/.socraticode/qdrant-data/`
- `~/.knowledge/qdrant_server_storage/`

Optionally:
- `~/.knowledge/qdrant_storage_openai/` (third indexed embeddings store)

Without this invariant, auto-prune is a class-5 (irreversible) action.
With the invariant, the source bulk reclassifies to class-1 (reversible
— re-clone is trivially available from `gh repo clone Dicklesworthstone/<name>`).

## Re-index workflow

When a specific jeff repo needs fresh embeddings (upstream changes, new
release, etc.):

```bash
# Don't permanently re-clone into ~/Developer/jeff-corpus/
TMP=$(mktemp -d -t jeff-reindex.XXXXXX)
cd "$TMP"
gh repo clone Dicklesworthstone/<repo>
# Run socraticode serial-index wrapper against $TMP/<repo>
# After indexing completes, the source clone in $TMP is no longer needed
```

This keeps the canonical state: source on disk is operator-on-demand,
indexed embeddings stay load-bearing.

## Sister doctrine + memory

- Memory `feedback_jeff_corpus_indexed_data_separates_from_source.md`
  (above-cited canonical source)
- `.flywheel/scripts/disk-reclaim-batch-2026-05-07.sh` Phase 3 — the
  empirical reclaim that anchored the directive
- Storage-discipline cluster: `.flywheel/PLANS/storage-discipline-consolidation/README.md`
  (sister inventory; SBH consolidation work documents which storage
  scripts are STILL NEEDED — including the corpus projection class)
- `feedback_storage_pressure_blocks_substrate` (sister memory in
  cluster; same Joshua-2026-05-07 timeframe)

## Conformance

A storage-discipline action involving jeff-corpus proves conformance
via one of:
- Receipt cites both indexed-data invariants probed BEFORE source-prune
- Receipt is gated on doctor-invariant `jeff-corpus missing +
  indexed-data present = GREEN`
- Receipt is an explicit re-index workflow (clone to /tmp; do NOT
  permanently re-clone into ~/Developer/jeff-corpus/)

## Anti-pattern

Treating `~/Developer/jeff-corpus/` as load-bearing without first
probing the indexed-embeddings substrate. Auto-prune without invariant
check is class-5 irreversible if both substrates accidentally vanish
during the same window.


## Meta-Learning Cross-References (2026-05-19)

This doctrine surface was backfilled during JSM fleet audit batch-3 so recent doctrine cites the relevant MP lessons directly.

- **MP-09 — info-source watchtower:** see `/Users/josh/Developer/skillos/.flywheel/doctrine/meta-learnings/MP-09-info-source-watchtower.md` for the canonical pattern.
- **MP-13 — living documentation:** see `/Users/josh/Developer/skillos/.flywheel/doctrine/meta-learnings/MP-13-living-documentation.md` for the canonical pattern.
- **MP-28 — checklist before claim:** see `/Users/josh/Developer/skillos/.flywheel/doctrine/meta-learnings/MP-28-checklist-before-claim.md` for the canonical pattern.
