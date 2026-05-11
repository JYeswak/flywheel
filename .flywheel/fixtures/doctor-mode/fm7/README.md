# FM-7: topology-resolved-pane mismatch

**Class:** substrate-config (resolver drift)
**Test mode:** SKIPPED-fixture-ready (no `_flywheel_loop_fm7_detect_fix` function in flywheel-loop; detect lives in session-topology resolver upstream)
**MEMORY source:** `feedback_topology_lookup_before_dispatch.md` — session-orchestrator-map is authoritative; resolver MUST align.

## Detect predicate
- Read topology row
- If `resolved_pane != session_orchestrator_map` → MISMATCH (resolver diverged)

## Fix strategy
- Realign `resolved_pane` to `session_orchestrator_map` value
- Emit `reconciled_from` + `reconciled_reason` + `reconciled_at` provenance
- Audit-trail preserves divergence event

## Fixture files
- `corrupt-topology.jsonl` — resolver returned `0.2`; orch-map says `0.1` (the FM-7 signature)
- `expected-resolved.jsonl` — realigned to `0.1` with reconciliation provenance
- `undo-original.bak` — byte-exact baseline
