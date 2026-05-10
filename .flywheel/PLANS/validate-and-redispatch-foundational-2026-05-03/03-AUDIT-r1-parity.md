---
title: "Phase 3 AUDIT r1 - Lens A Cross-Runtime Parity And Agent-Context Proof"
type: plan
created: 2026-05-04
frontmatter_source: scaffold-doc-frontmatter
---

# Phase 3 AUDIT r1 - Lens A Cross-Runtime Parity And Agent-Context Proof

Plan: `validate-everything-we-build-2026-05-03`
Lens: `cross-runtime-parity`
Status: `complete`
Findings: `4`
Critical: `0`
High: `3`
Zero round: `no`

## Skills Library Baseline

Required slash command attempted:

```bash
/flywheel:skills-best-practices "cross runtime parity codex claude agent context validation callback capture" --top=10 --include-content
```

Local CLI fallback result: `flywheel skills-best-practices` is not exposed in
this Codex shell (`ERR: unknown command: skills-best-practices`), so I used
`mcp__skill_search__query_skills_tool` with the same query.

Skills surfaced:

| skill | posture | reason |
|---|---|---|
| `socraticode` | adopt | Required for codebase claim audit; used 3 searches for parity, drift signal, and E2E fixture surfaces. |
| `data-quality-validation` | evaluate | Useful schema/contract lens, but not runtime-specific. |
| `codebase-audit` | adopt | General systematic audit pattern. |
| `request-validation` | evaluate | Relevant to receipt/schema validation but secondary to parity. |
| `multi-agent-swarm-workflow` | evaluate | Relevant to pane/callback coordination. |
| `research-triad` | skip | Broader external triangulation not needed for this plan-space parity pass. |
| `agent-evaluation` | evaluate | Relevant for future fixture harness quality. |

`skills_library_gap=none_for_audit_process; partial_for_codex_claude_parity_specific_skill`.

## Inputs Read

- `.flywheel/plans/validate-and-redispatch-foundational-2026-05-03/02-REFINE-r4.md`
- `.flywheel/plans/validate-and-redispatch-foundational-2026-05-03/00-PLAN.md`
- `.flywheel/plans/validate-and-redispatch-foundational-2026-05-03/01-RESEARCH-A.md`
- `.flywheel/plans/validate-and-redispatch-foundational-2026-05-03/01-RESEARCH-MEADOWS.md`
- `.flywheel/plans/validate-and-redispatch-foundational-2026-05-03/01-RESEARCH-MEADOWS-COMPONENTS.md`
- `.flywheel/plans/validate-and-redispatch-foundational-2026-05-03/04-BEADS-PREDRAFT.md`
- `AGENTS.md` L69 and L70
- `/tmp/codex-feedback-gap-probe.md`
- `~/.claude/skills/jeff-convergence-audit/SKILL.md`

## Acceptance Gate Results

| gate | verdict | notes |
|---|---|---|
| Identify runtime-facing mechanisms | pass | Callback validator, dispatch block, VALIDATE phase, doctor signals, capture parity, parity probe, and E2E smoke are named in final refine. |
| Classify Claude and Codex proof paths | partial | Codex agent-context path is detailed in B11; Claude path exists but is not carried into B12 E2E gates. |
| Verify B11 and B13 cover tool parity and Joshua-input capture parity | partial | B11 covers tool/runtime parity; B13 covers capture parity in final refine, but B13 lacks a full bead body in `04-BEADS-PREDRAFT.md`. |
| Verify `agent_context_probe_drift_count` has producer, measurement, consumer, threshold, fixture | fail | Producer/behavior and fixtures are implied; threshold/strict consumer are not specified in the final plan. |
| Verify every parity probe respects L69 | pass | B11 requires Codex probes via `ntm send` plus callback validation and classifies raw-shell/agent mismatch as drift. |
| Verify Codex unresponsive/crashed/frozen behavior | pass | `runtime_unresponsive` is named for timeout/unresponsive cases; frozen/crashed traumas are in B11 why-now evidence. |
| Verify E2E has Claude and Codex fixture for same primitive | fail | Final test plan says both runtimes, but B12 acceptance gate only names Codex parity fixture or q03g blocker. |
| Flag Claude hook treated as universal | partial | Final plan explicitly rejects Claude-first assumptions, but B13 under-specification still risks losing the capture parity mechanism at bead creation. |

## Runtime Mechanism Matrix

| mechanism | Claude proof path | Codex proof path | verdict |
|---|---|---|---|
| Dispatch validation block | valid Claude worker packet fixture in B02 | valid Codex worker packet fixture in B02 | partial: packet rendering only, not runtime execution |
| Callback validator | valid DONE fixture and Claude Bash context referenced in B11 | Codex `ntm send` probe plus callback parsing in B11 | partial: good design, needs B12 paired E2E |
| VALIDATE tick phase | generic callback receipt path | generic callback receipt path | partial: runtime-specific proof delegated to B11/B12 |
| Doctor signals | generic signal production | `agent_context_probe_drift_count`, `orchs_with_capture_gap_count` | partial: drift threshold missing |
| Capture parity | Claude hook is named as existing mechanism | agent-mail or `ntm send` wrapper first, pane-tail poller last | partial: B13 full body missing |
| Parity probe | Claude agent Bash context where applicable | Codex agent callback path; timeout = `runtime_unresponsive` | partial: q03g blocker policy ambiguous |
| E2E smoke | final plan requires both runtimes generally | B12 explicitly names Codex parity fixture | fail: B12 must name paired Claude+Codex fixture |

## Findings

| id | severity | criticality | component/bead | file:line | finding | evidence | recommended change | decision_needed |
|---|---|---|---|---|---|---|---|---|
| PARITY-001 | high | must_fix_before_beads | B13 `orch capture parity rule/signal/mechanisms` | `.flywheel/plans/validate-and-redispatch-foundational-2026-05-03/02-REFINE-r4.md:85`, `:101`; `.flywheel/plans/validate-and-redispatch-foundational-2026-05-03/04-BEADS-PREDRAFT.md:586` | The final plan adds B13 as required runtime capture parity work, but the pre-draft bead corpus still only contains B01-B12. Phase 4 can create an underspecified or missing B13 unless the audit/register forces a full bead body. | Final refine says B13 is new and required for L71 capture parity, while the pre-draft jumps from B11 to B12 and has no B13 acceptance gates. `/tmp/codex-feedback-gap-probe.md` confirms capture parity is operationally P0-shaped. | Before Phase 4 `br create`, add a full B13 body with goal, why now, 5+ machine-verifiable acceptance gates, DOD, dependencies, rollback/dry-run, and explicit links to xap2/L71/`orchs_with_capture_gap_count`. | no |
| PARITY-002 | high | must_fix_before_beads | B04/B11 doctor drift signal | `.flywheel/plans/validate-and-redispatch-foundational-2026-05-03/02-REFINE-r4.md:63`; `.flywheel/plans/validate-and-redispatch-foundational-2026-05-03/04-BEADS-PREDRAFT.md:282`, `:605`, `:609` | `agent_context_probe_drift_count` lacks a concrete threshold and strict consumer in the final plan. That leaves raw-shell/agent mismatch visible but not necessarily blocking parity work. | Final refine defines producer/behavior, B04 says emit the signal only "if those producers exist", and B11 tests drift, but no line states `>=1` blocks parity beads, integration, or rollout. L69 forbids treating drift as pass. | Add an explicit B04/B11 gate: `agent_context_probe_drift_count>=1` fails parity-bead validation and blocks strict rollout unless accompanied by `runtime_unresponsive`/retry work or Joshua-approved defer. Include fixture and doctor JSON field. | no |
| PARITY-003 | high | must_fix_before_beads | B12 E2E smoke harness | `.flywheel/plans/validate-and-redispatch-foundational-2026-05-03/02-REFINE-r4.md:194`; `.flywheel/plans/validate-and-redispatch-foundational-2026-05-03/04-BEADS-PREDRAFT.md:648`, `:656` | The final plan requires cross-runtime tests to exercise Claude and Codex separately, but B12's acceptance gates only require a Codex parity fixture or q03g blocker. The e2e closeout could pass without proving the same primitive through Claude and Codex. | Final refine line 194 says Claude hook proof cannot stand in for Codex and Codex raw shell proof cannot stand in for agent callback proof. B12 gate 7 only names Codex. | Change B12 acceptance gates to require a paired fixture for the same validation primitive: `claude_agent_context_fixture=<cmd>:PASS` and `codex_agent_context_fixture=<cmd>:PASS|blocked:q03g`, plus a negative raw-shell/agent drift fixture. | no |
| PARITY-004 | medium | can_polish | B11/q03g dependency policy | `.flywheel/plans/validate-and-redispatch-foundational-2026-05-03/04-BEADS-PREDRAFT.md:608`, `:632`; `.flywheel/plans/validate-and-redispatch-foundational-2026-05-03/02-REFINE-r4.md:203` | B11 allows "fixture-only or blocks" when q03g is absent, but the plan does not define which parity claims may ship fixture-only and which require the real parity probe binary. | B11 says document integration with q03g and run fixture-only or block if absent; the trade-off section says schema/mechanism first and signal later, but no decision rule separates acceptable fixture-only work from parity proof. | Add a Joshua-disposes decision or B11 gate: fixture-only may prove schema/renderer behavior, but any claim that an active runtime is parity-compliant requires q03g or an equivalent in-agent live probe. | yes |

## Findings Register Rows

| id | lens | criticality | component/bead | file:line | finding | evidence | recommended action | owner phase | decision_needed | status |
|---|---|---|---|---|---|---|---|---|---|---|
| PARITY-001 | cross-runtime-parity | must_fix_before_beads | B13 | `02-REFINE-r4.md:85`; `04-BEADS-PREDRAFT.md:586` | B13 is required in final refine but lacks a full pre-draft bead body. | Final refine added B13; pre-draft only has B01-B12. | Add full B13 body before Phase 4 bead creation. | Phase 4 DECOMPOSE | no | open |
| PARITY-002 | cross-runtime-parity | must_fix_before_beads | B04/B11 | `02-REFINE-r4.md:63`; `04-BEADS-PREDRAFT.md:282` | `agent_context_probe_drift_count` lacks explicit threshold/strict consumer. | Signal visible but not blocking. | Add `>=1` fail/block behavior for parity validation. | Phase 4 DECOMPOSE | no | open |
| PARITY-003 | cross-runtime-parity | must_fix_before_beads | B12 | `02-REFINE-r4.md:194`; `04-BEADS-PREDRAFT.md:656` | B12 does not require paired Claude+Codex E2E fixture for same primitive. | Final plan says both runtimes; B12 only names Codex fixture. | Add paired Claude and Codex E2E gates. | Phase 4 DECOMPOSE | no | open |
| PARITY-004 | cross-runtime-parity | can_polish | B11/q03g | `04-BEADS-PREDRAFT.md:608`; `04-BEADS-PREDRAFT.md:632` | q03g absence policy is ambiguous. | "fixture-only or blocks" lacks decision rule. | Decide fixture-only vs live-probe boundary. | Joshua-disposes / Phase 4 | yes | open |

## Notes On Passing Coverage

- L69 itself is strong: it explicitly forbids raw shell proof for agent-runtime claims and classifies timeouts as `runtime_unresponsive`, not raw-shell fallback (`AGENTS.md:1031` through `:1067`).
- B11 carries the right core mechanic: Codex probes go through `ntm send`, Claude probes use agent Bash context, raw-shell pass plus agent fail returns `context_drift`, and timeout returns `runtime_unresponsive` (`04-BEADS-PREDRAFT.md:600` through `:609`).
- The final refine correctly promotes runtime parity to goal/rule level rather than treating it as a Claude-hook-shaped information flow (`02-REFINE-r4.md:35` through `:39`, `:47` through `:50`).
- The codex-feedback gap is consumed, not ignored: L71 and `orchs_with_capture_gap_count` are present in final refine (`02-REFINE-r4.md:48`, `:59`, `:74`).

## Convergence Verdict

This lens does not reach zero in r1.

- `critical=0`
- `high=3`
- `zero_round=no`

The high findings are fixable in Phase 4 prep by tightening B13, B04/B11, and
B12 before bead creation. No finding requires source implementation during the
audit phase.
