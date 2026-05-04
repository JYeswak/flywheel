# Meadows Component Analysis - Validate Everything We Build

Plan: `validate-everything-we-build-2026-05-03`
Scope: other validate-everything components beyond codex-feedback capture
Status: `ladder_passed=yes`
Generated: 2026-05-03

This is a complement to `01-RESEARCH-MEADOWS.md`, which already covers the
codex-feedback capture gap and recommends a combined `#3 + #5 + #6` stack.
This file does not redo that analysis. It applies the same Meadows lens to the
remaining plan components plus the L70 chain-detection mechanism.

## Research Ledger

- Required Meadows skill read: `~/.claude/skills/donella-meadows-systems-thinking/SKILL.md`.
- Meadows references read: `references/LEVERAGE-POINTS.md`, `references/STOCKS-AND-FLOWS.md`, `references/FEEDBACK-LOOPS.md`, `references/ANTI-PATTERNS.md`, `data/sources.json`.
- Skill validation run: `/Users/josh/.claude/skills/donella-meadows-systems-thinking/scripts/validate-donella-systems-thinking.sh` -> `donella-meadows-systems-thinking validation ok`.
- Skills library check: attempted `flywheel skills-best-practices "leverage analysis system intervention root cause structural" --top=10`; local CLI returned `ERR: unknown command: skills-best-practices`. Fallback used `mcp__skill_search__query_skills_tool` with the same query.
- Skill-search matches: `nps-analysis`, `contract-review`, `socraticode`, `mission-anchor-init`, `client-ecosystem-audit`, `legal-research`, `research-triad`, `statistical-analysis`, `prompt-engineering-science`, `tech-debt-management`.
- Skills interpretation: no direct substitute for `donella-meadows-systems-thinking` surfaced; relevant companions are `socraticode`, `mission-anchor-init`, `research-triad`, and `tech-debt-management`. `skills_library_gap=none_for_meadows_skill_present; partial_for_validate_everything_component_specific_patterns`.
- Local artifacts verified on disk: `00-INTENT.md`, `01-RESEARCH-A.md`, `01-RESEARCH-MEADOWS.md`, `04-BEADS-PREDRAFT.md`.

## Meadows Source IDs Used

- `leverage-points-html`: Donella Meadows, "Leverage Points: Places to Intervene in a System", retrieved `2026-05-02T01:30:41Z`, page=TODO.
- `leverage-points-pdf`: Donella Meadows, "Leverage Points: Places to Intervene in a System" PDF, retrieved `2026-05-02T01:30:41Z`, page=TODO.
- `little-more-feedback`: Donella Meadows, "Let's Have a Little More Feedback", retrieved `2026-05-02T01:30:41Z`, page=TODO.
- `system-dynamics-press`: Donella Meadows, "System Dynamics Meets The Press", retrieved `2026-05-02T01:30:41Z`, page=TODO.
- `dancing-with-systems-archive`: Donella Meadows, "Dancing With Systems", retrieved `2026-05-02T01:30:41Z`, page=TODO.

## Component 1 - Mechanical Gate: Dispatch-Template Injection for Validate-Callback

SYSTEM: Dispatch authoring, worker callback receipts, orchestrator callback validation, and the reaper path named by `flywheel-1z65`, B02, and B03.

STOCK: Unvalidated `DONE` claims and under-specified dispatch packets accumulate. The stock rises when a dispatch omits acceptance probes, or when a callback is accepted without artifact checks. The stock drains only when a validation receipt exists and is consumed before forwarding.

PATTERN: Lane A names `orchestrator-skipped-callback-validation` as high criticality. The recurrence is not "agents forgot to be careful"; it is that the callback contract allows prose completion to compete with mechanical evidence.

LOOP: The missing balancing loop is callback claim -> acceptance probes -> pass/fail receipt -> orchestrator decision. Today the loop often stops at callback claim, so false positives flow directly into closeout.

LEVERAGE_POINT: `#5 - Rules of the system` is primary. A dispatch-template validation block changes what counts as a valid dispatch and callback. `#6 - Information flows` alone would be more callback text; it would not change the rule that lets an unvalidated callback proceed.

INTERVENTION: Add a reversible dispatch-template block requiring `expected_artifacts`, `probe_commands`, `acceptance_gates`, `failure_action`, and callback fields. Start as warn/audit on old packets, then fail newly authored packets missing the block.

MEASURE: `dispatches_missing_validation_block_count`, `callbacks_without_validation_receipt_count`, `callbacks_forwarded_without_probe_count`, and time from callback receipt to validation result.

SOURCE: Meadows source_id=`leverage-points-html` and `leverage-points-pdf` for leverage #5, page=TODO; source_id=`little-more-feedback` for the missing feedback loop, page=TODO. Local: `00-INTENT.md` components 1 and 6; `01-RESEARCH-A.md` high gap `orchestrator-skipped-callback-validation`; `04-BEADS-PREDRAFT.md` B02/B03; bead reference `flywheel-1z65`.

## Component 2 - Doctor Signal Taxonomy

SYSTEM: `flywheel-loop doctor`, strict-mode status, tick prelude consumption, and the plan's validation doctor signals: `callbacks_unvalidated_count`, `callbacks_validated_with_failures_count`, `ticks_punted_count`, `surfaces_unwired_count`, and `closed_bead_artifact_missing_count`.

STOCK: Hidden validation debt accumulates across callbacks, tick phases, beads, and doctrine surfaces. The stock is currently present even when doctor output can still appear operationally green.

PATTERN: Lane A shows multiple high-criticality gaps whose evidence existed but was not surfaced into a blocking doctor signal: skipped callback validation, idle with actionable work, closed artifacts missing, and substrate watchtower gaps.

LOOP: The delayed feedback loop is evidence -> doctor signal -> consumer behavior -> reduced recurrence. Existing evidence often reaches memory, incidents, or pane scrollback, but not a strict doctor consumer.

LEVERAGE_POINT: `#3 - Goals` is primary, with `#8 - Strength of negative feedback loops` as the mechanism. The doctor goal must shift from "report system health" to "prevent unvalidated integration." Once that goal is explicit, thresholds strengthen the balancing loop.

INTERVENTION: Define producer, measurement, consumer, threshold, and promotion path for each signal. Keep initial rollout warn-only until B12 proves the consumer, then make strict mode fail where integration would otherwise continue on false state.

MEASURE: Count of signal producers with no consumer, strict-mode failures by signal, recurrence rate of the trauma classes after signal promotion, and median age of unresolved signal instances.

SOURCE: Meadows source_id=`leverage-points-html` for #3 and #8, page=TODO; source_id=`little-more-feedback` for feedback-loop design, page=TODO. Local: `00-INTENT.md` component 2; `01-RESEARCH-A.md` Section 3 high gaps; `04-BEADS-PREDRAFT.md` B04; AGENTS L60 doctor-signal pattern.

## Component 3 - New VALIDATE Tick Phase

SYSTEM: The flywheel tick state machine between worker callback receipt and downstream integration, including `DISPATCH`, proposed `VALIDATE`, `INTEGRATE`, `LEARN`, and closeout.

STOCK: Callback claims waiting for validation are currently an implicit stock. Without an explicit phase, they either pile up invisibly or bypass validation and become accepted work.

PATTERN: The repeated failure is meat-puppet orchestration on partial state: a callback arrives, the tick moves forward, and the actual artifact or gate evidence is checked late or not at all.

LOOP: The missing loop is callback -> validation phase -> pass/fail routing -> integration or fix work. The delay is structural because validation is not a named phase with ownership.

LEVERAGE_POINT: `#3 - Goals` is primary, with `#5 - Rules` secondary. A tick with a `VALIDATE` phase says the goal is not throughput or dispatch volume; the goal is validated work entering the system. The phase rule is how that goal becomes operational.

INTERVENTION: Insert a `VALIDATE` phase that owns pending callback receipts. The phase may be dry-run first, emitting would-block decisions without halting integration until the e2e smoke harness passes.

MEASURE: `pending_validation_count`, `integrations_blocked_by_validation_count`, validation queue age, and percentage of callback receipts that pass through `VALIDATE` before `INTEGRATE`.

SOURCE: Meadows source_id=`leverage-points-html` for #3/#5, page=TODO; source_id=`system-dynamics-press` for stock/flow framing, page=TODO. Local: `00-INTENT.md` component 3; `01-RESEARCH-A.md` gaps `meat-puppet-orchestrator-decision-on-partial-state` and `orchestrator-skipped-callback-validation`; `04-BEADS-PREDRAFT.md` B05.

## Component 4 - Auto-Open Fix-Bead Protocol

SYSTEM: Validation failure routing into Beads, including new-finding handling, existing-bead update, `no_bead_reason`, and callback validation failure receipts.

STOCK: Known failed gates with no work item. This stock grows when validation finds a missing artifact or failed acceptance gate but nothing durable enters the work queue.

PATTERN: Lane A names `documented-bug-not-actioned-self-recursion` and `silent-finding-loss`: the system can know the defect and still fail to create actionable work.

LOOP: The missing feedback loop is validation failure -> repair bead -> future dispatch -> validation pass. Without the bead, failure evidence stays as a note, chat line, or doctor warning instead of becoming outflow from the defect stock.

LEVERAGE_POINT: `#5 - Rules of the system` is primary. The rule is that a failed validation gate must produce one of three durable outcomes: new fix bead, existing bead update, or explicit no-bead receipt. `#6` visibility without that rule would only count failures.

INTERVENTION: Add an idempotent auto-open protocol for validation failures. Start with `--dry-run` receipt generation; promote to actual bead creation once duplicate detection and parent/dependency assignment pass.

MEASURE: `validation_failures_without_bead_count`, duplicate auto-open candidate count, fix-bead creation latency, and percent of failed validations with a durable Beads outcome.

SOURCE: Meadows source_id=`leverage-points-html` for #5, page=TODO; source_id=`little-more-feedback` for failure-to-repair loop, page=TODO. Local: `00-INTENT.md` component 4; `01-RESEARCH-A.md` high gaps `documented-bug-not-actioned-self-recursion` and `orchestrator-skipped-callback-validation`; `04-BEADS-PREDRAFT.md` B06; AGENTS L52/L53/L56.

## Component 5 - Auto-Reopen Falsely Closed Beads

SYSTEM: Closed bead state, claimed close reasons, canonical artifact paths, validation receipts, and the reopen path for artifact-missing or gate-failed closed work.

STOCK: False closure debt. This stock accumulates when a bead is closed as shipped but the artifact is absent, incomplete, or unvalidated. The stock is dangerous because future selection logic treats it as drained.

PATTERN: The plan cites closed josh-request artifacts missing at canonical paths and Lane A identifies `closed-bead-artifact-missing` under the callback-validation trauma cluster.

LOOP: The delayed balancing loop is audit proof -> reopen candidate -> reopened bead or correction receipt -> future dispatch. If the loop is delayed until a human notices, the false closure stock compounds silently.

LEVERAGE_POINT: `#5 - Rules of the system` is primary, supported by `#8 - Strength of negative feedback loops`. The rule change is that closed is not final when mechanical evidence contradicts the close reason. The strengthened feedback loop makes closure state responsive to artifact reality.

INTERVENTION: Build a candidate-first scanner that records reopen recommendations with evidence. Promote to automatic reopen only for deterministic missing-artifact claims and keep ambiguous cases as validation failures requiring fix beads.

MEASURE: `closed_bead_artifact_missing_count`, reopen candidate age, false-positive reopen rate, and percent of reopened beads that later close with passing validation.

SOURCE: Meadows source_id=`leverage-points-html` for #5/#8, page=TODO; source_id=`little-more-feedback` for delayed feedback, page=TODO. Local: `00-INTENT.md` component 5; `01-RESEARCH-A.md` `orchestrator-skipped-callback-validation`; `04-BEADS-PREDRAFT.md` B07; bead reference `flywheel-1z65`.

## Component 6 - /flywheel:learn Integration

SYSTEM: Validation events, fuckup-log rows, INCIDENTS promotion, memory notes, L-rule promotion, skill publication, and `/flywheel:learn` as the routing surface.

STOCK: Unrouted learning events and repeated trauma classes. The stock rises when validation failures are fixed locally but do not update the learning substrate, or when positive doctrine accretions are misrouted into fuckup-log.

PATTERN: Lane A shows recurring trauma classes with memory and incident evidence. L56 already exists because prior accretion routed signals inconsistently between fuckup-log, INCIDENTS, and L-rules.

LOOP: The missing loop is event -> classification -> durable substrate -> future dispatch/doctor/skill behavior. Without `/flywheel:learn` integration, validation becomes a one-tick correction rather than system adaptation.

LEVERAGE_POINT: `#4 - Self-organization` is primary. This component changes the system's capacity to create new structure from repeated events: rules, incidents, beads, skills, and memory consumers. It is higher leverage than simply adding another information flow.

INTERVENTION: Route validation receipts into `/flywheel:learn` with dedupe keys and explicit classification: fuckup, incident candidate, doctrine candidate, skill gap, or no-learn reason.

MEASURE: `validation_events_unrouted_count`, duplicate learn event count, promotion latency from repeated validation failure to incident/L-rule/skill, and recurrence rate after promotion.

SOURCE: Meadows source_id=`leverage-points-html` for #4, page=TODO; source_id=`dancing-with-systems-archive` for adaptive learning, page=TODO. Local: `00-INTENT.md` component 7; `01-RESEARCH-A.md` high gaps `documented-bug-not-actioned-self-recursion` and `skill-substrate-validation-drift`; `04-BEADS-PREDRAFT.md` B09; AGENTS L56.

## Component 7 - Memory Wire-In Mechanical Gate

SYSTEM: Memory notes under `~/.claude/projects/.../memory/`, AGENTS L-rules, INCIDENTS, skills, README/SKILL surfaces, dispatch templates, and doctor/tick consumers.

STOCK: Memory-only doctrine. This stock grows when a note exists but no runtime surface consumes it. It drains when the note is wired into a rule, signal, skill, dispatch block, or validator.

PATTERN: Lane A names `canonical_doctrine_drift_local`, `skill-substrate-validation-drift`, and `info-source-watchtower-missing`. The pattern is documented truth that does not reliably reach the actor making the next operational decision.

LOOP: The broken loop is observation -> memory -> consumer enforcement -> changed future behavior. If the memory note is the terminal artifact, feedback exists but does not reach the governing rule.

LEVERAGE_POINT: `#5 - Rules of the system` is primary. The rule should be: a memory note that claims operational doctrine is not landed until it names and verifies a consumer. This avoids confusing `#6` information existence with behavioral control.

INTERVENTION: Add a mechanical gate for new validation doctrine memory: require `consumer_surface`, `verification_probe`, and `promotion_path`. Gate can initially be a plan/decompose checklist item before becoming doctor strict mode.

MEASURE: `memory_notes_without_consumer_count`, `doctrine_drift_count`, percent of new memory notes with verified consumers, and time from memory note creation to AGENTS/skill/doctor/dispatch surface.

SOURCE: Meadows source_id=`leverage-points-html` for #5/#6 distinction, page=TODO; source_id=`little-more-feedback` for feedback reaching the right actor, page=TODO. Local: `00-INTENT.md` component 8; `01-RESEARCH-A.md` high gaps `canonical_doctrine_drift_local`, `skill-substrate-validation-drift`, and `info-source-watchtower-missing`; `04-BEADS-PREDRAFT.md` B10; memory `feedback_three_audit_questions_per_surface.md`.

## Component 8 - Codex Parity General

SYSTEM: Cross-runtime validation parity across Claude Code and Codex: tool visibility, callback validation, agent-context probes, NTM transport, Beads interaction, doctor signals, and parity epic `flywheel-2p25`. This excludes codex-feedback capture specifics already covered by `01-RESEARCH-MEADOWS.md`.

STOCK: Runtime asymmetry and unknown parity cells. The stock rises when a validation mechanism works in Claude but is unproven in Codex, or when raw shell probes are mistaken for Codex agent-context truth.

PATTERN: ORX1 produced contradictory path observations until L69 separated orchestrator shell truth from agent execution truth. Lane A also names `codex-pane-crashed-mid-dispatch` and `bypass-canonical-substrate-cluster`.

LOOP: The missing feedback loop is runtime capability claim -> in-agent parity probe -> matrix cell status -> dispatch eligibility. Without it, failure appears only after a Codex pane misses a tool, crashes, or fails to receive a validation primitive.

LEVERAGE_POINT: `#3 - Goals` is primary, with `#5 - Rules` and `#6 - Information flows` underneath. The goal must be "all active runtimes are first-class validated participants", not "Claude has the gate and Codex probably does too." The rule is that unknown parity is nonconformant for validation-critical paths.

INTERVENTION: Treat parity as a validation gate with agent-context probes per L69 and future `flywheel-q03g` output. Use the matrix to block dispatches that depend on unproven runtime capabilities.

MEASURE: `parity_unknown_cells_count`, `runtime_context_drift_count`, `codex_validation_probe_failures_count`, and time from new validation feature to both-runtime proof.

SOURCE: Meadows source_id=`leverage-points-html` for #3/#5/#6 stack, page=TODO; source_id=`little-more-feedback` for agent-context feedback loop, page=TODO. Local: `00-INTENT.md` component 9; `01-RESEARCH-A.md` high gaps `codex-pane-crashed-mid-dispatch` and `bypass-canonical-substrate-cluster`; `04-BEADS-PREDRAFT.md` B11; AGENTS L69; `01-RESEARCH-MEADOWS.md` codex-feedback companion.

## Component 9 - Chain-Detection Mechanism per L70

SYSTEM: Tick phase transition driver and same-tick chaining: DISPATCH -> BEADS -> DISPATCH, INTEGRATE -> LEARN, validation failure -> fix bead, and worker callback -> next actionable phase.

STOCK: Named next actions waiting for a later tick. The stock rises when the orchestrator identifies a next phase but does not execute it in the same tick despite available capacity.

PATTERN: Lane A names `orchestrator-idle-with-actionable-work`; `flywheel-7lby` records the no-punt trauma. The current dispatch exists because L70 was applied immediately instead of waiting for Phase 2 convergence.

LOOP: The delayed loop is next-phase signal -> action execution -> updated plan/beads/dispatch state. When the loop waits for launchd or human attention, the system pays avoidable idle latency.

LEVERAGE_POINT: `#5 - Rules of the system` is primary, with `#9 - Delays` secondary. L70 already changes the rule: a named next actionable phase must run in the same tick or carry a blocker. The delay intervention is important but lower leverage than the rule that forbids silent punt.

INTERVENTION: Add chain detection that records `next_phase`, `capacity_state`, `chained=yes|no`, and `chain_blocked_reason`. Start in observe mode, then fail `ticks_punted_count` when `next_phase` and capacity exist without chaining.

MEASURE: `ticks_punted_count`, `phase_chain_latency_seconds`, `chain_blocked_reason_count`, and percent of ticks with actionable next phase chained same tick.

SOURCE: Meadows source_id=`leverage-points-html` for #5/#9, page=TODO; source_id=`system-dynamics-press` for delay framing, page=TODO. Local: `04-BEADS-PREDRAFT.md` B08; `01-RESEARCH-A.md` high gap `orchestrator-idle-with-actionable-work`; AGENTS L70; bead `flywheel-7lby`.

## Cross-Component Synthesis

Shared `#3 - Goals` leverage:

- Doctor signal taxonomy: the doctor goal becomes prevention of unvalidated integration, not passive reporting.
- VALIDATE tick phase: the tick goal becomes validated work, not motion through phases.
- Codex parity general: the runtime goal becomes first-class parity across active runtimes, not best-effort Claude-first behavior.

Shared `#5 - Rules` leverage:

- Mechanical gate: dispatches and callbacks are invalid without validation contract fields.
- Auto-open fix beads: failed validation must become a durable work item, update, or no-bead receipt.
- Auto-reopen falsely closed beads: mechanical contradiction can reopen closure.
- Memory wire-in: doctrine is not landed until a consumer is verified.
- Chain detection: next actionable phase must chain same tick or produce a blocker.

Shared `#6 - Information flows` support:

- Doctor signals, parity matrix cells, memory consumer fields, and callback receipts are all necessary information flows.
- They are not sufficient alone. Each becomes useful only when attached to a higher-level goal or rule.

Unique structural interventions:

- `/flywheel:learn` integration is the only `#4 - Self-organization` component. It changes the system's ability to generate future rules, incidents, beads, and skills from validation events.
- Chain detection uniquely targets `#9 - Delays` as a secondary point by shortening phase handoff latency.
- Auto-reopen uniquely modifies the closed-state feedback loop, making bead closure reversible when evidence contradicts the state.
- Codex parity uniquely makes agent execution context part of the system boundary, per L69, instead of treating shell state as sufficient truth.

## Anti-Pattern Check

Parameter thrash risk: mechanical gate.

- Obvious `#6` fix: ask callbacks to include more prose evidence.
- Why it thrashes: the old rule still lets the orchestrator forward unvalidated callbacks. More fields do not change the acceptance condition.
- Required alignment first: `#5` dispatch/callback validity rule.

Parameter thrash risk: doctor signal taxonomy.

- Obvious `#6` fix: add dashboard counters for unvalidated callbacks and missing artifacts.
- Why it thrashes: counters without consumer thresholds produce more visibility but no correction.
- Required alignment first: `#3` doctor goal and strict-mode consumer behavior.

Parameter thrash risk: memory wire-in.

- Obvious `#6` fix: write another memory note or AGENTS paragraph.
- Why it thrashes: information exists but does not reach dispatch, doctor, tick, or skill consumers.
- Required alignment first: `#5` rule requiring verified consumer and promotion path.

Parameter thrash risk: codex parity general.

- Obvious `#6` fix: print a parity table from raw shell commands.
- Why it thrashes: ORX1 showed raw shell context can contradict Codex agent execution context.
- Required alignment first: `#3` runtime parity goal and `#5` rule that unknown/in-wrong-context parity is nonconformant.

Parameter thrash risk: chain detection.

- Obvious `#6` fix: log `next_phase` in tick receipts.
- Why it thrashes: visibility of the next phase does not force same-tick execution.
- Required alignment first: L70 `#5` rule that actionable next phases chain or carry a blocker.

## Phase 2 Input Summary

The validate-everything plan should not synthesize uniformly at `#6`.

- Highest leverage stack for most mechanical components is `#5 rules + #6 evidence`.
- The doctor and VALIDATE phase require `#3 goal` alignment before their signals can be meaningful.
- `/flywheel:learn` is the self-organization layer and should be treated as the adaptive substrate, not as a logging add-on.
- Codex parity must remain a goal-level constraint for the whole validation system, while `01-RESEARCH-MEADOWS.md` handles the codex-feedback capture subcase.
- L70 chain detection should be implemented as a rule and delay reducer, not merely a receipt field.
