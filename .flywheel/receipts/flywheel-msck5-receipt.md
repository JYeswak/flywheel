# flywheel-msck5 Receipt

## Scope

Split Agent Mail identity registry topology drift into two operator-facing signals:

- `raw_topology_drift_count`: raw latest-row topology comparison before sparse `repo_path` merge.
- `confirmed_unreachable_session_count`: active identity rows absent from merged topology and absent from live `ntm health` proof.

The compatibility field `agentmail_orphan_session_rows_count` now maps to confirmed unreachable rows, not raw topology drift.

## Gates

1. **Doctor split fields exposed**: `identity --doctor --json` now emits `raw_topology_drift_count`, `topology_drift_unvalidated_count`, and `confirmed_unreachable_session_count`.
2. **Loop doctor relabeled**: doctor postcheck fails on `agentmail_confirmed_unreachable_session_count`; unconfirmed raw drift is labeled `topology_drift_unvalidated`.
3. **Sparse topology migration preserved panes**: latest sparse `repo_path` rows merge missing pane fields from the latest pane-bearing row, with `topology_sparse_merge_count` receipts.
4. **ALPS/flywheel source of truth aligned**: the live flywheel identity doctor now reports raw drift separately from confirmed unreachable rows:

```json
{
  "status": "pass",
  "raw_topology_drift_count": 16,
  "topology_drift_unvalidated_count": 0,
  "confirmed_unreachable_session_count": 0,
  "agentmail_orphan_session_rows_count": 0,
  "topology_sparse_merge_count": 7
}
```

5. **Regression fixture added**: `tests/test_agentmail_identity_raw_vs_confirmed_orphans.sh` covers repo_path-only migration rows plus fixture-backed live NTM proof.

## Validation

- `tests/test_agentmail_identity_raw_vs_confirmed_orphans.sh` passed.
- `tests/agent-mail-identity-registry.sh` passed: 15 passed, 0 failed.
- `rg` proof found the new split fields across `identity.sh`, `core.sh`, `doctor.sh`, and tests.

## Joshua-Lens Check

This fixes an operator-trust failure: two doctors appeared to disagree after a successful sweep. A real ops team cannot run for years on metrics where "orphan" sometimes means "raw ledger drift" and sometimes means "confirmed unreachable runtime." The split is turnover-resilient because a new operator can read the field name and know whether the signal is an observation, a warning, or an actionable failure.
