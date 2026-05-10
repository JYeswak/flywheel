---
title: "/flywheel:recovery Lane B - Jeff Recovery Pattern Audit"
type: plan
created: 2026-05-04
frontmatter_source: scaffold-doc-frontmatter
---

## Contents

- [Executive Summary](#executive-summary)
- [Evidence Index](#evidence-index)
- [1. Inventory - Jeff Session Durability Surface](#1-inventory-jeff-session-durability-surface)
  - [1.1 NTM](#1-1-ntm)
  - [1.2 Cross-Agent Session Resumer (CASR)](#1-2-cross-agent-session-resumer-casr)
  - [1.3 MCP Agent Mail](#1-3-mcp-agent-mail)
  - [1.4 beads_rust / br](#1-4-beads-rust-br)
  - [1.5 FrankenSQLite](#1-5-frankensqlite)
  - [1.6 Asupersync](#1-6-asupersync)
  - [1.7 Agentic Coding Flywheel Setup (ACFS)](#1-7-agentic-coding-flywheel-setup-acfs)
  - [1.8 DCG](#1-8-dcg)
  - [1.9 vibe_cockpit as Observability Reference](#1-9-vibe-cockpit-as-observability-reference)
- [2. Cross-Pattern Synthesis](#2-cross-pattern-synthesis)
- [3. Convergence Audit Findings](#3-convergence-audit-findings)
  - [Lens 01 - Security](#lens-01-security)
  - [Lens 02 - Idempotency](#lens-02-idempotency)
  - [Lens 03 - Race Conditions](#lens-03-race-conditions)
  - [Lens 04 - Error Handling](#lens-04-error-handling)
  - [Lens 05 - Observability](#lens-05-observability)
  - [Lens 06 - Performance](#lens-06-performance)
  - [Lens 07 - Compliance / Data Exposure](#lens-07-compliance-data-exposure)
  - [Lens 08 - Cross-Platform](#lens-08-cross-platform)
  - [Lens 09 - Versioning](#lens-09-versioning)
  - [Lens 10 - Retention](#lens-10-retention)
  - [Lens 11 - Dry-Run Discipline](#lens-11-dry-run-discipline)
  - [Lens 12 - Audit Log](#lens-12-audit-log)
  - [Lens 13 - Rollback](#lens-13-rollback)
  - [Lens 14 - Naming Collisions](#lens-14-naming-collisions)
  - [Lens 15 - Disk Pressure](#lens-15-disk-pressure)
  - [Lens 16 - Jeff Alignment](#lens-16-jeff-alignment)
- [4. Gap Analysis - State Layers Jeff Does Not Solve](#4-gap-analysis-state-layers-jeff-does-not-solve)
- [5. Adoption Recommendations](#5-adoption-recommendations)
- [6. Open Upstream Issues Check](#6-open-upstream-issues-check)
- [7. Proposed Flywheel Recovery Shape](#7-proposed-flywheel-recovery-shape)
- [8. Conflicts to Flag Explicitly](#8-conflicts-to-flag-explicitly)
- [9. Validation Ladder](#9-validation-ladder)
- [10. Bottom-Line Recommendation](#10-bottom-line-recommendation)
# /flywheel:recovery Lane B - Jeff Recovery Pattern Audit

task_id: recovery_lane_b_jeff_patterns
date: 2026-05-01
mode: plan-space read-only research
worker: flywheel pane 3

## Executive Summary

This audit treats reboot recovery as an integration problem across Jeff Emanuel's local stack.

The strongest reusable primitives are already present:

1. NTM has checkpoint/save/restore/export surfaces with integrity checks and dry-run restore.
2. NTM also has a launchd watcher pattern, but the current watcher requires an existing tmux session.
3. CASR provides provider-session conversion, not archival durability.
4. Agent Mail uses launchd supervision and durable SQLite/git-backed state.
5. Beads uses project-local `.beads/` state, WAL sidecars, JSONL export, backups, and path allowlists.
6. FrankenSQLite and Asupersync encode strong durability and cancellation discipline, but are not direct reboot-recovery tools.
7. DCG gives a safety hook pattern for recovery scripts that might otherwise run destructive shell operations.

Current local reality checked read-only:

1. `ntm list --json` reports 8 active sessions: alpsinsurance, clutterfreespaces, flywheel, picoz, skillos, vrtx, zeststream-v2, zesttube.
2. `find ~/Library/LaunchAgents -name 'com.ntm.watcher.*.plist'` reports no NTM watcher plists.
3. `ntm checkpoint list flywheel --json` reports zero flywheel checkpoints.
4. Active session checkpoint counts are mixed: alpsinsurance=0, clutterfreespaces=1, flywheel=0, picoz=6, skillos=0, vrtx=10, zeststream-v2=10, zesttube=10.
5. Global historical checkpoint storage exists: `ntm checkpoint list --json` reports 37 historical checkpoint sessions.

The immediate design should therefore not assume "NTM cannot checkpoint".
It should assume "checkpoint/watcher coverage is not enforced for current hive sessions".

## Evidence Index

Read-only files and commands used:

1. `/tmp/dispatch_recovery_research_lane_b_jeff_patterns.md`
2. `/Users/josh/Developer/ntm/scripts/ntm-launchd.sh`
3. `/Users/josh/Developer/ntm/scripts/ntm-watcher.sh`
4. `/Users/josh/Developer/ntm/internal/checkpoint/restore.go`
5. `/Users/josh/Developer/ntm/internal/checkpoint/integrity.go`
6. `/Users/josh/Developer/ntm/internal/session/state.go`
7. `/Users/josh/Developer/ntm/internal/session/storage.go`
8. `/Users/josh/Developer/ntm/internal/cli/checkpoint.go`
9. `/Users/josh/Developer/ntm/README.md`
10. `/Users/josh/.claude/skills/cross-agent-session-resumer/SKILL.md`
11. `/Users/josh/.claude/skills/cross-agent-session-resumer/references/PROVIDERS.md`
12. `/Users/josh/.claude/skills/cross-agent-session-resumer/references/TROUBLESHOOTING.md`
13. `/Users/josh/Library/LaunchAgents/ai.zeststream.mcp-agent-mail-local.plist`
14. `/Users/josh/.local/share/mcp_agent_mail/CHANGELOG.md`
15. `/Users/josh/Developer/beads_rust/src/sync/history.rs`
16. `/Users/josh/Developer/beads_rust/src/sync/mod.rs`
17. `/Users/josh/Developer/beads_rust/src/sync/path.rs`
18. `/Users/josh/Developer/frankensqlite/README.md`
19. `/Users/josh/Developer/frankensqlite/CHANGELOG.md`
20. `/Users/josh/Developer/frankensqlite/supported_surface_matrix.toml`
21. `/Users/josh/Developer/frankensqlite/parity_taxonomy.toml`
22. `/Users/josh/Developer/asupersync/README.md`
23. `/Users/josh/.claude/skills/agentic-coding-flywheel-setup/SKILL.md`
24. `/Users/josh/.claude/skills/agentic-coding-flywheel-setup/references/DOCTRINE-RELAY-PROTOCOL.md`
25. `/Users/josh/Developer/destructive_command_guard/README.md`
26. `/Users/josh/.claude/skills/dcg/SKILL.md`
27. `/Users/josh/.claude/skills/dicklesworthstone-stack/references/DOCTRINE.md`
28. `/Users/josh/.claude/skills/dicklesworthstone-stack/references/INVENTORY.md`
29. `/Users/josh/Developer/vibe-cockpit/AGENTS.md`
30. `/Users/josh/Developer/vibe-cockpit/COMPREHENSIVE_PLAN_TO_MAKE_VC__GPT.md`
31. `/Users/josh/Developer/vibe-cockpit/COMPREHENSIVE_PLAN_TO_MAKE_VC__OPUS.md`
32. `ntm list --json`
33. `ntm checkpoint list flywheel --json`
34. `ntm checkpoint list --json`
35. `ntm checkpoint list <active-session> --json`
36. `find ~/Library/LaunchAgents -maxdepth 1 -name 'com.ntm.watcher.*.plist'`
37. `find ~/Developer -maxdepth 3 -name .beads -type d`
38. `gh search issues <term> --owner Dicklesworthstone --state open`
39. `git -C ~/Developer/ntm log -1 --format='%h %ci %s'`
40. `git -C ~/Developer/beads_rust log -1 --format='%h %ci %s'`
41. `git -C ~/Developer/frankensqlite log -1 --format='%h %ci %s'`
42. `git -C ~/Developer/asupersync log -1 --format='%h %ci %s'`
43. `git -C ~/Developer/destructive_command_guard log -1 --format='%h %ci %s'`
44. `git -C ~/.local/share/mcp_agent_mail log -1 --format='%h %ci %s'`

No Socraticode calls were made.
No Agent Mail tools were called.
No source repo files were modified.
Only this `/tmp` report was written.

## 1. Inventory - Jeff Session Durability Surface

### 1.1 NTM

Audited paths:

1. `/Users/josh/Developer/ntm/scripts/ntm-launchd.sh`
2. `/Users/josh/Developer/ntm/scripts/ntm-watcher.sh`
3. `/Users/josh/Developer/ntm/internal/checkpoint/restore.go`
4. `/Users/josh/Developer/ntm/internal/checkpoint/integrity.go`
5. `/Users/josh/Developer/ntm/internal/session/state.go`
6. `/Users/josh/Developer/ntm/internal/session/storage.go`
7. `/Users/josh/Developer/ntm/internal/cli/checkpoint.go`
8. `/Users/josh/Developer/ntm/README.md`

Commands enumerated:

1. `ntm list --json`
2. `ntm checkpoint list flywheel --json`
3. `ntm checkpoint list --json`
4. `ntm checkpoint list <session> --json`
5. `rg -n "checkpoint|respawn|adopt|bind|save|restore|launchd|watcher" ~/Developer/ntm`

Observed behavior:

1. Boot trigger: `scripts/ntm-launchd.sh` creates user LaunchAgents under `~/Library/LaunchAgents`.
2. Runtime trigger: generated plists run `scripts/ntm-watcher.sh <session>`.
3. Watcher runtime: `ntm-watcher.sh` runs `ntm assign "$SESSION" --auto --strategy=dependency --watch`.
4. Watcher singleton: `ntm-watcher.sh` uses a lock file under `~/.local/state/ntm/watcher-$SESSION.lock`.
5. Watcher boot assumption: if the tmux session does not exist, `ntm-watcher.sh` exits 0 so launchd does not restart it.
6. Current watcher install workflow uses `launchctl load` and `launchctl unload`.
7. Checkpoint restore supports `DryRun`, `Force`, `SkipGitCheck`, `InjectContext`, custom directory, and scrollback line limits.
8. Checkpoint restore refuses if the target session exists unless force is set.
9. Checkpoint restore warns on git branch or commit mismatch.
10. Checkpoint restore can inject scrollback context back into restored panes.
11. Checkpoint integrity verifies schema, required files, pane consistency, and optional checksums.
12. Saved sessions include workdir, git branch/remote/commit, pane details, layout, and agent command snapshot.
13. Saved sessions write to `~/.ntm/sessions` via `util.AtomicWriteFile`.
14. Saved-session writes log `session.save` start and finish audit events.
15. README documents checkpoint storage under `~/.local/share/ntm/checkpoints/`.
16. README documents checkpoint export with tar.gz/zip and `--redact-secrets`.
17. README documents privacy mode disabling prompt history, event logs, checkpoints, and scrollback.
18. README documents robot save/restore dry-run surfaces.

Implicit assumptions:

1. The terminal multiplexer session exists before watcher supervision can continue.
2. The session name is stable across reboot.
3. The project working directory still exists at restore time.
4. Git branch and commit mismatch are warnings unless caller enforces policy.
5. Agent CLI command names remain valid between checkpoint and restore.
6. Pane layout strings remain accepted by the installed terminal multiplexer version.
7. Scrollback injection is an acceptable substitute for native agent conversation resurrection.
8. LaunchAgent labels derived from session names do not collide.
9. Logs under `/tmp` are acceptable for watcher debugging.
10. `launchctl load/unload` remains acceptable unless local doctrine modernizes to bootstrap/kickstart/bootout.

Gaps not filled by NTM:

1. NTM does not make watcher plists mandatory for all active sessions.
2. NTM watcher supervision does not recreate missing sessions from checkpoint by itself.
3. NTM does not coordinate restore order across multiple sessions.
4. NTM does not decide which panes are protected from drills or destructive restore.
5. NTM does not persist Claude/Codex native transcript state beyond scrollback.
6. NTM does not pair checkpoint restore with Agent Mail replay ordering.
7. NTM does not provide fleet-level coverage invariants such as "every active session has current checkpoint < N hours".
8. NTM launchd script currently uses legacy launchctl verbs.

Adoption posture:

1. `ntm checkpoint save/list/show/restore/export`: EXTEND.
2. `ntm sessions save/restore`: EXTEND.
3. `ntm respawn/adopt/bind`: ADOPT as operator verbs, wrap in receipts.
4. `ntm-launchd.sh`: EXTEND, not as-is, because install verbs and missing-session behavior need flywheel policy.

### 1.2 Cross-Agent Session Resumer (CASR)

Audited paths:

1. `/Users/josh/.claude/skills/cross-agent-session-resumer/SKILL.md`
2. `/Users/josh/.claude/skills/cross-agent-session-resumer/references/PROVIDERS.md`
3. `/Users/josh/.claude/skills/cross-agent-session-resumer/references/TROUBLESHOOTING.md`

Commands enumerated:

1. `casr providers`
2. `casr list --limit 5`
3. `casr info SESSION_ID --verbose`
4. `casr -cc SESSION_ID`
5. `casr -cod SESSION_ID`
6. `casr -gmi SESSION_ID`

Observed behavior:

1. CASR reads provider-native sessions into a canonical intermediate representation.
2. Claude Code sessions are JSONL under `~/.claude/projects/{project_hash}/`.
3. Codex sessions are JSON files under `~/.codex/sessions/`.
4. Gemini sessions are JSON files under `~/.gemini/sessions/`.
5. Canonical IR includes metadata, messages, tool calls/results, and working context.
6. CASR verifies converted sessions by message count, turn alternation, tool pair integrity, and content similarity.
7. CASR explicitly treats conversion as one-way snapshot creation.
8. CASR explicitly warns against converting mid-tool-call.
9. CASR explicitly says "Using casr for backup instead of conversion" is an anti-pattern.
10. CASR troubleshooting says provider sessions are machine-local.

Implicit assumptions:

1. Provider session files are readable and not pruned.
2. Provider storage paths have not changed.
3. Target provider is installed and authenticated.
4. Conversion losses are acceptable for continuation.
5. Session ID can be captured before the source agent exits.
6. Working directory must be restored separately by the operator.

Gaps not filled by CASR:

1. CASR does not supervise sessions at boot.
2. CASR does not archive current terminal pane layout.
3. CASR does not preserve sandbox state across providers.
4. CASR does not own retention policy.
5. CASR does not coordinate multi-session restore.
6. CASR does not replace NTM checkpoint scrollback capture.

Adoption posture:

1. CASR provider discovery: ADOPT.
2. CASR conversion for rate-limit/crash recovery: ADOPT.
3. CASR as reboot backup: AVOID.
4. CASR metadata in flywheel checkpoints: EXTEND.

### 1.3 MCP Agent Mail

Audited paths:

1. `/Users/josh/Library/LaunchAgents/ai.zeststream.mcp-agent-mail-local.plist`
2. `/Users/josh/.local/share/mcp_agent_mail/CHANGELOG.md`
3. `/Users/josh/.local/share/mcp_agent_mail` git HEAD `b1ad7bf 2026-04-28`

Commands enumerated:

1. `plutil -p ~/Library/LaunchAgents/ai.zeststream.mcp-agent-mail-local.plist`
2. `git -C ~/.local/share/mcp_agent_mail log -1 --format='%h %ci %s'`
3. `rg -n "FD|EMFILE|backup|SQLite|identity|window|archive|lock" ~/.local/share/mcp_agent_mail/CHANGELOG.md`

Observed behavior:

1. Agent Mail launchd plist uses label `ai.zeststream.mcp-agent-mail-local`.
2. It uses `RunAtLoad=true`.
3. It uses `KeepAlive=true`.
4. It runs from working directory `~/.local/share/mcp_agent_mail`.
5. It starts the HTTP server through `uv run python -m mcp_agent_mail.cli serve-http`.
6. It explicitly unsets ambient database environment variables in ProgramArguments.
7. stdout and stderr go to `~/.local/state/agent-mail`.
8. Changelog documents persistent window-based agent identity.
9. Changelog documents canonical per-pane identity file contract.
10. Changelog documents sender identity verification.
11. Changelog documents commit queue/archive locking for multi-agent concurrency.
12. Changelog documents FD health monitor and EMFILE recovery.
13. Changelog documents backup path resolution via expanduser/resolve.
14. Changelog documents disaster recovery backup/restore verification.
15. Changelog documents SQLite pool tuning and NullPool for FD prevention.

Implicit assumptions:

1. LaunchAgent starts before agents try to fetch inbox.
2. Mail DB and archive paths survive reboot.
3. Registration tokens survive compaction or are available in a vault.
4. Pane identity files survive terminal recreation.
5. Single local service is enough for all sessions on the Mac.
6. HTTP server health is a proxy for durable message availability.

Gaps not filled by Agent Mail:

1. Agent Mail does not know NTM session topology unless flywheel registers it.
2. Agent Mail does not poke panes; it is durable, not necessarily immediate.
3. Agent Mail does not decide restore ordering after reboot.
4. Agent Mail does not guarantee all sessions have registered identities.
5. Agent Mail does not checkpoint terminal process state.
6. Agent Mail launchd plist does not by itself verify inbox-drain after reboot.

Adoption posture:

1. LaunchAgent service pattern: ADOPT.
2. Per-pane identity concept: ADOPT.
3. Commit queue/archive locking: ADOPT.
4. Fleet recovery message queue: EXTEND with L61 immediate poke and boot replay.

### 1.4 beads_rust / br

Audited paths:

1. `/Users/josh/Developer/beads_rust/src/sync/history.rs`
2. `/Users/josh/Developer/beads_rust/src/sync/mod.rs`
3. `/Users/josh/Developer/beads_rust/src/sync/path.rs`
4. `/Users/josh/Developer/beads_rust` git HEAD `1a72cb425 2026-04-30`

Commands enumerated:

1. `git -C ~/Developer/beads_rust log -1 --format='%h %ci %s'`
2. `rg -n "backup|Atomic|WAL|jsonl|allowlist|sync" ~/Developer/beads_rust/src/sync`
3. `find ~/Developer -maxdepth 3 -name .beads -type d`

Observed behavior:

1. Beads uses per-repo `.beads/` directories.
2. Local filesystem check found 56 `.beads/` directories under `~/Developer`.
3. Sync allowlist explicitly permits `.beads/*.db`.
4. Sync allowlist explicitly permits `.beads/*.db-wal`.
5. Sync allowlist explicitly permits `.beads/*.db-shm`.
6. Sync allowlist explicitly permits `.beads/*.jsonl`.
7. Sync allowlist explicitly permits `.beads/*.jsonl.tmp`.
8. Sync path validation rejects `.git` paths.
9. JSONL export backs up prior JSONL into `.br_history`.
10. History backup deduplicates identical backups.
11. History backup rotates by count and age.
12. Export refuses empty DB over non-empty JSONL unless forced.
13. Export refuses stale DB that would lose issues unless forced.
14. Export writes to temp file before rename.
15. Export sorts IDs deterministically.
16. Export includes tombstones for sync propagation.

Implicit assumptions:

1. Per-project `.beads/` is the durable source of issue truth.
2. SQLite/WAL sidecars are preserved with the repo state.
3. JSONL export is the human/audit sync layer, not the only DB state.
4. History backup retention defaults fit most projects.
5. Path allowlists prevent recovery scripts from touching unrelated files.

Gaps not filled by beads:

1. Beads does not checkpoint terminal or agent sessions.
2. Beads does not say which NTM session owns a repo on boot.
3. Beads does not classify protected sessions for restore drills.
4. Beads does not enforce launchd watcher presence.
5. Beads does not coordinate across multiple repos after reboot.

Adoption posture:

1. `.beads/` project-local state: ADOPT.
2. WAL sidecar preservation: ADOPT.
3. JSONL export + history backup: ADOPT.
4. Path allowlist model: ADOPT for recovery write surfaces.

### 1.5 FrankenSQLite

Audited paths:

1. `/Users/josh/Developer/frankensqlite/README.md`
2. `/Users/josh/Developer/frankensqlite/CHANGELOG.md`
3. `/Users/josh/Developer/frankensqlite/supported_surface_matrix.toml`
4. `/Users/josh/Developer/frankensqlite/parity_taxonomy.toml`
5. `/Users/josh/Developer/frankensqlite` git HEAD `5eabd23e 2026-04-29`

Commands enumerated:

1. `rg -n "WAL|checkpoint|durability|fsync|RaptorQ|recovery|corrupt" ~/Developer/frankensqlite`
2. `git -C ~/Developer/frankensqlite log -1 --format='%h %ci %s'`

Observed behavior:

1. Supported surface matrix declares WAL crash recovery and checkpoint behavior as durability contract.
2. README emphasizes WAL crash recovery, atomic commit, and durability barriers.
3. README describes self-healing via RaptorQ repair symbols for torn writes and bit-flips.
4. README describes standard SQLite `.db` plus rollback-journal/WAL compatibility for stable runtime.
5. README describes WAL replay and WAL index rebuild on database open.
6. README describes hot journal recovery.
7. README describes two fsync barriers for native-mode commit marker safety.
8. Changelog documents adaptive checkpoint scheduling.
9. Changelog documents WAL checkpoint integration.
10. Changelog documents crash-loop replay determinism tests.
11. Parity taxonomy says multi-process corruption is still an open area in related issue #70.
12. README says native mode is not yet a mature public runtime toggle.

Implicit assumptions:

1. Stable production use should stay on compatibility runtime unless adopting experimental native features.
2. Durable DB design requires explicit crash model.
3. Recovery correctness needs tests that inject torn writes and replay.
4. WAL alone is not enough when multi-process semantics are undefined.

Gaps not filled by FrankenSQLite:

1. It does not restore terminal sessions.
2. It does not manage launchd.
3. It does not know Agent Mail topology.
4. It is not yet a direct replacement for existing flywheel SQLite stores.
5. Multi-process behavior is explicitly still a risk surface.

Adoption posture:

1. Crash-model language: ADOPT.
2. WAL repair ideas: EXTEND later, not for first recovery release.
3. Direct FrankenSQLite dependency for `/flywheel:recovery` v1: AVOID.
4. Durability matrix testing pattern: ADOPT.

### 1.6 Asupersync

Audited paths:

1. `/Users/josh/Developer/asupersync/README.md`
2. `/Users/josh/Developer/asupersync` git HEAD `a2e097b8 2026-03-09`

Commands enumerated:

1. `rg -n "checkpoint|cancel|quiescence|snapshot|integrity|RaptorQ|replay" ~/Developer/asupersync/README.md`
2. `git -C ~/Developer/asupersync log -1 --format='%h %ci %s'`

Observed behavior:

1. Asupersync uses explicit capability contexts for async operations.
2. Tasks are owned by regions and close to quiescence.
3. Cancellation is a protocol with checkpoints, bounded drain, and finalizers.
4. Readme examples show `cx.checkpoint()` in work loops.
5. It uses reserve/commit for cancellation-sensitive sends.
6. Runtime state is sharded with canonical lock acquisition order.
7. Restorable snapshots include deterministic content hashes and structural validation.
8. Tests can emit deterministic artifact bundles.
9. RaptorQ supports distributed snapshot distribution concepts.
10. Runtime leak responses can panic, log, recover, or stay silent based on config.

Implicit assumptions:

1. The application is written inside Asupersync.
2. Recovery semantics are modeled in code, not shell after the fact.
3. Checkpoints are cooperative in long-running tasks.
4. Deterministic replay is a lab/runtime feature, not a terminal multiplexer feature.

Gaps not filled by Asupersync:

1. Current NTM sessions are external processes, not Asupersync tasks.
2. It does not persist agent CLI native transcripts.
3. It does not manage macOS LaunchAgents.
4. It does not replace NTM checkpointing.
5. It does not tell flywheel which session to restore first.

Adoption posture:

1. Quiescence-before-checkpoint principle: ADOPT.
2. Cooperative checkpoint concept: EXTEND into worker protocol.
3. Direct runtime rewrite: AVOID for recovery v1.
4. Deterministic drill artifact pattern: ADOPT.

### 1.7 Agentic Coding Flywheel Setup (ACFS)

Audited paths:

1. `/Users/josh/.claude/skills/agentic-coding-flywheel-setup/SKILL.md`
2. `/Users/josh/.claude/skills/agentic-coding-flywheel-setup/references/DOCTRINE-RELAY-PROTOCOL.md`
3. `/Users/josh/.claude/skills/dicklesworthstone-stack/references/DOCTRINE.md`
4. `/Users/josh/.claude/skills/dicklesworthstone-stack/references/INVENTORY.md`

Commands enumerated:

1. `rg -n "launchd|RunAtLoad|StartInterval|recovery|doctor|idempotent|resume" ~/.claude/skills/agentic-coding-flywheel-setup ~/.claude/skills/dicklesworthstone-stack`

Observed behavior:

1. ACFS is idempotent; interrupted installs resume from last completed phase.
2. ACFS uses `acfs doctor` as verification surface.
3. ACFS Phase 8 installs the Dicklesworthstone coordination stack.
4. ACFS doctrine relay says recovery procedures are not ready until drill evidence exists.
5. ACFS doctrine relay stores recovery drill evidence in `~/.local/state/flywheel/recovery-drill.jsonl`.
6. Dicklesworthstone doctrine reference gives a LaunchAgent example with `StartInterval`.
7. The doctrine reference still shows `launchctl load` in one example.
8. ACFS targets Ubuntu VPS, not macOS directly.

Implicit assumptions:

1. Installation is phase-based and idempotent.
2. Doctor probes must grow when integrations are adopted.
3. Recovery claims require drill evidence.
4. macOS-specific LaunchAgent wiring is local adaptation, not ACFS core.

Gaps not filled by ACFS:

1. It does not implement Mac Studio session restore.
2. It does not register current NTM sessions.
3. It does not define flywheel-specific protected-session policies.
4. It does not own launchd modernization for current Mac user agents.
5. It does not checkpoint live pane work.

Adoption posture:

1. Phase marker/idempotent installer model: ADOPT.
2. Doctor-first integration rule: ADOPT.
3. Drill evidence requirement: ADOPT.
4. ACFS installer itself for macOS recovery: AVOID.

### 1.8 DCG

Audited paths:

<!-- AGENT-ANCHOR: section-1 -->
1. `/Users/josh/Developer/destructive_command_guard/README.md`
2. `/Users/josh/.claude/skills/dcg/SKILL.md`
3. `/Users/josh/Developer/destructive_command_guard` git HEAD `b6aaa23 2026-02-01`

Commands enumerated:

1. `rg -n "install|hook|pre-commit|doctor|explain|allow-once|pack" ~/Developer/destructive_command_guard`
2. `dcg --version`

Observed behavior:

1. DCG is a high-performance hook for AI coding agents.
2. It blocks destructive commands before execution.
3. It supports `dcg doctor`.
4. It supports `dcg explain`.
5. It supports `dcg test`.
6. It supports modular security packs.
7. It supports pre-commit scanning through `dcg scan install-pre-commit`.
8. It can configure Claude Code and Gemini hooks.
9. README says Codex CLI lacks pre-execution hooks, so Codex protection should use git/pre-commit paths.
10. The skill doctrine says blocks are checkpoints, not errors.
11. The skill says use safe alternatives before override.
12. Allow-once codes are short-lived and bound to exact command+directory.

Implicit assumptions:

1. Destructive recovery commands should be previewable.
2. Human override is possible but must be explicit.
3. Recovery scripts should avoid shell bypasses.
4. Hooks differ by agent runtime.

Gaps not filled by DCG:

1. DCG does not decide recovery order.
2. DCG does not checkpoint sessions.
3. DCG does not guard all Codex shell commands before execution.
4. DCG does not classify NTM protected sessions.
5. DCG does not provide reboot restore itself.

Adoption posture:

1. `dcg explain/test` in recovery doctor: ADOPT.
2. `dcg scan` for recovery scripts: ADOPT.
3. Human allow-once for protected restore operations: EXTEND.
4. DCG as complete runtime safety boundary for Codex: AVOID.

### 1.9 vibe_cockpit as Observability Reference

Audited paths:

1. `/Users/josh/Developer/vibe-cockpit/AGENTS.md`
2. `/Users/josh/Developer/vibe-cockpit/COMPREHENSIVE_PLAN_TO_MAKE_VC__GPT.md`
3. `/Users/josh/Developer/vibe-cockpit/COMPREHENSIVE_PLAN_TO_MAKE_VC__OPUS.md`
4. `/Users/josh/Developer/vibe-cockpit` git HEAD `e0daa5c 2026-04-30`

Commands enumerated:

1. `rg -n "daemon|state|DuckDB|SQLite|snapshot|checkpoint|collector" ~/Developer/vibe-cockpit`

Observed behavior:

1. Vibe Cockpit is designed as a read-only observability collector over existing tools.
2. Plans prefer shelling out to JSON/robot modes before reading local caches/SQLite/JSONL directly.
3. Plans use DuckDB for append-only facts and snapshots.
4. Plans call for stale-data degradation instead of daemon crash.
5. Plans include mcp_agent_mail SQLite and beads collector concepts.
6. Plans include fleet state snapshots and machine state snapshots.
7. Current local work has an open issue that daemon collection is dark; do not rely on VC as recovery source now.

Implicit assumptions:

1. Observability should be read-only.
2. Collectors should fail soft and show stale data.
3. Robot-mode CLIs are preferred recovery/monitoring inputs.
4. DuckDB is an analytics store, not the source of recovery truth.

Gaps not filled by vibe_cockpit:

1. Current daemon issue blocks relying on it for recovery.
2. It does not restore NTM sessions.
3. It does not own LaunchAgent creation.
4. It does not checkpoint agent state.

Adoption posture:

1. Read-only collector posture: ADOPT.
2. Stale-data semantics: ADOPT.
3. DuckDB analytics as recovery source of truth: AVOID for v1.
4. VC current daemon as live recovery monitor: AVOID until issue #4 is resolved locally.

## 2. Cross-Pattern Synthesis

Pattern P01 - launchd as boot trigger.

Evidence:

1. NTM watcher install script writes LaunchAgents.
2. Agent Mail local server uses a LaunchAgent with RunAtLoad and KeepAlive.
3. Dicklesworthstone doctrine reference shows LaunchAgent examples.

Adopt:

1. Recovery should use one flywheel-owned LaunchAgent as the boot entrypoint.
2. Per-session watcher plists may still exist, but the brain-level recovery agent should verify the fleet.

Conflict:

1. NTM watcher exits 0 when the session is absent.
2. That means watcher plists alone cannot reconstruct sessions after reboot.

Pattern P02 - SQLite/WAL durable local state.

Evidence:

1. beads allows `.db`, `.db-wal`, `.db-shm`.
2. Agent Mail changelog emphasizes SQLite pool tuning and FD leak fixes.
3. FrankenSQLite centers WAL recovery and checkpoint behavior.

Adopt:

1. Recovery state ledger should use append-only JSONL for simple history and SQLite only if query volume requires it.
2. Any SQLite store must preserve WAL sidecars in backup/drill routines.

Conflict:

1. SQLite durability does not imply semantic checkpoint consistency during active writes.

Pattern P03 - project-local state.

Evidence:

1. `.beads/` appears in 56 local Developer repos.
2. NTM checkpoint stores session state under `~/.local/share/ntm/checkpoints`.
3. Agent Mail stores local service logs under `~/.local/state/agent-mail`.

Adopt:

1. Recovery should separate global flywheel state, per-session topology, and per-repo mission state.
2. Restores should never use global files as substitutes for repo-local `.flywheel/` context.

Conflict:

1. Cross-session recovery needs global order; repo-local files do not encode fleet priority.

Pattern P04 - append-only logs.

Evidence:

1. flywheel already uses JSONL topology and fuckup logs.
2. Agent Mail writes canonical mailbox/archive artifacts.
3. beads exports JSONL for durable audit/sync.

Adopt:

1. Recovery should write `recovery-drill.jsonl`, `recovery-snapshot.jsonl`, and `recovery-restore.jsonl`.
2. Each mutation should append an event before and after action.

Conflict:

1. Append-only logs can grow without retention policy.

Pattern P05 - atomic temp + rename.

Evidence:

1. NTM saved-session storage calls `util.AtomicWriteFile`.
2. beads export writes temp file then rename.
3. beads validates temp files stay in the `.beads/` directory.

Adopt:

1. Flywheel recovery snapshots should write `.tmp`, fsync where shell supports it, then rename.
2. Partial files should be ignored unless explicitly inspected by doctor.

Conflict:

1. Shell atomicity varies by filesystem and cross-device moves.

Pattern P06 - explicit dry-run.

Evidence:

1. NTM restore has `DryRun`.
2. NTM robot restore has dry-run.
3. DCG has `dcg test` and `dcg explain`.

Adopt:

1. Every recovery mutation must support `--dry-run`.
2. Doctor should run dry-run restore plans without touching sessions.

Conflict:

1. Dry-run can lie if it does not re-check immediately before execution.

Pattern P07 - human-readable handoff.

Evidence:

1. CASR skill relies on `casr info` and resume commands.
2. ACFS uses skills and troubleshooting docs as operational handoffs.
3. NTM checkpoint metadata includes descriptions.

Adopt:

1. Recovery snapshot should include machine-readable JSON and human-readable markdown summary.
2. Every restore plan should print an exact operator handoff.

Conflict:

1. Markdown summaries can drift from JSON truth.

Pattern P08 - provenance and version checks.

Evidence:

1. NTM checkpoint restore warns on git branch/commit mismatch.
2. CASR warns provider format drift can break resume.
3. FrankenSQLite versioning is explicit in support matrices and parity taxonomy.

Adopt:

1. Recovery snapshot must record CLI versions, git heads, and provider version strings.
2. Restore should classify mismatch as soft/hard based on session protection.

Conflict:

1. Strict version gating can block urgent recovery.

Pattern P09 - drill evidence before reliability claims.

Evidence:

1. ACFS doctrine relay says recovery procedures are not ready until drill evidence exists.
2. FrankenSQLite includes crash recovery scenarios.
3. NTM tests cover robot save/restore dry-run.

Adopt:

1. `/flywheel:recovery` readiness requires at least D1/D2/D3 drills.
2. Drill results belong in `~/.local/state/flywheel/recovery-drill.jsonl`.

Conflict:

1. Protected client sessions cannot be used for destructive drill classes.

Pattern P10 - safety hooks around dangerous action.

Evidence:

1. DCG blocks destructive commands before execution.
2. beads sync rejects `.git` paths.
3. Agent Mail hard delete requires explicit confirmation string.

Adopt:

1. Recovery scripts must have protected-session allowlists.
2. Restore/kill commands must require explicit force flags and logged reason.

Conflict:

1. Codex lacks pre-execution hooks, so shell scripts must self-gate.

## 3. Convergence Audit Findings

### Lens 01 - Security

F01 HIGH: LaunchAgent plist generation can become command injection if session names are interpolated without validation.
Mitigation: allow only `[A-Za-z0-9._-]` session names before writing plist.

F02 HIGH: Checkpoints can contain scrollback secrets.
Mitigation: default checkpoint export to redaction, and store non-redacted local archives mode 0600.

F03 MED: LaunchAgent ProgramArguments can inherit unexpected environment unless scrubbed.
Mitigation: copy Agent Mail's explicit env discipline and unset known DB/token variables.

### Lens 02 - Idempotency

F04 HIGH: Re-running install can fail if a plist exists but is stale.
Mitigation: use bootstrap/kickstart/bootout with PID verification, not load/unload.

F05 MED: Re-running snapshot can duplicate JSONL rows.
Mitigation: include idempotency key `<session>/<timestamp bucket>/<git commit>/<pane hash>`.

F06 MED: Restore can hit existing sessions.
Mitigation: default to dry-run; force requires protected-session policy decision.

### Lens 03 - Race Conditions

F07 HIGH: Snapshot during active worker output can capture half-written context.
Mitigation: ask panes for checkpoint receipt, then snapshot after bounded wait.

F08 HIGH: Agent Mail replay can race with NTM pane recreation.
Mitigation: restore topology first, then identities, then inbox replay.

F09 MED: LaunchAgent kickstart can overlap old process shutdown.
Mitigation: use lock files plus launchctl PID verification.

### Lens 04 - Error Handling

F10 HIGH: Partial install across 8 sessions can leave mixed recovery states.
Mitigation: ledger each session independently and print remediations.

F11 MED: Checkpoint save can succeed while scrollback capture fails.
Mitigation: classify checkpoint completeness and refuse "green" if required files missing.

F12 MED: Restore warnings can be ignored.
Mitigation: promote git mismatch warnings to soft violations in receipt.

### Lens 05 - Observability

F13 HIGH: No watcher plist is currently installed for active NTM sessions.
Mitigation: doctor invariant `active_session_count == watcher_plist_count` except excluded sessions.

F14 HIGH: Some current sessions have zero checkpoints.
Mitigation: doctor invariant `checkpoint_age_hours <= N`.

F15 MED: `/tmp` watcher logs vanish across reboot.
Mitigation: move recovery-critical logs to `~/.local/state/flywheel/recovery/`.

### Lens 06 - Performance

F16 MED: Full scrollback snapshots across 8 sessions can be large.
Mitigation: cap scrollback lines per pane and store full capture only on explicit deep checkpoint.

<!-- AGENT-ANCHOR: section-2 -->
F17 MED: `ntm checkpoint list --json` can emit huge payloads.
Mitigation: use per-session list for doctor, not global full dump.

F18 LOW: Running all restore dry-runs serially may be slow.
Mitigation: parallelize read-only validations, serialize mutations.

### Lens 07 - Compliance / Data Exposure

F19 HIGH: Client panes may contain ALPS/Blackfoot/TerraTitle sensitive context.
Mitigation: protected sessions require redaction and no export off host.

F20 HIGH: Agent native transcripts may contain tool outputs with secrets.
Mitigation: do not copy provider transcripts into shared checkpoint archives by default.

F21 MED: Callback logs may leak paths or project names.
Mitigation: keep public callbacks to artifact paths and counts.

### Lens 08 - Cross-Platform

F22 MED: Current boot trigger design is macOS launchd-specific.
Mitigation: isolate service manager adapter behind `recovery service install`.

F23 MED: tmux/launchd assumptions do not port to Linux systemd.
Mitigation: document v1 macOS-only and make Linux future explicit.

F24 LOW: fsync shell support differs.
Mitigation: use small helper binary or Python only if shell cannot fsync safely.

### Lens 09 - Versioning

F25 HIGH: Provider CLI updates can make CASR resume or NTM restore stale.
Mitigation: snapshot `claude`, `codex`, `gemini`, `ntm`, `br`, `am`, `dcg` versions.

F26 MED: NTM checkpoint schema has version constants.
Mitigation: recovery doctor must check checkpoint version before restore.

F27 MED: LaunchAgent scripts can drift from repo scripts.
Mitigation: plist stores script path and script hash in recovery ledger.

### Lens 10 - Retention

F28 MED: Historical checkpoint storage already has hundreds of files.
Mitigation: retention by active session and age, with protected-session exceptions.

F29 MED: Beads history defaults may not match recovery retention needs.
Mitigation: separate `.br_history` from flywheel session checkpoint retention.

F30 LOW: JSONL ledgers grow forever.
Mitigation: rotate summaries while preserving raw rows for 30-90 days.

### Lens 11 - Dry-Run Discipline

F31 HIGH: Restore without dry-run can kill an existing session with force.
Mitigation: require dry-run receipt ID before restore execution.

F32 MED: Plist install dry-run must show exact file path and label.
Mitigation: print planned plist XML hash and target domain.

F33 MED: Snapshot dry-run must estimate size.
Mitigation: sample pane scrollback length and expected checkpoint bytes.

### Lens 12 - Audit Log

F34 HIGH: Recovery actions must be reconstructable after compaction.
Mitigation: append before/after rows to `recovery-actions.jsonl`.

F35 MED: NTM has audit events for session save/load.
Mitigation: copy correlation IDs into flywheel recovery receipts.

F36 MED: Human override needs durable reason.
Mitigation: write override reason, actor, target session, and expiry.

### Lens 13 - Rollback

F37 HIGH: Bad restore can overwrite a living session if force is misused.
Mitigation: pre-restore checkpoint existing target when possible.

F38 MED: Plist modernization can break watcher autostart.
Mitigation: keep previous plist as `.bak` until doctor passes.

F39 MED: Agent Mail replay can duplicate messages.
Mitigation: store last handled message IDs per identity.

### Lens 14 - Naming Collisions

F40 MED: LaunchAgent labels derive from session names.
Mitigation: canonical label includes owner prefix and sanitized session.

F41 MED: NTM saved-session names can collide unless overwritten.
Mitigation: use timestamped checkpoint IDs, not human names, for automation.

F42 LOW: Agent identities can collide if generated locally.
Mitigation: server registration or token vault uniqueness check.

### Lens 15 - Disk Pressure

F43 MED: Scrollback gzip per pane across daily checkpoints can accumulate.
Mitigation: quota by session and global bytes.

F44 MED: WAL sidecars can keep growing if checkpoint/truncate never runs.
Mitigation: doctor reports WAL size for recovery-critical DBs.

F45 LOW: Old global checkpoint sessions obscure active coverage.
Mitigation: active-session dashboard separates historical and current state.

### Lens 16 - Jeff Alignment

F46 HIGH: Fighting NTM by rebuilding checkpoint logic would duplicate Jeff's surface.
Mitigation: call NTM primitives and wrap with policy.

F47 MED: Relying on VC now fights current issue #4.
Mitigation: use VC as future observability only after daemon collector regression is resolved.

F48 MED: CASR is not backup; using it as archive contradicts its own skill.
Mitigation: CASR is fallback conversion only.

## 4. Gap Analysis - State Layers Jeff Does Not Solve

G01: Claude Code transcript durability.
Why Jeff does not solve it: NTM captures scrollback; CASR converts provider sessions but is not a backup archive.
Flywheel primitive: `provider-transcript-index.jsonl` with session ID, path, mtime, size, provider, and last valid parse result.

G02: Codex transcript durability.
Why Jeff does not solve it: CASR knows Codex session paths but does not guarantee post-reboot availability or freshness.
Flywheel primitive: `codex-session-ledger.jsonl` keyed by pane identity and dispatch task.

G03: CASS cache atomicity during checkpoint.
Why Jeff does not solve it: CASS is a memory/search layer; NTM checkpoint does not pause or snapshot CASS internals.
Flywheel primitive: checkpoint hook that records CASS service health and last index timestamp.

G04: Multi-session restore ordering.
Why Jeff does not solve it: NTM restore is session-scoped.
Flywheel primitive: `recovery-boot-plan.json` with priority, dependencies, protected flag, and restore phase.

G05: Cross-session Agent Mail recovery ordering.
Why Jeff does not solve it: Agent Mail persists messages but does not know which NTM pane must wake first.
Flywheel primitive: boot replay queue that waits for topology + identity readiness before fetch/reply.

G06: Protected-session safety.
Why Jeff does not solve it: NTM force restore can kill existing sessions; protection is business/domain policy.
Flywheel primitive: `protected-sessions.json` with damage class gates and explicit override requirements.

G07: Watcher coverage enforcement.
Why Jeff does not solve it: NTM provides script, not fleet invariant.
Flywheel primitive: doctor probe `watcher_plist_coverage`.

G08: Checkpoint freshness enforcement.
Why Jeff does not solve it: NTM can list checkpoints; it does not decide acceptable age.
Flywheel primitive: doctor probe `checkpoint_freshness_by_session`.

G09: Native terminal multiplexer process loss.
Why Jeff does not solve it: NTM wraps the multiplexer; the multiplexer itself does not survive reboot.
Flywheel primitive: boot restore manager that creates sessions from checkpoints, then starts watchers.

G10: Agent process command drift.
Why Jeff does not solve it: NTM stores command snapshots but cannot guarantee future CLI compatibility.
Flywheel primitive: restore preflight version matrix and downgrade plan.

G11: Human-readable mission state.
Why Jeff does not solve it: NTM checkpoint is session/process oriented, not mission-doctrine oriented.
Flywheel primitive: snapshot `.flywheel/MISSION.md`, `GOAL.md`, `STATE.md`, and last tick receipt per repo.

G12: Recovery drill evidence.
Why Jeff does not solve it: ACFS doctrine requires drills but does not run Mac Studio drills.
Flywheel primitive: `kill-recover-drill.sh` plus `recovery-drill.jsonl`.

## 5. Adoption Recommendations

A01 NTM checkpoint save/list/show/restore/export: EXTEND.
Use Jeff's implementation; add flywheel policy, coverage doctor, redaction defaults, and restore ordering.

A02 NTM sessions save/restore: EXTEND.
Useful for coarse session state; checkpoint remains the richer pane/scrollback artifact.

A03 NTM launchd watcher: EXTEND.
Keep watcher idea; modernize launchctl verbs and add missing-session restore handoff.

A04 NTM respawn/adopt/bind: ADOPT.
Use as operator verbs during recovery; log each action.

A05 CASR canonical IR: ADOPT.
Use for provider conversion when an agent must continue in another CLI.

A06 CASR as backup: AVOID.
The skill explicitly says CASR is for resume/conversion, not archive.

A07 Agent Mail LaunchAgent pattern: ADOPT.
Run durable coordination service at boot.

A08 Agent Mail per-pane identity: ADOPT.
Required for addressable recovered panes.

A09 Agent Mail as immediate wake channel: EXTEND.
Pair with NTM poke per L61 because durable mail alone is not an interrupt.

A10 beads `.beads/` state model: ADOPT.
Repo-local issue graph remains source for work selection after reboot.

A11 beads JSONL backup/history: ADOPT.
Good model for recovery ledger rotation and restore preview.

A12 beads path allowlist: ADOPT.
Recovery scripts should use the same explicit file surface style.

A13 FrankenSQLite stable runtime: EVALUATE.
Good future DB substrate; not needed for v1.

A14 FrankenSQLite native/RaptorQ durability: AVOID for v1.
Powerful but not mature enough to become recovery dependency now.

A15 Asupersync quiescence/cancellation concepts: ADOPT.
Use as protocol inspiration: checkpoint only after bounded quiescence attempts.

A16 Asupersync runtime rewrite: AVOID.
Not relevant to shell/NTM recovery v1.

A17 ACFS doctor/idempotent phase pattern: ADOPT.
Recovery installer should be phase-marked, resumable, and doctor-visible.

A18 DCG safety guard pattern: ADOPT.
Recovery scripts should self-check dangerous commands and expose dry-run/explain.

## 6. Open Upstream Issues Check

Command family:

`gh search issues <term> --owner Dicklesworthstone --state open --limit 20 --json repository,title,number,url,state,updatedAt`

Search terms:

1. reboot
2. persistence
3. checkpoint
4. durability
5. watcher
6. boot

Results:

1. `reboot`: no open issues returned.
2. `persistence`: `Dicklesworthstone/ntm#111` coordinator status ignores config.
3. `checkpoint`: `Dicklesworthstone/frankensqlite#81` loud-refusal unsupported multi-process configs.
4. `checkpoint`: `Dicklesworthstone/vibe_cockpit#4` daemon ticks without invoking collectors.
5. `checkpoint`: `Dicklesworthstone/frankensqlite#82` file-backed native-mode time travel.
6. `checkpoint`: `Dicklesworthstone/frankensqlite#70` multi-process concurrent access corrupts/stales DB.
7. `durability`: no open issues returned.
8. `watcher`: no open issues returned.
9. `boot`: no open issues returned.

Blocker assessment:

1. No open upstream issue blocks using NTM checkpoint primitives.
2. `ntm#111` matters for coordinator status correctness but not checkpoint restore.
3. `vibe_cockpit#4` blocks relying on VC daemon for recovery observability.
4. `frankensqlite#70/#81` argue against using FrankenSQLite for multi-process recovery v1.
5. No upstream issue appears to cover "NTM watcher plist exists but tmux session missing after reboot".
6. If flywheel finds that watcher behavior should restore from checkpoint on boot, file upstream rather than patching locally.

## 7. Proposed Flywheel Recovery Shape

Phase R0: inventory-only doctor.

1. List active NTM sessions.
2. List topology rows.
3. List watcher plists.
4. List checkpoint counts and newest checkpoint per active session.
5. List Agent Mail identities and token vault coverage.
6. List provider transcript candidate paths.
7. Emit `recovery-doctor.json`.

Phase R1: snapshot.

1. Ask each active pane for checkpoint receipt if responsive.
2. Save NTM checkpoint per session.
3. Save repo-local `.flywheel` mission files.
4. Save active provider transcript path metadata.
5. Save Agent Mail identity/token mapping metadata without copying token contents.
6. Save topology row snapshot.
7. Write temp snapshot manifest, then rename.

Phase R2: launchd install.

1. Install one flywheel recovery boot LaunchAgent.
2. Optionally install per-session NTM watcher plists after sessions exist.
3. Use bootstrap/kickstart/bootout.
4. Verify PID or scheduled-state after install.
5. Ledger every install action.

Phase R3: boot restore.

1. Start Agent Mail service first.
2. Read latest boot plan.
3. Restore flywheel session before worker sessions.
4. Restore protected sessions only in dry-run unless explicit override exists.
5. Start per-session watchers after session restore.
6. Replay inbox checks only after pane identity lookup succeeds.
7. Emit final boot receipt.

Phase R4: drills.

1. D1 drill: no-op/dry-run restore.
2. D2 drill: kill non-protected scratch session and restore.
3. D3 drill: simulate missing session plus stale Agent Mail ordering.
4. Protected sessions are excluded unless human grants explicit drill window.
5. Drill rows go to `~/.local/state/flywheel/recovery-drill.jsonl`.

## 8. Conflicts to Flag Explicitly

C01: NTM watcher wants an existing session; reboot removes sessions.
Resolution: flywheel boot agent must restore sessions before or alongside watcher activation.

C02: CASR can convert provider sessions; it is not a backup archive.
Resolution: snapshot provider transcript metadata separately.

C03: Agent Mail is durable; it is not a pane interrupt.
Resolution: pair durable mail with NTM poke where live panes exist; after reboot, replay after identity restoration.

C04: SQLite/WAL survives crashes; logical multi-writer consistency can still fail.
Resolution: quiescence attempt plus post-checkpoint validation.

C05: launchd keeps services alive; bad plists can keep bad loops alive too.
Resolution: doctor + bootout + rollback path.

C06: Global checkpoint history exists; active-session freshness is still missing.
Resolution: doctor reports active coverage, not just global count.

C07: Protected sessions need safety; recovery wants automation.
Resolution: classify sessions and require explicit override for destructive protected drills.

C08: `/tmp` logs are convenient; reboot loses them.
Resolution: use `~/.local/state/flywheel/recovery`.

C09: Markdown handoff is readable; JSON is authoritative.
Resolution: write both from one manifest.

C10: Flywheel wants fleet health; repo-local `.beads` wants local source of truth.
Resolution: boot plan reads both global topology and repo-local beads.

## 9. Validation Ladder

1. >=6 Jeff repos audited: yes.
2. Repos/surfaces audited: ntm, cross_agent_session_resumer, mcp_agent_mail, beads_rust, frankensqlite, asupersync, agentic_coding_flywheel_setup, destructive_command_guard, vibe_cockpit.
3. >=10 audit lenses applied with >=3 findings each: yes.
4. Audit lenses applied: 16.
5. Findings counted: 48.
6. >=5 gaps with proposed primitive: yes.
7. Gaps counted: 12.
8. Adoption recommendation made for each Jeff primitive: yes.
9. Adoption calls counted: 18.
10. Open upstream issues cross-referenced: yes.
11. Common patterns identified: 10.
12. No fabrication: Jeff-behavior claims cite local paths or commands in Evidence Index.
13. Read-only: yes, except required `/tmp` report creation.
14. No Socraticode: yes.
15. No Agent Mail MCP tools: yes.
16. Conflicts explicitly flagged: yes.

ladder_passed=yes

## 10. Bottom-Line Recommendation

Build `/flywheel:recovery` as a thin policy layer over Jeff primitives.

Do not reimplement NTM checkpointing.
Do not use CASR as archive.
Do not rely on vibe_cockpit daemon until the collector regression is fixed.
Do not make FrankenSQLite a dependency for v1.

The first production-worthy recovery substrate is:

1. NTM checkpoints for sessions.
2. Flywheel topology/mission snapshots for orchestration.
3. Agent Mail identity/token vault checks for messaging.
4. Launchd boot trigger with modern verbs.
5. Recovery doctor invariants.
6. Drill evidence before reliability claims.
