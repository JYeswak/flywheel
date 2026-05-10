---
title: "/flywheel:recovery Phase 3 Audit — Cross-Cutting Verification Lens"
type: plan
created: 2026-05-04
frontmatter_source: scaffold-doc-frontmatter
---

# /flywheel:recovery Phase 3 Audit — Cross-Cutting Verification Lens

Task: `recovery_audit_crosscutting`
Mode: plan-space, read-only audit
Audited plan: `00-PLAN.md`
Sister audits: `03-AUDIT-r1-SECURITY.md` and `03-AUDIT-r1-IDEMPOTENCY.md` were not present at audit time, so this report stands alone.

## Findings Count

- Concerns evaluated: 20
- Concerns with full fields: 20
- Critical: 5
- High: 8
- Medium: 7
- Low: 0
- New beads implied: 3 direct, 3 optional if B01/B12 cannot absorb safely
- Plan readiness for Phase 4 bead decomposition: RED
- Ladder passed: yes

## Critical Findings

1. C01 — Boot-to-live timeline is not encoded as a measurable state machine.
2. C03 — Cross-session boot dependency ordering is implied but not represented as a DAG.
3. C04 — Worker callback orphaning lacks an external-side-effect decision gate.
4. C11 — Joshua-disposes/L48 approval is not modeled as a durable recovery artifact.
5. C16 — Manual recovery path without a live orchestrator is underspecified.

## Concern Coverage Table

| Concern | Prompt concern(s) covered | Primary cross-cut |
|---|---|---|
| C01 | 1 | boot -> login -> live pane timeline |
| C02 | 2 | snapshot -> restore round-trip equivalence |
| C03 | 3 | cross-session boot ordering |
| C04 | 4 | callback orphaning and side effects |
| C05 | 5 | loop/tick continuity |
| C06 | 6 | restored cwd -> Beads DB |
| C07 | 7 | cwd canonicalization -> Claude memory |
| C08 | 8 | cwd canonicalization -> CASS cache |
| C09 | 9 | AM token vault -> AM DB identity |
| C10 | 10 | substrate registry -> installed binary reality |
| C11 | 11 | L48/L52 approval across automation |
| C12 | 12 | L61 dual-channel boot race |
| C13 | 13 | doctor strict-mode during recovery |
| C14 | 14 | shell hooks and readiness gates |
| C15 | 15 | first-boot operator UX |
| C16 | 16 | recovery without orchestrator |
| C17 | 17 | multi-pane invocation ambiguity |
| C18 | 18 | drill cadence |
| C19 | 19 | test environment isolation |
| C20 | 20 | failure injection |

## End-to-End Trace Replay

### Trace A — Planned reboot

1. Pre-reboot snapshot runs against all approved sessions.
2. Manifest records topology, protected policy, AM readiness, repo docs, dirty state, dispatch state, and pane resume pointers (`00-PLAN.md:L254-L318`, `L535-L543`).
3. Reboot kills live panes and agent processes.
4. LaunchAgents start after login.
5. Boot helper restores sessions and watchers latch.
6. Recovery verifies sessions, repo doctors, Beads integrity, AM readiness, and dispatch ledger (`L568-L579`).
7. Missing edge: exact boot state sequence with timeout and failure reason is not defined.

### Trace B — Unplanned reboot during worker task

1. Worker dispatch exists in a pane and possibly in `/tmp`.
2. Reboot kills in-progress generation.
3. Snapshot may be stale or absent for that task.
4. Restore rebuilds sessions from latest checkpoint.
5. Dispatch ledger classifies missing callback as orphan candidate (`00-PLAN.md:L695`, `L699`).
6. Missing edge: side-effect class is not recorded, so duplicate-risk redispatch is unresolved.

### Trace C — Agent Mail recovery ordering

1. AM DB/token files persist.
2. AM launchd service may start before or after NTM panes.
3. Recovery waits for topology and identity readiness before replay (`00-PLAN.md:L680-L682`).
4. L61 requires durable mail and immediate NTM poke pairing.
5. Missing edge: no queue tracks one channel succeeding while the other is unavailable.

### Trace D — Restored pane resumes repo work

1. Checkpoint restores pane layout and working directory.
2. The orchestrator or worker runs repo-local commands.
3. Beads DB and `.flywheel` docs are repo-local stores (`00-PLAN.md:L229-L230`, `L653`, `L705`).
4. Missing edge: plan does not compare restored cwd, git top-level, and `.beads` path before trusting `br`.

### Trace E — Context cache survival

1. Provider transcripts and project memory survive as files.
2. Recovery stores native transcript pointers and project memory coverage (`00-PLAN.md:L47`, `L666`).
3. Canonical path repair can change path-derived project hashes.
4. Missing edge: plan does not assert Claude memory and CASS project_sha remain stable across restored cwd resolution.

### Trace F — Drill proves release

1. Plan requires D1-D4 and seven nightly cycles before reliability claims (`00-PLAN.md:L576-L579`, `L857-L864`).
2. These prove initial implementation behavior.
3. Dependencies drift after release: NTM, provider CLIs, AM service, launchd, repo paths, topology.
4. Missing edge: recurring drill cadence and stale-drill blocking are not part of readiness.

## Findings

### C01 — Boot-to-live timeline is not encoded as a measurable state machine

- **Type:** flow
- **Severity:** CRITICAL
- **Detected because of:** Lane A and B both say watcher liveness is not resurrection; the plan acknowledges this at `00-PLAN.md:L45` and `00-PLAN.md:L134-L138`, but the final plan still describes boot recovery as phases rather than a timed state machine.
- **Current mitigation in 00-PLAN.md:** Boot readiness is named as a gap at `L164-L168`; Phase 5 requires a reboot-like bootstrap drill at `L574-L579`; risk register notes launchd PATH/permissions at `L730`.
- **Gap:** There is no exact sequence from power-on -> login -> LaunchAgents -> Agent Mail -> NTM session restore -> watcher latch -> flywheel pane 1 live -> Joshua attach. Without timestamps and per-edge timeout/error states, a launchd failure can be silent until Joshua notices.
- **Suggested fix:** Tighten B12 acceptance: "B12 emits `boot_timeline.jsonl` with ordered states, start/end timestamps, timeout, failure reason, and next manual command for every boot edge."
- **Owner:** B12 plus Joshua-disposes for timeout defaults.
- **Bead-DAG implication:** (b) tighten B12 acceptance, (c) phase ordering explicit, (d) Joshua gate for timeout policy.

### C02 — Snapshot/restore round-trip does not define equality criteria

- **Type:** flow
- **Severity:** HIGH
- **Detected because of:** The plan requires verified checkpoints and restore dry-runs, but not round-trip equivalence. Current checkpoint and restore coverage is at `00-PLAN.md:L46`, `L535-L543`, and `L568-L579`.
- **Current mitigation in 00-PLAN.md:** B12 must include baseline, retention, restore dry-run, and drill evidence at `L598`; failure-mode F2 ignores partial manifests at `L696`.
- **Gap:** "Restore dry-run passes" does not prove scrollback line counts, pane working directories, pane titles, active commands, and expected cold-start/resume semantics match the snapshot.
- **Suggested fix:** Add B12 acceptance: "For disposable drill session, snapshot -> restore round-trip compares pane count, cwd, title, command, scrollback hash/line count, git head, and native resume-pointer presence."
- **Owner:** B12.
- **Bead-DAG implication:** (b) tighten B12 acceptance.

### C03 — Cross-session boot ordering is implied but not represented as a DAG

- **Type:** flow
- **Severity:** CRITICAL
- **Detected because of:** The plan says Agent Mail readiness gates replay (`00-PLAN.md:L49`, `L680-L682`) and topology must be canonical before install/restore (`L50`), but no ordered dependency graph exists for bringing up eight sessions.
- **Current mitigation in 00-PLAN.md:** Architecture lists AM health, topology, restore, and post-doctor as components at `L213-L218`; B12 handles restore and dispatch reconciliation at `L568-L572`.
- **Gap:** The plan does not encode whether Agent Mail, flywheel, skillos, protected client sessions, fleet health, roster, and worker sessions have explicit boot predecessors. A session may restore before its mail identity or callback pane is authoritative.
- **Suggested fix:** Add a small new bead before B12: "recovery boot dependency DAG", producing `boot-plan.json` with nodes, dependencies, protection class, timeout, and fallback command.
- **Owner:** New bead or B01 if cap cannot expand.
- **Bead-DAG implication:** (a) new bead preferred, (b) B01/B12 acceptance if no new bead, (c) phase ordering.

### C04 — Worker callback orphaning lacks an external-side-effect decision gate

- **Type:** flow
- **Severity:** CRITICAL
- **Detected because of:** The plan handles orphan candidates, but cross-tracing dispatch -> reboot -> restore -> redispatch reveals the missing external side-effect branch. Current plan cites dispatch fragility at `00-PLAN.md:L48` and cross-lane gap Gx3 at `L146-L150`.
- **Current mitigation in 00-PLAN.md:** B12 includes dispatch/callback orphan reconciliation at `L571`; F1/F5/F16 acceptance requires orphan rows, idempotency keys, and callback pane source at `L695`, `L699`, and `L710`.
- **Gap:** Orphan classification does not distinguish pure plan-space work from tasks that may have already touched GitHub, launchd, checkpoints, npm globals, or client systems before reboot. Redispatch can duplicate external mutations.
- **Suggested fix:** Add dispatch ledger field `external_side_effect_class=none|local_file|repo_state|service_state|client_state|unknown`; B12 blocks redispatch unless class is `none` or explicit Joshua approval exists.
- **Owner:** B01 dispatch ledger schema and B12 reconcile.
- **Bead-DAG implication:** (b) tighten B01/B12 acceptance, (d) Joshua gate.

### C05 — Loop tick state continuity is only traced as stored files, not reactivation behavior

- **Type:** flow
- **Severity:** HIGH
- **Detected because of:** The plan protects loop state and tick receipts (`00-PLAN.md:L662-L663`) and says cron/tick delivery needs panes (`L53`, `L70-L74`), but does not define what happens when a loop was active before reboot.
- **Current mitigation in 00-PLAN.md:** Phase 4 has nightly JSONL and failure callback acceptance at `L545-L560`; Phase 5 runs post-restore doctor and dispatch reconciliation at `L568-L572`.
- **Gap:** If loop state says active=true pre-reboot, recovery does not define whether autoloop resumes immediately, waits for STATE.md verification, or pauses until Joshua confirms. This can either skip a tick or run stale logic.
- **Suggested fix:** Add B12 acceptance: "Recovery classifies each active loop as `resume_now|pause_stale_state|blocked_missing_pane`, with last_tick age and STATE.md strict-doctor result."
- **Owner:** B12.
- **Bead-DAG implication:** (b) tighten B12 acceptance.

### C06 — Beads DB path resolution is not checked against restored pane cwd

- **Type:** boundary
- **Severity:** HIGH
- **Detected because of:** The plan protects repo-local `.beads` state (`00-PLAN.md:L229-L230`, `L653`, `L705`) and repairs session paths, but cross-tracing restore -> pane cwd -> `br` access exposes a missing check.
- **Current mitigation in 00-PLAN.md:** Phase 1 resolves canonical paths at `L790-L796`; B03 protects stale path and wrong-repo restore at `L589`; F11 requires beads integrity status at `L705`.
- **Gap:** Beads integrity can pass for the wrong repo if cwd restoration lands in an adjacent checkout or symlink alias. Earlier `beads_db_health.leakage_count` regressions make this a real cross-boundary risk.
- **Suggested fix:** Add B12 verification: "For every restored pane with a repo, compare pane cwd, manifest `repo_path`, git top-level, and `.beads` DB path before any `br` command is trusted."
- **Owner:** B12.
- **Bead-DAG implication:** (b) tighten B12 acceptance.

### C07 — Project memory and Claude project-hash mapping can drift after cwd canonicalization

- **Type:** boundary
- **Severity:** MEDIUM
- **Detected because of:** The plan tracks project memory at `00-PLAN.md:L666` and native transcripts at `L47`, but does not link memory identity to canonical cwd.
- **Current mitigation in 00-PLAN.md:** B02/B12 protect project memory at `L666`; manifest tracks `repo_path` at `L270-L274`; Phase 1 resolves path authority at `L790-L796`.
- **Gap:** Claude memory directory names are path-derived. If restore starts from symlinked or newly canonicalized cwd, the agent may miss the existing memory directory and behave as a different project.
- **Suggested fix:** Add manifest field `project_memory_key` and B12 check: "restored cwd resolves to same project memory directory as latest pre-reboot handoff, or recovery injects a warning."
- **Owner:** B01 schema and B12 verify.
- **Bead-DAG implication:** (b) tighten B01/B12 acceptance.

### C08 — CASS cache project_sha drift is not tested

- **Type:** boundary
- **Severity:** MEDIUM
- **Detected because of:** The plan protects CASS cache at `00-PLAN.md:L652` and includes provider/native continuation tests at `L864`, but does not test cache key stability.
- **Current mitigation in 00-PLAN.md:** CASS cache is included in Lane A layer traceability at `L652`; recovery uses native transcript pointers at `L47`.
- **Gap:** `~/.cubcloud/mem/cache/context/<sha>.md` can become orphaned if the cwd canonical path changes. The plan validates restore mechanics, not whether the restored agent receives the same high-value context cache.
- **Suggested fix:** Add B12 acceptance: "snapshot records CASS project_sha and cache mtime; restore warns if resolved project_sha differs from snapshot."
- **Owner:** B12.
- **Bead-DAG implication:** (b) tighten B12 acceptance.

### C09 — Agent Mail token files and DB identity rows can diverge by epoch

- **Type:** boundary
- **Severity:** HIGH
- **Detected because of:** The plan gates replay on AM identity readiness (`00-PLAN.md:L49`, `L680-L682`, `L698`), but does not define precedence if token vault and SQLite identity rows disagree after restore.
- **Current mitigation in 00-PLAN.md:** Agent Mail service and identity readiness are included in manifest health and B12 acceptance at `L49`, `L680-L682`, and `L698`.
- **Gap:** Token files may be newer than the AM DB, or AM DB may contain identities whose token files are missing. A green service probe does not prove the receiver identity can fetch.
- **Suggested fix:** Add B02/B12 acceptance: "AM readiness includes token-file mtime, DB identity row existence, registration token match/validity probe, and conflict policy `db_wins|vault_wins|block`."
- **Owner:** B02 and B12; Joshua-disposes for conflict policy.
- **Bead-DAG implication:** (b) tighten B02/B12 acceptance, (d) Joshua gate.

### C10 — Substrate registry drift is not verified against installed binaries

- **Type:** boundary
- **Severity:** MEDIUM
- **Detected because of:** The plan protects substrate registry at `00-PLAN.md:L656` but only says doctor reads registry; it does not verify actual paths and shas after restore.
- **Current mitigation in 00-PLAN.md:** Layer traceability maps substrate registry to B02/B12 at `L656`; cross-references mention Jeff audit controls at `L871`.
- **Gap:** Ten tentacle entries can survive as JSON while binaries/scripts moved or changed. Recovery may report substrate-ready based on stale registry metadata.
- **Suggested fix:** Add B02 acceptance: "recovery status validates every registered substrate path exists and sha/version matches registry or marks `registry_drift` before restore readiness."
- **Owner:** B02.
- **Bead-DAG implication:** (b) tighten B02 acceptance.

### C11 — Joshua-disposes/L48 approval is not modeled as a durable recovery artifact

- **Type:** doctrine
- **Severity:** CRITICAL
- **Detected because of:** The plan says protected sessions need explicit policy (`00-PLAN.md:L240`, `L744-L746`) and decisions must not force mutation before protected-session policy is selected (`L830-L832`), but approval itself is not represented.
- **Current mitigation in 00-PLAN.md:** Protected sessions can be audited but restored only by explicit policy at `L240`; J2 chooses protected-session policy at `L742-L748`.
- **Gap:** Post-reboot automation may need to install plists, bootout/kickstart, restore sessions, or replay dispatches. The plan does not define where Joshua's signoff is stored, its scope, its expiry, or how L48 substrate-exhaustion applies during recovery.
- **Suggested fix:** Add `recovery-approval.jsonl` with `actor`, `scope`, `allowed_actions`, `expires_at`, `protected_sessions`, and `reason`; B12 refuses protected apply without matching approval row.
- **Owner:** New bead or B01 schema; Joshua-disposes.
- **Bead-DAG implication:** (a) new bead preferred, (b) B01/B12 acceptance, (d) Joshua gate.

### C12 — L61 dual-channel communication has a boot-time race

- **Type:** doctrine
- **Severity:** HIGH
- **Detected because of:** The plan combines durable AM with NTM callback/poke semantics (`00-PLAN.md:L48-L49`, `L680-L682`, `L699-L710`), but recovery starts when either AM or panes may be absent.
- **Current mitigation in 00-PLAN.md:** AM replay waits for topology and pane readiness at `L681`; callbacks use topology source and effective timestamp at `L710`.
- **Gap:** L61 says mail sends pair with NTM pokes. During recovery, NTM may exist before AM, or AM may exist before panes. The plan does not define whether to queue the missing half, retry, or downgrade.
- **Suggested fix:** Add B12 acceptance: "`dual_channel_queue.jsonl` records mail/poke pairs; recovery only marks communication delivered when both channels either succeed or have explicit degraded-mode reason."
- **Owner:** B12.
- **Bead-DAG implication:** (b) tighten B12 acceptance.

### C13 — Strict doctor during recovery can generate false failures

- **Type:** doctrine
- **Severity:** HIGH
- **Detected because of:** Phase 5 runs post-restore doctor suite (`00-PLAN.md:L570`) and F12 requires strict repo doctor at `L706`, but boot recovery passes through intentionally incomplete states.
- **Current mitigation in 00-PLAN.md:** Restore state machine blocks on missing prerequisites; boot-like drill is required at `L855`; strict repo doctor is in F12 acceptance at `L706`.
- **Gap:** Normal `flywheel-loop doctor --strict` may flag sessions absent during early boot, missing callbacks before replay, or AM unready before service start. The plan lacks a boot-time doctor mode that distinguishes expected transient recovery states from real regressions.
- **Suggested fix:** Add B01/B12 acceptance: "doctor supports `--recovery-phase=<phase>` and emits `transient_expected` versus `regression` classifications."
- **Owner:** B01 helper contract and B12 verify.
- **Bead-DAG implication:** (b) tighten B01/B12 acceptance.

### C14 — Shell hook dependencies are not part of recovery readiness

- **Type:** boundary
- **Severity:** MEDIUM
- **Detected because of:** The plan validates locked docs (`00-PLAN.md:L229`, `L706`) and failure-mode coverage (`L864`), but does not verify shell/session hooks load in restored panes.
- **Current mitigation in 00-PLAN.md:** F12 strict repo doctor covers STATE.md drift at `L706`; state docs are authoritative stores at `L229`.
- **Gap:** Flywheel readiness gates and other hooks can block or alter restored command behavior. A restored pane that has correct files but missing shell hooks may pass session restore and then fail first actual task.
- **Suggested fix:** Add B12 check: "restored pane runs hook-readiness probe in dry-run mode and records hook version/hash before declaring pane live."
- **Owner:** B12.
- **Bead-DAG implication:** (b) tighten B12 acceptance.

### C15 — First-boot operator UX is underspecified

- **Type:** ux
- **Severity:** MEDIUM
- **Detected because of:** The plan chooses JSON authoritative plus generated Markdown (`00-PLAN.md:L776-L780`) but does not define the first screen Joshua sees after boot.
- **Current mitigation in 00-PLAN.md:** Dry-run output format defaults to JSON authoritative with Markdown summary at `L776-L780`; operator summary is implied by recovery procedure and validation sections.
- **Gap:** A 6 AM recovery status must be glanceable: what is safe, what is blocked, what one command should run next. The plan has data fields but no required human output contract.
- **Suggested fix:** Add B01 acceptance: "`/flywheel:recovery status` prints a 10-line maximum human summary with RED/YELLOW/GREEN, blocked sessions, safest next command, and no stack traces unless `--verbose`."
- **Owner:** B01.
- **Bead-DAG implication:** (b) tighten B01 acceptance.

### C16 — Manual recovery path without a live orchestrator is underspecified

- **Type:** ux
- **Severity:** CRITICAL
- **Detected because of:** The plan assumes pane 1 receives resume packets and reconciliation occurs (`00-PLAN.md:L568-L572`), but cross-tracing the worst case has pane 1 dead and state JSON corrupt.
- **Current mitigation in 00-PLAN.md:** B12 restore harness and dispatch reconciliation are planned at `L568-L572`; boot helper environment risk is in `L730`.
- **Gap:** If flywheel pane 1 cannot start, Joshua needs a documented local command path that does not rely on a functioning orchestrator, slash command expansion, or latest manifest.
- **Suggested fix:** Add new bead: "standalone recovery rescue card" that writes `~/.local/state/flywheel-recovery/RESCUE.md` with exact commands to list manifests, verify latest checkpoint, restore flywheel dry-run, and open the latest handoff.
- **Owner:** New bead before B12, or B01 if no bead expansion allowed.
- **Bead-DAG implication:** (a) new bead, (b) B01/B12 acceptance, (d) Joshua gate for manual restore.

### C17 — Running recovery from a non-orchestrator pane has no command-context guard

- **Type:** ux
- **Severity:** MEDIUM
- **Detected because of:** Manifest has session fields (`00-PLAN.md:L270-L274`) and source-of-truth decision J8 at `L790-L796`, but the command can be invoked from any pane/cwd.
- **Current mitigation in 00-PLAN.md:** Recovery is fleet-scoped during planning and session-scoped during execution at `L239`; J8 says config is executable source with topology/roster validation at `L790-L796`.
- **Gap:** If Joshua runs `/flywheel:recovery snapshot` from a worker pane in a different repo, the command must know whether it is acting on that pane's session, all sessions, or the canonical flywheel session.
- **Suggested fix:** Add B01 acceptance: "Every mutating form prints resolved actor session, cwd, target session set, and source-of-truth rows; ambiguous invocation blocks."
- **Owner:** B01.
- **Bead-DAG implication:** (b) tighten B01 acceptance.

### C18 — Drill cadence ends after initial soak

- **Type:** coverage
- **Severity:** MEDIUM
- **Detected because of:** The plan requires D1-D4 drills and seven nightly cycles (`00-PLAN.md:L576-L579`, `L857-L864`), but not recurring post-launch drills.
- **Current mitigation in 00-PLAN.md:** D1-D4 are required before readiness at `L576-L579`; soak requires seven nightly cycles at `L857-L862`.
- **Gap:** Recovery rots as NTM, Claude/Codex, launchd, AM, and repo topology change. A one-time drill proves initial release, not ongoing survivability.
- **Suggested fix:** Add B12 acceptance: "drills.jsonl records monthly disposable-session drill and quarterly full dry-run; status reports drill age and blocks green if stale."
- **Owner:** B12.
- **Bead-DAG implication:** (b) tighten B12 acceptance.

### C19 — Test environment isolation is not strict enough

- **Type:** coverage
- **Severity:** HIGH
- **Detected because of:** The plan uses disposable session tests (`00-PLAN.md:L845-L848`, `L852-L855`, `L824-L828`), but does not require isolation of state roots, labels, or config writes.
- **Current mitigation in 00-PLAN.md:** Integration tests use disposable NTM session path audit, watcher install/uninstall, checkpoint, and restore dry-run at `L843-L848`; drill target recommends disposable session first at `L822-L828`.
- **Gap:** A "disposable" test can still touch global NTM config, LaunchAgents, checkpoint store, or session names that collide with production. The plan needs a test namespace contract.
- **Suggested fix:** Add B12 acceptance: "test mode uses `flywheel-recovery-test-*` session names, separate state dir, separate plist label prefix, and cleanup receipt proving no production sessions touched."
- **Owner:** B12.
- **Bead-DAG implication:** (b) tighten B12 acceptance.

### C20 — Failure injection coverage is too shallow for the stated failure modes

- **Type:** coverage
- **Severity:** HIGH
- **Detected because of:** The plan lists 16 failure modes and compact coverage (`00-PLAN.md:L693-L710`, `L864`) but only explicitly drills dry-run, kill/restore, interrupted snapshot, and boot-like sequence.
- **Current mitigation in 00-PLAN.md:** E2E tests include D1-D4 at `L850-L855`; failure-mode coverage line summarizes several tests at `L864`; disk pressure F10 has byte/quota acceptance at `L704`.
- **Gap:** There is no explicit failure injection for disk-full, kill -9 mid-snapshot process, corrupt checkpoint manifest, stale AM identity, stale callback pane, missing hook, or wrong cwd restore.
- **Suggested fix:** Add B12 acceptance: "failure-injection suite covers at least F2/F4/F6/F8/F10/F11/F12/F16 with disposable fixtures and records pass/fail in drills.jsonl."
- **Owner:** B12.
- **Bead-DAG implication:** (b) tighten B12 acceptance.

## Pattern: Lane-vs-Lane Gaps This Lens Caught

1. Lane A inventories state layers; Lane B inventories primitives; Lane C builds a CLI. Cross-tracing exposed missing *ordering* between layers, especially Agent Mail before replay and session restore before watcher latch.
2. Lane C's bead cap collapses snapshot, cron, restore, and drills into B12. Cross-tracing shows B12 needs internal milestone receipts or a few new beads; otherwise critical acceptance gets buried.
3. Lane B correctly says Agent Mail is durable but not an interrupt. Cross-tracing L61 at boot shows the inverse race too: NTM panes may exist while AM is not ready.
4. Lane A names path/topology drift; Lane B names Beads project-local state. Cross-tracing restored pane cwd to `.beads` access exposes wrong-repo `br` risk.
5. The plan treats protected sessions as a policy choice, but doctrine requires a durable approval substrate. Cross-tracing L48 with automated boot recovery turns "Joshua approval" into a data model requirement.

## Plan Readiness Gauge

**RED for Phase 4 bead decomposition.**

The architecture is directionally correct, and most findings can be addressed by tightening B01/B02/B12 acceptance. It is not ready for bead conversion until the five criticals are resolved because they affect graph shape and Joshua-disposes gates:

- C01 needs an executable boot timeline.
- C03 needs a boot dependency DAG.
- C04 needs side-effect-aware orphan policy.
- C11 needs durable approval rows.
- C16 needs manual rescue without a live orchestrator.

## Bead-DAG Implications

| Finding | New bead (a) | Tighten acceptance (b) | Phase ordering (c) | Joshua gate (d) |
|---|---:|---:|---:|---:|
| C01 | 0 | 1 | 1 | 1 |
| C02 | 0 | 1 | 0 | 0 |
| C03 | 1 | 1 | 1 | 0 |
| C04 | 0 | 1 | 0 | 1 |
| C05 | 0 | 1 | 0 | 0 |
| C06 | 0 | 1 | 0 | 0 |
| C07 | 0 | 1 | 0 | 0 |
| C08 | 0 | 1 | 0 | 0 |
| C09 | 0 | 1 | 0 | 1 |
| C10 | 0 | 1 | 0 | 0 |
| C11 | 1 | 1 | 0 | 1 |
| C12 | 0 | 1 | 0 | 0 |
| C13 | 0 | 1 | 1 | 0 |
| C14 | 0 | 1 | 0 | 0 |
| C15 | 0 | 1 | 0 | 0 |
| C16 | 1 | 1 | 1 | 1 |
| C17 | 0 | 1 | 0 | 0 |
| C18 | 0 | 1 | 0 | 0 |
| C19 | 0 | 1 | 0 | 0 |
| C20 | 0 | 1 | 0 | 0 |

Tally:

- (a) New bead needed: 3 direct, 3 optional if B01/B12 cannot absorb safely.
- (b) Existing bead acceptance must be tightened: 20.
- (c) Phase ordering must change or be made explicit: 4.
- (d) New Joshua-disposes gate: 5.

## Test Coverage Notes

- Drill cadence is insufficient after initial readiness. Add monthly disposable-session recovery drill and quarterly full dry-run age checks.
- Failure injection should be explicit, not implied by the failure-mode table. Minimum suite: interrupted checkpoint write, disk-full, stale session path, stale AM identity, stale callback pane, corrupt Beads DB, strict STATE.md drift, missing hook, and wrong cwd.
- Test isolation needs a namespace contract so disposable drills never touch production session names, LaunchAgent labels, or checkpoint directories.

## Validation Ladder

1. >=18 concerns evaluated, >=15 with all 7 fields filled: PASS, 20 evaluated and 20 full.
2. Critical-findings list present: PASS, 5 criticals.
3. Pattern-of-lane-vs-lane gaps surfaced: PASS.
4. Plan readiness gauge with explicit color: PASS, RED.
5. Bead-DAG implications tallied: PASS.
6. Test-coverage section addresses drill cadence and failure injection: PASS.
7. No fabrication: PASS, every concern cites `00-PLAN.md` line(s).
8. Read-only: PASS, no source or live substrate mutations; only this audit artifact was written.
9. Sister audit files referenced if existing at audit time: PASS, both absent and not relied on.
10. `ladder_passed`: yes.
