---
title: "Phase 5 POLISH r1 - Orchestrator Uptime Beads"
type: plan
created: 2026-05-08
frontmatter_source: scaffold-doc-frontmatter
---

# Phase 5 POLISH r1 - Orchestrator Uptime Beads

task_id: `orch-uptime-polish-2026-05-06`
plan_slug: `orch-uptime-2026-05-06`
scope: Phase 5 polish round 1, plan-space only
created_at: `2026-05-06T21:20:00Z`
socraticode_queries: 10
skills_cited: 21
r0_source: `.flywheel/plans/orch-uptime-2026-05-06/04-BEADS-DAG.md` plus the 15 append-only bead rows in `.beads/issues.jsonl`

## Inputs Read

- `00-PLAN.md`
- `01-RESEARCH-A.md`, `01-RESEARCH-B.md`, `01-RESEARCH-C.md`
- `02-DEEP-C2-invariant-scanner.md`, `02-DEEP-C3-woe-bootstrap.md`
- `03-AUDIT-r1-security.md`, `03-AUDIT-r1-cross-cutting.md`, `03-AUDIT-r1-paradigm.md`
- `04-BEADS-DAG.md`
- `SIDE-incidents-codex-capacity-cycle.md`
- `STATE.json`
- `beads-workflow` skill, polishing protocol

## Round Verdict

All 15 beads were reviewed against the six requested polish dimensions. The r0
rows already carried acceptance criteria, tests, skills, dependencies, and audit
refs; r1 tightens them into exact probes and fixture names where a worker could
otherwise satisfy prose without proving behavior.

- Beads reviewed: 15/15
- Internal dependency edges in JSONL rows: 27
- Missing internal dependency targets: 0
- Coordination targets checked in append-only bead log: 10/10 present
- Unique skills cited by r0 rows: 21
- Audit amendment coverage preserved: 14/14
- `polish_diff_pct`: 21
- `convergence_steady_state`: false, pending r2

Diff basis: r1 changes are counted as material field-level refinements against
the 26.8 KB r0 JSONL bead corpus. The first polish pass changes enough
acceptance/test wording that it does not meet the <5 percent steady-state gate.

## DAG Sanity

The r0 DAG remains valid. This round does not change wave ordering.

- Wave 0 remains a baseline reconcile gate.
- Wave 1 primitives and doctrine remain parallel-safe.
- Wave 2 remains implementation fanout after primitives.
- Wave 3 remains schema/doctor/fleet execution.
- Wave 4 remains aggregate validation and closeout.

Local dependency check: every `flywheel-orch-uptime-*` dependency referenced by
the 15 rows exists in the same 15-row set. The hard external edge
`flywheel-25om8` and coordinate beads `flywheel-5ktd.2`, `flywheel-5ktd.3`,
`flywheel-zidg`, `flywheel-2x5yi`, `flywheel-viux`, `flywheel-3iz0`,
`flywheel-pp1g`, `flywheel-wire-codex-model-at-capacity-halt-class-c38ad0dd`,
and `flywheel-wire-codex-queued-not-submitted-classifier-and-recovery-2026-05-06`
are present in `.beads/issues.jsonl`. Live `br` remains degraded by the
BusySnapshot class observed in Phase 4, so JSONL latest-row truth is the checked
substrate for this polish pass.

## Per-Bead Polish Deltas

### W0 - detector baseline reconcile

R0 is directionally correct. R1 tightens the close evidence:

- Add exact probe: `rg -n 'OK_codex_queued_not_submitted_wired|flywheel-wire-codex-queued-not-submitted-classifier-and-recovery-2026-05-06' INCIDENTS.md .beads/issues.jsonl`.
- Add exact fixture obligation: `bash tests/codex-template-stuck-detector.sh` and `bash tests/e2e/e2e_oom_classifier.sh` must stay green before A2 edits the detector.
- Preserve dependency: no new dependency. This remains Wave 0 before A2.

### A1 - CAAM auto-rotate primitive

R0 includes all security amendments, but workers need exact output probes.

- Add acceptance probe for authorization scope: result JSON must satisfy `(.authorized_operations | index("caam_activate_existing_profile")) and (.forbidden_operations | index("pane_mutation")) and (.forbidden_operations | index("oauth_refresh"))`.
- Add idempotency probe: duplicate is allowed only when `limited_profile_before`, `selected_profile`, `post_check.active_profile`, and TTL all match the prior success.
- Add fixture paths: `.flywheel/tests/test_caam_auto_rotate_on_usage_limit.sh` and `.flywheel/tests/fixtures/caam-auto-rotate/`.
- Add secret-negative probe: fixture output must omit raw `auth.json`, bearer/token fields, and unknown CAAM payload keys; redacted selector hashes are allowed.
- R2 should verify whether `--redact-profile-names` is mandatory default or optional flag.

### B1 - topology tick refresh script

R0 has the right primitive shape. R1 makes L116 evidence explicit.

- Add exact fire-ledger probe: every invocation writes one row to the topology-refresh invocation ledger with `run_id`, `status`, `session`, `topology_shape_hash`, `max_age_sec_before`, and `max_age_sec_after`.
- Accepted statuses must include `refreshed`, `already_fresh`, `refused`, `malformed`, and `lock_held`.
- Add fixture paths: `tests/topology-tick-refresh.sh`, `tests/fixtures/topology-tick-refresh/unchanged-shape.jsonl`, `shape-changed.jsonl`, and `lock-held.json`.
- Preserve contract: append-only topology rows only on unchanged shape; invocation ledger rows exist even when no topology row is appended.

### C1 - frozen projection L-rule doctrine

R0 correctly routes label drift and skillos coordination. R1 adds durable receipt
requirements.

- Add acceptance probe: `rg -n 'templates-name-sources-not-values|Templates name sources, not values' AGENTS.md templates/flywheel-install/AGENTS.md`.
- Add coordination probe: cross-orch coordination JSONL must contain `blocker_type=flywheel_class`, `blocker_class=frozen-projection-of-mutable-state`, `requested_owner=flywheel:1`, and `proposed_action=Option C Hybrid`.
- Keep label mapping: L75 for skillos coordination, L115/L117 for peer recovery, L107 only for shared-surface reservations.
- R2 should decide whether doctrine lands directly in `AGENTS.md` or first as a doctrine patch artifact.

### A2 - codex_usage_limit detector subclass

R0 includes pattern families. R1 requires exact sibling-regression proof.

- Add six positive fixture files or cases for `usage limit`, `Limit reached`, `rate_limit_exceeded`, `Plan free tier`, `try again in`, and `429 Too Many`.
- Add false-positive fixture where generic retry text without quota semantics remains non-usage-limit.
- Add ordering assertion: usage-limit detection runs before capacity/unknown-stable fallback when both strings are present.
- Required tests: `bash tests/codex-template-stuck-detector.sh`, `bash tests/e2e/e2e_oom_classifier.sh`, and new `bash .flywheel/tests/test_codex_usage_limit_classifier.sh`.
- Preserve W0 close evidence and the queued-not-submitted bare-enter route.

### A3 - credential_rotation auth gate

R0 states the scope. R1 needs machine-verifiable operation boundaries.

- Add exact probe: `capacity-halt-pane-authorization.sh --tool codex --recovery-class credential_rotation --json` on a stale-topology fixture returns `authorized=true`, `stale_topology_allowed=true`, and `decision_reason=vault_selector_swap_independent_of_pane_role`.
- Add refusal fixtures for default recovery class, unsupported tool, pane mutation, respawn, launchctl, OAuth refresh, token rotation, and vault write.
- Add fixture path: `.flywheel/tests/test_capacity_halt_pane_authorization.sh` or sibling `test_credential_rotation_authorization.sh`.
- Keep A3 parallel with B2 at file level, but W4 must test the combined flow after both land.

### B2 - topology tick wire-in

R0 gets ordering right. R1 turns it into a tick-driver proof.

- Add manifest probe: `jq -e '.primitives[] | select(.name=="topology-tick-refresh" and .timeout_sec <= 30)' .flywheel/scripts/tick-driver-manifest.json`.
- Add ordering probe: tick log has `meta_rule_cache_sync` before `topology_tick_refresh`, and `topology_tick_refresh` before stuck/capacity gates.
- Add doctor join probe: `flywheel-loop doctor --scope tick-driver --json` exposes a recent tick-driver row joined to a topology-refresh invocation row by `run_id`.
- Keep hard external edge: B2 either waits for `flywheel-25om8` or includes a non-overlap receipt for loop-driver writeback.

### B3 - mobile-eats arity guard

R0 correctly cites the empirical capacity-cycle evidence. R1 clarifies ownership
and acceptance.

- Add peer-owned file reservation note: implementation belongs to mobile-eats, not this flywheel plan unless separately dispatched.
- Add fixture path: `/Users/josh/.local/bin/mobile-eats-flywheel-loop-tick` fixture harness or a copied temp fixture under the mobile-eats dispatch.
- Add exact probe: calling the helper with one arg under `set -u` returns rc 0 and emits `fleet_escalation_capsule_skipped` with `reason=missing_args` and `argc=1`.
- Add `--accept-stall` acceptance: capacity-cycle stall must carry an explicit receipt before new work is routed to the throttled single pane.

### B4 - watchers register/load/fire

R0 split registration/load/fire. R1 adds concrete labels and proofs.

- Required labels: `com.flywheel.shutdown-recovery` and `ai.zeststream.flywheel-idle-pane-watch`.
- Add registry probe: `flywheel-watchers registry --json` or equivalent must show both labels with the orch-uptime idempotency keys.
- Add load probe: guarded bootstrap/load evidence proves the label is present in the GUI-domain `launchctl` list without guard bypass.
- Add fire probe: recent watcher log/ledger row exists inside two cadence windows.
- Test paths: `tests/flywheel-watchers-test.sh`, `tests/flywheel-watchers-doctor-launchctl-test.sh`, and a new load/fire fixture if existing tests cannot assert recency.

### C2 - frozen projection invariant scan

R0 is strong from the deep dive. R1 imports the exact regex/cutoff contract.

- Add CLI acceptance: `--info --json`, `--examples --json`, `--schema --json`, `--json`, stable rc map, and canonical CLI scoping citation.
- Add enforcement fields: `cutoff_ts`, `strict_promoted_at`, `file_mtime`, `mtime_relation`, `pattern_id`, `allow_pattern_id`, and redacted match text.
- Add fixture paths: `.flywheel/tests/test_frozen_projection_invariant.sh`, `.flywheel/tests/fixtures/frozen-projection/literal-blocker/`, `source-path/`, `existing-debt/`, and `new-debt/`.
- Add exact policy: pre-cutoff unallowed findings warn; post-cutoff in-scope findings fail; secret-value literals fail always.

### C3 - WOE ledger bootstrap

R0 scopes the blocker correctly. R1 names the writer and close-gate probes.

- Add writer-only acceptance: production rows must be written through `.flywheel/scripts/wire-or-explain-ledger-writer.sh`, not shell redirection.
- Add idempotency key shape: `orch-uptime-c3-woe-bootstrap:2026-05-06:<bead_id>`.
- Add temp-ledger proof: append all bootstrap rows to a temp ledger, run chain verifier, run close gate in shadow/bootstrap, then write production.
- Add scope probe: missing ledger warns in bootstrap/shadow and blocks only WOE-drain/bootstrap claims in enforce mode.
- Test paths: `tests/wire-or-explain-ledger.sh`, `tests/wire-or-explain-close-gate.sh`, `tests/wire-or-explain-doctor.sh`, and `tests/wire-or-explain-close-gate-fault-injection.sh` FM5.

### A4 - recovery ledger CAAM additive schema

R0 keeps fields additive. R1 tightens schema regression tests.

- Add schema probe: `jq -e '.properties.recovery_class.enum | index("credential_rotation")' .flywheel/validation-schema/v1/recovery-ledger.schema.json`.
- Add legacy-required-field regression for every pre-existing required field: `actor`, target fields, `pane_role`, `trauma_class`, `signal_text`, `decision_reason`, `budget_state`, `transport`, `post_check`, `failure_class`, and `primitive_invoked`.
- Add fixture paths: `.flywheel/tests/test_recovery_ledger_schema.sh` or nearest recovery doctor schema test plus `tests/fixtures/recovery-ledger/caam-credential-rotation.json`.
- Keep `profile_selector.redacted` and `selector_sha256` required for CAAM rows if selector names are omitted.

### B5 - watchers doctor com.flywheel scope

R0 identifies the scope gap. R1 requires doctor output fields.

- Add doctor field acceptance: output separates `registered_count`, `loaded_count`, `recent_fire_count`, `unregistered_count`, and `guard_refusal_count` for both `ai.zeststream.flywheel-*` and guarded `com.flywheel.*` labels.
- Add regression: existing `ai.zeststream.flywheel-*` behavior remains unchanged.
- Test paths: `tests/flywheel-watchers-doctor-launchctl-test.sh` and `tests/flywheel-watchers-test.sh`.
- Preserve dependency on B4 because doctor counts are only meaningful after registry/load/fire evidence exists.

### C4 - fleet sweep execution

R0 is correct but too broad for worker dispatch. R1 makes routing explicit.

- Add dry-run report shape: `status`, `existing_debt_warn_count`, `new_debt_fail_count`, `peer_coordination_rows`, `beads_filed`, and `no_bead_reasons`.
- Add coordination acceptance: skillos, mobile-eats, and ALPS debt must route through durable coordination rows or separate dispatches; this bead must not mutate peer repos directly.
- Add L87 probe: `flywheel-pp1g` remains open/in_progress or classifier divergence rows remain fresh means L87 stays active.
- Test path: fleet-sweep dry-run fixture under `.flywheel/tests/test_frozen_projection_invariant.sh` or a separate `tests/frozen-projection-fleet-sweep.sh`.

### W4 - integration validation closeout

R0 aggregates all amendments. R1 names the closeout probes.

- Add aggregate command list: detector, CAAM fake primitive, authorization gate, topology refresh, tick-driver, watchers, frozen-projection scan, WOE ledger, and recovery-ledger schema tests.
- Add audit coverage probe: report maps every amendment number 1-14 to at least one landed artifact and test evidence path.
- Add architecture-health metric: `founder_pages_avoided_by_orch_uptime_24h` must pair a counterfactual with quality probes such as `false_recovery_count_24h` and `recovery_success_pct_24h`.
- Add callback shape: DID/DIDNT/GAPS, L112 successor, tests run, files touched, bead IDs, and true Joshua-blocker class check.
- R2 should decide the exact successor L112 marker for implementation closeout; r0 reused the Phase 4 marker in one sentence.

## Cross-Bead R1 Findings

1. Acceptance criteria are mostly present but need exact command probes in 13 of
   15 beads.
2. Fixture paths are concrete for detector, WOE, watchers, and tick-driver
   surfaces; new fixture directories should be named for CAAM auto-rotate,
   topology refresh, frozen projection, and recovery-ledger schema.
3. Dependency edges are sane and acyclic by wave order. No r1 edge rewrite is
   needed.
4. Skills are complete by surface. The r0 rows cite 21 unique skills and satisfy
   the cross-cutting MEDIUM-1 table.
5. Idempotency keys need exact shapes in A1, B1, C2, and C3. C3 now has the
   exact shape; A1/B1/C2 still need final implementation-specific ledger path
   names.
6. Amendment refs are complete. R1 adds more exact probes but no new amendment
   class.

## R2 Triggers

Run r2 after the implementation owners either fold or reject these exact probes.
The next round should verify whether the r1 text delta falls below 5 percent
and should mark steady-state only after two consecutive <5 percent rounds.

Likely r2 focus:

- CAAM selector redaction default and final idempotency key shape.
- Topology-refresh invocation ledger path and tick-driver join field name.
- Frozen-projection scanner cutoff timestamp source.
- WOE bootstrap production ledger row count and temp-ledger proof path.
- W4 successor L112 marker for implementation closeout.

L112: OK_orch_uptime_polish_r1_complete

Mission-anchor: continuous-orchestrator-uptime-self-sustaining-fleet
