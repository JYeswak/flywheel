# Journey entry — flywheel-k8gcv

**Bead**: P0 doctor-mode-integration-2-wave-3 — **decomposition bead** (not surface work).
**Parent**: flywheel-jloib (canonical-cli baseline lane).
**Disposition**: filed 27 per-binary sub-beads (flywheel-k8gcv.1 → .27) following wzjo9.1.{1..9} pattern.
**Result**: 27/27 sub-beads filed; 1000/1000.

## Arc

1. **Read bead + apply-spec** at `.flywheel/audit/flywheel-jloib/wave-3-apply-spec.md`. Spec mandated "file 27 per-binary sub-beads at wave dispatch."
2. **Verified all 27 surfaces exist** on disk. 0 missing.
3. **Filed 27 sub-beads** via `br create -p P0 --parent flywheel-k8gcv --silent "[wave-3-NN] <surface> canonical-cli partial->passing (lane)"`. IDs landed sequentially flywheel-k8gcv.1 → .27.
4. **Caught inventory staleness**: surface #26 (`flywheel-verdict`) inventory.jsonl row still shows `status:"partial"` but was actually fully filled by sister bead wzjo9.1.4 (commit a7a85a2, 1000/1000, 32/32 regression assertions). Worker on flywheel-k8gcv.26 should verify AG3 + update inventory row as "already_canonical_via_wzjo9.1.4".
5. **Compliance pack** preserves the 27-surface idx/lane/surface/bead-id mapping in `subbeads.tsv` for any future regrouping or batch dispatch.

## Discoveries

None new — wzjo9 wave-2.0a sub-bead decomposition pattern reapplied at wave-3 scale. The natural-unit META-RULE called for decomposition (27 × 30-60min = 13-27h cumulative); one-bead-per-binary is the right granularity.

## Sister pattern continuity

| Wave | Decomposition bead | Sub-beads | Surface state |
|---|---|---|---|
| 2.0a | flywheel-wzjo9.1 (parent) | 9 sub-beads (wzjo9.1.1-.9) | **missing** → full scaffold + 18-TODO fillin (~30-60min each) |
| 2.0b | flywheel-wzjo9.2 (parent) | 9 sub-beads (wzjo9.2.1-.9) | **missing** → full scaffold + 18-TODO fillin |
| **3** | **flywheel-k8gcv (this)** | **27 sub-beads (k8gcv.1-.27)** | **partial** → fill gaps only (lighter lift) |

Wave-3 is broader scope (27 vs 9) but lighter per-binary (gaps vs full scaffold). Sister exemplars from wzjo9.1.{1..9} avg 982/1000 give the worker template.

## Sub-bead worker template (carry-forward)

Each sub-bead worker:
1. Reserve target file
2. Inspect → identify which canonical-cli surfaces (--info / --schema / --examples) are present vs missing
3. Manual fill of gaps (NOT full scaffold — surface already has partial signals)
4. Verify AG3: `<bin> --info|--schema|--examples --json` each emit valid envelope
5. Update inventory.jsonl row partial → passing
6. canonical-cli-lint + sister regressions
7. Compliance pack + journal + commit + close + DONE callback

## Next phase

27 sub-beads queued. Suggested dispatch order:
- Batch by lane (5 capacity together, 12 jeff-corpus together, 2 each for beads/doctrine/mission/orchestration, 1 each for recovery/testing)
- OR priority-by-frequency-of-use: orchestration + capacity surfaces first (most-invoked) → jeff-corpus (highest count) → others

flywheel-k8gcv.26 (flywheel-verdict) can be closed quickly as already-done; opens slot for next batch.
