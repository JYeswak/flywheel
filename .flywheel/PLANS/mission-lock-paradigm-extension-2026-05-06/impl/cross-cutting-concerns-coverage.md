# Cross-Cutting Concerns Coverage

Task: `amendment-cross-cutting-skill-routing-2026-05-06`
Resolver: `.flywheel/scripts/dispatch-skill-router-collision-resolver.sh`

## Coverage Map

| Concern | Trigger Tags | Skills/Overlay | Receipt Fields | Failure Mode Covered |
|---|---|---|---|---|
| Agent-mail coordination | `agent-mail`, `mail`, `reservation`, `callback`, `receipt`, `jsonl`, `concurrent`, `shared`, `parallel`, `coordination` | `agent-mail` | `overlays`, `skills`, `input_tags` | Dispatches that edit or coordinate without reservation/callback discipline. |
| Observability and monitoring | `observability`, `monitoring`, `telemetry`, `metric`, `health`, `runtime`, `watchtower`, `doctor`, `loop` | `agent-monitoring` | `overlays`, `route_status`, `self_test_gate` | Runtime work that lacks health and telemetry hooks. |
| Cost attribution | `cost`, `budget`, `spend`, `token`, `model`, `gpu`, `attribution` | `cost-attribution` | `overlays`, `skills` | Provider/model changes without cost visibility. |
| Search-tool routing | `search`, `skill`, `discovery`, `exact`, `semantic`, `router`, `route`, `source` | `search-tool-routing-doctrine` | `source_precedence`, `overlays`, `degraded_mode_reason` | Exact/local/semantic/external disagreement and stale catalog drift. |
| Secret rotation and credential safety | `security`, `auth`, `credential`, `secret`, `rotation`, `token`, `bearer`, `infisical` | `authentication-authorization`, `mcp-secret-scanner`, `infisical-secrets` | `no_raw_secret_evidence`, `overlays`, `skills` | Raw secret evidence in dispatch receipts or security work without scanner coverage. |

## Global Rules

1. `socraticode` is always selected because dispatches must survey repo context
   before new design or implementation work.
2. Exact/local discovery wins over semantic routing; external `npx skills find`
   is for installable ecosystem discovery only.
3. Collision handling is deterministic: preserve input order, dedupe, apply the
   strictest invariant, then prune prompt material to risk-bearing excerpts.
4. Missing exact skills are degraded, not silent: emit `missing_skill_followup`,
   `missing_exact_skill_fallback`, and a degraded reason.
5. Negative route-health fixtures must fail. A resolver that only counts skills
   is not accepted.

## Golden Cases

| Case | Tags | Expected Coverage |
|---|---|---|
| Backend plus database | `backend-endpoint database-migration` | API, auth, database, operations, data-quality, `backend_plus_database`. |
| Substrate/security/CLI | `substrate-fix security cli` | CLI scoping, scanner, config, monitoring, `no_raw_secret_evidence=true`. |
| Docs plus implementation | `docs operator-contract implementation` | Docs/operator overlay, golden tests, explicit skip receipts. |
| Missing exact fallback | `missing-skill schema-complete-drift-guard` | Degraded mode, search routing, skillos follow-up flag. |
| Cross-cutting overlays | `agent-mail observability cost secret-rotation search` | Agent-mail, monitoring, cost, secret, search overlays. |
| Negative fixture | `irrelevant no-source blocked` | `route_status=fail`, `self_test_gate=fail`. |

## Dispatch Author Contract

Dispatch authors should attach the resolver JSON to dispatch packets or receipts
when bead-class tags overlap. Minimum fields to preserve:

- `skills`
- `overlays`
- `collisions`
- `source_precedence`
- `route_status`
- `self_test_gate`
- `missing_skill_followup`
- `no_raw_secret_evidence`
