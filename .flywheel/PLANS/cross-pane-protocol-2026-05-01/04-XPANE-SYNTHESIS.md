---
title: Cross-Pane Protocol — Synthesis
date: 2026-05-01
status: converged
author: flywheel:3 codex worker
task_id: 22831e0a
bead: flywheel-7np
scope: plan-space synthesis only
inputs:
  lane_1_l69_doctrine_state_machine:
    path: 01-L69-DOCTRINE-AND-STATE-MACHINE.md
    status: done
    ladder_passed: yes
    soft_violations: 7
    landed_rule: L81
  lane_2_cli_surface_protocols:
    path: 02-CLI-SURFACE-AND-PROTOCOLS.md
    status: done
    ladder_passed: yes
    commands: 26
    canonical_cli_scoping: yes
  lane_3_fleet_wide_backfill_engine:
    path: 03-FLEET-WIDE-BACKFILL-ENGINE.md
    status: done
    ladder_passed: yes
    repo_lifecycle_stages: 6
    engine_commands: 4
---

# Cross-Pane Protocol — Synthesis

All three lanes have landed on disk. This synthesis replaces the earlier
partial state and records the converged cross-lane plan for L81 docs-as-substrate,
`flywheel-readme`, and fleet-wide docs backfill.

ID reconciliation: Lane 1 proposed docs-as-substrate as L69 and Lane 2 proposed
canonical CLI scoping as L70. Canonical `AGENTS.md` later allocated L69 to
`ORCH-PROBE-AGENT-CONTEXT` and L70 to `ORCH-NO-PUNT`, so the cross-pane docs
doctrine landed as L81 and canonical CLI scoping landed as L82. L69/L70 are not
available IDs for these two doctrines.

## Source Ledger

| Source | Role | Key proof |
|---|---|---|
| `01-L69-DOCTRINE-AND-STATE-MACHINE.md` | Historical Lane 1 docs doctrine, landed as L81; actors, state machine, Gate 2, SOFT violations | 7 SOFT violations, cross-pane no-self-validation rule, reject-and-revert mechanics |
| `02-CLI-SURFACE-AND-PROTOCOLS.md` | `flywheel-readme` operator CLI spec | 26 command/mode surfaces, canonical CLI scoping overlay integrated, dry-run/schema/observability contracts |
| `03-FLEET-WIDE-BACKFILL-ENGINE.md` | Propagation and repo-local backfill design | Doctrine-sync reuse, 6-stage repo lifecycle, docs-inventory/docs-backfill/fleet-docs commands |
| Socraticode survey | Prior local substrate check | Query: `cross-pane protocol synthesis Lane 1 Lane 2 Lane 3 SOFT violations doctor signals fleet-docs state machine` |

## Lane Captures

### Lane 1 — L81 Doctrine And State Machine

Lane 1 defines the doctrine shape: documentation for load-bearing artifacts is
part of the artifact contract, not commentary. The worker may draft a README,
but a different pane must perform Gate 2 validation before Joshua signoff.

Key outputs:

- Landed L81 `DOCS-ARE-LOAD-BEARING-CROSS-PANE-VALIDATED` wording with provenance from the
  documentation-substrate incident cluster.
- Load-bearing scope: flywheel binaries, launchd plists, hooks, slash-command
  contracts, substrate registry rows, canonical doctrine, and relied-on scripts.
- State machine from dispatch to draft, orchestrator review, reject/pass,
  Joshua signoff/rejection, timeout, escalation, and retirement.
- Gate 2 checklist for cold-read validation.
- 7 SOFT violations:
  `readme_below_floor`, `readme_validated_by_self`, `readme_orphaned`,
  `readme_validation_failed`, `readme_pending_orchestrator_review`,
  `readme_pending_joshua_signoff`, `readme_review_timeout`.
- Reject-and-revert posture: failed README validation routes back as rewrite,
  not patch-forward.

### Lane 2 — CLI Surface And Protocols

Lane 2 defines the operator surface for the cross-pane README workflow:
`flywheel-readme`.

Command surface:

| Group | Commands |
|---|---|
| Review flow | `draft`, `submit`, `review --queue`, `review <path>`, `reject`, `pass`, `signoff --queue`, `signoff <path>` |
| Canonical triad | `doctor`, `health`, `repair` |
| State subsidiary | `validate`, `audit`, `why` |
| Self-documentation | `--info`, `examples` / `--examples`, `quickstart`, `help <topic>`, `completion <shell>` |
| Schema and observability | `schema`, `metrics`, `logs`, `trace` |
| Large-surface discoverability | `palette`, `activity`, `triage` |

Canonical overlay status:

- `--json`, `--no-color`, `--no-emoji`, and `--width` are universal.
- Mutations use `--dry-run`, `--explain`, and `--idempotency-key`.
- JSON dry-runs use planned-only keys; applied runs use actual-only keys.
- Canonical exit codes are documented.
- Console-script name collision precheck is explicit.
- Schema emission and observability are in scope.

### Lane 3 — Fleet-Wide Backfill Engine

Lane 3 designs how the doctrine and review protocol propagate into repo-local
work without creating a parallel doctrine system.

Key outputs:

- Reuse `flywheel-doctrine-sync` for propagation; no second sync path.
- Extend `flywheel-loop init` with docs scaffolding:
  `.flywheel/docs-policy.md`, `.flywheel/docs-review-queue.jsonl`,
  `.flywheel/INVENTORY-DOCS.md`, `.flywheel/TOP20-BACKFILL.md`, and doctor
  `.docs_substrate`.
- Add repo-local engine commands:
  `docs-inventory`, `docs-backfill`, and `fleet-docs`, plus the init extension.
- Repo lifecycle:
  `0_uninitialized -> 1_initialized -> 2_inventoried -> 3_backfilling -> 4_partial_validated -> 5_fleet_caught_up`.
- Tick integration: `DOCS_BACKFILL` after normal dispatchable beads and before
  doctrine hunting.
- Explicit fallback for repos with fewer than two Codex panes.

## Required Convergence Checks

### 1. Lane 1 SOFT Violations -> Lane 2 Doctor Signals -> Lane 3 Fleet-Docs JSON

| Lane 1 SOFT violation | Lane 2 doctor/health scope | Lane 3 `.docs_substrate` / `fleet-docs` field | Verdict |
|---|---|---|---|
| `readme_below_floor` | frontmatter + validation_commands | `.below_floor[]`, `fleet_totals.below_floor` | aligned |
| `readme_validated_by_self` | frontmatter | `.self_validation[]` | aligned |
| `readme_orphaned` | frontmatter + validation_commands | `.orphaned[]` | aligned |
| `readme_validation_failed` | validation_commands | `.validation_failed[]` | aligned |
| `readme_pending_orchestrator_review` | queue + ledger | `.review_overdue[]`, `in_review` | aligned |
| `readme_pending_joshua_signoff` | queue + ledger | `.signoff_overdue[]`, `in_review` | aligned |
| `readme_review_timeout` | queue + locks + ledger | `.review_timeout[]`, `fleet_totals.review_timeout` | aligned |

Verdict: aligned. Lane 1 names the failure classes, Lane 2 provides the
operator CLI surfaces that diagnose/repair them, and Lane 3 makes them visible
at repo and fleet level.

Open implementation constraint: Lane 2's `doctor --json` schema must preserve
these exact violation names or a deterministic mapping table so `fleet-docs`
does not need prose inference.

### 2. Lane 1 State Machine Stages -> Lane 3 Repo Lifecycle Stages

| Lane 1 README state | Lane 3 repo lifecycle relation | Verdict |
|---|---|---|
| `0_dispatched` | repo has a generated backfill bead in `3_backfilling` | aligned |
| `1_drafted` | repo remains `3_backfilling`; review queue has drafted row | aligned |
| `2_orchestrator_reviewing` | repo remains `3_backfilling`; item has reviewer ownership | aligned |
| `3_orchestrator_failed` | repo remains `3_backfilling`; backfill bead is rewritten/requeued | aligned |
| `3_orchestrator_passed` | repo is still below `4_partial_validated` until Joshua signoff | aligned |
| `4_joshua_signed` | first signed README advances repo to `4_partial_validated` | aligned |
| `5_joshua_rejected` | repo remains `3_backfilling` or retires artifact | aligned |
| timeout/escalation/retire | repo can return to `2_inventoried` or keep blocked backfill visible | aligned |

Verdict: aligned. Lane 1 is item-level truth; Lane 3 is repo-level aggregate
truth. A repo only advances to partial validation when at least one item reaches
Joshua-signed state.

### 3. Lane 2 CLI Surface -> Canonical CLI Scoping Checklist

| Canonical requirement | Lane 2 coverage |
|---|---|
| doctor / health / repair triad | `doctor`, `health`, `repair` |
| validate / audit / why | `validate`, `audit`, `why` |
| self-documentation | `--info`, `examples`, `quickstart`, `help <topic>`, `completion` |
| `--json` everywhere | universal flags section |
| canonical exit codes | explicit exit-code table |
| mutation discipline | dry-run/explain/idempotency-key on mutating commands |
| schema emission | `schema <command|all>` |
| observability | `metrics`, `logs`, `trace` |
| name collision precheck | `which flywheel-readme` section |

Verdict: aligned. Lane 2 is compliant as a plan-space spec. Implementation must
dogfood with `canonical-cli-scoping/scripts/check-cli-scoping.sh` after the
binary ships.

### 4. Lane 3 Backfill Engine Commands -> Canonical CLI Scoping Too

| Lane 3 command | Mutation? | Canonical requirements before implementation |
|---|---:|---|
| `flywheel-loop init` extension | yes | `--json`, idempotent scaffold, audit row for generated docs substrate |
| `flywheel-loop docs-inventory --repo <repo>` | yes | `--json`, `--dry-run`, schema for inventory ledger, deterministic output paths |
| `flywheel-loop docs-backfill --repo <repo>` | yes | `--json`, `--dry-run`, `--explain`, `--idempotency-key`, audit log, repo-local Beads proof |
| `flywheel-loop fleet-docs --json` | no | schema emission, canonical exit codes, readable failure classes |

Verdict: partial by design. Lane 3 was written before the canonical overlay was
declared mandatory, so it correctly defines the engine but does not fully spell
out the canonical CLI discipline for every `flywheel-loop` subcommand. This is
not a blocker for synthesis, but it is a required implementation guardrail.

Recommended follow-up: implementation beads for Lane 3 commands must embed the
canonical CLI checklist instead of treating the commands as internal helpers.

### 5. Reject-And-Revert Mechanics Across All Lanes

| Path | Lane 1 | Lane 2 | Lane 3 | Verdict |
|---|---|---|---|---|
| Quality failure | Gate 2 fails; reject to worker for rewrite | `reject <readme> --reasons` | Backfill bead remains open/requeued | aligned |
| Joshua rejection | Joshua rejects after orchestrator pass | `signoff <readme> --reject-with-reason` | Repo remains in backfilling or retires artifact | aligned |
| Liveness failure | timeout/escalation states | `doctor`, `repair`, queue commands | stuck bead timeout -> reassign | aligned but separate |
| Repeated pattern | 2x same artifact escalates; 3x same checklist item logs fuckup | `audit`/`why` provide evidence | fleet-docs aggregates repeated timeout/fail classes | aligned |

Verdict: aligned with one important distinction. Lane 1 handles quality failure;
Lane 3 handles liveness failure. The implementation must keep both paths:
`flywheel-readme reject` is not a substitute for stuck-bead reassignment, and
reassignment is not a substitute for Gate 2 rejection.

## Divergences And Decisions For Joshua

| ID | Divergence / decision | Recommendation |
|---|---|---|
| JD-XPANE-001 | Historical: commit the Lane 1 proposed L69 wording now or after implementation? | Resolved: do not use L69 for this doctrine; docs-as-load-bearing landed as L81 and canonical CLI scoping landed as L82 after L69/L70 were allocated elsewhere. |
| JD-XPANE-002 | Lane 3 command canonical retrofit is not fully specified inline. | Do not rewrite Lane 3 now; make each implementation bead carry the canonical CLI checklist. |
| JD-XPANE-003 | Exact Lane 2 doctor output names must map to Lane 1 SOFT names. | Preserve Lane 1 violation names in `flywheel-readme doctor --json` to avoid translation drift. |
| JD-XPANE-004 | Repos with fewer than two Codex panes cannot truly cross-pane validate. | Keep explicit `fallback_joshua_orchestrator`; never mark those as standard cross-pane validated. |

## Implementation Roadmap

Wave 1 — doctrine and CLI proof:

1. Land/propagate the final L81 doctrine; JD-XPANE-001 is resolved by the L81/L82 ID reconciliation.
2. Implement or validate `flywheel-readme` against Lane 2 and
   `canonical-cli-scoping/scripts/check-cli-scoping.sh`.
3. Publish `flywheel-readme doctor --json` schema with the seven Lane 1 SOFT
   violation names.

Wave 2 — repo-local substrate:

1. Extend `flywheel-loop init` with docs substrate scaffolding.
2. Implement `docs-inventory --repo` with schema and idempotent output.
3. Implement `docs-backfill --repo` with repo-local Beads conflict handling and
   idempotency keys.

Wave 3 — fleet integration:

1. Implement `fleet-docs --json`.
2. Wire `DOCS_BACKFILL` into tick decision order.
3. Add status/dashboard surfacing for queue overflow, review timeout, fallback
   capacity, and validation rate.

## Validation Summary

- Lane 1 read: yes.
- Lane 2 read: yes.
- Lane 3 read: yes.
- Socraticode survey: yes.
- Required convergence checks: 5/5 complete.
- Divergences surfaced for Joshua: 4.
- File modifications outside plan directory: none for this bead.

ladder_passed: yes
