# Brenner System Deep Dive - 2026-05-07

## Section 1 - Headline numbers

- `socraticode_queries=16` against `/Users/josh/Developer/brenner_bot` after `serial-index.sh`; final Socraticode status was green with `9630` indexed chunks, watcher active, and code graph built.
- `files_read=25` direct source/spec/skill files, plus sampled `complete_brenner_transcript.md` because it is 484 KB.
- Top-level Brenner concepts identified: cheap decisive questions, hypothesis kill loop, third alternative, evidence per week, prediction locking, hypothesis arena, deterministic delta merge, evidence packs, tribunal roles, robot convergence, and session replay.
- Disposition counts in the comparison matrix: `adopt=3`, `extend=6`, `avoid=2`, `already_covered=2`.
- `wire_in_proposals=6`.

## Section 2 - Brenner methodology

### Core loop

The original metaprompt asks for the "inner threads" of how Brenner forms hypotheses on scant data, chooses high-yield experiments, avoids dependence on expensive machinery, and implicitly uses Bayesian reasoning in experiment choice (`initial_metaprompt.md:1-5`). The strongest unified distillation is: Brenner turns inquiry into cheap decisive questions by reframing until rival hypotheses separate, choosing high-contrast systems, and running experiments as decision procedures that delete hypothesis space (`final_distillation_of_brenner_method_by_gpt_52_extra_high_reasoning.md:21-23`).

The operational loop:

1. Find the bite point, usually a paradox (`final_distillation_of_brenner_method_by_gpt_52_extra_high_reasoning.md:47-53`).
2. Keep a small slate of 2-5 hypotheses and force a third alternative (`final_distillation_of_brenner_method_by_gpt_52_extra_high_reasoning.md:55-64`).
3. Change representation until hypotheses disagree on observables (`final_distillation_of_brenner_method_by_gpt_52_extra_high_reasoning.md:65-83`).
4. Choose or build the experimental object that makes the decisive test cheap (`final_distillation_of_brenner_method_by_gpt_52_extra_high_reasoning.md:85-90`).
5. Engineer a digital, high-contrast readout (`final_distillation_of_brenner_method_by_gpt_52_extra_high_reasoning.md:91-98`).
6. Add potency controls so a failed test distinguishes "hypothesis wrong" from "assay failed" (`final_distillation_of_brenner_method_by_gpt_52_extra_high_reasoning.md:99-108`).
7. Run the fastest decisive experiment, then update brutally (`final_distillation_of_brenner_method_by_gpt_52_extra_high_reasoning.md:109-114`).
8. Quarantine anomalies without letting them collapse a high-compression theory prematurely (`final_distillation_of_brenner_method_by_gpt_52_extra_high_reasoning.md:115-120`).

### Three-judge convergence pattern

The three distillations are not interchangeable summaries; they triangulate different invariants:

- GPT frames the method as an optimization problem: maximize discriminative leverage, speed, low ambiguity, and option value, not fact accumulation (`final_distillation_of_brenner_method_by_gpt_52_extra_high_reasoning.md:27-43`).
- Opus frames the method as reverse-engineering: reality has a generative grammar and understanding means reconstruction from primitives (`final_distillation_of_brenner_method_by_opus45.md:17-52`).
- Gemini frames the method as an instruction set: seek integers/digital handles, split state from logic, reduce dimension, materialize, and debug errors explicitly (`final_distillation_of_brenner_method_by_gemini3.md:13-87`).

The useful flywheel pattern is not "average the judges." It is "extract invariant operators, preserve dissenting lenses, then compile them into a role/prompt kernel." BrennerBot does this explicitly through `specs/role_prompts_v0.1.md`, which defines a triangulated Brenner kernel as the single prompt source of truth (`apps/web/src/lib/session-kickoff.ts:256-266`).

### Hypothesis lifecycle

The human methodology is kill-first: a hypothesis is an object to test and eliminate, not a thing to defend. The code mirrors this in `hypothesis-lifecycle.ts`: transitions include activate, refute, confirm, supersede, defer, and reactivate; terminal states include refuted and superseded, while confirmed can still be invalidated by new evidence (`apps/web/src/lib/schemas/hypothesis-lifecycle.ts:22-100`). Every transition is logged with state before/after, trigger, test result, reason, timestamp, and session ID (`apps/web/src/lib/schemas/hypothesis-lifecycle.ts:106-143`).

### Evidence-pack pattern

Brenner evidence packs are session-scoped, excerpt-first, anchored, local-first records co-located with artifacts under `artifacts/<thread_id>/evidence.json` and `evidence.md` (`specs/evidence_pack_v0.1.md:10-35`). Records have stable `EV-NNN` IDs, excerpts have `EV-NNN#E{n}` anchors, and the artifact schema requires those evidence refs to resolve or be marked as inference (`specs/artifact_schema_v0.1.md:57-76`). CLI support initializes packs, auto-assigns IDs, tracks supports/refutes/informs relations, and adds excerpt anchors (`brenner.ts:3139-3271`).

This is richer than flywheel's current compliance-pack direction: it is not just proof that work was done; it is a relational evidence substrate that says which claim each evidence record supports, refutes, or informs.

### Multi-agent orchestration

The worked nanochat example shows the human pattern: a kickoff defines a discriminative question, working hypotheses, ranked tests, anchors, and roles (`ANALYSIS_OF_USING_BRENNERBOT_FOR_BIO_INSPIRED_NANOCHAT.md:29-85`). Agents then add structured deltas: adversarial critique and H4 (`ANALYSIS_OF_USING_BRENNERBOT_FOR_BIO_INSPIRED_NANOCHAT.md:91-150`), then H5 and a recovery test with potency controls (`ANALYSIS_OF_USING_BRENNERBOT_FOR_BIO_INSPIRED_NANOCHAT.md:170-227`). The output is explicitly described as multi-agent scientific behavior: building on each other, cross-validating anomalies, distinct perspectives, and role flexibility (`ANALYSIS_OF_USING_BRENNERBOT_FOR_BIO_INSPIRED_NANOCHAT.md:237-247`).

The skill-level tribunal model has four roles: Devil's Advocate, Experiment Designer, Brenner Channeler, and Synthesis. Its flow is kickoff, initial response, cross-examination, integration, then iteration until convergence or timeout (`/Users/josh/.claude/skills/brenner/references/TRIBUNAL.md:5-102`).

### Compaction and distillation

Brenner compaction is structured compilation, not prose summarization. The artifact schema requires seven ordered sections with stable IDs: research thread, hypothesis slate, predictions table, discriminative tests, assumption ledger, anomaly register, and adversarial critique (`specs/artifact_schema_v0.1.md:19-31`). Agent outputs are deltas with `ADD`, `EDIT`, and `KILL` operations over those sections (`apps/web/src/lib/delta-parser.ts:26-48`). The merger is deterministic, timestamp-ordered, contributor-tracked, and returns applied/skipped counts and warnings (`apps/web/src/lib/artifact-merge.ts:918-1009`).

## Section 3 - brenner_bot architecture

### Repo shape and operating contract

BrennerBot is a Bun-only TS project. `AGENTS.md` makes deletion an absolute no-go, mandates Bun, and describes the project as a documents-first research lab that coordinates Codex/Claude/Gemini via Agent Mail and produces durable artifacts (`AGENTS.md:3-90`). The CLI entrypoint is `brenner.ts`, with imports from web library modules for Agent Mail, excerpt building, corpus search, operators, kickoff, delta parsing, artifact merge, thread status, hypothesis storage, scoring, and replay (`brenner.ts:1-157`).

Version arc: v0.4.0 adds robot mode, HITL step mode, robot-stress, per-agent health, session record/replay, robot session viewer, and confirms score/feedback/leaderboard are implemented (`CHANGELOG.md:11-39`). The same release reports TypeScript clean and 4,505 tests passing (`CHANGELOG.md:59-64`).

### CLI surface

`brenner.ts` exposes a broad surface: doctor, memory, excerpt, corpus search, experiment run/record/encode/post, evidence init/add/add-excerpt/list/render/post/verify, anomaly, critique, assumption, program, hypothesis lifecycle, test execution/binding, mail verbs, toolchain, prompt compose, cockpit, session start/status/compile/write/publish/nudge/diagnose/robot/robot-stress/record/replay (`brenner.ts:1348-1510`). It also exposes score, feedback, and leaderboard commands with JSON outputs (`brenner.ts:7336-7610`).

### Corpus retrieval

The global search index covers transcript sections, quote-bank entries, final distillations, raw model responses, and metaprompts, with caching, relevance scoring, highlighting, category filtering, and per-section URLs (`apps/web/src/lib/globalSearch.ts:1-20`). It parses transcript sections, quote chunks, distillation chunks, and generic document sections into searchable chunks (`apps/web/src/lib/globalSearch.ts:65-128`).

### Agent roles and kickoff

Role prompt composition extracts a triangulated kernel and role-specific prompts from `specs/role_prompts_v0.1.md` when available (`apps/web/src/lib/session-kickoff.ts:250-292`). Fallback role prompts enforce the core mechanics:

- Hypothesis generator: third alternative, level separation, citations, structured deltas (`apps/web/src/lib/session-kickoff.ts:307-330`).
- Test designer: tests designed to kill models, potency checks, evidence-per-week scoring (`apps/web/src/lib/session-kickoff.ts:333-358`).
- Adversarial critic: scale checks, anomaly quarantine, theory kill, third alternatives (`apps/web/src/lib/session-kickoff.ts:361-385`).

### Thread status and message protocol

The web session status model has explicit phases from `not_started` through `awaiting_responses`, `partially_complete`, `awaiting_compilation`, `compiled`, `in_critique`, and `closed` (`apps/web/src/lib/threadStatus.ts:72-80`). It also recognizes typed subjects: `KICKOFF`, `DELTA[...]`, `TRIBUNAL[...]`, `COMPILED`, `CRITIQUE`, `ACK`, `CLAIM`, `HANDOFF`, `BLOCKED`, `QUESTION`, and `INFO` (`apps/web/src/lib/threadStatus.ts:151-165`). This is stronger than flywheel's current ad-hoc message classes in older worker callbacks.

### Artifact and delta system

Artifacts are auditable, mergeable, and discrete: every claim has evidence or inference labeling, agents contribute deltas, and output is enumerated instead of narrative (`specs/artifact_schema_v0.1.md:9-16`). Delta payloads support hypothesis, prediction, discriminative test with potency check, assumption, anomaly, critique, kill, and research-thread edits (`apps/web/src/lib/delta-parser.ts:50-130`). The parser rejects invalid operations/sections and validates target/payload requirements (`apps/web/src/lib/delta-parser.ts:180-260`). Merge errors include invalid target, killed target, section limit, missing field, invalid section, no third alternative, below minimum, and runtime errors (`apps/web/src/lib/artifact-merge.ts:228-260`).

### Evidence packs and experiment capture

Evidence packs initialize empty state, auto-assign `EV-NNN` IDs, infer access method, capture relevance, and preserve supports/refutes/informs links (`brenner.ts:3139-3233`). Excerpts are appended as stable `E{n}` anchors under the evidence record (`brenner.ts:3235-3271`). Experiment capture records run/record mode, thread/test IDs, timing, stdout/stderr, exit code, cwd, argv, optional git state, and Bun runtime (`brenner.ts:480-514`; `specs/experiment_capture_protocol_v0.1.md:1-100`).

### Robot mode and convergence

Robot mode is a non-Agent-Mail subprocess runner for Claude Code, Codex CLI, and Gemini CLI. Each round builds prompts, invokes agents, parses deltas, merges, lints, and stops when kill-rate exceeds add-rate or max rounds is reached (`brenner.ts:1487-1501`). The convergence function never converges on round 1, then converges if kills are positive and `kills >= adds`, if no deltas appear, or if max rounds is hit (`brenner.ts:7975-8026`). Round summaries persist adds/kills/edits/errors/converged/reason/agent health and final session reports (`brenner.ts:8199-8298`).

### Replay

`session record` converts a robot session directory into `SessionRecord` JSON by reading `robot_session.json`, `session_state.json`, agent output files, roster roles, trace messages, content hashes, and artifact counts (`brenner.ts:8457-8605`). `session replay --mode trace` displays round-by-round messages with content hashes and output counts (`brenner.ts:8608-8715`).

`methodology_vs_code_drift`: the replay spec defines verification and comparison replay modes (`specs/session_replay_spec_v0.1.md:91-190`), and the CLI accepts `--mode trace|verification|comparison`, but only trace mode is implemented; verification and comparison throw an explicit not-yet-implemented error (`brenner.ts:8611-8719`).

### Prediction locks and arena

The prediction lock system cryptographically seals predictions before evidence to prevent post-hoc rationalization (`apps/web/src/lib/brenner-loop/prediction-lock.ts:1-30`). Locked predictions preserve original text, hash, timestamp, reveal state, observed outcome, and amendments (`apps/web/src/lib/brenner-loop/prediction-lock.ts:37-80`). The local skill reference also describes the arena: hypotheses compete on boldness, discriminative power, survival, and parsimony, with commands to enter, run rounds, view leaderboard, and eliminate with evidence (`/Users/josh/.claude/skills/brenner/references/ADVANCED.md:36-61`).

## Section 4 - /brenner skill gap analysis

The local `/brenner` skill wraps the basic research workflow: `doctor`, `corpus search`, `excerpt build`, `session start`, `session status`, `mail agents`, `session compile`, `artifact lint`, and `artifact nudge` (`/Users/josh/.claude/skills/brenner/SKILL.md:18-50`). It captures the key constraints: no vendor API calls, thread ID as join key, adjective+noun agents, excerpts before sessions, and third alternative required (`/Users/josh/.claude/skills/brenner/SKILL.md:74-81`).

Gaps relative to upstream CLI:

- The skill does not surface experiment capture (`experiment run/record/encode/post`) even though the CLI supports it (`brenner.ts:1362-1367`).
- The skill does not surface evidence pack commands beyond a reference pointer, while upstream supports init/add/add-excerpt/list/render/post/verify (`brenner.ts:1369-1378`).
- The skill does not surface anomaly, critique, assumption, program, hypothesis, or test storage/lifecycle commands (`brenner.ts:1380-1454`).
- The skill does not surface `session diagnose`, `robot`, `robot-stress`, `session record`, or `session replay` (`brenner.ts:1484-1504`).
- The skill does not surface `score`, `feedback`, or `leaderboard`, despite upstream implementation (`brenner.ts:7336-7610`).

Recommendation: keep `/brenner` as the lightweight "exact prompt" skill, but add an "advanced surfaces" section that names the upstream primitives above. Do not turn it into a kitchen-sink skill; point to workflows by intent.

## Section 5 - Comparison matrix

| Flywheel primitive | Brenner counterpart | Disposition | Rationale |
|---|---|---|---|
| `/flywheel:plan` 5-phase | Brenner loop: bite point -> slate -> representation -> decisive test -> anomaly handling | EXTEND | Flywheel plans have phases, but not always explicit hypothesis slates, third alternatives, potency controls, or kill criteria. Add those to plan refinement, not every worker packet. |
| `dueling-idea-wizards` | Tribunal roles and 3-agent role prompts | EXTEND | Brenner agents output mergeable deltas with role obligations, not just arguments. Dueling wizards should produce `ADD/EDIT/KILL`-like structured deltas. |
| `jeff-convergence-audit` Phase 1 broad sweep | Multi-model final distillation and triangulated kernel | ALREADY-COVERED + EXTEND | Flywheel already uses broad sweep and convergence, but Brenner preserves epistemic status: syntheses are hypotheses and claims should anchor to transcript/evidence. |
| `research-triad` 3-lane parallel | Hypothesis generator, test designer, adversarial critic | EXTEND | The roles align, but Brenner makes each role operational: hypotheses, discriminative tests, critiques, potency checks, and citations. |
| Evidence-pack contract post-x6ok8 | Brenner evidence pack | ADOPT | Flywheel should adopt stable evidence IDs, excerpt anchors, supports/refutes/informs relations, and co-location beside artifacts. |
| `multi-model-triangulation` skill | Triangulated Brenner kernel across Opus/GPT/Gemini | ALREADY-COVERED + EXTEND | Covered in spirit. Extend with explicit invariant extraction and dissent preservation before compiling a kernel. |
| Beads + plan-space convergence | Hypothesis lifecycle and transition log | ADOPT | Brenner has a cleaner state machine for idea objects than flywheel's ad-hoc acceptance criteria. Use for design hypotheses, not for replacing beads. |
| Flywheel polish/close gate | Robot convergence: kills >= adds, no deltas, max rounds | EXTEND | Flywheel convergence can add a "finding kill-rate" heuristic for polish rounds. |
| Flywheel callback/evidence discipline | Session record/replay with content hashes | ADOPT | Trace replay is a strong receipt primitive for multi-agent plan rounds and would make close-gate audits cheaper. |
| Flywheel orchestrator runtime | Brenner robot mode subprocess orchestration | AVOID | Do not replace NTM/Agent Mail with subprocess robot mode. Adopt convergence/replay ideas, not the transport. |
| Flywheel generic execution tasks | Brenner seven-section scientific artifact | AVOID | The seven-section schema is excellent for research, but too scientific for every execution bead. Use it for research/refinement plans only. |

## Section 6 - Wire-in proposals

1. **P0 - `[brenner-wire] add hypothesis slate and kill criteria to /flywheel:plan Phase 2`**  
   Scope: update plan template/refinement prompts, not worker code.  
   Gap: plans often converge by consensus instead of explicit hypothesis elimination.  
   Acceptance: every new research/refactor plan has 2-5 candidate strategies, one third alternative, and a kill condition per strategy.

2. **P0 - `[brenner-wire] extend evidence-pack contract with EV anchors`**  
   Scope: add `evidence.json`/`evidence.md` schema for flywheel plan artifacts.  
   Gap: compliance packs prove work happened but do not express supports/refutes/informs relationships.  
   Acceptance: close-gate can resolve every cited `EV-NNN` and every excerpt anchor in plan artifacts.

3. **P1 - `[brenner-wire] add prediction-lock receipt to high-risk plan hypotheses`**  
   Scope: plan-space pre-registration only; no runtime mutation.  
   Gap: flywheel can rationalize after results.  
   Acceptance: before execution, key predictions are timestamped and hashed; close gate flags post-hoc amendments.

4. **P1 - `[brenner-wire] structured deltas for dueling-idea-wizards`**  
   Scope: prompt/template change.  
   Gap: idea duels produce prose instead of mergeable decision objects.  
   Acceptance: wizard outputs include `ADD`, `EDIT`, and `KILL` operations over plan hypotheses, risks, and tests.

5. **P1 - `[brenner-wire] add convergence telemetry to polish rounds`**  
   Scope: quality-bar-close-gate and polish artifact template.  
   Gap: current close-gate detects unresolved findings but not whether the finding set is narrowing.  
   Acceptance: gate reports adds/kills/edits/no-deltas across polish rounds and requires two stable rounds for complex plans.

6. **P2 - `[brenner-wire] expose advanced /brenner skill surfaces`**  
   Scope: local skill doc update only.  
   Gap: `/brenner` hides experiment/evidence/replay/score commands now available upstream.  
   Acceptance: skill names advanced commands by intent with one canonical example each, without bloating the exact prompt workflow.

## Section 7 - Cross-cutting Jeff-philosophy candidates

- **Exclusion over confirmation as doctrine:** require every research plan to say what would kill its leading strategy.
- **Third alternative as anti-false-binary guard:** make "both could be wrong" a required section for high-risk architecture plans.
- **Evidence per week:** score tests by expected mind-change, speed, ambiguity, and cost, not by how impressive they look.
- **Prediction locking:** pre-register key expectations before execution so close-gate audits can detect narrative drift.
- **Anomaly quarantine:** do not let anomalies vanish into summaries; classify as active/resolved/deferred with owner and next action.
- **Trace replay:** preserve enough message/output hashes that a future audit can reconstruct what agents actually saw and emitted.

## Section 8 - Top 3 surprises

1. **Brenner is more kill-first than flywheel.** Flywheel tends to close over completion/evidence; Brenner actively rewards elimination. The hypothesis kill-rate score and robot convergence (`kills >= adds`) are the clearest adoption targets.

2. **The evidence pack is relational, not just archival.** `supports`, `refutes`, and `informs` turn evidence into a graph over claims/tests. Flywheel's post-x6ok8 compliance packs should not stop at "proof of work."

3. **Replay is both strong and unfinished.** The record/trace path is practical today, but verification/comparison replay is specified and not implemented. Flywheel should adopt trace receipts now and avoid depending on deterministic LLM replay until the implementation exists.
