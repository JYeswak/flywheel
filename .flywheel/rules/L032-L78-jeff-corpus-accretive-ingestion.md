## L78 — JEFF-CORPUS-ACCRETIVE-INGESTION

---
id: L78
title: Jeff corpus accretive ingestion
status: long_term
shipped: 2026-05-04
review_due: 2026-11-04
trauma_class: bulk-ingest-without-maintenance-plan
---

The Jeff corpus is a maintained learning substrate, not a one-shot bulk index.
After a full verified baseline exists, ongoing ingestion MUST use frozen
baseline + daily SHA diff watcher + diff-only delta indexing + weekly
compaction + doctor storage budget signal.

**How to apply:**
- Baseline state lives at `.flywheel/jeff-corpus/v1/manifest.json` with one row
  per Jeff repo: repo, git SHA, last indexed timestamp, chunk count, repo size,
  and content hash set.
- Daily 03:00Z watcher `.flywheel/scripts/jeff-corpus-diff-watcher.sh` compares
  upstream HEAD to the manifest SHA and writes only changed repos to
  `.flywheel/jeff-corpus/pending-reindex.jsonl`.
- `.flywheel/scripts/jeff-corpus-delta-reindex.sh` uses
  `git diff <old_sha> <new_sha> --name-only` and content-hash deduplication; it
  MUST NOT full-reindex unchanged files.
- Sunday 04:00Z compaction `.flywheel/scripts/jeff-corpus-compact.sh` merges
  v1+v2 into the next baseline, drops superseded chunks, and retires old
  manifests/delta rows to cold storage.
- `flywheel-loop doctor --json` MUST expose `jeff_corpus_v1_total_mb` and
  `jeff_corpus_storage_health` (`GREEN|YELLOW|RED`). RED blocks new ingestion
  until compaction runs.

**Forbidden outputs:**
- "Reindex all Jeff repos nightly" or any recurring full-corpus maintenance
  path after the verified baseline exists.
- Calling Jeff corpus ingestion complete without a manifest, pending queue,
  delta-only path, compaction path, doctor storage signal, and tests.
- Treating a docs-only schedule recommendation as implementation proof without
  the watcher script and deterministic fixture coverage.

**Evidence:** bead `flywheel-15dg`; memory
`feedback_accretive_corpus_ingestion.md`; completed 177/177 Qdrant verification
in `/tmp/jeff-corpus-truth-state.md`; tests `tests/jeff-corpus-accretive.sh`.

**Companion rules:** L60 (doctor signal contract), L63 (Jeff substrate
dependency), L64 (Jeff pattern mining), L72 (storage discipline), L77 (daily
learning rollup), `info-source-watchtower`, `vector-ingest-verification`, and
`qdrant-ops`.

