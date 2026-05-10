---
title: "Recovery Phase 3 Audit Findings Synthesis"
type: plan
created: 2026-05-04
frontmatter_source: scaffold-doc-frontmatter
---

## Contents

- [1. Decisions For Joshua](#1-decisions-for-joshua)
  - [D01 - Advance Strategy For Phase 4](#d01-advance-strategy-for-phase-4)
  - [D02 - V1 Protection Scope](#d02-v1-protection-scope)
  - [D03 - Protected Restore Authorization Artifact](#d03-protected-restore-authorization-artifact)
  - [D04 - Protected Checkpoint Data Policy](#d04-protected-checkpoint-data-policy)
  - [D05 - LaunchAgent Preplant Handling](#d05-launchagent-preplant-handling)
  - [D06 - Boot Timeline And Dependency DAG](#d06-boot-timeline-and-dependency-dag)
  - [D07 - Orphan Redispatch Side-Effect Policy](#d07-orphan-redispatch-side-effect-policy)
  - [D08 - Manual Rescue Without Live Orchestrator](#d08-manual-rescue-without-live-orchestrator)
  - [D09 - Lock Hierarchy And Stale-Lock Policy](#d09-lock-hierarchy-and-stale-lock-policy)
  - [D10 - Beads DB Restore Policy](#d10-beads-db-restore-policy)
  - [D11 - Schedule Authority And Fire-ID Semantics](#d11-schedule-authority-and-fire-id-semantics)
  - [D12 - Drill Cadence And Test Namespace](#d12-drill-cadence-and-test-namespace)
  - [D13 - Bead 12 Scope](#d13-bead-12-scope)
- [2. Combined Critical Findings Register](#2-combined-critical-findings-register)
  - [CR-01 - Boot-to-live timeline is not measurable](#cr-01-boot-to-live-timeline-is-not-measurable)
  - [CR-02 - Cross-session boot dependency ordering is absent](#cr-02-cross-session-boot-dependency-ordering-is-absent)
  - [CR-03 - Worker orphan redispatch lacks side-effect gate](#cr-03-worker-orphan-redispatch-lacks-side-effect-gate)
  - [CR-04 - Protected restore authorization is not a durable boundary](#cr-04-protected-restore-authorization-is-not-a-durable-boundary)
  - [CR-05 - Manual rescue path is missing when orchestrator is dead](#cr-05-manual-rescue-path-is-missing-when-orchestrator-is-dead)
  - [CR-06 - LaunchAgent preplant handling is undefined](#cr-06-launchagent-preplant-handling-is-undefined)
  - [CR-07 - Protected checkpoint payloads can preserve client secrets](#cr-07-protected-checkpoint-payloads-can-preserve-client-secrets)
  - [CR-08 - Simultaneous restore of same session is possible](#cr-08-simultaneous-restore-of-same-session-is-possible)
  - [CR-09 - Watcher/bootstrap can race with snapshot](#cr-09-watcher-bootstrap-can-race-with-snapshot)
  - [CR-10 - Retention can prune while snapshot writes](#cr-10-retention-can-prune-while-snapshot-writes)
  - [CR-11 - Beads DB can be read/restored while live writers mutate it](#cr-11-beads-db-can-be-read-restored-while-live-writers-mutate-it)
- [3. Combined High And Medium Findings Register](#3-combined-high-and-medium-findings-register)
  - [HIGH Findings](#high-findings)
  - [MEDIUM Findings Grouped By Theme](#medium-findings-grouped-by-theme)
- [4. Cross-Lens Patterns](#4-cross-lens-patterns)
  - [Pattern 1 - Boot Timeline Appears In Every Lens](#pattern-1-boot-timeline-appears-in-every-lens)
  - [Pattern 2 - Protected Sessions Are Policy, Data, And Authorization](#pattern-2-protected-sessions-are-policy-data-and-authorization)
  - [Pattern 3 - B12 Is The Compression Point](#pattern-3-b12-is-the-compression-point)
  - [Pattern 4 - Local Durability Without Tamper/Atomic Contracts Is Not Enough](#pattern-4-local-durability-without-tamper-atomic-contracts-is-not-enough)
  - [Pattern 5 - Active Work Is The Hard Boundary](#pattern-5-active-work-is-the-hard-boundary)
  - [Pattern 6 - ALPS Exposure Is Not Paranoia](#pattern-6-alps-exposure-is-not-paranoia)
  - [Pattern 7 - Cross-Cutting Found What Single-Class Lenses Missed](#pattern-7-cross-cutting-found-what-single-class-lenses-missed)
  - [Pattern 8 - Existing Beads Can Absorb Most Fixes, But Not All](#pattern-8-existing-beads-can-absorb-most-fixes-but-not-all)
- [5. Plan Readiness Gauge - Combined](#5-plan-readiness-gauge-combined)
- [6. Recommended Next-Phase Plan](#6-recommended-next-phase-plan)
  - [Option A - Full r2 Plan Refinement](#option-a-full-r2-plan-refinement)
  - [Option B - Targeted Bead Changes](#option-b-targeted-bead-changes)
  - [Option C - Joshua-Disposes Split](#option-c-joshua-disposes-split)
- [7. Bead-DAG Impact Summary](#7-bead-dag-impact-summary)
  - [Original 12 Beads From Lane C / 00-PLAN](#original-12-beads-from-lane-c-00-plan)
  - [New Beads Required](#new-beads-required)
  - [Acceptance Changes To Existing Beads](#acceptance-changes-to-existing-beads)
  - [Cycle Check](#cycle-check)
- [8. Convergence Test Result](#8-convergence-test-result)
- [9. Audit-Phase Costs](#9-audit-phase-costs)
- [10. References](#10-references)
- [Validation Ladder](#validation-ladder)
# Recovery Phase 3 Audit Findings Synthesis
Task: `recovery_audit_synthesis`
Date: 2026-05-01
Mode: Phase 3 audit synthesis, plan-space only
Output role: audit -> decompose boundary digest
Inputs read:
- `03-AUDIT-r1-CROSSCUTTING.md` — 20 concerns, 5 criticals, readiness RED.
- `03-AUDIT-r1-SECURITY.md` — 18 threats, 3 criticals.
- `03-AUDIT-r1-IDEMPOTENCY.md` — 16 concerns, 4 criticals, 7 races.
- `00-PLAN.md` — post-r2 converged plan, 12 Joshua decisions, 12-bead DAG.
- `01-RESEARCH-A.md` — Lane A state inventory, 21 layers, 16 failure modes.
- `01-RESEARCH-B.md` — Lane B Jeff-pattern audit, 48 findings, 18 adoption calls.
- `01-RESEARCH-C.md` — Lane C implementation/bead design, 12 beads, caveat `ladder_passed=no`.
## 1. Decisions For Joshua
These decisions should be disposed before Phase 4 starts, or explicitly carried
as bead-gated overlays. Each one cites the audit finding(s) that make it
load-bearing.
### D01 - Advance Strategy For Phase 4
Decision text:
- Should Phase 3 reopen for a full r2 audit, proceed to beads with overlay, or split by critical?
Options:
- Option A: full r2 plan refinement. Lowest implementation ambiguity, highest delay.
- Option B: proceed to bead conversion with audit-overlay acceptance criteria. Fastest, but risks burying plan-graph changes inside B12.
- Option C: hybrid. Reopen only graph/approval/rescue decisions, convert validator/lock/test findings into bead overlays.
Recommendation:
- Option C. The audits agree the architecture is sound, but graph-shaping criticals cannot be treated as ordinary B12 polish.
Cost of not deciding:
- Phase 4 either stalls on uncertainty or creates beads that later need topology-breaking edits.
Raised by:
- Cross-cutting, security, idempotency.
Citation:
- `CC-C01`, `CC-C03`, `CC-C11`, `CC-C16`, `SEC-T06`, `IDM-C03`.
### D02 - V1 Protection Scope
Decision text:
- Which sessions are in v1 apply scope, not merely audit scope?
Options:
- Option A: all 8 sessions. Fastest fleet coverage, highest blast radius.
- Option B: flywheel + skillos + internal non-client sessions. Safer, but ALPS/Picoz remain unprotected.
- Option C: scratch/disposable drill first, then flywheel, then protected sessions by evidence.
Recommendation:
- Option C for restore/apply; Option A for audit-only status. This honors protected-session risk while still measuring the whole fleet.
Cost of not deciding:
- B04-B11 can install/apply against ALPS/Picoz without an agreed protected-session boundary.
Raised by:
- Security and cross-cutting.
Citation:
- `SEC-T04`, `SEC-T06`, `CC-C11`, `CC-C16`.
### D03 - Protected Restore Authorization Artifact
Decision text:
- What is the durable proof that Joshua authorized protected `restore --apply`?
Options:
- Option A: per-run token/receipt with scope and expiry. Strongest auditability; adds a small schema.
- Option B: live human-pane confirmation row. Simpler, but weaker after reboot if pane state is damaged.
- Option C: dry-run only for protected sessions in v1. Safest, but delays full recovery value.
Recommendation:
- Option A for protected apply; Option C until the receipt schema exists.
Cost of not deciding:
- "Explicit approval" remains prose, so any pane could potentially invoke an apply path.
Raised by:
- Security and cross-cutting.
Citation:
- `SEC-T06`, `SEC-C01`, `CC-C11`.
### D04 - Protected Checkpoint Data Policy
Decision text:
- Are raw protected-session checkpoints allowed at rest, and under what retention/encryption rule?
Options:
- Option A: shallow/redacted default, no raw retention for protected sessions. Lowest exposure, weaker forensic replay.
- Option B: raw local retention allowed with mode checks and optional encryption. Better recovery, higher compliance surface.
- Option C: raw retention only by per-session Joshua approval. More ceremony, strongest client-data control.
Recommendation:
- Option C for ALPS/Picoz; Option B for internal sessions if mode/encryption checks pass.
Cost of not deciding:
- ALPS/client scrollback can be preserved for 14 daily + 8 weekly cycles without an explicit business decision.
Raised by:
- Security, idempotency, cross-cutting.
Citation:
- `SEC-T04`, `SEC-T12`, `IDM-C05`, `CC-C01`.
### D05 - LaunchAgent Preplant Handling
Decision text:
- If a watcher plist label already exists, should recovery accept, overwrite, quarantine, or block?
Options:
- Option A: block on mismatch and require Joshua decision. Safest, may interrupt install.
- Option B: quarantine old plist then install canonical. Operationally smooth, but still mutates launchd state.
- Option C: overwrite if owner/mode/label match. Fastest, weaker against stale malicious content.
Recommendation:
- Option A for protected sessions; Option B for non-protected after dry-run shows exact diff.
Cost of not deciding:
- A stale or malicious plist can satisfy "exists" while running wrong ProgramArguments.
Raised by:
- Security.
Citation:
- `SEC-T01`, `SEC-C03`, `SEC-T03`.
### D06 - Boot Timeline And Dependency DAG
Decision text:
- Should boot recovery have an explicit timed state machine and cross-session DAG?
Options:
- Option A: encode both before Phase 4. Highest plan quality, adds one new bead.
- Option B: encode only B12 acceptance text. Fewer beads, higher risk B12 becomes opaque.
- Option C: defer DAG until after first drill. Fastest, but weakens readiness claim.
Recommendation:
- Option A. The boot timeline and dependency graph are critical, not polish.
Cost of not deciding:
- Watchers, Agent Mail, topology, and sessions can come up in unsafe order while status still looks green.
Raised by:
- Cross-cutting and idempotency.
Citation:
- `CC-C01`, `CC-C03`, `IDM-C04`.
### D07 - Orphan Redispatch Side-Effect Policy
Decision text:
- When a reboot kills a worker before callback, what side-effect classes allow redispatch?
Options:
- Option A: redispatch only if `external_side_effect_class=none`. Safest, more manual review.
- Option B: redispatch local-file work if repo state is unchanged. Balanced, needs probes.
- Option C: redispatch unknowns after timeout. Fast, but can duplicate service/client effects.
Recommendation:
- Option B with unknown defaulting to block. The ledger should distinguish plan-space from service/client state.
Cost of not deciding:
- Recovery may duplicate GitHub, launchd, checkpoint, or client-system side effects.
Raised by:
- Cross-cutting plus security/idempotency active-dispatch findings.
Citation:
- `CC-C04`, `SEC-T10`, `IDM-C02`.
### D08 - Manual Rescue Without Live Orchestrator
Decision text:
- What exact local command path exists if flywheel pane 1 does not come back?
Options:
- Option A: standalone `RESCUE.md` generated from latest manifest. Low-tech, robust.
- Option B: recovery helper `rescue` form only. Cleaner CLI, weaker if helper path is broken.
- Option C: defer until after v1. Fastest, leaves worst case undocumented.
Recommendation:
- Option A plus helper command pointers. A printed/local rescue card is the least coupled recovery primitive.
Cost of not deciding:
- Recovery depends on the orchestrator it is meant to restore.
Raised by:
- Cross-cutting and security path-hijack concerns.
Citation:
- `CC-C16`, `SEC-T18`.
### D09 - Lock Hierarchy And Stale-Lock Policy
Decision text:
- Which lock hierarchy governs install, snapshot, restore, retention, watcher, audit append, and schedule?
Options:
- Option A: one fleet lock. Simple, but over-serializes and blocks safe parallel status.
- Option B: hierarchical fleet/config/session/snapshot/restore/audit locks. More work, precise.
- Option C: no locks in v1 except restore. Fast, but leaves known races.
Recommendation:
- Option B. The idempotency audit found enough races that coarse prose is not sufficient.
Cost of not deciding:
- Parallel restore, retention-vs-snapshot, watcher-vs-snapshot, and JSONL append races remain live.
Raised by:
- Idempotency, cross-cutting, security.
Citation:
- `IDM-C03`, `IDM-C04`, `IDM-C05`, `IDM-C10`, `IDM-C14`, `SEC-T13`.
### D10 - Beads DB Restore Policy
Decision text:
- Can recovery ever write `.beads/*.db` from a checkpoint in v1?
Options:
- Option A: inspect-only v1; never replace Beads DBs. Safest for issue substrate.
- Option B: replace only with explicit Joshua receipt and pre/post hashes. More capability, higher risk.
- Option C: full DB restore from checkpoint. Fast recovery, highest corruption/rollback risk.
Recommendation:
- Option A for v1.
Cost of not deciding:
- Restore can regress issue state or poison redispatch decisions while workers are active.
Raised by:
- Idempotency, security, cross-cutting.
Citation:
- `IDM-C15`, `SEC-T15`, `CC-C06`.
### D11 - Schedule Authority And Fire-ID Semantics
Decision text:
- Is remote `/schedule` authoritative, and what idempotency key identifies a nightly fire?
Options:
- Option A: local launchd helper only. Deterministic, less external supervision.
- Option B: remote `/schedule` only. Less local setup, but wrong substrate for local NTM commands.
- Option C: local helper authoritative; remote schedule is constant-size nudge/monitor.
Recommendation:
- Option C with `nightly:<date>:<time>:<schedule-id>` fire IDs.
Cost of not deciding:
- Duplicate schedule payloads can create duplicate checkpoints, or cloud prompt drift can trigger partial recovery.
Raised by:
- Security and idempotency.
Citation:
- `SEC-T07`, `SEC-T08`, `IDM-C16`.
### D12 - Drill Cadence And Test Namespace
Decision text:
- What recurring drill cadence and isolation namespace are required after initial readiness?
Options:
- Option A: one-time D1-D4 only. Fastest, rots quickly.
- Option B: monthly disposable-session drill and quarterly full dry-run. Balanced.
- Option C: weekly drill. Strong signal, more noise.
Recommendation:
- Option B, with `flywheel-recovery-test-*` session names, separate state dir, and cleanup receipt.
Cost of not deciding:
- Recovery can pass launch then silently rot as NTM, AM, launchd, and repo topology change.
Raised by:
- Cross-cutting and security doctrine.
Citation:
- `CC-C18`, `CC-C19`, `CC-C20`, `SEC-L63`.
### D13 - Bead 12 Scope
Decision text:
- Does B12 remain one bead, or split baseline snapshot, nightly schedule, restore, and drills?
Options:
- Option A: keep B12 but require four milestone receipts. Preserves 12-bead cap.
- Option B: split into multiple beads. Clearer ownership, increases graph size.
- Option C: keep B12 and file follow-ups only after slippage. Fast now, weak control.
Recommendation:
- Option A only if B12 acceptance gains explicit milestone receipts; otherwise Option B.
Cost of not deciding:
- Snapshot, retention, restore, schedule, and drill criticals can be hidden inside one oversized bead.
Raised by:
- Cross-cutting and idempotency.
Citation:
- `CC-C20`, `IDM-C05`, `IDM-C13`, `IDM-C16`.
## 2. Combined Critical Findings Register
Raw criticals across lenses:
- Cross-cutting: 5.
- Security: 3.
- Idempotency: 4.
- Raw total: 12.
Deduplicated criticals:
- Total deduped criticals: 11.
- Multi-lens criticals: 6.
- New beads required: 3.
- Existing-bead acceptance changes: 12 original beads touched.
- Joshua-only decisions: 13.
### CR-01 - Boot-to-live timeline is not measurable
Severity:
- CRITICAL.
Source lens(es):
- Cross-cutting: `CC-C01`.
- Idempotency overlap: `IDM-C04`.
Affected layer:
- Lane A layer 1 NTM session process.
- Lane A layer 10 Agent Mail service.
- Lane A layer 14 session topology.
- Lane A layer 16 fleet health daemon.
Affected bead:
- B12, plus new B13 boot dependency DAG.
Mitigation summary:
- Emit `boot_timeline.jsonl` with ordered states, timestamps, timeouts, failure reason, and next manual command.
Owner:
- New bead B13 and B12 acceptance; Joshua sets timeout defaults.
### CR-02 - Cross-session boot dependency ordering is absent
Severity:
- CRITICAL.
Source lens(es):
- Cross-cutting: `CC-C03`.
Affected layer:
- Lane A layer 10 Agent Mail service.
- Lane A layer 14 session topology.
- Lane A layer 15 team roster/pulse.
- Lane A layer 19 in-flight dispatch context.
Affected bead:
- New B13 before B12.
Mitigation summary:
- Add `boot-plan.json` with nodes, dependencies, protection class, timeout, and fallback command.
Owner:
- New bead B13; can be absorbed into B01 only if Joshua refuses bead expansion.
### CR-03 - Worker orphan redispatch lacks side-effect gate
Severity:
- CRITICAL.
Source lens(es):
- Cross-cutting: `CC-C04`.
- Security/idempotency overlap: `SEC-T10`, `IDM-C02`.
Affected layer:
- Lane A layer 18 tick receipts/logs.
- Lane A layer 19 in-flight dispatch context.
- Lane A layer 20 `/tmp` tentacle plans.
Affected bead:
- B01 dispatch ledger schema.
- B12 restore/orphan reconciliation.
Mitigation summary:
- Add `external_side_effect_class` and block redispatch unless side effects are known safe or Joshua approves.
Owner:
- Existing bead acceptance change; Joshua decides unknown/default policy.
### CR-04 - Protected restore authorization is not a durable boundary
Severity:
- CRITICAL.
Source lens(es):
- Cross-cutting: `CC-C11`.
- Security: `SEC-T06`, `SEC-C01`.
Affected layer:
- Lane A layer 1 NTM session process.
- Lane A layer 10 Agent Mail service.
- Lane A layer 19 in-flight dispatch context.
Affected bead:
- New B14 recovery approval ledger, or B01 schema + B12 enforcement.
Mitigation summary:
- Add `recovery-approval.jsonl` with actor, scope, allowed actions, expiry, protected sessions, and reason.
Owner:
- Joshua-disposes plus new B14.
### CR-05 - Manual rescue path is missing when orchestrator is dead
Severity:
- CRITICAL.
Source lens(es):
- Cross-cutting: `CC-C16`.
- Security overlap: `SEC-T18`.
Affected layer:
- Lane A layer 1 NTM session process.
- Lane A layer 14 session topology.
- Lane A layer 21 project memory.
Affected bead:
- New B15 standalone rescue card before B12.
Mitigation summary:
- Generate `RESCUE.md` with exact commands to list manifests, verify latest checkpoint, dry-run restore flywheel, and open latest handoff.
Owner:
- New B15; Joshua approves manual restore policy.
### CR-06 - LaunchAgent preplant handling is undefined
Severity:
- CRITICAL.
Source lens(es):
- Security: `SEC-T01`, `SEC-C03`.
- Idempotency/boot overlap: `IDM-C13`.
Affected layer:
- Lane A layer 1 NTM session process.
- Lane A layer 14 session topology.
- Lane A layer 16 fleet health daemon.
Affected bead:
- B04-B11 plist install beads.
- B01 plist policy.
Mitigation summary:
- Verify owner, mode, label, ProgramArguments hash, helper path, and `plutil`; mismatch blocks or quarantines by policy.
Owner:
- Existing bead acceptance change; Joshua decides overwrite/quarantine policy.
### CR-07 - Protected checkpoint payloads can preserve client secrets
Severity:
- CRITICAL.
Source lens(es):
- Security: `SEC-T04`, `SEC-C02`.
- Idempotency/storage overlap: `IDM-C05`.
Affected layer:
- Lane A layer 2 pane layout/scrollback.
- Lane A layer 4 Claude transcripts.
- Lane A layer 5 Codex state.
- Lane A layer 20 `/tmp` artifacts.
Affected bead:
- B12 snapshot/retention.
- B02 protected-session classifier.
Mitigation summary:
- Default protected sessions to shallow/redacted exports; raw retention requires local mode/encryption checks and Joshua approval.
Owner:
- B02/B12 acceptance plus Joshua data-retention decision.
### CR-08 - Simultaneous restore of same session is possible
Severity:
- CRITICAL.
Source lens(es):
- Idempotency: `IDM-C03`.
- Security overlap: `SEC-T11`, `SEC-T06`.
Affected layer:
- Lane A layer 1 NTM session process.
- Lane A layer 2 pane layout.
- Lane A layer 19 dispatch context.
Affected bead:
- B01 lock contract.
- B12 restore apply.
Mitigation summary:
- Add `restore.<session>.lock` with atomic acquisition, owner metadata, heartbeat, and protected stale-steal rules.
Owner:
- Existing bead acceptance change; lock policy in B01.
### CR-09 - Watcher/bootstrap can race with snapshot
Severity:
- CRITICAL.
Source lens(es):
- Idempotency: `IDM-C04`.
- Cross-cutting overlap: `CC-C01`, `CC-C03`.
Affected layer:
- Lane A layer 1 session process.
- Lane A layer 14 topology.
- Lane A layer 16 fleet health daemon.
Affected bead:
- B04-B11 watcher install.
- B12 snapshot/restore.
- New B13 boot DAG.
Mitigation summary:
- Shared session lock blocks watcher/bootstrap while snapshot/restore owns the session; snapshot records watcher state.
Owner:
- B01 lock contract, B04-B12 acceptance, B13 ordering.
### CR-10 - Retention can prune while snapshot writes
Severity:
- CRITICAL.
Source lens(es):
- Idempotency: `IDM-C05`.
- Security storage overlap: `SEC-T04`, `SEC-T12`.
Affected layer:
- Lane A layer 2 scrollback/checkpoint state.
- Lane A layer 20 artifact promotion.
Affected bead:
- B12 snapshot/retention.
Mitigation summary:
- Snapshot writes to `.staging/<run_id>`, verifies archive/manifest, atomically publishes; retention ignores staging and current manifest references.
Owner:
- Existing B12 acceptance change.
### CR-11 - Beads DB can be read/restored while live writers mutate it
Severity:
- CRITICAL.
Source lens(es):
- Idempotency: `IDM-C15`.
- Security/cross-cutting overlap: `SEC-T15`, `CC-C06`.
Affected layer:
- Lane A layer 8 Beads DBs.
- Lane A layer 9 dirty worktrees.
- Lane A layer 19 dispatch context.
Affected bead:
- B02 Beads integrity.
- B12 restore/reconcile.
Mitigation summary:
- V1 restore never replaces `.beads/*.db`; it uses read-only snapshot copies and marks orphan work instead.
Owner:
- Existing B02/B12 acceptance change.
## 3. Combined High And Medium Findings Register
### HIGH Findings
- `CC-C02`: Snapshot/restore round-trip lacks equality criteria; B12 must compare pane count, cwd, titles, commands, scrollback hash/line count, git head, and resume pointers.
- `CC-C05`: Loop tick continuity protects files but not reactivation behavior; B12 needs `resume_now|pause_stale_state|blocked_missing_pane`.
- `CC-C06`: Restored cwd is not tied to `.beads` DB path; B12 must compare cwd, manifest repo, git top-level, and Beads path.
- `CC-C09`: Agent Mail token files and DB identity rows can diverge; B02/B12 need token/DB conflict policy.
- `CC-C12`: L61 dual-channel communication has boot-time race; B12 needs `dual_channel_queue.jsonl`.
- `CC-C13`: Strict doctor can false-fail during recovery; B01/B12 need `--recovery-phase`.
- `CC-C19`: Test environment isolation is weak; B12 needs separate namespace, state dir, label prefix, and cleanup receipt.
- `CC-C20`: Failure injection is shallow for listed failure modes; B12 needs explicit F2/F4/F6/F8/F10/F11/F12/F16 fixtures.
- `SEC-T02`: Session-name validation may not cover all derived surfaces; centralize `validate_session_name()`.
- `SEC-T03`: Plist ownership/mode policy is missing; B01/B04-B11 need owner/group/mode/hash policy.
- `SEC-T05`: Cross-session checkpoint bleed is possible; restore preflight must bind checkpoint to target session/repo.
- `SEC-T07`: Remote `/schedule` can drift or inject commands; payload must be constant local-helper reference only.
- `SEC-T09`: Artifact promotion/checkpoint export lacks symlink/path traversal policy.
- `SEC-T10`: Snapshot during active dispatch lacks fail-closed protected-session rule.
- `SEC-T11`: Live-target restore has weak "when feasible" checkpoint language; protected force restore must require idle/drain/token.
- `SEC-T12`: Retention can preserve rotated secrets/client data; manifest needs sensitivity, secret epoch, and retire-after.
- `SEC-T13`: Audit JSONL has no tamper evidence; add hash chain and doctor verification.
- `SEC-T14`: Agent Mail token handling lacks reauth survival policy; token content excluded but path/mode/hash readiness needed.
- `SEC-T15`: Beads DB poisoning/rollback can confuse redispatch; v1 should hash/read-only inspect, not overwrite.
- `SEC-T16`: Latest manifest replay can be stale/poisoned; registry needs hash chain and monotonic supersession.
- `SEC-T18`: Helper path/PATH hijack risk at launchd/schedule time; B01 pins absolute paths or validates hashes.
- `IDM-C01`: Install rerun safety is implicit; B03/B04-B11 need `already_current` behavior and stable hashes.
- `IDM-C02`: Snapshot during active worker generation lacks quiescence protocol.
- `IDM-C06`: Atomic write contract is explicit only for manifest; all mutation classes need temp/fsync/rename or append locks.
- `IDM-C07`: Idempotency key scope/storage/conflict behavior is undefined.
- `IDM-C08`: Partial install after 5/8 plists lacks converge-forward semantics.
- `IDM-C09`: Crash mid-install has no recovery-operation journal.
- `IDM-C10`: Lock directory, owner schema, stale policy, and lock ordering are missing.
- `IDM-C11`: Direct lower-level phase invocation could bypass preconditions.
- `IDM-C13`: Watcher restart loops need backoff/status/disable state.
### MEDIUM Findings Grouped By Theme
Path and memory identity:
- Count: 3.
- Citations: `CC-C07`, `CC-C08`, `CC-C10`.
- Theme: canonical cwd changes can drift Claude memory, CASS project SHA, and substrate registry truth.
Hook/operator surface:
- Count: 3.
- Citations: `CC-C14`, `CC-C15`, `CC-C17`.
- Theme: shell hooks, first-boot UX, and non-orchestrator invocation need explicit guardrails.
Drill and long-term maintenance:
- Count: 1.
- Citation: `CC-C18`.
- Theme: drill cadence cannot end after initial soak.
Schedule/callback leakage:
- Count: 2.
- Citations: `SEC-T08`, `SEC-T17`.
- Theme: schedule payload truncation and callback content leakage need fixed-size structured fields.
Checkpoint/artifact/idempotency hygiene:
- Count: 3.
- Citations: `IDM-C12`, `IDM-C14`, `IDM-C16`.
- Theme: checkpoint name collision, fuckup-log append races, and cron fire duplication are medium severity but easy to harden now.
Medium total:
- 12.
## 4. Cross-Lens Patterns
### Pattern 1 - Boot Timeline Appears In Every Lens
Cross-cutting sees missing measurable boot states (`CC-C01`, `CC-C03`).
Security sees launchd as a trust boundary (`SEC-T01`, `SEC-T18`).
Idempotency sees watcher/snapshot and watcher-loop races (`IDM-C04`, `IDM-C13`).
Impact:
- Upgrade boot-DAG work from B12 detail to explicit pre-B12 overlay bead.
### Pattern 2 - Protected Sessions Are Policy, Data, And Authorization
Security flags protected restore privilege and ALPS raw payload exposure
(`SEC-T04`, `SEC-T06`). Cross-cutting flags durable Joshua approval (`CC-C11`).
Idempotency flags live/parallel restore risk (`IDM-C03`).
Impact:
- A protected-session decision cannot be a single yes/no. It needs scope, authorization, retention, restore force, and expiry semantics.
### Pattern 3 - B12 Is The Compression Point
Cross-cutting warns B12 hides critical acceptance (`CC-C20`). Security adds
ten B12 amendments. Idempotency puts snapshot, restore, retention, schedule,
and Beads safety into B12.
Impact:
- Keep B12 only with milestone receipts; otherwise split it.
### Pattern 4 - Local Durability Without Tamper/Atomic Contracts Is Not Enough
Security sees audit/manifest tamper risk (`SEC-T13`, `SEC-T16`). Idempotency
sees incomplete atomic write and append contracts (`IDM-C06`, `IDM-C14`).
Cross-cutting sees strict doctor and state continuity risks (`CC-C13`).
Impact:
- B01 must define mutation classes, hash chains, append locks, and recovery-phase doctor semantics before helpers mutate state.
### Pattern 5 - Active Work Is The Hard Boundary
Cross-cutting flags orphan side effects (`CC-C04`). Security flags active
dispatch snapshots and live-target restore (`SEC-T10`, `SEC-T11`). Idempotency
flags active generation and simultaneous restore (`IDM-C02`, `IDM-C03`).
Impact:
- "Pane exists" is not a safe readiness signal. Recovery must reason about active work, side effects, and drain/quiescence.
### Pattern 6 - ALPS Exposure Is Not Paranoia
Security names ALPS/client data (`SEC-T04`, `SEC-T12`). Cross-cutting names
protected approval (`CC-C11`). Idempotency names retention/snapshot storage
race (`IDM-C05`).
Impact:
- ALPS needs `sensitivity_class=client_protected`, redacted default, raw-retention approval, and callback field limits.
### Pattern 7 - Cross-Cutting Found What Single-Class Lenses Missed
Cross-cutting uniquely found manual rescue without orchestrator (`CC-C16`),
boot dependency DAG (`CC-C03`), and L61 boot-channel race (`CC-C12`).
Impact:
- Retain the audit order for v2 doctrine: specialist lenses are necessary, but cross-cutting trace replay should run before bead conversion.
### Pattern 8 - Existing Beads Can Absorb Most Fixes, But Not All
Most security/idempotency findings map to B01/B02/B04-B12. Cross-cutting has
three graph-shaping new beads (`CC-C03`, `CC-C11`, `CC-C16`).
Impact:
- Phase 4 can proceed only if those three overlays are accepted or explicitly folded into B01/B12 with no loss of acceptance clarity.
## 5. Plan Readiness Gauge - Combined
Combined readiness:
- RED for straight Phase 4 bead conversion.
- YELLOW for Phase 4 with explicit audit-overlay beads and Joshua decisions.
- GREEN only after r2 audit or Joshua-accepted overlay disposal.
Why RED for straight conversion:
- Cross-cutting already declared RED because five criticals affect graph shape and Joshua-disposes gates (`CC-C01`, `CC-C03`, `CC-C04`, `CC-C11`, `CC-C16`).
- Security says protected-client automation is promising but not bead-ready until restore authority, raw checkpoint policy, and plist preplant handling are explicit (`SEC-T01`, `SEC-T04`, `SEC-T06`).
- Idempotency says restore locks, watcher/snapshot locks, retention staging, and Beads DB read-only policy are required before mutating implementation (`IDM-C03`, `IDM-C04`, `IDM-C05`, `IDM-C15`).
Must address before any mutating implementation:
- Protected restore authorization and approval artifact: `CC-C11`, `SEC-T06`.
- Restore/session lock hierarchy: `IDM-C03`, `IDM-C10`.
- LaunchAgent preplant handling: `SEC-T01`.
- Protected checkpoint data policy: `SEC-T04`.
- Beads DB v1 inspect-only policy: `IDM-C15`.
Can become Phase 5 polish if explicitly beaded:
- First-boot operator UX: `CC-C15`.
- Project memory/CASS drift warnings: `CC-C07`, `CC-C08`.
- Monthly/quarterly drill cadence beyond initial readiness: `CC-C18`.
- Callback content length/redaction details: `SEC-T17`.
## 6. Recommended Next-Phase Plan
### Option A - Full r2 Plan Refinement
Shape:
- Reopen Phase 2.
- Incorporate every critical into `00-PLAN.md`.
- Run Phase 3 r2 audits.
- Convert beads only after two consecutive zero-critical rounds.
Estimated cost:
- 1-2 additional planning waves.
- Another 3 lens audits plus synthesis.
Risk profile:
- Lowest code-space risk.
- Highest schedule drag.
Time to Phase 5-ready:
- Slowest, but most likely to survive without bead churn.
Best when:
- Joshua wants strict v2 convergence and no audit-overlay exception.
### Option B - Targeted Bead Changes
Shape:
- Proceed to Phase 4.
- Add audit-overlay beads/acceptance criteria during decomposition.
- Treat all criticals as bead inputs.
Estimated cost:
- One decomposition wave plus larger B01/B12 acceptance.
Risk profile:
- Faster, but critical graph/approval decisions can be mis-modeled during bead creation.
Time to Phase 5-ready:
- Fastest if Joshua is available to dispose decisions early.
Best when:
- Joshua wants momentum and accepts overlay as equivalent to r2 plan convergence.
### Option C - Joshua-Disposes Split
Shape:
- Joshua disposes the graph/approval decisions first.
- Reopen plan-space only for B13/B14/B15 and protected-session policy.
- Convert all validator/lock/test findings into bead acceptance overlays.
Estimated cost:
- One short plan patch plus one decomposition wave.
Risk profile:
- Balanced. Prevents graph mistakes while preserving audit momentum.
Time to Phase 5-ready:
- Medium. Faster than full r2, safer than direct bead conversion.
Recommendation:
- Option C.
Why:
- The audits do not invalidate the recovery architecture. They do invalidate straight bead conversion without durable decisions for boot order, protected authority, rescue path, locks, and protected data policy.
## 7. Bead-DAG Impact Summary
### Original 12 Beads From Lane C / 00-PLAN
| Bead | Title | Status after audit |
|---|---|---|
| B01 | Recovery skill contract and helper surface | Keep; expand schema, auth, locks, idempotency, atomic write, path policy. |
| B02 | Preinstall audit and session path map | Keep; add protected classifier, substrate registry/binary verification, AM token/DB checks. |
| B03 | Repair session paths | Keep; add idempotent rerun and no-duplicate TOML acceptance. |
| B04 | Install plist for flywheel | Keep; add plist verifier/preplant policy. |
| B05 | Install plist for alpsinsurance | Keep; protected policy gate required before apply. |
| B06 | Install plist for clutterfreespaces | Keep; same verifier. |
| B07 | Install plist for picoz | Keep; safety-critical install only, no restore automation without approval. |
| B08 | Install plist for skillos | Keep; same verifier. |
| B09 | Install plist for vrtx | Keep; same verifier. |
| B10 | Install plist for zeststream-v2 | Keep; dashed-name quoting validation. |
| B11 | Install plist for zesttube | Keep; same verifier. |
| B12 | Baseline snapshot, nightly cron, restore harness | Keep only with four milestone receipts or split. |
### New Beads Required
#### B13 - Recovery Boot Dependency DAG
Acceptance:
- Emits `boot-plan.json` with nodes, dependencies, protection class, timeout, fallback command.
- Emits `boot_timeline.jsonl` during drill with timestamps and failure reasons.
- Proves Agent Mail/topology/session/watcher ordering before replay.
Sources:
- `CC-C01`, `CC-C03`, `IDM-C04`.
#### B14 - Recovery Approval Ledger
Acceptance:
- Writes/reads `recovery-approval.jsonl`.
- Protected apply requires actor, scope, expiry, protected sessions, reason, and command class.
- Refuses protected restore without matching receipt.
Sources:
- `CC-C11`, `SEC-T06`.
#### B15 - Standalone Rescue Card
Acceptance:
- Generates `~/.local/state/flywheel-recovery/RESCUE.md`.
- Lists commands to inspect manifests, validate latest checkpoint, dry-run flywheel restore, and open handoff.
- Works without slash-command expansion or live flywheel pane.
Sources:
- `CC-C16`, `SEC-T18`.
### Acceptance Changes To Existing Beads
B01:
- Add authorization envelope: `SEC-T06`, `CC-C11`.
- Add idempotency registry and conflict semantics: `IDM-C07`.
- Add lock hierarchy/owner schema: `IDM-C10`.
- Add atomic write matrix: `IDM-C06`.
- Add path/symlink/archive traversal policy: `SEC-T09`.
- Add audit/manifest hash chain: `SEC-T13`, `SEC-T16`.
- Add recovery-phase doctor classifications: `CC-C13`.
B02:
- Add protected-session sensitivity classifier: `SEC-T04`, `SEC-T12`.
- Add Agent Mail token/DB readiness conflict policy: `CC-C09`, `SEC-T14`.
- Add substrate registry path/hash verification: `CC-C10`.
- Add Beads DB inventory/WAL hash baseline: `IDM-C15`, `SEC-T15`.
B03:
- Prove rerun-stable TOML repair with no duplicate keys: `IDM-C01`.
- Block ambiguous session path source-of-truth mismatch: `CC-C17`.
B04-B11:
- Add plist owner/mode/label/ProgramArguments/hash verifier: `SEC-T01`, `SEC-T03`.
- Add preplant block/quarantine policy: `SEC-T01`.
- Add watcher restart-loop status/backoff: `IDM-C13`.
- Add per-session install idempotency and locks: `IDM-C01`, `IDM-C08`.
B12:
- Add snapshot quiescence and active-dispatch handling: `IDM-C02`, `SEC-T10`.
- Add restore lock and live-target force policy: `IDM-C03`, `SEC-T11`.
- Add staging/publish retention contract: `IDM-C05`.
- Add protected snapshot mode: `SEC-T04`.
- Add checkpoint target binding: `SEC-T05`.
- Add Beads DB inspect-only restore: `IDM-C15`, `SEC-T15`.
- Add schedule nudge contract and duplicate fire keys: `SEC-T07`, `IDM-C16`.
- Add JSONL append lock/fuckup-log safety: `IDM-C14`.
- Add test namespace and failure injection suite: `CC-C19`, `CC-C20`.
- Add drill ledger and recurring cadence: `CC-C18`.
### Cycle Check
Overlay DAG:
- B01 remains root.
- B02 depends on B01.
- B03 depends on B02.
- B04-B11 depend on B03.
- B13 depends on B01/B02 and precedes B12.
- B14 depends on B01 and precedes any protected B05/B07 apply plus B12 restore apply.
- B15 depends on B01/B02 and precedes B12 readiness.
- B12 depends on B04-B11 plus B13/B14/B15.
Cycle result:
- No cycles introduced.
- New beads only add forward dependencies into B12 or protected apply gates.
## 8. Convergence Test Result
v2 spec convergence rule:
- Phase 3 converges when two consecutive rounds produce zero findings.
Round 1 result:
- Findings raised: 54.
- Raw criticals: 12.
- Deduped criticals: 11.
- Readiness: RED for straight Phase 4 conversion.
Conclusion:
- v2 spec says Phase 3 r2 is required.
Exception path:
- Joshua may dispose Option B or Option C and accept the critical findings as bead inputs.
Explicit statement:
- Phase 3 r2 is required unless Joshua chooses Option B/C and accepts audit-overlay beads as the convergence short-circuit.
## 9. Audit-Phase Costs
Worker dispatches:
- 3 lens audits plus 1 synthesis = 4.
Worker time:
- Approximately 22 minutes parallel for the lens round, plus this synthesis pass.
Output volume:
- 1,315 lines of lens audit.
- This digest is the single decision artifact for Joshua.
Findings raised:
- 54 raw findings.
- Cross-cutting: 20.
- Security: 18.
- Idempotency: 16.
Net signal:
- 12 raw criticals.
- 11 deduped criticals.
- 6 multi-lens overlaps.
- 3 new overlay beads.
- 12 original beads need acceptance changes.
Value:
- The audits did not reject the architecture.
- They converted vague recovery reliability into concrete decision, lock, authorization, data, and test contracts.
## 10. References
Audit lens files:
- `03-AUDIT-r1-CROSSCUTTING.md`
  - `CC-C01` boot timeline.
  - `CC-C03` boot dependency DAG.
  - `CC-C04` orphan side-effect decision gate.
  - `CC-C11` durable Joshua/L48 approval.
  - `CC-C16` manual rescue without orchestrator.
  - `CC-C19` test isolation.
  - `CC-C20` failure injection.
- `03-AUDIT-r1-SECURITY.md`
  - `SEC-T01` plist preplant.
  - `SEC-T04` protected checkpoint secrets.
  - `SEC-T06` restore authorization.
  - `SEC-T07` schedule payload drift.
  - `SEC-T13` audit tamper evidence.
  - `SEC-T15` Beads DB poisoning.
  - `SEC-T18` PATH/helper hijack.
- `03-AUDIT-r1-IDEMPOTENCY.md`
  - `IDM-C03` simultaneous restore.
  - `IDM-C04` watcher during snapshot.
  - `IDM-C05` retention during snapshot write.
  - `IDM-C10` lock discipline.
  - `IDM-C15` Beads DB during restore.
  - `IDM-C16` schedule uniqueness.
Plan and lane files:
- `00-PLAN.md`
  - 12 Joshua decisions.
  - Lane A layer traceability table.
  - Lane B adoption traceability table.
  - 12-bead DAG.
  - Failure-mode coverage matrix.
- `01-RESEARCH-A.md`
  - 21 state layers.
  - 16 failure modes.
  - Recovery architecture recommendation.
- `01-RESEARCH-B.md`
  - Jeff patterns.
  - 48 audit findings.
  - 18 adoption recommendations.
- `01-RESEARCH-C.md`
  - CLI design.
  - 12-bead decomposition.
  - Execution caveat: design useful, validation status not clean.
## Validation Ladder
1. ALL critical findings deduplicated across 3 lenses:
   - PASS.
   - Raw criticals 12; deduped criticals 11.
2. >=8 Joshua decisions surfaced with 2-3 options each:
   - PASS.
   - 13 decisions surfaced.
3. >=5 cross-lens patterns identified:
   - PASS.
   - 8 patterns identified.
4. Combined readiness gauge with color and justification:
   - PASS.
   - RED for straight Phase 4; YELLOW for accepted overlay.
5. Option A/B/C recommendation with cost/risk for each:
   - PASS.
   - Recommendation is Option C.
6. Bead-DAG impact summary if Option B/C chosen:
   - PASS.
   - Original 12 beads, 3 new overlays, acceptance changes, and cycle check included.
7. Convergence-test honest answer:
   - PASS.
   - v2 spec requires Phase 3 r2 unless Joshua accepts Option B/C overlay.
8. NO fabrication; every claim cites lens:finding-id:
   - PASS.
   - Decision, critical, high, medium, and pattern claims cite lens finding IDs.
9. Read-only:
   - PASS.
   - Inputs were read; this synthesis file is the only written artifact.
10. `ladder_passed=yes` only if 1-9 clean:
    - PASS.
```text
ladder_passed=yes
decisions=13
criticals_dedup=11
readiness=red
recommendation=C
```
