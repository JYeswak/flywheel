---
title: "DAG Rebuild Worker Beta Output - L3 Quality + Plan-Skill Beads"
type: plan
created: 2026-05-06
frontmatter_source: scaffold-doc-frontmatter
---

# DAG Rebuild Worker Beta Output - L3 Quality + Plan-Skill Beads

Task: `dag-rebuild-beta-l3-quality-2026-05-05`
Scope: symbolic bead specs only; `.beads/` read-only; no `br create`.
Output owner: flywheel:3 codex worker.

## Self-Grade

| Check | Score | Evidence |
|---|---:|---|
| Jeff convergence | 9.6 | `jeff-corpus` searches found reusable fail-closed callback validation, quality display/test, LLM-judge JSON, and polish-loop patterns. |
| Donella trace | 9.6 | Every bead names stock, producer/inflow, consumer/outflow, feedback consequence, and leverage point. |
| Joshua bar | 9.7 | Specs are short, mechanical, acceptance-heavy, and avoid new worker dispatch or `.beads/` mutation. |
| Composite | 9.6 | Median acceptance bullets: 7; L112 commands: 11; L110 rows: 11. |

quality_bar_passed=yes
rust_clean=n/a
python_clean=n/a
cli_canonical=yes
readme_quality=yes

## Evidence Register

| ID | Evidence | Grep anchor / expected substring |
|---|---|---|
| E-SPEC-L3 | `/Users/josh/Developer/flywheel/.flywheel/plans/wire-or-explain-tick-gate-2026-05-04/05-DAG-REBUILD-SPEC-2026-05-05.md:58` | `7-ledger architecture` |
| E-SPEC-BETA | `/Users/josh/Developer/flywheel/.flywheel/plans/wire-or-explain-tick-gate-2026-05-04/05-DAG-REBUILD-SPEC-2026-05-05.md:103` | `beta-2: L3 quality + E plan-skill` |
| E-SPEC-DEPS | `/Users/josh/Developer/flywheel/.flywheel/plans/wire-or-explain-tick-gate-2026-05-04/05-DAG-REBUILD-SPEC-2026-05-05.md:137` | `Dependency wiring` |
| E-SPEC-FMC | `/Users/josh/Developer/flywheel/.flywheel/plans/wire-or-explain-tick-gate-2026-05-04/05-DAG-REBUILD-SPEC-2026-05-05.md:154` | `FMC-EXP-F1` |
| E-INTENT-C | `/Users/josh/Developer/flywheel/.flywheel/plans/wire-or-explain-tick-gate-2026-05-04/00-INTENT.md:286` | `Quality-skill auto-routing` |
| E-INTENT-E | `/Users/josh/Developer/flywheel/.flywheel/plans/wire-or-explain-tick-gate-2026-05-04/00-INTENT.md:314` | `/flywheel:plan skill gaps` |
| E-R3 | `/Users/josh/Developer/flywheel/.flywheel/plans/wire-or-explain-tick-gate-2026-05-04/03-AUDIT-r3-confirmation.md:44` | `IDEMP-EXP-F1` |
| E-PLAN-122 | `/Users/josh/.claude/commands/flywheel/plan.md:122` | `quality_bar_passed=true` |
| E-PLAN-392 | `/Users/josh/.claude/commands/flywheel/plan.md:392` | `5th gate (quality bar)` |
| E-DISPATCH-FIELDS | `/Users/josh/.claude/commands/flywheel/_shared/dispatch-template.md:451` | `quality_bar_passed=<yes|no>` |
| E-JEFF-QB | `/Users/josh/Developer/jeff-corpus/meta_skill/src/output/builders.rs:424` | `Build a quality bar string` |
| E-JEFF-CB | `/Users/josh/Developer/jeff-corpus/flywheel_connectors/crates/fcp-oauth/src/oauth2.rs:246` | `Validate a provider callback exactly once` |
| E-JEFF-JUDGE | `/Users/josh/Developer/jeff-corpus/claude_code_agent_farm/best_practices_guides/GENAI_LLM_OPS_BEST_PRACTICES.md:1351` | `judge_model` |
| E-JEFF-POLISH | `/Users/josh/Developer/jeff-corpus/agent_flywheel_clawdbot_skills_and_integrations/skills/beads-workflow/SKILL.md:91` | `Polishing Protocol` |

## Jeff Convergence Summary

| Query | Pattern | Disposition |
|---|---|---|
| `quality_bar` | Quality bar code and tests use explicit score bands and assertions. | ADOPT deterministic threshold evidence; EXTEND from visual score to close-gate evidence rows. |
| `callback_validator` | OAuth callback validation consumes callbacks exactly once and fails closed on invalid state. | ADOPT fail-closed validator semantics; AVOID accepting partial envelopes. |
| `judges` | LLM judge examples emit structured JSON with score, reasoning, and issue list. | ADOPT per-judge JSON fields; AVOID stale model IDs from examples. |
| `polish_round` | Bead workflow and methodology docs require repeated polish until convergence. | ADOPT convergence loop; EXTEND with L111 self-pass rows. |

## Common L110 Row Shape

```json
{"ts":"<iso>","artifact_id":"wire-or-explain-l3-l5-quality-2026-05-05:<artifact-path>","artifact_class":"quality_bar_evidence","stock":"<int>","consumer":"plan-close-5th-gate","owner":"plan-author","deferral_until":null,"deferred_reason":null,"verification_probe":"jq .quality_bar_evidence[] STATE.json","tick_consequence":"error","drain_receipt":{"composite":"<num>","jeff":"<num>","donella":"<num>","joshua":"<num>"},"dedup_key":"<plan-slug>:<artifact-path>:<sha256-prefix>"}
```

## WOE-EXP-B31 - Dispatch Template Inherits 4 Skill Auto-Routes

Priority: P0
Items: C1+C2+C3+C4
Parents: `flywheel-2ypj`, `flywheel-35zx`
Depends on: none inside beta-2.
Dedup key: `wire-or-explain-l3-l5-quality-2026-05-05:dispatch-template-skill-auto-routes:sha256-prefix`

Body: Make the shared dispatch template require write-time skill routing for Rust, Python, CLI, and README-shaped work. The template emits L3 quality rows before callback acceptance, so C1-C4 become one template PR instead of four drifting reminders. The result feeds the close gate and shadow/enforce parents without mutating `.beads/`.

Acceptance:
- Producer event: dispatch packet render writes one row shaped `{"artifact_class":"quality_bar_evidence","rust_clean":"yes|no|n/a","python_clean":"yes|no|n/a","cli_canonical":"yes|no","readme_quality":"yes|no|n/a","dedup_key":"<plan>:dispatch-template:<sha>"}`.
- Consumer: callback-validator reads the four skill fields, and the 5th gate at `plan.md:392` refuses auto-advance when any applicable field is not clean.
- L112 command: `rg -n 'rust_clean|python_clean|cli_canonical|readme_quality' /Users/josh/.claude/commands/flywheel/_shared/dispatch-template.md` returns all four field names.
- Self-pass: this bead's own apply callback reports `rust_clean=n/a python_clean=n/a cli_canonical=yes readme_quality=yes` and a quality row for the edited template.
- Beta-alpha integration: `flywheel-2ypj` consumes the row at tick close; `flywheel-35zx` decides shadow/enforce behavior from the same row.
- Jeff pattern adopted: fail-closed callback validation from E-JEFF-CB; quality threshold evidence from E-JEFF-QB.
- Donella trace: stock is unrouted skill-shaped artifacts; inflow is dispatch render; outflow is validator refusal; leverage is #5 rules.

L110 row example:

```json
{"ts":"2026-05-05T00:00:00Z","artifact_id":"wire-or-explain-l3-l5-quality-2026-05-05:/Users/josh/.claude/commands/flywheel/_shared/dispatch-template.md","artifact_class":"quality_bar_evidence","stock":"1","consumer":"callback-validator+plan-close-5th-gate","owner":"dispatch-template","deferral_until":null,"deferred_reason":null,"verification_probe":"rg -n 'rust_clean|python_clean|cli_canonical|readme_quality' /Users/josh/.claude/commands/flywheel/_shared/dispatch-template.md","tick_consequence":"error","drain_receipt":{"composite":"9.6","jeff":"9.6","donella":"9.6","joshua":"9.7"},"dedup_key":"wire-or-explain-l3-l5-quality-2026-05-05:/Users/josh/.claude/commands/flywheel/_shared/dispatch-template.md:sha256-prefix"}
```

## WOE-EXP-B32 - Callback Validator Gates 3-Judges Scores

Priority: P0
Item: C5
Parents: `flywheel-2ypj`, `flywheel-35zx`
Depends on: none inside beta-2.
Dedup key: `wire-or-explain-l3-l5-quality-2026-05-05:callback-validator-3-judges:sha256-prefix`

Body: Extend callback validation so Jeff, Donella, Joshua, and composite scores are mandatory and thresholded before DONE can integrate. This turns the 3-judges sniff from narrative self-grade into a mechanical pass/fail gate. It preserves worker autonomy by returning re-pass-required instead of paging Joshua.

Acceptance:
- Producer event: worker callback receipt writes `{"artifact_class":"quality_bar_evidence","jeff_score":9.0,"donella_score":9.0,"joshua_score":9.0,"composite":9.5,"dedup_key":"<plan>:callback:<sha>"}`.
- Consumer: callback-validator rejects `quality_bar_passed=yes` when any judge is below 9.0 or composite is below 9.5.
- L112 command: `rg -n 'jeff_score|donella_score|joshua_score|composite_score' /Users/josh/.claude/commands/flywheel/_shared/dispatch-template.md` returns the four score fields.
- Self-pass: validator implementation callback must carry the four scores and a sample failing-envelope fixture.
- Beta-alpha integration: `flywheel-2ypj` blocks close on failed receipts; `flywheel-35zx` can run shadow mode before enforce.
- Jeff pattern adopted: structured judge JSON from E-JEFF-JUDGE, combined with single-use validation from E-JEFF-CB.
- Donella trace: stock is ungraded artifacts; inflow is callback receipt; outflow is fail-closed validation; leverage is #6 information flow plus #5 rules.

L110 row example:

```json
{"ts":"2026-05-05T00:00:00Z","artifact_id":"wire-or-explain-l3-l5-quality-2026-05-05:callback-validator","artifact_class":"quality_bar_evidence","stock":"1","consumer":"callback-validator","owner":"flywheel:1","deferral_until":null,"deferred_reason":null,"verification_probe":"rg -n 'jeff_score|donella_score|joshua_score|composite_score' /Users/josh/.claude/commands/flywheel/_shared/dispatch-template.md","tick_consequence":"error","drain_receipt":{"composite":"9.6","jeff":"9.6","donella":"9.6","joshua":"9.7"},"dedup_key":"wire-or-explain-l3-l5-quality-2026-05-05:callback-validator:sha256-prefix"}
```

## WOE-EXP-B33 - Publishability-Bar Runner Auto-Fire On Doc Edits

Priority: P1
Item: C6
Parents: `flywheel-2ypj`, `flywheel-35zx`
Depends on: none inside beta-2.
Dedup key: `wire-or-explain-l3-l5-quality-2026-05-05:publishability-bar-doc-edits:sha256-prefix`

Body: Wire doc-edit events to the publishability bar so README, AGENTS, plan, and public-facing docs get scored when changed. The runner writes L3 evidence rows and routes low scores to polish instead of letting publishability debt sit as an afterthought. This bead is warn-level because it improves documentation quality rather than blocking core safety.

Acceptance:
- Producer event: doc-edit detection writes `{"artifact_class":"quality_bar_evidence","publishability_bar_score_value":5,"artifact_path":"<doc>","dedup_key":"<plan>:publishability:<sha>"}`.
- Consumer: tick-close gate reads the row and warns or blocks according to publishability threshold policy.
- L112 command: `rg -n 'publishability_bar_score_value|publishability-bar' /Users/josh/Developer/flywheel` returns the runner/test surfaces.
- Self-pass: this bead's doc changes run the publishability command and include the score row in STATE.json quality evidence.
- Beta-alpha integration: `flywheel-2ypj` receives warn/error status; `flywheel-35zx` controls shadow/enforce rollout.
- Jeff pattern adopted: quality bar threshold tests from E-JEFF-QB; polish-loop convergence from E-JEFF-POLISH.
- Donella trace: stock is low-quality docs; inflow is doc edits; outflow is publishability scoring plus polish routing; leverage is #6 information flow.

L110 row example:

```json
{"ts":"2026-05-05T00:00:00Z","artifact_id":"wire-or-explain-l3-l5-quality-2026-05-05:<doc-path>","artifact_class":"quality_bar_evidence","stock":"1","consumer":"tick-close-gate","owner":"doc-author","deferral_until":null,"deferred_reason":null,"verification_probe":"rg -n 'publishability_bar_score_value|publishability-bar' /Users/josh/Developer/flywheel","tick_consequence":"warn","drain_receipt":{"composite":"9.6","jeff":"9.6","donella":"9.6","joshua":"9.7"},"dedup_key":"wire-or-explain-l3-l5-quality-2026-05-05:<doc-path>:sha256-prefix"}
```

## WOE-EXP-B34 - Dispatch Template L111 Inheritance + Bead Acceptance Gate

Priority: P0
Item: C7
Parents: `flywheel-2ypj`, `flywheel-35zx`
Depends on: WOE-EXP-B31.
Dedup key: `wire-or-explain-l3-l5-quality-2026-05-05:dispatch-template-l111-inheritance:sha256-prefix`

Body: Make every generated dispatch inherit L111 fields and require bead acceptance text to name the quality gate. This closes the gap where a worker can receive a rich task but callback without the quality fields. The template becomes the producer, and the callback validator plus plan 5th gate become the consumers.

Acceptance:
- Producer event: dispatch-template render writes `{"artifact_class":"quality_bar_evidence","l111_inherited":true,"acceptance_gate_named":true,"dedup_key":"<plan>:dispatch-l111:<sha>"}`.
- Consumer: callback-validator rejects missing inherited fields; 5th gate checks STATE rows before `audit_disposition`.
- L112 command: `rg -n 'quality_bar_passed|quality_bar_blocker|Required callback envelope additions' /Users/josh/.claude/commands/flywheel/_shared/dispatch-template.md` returns the L111 block.
- Self-pass: the bead applying this template change must be dispatched through the same inherited L111 field set.
- Beta-alpha integration: depends on B31's skill auto-route fields, then feeds `flywheel-2ypj` close gate and `flywheel-35zx` enforcement state.
- Jeff pattern adopted: E-JEFF-CB validates a provider callback exactly once; apply the same fail-closed pattern to worker callback fields.
- Donella trace: stock is dispatches without quality inheritance; inflow is template render; outflow is callback refusal; leverage is #5 rules.

L110 row example:

```json
{"ts":"2026-05-05T00:00:00Z","artifact_id":"wire-or-explain-l3-l5-quality-2026-05-05:dispatch-template-l111","artifact_class":"quality_bar_evidence","stock":"1","consumer":"callback-validator+plan-close-5th-gate","owner":"dispatch-template","deferral_until":null,"deferred_reason":null,"verification_probe":"rg -n 'quality_bar_passed|quality_bar_blocker|Required callback envelope additions' /Users/josh/.claude/commands/flywheel/_shared/dispatch-template.md","tick_consequence":"error","drain_receipt":{"composite":"9.6","jeff":"9.6","donella":"9.6","joshua":"9.7"},"dedup_key":"wire-or-explain-l3-l5-quality-2026-05-05:dispatch-template-l111:sha256-prefix"}
```

## WOE-EXP-B35 - Callback Envelope Schema Requires 7 L111 Fields

Priority: P0
Item: C8
Parents: `flywheel-2ypj`, `flywheel-35zx`
Depends on: WOE-EXP-B32, WOE-EXP-B34.
Dedup key: `wire-or-explain-l3-l5-quality-2026-05-05:callback-envelope-seven-fields:sha256-prefix`

Body: Extend the callback schema so missing quality fields are schema failures, not reviewer judgment calls. The seven L111 fields are `quality_bar_passed`, three judge scores, `rust_clean`, `python_clean`, `cli_canonical`, and `readme_quality`. The schema also preserves `quality_bar_blocker` for honest non-pass callbacks.

Acceptance:
- Producer event: callback parse writes `{"artifact_class":"quality_bar_evidence","schema_valid":true,"missing_l111_fields":[],"dedup_key":"<plan>:callback-schema:<sha>"}`.
- Consumer: callback-validator refuses DONE when any required field is missing or contradicts thresholds.
- L112 command: `rg -n 'quality_bar_passed|rust_clean|python_clean|cli_canonical|readme_quality' /Users/josh/.claude/commands/flywheel/_shared/dispatch-template.md` returns the required envelope fields.
- Self-pass: schema patch callback includes all seven fields and one negative fixture proving missing fields fail.
- Beta-alpha integration: schema failures feed `flywheel-2ypj` unresolved close rows; `flywheel-35zx` decides warning versus enforce.
- Jeff pattern adopted: E-JEFF-CB state validation refuses malformed callbacks; use the same strict parser shape.
- Donella trace: stock is accepted callbacks with missing fields; inflow is callback parse; outflow is schema rejection; leverage is #5 rules.

L110 row example:

```json
{"ts":"2026-05-05T00:00:00Z","artifact_id":"wire-or-explain-l3-l5-quality-2026-05-05:callback-envelope-schema","artifact_class":"quality_bar_evidence","stock":"1","consumer":"callback-validator","owner":"flywheel:1","deferral_until":null,"deferred_reason":null,"verification_probe":"rg -n 'quality_bar_passed|rust_clean|python_clean|cli_canonical|readme_quality' /Users/josh/.claude/commands/flywheel/_shared/dispatch-template.md","tick_consequence":"error","drain_receipt":{"composite":"9.6","jeff":"9.6","donella":"9.6","joshua":"9.7"},"dedup_key":"wire-or-explain-l3-l5-quality-2026-05-05:callback-envelope-schema:sha256-prefix"}
```

## WOE-EXP-B36 - `quality_bar_passed` Phase 5 Close Gate Enforcement

Priority: P0
Item: E1
Parents: `flywheel-2ypj`, `flywheel-35zx`
Depends on: WOE-EXP-B31, WOE-EXP-B32.
Dedup key: `wire-or-explain-l3-l5-quality-2026-05-05:phase5-quality-close-gate:sha256-prefix`

Body: Enforce `quality_bar_passed` before Phase 5 closes or auto-advances, and absorb FMC-EXP-F1 with a fleet-wide pending-count doctor field. Plans without quality evidence become polish work, not Joshua questions. The gate is recursive, so first ship uses a bootstrap row that must later replay as normal evidence.

Acceptance:
- Producer event: plan-close writes `{"artifact_class":"quality_bar_evidence","quality_bar_passed":true,"plan_state_quality_bar_pending_count":0,"warn_threshold":20,"error_threshold":50,"dedup_key":"<plan>:phase5-close:<sha>"}`.
- Consumer: 5th gate at `plan.md:392` reads `STATE.json.quality_bar_evidence[]`; doctor exposes `plan_state_quality_bar_evidence_present_rate_24h` and `plan_state_quality_bar_pending_count`.
- L112 command: `jq -e '.quality_bar_passed == true and ([.quality_bar_evidence[]? | select(.composite < 9.5 or .jeff_score < 9.0 or .donella_score < 9.0 or .joshua_score < 9.0)] | length == 0)' STATE.json` returns true.
- Self-pass: per BR-EXP-F2, this bead writes `bootstrap=true` on first install and then replays without bootstrap to prove the gate enforces itself.
- Beta-alpha integration: consumes B31 skill fields and B32 judge scores, then blocks `flywheel-2ypj` close and routes `flywheel-35zx` shadow/enforce.
- Jeff pattern adopted: deterministic threshold tests from E-JEFF-QB and repeated callback refusal from E-JEFF-CB.
- Donella trace: stock is plans with missing quality evidence; inflow is plan-close attempt; outflow is close refusal or polish spawn; leverage is #5 rules.

L110 row example:

```json
{"ts":"2026-05-05T00:00:00Z","artifact_id":"wire-or-explain-l3-l5-quality-2026-05-05:STATE.json","artifact_class":"quality_bar_evidence","stock":"1","consumer":"plan-close-5th-gate","owner":"plan-author","deferral_until":null,"deferred_reason":null,"verification_probe":"jq -e '.quality_bar_passed == true and ([.quality_bar_evidence[]? | select(.composite < 9.5 or .jeff_score < 9.0 or .donella_score < 9.0 or .joshua_score < 9.0)] | length == 0)' STATE.json","tick_consequence":"error","drain_receipt":{"composite":"9.6","jeff":"9.6","donella":"9.6","joshua":"9.7"},"dedup_key":"wire-or-explain-l3-l5-quality-2026-05-05:STATE.json:sha256-prefix"}
```

## WOE-EXP-B37 - 3-Judges Mandatory Phase 3 Audit Lens

Priority: P0
Item: E2
Parents: `flywheel-2ypj`, `flywheel-35zx`
Depends on: WOE-EXP-B32.
Dedup key: `wire-or-explain-l3-l5-quality-2026-05-05:phase3-three-judges-lens:sha256-prefix`

Body: Add a mandatory Phase 3 audit lens that records Jeff, Donella, Joshua, and composite scores before convergence can be claimed. Audit outputs without judge rows are incomplete artifacts. This is the Phase 3 producer for the same evidence consumed later by the Phase 5 close gate, keeping convergence and close evidence aligned.

Acceptance:
- Producer event: Phase 3 audit write emits `{"artifact_class":"quality_bar_evidence","audit_lens":"3-judges","jeff_score":9.0,"donella_score":9.0,"joshua_score":9.0,"composite":9.5,"dedup_key":"<plan>:phase3-judges:<sha>"}`.
- Consumer: Phase 3 convergence check and 5th gate both read the judge rows before `auto_advance`.
- L112 command: `rg -n 'jeff_score|donella_score|joshua_score|composite' .flywheel/plans/*/03-AUDIT-*.md` returns judge rows for current plans.
- Self-pass: this bead's own audit artifact includes all three judge scores and no individual score below 9.0.
- Beta-alpha integration: feeds `flywheel-2ypj` quality evidence and allows `flywheel-35zx` to shadow missing-judge failures first.
- Jeff pattern adopted: E-JEFF-JUDGE structured JSON with score and reasoning; AVOID relying on prose-only judge summaries.
- Donella trace: stock is audits without judge evidence; inflow is Phase 3 audit write; outflow is convergence refusal; leverage is #6 information flow and #5 rules.

L110 row example:

```json
{"ts":"2026-05-05T00:00:00Z","artifact_id":"wire-or-explain-l3-l5-quality-2026-05-05:03-AUDIT.md","artifact_class":"quality_bar_evidence","stock":"1","consumer":"phase3-convergence+plan-close-5th-gate","owner":"plan-author","deferral_until":null,"deferred_reason":null,"verification_probe":"rg -n 'jeff_score|donella_score|joshua_score|composite' .flywheel/plans/*/03-AUDIT-*.md","tick_consequence":"error","drain_receipt":{"composite":"9.6","jeff":"9.6","donella":"9.6","joshua":"9.7"},"dedup_key":"wire-or-explain-l3-l5-quality-2026-05-05:03-AUDIT.md:sha256-prefix"}
```

## WOE-EXP-B38 - Phase 5 Polish Quality Measurement

Priority: P1
Item: E3
Parents: `flywheel-2ypj`, `flywheel-35zx`
Depends on: WOE-EXP-B36, WOE-EXP-B37.
Dedup key: `wire-or-explain-l3-l5-quality-2026-05-05:phase5-polish-quality:sha256-prefix`

Body: Measure each Phase 5 polish round with skill-clean and judge-score evidence instead of treating polish as informal cleanup. The bead records iterations, changed artifacts, and remaining blocker classes. Phase 5 can still warn rather than halt for non-critical polish, but the evidence must exist before closure.

Acceptance:
- Producer event: polish round completion writes `{"artifact_class":"quality_bar_evidence","quality_bar_iterations":1,"changed_artifacts":["<path>"],"blockers":[],"dedup_key":"<plan>:phase5-polish:<sha>"}`.
- Consumer: Phase 5 close gate reads iteration rows and refuses closure when required polish evidence is absent.
- L112 command: `jq -e '.quality_bar_evidence[]? | select(.quality_bar_iterations >= 1)' STATE.json` returns at least one row after a polish round.
- Self-pass: the worker closing this bead records its own quality-bar iteration count and score row.
- Beta-alpha integration: `flywheel-2ypj` blocks if polish evidence is missing; `flywheel-35zx` starts in shadow for warn-only polish debt.
- Jeff pattern adopted: E-JEFF-POLISH says repeat polish until steady-state; adopt measured iterations rather than arbitrary count.
- Donella trace: stock is unmeasured polish debt; inflow is Phase 5 edits; outflow is iteration evidence and close gate; leverage is #6 information flow.

L110 row example:

```json
{"ts":"2026-05-05T00:00:00Z","artifact_id":"wire-or-explain-l3-l5-quality-2026-05-05:phase5-polish","artifact_class":"quality_bar_evidence","stock":"1","consumer":"plan-close-5th-gate","owner":"plan-author","deferral_until":null,"deferred_reason":null,"verification_probe":"jq -e '.quality_bar_evidence[]? | select(.quality_bar_iterations >= 1)' STATE.json","tick_consequence":"warn","drain_receipt":{"composite":"9.6","jeff":"9.6","donella":"9.6","joshua":"9.7"},"dedup_key":"wire-or-explain-l3-l5-quality-2026-05-05:phase5-polish:sha256-prefix"}
```

## WOE-EXP-B39 - Phase 4 Bead Description Quality Auto-Mining

Priority: P1
Item: E4
Parents: `flywheel-2ypj`, `flywheel-35zx`
Depends on: WOE-EXP-B31, WOE-EXP-B32.
Dedup key: `wire-or-explain-l3-l5-quality-2026-05-05:phase4-bead-description-quality:sha256-prefix`

Body: Make Phase 4 bead bodies measurable by mining description length, seven-field coverage, acceptance bullets, testing obligations, and L112 commands. Thin beads become quality evidence debt before implementation begins. The existing bead-quality-mining surface becomes a producer, not only a retroactive cleanup.

Acceptance:
- Producer event: Phase 4 bead draft writes `{"artifact_class":"quality_bar_evidence","bead_id":"<symbolic-or-real>","body_chars":400,"acceptance_bullets":5,"l112_commands":1,"dedup_key":"<plan>:bead-body:<sha>"}`.
- Consumer: bead-quality-mining and 5th gate read rows before implementation dispatch.
- L112 command: `rg -n '^## WOE-EXP-B|Acceptance:|L112 command:' .flywheel/plans/*/06-DAG-REBUILD-WORKER-*.md` returns bead specs with evidence commands.
- Self-pass: this beta output has 11 bead sections, each with acceptance bullets and L112 command text.
- Beta-alpha integration: `flywheel-2ypj` blocks close on missing quality rows; `flywheel-35zx` controls migration from retroactive to proactive mining.
- Jeff pattern adopted: E-JEFF-POLISH bead checklist requires self-contained, testable beads with dependencies explicit.
- Donella trace: stock is thin bead descriptions; inflow is Phase 4 draft; outflow is auto-mining evidence; leverage is #6 information flow.

L110 row example:

```json
{"ts":"2026-05-05T00:00:00Z","artifact_id":"wire-or-explain-l3-l5-quality-2026-05-05:WOE-EXP-B39","artifact_class":"quality_bar_evidence","stock":"1","consumer":"bead-quality-mining+plan-close-5th-gate","owner":"plan-author","deferral_until":null,"deferred_reason":null,"verification_probe":"rg -n '^## WOE-EXP-B|Acceptance:|L112 command:' .flywheel/plans/*/06-DAG-REBUILD-WORKER-*.md","tick_consequence":"warn","drain_receipt":{"composite":"9.6","jeff":"9.6","donella":"9.6","joshua":"9.7"},"dedup_key":"wire-or-explain-l3-l5-quality-2026-05-05:WOE-EXP-B39:sha256-prefix"}
```

## WOE-EXP-B40 - Isomorphic Simplification Audit Lens

Priority: P1
Item: E5
Parents: `flywheel-2ypj`, `flywheel-35zx`
Depends on: WOE-EXP-B37.
Dedup key: `wire-or-explain-l3-l5-quality-2026-05-05:isomorphic-audit-lens:sha256-prefix`

Body: Add `/simplify-and-refactor-code-isomorphically` as a Phase 3 audit lens for plans that create overlapping primitives. The lens must prove behavior-preserving consolidation or explicitly reject simplification. This prevents quality work from multiplying surfaces when one ledger or validator can serve two consumers.

Acceptance:
- Producer event: Phase 3 audit writes `{"artifact_class":"quality_bar_evidence","audit_lens":"isomorphic-simplification","isomorphism_verdict":"pass|reject","dedup_key":"<plan>:isomorphic-lens:<sha>"}`.
- Consumer: Phase 3 convergence and 5th gate read the lens before close.
- L112 command: `rg -n 'isomorphism|simplify-and-refactor-code-isomorphically|one primitive' .flywheel/plans/*/03-AUDIT-*.md` returns the lens verdict.
- Self-pass: this bead declares no new primitive when L5 is a typed view of L3 unless evidence proves separate behavior.
- Beta-alpha integration: `flywheel-2ypj` consumes missing-lens rows; `flywheel-35zx` starts warn-level before enforce.
- Jeff pattern adopted: E-JEFF-POLISH and methodology docs favor convergence/fresh-eyes review before implementation.
- Donella trace: stock is duplicate primitives; inflow is plan expansion; outflow is isomorphic lens decision; leverage is #4 self-organization.

L110 row example:

```json
{"ts":"2026-05-05T00:00:00Z","artifact_id":"wire-or-explain-l3-l5-quality-2026-05-05:isomorphic-lens","artifact_class":"quality_bar_evidence","stock":"1","consumer":"phase3-convergence+plan-close-5th-gate","owner":"plan-author","deferral_until":null,"deferred_reason":null,"verification_probe":"rg -n 'isomorphism|simplify-and-refactor-code-isomorphically|one primitive' .flywheel/plans/*/03-AUDIT-*.md","tick_consequence":"warn","drain_receipt":{"composite":"9.6","jeff":"9.6","donella":"9.6","joshua":"9.7"},"dedup_key":"wire-or-explain-l3-l5-quality-2026-05-05:isomorphic-lens:sha256-prefix"}
```

## WOE-EXP-B41 - Dispatch-Log Retroactive Audit Replay

Priority: P2
Item: E6
Parents: `flywheel-2ypj`, `flywheel-35zx`
Depends on: WOE-EXP-B31, WOE-EXP-B32, WOE-EXP-B33, WOE-EXP-B34, WOE-EXP-B35, WOE-EXP-B36, WOE-EXP-B37, WOE-EXP-B38, WOE-EXP-B39, WOE-EXP-B40.
Dedup key: `wire-or-explain-l3-l5-quality-2026-05-05:dispatch-log-retro-replay:sha256-prefix`

Body: Replay historical dispatch-log rows through the new L111 callback schema to identify missing quality fields and create repair evidence without blocking current work. This bead is last because replay depends on the template, validator, close gate, audit lens, and polish measurement existing first. Output is a backlog, not direct dispatch.

Acceptance:
- Producer event: replay run writes `{"artifact_class":"quality_bar_evidence","dispatch_rows_scanned":100,"missing_l111_fields_count":0,"replay_mode":"audit","dedup_key":"<plan>:dispatch-replay:<sha>"}`.
- Consumer: callback-validator-replay report and tick-close gate read the backlog count.
- L112 command: `jq -r 'select(.event=="ntm_dispatch_sent") | [.task_id,.quality_bar_passed] | @tsv' .flywheel/dispatch-log.jsonl | head` runs and shows dispatch rows with quality fields when present.
- Self-pass: this beta output's callback is replayable because it includes all L111 fields and L113 evidence counts.
- Beta-alpha integration: `flywheel-2ypj` closes only after replay debt is routed; `flywheel-35zx` keeps replay audit in shadow until false-positive rate is known.
- Jeff pattern adopted: E-JEFF-CB exactly-once callback validation and E-JEFF-POLISH retroactive bead-quality review.
- Donella trace: stock is historical callbacks without quality fields; inflow is replay scan; outflow is backlog or no-gap receipt; leverage is #6 information flow.

L110 row example:

```json
{"ts":"2026-05-05T00:00:00Z","artifact_id":"wire-or-explain-l3-l5-quality-2026-05-05:.flywheel/dispatch-log.jsonl","artifact_class":"quality_bar_evidence","stock":"1","consumer":"callback-validator-replay+tick-close-gate","owner":"flywheel:1","deferral_until":null,"deferred_reason":null,"verification_probe":"jq -r 'select(.event==\"ntm_dispatch_sent\") | [.task_id,.quality_bar_passed] | @tsv' .flywheel/dispatch-log.jsonl | head","tick_consequence":"warn","drain_receipt":{"composite":"9.6","jeff":"9.6","donella":"9.6","joshua":"9.7"},"dedup_key":"wire-or-explain-l3-l5-quality-2026-05-05:.flywheel/dispatch-log.jsonl:sha256-prefix"}
```

## L113 DID / DIDN'T Ledger

| Type | Claim | Evidence |
|---|---|---|
| DID | Read the full dispatch packet. | Command: `wc -l /tmp/dispatch_dag_rebuild_beta_2026-05-05.md` expected substring `134`; file line `/tmp/dispatch_dag_rebuild_beta_2026-05-05.md:1` anchors task title. |
| DID | Read spec section 3 and section 4 beta-2 table. | E-SPEC-L3 and E-SPEC-BETA. |
| DID | Read Sections C and E inventory. | E-INTENT-C and E-INTENT-E. |
| DID | Read r3 audit amendments and absorbed FMC-EXP-F1. | E-R3 and E-SPEC-FMC. |
| DID | Read plan 5th gate and quality_bar_passed rule. | E-PLAN-122 and E-PLAN-392. |
| DID | Read dispatch-template quality callback fields. | E-DISPATCH-FIELDS. |
| DID | Ran 4 Jeff-corpus Socraticode searches. | Re-runnable MCP calls: `codebase_search(projectPath="/Users/josh/Developer/jeff-corpus", query="quality_bar|callback_validator|judges|polish_round", limit=10)`; expected paths E-JEFF-QB/E-JEFF-CB/E-JEFF-JUDGE/E-JEFF-POLISH. |
| DID | Drafted 11 symbolic bead specs, WOE-EXP-B31 through WOE-EXP-B41. | Command: `rg -c '^## WOE-EXP-B[0-9]+' /Users/josh/Developer/flywheel/.flywheel/plans/wire-or-explain-tick-gate-2026-05-04/06-DAG-REBUILD-WORKER-beta-output.md` expected `11`. |
| DID | Each bead includes 5+ acceptance bullets. | Command: `awk '/^## WOE-EXP-B/{if(id&&c<5){print id,c;bad=1} id=$2; c=0} /^- /{c++} END{if(id&&c<5){print id,c;bad=1} exit bad}' /Users/josh/Developer/flywheel/.flywheel/plans/wire-or-explain-tick-gate-2026-05-04/06-DAG-REBUILD-WORKER-beta-output.md` expected exit 0. |
| DID | Each bead includes an L112 verification command. | Command: `rg -c 'L112 command:' /Users/josh/Developer/flywheel/.flywheel/plans/wire-or-explain-tick-gate-2026-05-04/06-DAG-REBUILD-WORKER-beta-output.md` expected `11`. |
| DID | Every bead includes L110 row example and dedup_key. | Commands: `rg -c 'L110 row example:' <output>` expected `11`; `rg -c 'dedup_key' <output>` expected >= `12`. |
| DID | B36 absorbs FMC-EXP-F1 thresholds. | Command: `rg -n 'plan_state_quality_bar_pending_count|warn_threshold\":20|error_threshold\":50|FMC-EXP-F1' <output>` expected all three threshold anchors. |

DIDN'T claims: none.

L113 coverage: `12/12` claims have file:line evidence or re-runnable command evidence.
