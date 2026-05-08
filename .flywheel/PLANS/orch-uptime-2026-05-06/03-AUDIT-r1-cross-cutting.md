# Orchestrator Uptime Audit Lens 2: Cross-Cutting Skill Routing

Task: `orch-uptime-audit-2026-05-06`  
Lens: `cross-cutting-skill-routing`  
Primary input: `.flywheel/plans/orch-uptime-2026-05-06/00-PLAN.md`  
Status: done, read-only audit  
Identity: `MagentaPond` (`flywheel:3`)  
L112: `OK_orch_uptime_audit_lens2_complete`

## Donella Trace

- Boundary: synthesized plan, live bead substrate, detector/gate/recovery scripts, tick manifest, and skill routing substrate.
- Stock: coherent implementation DAG with one owner per mutating surface and skill-backed acceptance gates.
- Flow break: plan-space can freeze stale bead status or drop skill routing when moving from lane reports into synthesis.
- Loop: lane research -> synthesis -> audit -> bead DAG -> worker dispatch -> callback evidence -> updated substrate.
- Leverage: Meadows #5 rules through explicit dependency edges, file reservations, canonical skill citations, and shared receipt schema.
- Intervention: reconcile detector baseline, add missing dependency edges, preserve skill floor per surface, and normalize lock/idempotency/error-class contracts.
- Measurement: zero same-file parallel detector edits, no stale bead status in dispatch, every bead carries canonical skill citations, and new primitives share receipt fields.

## Skill Floor

Skills/references consulted:

- `codex-cli-tracker`: canonical skill for Codex stuck/freeze subclasses and upstream issue mapping.
- `caam`: canonical vault/profile selector surface for account switching.
- `agent-monitoring`: canonical detector/recovery ledger and SLO/health-counter surface.
- `dispatch-tool-contracts`: Socraticode K/Q, callback, diagnose-only, and receipt discipline.
- `jeff-convergence-audit`: Phase 3 broad sweep and convergence gating pattern.
- `codebase-audit`: severity/classified findings with file/surface references.
- `claude-md-skill-arsenal.md`: skill router for selecting the above.

Socraticode queries: 10 against `/Users/josh/Developer/flywheel` (indexed chunks observed: 978).

## Executive Verdict

Recommend `auto_advance` only if Phase 4 absorbs the dependency corrections below. No critical finding maps to a TRUE Joshua-blocker class.

Findings: critical=0, high=2, medium=3, low=1.

## Findings

### HIGH-1: Detector collision is real, but plan status is stale/ambiguous

- Evidence:
  - `00-PLAN.md:54` schedules `codex-template-stuck-detector.sh` v1.2.0 -> v1.3.0 for `codex_usage_limit`.
  - `00-PLAN.md:75` and `:142` call `flywheel-wire-codex-queued-not-submitted-classifier-and-recovery-2026-05-06` an open P0 same-file coordination risk.
  - Live `.beads/issues.jsonl` contains an open row, then a closed row, then `event=close` and `event=verification` rows for that same ID at 2026-05-06T12:33Z and 12:42Z.
  - Current `.flywheel/scripts/codex-template-stuck-detector.sh:539-546` already includes `codex_queued_not_submitted`; `:641-650` has the bare-Enter primitive call; `:718-724` auto-recovers that subclass.

Risk: Phase 4 may dispatch against a stale "open P0" assumption, or a worker may overwrite the already-landed queued-not-submitted logic while adding `codex_usage_limit`.

Conflict class: `same-file semantic classifier-order conflict` plus `stale-bead-status`.

Recommendation:

1. Add a Wave 0 `detector-baseline-reconcile` gate before A2.
2. Treat latest event status as authoritative; if queued-not-submitted is verified closed, A2 depends on that L112 baseline and must preserve its tests.
3. If the bead is reopened by a live `br` truth source, serialize: queued-not-submitted first, usage-limit second.
4. Reserve/write as one owner for:
   - `.flywheel/scripts/codex-template-stuck-detector.sh`
   - `tests/codex-template-stuck-detector.sh`
   - `tests/e2e/e2e_oom_classifier.sh`

Joshua-blocker verdict: none-fire.

### HIGH-2: 00-PLAN loses several 01-RESEARCH-C dependency edges

`01-RESEARCH-C.md:97-109` listed live P0/P1 ordering constraints. The synthesis handles some but not all.

| Bead | Live status observed | 00-PLAN handling | Verdict |
|---|---:|---|---|
| `flywheel-pp1g` | P1 `in_progress` | `00-PLAN.md:101` defers L87 sunset | correct |
| `flywheel-3iz0` | P0 open | `00-PLAN.md:119` WOE bootstrap | correct, but name bead dependency |
| `flywheel-2x5yi` | P0 open | `00-PLAN.md:115,124` watcher register/scope | correct |
| `flywheel-25om8` | P0 `in_progress` | not explicitly linked | missing: same loop-driver/writeback surface as B2 |
| `flywheel-5ktd.2` | P0 open | not explicitly linked | missing: pane-state parser affects topology/robot truth |
| `flywheel-5ktd.3` | P0 open | not explicitly linked | missing: dispatch-capacity truth overlaps B2/A3 validation |
| `flywheel-wire-codex-model-at-capacity-halt-class-c38ad0dd` | P0 open | not explicitly linked | missing: sibling detector/gate schema family |
| `flywheel-viux` | P1 `in_progress` | not explicitly linked | missing: idle-state doctor output overlaps topology/watchers |
| `flywheel-zidg` | P1 open | not explicitly linked | missing: NTM-only pane-state source overlaps topology refresh |
| `flywheel-1255t` | P1 open | can parallel if isolated | acceptable |

Recommendation: add explicit "coordinates-with" edges, not necessarily hard dependencies, for `flywheel-25om8`, `flywheel-5ktd.2`, `flywheel-5ktd.3`, `flywheel-wire-codex-model-at-capacity-halt-class-c38ad0dd`, `flywheel-viux`, and `flywheel-zidg`. Hard-depend B2 on either `flywheel-25om8` completion or a declared non-overlap proof for `.flywheel/flywheel-loop-tick` and driver writeback.

Joshua-blocker verdict: none-fire.

### MEDIUM-1: Skill floor is present in lane reports but not preserved per Phase 4 bead

`00-PLAN.md:135` says lane reports cite skill floors, but the Phase 4 DAG (`:107-124`) does not carry skill citations into each bead. That loses the router at the point workers will actually execute.

Required citations by surface:

| Surface | Required canonical skills |
|---|---|
| detector subclass / Codex freeze class | `codex-cli-tracker`, `agent-monitoring` |
| CAAM vault selector primitive | `caam`, `agent-security` |
| authorization gate | `agent-monitoring`, `agent-security`, `canonical-cli-scoping` |
| recovery ledger schema / doctor counters | `agent-monitoring`, `dispatch-tool-contracts` |
| topology refresh / NTM reads | `ntm`, `loop-enforcement`, `agent-monitoring` |
| watcher register / launchd ownership | `accretive-cron-orchestration`, `install-substrate` |
| frozen projection invariant scan | `codebase-audit`, `canonical-cli-scoping`, `loop-enforcement` |

Recommendation: put `skills_required=[...]` directly into every Phase 4 bead body and dispatch packet. Do not rely on workers rereading lane reports.

Joshua-blocker verdict: none-fire.

### MEDIUM-2: New primitives need one shared lock/idempotency/error-class contract

Existing precedents:

- `worker-auto-respawn-watchdog.sh` emits canonical recovery fields including `pane_role`, `post_check`, `failure_class`, and `primitive_invoked`.
- `capacity-halt-auto-continue-primitive.sh` has dry-run/apply, explicit exit codes, authorization refusal statuses, lease/budget, timeout, and structured result JSON.
- `tick-driver-manifest` primitives rely on driver ledger rows and failure rows for timeout/error.

Plan gaps:

- `caam-auto-rotate-on-usage-limit.sh` has idempotency by `tool:session:pane:digest`, but the synthesis does not require a CAAM tool-level lock. Two usage-limit panes could race the active profile selector.
- `topology-tick-refresh.sh` is append-only, but `00-PLAN.md:62-64` does not state the lock/idempotency key, dry-run/apply behavior, or canonical error field names.
- `frozen-projection-invariant-scan.sh` reads many surfaces but should still emit `error_class`, `scan_status`, and doctor fields consistently.

Recommendation: Phase 4 should add a shared primitive contract:

`dry_run`, `apply`, `idempotency_key`, `lock_path`, `ledger_path`, `status`, `error_class|failure_class`, `primitive_invoked`, `post_check`, `schema_version`.

Joshua-blocker verdict: none-fire.

### MEDIUM-3: A3 and B2 are file-parallel but integration-sequenced

`00-PLAN.md:56` adds `--recovery-class credential_rotation` to the gate. `00-PLAN.md:63` wires topology refresh into `flywheel-loop-tick` before topology-consuming gates.

No direct same-file conflict: A3 edits `capacity-halt-pane-authorization.sh`; B2 edits `flywheel-loop-tick` and manifest wiring. But integration tests must run after both land, because a recovered pane after rotation depends on both:

1. credential rotation can bypass stale topology for vault-only mutation;
2. pane-touching recovery still requires refreshed topology;
3. loop tick must log topology freshness before recovery gates consume it.

Recommendation: keep A3 and B2 as parallel implementation beads, but add a Wave 3 integration bead that tests stale topology + credential rotation + topology refresh + pane recovery in one fixture.

Joshua-blocker verdict: none-fire.

### LOW-1: New scanner CLI needs canonical CLI scoping

`00-PLAN.md:72` proposes `.flywheel/scripts/frozen-projection-invariant-scan.sh`, but the synthesis does not name CLI surface requirements. Because this is a new operator-facing script, it should include `--info`, `--examples`, `--json`, stable exit codes, and a schema command per L82/canonical CLI scoping.

Recommendation: fold this into C2 acceptance criteria.

Joshua-blocker verdict: none-fire.

## Double-Edit / Sequence Summary

- Serialize semantic detector changes: baseline reconcile -> usage-limit subclass.
- Coordinate or prove non-overlap for loop-tick/driver writeback with `flywheel-25om8`.
- Keep A3 and B2 file-parallel, but sequence integration proof after both.
- Preserve queued-not-submitted, model-at-capacity, OOM, post-callback, and unknown-stable fixtures in the A2 regression set.

## Disposition

Recommended audit disposition: `auto_advance` with mandatory Phase 4 corrections above. The findings are bead/DAG quality issues, not true Joshua blockers.

Mission-anchor: continuous-orchestrator-uptime-self-sustaining-fleet
