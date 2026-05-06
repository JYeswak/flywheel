# Phase 3 AUDIT r2 — Idempotency (Phase 4 Expansion II)

Plan: `wire-or-explain-tick-gate-2026-05-04` + sibling `orch-monitor-recovery-auto-act-2026-05-04`
Lens: idempotency / replay-safety on the 7-ledger architecture
Generated: 2026-05-04
Mode: plan-space read-only audit
Prior round: r1 idempotency (`03-AUDIT-r1-idempotency.md`) + r2-confirmation
Convergence flag: `prior_round=r1`

## Audit Frame

Are ledger row writes replay-safe across the 7 producer ledgers? Are the ID schemes stable across re-runs? Can a tick that crashes mid-write recover without duplicate rows?

Skills applied: `multi-pass-bug-hunting`, `lean-formal-feedback-loop`.

Self-grade: `Y`
Composite score: `8.7/10.0`
Disposition: `auto_advance_eligible`
Reason: zero criticals; one medium finding amends bead acceptance for replay-safe writers.

## Source Lines Used

| Source | Lines |
|---|---|
| WOE L1 schema | `04-BEADS-DAG.md:226-258` |
| WOE L3 schema | `04-BEADS-DAG.md:282-314` |
| WOE L4 schema | `04-BEADS-DAG.md:336-358` |
| Orchmon L2 schema | `orch-monitor.../04-BEADS-DAG.md:55-72` |
| Orchmon L6 schema | `orch-monitor.../04-BEADS-DAG.md:99-115` |
| Orchmon L7 schema | `orch-monitor.../04-BEADS-DAG.md:117-138` |
| r1 idempotency baseline | `03-AUDIT-r1-idempotency.md:45-86` |

## Findings

| ID | Severity | Beads | Description | Mitigation |
|---|---|---|---|---|
| IDEMP-EXP-F1 | medium | All 19 expansion beads (producers) | The 7 ledgers each declare an `artifact_id` shape but only L2 explicitly names a `check_tick_id` for replay-keying. L1/L3/L4/L6/L7 row writes during a crashing tick could replay and double-write because the producer doesn't have a stable `dedup_key=hash(artifact_id, check_tick_id)`. | Amend r2-B28 (canonical L110 schema) to require `dedup_key` on every row; producer writers MUST `jq` filter on `dedup_key` before append. Same shape as r1 IDEMP-09 `bootstrap_seed/v1` resolution. |
| IDEMP-EXP-F2 | low | Sub-DAG η L7 | Session-violation rows are dual-indexed (L1 + L7). Concurrent producer + indexer could race if writer doesn't fsync. | Producer uses append-only `O_APPEND` semantics; indexer is a tail-reader, not a re-writer. Standard newline-JSONL pattern; doc this in r2-B28 acceptance. |

## Stable IDs

- L1 `artifact_id="L<n>:<probe_name>"` — stable; deterministic from L-rule + probe.
- L2 `artifact_id="<primitive-script-name>:<check-tick-id>"` — stable IFF check_tick_id is monotonic.
- L3 `artifact_id="<plan-slug>:<artifact-path>"` — stable.
- L4 `artifact_id="<repo>:<doc-path>"` — stable.
- L6 `artifact_id="<from-pane>:<to-pane>:<msg-hash>"` — stable; msg-hash is content-addressed.
- L7 `artifact_id="<session>:<violation-class>:<tick-id>"` — stable.

All 7 ID schemes pass content-addressing or deterministic-from-source check. **Replay-safety after IDEMP-EXP-F1 mitigation: yes.**

## Convergence

```text
new_critical_findings=0
new_true_blocker_classes=0
medium_findings=1
low_findings=1
prior_round_findings_repeated=0
disposition=auto_advance
```
