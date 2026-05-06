# Cross-Cutting Skill Routing Amendments

Task: `amendment-cross-cutting-skill-routing-2026-05-06`
Bead: `flywheel-mission-lock-cross-cutting-skill-routing-amendments-2026-05-06`

## Scope

This implements the Phase 4 cross-cutting amendments from the r1 audit for
CSR-001 through CSR-006. The shipped surface is intentionally narrow:

- `.flywheel/scripts/dispatch-skill-router-collision-resolver.sh`
- `.flywheel/tests/test_dispatch_skill_router_collision_resolver.sh`
- `.flywheel/plans/mission-lock-paradigm-extension-2026-05-06/impl/cross-cutting-concerns-coverage.md`
- `INCIDENTS.md` additive shipped note
- `.beads/issues.jsonl` JSONL closure receipt

No audit reports, plan rounds, mission files, validation schemas, or skill
sources were changed.

## Finding Table

| ID | Audit Finding | Mitigation Shipped | Evidence |
|---|---|---|---|
| CSR-001 | Multiple bead-class tags lacked a deterministic merge rule. | Resolver uses ordered input, deterministic dedupe, collision receipts, strictest-invariant-wins notes, and prompt-budget pruning policy. | `dispatch-skill-router-collision-resolver.sh --json backend-endpoint database-migration` emits `backend_plus_database` and `strictest_data_auth_invariant_wins`. |
| CSR-002 | Discovery-source disagreement was under-specified. | Resolver stamps `source_precedence`: exact `get_skill`, local readable `SKILL.md`, semantic Socraticode, external `npx skills find` for installable discovery only, then `rg` fallback. | `--info` and JSON output include source precedence and disagreement policy. |
| CSR-003 | Skillos handshake was not a reliable protocol. | Missing exact skill routes enter degraded mode with `missing_skill_followup=true`, collision `missing_exact_skill_fallback`, and explicit degraded reason. | Test case `missing exact fallback is degraded with follow-up`. |
| CSR-004 | Stale or blocked skill references lacked receipt fields. | Resolver output includes selected skills, overlays, route status, source precedence, input tags, self-test gate, and degraded reason for stale/blocked paths. | JSON schema `dispatch-skill-router-collision-resolver/v1`. |
| CSR-005 | Cross-cutting overlays were missing from class routing. | Resolver adds independent overlays for agent-mail, observability, cost attribution, search-tool routing, and secret rotation. | Coverage map plus test case `cross cutting overlays are included`. |
| CSR-006 | Self-test could be gamed by counting skills instead of route quality. | Golden tests assert named collisions, overlays, negative fixture failure, CLI verbs, and route-health fields. | `.flywheel/tests/test_dispatch_skill_router_collision_resolver.sh`, 10 green cases. |

## Collision Rules

| Collision | Resolver Behavior |
|---|---|
| Backend plus database | Merges API, auth, database, operations, and data-quality skills; data/auth invariants win. |
| Substrate plus security plus CLI | Adds CLI scoping, scanner, secret handling, and `no_raw_secret_evidence=true`. |
| Docs/operator contract plus implementation | Adds documentation and golden-test skills; emits explicit skip receipt note. |
| Missing exact skill/fallback | Emits degraded status, source-routing overlay, and missing-skill follow-up flag. |

## Receipt Fields

Dispatch authors can consume the JSON fields directly:

- `schema_version`
- `input_tags`
- `skills`
- `overlays`
- `collisions`
- `notes`
- `source_precedence`
- `route_status`
- `self_test_gate`
- `missing_skill_followup`
- `degraded_mode_reason`
- `no_raw_secret_evidence`
- `prompt_budget_policy`

## Verification

Primary check:

```bash
test -f /Users/josh/Developer/flywheel/.flywheel/plans/mission-lock-paradigm-extension-2026-05-06/impl/cross-cutting-amendments-impl.md && \
  test -f /Users/josh/Developer/flywheel/.flywheel/plans/mission-lock-paradigm-extension-2026-05-06/impl/cross-cutting-concerns-coverage.md && \
  test -x /Users/josh/Developer/flywheel/.flywheel/scripts/dispatch-skill-router-collision-resolver.sh && \
  bash /Users/josh/Developer/flywheel/.flywheel/scripts/dispatch-skill-router-collision-resolver.sh --info > /dev/null 2>&1 && \
  bash /Users/josh/Developer/flywheel/.flywheel/tests/test_dispatch_skill_router_collision_resolver.sh > /dev/null 2>&1 && \
  grep -q "cross-cutting-skill-routing 6 findings mitigated" /Users/josh/Developer/flywheel/INCIDENTS.md && \
  echo OK_cross_cutting_amendments_shipped
```

Observed target: `OK_cross_cutting_amendments_shipped`.
