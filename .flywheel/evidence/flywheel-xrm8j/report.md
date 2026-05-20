# flywheel-xrm8j — JSM Substrate Replacement Sprint

## Scope

This closes the comparison sprint requested by `flywheel-xrm8j`: compare SQLite-WAL current state, Postgres, LMDB, and DuckDB for JSM ingest/search after the 2026-05-19 substrate incident.

Source context:
- `.flywheel/handoffs/20260519T2350Z-from-flywheel-to-skillos-jsm-discoverability-audit-substrate-replacement.md`
- `.flywheel/handoffs/20260520T0000Z-from-flywheel-to-skillos-jsm-search-blind-to-primary.md`
- `br show flywheel-eozi9 --json` duplicate body, which names the concrete sprint schema: comparison matrix, ingest latency probe, search latency probe, and malformation-class probability under concurrent load.

## Live Read-Only JSM Proof

`jsm search 'codex goal format' --json` now returns the expected `codex-goal-format-enforcement` v2 row while `~/.local/state/jsm/skills.db` is still 0 bytes.

Evidence: `.flywheel/evidence/flywheel-xrm8j/jsm-readonly-proof.json`

Important interpretation: the earlier cache-blindness observation was real for the 2026-05-19 handoff window, but current live search is no longer blind to the primary DB for that query. The 0-byte cache remains a recovery bug / stale surface, not proof of current total search blackout.

## Latency Probe

Command:

```bash
PYTHONPATH="/var/folders/d0/09qgt_0n1m1ff8nyzbxppx9c0000gn/T/flywheel-xrm8j.XXXXXX.WiD7yUDRjX/vendor" \
  python3 .flywheel/evidence/flywheel-xrm8j/substrate_probe.py \
  --rows 2000 \
  --tmp-dir /var/folders/d0/09qgt_0n1m1ff8nyzbxppx9c0000gn/T/flywheel-xrm8j.XXXXXX.WiD7yUDRjX/probe \
  --json-out .flywheel/evidence/flywheel-xrm8j/probe-results.json
```

Results:

| Substrate | Ingest ms | Search p50 ms | Search p95 ms | Probe status |
|---|---:|---:|---:|---|
| SQLite-WAL + FTS5 | 7.945 | 0.027 | 0.041 | ok |
| Postgres temp table + GIN FTS | 159.854 | 0.180 | 0.336 | ok |
| LMDB + in-probe inverted index | 22.044 | 0.088 | 0.181 | ok |
| DuckDB + LIKE search | 1157.894 | 0.815 | 1.061 | ok |

Probe limits:
- Synthetic 2,000-row JSM-shaped dataset, not a production replay.
- Postgres uses only temp tables against `postgresql://josh@localhost:5432/postgres`.
- LMDB result includes a small purpose-built inverted index; a real migration must define that index contract.
- DuckDB probe intentionally uses simple hot-path lookup semantics; DuckDB is stronger for analytics than high-frequency control-plane mutation.

## Comparison Matrix

| Dimension | SQLite-WAL current | Postgres | LMDB | DuckDB |
|---|---|---|---|---|
| Raw local ingest/search latency | Best in probe | Good enough; sub-ms p95 search | Strong | Weakest ingest in probe |
| Concurrent readers + writers | Fragile under observed fleet pressure; 72 malformation events in source handoff | Strong MVCC fit | Single writer; many readers; caller must serialize writes | Single-writer-oriented; not a hot OLTP fit |
| Malformation-class probability under current load | High, by observed incident history | Low for this class; no SQLite file-image corruption class | Low for this class; memory-mapped single-writer file, but file-copy discipline matters | Low for SQLite malformation class, but lock/contention class likely |
| Cache / primary drift class | Present in current architecture | Removed if JSM uses one canonical table/index source | Removed if one environment is canonical; reintroduced if external cache added | Removed if one file is canonical; less suitable for live search updates |
| Recovery ergonomics | Per-file, per-surface recovery; easy to recover one surface and miss another | `pg_dump` / `pg_restore`, WAL, transactional rebuilds | Snapshot copy under no-writer gate | File copy/checkpoint; good analytics snapshot story |
| Operational fit for Joshua stack | Misaligned with repo default for control-plane state | Best aligned | Good embedded fallback | Good analytical sidecar, not primary |
| Migration complexity | None, but leaves incident class | Moderate: schema, migration shim, local service dependency | Moderate-high: custom index/search schema | Moderate: query rewrite, concurrency caveats |

## Recommendation

Default candidate: **Postgres**.

Reason: SQLite-WAL wins the synthetic speed probe, but the real incident is not normal-case speed. The failure class is control-plane durability under fleet concurrency, recovery coupling, and cache/primary drift. Postgres removes the SQLite malformed-file class and gives one canonical transactional surface with MVCC for concurrent intake/search. Its measured p95 search latency, 0.336 ms on the synthetic probe, is well inside a control-plane budget.

Fallback: **LMDB** if SkillOS rejects a local Postgres dependency for JSM. LMDB is fast and eliminates SQLite-WAL malformation, but it pushes index/schema correctness into application code and requires strict single-writer discipline.

Do not choose DuckDB as the primary JSM substrate. It is useful for append-only analytics and offline corpus inspection, but its write profile is a poor match for hot ingest plus CLI search.

Do not retain current SQLite-WAL as the primary substrate without changing the architecture. Tuning `busy_timeout`, WAL, and `synchronous=NORMAL` does not address the observed two-surface recovery bug or the 72-event malformation history.

## Acceptance Checklist

1. Comparison matrix: complete above.
2. Ingest latency probe: complete in `.flywheel/evidence/flywheel-xrm8j/probe-results.json`.
3. Search latency probe: complete in `.flywheel/evidence/flywheel-xrm8j/probe-results.json`.
4. Malformation-class probability under concurrent load: assessed in the matrix using observed incident history plus concurrency model.
5. Joshua-gate + SkillOS codesign boundary: no JSM mutation performed; recommendation is report-only and remains codesign-gated.

## Skill Auto-Routes

`canonical-cli-scoping=yes`: the probe has `--json-out`, explicit options, non-interactive execution, and stable zero/non-zero process behavior. Doctor/repair/dry-run surfaces are not applicable because this is an evidence probe, not a shipped operator CLI.

`rust-best-practices=n/a`: no Rust files touched.

`python-best-practices=yes`: probe uses typed public helpers, temp paths for file substrates, and remains under 400 lines.

`readme-writing=n/a`: no README touched.

## L52 / Skill Discovery

No new bead filed. Reason: all material gaps are already covered by the active substrate-replacement beads and SkillOS mirror (`skillos-knge7`), plus the storage correlation/halt coordination beads named in the source handoff. The live-read-only proof changes the current state from "search fully blind" to "cache still zero but primary-backed search returns expected row"; that is evidence for the same recovery/coupling class, not a new independent gap.

Skill discoveries: 0. No reusable skill gap beyond the existing canonical-cli-scoping / storage-substrate doctrine surfaced.

## Four-Lens Self-Grade

four_lens=brand:9,sniff:8,jeff:8,public:8

- Brand: favors Joshua's stated Postgres default while preserving measured tradeoffs.
- Sniff: separates fast benchmark numbers from the actual failure class.
- Jeff: uses explicit probes, JSON evidence, and stable callback-ready artifacts.
- Public: Three Judges check passes for a skeptical operator, maintainer, and future worker because every recommendation maps to a probe or source handoff.
