# Codex /goal-mode Bypass / Override Hatch Design — Paper Spec v0.1

**Status:** Paper-only, pre-Joshua-ratification
**Owner:** flywheel:1 authors, skillos:1 canonicalizes
**Joint-packet input:** YES

## Purpose

Layer 1 (czwpu) already has `CODEX_GOAL_FORMAT_BYPASS=<reason>` env-var override with audit ledger row. Layers 2/3/4 need a parallel hatch — but with different semantics because runtime enforcement is harder to legitimately bypass than dispatch-time prefix.

## Bypass classes (proposed)

| Class | Use case | Auth |
|---|---|---|
| `DISPATCH_TIME_BYPASS` | Layer 1 only (existing czwpu, no change) | env-var, audit-row |
| `RUNTIME_TRAUMA_SUPPRESS` | Suppress trauma fires for explicit test scenarios (fixtures, dry-runs, debugging) | env-var + dispatch-log row marker |
| `OPERATOR_OVERRIDE` | Orch explicitly accepts mode-bypass for one dispatch (e.g., codex one-shot probe, no /goal needed) | per-dispatch flag in dispatch-log row |
| `EMERGENCY_HALT_BYPASS` | When the monitor itself is broken/failing and blocking legitimate work | Joshua-direct only |

## Hatch surface

| Bypass class | Surface |
|---|---|
| `DISPATCH_TIME_BYPASS` | `CODEX_GOAL_FORMAT_BYPASS=<reason>` env-var (existing) |
| `RUNTIME_TRAUMA_SUPPRESS` | `CODEX_GOAL_MODE_TRAUMA_SUPPRESS=<reason>` env-var |
| `OPERATOR_OVERRIDE` | `{"goal_mode_required": false, "override_reason": "..."}` in dispatch-log row |
| `EMERGENCY_HALT_BYPASS` | `~/.local/state/flywheel/codex-goal-mode-monitor-disabled.flag` file with Joshua-signature |

## Audit ledger

Every bypass invocation writes to `~/.local/state/flywheel/codex-goal-mode-bypass-audit.jsonl`:

```json
{
  "ts": "2026-05-20T00:30:00Z",
  "bypass_class": "OPERATOR_OVERRIDE",
  "dispatch_id": "flywheel-c7t6k",
  "pane": 2,
  "session": "flywheel",
  "reason": "one-shot probe, no /goal needed",
  "authorized_by": "flywheel:1",
  "joshua_signature": null,
  "schema_version": "codex_goal_mode_bypass_audit.v1"
}
```

## Anti-abuse properties

1. **No silent bypass** — every bypass writes an audit row, EVERY layer (1+2+3+4) consults the audit ledger to verify the bypass row exists before suppressing trauma
2. **No retroactive bypass** — bypass must be present BEFORE the dispatch fires; post-hoc bypass rows are ignored
3. **Bypass-rate ceiling** — if any orch exceeds N bypasses per 24h (proposed N=5), trauma class `codex-goal-mode-bypass-abuse` fires alerting Joshua
4. **`EMERGENCY_HALT_BYPASS` requires Joshua-signature** — file presence alone isn't enough; the file must contain a Joshua-rotated signature (sha256 of timestamp + Joshua-secret per Infisical pattern)

## Open questions for joint codesign

1. Should `OPERATOR_OVERRIDE` require orch-peer-attestation (e.g., flywheel:1 + skillos:1 both sign) or single-orch attestation enough?
2. Should the bypass-rate ceiling be per-orch (5/24h) or per-session-pane (3/24h)?
3. Should `EMERGENCY_HALT_BYPASS` trigger automatic Joshua-page (Slack/SMS) or rely on dashboard surface only?
4. Symmetry with czwpu: should we backport the bypass-audit-row anti-abuse properties to Layer 1 as well?

— flywheel:1
