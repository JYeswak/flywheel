---
title: "Phase 1 Lane A — Problem-Space Inventory"
type: plan
created: 2026-05-04
frontmatter_source: scaffold-doc-frontmatter
---

# Phase 1 Lane A — Problem-Space Inventory

Plan: `validate-and-redispatch-foundational-2026-05-03`
Lane: A, problem-space inventory
Mode: read-only research; no solution design, no bead creation, no source edits
Result: `ladder_passed=yes`

## Research Ledger

Required sources read:

- `00-INTENT.md`
- `~/.claude/projects/-Users-josh-Developer-flywheel/memory/feedback_three_audit_questions_per_surface.md`
- `~/.claude/projects/-Users-josh-Developer-flywheel/memory/feedback_orchestrator_validates_callbacks.md`
- `~/.claude/projects/-Users-josh-Developer-flywheel/memory/feedback_substrate_watchtower_must_be_wired.md`
- `AGENTS.md` L48-L69
- `INCIDENTS.md`
- `~/.local/state/flywheel/fuckup-log.jsonl` tail 50, lines 313-362

Ladder:

- Probe: Socraticode queries against `/Users/josh/Developer/flywheel` for validation/callback/tick/doctor/surfacing surfaces.
- Source: skills library lookup first, then AGENTS, INCIDENTS, memory, fuckup-log, README, dispatch/log surfaces, open/recent beads.
- Duplicate: high-criticality gaps below are mapped to existing trauma classes or existing beads; no new fuckup row filed because each high gap has existing durable evidence.
- Recent-commit/context: recent AGENTS L69 and closed/recent beads (`flywheel-d62z`, `flywheel-fh0`, `flywheel-susm`, `flywheel-e1uq`) checked for current state.

Skills library check:

- Slash surface consulted: `/flywheel:skills-best-practices "validation discipline orchestrator callback feedback loop quality assurance" --top=10 --include-content`.
- The slash command is documented at `~/.claude/commands/flywheel/skills-best-practices.md`; it defines skills-library source-(a), `--include-content`, and status semantics.
- Matching skills cited:
  - `agent-evaluation`: no agent quality claim without measured evidence; pre-deploy and runtime evaluation loop.
  - `agent-monitoring`: no blind spots; fleet health, alerting, SLOs, anomaly detection.
  - `agent-orchestration`: orchestration is decomposition plus failure management; no fire-and-forget.
  - `codebase-audit`: systematic audit output by domain with severity and evidence.
  - `beads-workflow`: plan-space first, self-contained beads, validation before dispatch.
  - `agent-mail`: file reservations, messages, identity, callback side-channel.
  - `canonical-cli-scoping`: doctor/health/repair, validate/audit/why, --info/--examples/schema for every CLI.
  - `socraticode`: source-(b), codebase survey before claims.
  - `incident-response`: severity, timeline, RCA, postmortem learning loop.
  - `accretive-cron-orchestration`: sweep/audit/learn loop with probe-before-hold discipline.
- `skills_library_gap=none_for_inventory`; no single skill covers all three audit questions as a unified flywheel primitive, but the above skills cover the constituent domains.

## Section 1: Surface Taxonomy

Flywheel surfaces identified for 3-Q audit:

1. Canonical L-rules in `AGENTS.md` and `.flywheel/AGENTS-CANONICAL.md`.
2. `INCIDENTS.md` trauma classes and per-skill incident files.
3. Memory notes under `~/.claude/projects/-Users-josh-Developer-flywheel/memory/`.
4. Skills under `~/.claude/skills/`, `~/.codex/skills/`, and flywheel command skills under `~/.claude/commands/flywheel/`.
5. Beads: open, blocked, recently closed, child/epic graphs, dependency metadata, comments.
6. Doctor signals: `flywheel doctor`, `flywheel-loop doctor`, repo-local doctor probes, auto-doctor bead promotion.
7. Tick phases: prelude, doctor/readiness, dispatch, integrate, learn/fuckup processing, closeout receipts.
8. Dispatch templates and dispatch wrappers: `/flywheel:dispatch`, `_shared/dispatch-template.md`, `.flywheel/scripts/dispatch-and-log.sh`.
9. Worker callbacks: NTM callback text, dispatch-log rows, callback expected-by fields, validation receipts.
10. Hooks: UserPromptSubmit, PreToolUse, PostToolUse, SessionStart, Stop, hook archives, hook settings.
11. Launchd plists and prompt drivers: flywheel loop, autoloop, watcher plists, per-repo prompt scripts.
12. CLI surfaces: `flywheel-loop`, `flywheel-autoloop`, `flywheel`, `br`, `ntm`, `dcg`, `cm`, `jsm`, `josh-requests`, future `flywheel-toolset-parity`.
13. MCP servers: Socraticode, Agent Mail, skill-search, and other configured MCP surfaces.
14. Agent Mail identities/messages: identities, registration tokens, inboxes, reservations, cross-orch fleet-mail.
15. Josh-request captured prompts: hook, JSONL schema, CLI, tick promotion, Codex parity gap.
16. `/flywheel:learn` loop: fuckup harvest, promotion ladder, STATE.md mining, skillos candidate routing.
17. Cross-orchestrator propagation paths: doctrine sync, canonical AGENTS propagation, fleet-mail, cross-session topology.
18. Runtime state ledgers: `~/.local/state/flywheel/`, `~/.local/state/flywheel-loop/`, `~/.local/state/flywheel-autoloop/`, dispatch logs, lock logs, receipts.
19. Repo-local `.flywheel/` docs: MISSION, GOAL, STATE, WORK, receipts, plan artifacts, lock logs.
20. Watchtowers/source monitors: Jeff substrate watchtower, Codex watchtower, issue-response watcher, info-source watchtower, version probes.
21. Safety/guardrails: DCG, dispatch transport gate, readiness gate, safe-probe, token redaction, destructive command guard.
22. Test/validation scripts: shell tests under `.flywheel/scripts/test-*`, `tests/`, template tests, probe fixtures.
23. README/user-facing docs: root README, templates README, skill docs, CLI quickstarts.
24. External upstream interaction: Jeff issue templates, outbound issue tracker, response watcher, upstream triage beads.
25. Agent/runtime panes: Claude/Codex workers, orchestrator panes, NTM health/activity/tail/diagnose surfaces.

## Section 2: 3-Q Audit Per Surface Category

Ratings: `none`, `partial`, `full mechanical gate`.

| Surface | Q1 Validated? | Q2 Documented? | Q3 Surfacing? | Evidence |
|---|---|---|---|---|
| L-rules | partial | full | partial | `AGENTS.md` L48-L69 is rich; L61 requires wire-in; no universal mechanical proof every L-rule has tests/doctor/tick consumer. |
| INCIDENTS trauma classes | partial | full | partial | `INCIDENTS.md` is populated from fuckup-log; some entries are candidates or drafts; promotion linkage is uneven. |
| Memory notes | partial | full | partial | Three required memory notes exist; `feedback_three_audit_questions_per_surface.md` says memory alone is insufficient. |
| Skills library | partial | partial | partial | Skill-search surfaced fresh indexed skills; INCIDENTS has `skill-substrate-validation-drift` from stale hashes and invalid frontmatter. |
| Beads | partial | partial | partial | `flywheel-1z65`, `flywheel-bi76`, `flywheel-2p25` encode gates; recent `flywheel-d62z` fixed falsely closed josh-request beads; source_repo leakage still open (`flywheel-5f0j`). |
| Doctor signals | partial | partial | partial | Auto-doctor creates beads (`flywheel-4ij1`, `flywheel-5f0j`), but callback validation signal is only proposed in `flywheel-1z65`; duplicate auto-doctor beads occurred. |
| Tick phases | partial | partial | partial | README describes tick loop; L60/L68 define signals; current plan states VALIDATE phase does not exist yet. |
| Dispatch templates | partial | partial | partial | README requires dispatch fields; L50-L53 define callback receipts; recent `dispatch-acceptance-gate-incomplete-corpus` proves gates can omit downstream consumability. |
| Worker callbacks | partial | partial | partial | L52/L53 require no-bead/fuckup fields; `feedback_orchestrator_validates_callbacks` and fuckup row 360 prove orchestrator validation is missing. |
| Hooks | partial | partial | partial | Josh-request hook shipped for Claude; Codex parity open as `flywheel-xap2`; token/hook transcript risk covered by L58. |
| Launchd/prompt drivers | partial | full | partial | L57 and L60 document driver proof; skillos/mobile-eats rows show active markers can still execute prompt text or block reaping. |
| CLI surfaces | partial | partial | partial | `flywheel-fh0` audit found 196 gates, only 10 PASS; canonical-cli-scoping documents the target. |
| MCP servers | partial | partial | partial | Agent Mail FD and token issues are surfaced; Socraticode-first works but FD/leak and token surfaces are not uniformly gated. |
| Agent Mail identities/messages | partial | partial | partial | L58; rows 331-337 and 342/348 show token loss/exposure/retirement; reservations protect edits but recovery is brittle. |
| Josh-request capture | partial | partial | partial | `flywheel-d62z` just closed 5/5 for Claude path; `flywheel-xap2` remains open for Codex parity. |
| `/flywheel:learn` | partial | partial | partial | L56/L62 document promotion and STATE mining; current plan asks whether findings surface throughout, indicating gaps remain. |
| Cross-orch propagation | partial | partial | partial | FoggyBear retirement and canonical doctrine drift rows show propagation/liveness can break after reboot or drift. |
| Runtime state ledgers | partial | partial | partial | L60 enumerates ledgers/receipts/callbacks/fuckup decisions; row 341 shows launchd prompt executed shell text despite driver marker. |
| Repo-local `.flywheel/` docs | partial | full | partial | Mission/goal/state docs exist; `mission-lock-drift-no-audit-trail` and canonical drift rows show validation/audit gaps. |
| Watchtowers/source monitors | partial | partial | partial | `feedback_substrate_watchtower_must_be_wired`; dcg v0.5.1 miss; `info-source-watchtower-missing` incident. |
| Safety/guardrails | partial | partial | partial | DCG and gates exist; `agent-fighting-gate`, `repeat-gate-deny-*`, and shell-backtick rows show guard results are not always transformed into bounded repair. |
| Test/validation scripts | partial | partial | partial | Many probes/tests exist; incident `test-data-in-fuckup-log` and skill validation drift show test isolation/coverage gaps. |
| README/user-facing docs | partial | partial | partial | README maps surfaces and validation commands; L61 says README update is required but not always mechanically enforced. |
| External upstream interaction | partial | partial | partial | L66 and Jeff issue chain exist; frankensqlite#85 row 346 shows local intentionality check missed before filing. |
| Agent/runtime panes | partial | partial | partial | L67/L69 landed; rows 328-352 show NTM state contradictions, Codex crashes, stale/cached pane evidence. |

## Section 3: Gap Criticality Matrix

High criticality means caused fleet-killer trauma, high-severity recent rows, or direct foundational validation failure in the last 7 days.

| Criticality | Gap | Surface | Evidence |
|---|---|---|---|
| High | `orchestrator-skipped-callback-validation` | Worker callbacks, orchestrator validation | fuckup-log line 360; `feedback_orchestrator_validates_callbacks.md`; bead `flywheel-1z65`. |
| High | `fleet-death-rca` / clean Codex exits | Agent/runtime panes, MCP/tool execution | open P0 `flywheel-delp`; three exits in one day. |
| High | `dispatch-acceptance-gate-incomplete-corpus` | Dispatch templates, acceptance gates | fuckup-log line 338: 177 repos on disk but zero semantic indexing because gate omitted consumability. |
| High | `worker_capacity_gate_false_block` / state contradiction | Tick integrate, NTM health/activity | rows 328, 330, 335, 339, 347; mobile-eats integrate blocked despite callbacks/idle evidence. |
| High | `loop-driver-active-but-prompt-shell-executed` | Launchd prompt drivers | row 341; prompt markdown executed as shell, including command-like backticks. |
| High | `agent-mail-token-transcript-exposure` | Agent Mail identities/messages, hooks/callback substrate | row 337; L58 violation; token rendered in pane transcript. |
| High | `agent-mail-identity-retired-after-reboot` | Cross-orch propagation, Agent Mail identities | row 342; FoggyBear retired made skillos unreachable. |
| High | `authenticated-jsm-sandbox-diagnose-touched-real-db` | CLI/MCP/safety boundary | row 345; supposed sandbox diagnose mutated real JSM DB mtime. |
| High | `jsm-computer-password-not-sandbox-credential-passphrase` | Secrets/auth substrate, JSM | row 350; human-provided password did not prove auth; real DB touched. |
| High | `jsm-device-login-poll-touches-real-db` | JSM CLI/auth workflow | row 354; login poll changed real DB while waiting for browser approval. |
| High | `jsm-keychain-oauth-not-usable-in-copied-sandbox` | JSM auth, keychain, sandboxing | row 355; keychain item readable but not usable API key; DB mtime changed. |
| High | `codex-pane-crashed-mid-dispatch` | Agent/runtime panes, tick recovery | row 352; pane 2 crashed mid-dispatch and tick did not catch it. |
| High | `canonical_doctrine_drift_local` | Cross-orch propagation, repo-local doctrine | rows 361-362; mobile-eats BEADS blocked by canonical snapshot drift. |
| High | `frozen-codex-spinner-misclassified-as-thinking` | Agent/runtime panes, frozen detector | `INCIDENTS.md` first entry; 5+ strikes 2026-05-03. |
| High | `orchestrator-idle-with-actionable-work` | Tick/refill/dispatch | `INCIDENTS.md`; 4 events and multiple idle/ready-work examples. |
| High | `meat-puppet-orchestrator-decision-on-partial-state` | Orchestrator decisions, state ledgers | `INCIDENTS.md`; 5 sub-classes, high severity. |
| High | `bypass-canonical-substrate-cluster` | Dispatch/NTM/topology canonical paths | `INCIDENTS.md`; high severity cluster of canonical substrate bypasses. |
| High | `documented-bug-not-actioned-self-recursion` | Beads, autoloop selection, learn loop | `INCIDENTS.md`; 3 ALPS P1 self-bug beads sat 25h+, 190 min idle spiral. |
| High | `info-source-watchtower-missing` | Watchtowers/source monitors | `INCIDENTS.md`; Codex/Codex issue blackout + 5+ strikes. |
| High | `skill-substrate-validation-drift` | Skills library validation | `INCIDENTS.md`; 182 stale chunk hashes, 164 invalid frontmatters. |

Medium criticality:

- `worker_agent_mail_release_token_lost` / `worker_agent_mail_release_token_unavailable_after_session_recovery`: rows 331-332 and 348; recurring, but localized to reservation release.
- `agent_mail_force_release_policy_gap`: row 336; policy gap caused direct SQLite release.
- `dispatch-callback-missed`: row 340; corrected via NTM send and landing verification.
- `file-without-checking-intentional-API-drift`: row 346; upstream issue quality gap, high embarrassment but not fleet-killer.
- `beads_db_source_repo_leakage`: row 343 and open `flywheel-5f0j`; recurring substrate hygiene.
- `positive-event-misrouted-to-fuckup-log`: INCIDENTS; corrupts learning signal but lower immediate operational severity.

Low criticality:

- `test-data-in-fuckup-log`: INCIDENTS; signal pollution but contained.
- `file-reservation-after-edit`: row 315; ordering issue, no conflict observed.
- `shell-heredoc-backtick-execution`: row 317; no source/JSM mutation.
- `integrate_worker_not_waiting`: rows 351/353/358/359; often symptom of broader capacity gate contradictions.

## Section 4: Failure Mode Catalog

High-criticality failure modes and durable evidence:

1. `orchestrator-skipped-callback-validation`
   - Evidence: fuckup-log line 360; `feedback_orchestrator_validates_callbacks.md`; `flywheel-1z65`.
   - Row exists: yes.

2. `fleet-death-rca` / `codex-pane-crashed-mid-dispatch`
   - Evidence: `flywheel-delp`; fuckup-log line 352.
   - Row exists: yes for crash; RCA bead exists for clean exits.

3. `dispatch-acceptance-gate-incomplete-corpus`
   - Evidence: fuckup-log line 338; dispatch path `/tmp/dispatch_jeff-corpus-clone-rebuild_2026_05_03.md`.
   - Row exists: yes.

4. `worker_capacity_gate_false_block` / `worker_capacity_gate_state_contradiction`
   - Evidence: rows 328, 330, 335, 347; recent `flywheel-susm` closeout.
   - Row exists: yes.

5. `loop-driver-active-but-prompt-shell-executed`
   - Evidence: row 341; skillos launchd loop stderr and `.flywheel/run-30m-loop.sh`.
   - Row exists: yes.

6. `agent-mail-token-transcript-exposure`
   - Evidence: row 337; AGENTS L58.
   - Row exists: yes.

7. `agent-mail-identity-retired-after-reboot`
   - Evidence: row 342; `flywheel-6krl`, `flywheel-7jp3`.
   - Row exists: yes.

8. `authenticated-jsm-sandbox-diagnose-touched-real-db`
   - Evidence: row 345; bead `skillos-1kc`.
   - Row exists: yes.

9. `jsm-computer-password-not-sandbox-credential-passphrase`
   - Evidence: row 350; real DB mtime changed while auth still failed.
   - Row exists: yes.

10. `jsm-device-login-poll-touches-real-db`
    - Evidence: row 354; remote login changed real DB mtime.
    - Row exists: yes.

11. `jsm-keychain-oauth-not-usable-in-copied-sandbox`
    - Evidence: row 355; OAuth JSON not usable as `jsm_` API key; real DB mtime changed.
    - Row exists: yes.

12. `canonical_doctrine_drift_local`
    - Evidence: rows 361-362; open auto-doctor bead `flywheel-4ij1`.
    - Row exists: yes.

13. `frozen-codex-spinner-misclassified-as-thinking`
    - Evidence: `INCIDENTS.md`, `flywheel-mugq`, `flywheel-ezyf`, detector script.
    - Row exists: promoted in INCIDENTS.

14. `orchestrator-idle-with-actionable-work`
    - Evidence: `INCIDENTS.md`; rows 45, 57, 59, 64 cited there.
    - Row exists: promoted in INCIDENTS.

15. `meat-puppet-orchestrator-decision-on-partial-state`
    - Evidence: `INCIDENTS.md`; row classes listed in entry.
    - Row exists: promoted in INCIDENTS.

16. `bypass-canonical-substrate-cluster`
    - Evidence: `INCIDENTS.md`; cross-links to L66/L67/L68.
    - Row exists: promoted in INCIDENTS.

17. `documented-bug-not-actioned-self-recursion`
    - Evidence: `INCIDENTS.md`; ALPS beads `josh-1eo8p`, `josh-1s3ie`, `josh-35h17`.
    - Row exists: promoted in INCIDENTS.

18. `info-source-watchtower-missing`
    - Evidence: `INCIDENTS.md`; `flywheel-1ndw`, `flywheel-ezyf`, `dicklesworthstone-stack`.
    - Row exists: promoted in INCIDENTS.

19. `skill-substrate-validation-drift`
    - Evidence: `INCIDENTS.md`; rows 61, 63, 66 cited.
    - Row exists: promoted in INCIDENTS.

No new fuckup row was filed in this read-only lane because every high-criticality gap named above already has a fuckup-log row, INCIDENTS entry, or open bead.

## Section 5: Open Questions For Lane B And Lane C

Lane B, Jeff substrate/ecosystem audit questions:

1. What validation/callback contract patterns exist in Jeff's `ntm`, `beads_rust`, `mcp_agent_mail`, `socraticode`, `dcg`, and `jsm` repos that should inform this plan?
2. Does Jeff have a canonical representation for worker callback validation, or is this a ZestStream-only pattern?
3. How do Jeff tools distinguish CLI identity, runtime context, and command transport in their doctor/health outputs?
4. What upstream surfaces already expose live-vs-cached provenance for pane state, callback state, or agent activity?
5. How does Jeff's own issue response/watchtower workflow prevent documented-but-unwired source monitors?
6. Are there existing Jeff patterns for "positive learning event" vs "failure/fuckup event" substrate separation?
7. Which Jeff tools already support schemas for validation receipts and could be reused as examples?
8. Does `mcp_agent_mail` have a first-class token recovery / reservation release pattern after compaction or reboot?
9. Does `jsm` have a safe diagnostic mode that guarantees no real DB mtime mutation?
10. Which Jeff repos should Lane B mine for end-to-end validation terminology and state machine shape?

Lane C, implementation-design constraints imposed by this taxonomy:

1. The design must span all three questions: validation, documentation, and surfacing; a callback validator alone is too narrow.
2. The design must treat worker `DONE` as a proposal until orchestrator validation records a receipt.
3. The design must not rely on memory-only rules; it needs a mechanical gate or doctor/tick signal per surface.
4. The design must preserve agent-runtime context distinctions from L69.
5. The design must preserve CLI identity proof from L65.
6. The design must connect validation failures to beads or explicit no-bead reasons, matching L52.
7. The design must connect trauma discoveries to fuckup-log and INCIDENTS promotion, matching L53/L56.
8. The design must define where positive outcomes live so they do not pollute fuckup-log.
9. The design must include cross-orch and cross-runtime propagation, not only local flywheel repo behavior.
10. The design must handle unresponsive agents as first-class states, not substitute raw shell probes.
11. The design must distinguish documented, wired, and executed; those are three different states.
12. The design must expose "validated end-to-end" as data that `/flywheel:learn`, doctor, tick, and dispatch logs can read.
