# Phase 1 Lane B — Jeff Ecosystem Validation Pattern Audit

plan: validate-and-redispatch-foundational-2026-05-03
lane: B
status: complete
ladder_passed: yes
scope: read-only ecosystem audit; no source edits to Jeff repos or flywheel source

## Skill Library Check

Command requested: `/flywheel:skills-best-practices "validation feedback loops jeff substrate ecosystem patterns" --top=10 --include-content`

Local execution path used: skill search MCP plus direct skill reads. Matching skills:

- `flywheel-doctor-author` — strongest match. It requires every doctor invariant to define producer, measurement, consumer, and promotion, and warns against prose-only halt claims and positive probes of phantom substrates (`~/.claude/skills/flywheel-doctor-author/SKILL.md:13`, `~/.claude/skills/flywheel-doctor-author/SKILL.md:56`).
- `install-substrate` — matched substrate install validation/receipts.
- `codebase-audit` and `socraticode` — matched evidence-led repo archaeology.
- `skill-builder`, `request-validation`, `lean-formal-feedback-loop`, `testing-metamorphic`, `loop-enforcement` — useful support skills for validation/feedback-loop framing.
- `jeff-issue-chain` — governs Jeff engagement: file:line evidence, no prescriptive implementation, no local PRs/patches to Jeff repos (`~/.claude/skills/jeff-issue-chain/SKILL.md:27`, `~/.claude/skills/jeff-issue-chain/SKILL.md:36`, `~/.claude/skills/jeff-issue-chain/SKILL.md:127`).

skills_library_gap=none_for_lane_b_core. There is no dedicated `jeff-pattern-mining` skill surfaced by search, but AGENTS L62-L64 plus `jeff-issue-chain` cover the operational rule.

## Socraticode Ledger

All searches used K=10 and canonical local paths, with linked-project search enabled where available.

1. `/Users/josh/Developer/ntm`: `validation feedback loop callback verification`
2. `/Users/josh/Developer/beads_rust`: `doctor health probe substrate audit`
3. `/Users/josh/Developer/asupersync`: `test-driven implementation acceptance gate`
4. `/Users/josh/Developer/meta_skill`: `fuckup learn promote trauma class`

Additional `rg`/line-citation passes covered `destructive_command_guard`, `mcp_agent_mail`, `mcp_agent_mail_rust`, `coding_agent_session_search`, `cass_memory_system`, `frankensqlite`, and `vibe_cockpit`.

## 1. Pattern Catalog

### ntm

| Citation | Pattern | Solves | Class |
|---|---|---|---|
| `/Users/josh/Developer/ntm/internal/robot/robot.go:6181` | Closed-loop actuation verification | Separates "command sent" from observed pane readiness; emits ready, skipped, partial, timeout, and pending target state into the attention feed. | ADOPT |
| `/Users/josh/Developer/ntm/internal/cli/checkpoint.go:814` | Checkpoint integrity verifier | Validates schema, required files, and consistency for one/all checkpoints before trusting persisted state. | ADOPT |
| `/Users/josh/Developer/ntm/e2e/scenario_harness.go:4` | Operator-loop scenario harness | Provides deterministic session management, artifact directories, timeline logging, cursor tracking, and invariant assertions for loop behavior. | EXTEND |
| `/Users/josh/Developer/ntm/internal/handoff/validate.go:147` | Validate-and-default boundary | Ensures handoff objects get defaults, then validation, then structured pass logging. | ADOPT |

### beads_rust

| Citation | Pattern | Solves | Class |
|---|---|---|---|
| `/Users/josh/Developer/beads_rust/src/cli/commands/doctor.rs:99` | Doctor report with `ok/warn/error` counts | Gives humans and agents one summary plus per-check details in a consistent severity model. | ADOPT |
| `/Users/josh/Developer/beads_rust/src/cli/commands/doctor.rs:794` | Real-substrate doctor execution | Probes `.beads`, metadata, JSONL, SQLite schema, integrity, sync metadata, and exits nonzero on errors. | ADOPT |
| `/Users/josh/Developer/beads_rust/tests/conformance.rs:9575` | Cross-runtime conformance doctor | Runs both `br doctor --json` and legacy `bd doctor --json`, then requires both emit checks. | EXTEND |
| `/Users/josh/Developer/beads_rust/tests/common/binary_discovery.rs:73` | Binary identity discovery | Probes env override, cargo build output, release binary, and PATH instead of assuming the executable under test. | ADOPT |

### destructive_command_guard

| Citation | Pattern | Solves | Class |
|---|---|---|---|
| `/Users/josh/Developer/destructive_command_guard/src/cli.rs:172` | Safety doctor surface | Exposes `dcg doctor` with pretty/json output and optional fix mode for installation validation. | ADOPT |
| `/Users/josh/Developer/destructive_command_guard/src/cli.rs:378` | Policy simulation | Replays command logs against current policy for rollout analysis, false positives, and allowlist candidates. | EXTEND |
| `/Users/josh/Developer/destructive_command_guard/src/cli.rs:393` | Explainable decision trace | Shows keyword gating, pack evaluation, pattern match, and allowlist checks for a command. | ADOPT |
| `/Users/josh/Developer/destructive_command_guard/src/suggestions.rs:152` | Block-to-safer-next-step suggestion | Denial output points to `dcg explain` and safer alternatives rather than leaving a dead end. | ADOPT |

### mcp_agent_mail

| Citation | Pattern | Solves | Class |
|---|---|---|---|
| `/Users/josh/Developer/mcp_agent_mail/SKILL.md:355` | Mailbox doctor with dry-run repair | Documents diagnostic, repair preview, backup-before-repair, and checks for stale locks, DB integrity, orphaned records, FTS sync, and expired reservations. | ADOPT |
| `/Users/josh/Developer/mcp_agent_mail/src/mcp_agent_mail/app.py:9171` | Read receipts as idempotent state | `mark_message_read` is per-recipient and idempotent, returning durable read timestamps. | ADOPT |
| `/Users/josh/Developer/mcp_agent_mail/src/mcp_agent_mail/app.py:9249` | Ack receipts as callback proof | `acknowledge_message` sets both read and ack timestamps and preserves prior timestamps on repeat calls. | ADOPT |
| `/Users/josh/Developer/mcp_agent_mail/src/mcp_agent_mail/app.py:10720` | Advisory file reservation lease | Reports conflicts, writes JSON artifacts, enforces TTL, and pushes agents toward specific scoped reservations. | ADOPT |

### mcp_agent_mail_rust

| Citation | Pattern | Solves | Class |
|---|---|---|---|
| `/Users/josh/Developer/mcp_agent_mail_rust/EXISTING_MCP_AGENT_MAIL_STRUCTURE.md:109` | Doctor check/repair/backups/restore cluster | Checks stale locks, SQLite integrity, orphaned recipients, FTS mismatch, expired reservations, WAL/SHM; repair has dry-run and backup semantics. | ADOPT |
| `/Users/josh/Developer/mcp_agent_mail_rust/EXISTING_MCP_AGENT_MAIL_STRUCTURE.md:269` | Health and idempotent identity tools | Provides `health_check`, `ensure_project`, agent registration, and lookup as explicit substrate truth surfaces. | ADOPT |
| `/Users/josh/Developer/mcp_agent_mail_rust/EXISTING_MCP_AGENT_MAIL_STRUCTURE.md:279` | Acknowledged message receipt | `acknowledge_message` returns acknowledged/read timestamps, converting "sent" into "received/read." | ADOPT |
| `/Users/josh/Developer/mcp_agent_mail_rust/EXISTING_MCP_AGENT_MAIL_STRUCTURE.md:294` | File reservation lease cluster | Grants/conflicts/renews/releases/force-releases reservations with TTL and inactivity heuristics. | ADOPT |
| `/Users/josh/Developer/mcp_agent_mail_rust/EXISTING_MCP_AGENT_MAIL_STRUCTURE.md:316` | Workflow macros | Combines registration, reservation, inbox fetch, and thread prep into one receipt-bearing operation. | EXTEND |

### coding_agent_session_search

| Citation | Pattern | Solves | Class |
|---|---|---|---|
| `/Users/josh/Developer/coding_agent_session_search/AGENTS.md:377` | Derived asset truth contract | Declares SQLite as source of truth and makes lexical indexes self-healing derived assets. | ADOPT |
| `/Users/josh/Developer/coding_agent_session_search/AGENTS.md:381` | Truthful fallback metadata | Semantic assets are opportunistic; health/status/search metadata reports lexical fallback instead of hiding it. | ADOPT |
| `/Users/josh/Developer/coding_agent_session_search/AGENTS.md:393` | Quarantine instead of deletion | Corrupt assets are quarantined; GC eligibility is advisory, not automatically destructive. | ADOPT |
| `/Users/josh/Developer/coding_agent_session_search/AGENTS.md:398` | Golden-freeze JSON contract gates | Every robot JSON contract surface is pinned by golden tests; field/type changes require reviewed golden diffs. | ADOPT |
| `/Users/josh/Developer/coding_agent_session_search/AGENTS.md:586` | Fast pre-flight health + actionable exits | `cass health --json` gives readiness and `recommended_action`; exit codes include retryability and domain `err.kind`. | ADOPT |

### cass_memory_system

| Citation | Pattern | Solves | Class |
|---|---|---|---|
| `/Users/josh/Developer/cass_memory_system/SKILL.md:165` | Historical evidence gate before rule promotion | Proposed playbook rules search prior sessions and remain candidates without supporting outcomes. | ADOPT |
| `/Users/josh/Developer/cass_memory_system/SKILL.md:198` | Doctor plus fix surface | `cm doctor --json` and `cm doctor --fix` make memory health machine-visible and repairable. | EXTEND |
| `/Users/josh/Developer/cass_memory_system/SKILL.md:225` | Helpful/harmful/session-outcome feedback loop | Marks rules helpful/harmful, records session outcomes, and applies outcomes back into playbook scoring. | ADOPT |
| `/Users/josh/Developer/cass_memory_system/SKILL.md:243` | Rule validation and audit commands | `cm validate` and `cm audit` let the memory substrate test proposed rules against actual sessions. | ADOPT |

### frankensqlite

| Citation | Pattern | Solves | Class |
|---|---|---|---|
| `/Users/josh/Developer/frankensqlite/supported_surface_matrix.toml:1` | Machine-readable supported surface matrix | Freezes supported/excluded feature scope, owners, target evidence, and verification status. | ADOPT |
| `/Users/josh/Developer/frankensqlite/scripts/verify_replay_triage.sh:1` | Verification script writes evidence artifact | Runs integration/unit checks and emits a JSON artifact with schema version, verdict, counts, bead ID, and timestamp. | ADOPT |

### meta_skill

| Citation | Pattern | Solves | Class |
|---|---|---|---|
| `/Users/josh/Developer/meta_skill/README.md:13` | Skill platform with provenance/effectiveness loop | Treats feedback, outcomes, experiments, quality scores, provenance, and agent integration as first-class data. | ADOPT |
| `/Users/josh/Developer/meta_skill/src/config.rs:841` | Configured learning loop | Makes learning enabled, exploration, learning rate, cold-start threshold, bandit blend, and persistence explicit config. | EXTEND |
| `/Users/josh/Developer/meta_skill/src/suggestions/bandit/contextual.rs:731` | Learning improves prediction tests | Tests that positive/negative feedback changes recommendations and stats are updated. | ADOPT |
| `/Users/josh/Developer/meta_skill/PLAN_TO_MAKE_METASKILL_CLI.md:13697` | Outcome/feedback/effectiveness CLI | Plans command surfaces for track load/outcome, feedback, stats, improvements, calibration, quality update, and experiments. | EXTEND |
| `/Users/josh/Developer/meta_skill/PLAN_TO_MAKE_METASKILL_CLI__CONDENSED.md:1082` | Anti-pattern and uncertainty mining | Treats counterexamples and low-confidence patterns as first-class queue items for targeted evidence gathering. | EXTEND |

### asupersync

| Citation | Pattern | Solves | Class |
|---|---|---|---|
| `/Users/josh/Developer/asupersync/tests/tokio_replacement_readiness_gate_enforcement.rs:4` | Readiness gate aggregator enforcement | Tests taxonomy, evidence dimensions, evaluation rules, output schema, diagnostics, waivers, and quality gates. | ADOPT |
| `/Users/josh/Developer/asupersync/tests/t2_track_conformance_and_performance_gates.rs:186` | Acceptance criteria bound by tests | Requires exact acceptance tokens in docs so prose gates stay executable and auditable. | ADOPT |
| `/Users/josh/Developer/asupersync/docs/wasm_ga_go_no_go_evidence_packet.md:91` | Evidence packet and waiver contract | Requires threshold policy, evidence fields, per-gate statuses, artifact paths, and bounded waivers. | EXTEND |
| `/Users/josh/Developer/asupersync/docs/semantic_readiness_gates.md:181` | Minimum all-gates-pass policy | Makes "all gates pass every commit" the minimum, then maps downstream CI/property/replay consumers. | ADOPT |

### vibe_cockpit

| Citation | Pattern | Solves | Class |
|---|---|---|---|
| `/Users/josh/Developer/vibe_cockpit/AGENTS.md:241` | Fleet health pipeline | Connects collectors, DuckDB store, health scores, anomaly detection, guardian workflows, alerts, and audit log. | EXTEND |
| `/Users/josh/Developer/vibe_cockpit/AGENTS.md:321` | Cross-tool collector inventory | Collects NTM, CASS, Beads, DCG, Agent Mail, remote compilation, and other substrate metrics into one cockpit. | EXTEND |
| `/Users/josh/Developer/vibe_cockpit/AGENTS.md:355` | Robot mode mirrors human screens | Same data available as TUI screens and agent-optimized JSON/TOON envelopes. | ADOPT |
| `/Users/josh/Developer/vibe_cockpit/AGENTS.md:382` | Fail-soft, incremental, versioned collection | Uses cursors, stale data instead of crashes, idempotent inserts, schema versions, tracing, and audit logs. | ADOPT |

## 2. Cross-Cutting Findings

Patterns Jeff uses that flywheel should mine harder:

- Closed-loop verification after actuation, not just "command accepted" (`ntm`).
- JSON doctor surfaces that probe the leaf substrate and carry ok/warn/error counts (`beads_rust`, `cass`, `mcp_agent_mail`, `dcg`).
- Evidence packets with explicit gate result contracts and waiver rules (`asupersync`).
- Golden-freeze tests for robot JSON contracts (`coding_agent_session_search`).
- Binary identity/provenance checks before comparing runtime behavior (`beads_rust`).
- Bandit/effectiveness loops that make feedback modify future recommendations (`meta_skill`, `cass_memory_system`).
- Quarantine/derived-asset repair instead of destructive cleanup (`coding_agent_session_search`).

Patterns flywheel uses that were not found as strongly in Jeff's repos:

- Fuckup-log -> INCIDENTS -> L-rule promotion ladder. This looks like a flywheel innovation, not a direct Jeff pattern.
- Dispatch callback contracts requiring `socraticode_queries`, `beads_filed/no_bead_reason`, and `fuckups_logged`. Jeff has adjacent primitives but not this exact worker-supervisor contract.
- NTM pane-orchestrated redispatch as a first-class operational loop. Jeff provides the transport and verification primitives, but the doctrine layer is flywheel-specific.

Common ground:

- Machine-readable JSON output and robot surfaces.
- Doctor/health commands as trust boundaries.
- Artifact-backed evidence rather than prose-only claims.
- Explicit version/schema metadata.
- Read-only inspection by default; repair requires `--fix`, `--yes`, backup, or dry-run semantics.

## 3. Doctor Pattern Landscape

Using the `flywheel-doctor-author` shape:

- Producer: repo-local databases, JSONL files, generated indexes, checkpoint directories, CLI config, message archives, file reservations, skill feedback tables, supported-surface matrices.
- Measurement: `doctor --json`, `health --json`, `status --json`, `checkpoint verify`, conformance tests, golden tests, evidence scripts, and readiness-gate tests.
- Consumer: CLI exit codes, CI/conformance suites, agent pre-flight checks, attention feeds, TUI/robot views, repair commands, and alert/guardian loops.
- Promotion: Jeff repos usually promote through severity (`ok/warn/error`), hard-fail gates, waiver policy, or learned recommendation score. Flywheel's explicit clean-window promotion calculus is less visible upstream and should be treated as our doctrine layer on top of Jeff's primitives.

Doctor anti-patterns observed or implied:

- AVOID repair surfaces that do real mutation without dry-run, backup, or explicit confirmation.
- AVOID health that treats derived artifact corruption as source-data loss.
- AVOID doctor checks that only count docs/config and never probe the producer's leaf artifact.
- AVOID robot JSON changes without golden/schema contract review.

## 4. Callback-Validation Patterns

No single Jeff repo appears to implement "worker says DONE -> supervisor validates -> redispatch" as a complete flywheel-style loop. The reusable pieces are present:

- `ntm` actuation verification is the closest analog: after an interrupt request, NTM publishes observed readiness, pending targets, timeout state, severity, and actionability (`/Users/josh/Developer/ntm/internal/robot/robot.go:6181`). This is ADOPT for any future callback verifier.
- `ntm` scenario harness gives deterministic operator-loop artifacts and invariants (`/Users/josh/Developer/ntm/e2e/scenario_harness.go:4`). This is EXTEND for callback replay tests.
- `beads_rust` doctor/conformance compares claimed tool behavior across `br` and `bd` (`/Users/josh/Developer/beads_rust/tests/conformance.rs:9575`). This is EXTEND for cross-runtime callback claims.
- `asupersync` evidence packets define per-gate status, blocking semantics, artifacts, and waivers (`/Users/josh/Developer/asupersync/docs/wasm_ga_go_no_go_evidence_packet.md:122`). This is EXTEND for worker DONE evidence shape.
- `mcp_agent_mail` ack/read timestamps and file reservations convert "sent" into receipt/lease state (`/Users/josh/Developer/mcp_agent_mail_rust/EXISTING_MCP_AGENT_MAIL_STRUCTURE.md:279`). This is ADOPT for dispatch delivery and ownership receipts.

Lane B finding: Jeff's pattern repertoire favors verifiable primitives and artifact contracts, not a monolithic supervisor. Lane C should treat callback validation as composition of those primitives, not an invented standalone bureaucracy.

## 5. Skill Ecosystem Patterns

`meta_skill` and `cass_memory_system` are the strongest skill ecosystem references.

- `meta_skill` stores skills in SQLite plus Git for speed and accountability, with provenance and agent integration (`/Users/josh/Developer/meta_skill/README.md:87`).
- It makes effectiveness a first-class data model: usage tracking, outcomes, feedback, improvements, quality updates, and experiments (`/Users/josh/Developer/meta_skill/PLAN_TO_MAKE_METASKILL_CLI.md:13697`).
- It has explicit learning configuration: exploration, learning rate, cold-start threshold, bandit blend, persistence (`/Users/josh/Developer/meta_skill/src/config.rs:841`).
- It tests feedback changing recommendation quality (`/Users/josh/Developer/meta_skill/src/suggestions/bandit/contextual.rs:731`).
- It treats anti-patterns and uncertainty as candidates for targeted evidence mining, not discarded noise (`/Users/josh/Developer/meta_skill/PLAN_TO_MAKE_METASKILL_CLI__CONDENSED.md:1082`).
- `cass_memory_system` validates a proposed rule against historical sessions before promoting it and leaves unsupported rules as candidates (`/Users/josh/Developer/cass_memory_system/SKILL.md:165`).

Cross-runtime parity:

- `coding_agent_session_search` explicitly supports many agent session formats including Claude Code, Codex, Cursor, Gemini, Aider, Amp, ChatGPT, Cline, OpenCode, and others (`/Users/josh/Developer/coding_agent_session_search/AGENTS.md:498`).
- `meta_skill` says MCP exposes skills to Claude, Codex, and others (`/Users/josh/Developer/meta_skill/README.md:47`).
- I did not find a strong `meta_skill` cross-runtime validation gate in the K=10 + rg pass. Treat parity validation as an open Lane C constraint, not as a solved upstream pattern.

## 6. Open Questions for Lane C

Design constraints imposed by Jeff's repertoire:

1. What is the producer/measurement/consumer/promotion tuple for every flywheel surface?
2. Which surfaces need a `doctor --json` check versus a cheaper `health --json` or evidence-script check?
3. What exact artifact proves a worker callback: command output, receipt JSON, doctor slice, golden diff, or pane actuation verification?
4. What is the waiver policy for a non-blocking validation gap, and where does expiry/owner live?
5. Which validation claims should be read-only forever, and which may have explicit `--fix` repair modes?
6. How do we pin robot JSON/schema changes so "validated" does not drift invisibly?
7. How does Codex parity get validated when Claude hooks and Codex manual doctrine do not share the same runtime surface?
8. How do we feed validation outcomes back into skill selection without double-counting noisy sessions?

Patterns Jeff explicitly recommends against, as captured in local doctrine/issue-chain:

- Do not prescribe implementation in Jeff repos; cite observed gap and let Jeff design (`~/.claude/skills/jeff-issue-chain/SKILL.md:36`).
- Do not file upstream without file:line citations (`~/.claude/skills/jeff-issue-chain/SKILL.md:31`).
- Do not submit PRs or local patches to Jeff repos as the default interaction model (`~/.claude/skills/jeff-issue-chain/SKILL.md:37`).
- Do not reply to upstream just to acknowledge or ask for ETA; only reply with evidence, prioritization, or dogfood receipt (`~/.claude/skills/jeff-issue-chain/SKILL.md:82`).

Lane B recommendation boundary: this report does not propose flywheel implementation. It identifies Jeff primitives to adopt/extend/avoid for Lane C.
