---
title: "Phase 3 AUDIT r1 - Cross-Cutting"
type: plan
created: 2026-05-08
frontmatter_source: scaffold-doc-frontmatter
---

# Phase 3 AUDIT r1 - Cross-Cutting

task_id: `ntm-surface-migration-audit-cross-cutting-r1-2026-05-06`  
plan_slug: `ntm-surface-utilization-migration-2026-05-06`  
date: 2026-05-06  
auditor: `PearlRaven`  
socraticode_queries: 10, K=10 each  
converged_source_used: `02-REFINE-r1.md` because required `00-PLAN.md` is absent

## 1. Skills Library Cited

- `dispatch-tool-contracts`: callback fields, Socraticode K vs Q, worker prompt contract, proof-of-work fields.
- `migration-architect`: expand-contract sequencing, rollback before cutover, parallel-run before supersession.
- `codebase-audit`: severity-tagged report with root cause and concrete fix.
- `agent-mail`: file reservations before edits, release on DONE/BLOCKED, threadable coordination.
- `ntm` reference: pane/session actions through NTM only.

Freshness: `migration-architect/LATEST.md` had no actionable migration delta. `dispatch-tool-contracts/LATEST.md` confirms the dispatch contract itself is recent and load-bearing. `skills_library_gap=none`.

## 2. Wave-Internal Sequencing Audit

| Transition | Gate Required | Plan State | Verdict |
|---|---|---|---|
| W1 `quota -> metrics` | W1Q callback proves quota schema, stale/unsupported cases, and actionability before W1M consumes | `02-REFINE-r1.md` says W1 is strict sequential | PASS with explicit callback gate added in Phase 4 |
| W1 `metrics -> serve` | W1M callback proves counters are meaningful and not dashboard-only before W1S exposes them | Sequential in refine; Lane C had looser parallel shape | GAP: Phase 4 must use refine order, not Lane C parallel order |
| W2 `scrub -> preflight` | scrub redacts packet/callback artifacts before preflight classifies them | Refine says scrub first; Lane C says preflight first | HIGH: artifact conflict; choose scrub first |
| W2 `preflight -> safety` | preflight callback proves prompt-visible/work-start receipt wrapper remains separate from transport ack | Sequential in refine | PASS with L91 receipt fields required |
| W2 `safety -> approve` | safety/DCG divergence receipt exists before human approval payload can be trusted | Sequential in refine | PASS with exact-question/evidence schema required |

Transition rule: no W1/W2 downstream bead starts until prior bead callback validates, not merely until the upstream command exits.

## 3. Cross-Wave Shared-Resource Map

| Shared Surface | Beads Touching | Declared Reservation Pattern | Conflict Risk | Required Fix |
|---|---|---|---|---|
| `.beads/issues.jsonl` | W4T; any follow-up beads from W2/W3 stricter native findings | generic "exact paths" only | HIGH | name explicit reservation in each prompt; append-safe only |
| `~/.local/state/flywheel/cross-orch-coordination.jsonl` | W0T, W3C, W4T | "Agent Mail awareness" only | HIGH | exact row schema + writer owner + append lock |
| `.flywheel/STATE.md` / plan `STATE.json` | W3P, W4T, closeout | rollback path names state, no reserve list | MED | per-bead `files_reserved[]` and release proof |
| `AGENTS.md` / templates doctrine surfaces | W0T, W0N, W3C/W3R if policy codifies rules | not enumerated | HIGH | Agent Mail reservation plus shared-surface reservation check |
| `.flywheel/scripts/*` | W0A, W1, W2, W3 implementation beads | examples mention script paths | MED | reserve exact script + matching test in same prompt |
| `~/.claude/skills/.flywheel/scripts/` | skillos-sourced K/L/L29/M handoff | not specified | MED | producer/consumer handoff row before flywheel edits |

Cross-cutting verdict: L51 is acknowledged but not mechanically instantiated per bead. L107 shared-surface reservation is missing for shared author files.

## 4. Orphaned-State Risk Register

| Superseded Orch-Uptime Bead | Migration Target | State That Must Migrate | Risk |
|---|---|---|---|
| A2 usage-limit detector | W1 quota | regex fixtures, recovery routing, false-positive cases | MED |
| A4 CAAM recovery ledger fields | W0A/W3b audit-policy | optional ledger fields and schema compatibility | MED |
| B3 mobile-eats arity/accept-stall | W2 preflight/approve | peer UX evidence and accept-stall semantics | LOW |
| B4 watcher register/load/fire | W1 serve/W3a coordinator | register/load/recent-fire evidence split | MED |
| B5 watcher doctor scope | W1 serve/W3b audit | doctor field scope and guarded launch evidence | MED |
| C2 frozen-projection scan | W2 scrub/W3b policy | scanner fixtures and warn-existing/fail-new policy | HIGH |
| C3 WOE ledger bootstrap | W3b audit | WOE-drain scoped blocker semantics | MED |
| C4 fleet sweep execution | W3a coordinator/W4 triage | peer-owned debt routing and sweep receipts | HIGH |
| W4 integration closeout | W4T | aggregate L112, amendment coverage, closeout proof | MED |

`orphaned_state_risk_count=9`. The plan maps all nine, but does not yet require a per-row supersession ledger proving what was copied, intentionally retained, or left peer-owned.

## 5. L-Rule Cross-Coverage Matrix

| L-rule | W0T | W0A | W1 | W2 | W3 | W4 | Gap |
|---|---|---|---|---|---|---|---|
| L29 NTM-only | Y | Y | Y | Y | Y | Y | no |
| L57 driver proof | - | - | Y | - | Y | - | serve/metrics must prove driver, not marker |
| L66 Jeff issue gate | - | - | - | - | - | - | named by dispatch, but not actually relevant unless upstream Jeff issue filed |
| L67 live truth | Y | - | Y | Y | Y | Y | live-vs-cached proof must be in W1/W3 fixtures |
| L70 same-tick chain | - | - | - | Y | Y | Y | W4 needs chain-if-capacity instruction |
| L91 four-state receipt | - | - | Y | Y | Y | - | W2P must keep post-send receipt separate |
| L101 continuous productivity | - | - | Y | - | Y | Y | W4 triage should create work or no-bead reasons same tick |
| L102 META-RULE cache | Y | - | - | - | Y | - | no explicit tick-start freshness gate |
| L119 source-not-value templates | Y | - | Y | Y | Y | Y | missing per-template source selector fields |
| L120 close-before-callback | Y | Y | Y | Y | Y | Y | callback template present, but quality-bar fields must join it |

`l_rule_coverage_gap_count=5`: L57 driver proof detail, L66 applicability mismatch, L101 outflow, L102 freshness gate, L119 source selectors.

## 6. Skillos Cross-Orch Coord-Step Check

Verdict: PARTIAL.

The plan names Wave 0 adoption of K/L/L29 and cites the skillos reply. It does not specify the full landing sequence:

1. skillos produces committed proposal/script/test artifacts.
2. flywheel records `producer=skillos`, `consumer=flywheel`, exact paths, and version/sha in `cross-orch-coordination.jsonl`.
3. flywheel reserves target doctrine/script/template paths.
4. flywheel applies only contract/adoption edits, not skillos-owned implementation history.
5. flywheel runs doctrine 3-surface/probe receipts where AGENTS/template rules change.
6. skillos receives ACK with adopted paths or explicit no-adopt reason.

Gap: "who edits flywheel AGENTS.md / template / script registry" is not assigned per bead.

## 7. Mission-Anchor Propagation Check

Verdict: NO.

The plan artifact has the footer, but per-bead callback and acceptance templates do not require `Mission-anchor: continuous-orchestrator-uptime-self-sustaining-fleet`. Phase 4 prompts should require the mission anchor in every evidence artifact and DONE envelope.

## 8. Quality-Bar Applicability Per Bead

| Bead | Rust | Python | CLI Canonical | README/Docs | Three Judges |
|---|---|---|---|---|---|
| W0T | n/a | n/a | yes | yes | yes |
| W0A | n/a | n/a | yes | n/a | yes |
| W1Q | n/a | maybe | yes | n/a | yes |
| W1M | n/a | maybe | yes | n/a | yes |
| W1S | n/a | maybe | yes | maybe | yes |
| W2S | n/a | maybe | yes | n/a | yes |
| W2P | n/a | maybe | yes | n/a | yes |
| W2D | n/a | maybe | yes | n/a | yes |
| W2A | n/a | maybe | yes | maybe | yes |
| W3aC | n/a | maybe | yes | maybe | yes |
| W3aP | n/a | maybe | yes | maybe | yes |
| W3bA | n/a | maybe | yes | maybe | yes |
| W3bP | n/a | maybe | yes | maybe | yes |
| W3bR | n/a | maybe | yes | maybe | yes |
| W4T | n/a | maybe | yes | yes | yes |

`quality_bar_subset_documented=yes`. Existing plan scores below the 9.5 auto-advance threshold and `STATE.json` has `quality_bar_passed=false`; Phase 4 cannot auto-advance until each bead prompt includes applicable subset fields and scores.

## 9. Dispatch-Tool-Contracts Compliance

| Contract Field | Plan Coverage | Gap |
|---|---|---|
| Socraticode K>=10 | present | Q count varies by lane; Phase 4 should require Q>=3, K=10 |
| File reservations | generic | no per-bead `files_reserved[]` list |
| Callback delivery | present | must include L112 probe fields, not just claimed sentinel |
| `br_close_executed` | present in Lane C | future prompts must close before DONE or say non-applicable only for plan-space |
| Proof-of-work invariant | partial | per-bead native/wrapper differential invariant required |
| Quality bar envelope | missing | add `quality_bar_passed`, judge scores, clean fields |
| Dispatch template skill reference | skill cited | not repeated in each wave prompt |

## 10. Findings Register

| ID | Severity | Finding | Required R2 Focus |
|---|---|---|---|
| CC-H1 | High | Shared-resource reservations are not explicit per bead and omit L107 shared-surface check. | Add per-bead reservation matrix. |
| CC-H2 | High | Quality bar cannot auto-advance: current scores are <9.5 and state says false. | Add per-bead quality subset + scoring fields. |
| CC-H3 | High | W2 ordering conflicts across artifacts; scrub must precede preflight. | Ratify one order in Phase 4. |
| CC-M1 | Medium | Required `00-PLAN.md` is absent; audit used `02-REFINE-r1.md`. | Produce or alias canonical plan artifact. |
| CC-M2 | Medium | Skillos handoff lacks actor/path/ACK sequence. | Add cross-orch landing checklist. |
| CC-M3 | Medium | Mission anchor is artifact-level, not enforced per bead callback. | Add footer/callback requirement. |
| CC-M4 | Medium | Superseded orch-uptime rows mapped but not migrated via a ledger. | Add supersession ledger table. |
| CC-M5 | Medium | L-rule matrix reveals five uncovered or underspecified rules. | Add L-rule-to-acceptance rows. |
| CC-L1 | Low | Lane C and refine differ on W1 parallel/sequential wording. | Use refine as canonical. |
| CC-L2 | Low | Dispatch-tool-contracts cited globally but not repeated in every prompt. | Put it in prompt template. |

Totals: critical=0, high=3, medium=5, low=2.

## 11. Convergence Verdict

`convergence_verdict=needs_r2_focus`.

The wave/bead architecture is sound and remains within the 15-bead cap. R2 should focus narrowly on `quality_bar_and_shared_resource_contracts`, plus ratifying scrub-before-preflight and the skillos landing sequence. No Joshua decision is needed.

## 12. Three-Judges Sniff

| Judge | Score | Read |
|---|---:|---|
| Jeff | 8.4 | Good native-first plan; wants exact per-bead file and CLI contracts before execution. |
| Donella | 8.8 | Strong wave feedback loops, but stocks/flows still leak through shared-resource and supersession ledgers. |
| Joshua | 8.2 | Practical cap and real migration path; not ready to execute until quality and reservation receipts are boring. |

Self-grade: B+/8.5. This audit is specific enough for R2 without expanding scope.

L112: `OK_ntm_surface_migration_audit_cross_cutting_r1`

Mission-anchor: continuous-orchestrator-uptime-self-sustaining-fleet
