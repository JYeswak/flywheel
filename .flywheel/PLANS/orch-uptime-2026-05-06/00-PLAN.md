---
title: "Orchestrator Uptime + Auto-Credential-Rotation — Synthesized Plan"
type: plan
created: 2026-05-08
frontmatter_source: scaffold-doc-frontmatter
---

# Orchestrator Uptime + Auto-Credential-Rotation — Synthesized Plan

**Plan slug:** `orch-uptime-2026-05-06`
**Phase:** 2 (REFINE) → ready for Phase 3 audit
**Inputs:** Lane A (`/tmp/orch-uptime-laneA-detector-primitive-2026-05-06.md`), Lane B (`/tmp/orch-uptime-laneB-topology-watcher-2026-05-06.md`), Lane C (`/tmp/orch-uptime-laneC-integration-wire-or-explain-2026-05-06.md`).

## Mission anchor

`continuous-orchestrator-uptime-self-sustaining-fleet`

## Trauma class

`frozen-projection-of-mutable-state` — Lane C codified. Today's failures (topology stale 5d / cron-literal blocker_id 2d / capacity-gate refusing recoveries) are the same class. The cure is the canonical L-rule **`templates-name-sources-not-values`** (sibling of SEC-001, L116, L57, L110).

## Donella trace (synthesis)

- **Boundary:** detector → authorization gate → recovery primitive → respawn primitive → tick refresh → next-tick-observes-health.
- **Stock:** continuously-productive orch panes + fresh topology + executable recovery primitives + drained WOE rows.
- **Flow break (3-way):** (a) `codex_usage_limit` not a detector subclass → no recovery loop; (b) topology freshness has no scheduled writer → gate refuses every recovery; (c) WOE ledger absent → close-gate cannot prove any row drained.
- **Loop:** detect → authorize (per recovery class) → repair → fresh stock → next tick proves health.
- **Leverage:** Meadows #5 rules (new subclass + new recovery class + L-rule promotion) + #6 information flow (tick-refresh + WOE bootstrap) + #4 self-organize (caam vault swap is flywheel-decided per memory rules).
- **Intervention:** 3-lane stage-split shipping (below).
- **Measurement:** `topology_max_age_sec_after < gate_TTL`, `codex_usage_limit_recovered_24h`, `frozen_projection_count`, `woe_ledger_present`, `topology_stale_refusal_rate`.

## Stage-split shipping contract (Lane C's load-bearing finding)

Lane A's vault rotation does NOT depend on topology freshness. Lane B's topology refresh enables ALL pane-touching recoveries. Lane C's L-rule + invariant is doctrine independent of both.

| Stage | Topology required? | Owner | Notes |
|---|---|---|---|
| `credential_rotate` (vault-only) | NO | Lane A | New `recovery_class=credential_rotation` bypasses topology-stale gate |
| `verify_profile_active` | NO | Lane A | Read-only `caam status` |
| `topology_refresh` (pure-freshness) | n/a (writes it) | Lane B | Wired into tick-driver, append-only, latest-wins |
| `recover_pane_after_rotation` | YES (fresh) | Lane B prereq | All pane-touching recoveries gated on fresh topology |
| `drain_woe_row` | YES (ledger present) | Lane C | Bootstrap the canonical ledger first |

**Parallel-safe at research level.** Implementation must observe stage gating: Lane A's primitive can ship and authorize independently; Lane B's tick-refresh must ship before Lane B's pane-respawn-after-rotation can be claimed safe; Lane C's L-rule is doctrine-only and ships independently.

## What's already built (do NOT rebuild)

- Detector v1.2.0 (3 subclasses + auto-recover dispatch table + safe-recovery-policy)
- Capacity-halt-pane-authorization gate (consumes latest topology row)
- Recovery-doctor-probe + canonical recovery-ledger.schema.json
- Peer-orch-respawn-permit + peer-orch-freeze-monitor (L115/L117)
- Tick-driver L116 + tick-driver-manifest.json
- caam CLI (`caam ls/list/activate/status` all `--json`)
- Wire-or-explain close-gate + writer doctor + fault-injection FM1-FM6 fixtures
- Stale-error-auto-ping (L87, temporary, sunset bead `flywheel-pp1g` open)
- launchctl-guard + flywheel-watchers register/registry/doctor

## What's NEW (3 lanes converged)

### From Lane A — Detector + Vault Primitive
1. `codex-template-stuck-detector.sh` v1.2.0 → v1.3.0: add `codex_usage_limit` subclass + 6-pattern regex bank + classifier ordering BEFORE `model_at_capacity_halt`
2. NEW `.flywheel/scripts/caam-auto-rotate-on-usage-limit.sh` (220 lines, dry-run default, `--apply` for mutation, idempotency by `tool:session:pane:digest`, `caam list || caam ls` fallback, post-check `caam status`, returns rc=0|2|3|4)
3. Extend `capacity-halt-pane-authorization.sh` with `--recovery-class credential_rotation` that authorizes regardless of topology staleness (vault selector swap is independent of pane role)
4. Extend `recovery-ledger.schema.json` with optional `recovery_class` enum + `profile_selector` object (no breaking changes to existing rows)
5. NEW test `.flywheel/tests/test_caam_auto_rotate_on_usage_limit.sh` with 18 cases including topology-stale-with-credential-rotation interaction
6. Fake CAAM binary fixture (no live mutation in tests)

### From Lane B — Topology Freshness + Watcher Load
1. NEW `.flywheel/scripts/topology-tick-refresh.sh` (append-only-latest-wins; refuses on shape-change with 7 explicit refusal classes; emits `topology_shape_hash` + `refresh_reason=pure_freshness`)
2. Wire into `flywheel-loop-tick` AFTER L102 meta-rule sync, BEFORE all topology-consuming gates
3. Add `topology-tick-refresh` to `tick-driver-manifest.json`
4. Register the 2 unloaded plists via `flywheel-watchers register --apply` with idempotency keys (`com.flywheel.shutdown-recovery`, `ai.zeststream.flywheel-idle-pane-watch`)
5. Patch `mobile-eats-flywheel-loop-tick` line 83: `(( $# >= 8 )) ||` arity guard before positional `local`
6. Sub-bead: `flywheel-watchers doctor launchctl` should count `com.flywheel.*` scope (currently only `ai.zeststream.flywheel-*`)
7. NEW test `tests/topology-tick-refresh.sh` (16 cases including ordering fixture + watcher idempotency + mobile-eats arity)

### From Lane C — Doctrine + Invariant + WOE Bootstrap
1. NEW canonical L-rule `templates-name-sources-not-values` (forbidden-literals matrix + allowable-literals matrix in deliverable lines 130-131)
2. NEW `.flywheel/scripts/frozen-projection-invariant-scan.sh` (5 scan input groups, 5 flag patterns, 5 allow patterns, doctor output fields)
3. WOE ledger bootstrap (separate substrate bead — `~/.local/state/flywheel/wire-or-explain-ledger.jsonl` doesn't exist; close-gate currently passes empty as bootstrap)
4. L87 sunset coordination (do NOT close yet — `flywheel-pp1g` in_progress + fresh divergence rows on flywheel:1 today)
5. Cross-coordinate detector edits with open P0 bead `flywheel-wire-codex-queued-not-submitted-classifier-and-recovery-2026-05-06` (same file)
6. Sibling pattern absorption: skillos cron-literal + flywheel topology-stale = single canonical rule, single fleet sweep
7. NEW test fixture `.flywheel/tests/test_frozen_projection_invariant.sh` (10 cases including L-rule allow/forbid, mobile-eats arity, source-name vs literal-value cron)

## TRUE Joshua-blocker class check (per Phase 4 contract)

| Class | Verdict | Why |
|---|---|---|
| 1. new-platform-or-vendor-not-in-mission-lock | **None fire** | All work uses existing platforms (codex, caam, ntm, launchd) |
| 2. secret-rotation-or-new-credential-creation | **None fire** | caam activate is vaulted-profile-selector swap per memory rule `feedback_caam_activate_is_flywheel_decided_not_joshua_gated.md` |
| 3. financial-commitment-above-mission-budget | **None fire** | $0 spend |
| 4. legal-or-compliance-decision | **None fire** | No new ToS, no DPA, no legal weight |
| 5. destructive-irreversible-on-shared-state | **None fire** | All changes are append-only-ledger, file-add, or extension; reversible via git revert |
| 6. paradigm-conflict-with-active-mission | **None fire** | Continues 2026-05-04 self-sustaining-company paradigm |

**Disposition: `auto_advance` to Phase 4 decompose.** Joshua paged ONLY if Phase 3 audit surfaces critical findings mapping to a true class.

## Cross-orch coordination

- **skillos:1** owns implementation half of cron-literal-payload fix (Hybrid Option C: watcher + heartbeat-cron, both name paths). Reframed `skillos-wy2w` as the skillos-side deliverable.
- **flywheel:1** owns: L-rule promotion, doctor invariant, fleet sweep, doctrine ratification.
- **mobile-eats** owns: tick script implementation fix (line 83 arity guard).
- **alps** owns: tick prompt audit (peer repo).

## Deferrals

- **L87 sunset** — keep `stale-error-auto-ping.sh` active. Re-evaluate after Phase 5 polish round when classifier-divergence-log shows no fresh stale-error rows for 7 days.
- **Live OAuth rotation** — separate bead. Vault-only primitive ships now; OAuth refresh path is class-2 Joshua-gated under current safety conditions.
- **WOE ledger bootstrap** — separate substrate bead, sequenced before any "WOE row drained" claim.

## Bead DAG (preview for Phase 4 decompose)

Wave 1 (parallel, no dependencies):
- B1 `topology-tick-refresh-script` (Lane B primitive)
- A1 `caam-auto-rotate-primitive` (Lane A new file)
- C1 `frozen-projection-l-rule-doctrine` (Lane C L-rule + AGENTS.md entry)

Wave 2 (depends on wave 1):
- B2 `topology-tick-wire-into-loop-tick` (depends B1)
- B3 `mobile-eats-line-83-arity-guard` (parallel-safe with B2)
- B4 `flywheel-watchers-register-2-plists` (parallel-safe)
- A2 `detector-codex-usage-limit-subclass` (depends A1 for recovery dispatch)
- A3 `auth-gate-recovery-class-extension` (depends A1)
- C2 `frozen-projection-invariant-scan-script` (depends C1)
- C3 `woe-ledger-bootstrap` (parallel-safe; substrate gap)

Wave 3 (depends on wave 2):
- A4 `recovery-ledger-schema-credential_rotation-additive` (depends A1+A3)
- C4 `fleet-sweep-execution` (depends B+C primitives)
- B5 `flywheel-watchers-doctor-com-scope-extension` (depends B4 — sub-bead Lane B noted)

Wave 4 (synthesis):
- ALL `tests-pass + L112-OK + commit + INCIDENTS-update + memory-rule-promote`

Total beads: ~12 (within 8-15 cap). Critical path: A1 → A2 → A3 → A4 ≈ 4 waves; B1 → B2 → tests ≈ 3 waves. Run in parallel where DAG allows.

## Polish gate readiness

Per Phase 5 polish-gate close-gate contract:
- 3 deliverables + 1 synthesis stored in `.flywheel/plans/orch-uptime-2026-05-06/`
- All Lane reports cite Donella trace + Joshua-blocker check + skill floor + socraticode K≥10
- Test cases designed: 18 (A) + 16 (B) + 10 (C) = 44 across 3 surfaces

## Phase 3 AUDIT lens picks

Recommended audit lenses for this plan (3 picks per /flywheel:plan Phase 3):
1. **security-negative-invariants** — credential primitive must not leak token values, profile names should be redactable, idempotency must not poison legitimate rotations
2. **cross-cutting-skill-routing** — detector + auth-gate + caam-primitive + recovery-ledger all touch the same surfaces; coordinate-edits with open P0 `flywheel-wire-codex-queued-not-submitted-classifier-and-recovery-2026-05-06`
3. **paradigm-conflict-with-active-mission** — confirm none of the new substrate violates self-sustaining-company-architecture-health (continuous productivity, no-Joshua-paging-default, no founder-bottleneck)

Audit owner: dispatched to flywheel:2 codex worker after this synthesis lands.

## Status

`current_phase=refine_complete`, ready for Phase 3 audit dispatch.
