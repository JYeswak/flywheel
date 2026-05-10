---
title: "01-RESEARCH-B - NTM Surface Migration Ecosystem Audit"
type: plan
created: 2026-05-08
frontmatter_source: scaffold-doc-frontmatter
---

# 01-RESEARCH-B - NTM Surface Migration Ecosystem Audit

Task: `ntm-surface-migration-lane-b-2026-05-06`  
Scope: read-only plan-space audit of the 109-surface migration candidates.  
L112: `OK_ntm_surface_migration_lane_b`

## Skills Library Cited

- `ntm`: native NTM surface map; dispatch, coordinator, checkpoint, safety, serve, robot, and work-intelligence primitives.
- `dicklesworthstone-stack`: Jeff-style verdict framing: adopt native patterns, adapt only where local invariants require it, avoid domain drift.
- `jeff-convergence-audit`: convergence test for repeated cross-cutting findings and two-zero cleanup discipline.
- `jeff-issue-chain`: do not prescribe implementation when the substrate already has a native primitive; identify bugs/gaps precisely.
- `canonical-cli-scoping`: keep wrapper surfaces close to canonical command scope.
- `dispatch-tool-contracts`: Socraticode K>=10 and callback evidence fields.
- `observability-designer`: W1 telemetry should become operational signals, not dashboards-only output.
- `agent-orchestration`: maps pipeline, ensemble, coordinator, and rebalance surfaces to orchestration patterns.
- `socraticode`: mandatory repo precedent survey; 5 queries, K=10 each, `indexed_chunks_observed=989`.
- `codebase-audit`: use evidence-first matrix with explicit adoption verdicts.

`skills_library_gap=none`

## Source Notes

- Primary packet: `/tmp/dispatch_ntm-surface-migration-lane-b-2026-05-06.md`.
- Audit input: `/tmp/ntm-surface-audit-summary-2026-05-06.md`.
- Intent input: `.flywheel/plans/ntm-surface-utilization-migration-2026-05-06/00-INTENT.md`.
- Skillos coordination: `/tmp/skillos-pane1-batch-promotion-coord-2026-05-06T2210Z.md` and `/tmp/skillos-coord-reply-ntm-audit-gate-2026-05-06T2235Z.md`.
- Native reference: `ntm v1.14.0-41-ga2529ba3-dirty`, source inspected at `/Users/josh/Developer/ntm/internal/cli/`.
- `rotate` is excluded from the 28-candidate matrix because A1 already shipped as a wrapper and the audit marks it `using_well`; it stays W0 conformance evidence.

## Per-Candidate ADOPT / EXTEND / AVOID Matrix

| # | surface | jeff_pattern_aligned | adopt_extend_avoid | rationale |
|---:|---|---|---|---|
| 1 | `quota` | Y | ADOPT | Native quota queries Claude/Codex/Gemini panes; make it W1 usage-limit telemetry before capacity stalls. |
| 2 | `serve` | Y | ADOPT | Native REST/SSE gives push health and event feed; use as live evidence substrate for doctor and L57. |
| 3 | `preflight` | Y | EXTEND | Native prompt preflight covers size/secrets/destructive/PII; L91 still needs post-send four-state probe wrapper. |
| 4 | `rebalance` | Y | EXTEND | Native imbalance scoring fits workload skew, but dispatch ownership and bead safety must gate apply mode. |
| 5 | `metrics` | Y | ADOPT | Native metrics/snapshot/export should feed closeout, doctor, and fleet health receipts. |
| 6 | `coordinator` | Unknown | EXTEND | Native coordinator covers assignments/conflicts/digests; must preserve cross-orch ledger ownership, heartbeat, and ACK fields. |
| 7 | `ensemble` | Y | EXTEND | Native ensemble fits review rounds, but mission-lock judge scoring and callback receipts must remain explicit. |
| 8 | `pipeline` | Unknown | EXTEND | Native pipeline can run stages, but plan/refine/audit/polish/ship receipts must remain flywheel-addressable. |
| 9 | `approve` | Unknown | EXTEND | Native approval substrate fits Joshua gates; exact question, evidence, and why-not-agent fields need schema parity. |
| 10 | `safety` | Y | EXTEND | Native safety is a strong NTM sibling; dcg remains final destructive-command guard and cannot be weakened. |
| 11 | `scrub` | Y | ADOPT | Native scrub is read-only/redacted and should scan dispatch packets, callbacks, and skill-source gate inputs. |
| 12 | `policy` | Y | EXTEND | Native policy can encode NTM automation rules; AGENTS L-rules remain canonical doctrine source. |
| 13 | `audit` | Y | ADOPT | Native tamper-evident audit can prove receipt consistency before close and migration promotions. |
| 14 | `checkpoint` | Y | ADOPT | Native checkpoint should precede long ticks, high-risk recovery, and rollback candidates. |
| 15 | `rollback` | Y | EXTEND | Native rollback must be tied to checkpoint receipts and dry-run proof before fleet use. |
| 16 | `add` | N | AVOID | No concrete workflow fit in this migration; keep available for later scaling rather than inventing demand. |
| 17 | `quota` -> `.flywheel/scripts/capacity-halt-pane-authorization.sh` | Y | EXTEND | Keep authorization semantics; add quota signal as input, not replacement. |
| 18 | `serve` -> `.flywheel/scripts/ntm-fleet-health.sh` | Y | EXTEND | Feed native serve/SSE into fleet-health until doctor fields and history parity are proven. |
| 19 | `preflight` -> `.flywheel/scripts/validate-callback-before-close.sh` | Y | EXTEND | Pre-send validation and closeout validation are different gates; wire both. |
| 20 | `metrics` -> `.flywheel/scripts/ntm-fleet-health.sh` | Y | EXTEND | Native metrics should enrich fleet health, not delete existing pane-health checks on day one. |
| 21 | `coordinator` -> `~/.local/state/flywheel/cross-orch-coordination.jsonl` | Unknown | EXTEND | Migrate only if blocker class, requested owner, heartbeat, and ACK rows survive. |
| 22 | `pipeline` -> `/flywheel:plan` plan pipeline | Unknown | EXTEND | Native stages can host execution, but plan-space artifacts remain canonical. |
| 23 | `approve` -> `.flywheel/scripts/validate-callback-before-close.sh` | Unknown | EXTEND | Approval decisions need human-question and evidence fields beyond generic request state. |
| 24 | `safety` -> `dcg + .flywheel/scripts/dispatch-canonical-cli-validator.sh` | Y | EXTEND | Add native safety to dispatch path; keep dcg and canonical CLI validator as independent gates. |
| 25 | `policy` -> `AGENTS.md L-rules + validator scripts` | Y | EXTEND | Generate/enforce NTM policy from doctrine where possible; do not make policy the doctrine source. |
| 26 | `audit` -> `.flywheel/reports/ + .flywheel/scripts/*validator.sh` | Y | EXTEND | Native audit should become an evidence source for validators and reports. |
| 27 | `checkpoint` -> `.flywheel/STATE.md + .flywheel/last_closeout_receipt.json` | Y | EXTEND | Checkpoints should point to state/receipt hashes and not replace closeout receipts. |
| 28 | `rollback` -> git/worktree rollback conventions + receipt supersession | Unknown | EXTEND | Rollback is safe only with checkpoint id, dry-run, changed-files ledger, and receipt supersession. |

Counts: `ADOPT=6`, `EXTEND=21`, `AVOID=1`.

## Cross-Cutting Findings

1. The right default is native-first wrappers: call NTM primitives, then preserve flywheel-specific receipts and L-rule evidence.
2. Pre-send and post-send are separate planes. `preflight`, `scrub`, `policy`, and `safety` do not replace L91 delivery proof.
3. W1 should bundle `quota + metrics + serve` into operational telemetry for doctor/closeout, not a side dashboard.
4. `policy + safety + approve` should form one decision ladder; dcg remains the destructive-operation authority.
5. `coordinator + pipeline` can reduce custom cross-orch JSONL only after field parity is demonstrated.
6. `checkpoint + rollback` must be atomic: every rollback candidate needs a checkpoint id, dry-run, and changed-files ledger.
7. `audit + scrub` should run before closeout callbacks and before any skill-source or cross-repo propagation.
8. `rebalance`, `ensemble`, and `add` are later-wave scaling primitives; premature adoption risks inventing orchestration demand.

## AGENTS.md L-Rule Impact Map

- W1 telemetry (`quota`, `metrics`, `serve`): reinforces L57 active-driver proof, L70 no-punt evidence, L99 worker recovery SLOs, L102 meta-rule freshness, L110 self-repair declarations, and L116 tick-as-process receipts.
- Dispatch hardening (`preflight`, `scrub`, `safety`, `approve`, `policy`): reinforces L29 NTM-only operations, L91 four-state delivery, L111 real-time quality, L119 template-source discipline, and L120 callback closeout proof.
- Coordination substrate (`coordinator`, `pipeline`, `audit`, `checkpoint`, `rollback`): reinforces L61 doctrine landing wires, L75 cross-orch blocker coordination, L102 sync adjacency, L110 self-repair loops, L116 process receipts, L119 templates, and L120 callbacks.
- Scaling primitives (`rebalance`, `ensemble`, `add`): should be gated by L70 no-punt, L75 ownership, L85 idle-state classification, L99 recovery windows, and L111 quality bar.
- L91 candidate specifically maps to L29, L57, L67, L71, L85, L87, L91, L99, and L120 as cited by Socraticode.
- M gate specifically maps to L29, L61, L102, L110, L119, and the dispatch safety lane; native NTM policy must not become the only source of truth.

## L91 Four-State Probe Verdict

Verdict: `wrapper`

`ntm preflight` is necessary but not sufficient: it validates the outgoing prompt before transport. L91 requires four states after dispatch: `transport_accepted`, `prompt_visible_in_target`, `prompt_submitted`, and `work_started`. The L91 probe should wrap native primitives:

- Pre-send: `ntm preflight --strict --json` plus writer-side lint.
- Transport: `ntm send ... --json`.
- Delivery evidence: `ntm copy` or `ntm serve` event feed showing target-pane prompt visibility.
- Work-start evidence: `ntm wait --until=generating|healthy --json` plus pane evidence when available.

Do not run L91 as a parallel bespoke lane, and do not let native preflight supersede it.

## M Cross-Repo Gate Verdict

Verdict: `hybrid`

Native `ntm policy` and `ntm scrub` should be adopted into the gate, but they do not fully subsume the skill-source write-side validator. M protects `~/.claude` shared library schema/frontmatter and no-write-side discipline across repos. That is broader than NTM runtime policy and narrower than generic secret scrubbing.

Recommended shape: keep the shared-library pre-commit YAML validator, then call `ntm scrub` and `ntm policy validate` from the hook/doctor path where NTM artifacts or dispatch surfaces are involved.

## Three-Judges Sniff

| judge | score | sniff |
|---|---:|---|
| Jeff | 8/10 | Native-first, avoids from-scratch substitutes, but several EXTEND rows still need parity probes before migration. |
| Donella | 9/10 | Identifies feedback loops and delayed failure modes: telemetry, coordinator ACKs, and rollback receipts. |
| Joshua | 8/10 | Practical dispatch order with bounded wrappers; avoids deleting working local gates before native proof exists. |

Self-grade: `8.3/10`

## Ladder Pass

- Inputs read: dispatch packet, audit summary, 00-INTENT, skillos coordination files, NTM reference, skill docs, Socraticode results, and native NTM help/source.
- Socraticode: `queries=5`, `limit=10`, `indexed_chunks_observed=989`.
- Read-only compliance: no source files modified; only this Lane B plan artifact was added.
- Bead posture: no bead created; this is a dispatched research artifact and no new defect was observed.
- Recommended order: W0 conformance first, W1 telemetry second, W2 dispatch hardening third, W3 coordination/audit/policy fourth, W4 scaling primitives last.
- L112 observed: `OK_ntm_surface_migration_lane_b`.

Mission-anchor: `continuous-orchestrator-uptime-self-sustaining-fleet`
