---
title: "/flywheel:recovery Lane A - State Inventory + Reboot Surface Mapping"
type: plan
created: 2026-05-04
frontmatter_source: scaffold-doc-frontmatter
---

# /flywheel:recovery Lane A - State Inventory + Reboot Surface Mapping

Task: `recovery_lane_a_state_inventory`
Scope: Round 1 plan-space research for `/flywheel:recovery`
Mode: read-only inspection only
Output: `/tmp/recovery_lane_a_state_inventory.md`

## Executive Summary

This lane answers one question: what state must survive a Mac Studio reboot for
Joshua's active NTM fleet to come back in a useful state?

Current fleet snapshot:

- Active NTM sessions: 8.
- Active panes: 32.
- Active sessions from `ntm list --json`: `alpsinsurance`, `clutterfreespaces`,
  `flywheel`, `picoz`, `skillos`, `vrtx`, `zeststream-v2`, `zesttube`.
- Session watcher plists installed: 0 exact `com.ntm.watcher.*.plist`.
- NTM launchd status: `(none installed)`.
- Exact checkpoint history gaps: no exact checkpoint row for `flywheel`,
  `skillos`, or `alpsinsurance`.
- Stale path gaps: `session_paths` still contains `alps-insurance` and old
  desktop paths; active repos now live under `~/Developer/...` for several
  sessions.
- Per-agent transcript stores are mostly persistent on disk, but live agent
  processes and in-progress generation state die on reboot.
- `/flywheel:handoff` captures the right kind of semantic state, but it is a
  manual/accretive pause primitive, not an automatic reboot crash primitive.

Bottom line:

The durable data mostly exists. The missing primitive is a fleet-level,
atomic pre-reboot/recovery bundle that joins:

1. watcher plist install/status,
2. current pane topology,
3. exact repo paths,
4. latest valid checkpoint per session,
5. dirty git state,
6. in-flight dispatch/callback ledger,
7. per-agent transcript pointers,
8. locked flywheel docs,
9. CASS/handoff context,
10. a restore verifier that detects path mismatch before starting agents.

## Evidence Commands

All commands were read-only.

```bash
/Users/josh/.claude/skills/.flywheel/bin/flywheel-loop doctor --repo /Users/josh/Developer/flywheel --json
/Users/josh/.claude/skills/.flywheel/bin/flywheel-loop tick --repo /Users/josh/Developer/flywheel --dry-run --json
/Users/josh/.local/bin/ntm list --json
/Users/josh/.local/bin/ntm health <session> --json
/Users/josh/.local/bin/ntm checkpoint --help
/Users/josh/.local/bin/ntm checkpoint save --help
/Users/josh/.local/bin/ntm checkpoint list --help
/Users/josh/.local/bin/ntm checkpoint restore --help
/Users/josh/.local/bin/ntm checkpoint export --help
/Users/josh/.local/bin/ntm save --help
/Users/josh/.local/bin/ntm adopt --help
/Users/josh/.local/bin/ntm health --help
/Users/josh/Developer/ntm/scripts/ntm-launchd.sh status
sed -n '1,260p' ~/.claude/skills/ntm-session-plist/SKILL.md
sed -n '1,260p' ~/.claude/skills/cross-agent-session-resumer/SKILL.md
sed -n '1,260p' ~/.claude/commands/flywheel/handoff.md
python3 ~/.claude/skills/cross-agent-session-resumer/scripts/session_converter.py --help
python3 ~/.claude/skills/cross-agent-session-resumer/scripts/session_converter.py --json providers
```

Preflight result:

- `flywheel-loop doctor`: status ok.
- `flywheel-loop tick --dry-run`: status ok, decision `review existing repo changes before editing`.
- Dirty worktree count in flywheel: 70. No repo edits were made.

## Active Fleet Snapshot

From `ntm list --json`:

| Session | Panes | Attached | Agent summary |
|---|---:|---|---|
| `alpsinsurance` | 4 | true | 2 Claude, 1 Codex, 1 user |
| `clutterfreespaces` | 3 | true | 3 user |
| `flywheel` | 5 | true | 1 Claude, 3 Codex, 1 user |
| `picoz` | 4 | false | 2 Claude, 2 Codex |
| `skillos` | 3 | true | 2 Codex, 1 user |
| `vrtx` | 5 | true | 1 Claude, 3 Codex, 1 user |
| `zeststream-v2` | 4 | false | 4 user |
| `zesttube` | 4 | false | 3 Claude, 1 user |

Read-only health pass:

| Session | Health status | Total | Healthy | Error | Notes |
|---|---|---:|---:|---:|---|
| `alpsinsurance` | ok | 4 | 4 | 0 | Reboot risk is persistence, not current liveness. |
| `clutterfreespaces` | error | 3 | 1 | 2 | No topology row in current ledger. |
| `flywheel` | error | 5 | 3 | 2 | Brain session has current health errors. |
| `picoz` | ok | 4 | 4 | 0 | Has topology rows and roster rows. |
| `skillos` | error | 3 | 2 | 1 | Partial topology row only. |
| `vrtx` | error | 5 | 1 | 4 | No topology row in current ledger. |
| `zeststream-v2` | error | 4 | 0 | 4 | No topology row in current ledger. |
| `zesttube` | error | 4 | 3 | 1 | No topology row in current ledger. |

## 1. Active State Taxonomy

Each layer has five fields:

- Storage location.
- Persistence mechanism today.
- Reboot survival status today.
- Restoration cost/risk.
- Evidence.

### Layer 1 - NTM/tmux session process state

Storage location:

- Live multiplexer session/process tree, surfaced through `ntm list --json`.
- Current active sessions are not persisted as running processes across reboot.

Persistence mechanism today:

- None for exact live process state.
- `ntm checkpoint save` can capture layout, scrollback, agent types, commands,
  git state, and patches when run.
- `ntm-launchd.sh install <session>` can install a watcher plist, but none are
  currently installed.

Reboot survival status today:

- Dies on reboot.
- No exact `com.ntm.watcher.<session>.plist` exists to auto-recreate the active
  sessions.

Restoration cost/risk:

- HIGH.
- Manual respawn risks losing pane layout, working directories, active dispatch
  prompts, provider-specific resume IDs, and callback routing.

Evidence:

- `ntm list --json` reports 8 sessions / 32 panes.
- `ntm-launchd.sh status` reports `(none installed)`.

### Layer 2 - Pane layout, pane title, active pane, pane command

Storage location:

- Live session.
- Checkpoint bundle under NTM checkpoint storage when saved.

Persistence mechanism today:

- `ntm checkpoint save <session>` help says it captures all pane configurations,
  titles, agent types, commands, pane scrollback, and git state.

Reboot survival status today:

- Partial.
- Checkpoints exist for some session names, but exact active names are missing
  for `flywheel`, `skillos`, and `alpsinsurance`.

Restoration cost/risk:

- HIGH.
- Layout is recoverable only from a recent, correctly named checkpoint.
- Old checkpoints can restore stale panes into wrong repos.

Evidence:

- `ntm checkpoint save --help`.
- `ntm checkpoint list --json`.

### Layer 3 - Agent CLI process state

Storage location:

- Live Claude/Codex/Gemini processes inside panes.
- Native transcript stores under agent home directories.

Persistence mechanism today:

- Process state itself does not persist.
- Transcript state persists in provider-specific files.
- Resume support is provider-specific.

Reboot survival status today:

- Process dies.
- Transcript store survives.
- Mid-generation/tool-call state is not guaranteed to survive.

Restoration cost/risk:

- HIGH for active workers.
- MEDIUM for idle panes.
- Reboot during generation can orphan a dispatch with no callback.

Evidence:

- `cross-agent-session-resumer` skill: source sessions exist in provider stores;
  conversion should not happen mid-tool-call.
- Raw filesystem counts: 4686 Claude JSONL files, 951 Codex session files, 735
  Gemini-related files.

### Layer 4 - Claude Code transcripts

Storage location:

- `~/.claude/projects/*/*.jsonl`.
- Flywheel project memory under
  `~/.claude/projects/-Users-josh-Developer-flywheel/memory/`.

Persistence mechanism today:

- File-backed JSONL transcripts and memory files.

Reboot survival status today:

- Survives as files.
- Active Claude process and current tool execution die.

Restoration cost/risk:

- MEDIUM.
- Resume can be possible, but pane assignment and dispatch context must be
  joined from NTM topology and callback ledgers.

Evidence:

- 4686 `.jsonl` files under `~/.claude/projects`.
- 25 memory files under the flywheel project memory path.

### Layer 5 - Codex session state

Storage location:

- `~/.codex/sessions`.

Persistence mechanism today:

- File-backed session state.

Reboot survival status today:

- Files survive.
- Live Codex workers die.

Restoration cost/risk:

- HIGH for active dispatched Codex panes because callback delivery depends on
  pane identity and submit behavior.

Evidence:

- 951 raw files under `~/.codex/sessions`.
- Fuckup-log classes include `ntm-codex-queued-not-submitted` and
  `ntm-codex-submit-assurance-narrow-scope`.

### Layer 6 - Gemini state

Storage location:

- `~/.gemini`.
- CASR skill expects `~/.gemini/sessions`.

Persistence mechanism today:

- File-backed provider state.

Reboot survival status today:

- Files survive.
- CASR script reported Gemini installed but `session_count=0` at its expected
  session path, while raw scan found 735 files under `~/.gemini`.

Restoration cost/risk:

- MEDIUM.
- Need provider-specific resume verification before relying on CASR output.

Evidence:

- CASR provider probe.
- Raw filesystem count.

### Layer 7 - CASS cache / PreCompact context

Storage location:

- `~/.cubcloud/mem/cache/context/`.

Persistence mechanism today:

- File-backed cache.
- `/flywheel:handoff` publishes condensed CASS PreCompact cache through an
  atomic helper after writing handoff.

Reboot survival status today:

- Survives as files.
- Only as fresh as the last handoff/cache publish.

Restoration cost/risk:

- MEDIUM.
- Missing or stale CASS cache produces recovery context gaps but does not
  destroy repo data.

Evidence:

- Cache path present.
- 25 files observed.
- `/flywheel:handoff` Step 5 publishes CASS cache.

### Layer 8 - Beads databases

Storage location:

- Per-repo `.beads/beads.db` and sometimes `.beads/issues.db`.

Persistence mechanism today:

- SQLite files in repo directories.

Reboot survival status today:

- Files survive.
- WAL/write-in-progress risk exists if reboot hits during mutation.

Restoration cost/risk:

- HIGH where beads define active work.
- Corruption blocks planning, dispatch, and dependency graph recovery.

Evidence:

- Active repo DBs found:
  - `alpsinsurance/.beads/beads.db` 14M.
  - `flywheel/.beads/beads.db` 688K and `issues.db` 0B.
  - `picoz/.beads/beads.db` 14M and `issues.db` 10M.
  - `polymarket-pico-z/.beads/beads.db` 14M and `issues.db` 10M.
  - `skillos/.beads/beads.db` 300K.
  - `zeststream-v2/.beads/beads.db` 236K.
  - `zesttube/.beads/beads.db` 6.8M.

### Layer 9 - Dirty repo worktrees

Storage location:

- Repo working trees.

Persistence mechanism today:

- Files on disk survive.
- Uncommitted work survives normal reboot, but not accidental cleanup/reset.

Reboot survival status today:

- Survives on disk.
- Semantic ownership and in-progress intent can be lost.

Restoration cost/risk:

- HIGH.
- Dirty state must be tied to pane/dispatch/bead before restart.

Evidence:

- Dirty path counts:
  - `alpsinsurance`: 109.
  - `flywheel`: 70.
  - `picoz` / `polymarket-pico-z`: 450.
  - `skillos`: 21.
  - `vrtx`: 462.
  - `zesttube`: 29.
  - `clutterfreespaces`: 0.
  - `zeststream-v2`: 0.

### Layer 10 - Agent Mail service state

Storage location:

- Install dir: `~/.local/share/mcp_agent_mail`.
- Live DB observed: `~/.local/share/mcp_agent_mail/storage.sqlite3`.
- WAL/SHM present: `storage.sqlite3-wal`, `storage.sqlite3-shm`.
- Plist: `~/Library/LaunchAgents/ai.zeststream.mcp-agent-mail-local.plist`.

Persistence mechanism today:

- SQLite file plus launchd service plist.

Reboot survival status today:

- DB survives.
- Service should restart via launchd plist.
- In-flight MCP calls do not survive.

Restoration cost/risk:

- HIGH for dispatch coordination when workers rely on mail/file reservations.
- FD leak or DB lock state can return as a wedge if not diagnosed.

Evidence:

- DB candidates found; dispatch's older `mcp_agent_mail.db` name did not match
  live install, which uses `storage.sqlite3`.
- Fuckup-log has repeated `agent-mail-too-many-open-files` and
  `agent-mail-mcp-too-many-open-files` rows.

### Layer 11 - Substrate registry

Storage location:

- `~/.claude/skills/.flywheel/data/substrate-registry.json`.

Persistence mechanism today:

- JSON file in flywheel skill data.

Reboot survival status today:

- Survives.

Restoration cost/risk:

- MEDIUM.
- Registry gives doctor/health probes a map, but does not restart sessions.

Evidence:

- File exists, 271K.
- Doctor scanned 10 tentacles: 9 healthy, 1 unhealthy.

### Layer 12 - Locked repo docs

Storage location:

- Per repo: `.flywheel/MISSION.md`, `.flywheel/GOAL.md`,
  `.flywheel/STATE.md`.

Persistence mechanism today:

- Git/file-backed docs with lock hashes.
- `flywheel-loop finalize-state-lock` exists from previous work.

Reboot survival status today:

- Files survive.
- Drift risk remains if a writer mutates body after lock.

Restoration cost/risk:

- HIGH for repo-local mission correctness.
- Wrong `STATE.md` can direct a restored orchestrator into stale work.

Evidence:

- Present in `alpsinsurance`, `flywheel`, `picoz`, `polymarket-pico-z`,
  `skillos`, `vrtx`, and `zesttube`.
- `zeststream-v2` has beads but no `.flywheel` docs found in this pass.

### Layer 13 - Fuckup-log

Storage location:

- `~/.local/state/flywheel/fuckup-log.jsonl`.

Persistence mechanism today:

- Append-only JSONL file.

Reboot survival status today:

- Survives.
- Last in-memory correlation with pane scrollback can be lost.

Restoration cost/risk:

- MEDIUM.
- Critical for not repeating recovery mistakes.

Evidence:

- File exists, 151K.
- Relevant classes found: `autoloop-launchd-startinterval-skipped-7hr`,
  `ntm-send-codex-enter-submit-glitch`, `state-lock-hash-one-tick-behind`,
  `alps-pane-state-drift`, `agent-mail-too-many-open-files`,
  `ntm-codex-queued-not-submitted`.

### Layer 14 - Session topology

Storage location:

- `~/.local/state/flywheel/session-topology.jsonl`.

Persistence mechanism today:

- Append-only JSONL ledger.

Reboot survival status today:

- File survives.
- Coverage is incomplete and uneven.

Restoration cost/risk:

- HIGH.
- Callback panes and orchestrator panes are needed to avoid sending recovery
  messages to wrong panes.

Evidence:

- File exists, 4.0K.
- Latest complete rows exist for `flywheel`, `picoz`, and `alpsinsurance`.
- `skillos` latest row only has `session`, `orchestrator_pane`,
  `fleet_mail_identity`, and `effective_at`.
- `vrtx`, `zesttube`, `zeststream-v2`, and `clutterfreespaces` did not appear
  in the latest topology tail.

### Layer 15 - Team roster / pulse state

Storage location:

- `~/.local/state/flywheel/team-roster.jsonl`.
- `~/.local/state/flywheel/team-pulse.jsonl`.

Persistence mechanism today:

- Roster JSONL exists.
- Pulse file missing.

Reboot survival status today:

- Roster survives.
- Pulse is absent, so age-based live/dead recovery cannot run from it.

Restoration cost/risk:

- MEDIUM.
- Roster helps identify repo/session ownership, but without pulse it cannot
  confirm recency.

Evidence:

- `team-roster.jsonl` exists, 6.6K.
- `team-pulse.jsonl` missing.

### Layer 16 - NTM fleet health daemon state

Storage location:

- `~/.local/state/flywheel/ntm-fleet-health.jsonl`.
- LaunchAgent: `~/Library/LaunchAgents/ai.zeststream.ntm-fleet-health.plist`.

Persistence mechanism today:

- Launchd plist plus bounded JSONL.

Reboot survival status today:

- Daemon should run after login/launchd.
- It observes and can auto-restart stuck panes, but it does not recreate
  missing sessions from scratch.

Restoration cost/risk:

- MEDIUM.
- Useful verifier, not full recovery.

Evidence:

- JSONL exists, 456K.
- Latest rows show `success=true`, no `restarted`, threshold `10m`.

### Layer 17 - Loop state

Storage location:

- `~/.flywheel/loops/alpsinsurance.json`.
- `~/.flywheel/loops/flywheel.json`.
- `~/.local/state/flywheel-loop/last_tick_alpsinsurance.json`.
- `~/.local/state/flywheel-loop/last_tick_flywheel.json`.

Persistence mechanism today:

- JSON files.

Reboot survival status today:

- Files survive.
- Scheduler/session delivery can fail if session watcher is absent.

Restoration cost/risk:

- HIGH for active loops.
- `auto_revive_on_reboot=true` in loop files is aspirational unless session
  launchd watcher + tick delivery is wired.

Evidence:

- Two loop project files.
- Two last tick files.

### Layer 18 - Tick receipts and flywheel logs

Storage location:

- `~/.claude/skills/.flywheel/logs/`.

Persistence mechanism today:

- Log files.

Reboot survival status today:

- Survives.

Restoration cost/risk:

- LOW to MEDIUM.
- Logs help reconstruct history but do not restore agents.

Evidence:

- 106 log files observed.
- `flywheel.log`, `hook-capture.log`, summarize/weekly logs present.

### Layer 19 - In-flight dispatch context

Storage location:

- `/tmp/dispatch_*.md` packets.
- Repo `.flywheel/dispatch-log.jsonl` when present.
- Pane scrollback and callback messages.

Persistence mechanism today:

- `/tmp` may persist across warm reboot on macOS, but it is not a recovery
  contract.
- Handoff command explicitly captures open `/tmp/dispatch_*.md` files referenced
  by un-callbacked dispatches.

Reboot survival status today:

- Fragile.
- In-flight prompt/generation dies; packet file may survive; callback ledger may
  be incomplete.

Restoration cost/risk:

- HIGH.
- This is the main "orphaned worker" class.

Evidence:

- `/flywheel:handoff` Step 2 includes all in-flight dispatches with no callback
  and open dispatch files.
- Fuckup-log has callback/pane-state classes.

### Layer 20 - Substrate-tentacle plans from this session

Storage location:

- `/tmp/*tentacle*plan*.md`.

Persistence mechanism today:

- `/tmp` files only unless copied into a repo or bead.

Reboot survival status today:

- Fragile.

Restoration cost/risk:

- MEDIUM.
- They are planning artifacts, not active process state, but losing them forces
  re-research.

Evidence:

- Ten plan files found:
  - `/tmp/am_tentacle_substrate_plan.md`
  - `/tmp/asupersync_tentacle_substrate_plan.md`
  - `/tmp/br_tentacle_substrate_plan.md`
  - `/tmp/bv_tentacle_substrate_plan.md`
  - `/tmp/cass_tentacle_substrate_plan.md`
  - `/tmp/dcg_tentacle_substrate_plan.md`
  - `/tmp/frankensqlite_tentacle_substrate_plan.md`
  - `/tmp/ntm_tentacle_substrate_plan.md`
  - `/tmp/pi_tentacle_substrate_plan.md`
  - `/tmp/vc_tentacle_substrate_plan.md`

### Layer 21 - Project memory

Storage location:

- `~/.claude/projects/-Users-josh-Developer-flywheel/memory/`.

Persistence mechanism today:

- File-backed memory Markdown.

Reboot survival status today:

- Survives.

Restoration cost/risk:

- MEDIUM.
- Memory contains operational corrections that can prevent wrong recovery
  decisions, but it is only useful if recovery reads it.

Evidence:

- 25 memory files found, including callback pane, NTM send verification,
  session handoff v0.4, Agent Mail service, and Jeff issue chain references.

## 2. Reboot Survival Matrix

| State Layer | Today's Survival | After Reboot | Restoration Cost | Critical? |
|---|---|---|---|---|
| NTM/tmux live session | live only | dies | recreate sessions and panes | HIGH |
| Pane layout/titles/commands | checkpoint if saved | partial/stale | restore from checkpoint or manually rebuild | HIGH |
| Agent CLI processes | live only | dies | resume provider sessions manually | HIGH |
| Claude transcripts | file-backed | survives | map transcript to pane/session | MEDIUM |
| Codex transcripts | file-backed | survives | resume and rebind to NTM pane | HIGH |
| Gemini transcripts | file-backed | survives | verify actual session path before use | MEDIUM |
| CASS cache | file-backed | survives if fresh | read cache or regenerate | MEDIUM |
| Beads DBs | SQLite files | survives, possible WAL risk | integrity check/repair | HIGH |
| Dirty worktrees | filesystem | survives | attribute to panes before continuing | HIGH |
| Agent Mail DB/service | SQLite + launchd | DB survives, service restarts | verify service and FD state | HIGH |
| Substrate registry | JSON file | survives | read during doctor | MEDIUM |
| Locked docs | repo files | survives, possible drift | doctor/finalize locks | HIGH |
| Fuckup-log | JSONL | survives | read and triage | MEDIUM |
| Session topology | JSONL | survives but incomplete | append missing authoritative rows | HIGH |
| Team roster | JSONL | survives | latest-per-session read | MEDIUM |
| Team pulse | missing | absent | implement heartbeat | MEDIUM |
| Fleet health daemon state | JSONL + plist | survives after launchd | verify session health | MEDIUM |
| Loop state | JSON files | survives | tick delivery still needs panes | HIGH |
| Tick receipts/logs | logs | survives | audit trail only | LOW |
| In-flight dispatch context | `/tmp` + panes | fragile | reconcile packets/callbacks | HIGH |
| Tentacle plans | `/tmp` only | fragile | copy/promote to repo plan space | MEDIUM |
| Project memory | markdown files | survives | read during recovery | MEDIUM |

## 3. Existing Primitives Audit

### Primitive A - `ntm checkpoint save`

Command surface:

```bash
ntm checkpoint save <session> [--message <text>] [--scrollback N] [--no-git] [--json]
```

What it captures:

- Pane configurations: titles, agent types, commands.
- Pane scrollback buffers.
- Git branch, commit, dirty status.
- Optional uncommitted diff patch.

What it does not capture:

- Live process memory.
- Provider-internal current generation/tool execution.
- Agent Mail in-flight MCP calls.
- Dispatch callback completion semantics.
- Whether a checkpoint name matches the current canonical session name.
- Whether the checkpoint working directory still exists.

Observed gaps:

- No exact active-session checkpoint for `flywheel`.
- No exact active-session checkpoint for `skillos`.
- No exact active-session checkpoint for `alpsinsurance`; only stale
  `alps-insurance`.
- `zeststream-v2` checkpoint points at missing desktop path.
- `picoz` has both `picoz` and `polymarket-pico-z` checkpoint histories, which
  can confuse restore target selection.

Known traumas:

- `state-lock-hash-one-tick-behind`.
- `alps-pane-state-drift`.
- `ntm-codex-queued-not-submitted`.
- `wrong-workdir-applypatch`.

Gap relative to full reboot survival:

- It is necessary but not sufficient. It must be run atomically with topology,
  dispatch, dirty-worktree, and provider transcript pointer capture.

### Primitive B - `ntm checkpoint list`

Command surface:

```bash
ntm checkpoint list [session] [--json]
```

What it captures:

- Inventory of checkpoint bundles.
- Per-session checkpoint counts.
- Created timestamps and working dirs.

What it does not capture:

- Whether a checkpoint is safe to restore now.
- Whether repo path exists now.
- Whether active session name differs from checkpoint session name.

Observed active-session checkpoint status:

| Active session / alias | Checkpoints | Latest | Latest working dir |
|---|---:|---|---|
| `alpsinsurance` | 0 exact | none | none |
| `alps-insurance` | 3 | 2026-03-14 | missing old desktop path |
| `clutterfreespaces` | 1 | 2026-03-26 | missing old desktop path |
| `flywheel` | 0 | none | none |
| `picoz` | 6 | 2026-04-19 | `/Users/josh/Developer/picoz` |
| `polymarket-pico-z` | 5 | 2026-04-08 | `/Users/josh/Developer/polymarket-pico-z` |
| `skillos` | 0 | none | none |
| `vrtx` | 10 | 2026-04-29 | `/Users/josh/Developer/vrtx` |
| `zeststream-v2` | 10 | 2026-02-06 | missing old desktop path |
| `zesttube` | 10 | 2026-04-24 | `/Users/josh/Developer/zesttube` |

Gap relative to full reboot survival:

- Needs a "latest valid checkpoint for current active canonical session" view,
  not just list by historical session names.

### Primitive C - `ntm checkpoint restore`

Command surface:

```bash
ntm checkpoint restore <session> [checkpoint-id] [--dry-run] [--directory <path>] [--inject-context] [--scrollback N] [--skip-git-check] [--force] [--attach]
```

What it restores:

- Session layout and panes from checkpoint.
- Can inject captured scrollback.
- Can dry-run.

What it does not restore:

- True live agent continuation.
- Dispatch callback state.
- Agent Mail reservations.
- Provider auth health.
- Dirty work ownership.

Gap relative to full reboot survival:

- Restore must be wrapped by a verifier that checks repo path, git HEAD, dirty
  patch applicability, active session name, and topology callback pane.

### Primitive D - `ntm checkpoint export`

Command surface:

```bash
ntm checkpoint export <session> <id> [--output <path>] [--format tar.gz|zip] [--redact-secrets] [--no-git-patch] [--no-scrollback]
```

What it captures:

- Metadata, scrollback, git patches, and `MANIFEST.json` with SHA256 checksums.

What it does not capture:

- Live process state.
- In-flight external service state.
- Fleet-wide dependency graph.

Gap relative to full reboot survival:

- Useful for portable backup, not automatic boot recovery unless invoked before
  reboot or scheduled.

### Primitive E - `ntm-launchd.sh install <session>`

Command surface from script:

```bash
~/Developer/ntm/scripts/ntm-launchd.sh install SESSION [EXTRA_FLAGS...]
~/Developer/ntm/scripts/ntm-launchd.sh uninstall SESSION
~/Developer/ntm/scripts/ntm-launchd.sh status
~/Developer/ntm/scripts/ntm-launchd.sh install-all
```

What it creates:

- `~/Library/LaunchAgents/com.ntm.watcher.<session>.plist`.
- ProgramArguments call `~/Developer/ntm/scripts/ntm-watcher.sh <session>`.
- `RunAtLoad=true`.
- `KeepAlive` with `SuccessfulExit=false`.
- `SoftResourceLimits.NumberOfFiles=4096`.

What watcher does:

- Checks session exists.
- If session missing, exits 0 so launchd does not restart.
- If session exists, runs `ntm assign "$SESSION" --auto --strategy=dependency --watch`.
- Resolves project dir from `[session_paths]`; otherwise falls back to
  `$HOME/Developer/$SESSION`.

What it does not do:

- Create the missing NTM/tmux session at boot by itself.
- Restore from checkpoint.
- Fix stale `session_paths`.
- Verify active repo path.
- Resume provider transcripts.

Observed current status:

- `(none installed)`.
- No `com.ntm.watcher.*.plist` files.

Gap relative to full reboot survival:

- The skill's "survive reboots" claim is incomplete for this script version:
  if the session is absent, watcher exits cleanly. A separate boot primitive must
  restore/spawn the session before watcher can latch.

### Primitive F - `ntm save`

Command surface:

```bash
ntm save [session-name] [--all] [--cc] [--cod] [--gmi] [--lines N] [--output DIR] [--json]
```

What it captures:

- Pane output text into timestamped files.
- Useful for scrollback evidence and postmortem.

What it does not capture:

- Layout.
- Agent process state.
- Git patch.
- Dispatch ledger.
- Resume IDs.

Gap relative to full reboot survival:

- Useful as an evidence snapshot. Not a recovery snapshot.

### Primitive G - `ntm adopt`

Command surface:

```bash
ntm adopt <session-name> --cc=0,1 --cod=2,3 --gmi=4 --user=0 --auto-name --dry-run
```

What it captures/changes:

- Adopts externally-created sessions for NTM management.
- Sets pane titles and agent types.
- Has `--dry-run`.

What it does not capture:

- It does not persist a reboot contract.
- It does not save checkpoints.
- It does not install watcher plists.

Gap relative to full reboot survival:

- Useful after manual resurrection; not enough for automatic recovery.

### Primitive H - `casr` / cross-agent-session-resumer

Command surface from skill:

```bash
casr providers
casr list --limit 20 --sort date
casr info SESSION_ID
casr -cc SESSION_ID
casr -cod SESSION_ID
casr -gmi SESSION_ID
casr cc resume SESSION_ID --json
python3 scripts/session_converter.py discover --limit 20
python3 scripts/session_converter.py inspect --session-id SESSION_ID
python3 scripts/session_converter.py --json providers
python3 scripts/session_converter.py validate --session-id ID --target codex
```

Observed install state:

- `casr` binary not on PATH.
- Skill-local `scripts/session_converter.py` exists.
- Provider probe reported Codex and Gemini installed, Claude false.
- Provider probe reported zero session counts even though raw filesystem scans
  found Claude/Codex/Gemini transcript files. This is a mapping gap.

What it helps with:

- Provider conversion after a session exists and a source session is known.
- Rate-limit/stuck-agent recovery.
- Cross-provider handoff.

What it does not help with:

- It is not a reboot backup.
- It should not convert mid-tool-call.
- It does not preserve sandbox/process state.

Gap relative to full reboot survival:

- Recovery needs a "resume pointer registry" per pane before CASR can be used
  reliably after reboot.

### Primitive I - `/flywheel:handoff`

Command surface:

```text
/flywheel:handoff [reason]
```

What it captures:

- In-flight dispatches with no callback.
- Open beads with `in_progress`.
- Pending Agent Mail threads.
- Open `/tmp/dispatch_*.md` files referenced by un-callbacked dispatches.
- Current pane state via `pane-state.sh`.
- Learning state from fuckup-log and doctor triage.
- Handoff Markdown under `.flywheel/handoffs/<iso>-<reason>.md`.
- Pointer update in `.flywheel/STATE.md`.
- Condensed CASS PreCompact cache.
- Agent Mail "session pausing" broadcast.

What it does not capture:

- It is manual.
- It does not install watcher plists.
- It does not run `ntm checkpoint save`.
- It does not restore sessions.

Gap relative to full reboot survival:

- The semantic state is right; the trigger is wrong. A recovery system should
  reuse the handoff schema but produce it automatically before planned reboot
  and as a degraded "last-known" bundle on unplanned reboot.

## 4. Gap Analysis

### Gap 1 - No session watcher plists

Today's state:

- 8 active sessions.
- 0 `com.ntm.watcher.*.plist`.

Almost-working primitive:

- `ntm-launchd.sh install <session>`.

Smallest closing primitive:

- `flywheel recovery install-watchers --sessions active --dry-run`.
- Validates `[session_paths]` before install.
- Installs only after path and checkpoint checks pass.

Complexity:

- M.

### Gap 2 - Watcher does not recreate missing sessions

Today's state:

- `ntm-watcher.sh` exits 0 if session does not exist.

Almost-working primitive:

- `ntm checkpoint restore --dry-run`.
- `ntm create/spawn` family.

Smallest closing primitive:

- Boot coordinator LaunchAgent that runs before watchers:
  `recovery-bootstrap --restore-missing-sessions`.

Complexity:

- L.

### Gap 3 - Stale `session_paths`

Today's state:

- `alps-insurance` points to missing old desktop path.
- Active session is `alpsinsurance` and repo exists at
  `/Users/josh/Developer/alpsinsurance`.
- `zeststream-v2` checkpoint uses missing old desktop path.
- Several active sessions have no current config mapping.

Almost-working primitive:

- `ntm-session-plist` skill documents manual config update.

Smallest closing primitive:

- `recovery path-audit` that compares `ntm list`, team roster,
  session topology, checkpoint working dirs, and actual repo dirs.

Complexity:

- M.

### Gap 4 - No exact checkpoint for core sessions

Today's state:

- No exact `flywheel` checkpoint.
- No exact `skillos` checkpoint.
- No exact `alpsinsurance` checkpoint.

Almost-working primitive:

- `ntm checkpoint save`.

Smallest closing primitive:

- `recovery checkpoint-fleet --active --scrollback 2000`.
- Must be atomic per session: save to temp, verify, then mark current.

Complexity:

- M.

### Gap 5 - Dirty worktree ownership not captured

Today's state:

- Multiple active repos have 20-400+ dirty paths.

Almost-working primitive:

- `ntm checkpoint save` captures git dirty status and patch.
- Beads DB tracks work items.

Smallest closing primitive:

- Add `dirty_owner_map` to checkpoint metadata by joining repo status,
  session topology, dispatch log, and worker pane.

Complexity:

- M.

### Gap 6 - In-flight dispatches can orphan

Today's state:

- Dispatch packets may live in `/tmp`.
- Callback state may only exist in pane scrollback and report files.

Almost-working primitive:

- `/flywheel:handoff` Step 2.

Smallest closing primitive:

- `recovery dispatch-ledger-snapshot` that writes an append-only JSONL row for
  every active dispatch before sending to a pane and marks callback receipt.

Complexity:

- M.

### Gap 7 - Per-agent resume pointers missing

Today's state:

- Transcript files exist, but mapping from pane to native session ID is not
  canonical.

Almost-working primitive:

- CASR skill/script.
- Agent CLI native resume mechanisms.

Smallest closing primitive:

- `pane_resume_pointer.jsonl` containing session, pane, agent kind, native
  session id/path, started_at, last_seen_at, dispatch id.

Complexity:

- L.

### Gap 8 - Agent Mail service can be green but wedged

Today's state:

- DB and plist exist.
- Recent fuckup-log has repeated FD leak/open files failures.

Almost-working primitive:

- Agent Mail health probes and tentacle plan.

Smallest closing primitive:

- Recovery health check that includes FD count, lock count, DB integrity, and
  service restart proof after reboot.

Complexity:

- M.

### Gap 9 - Team pulse missing

Today's state:

- Roster exists.
- Pulse file missing.

Almost-working primitive:

- `roster-register.sh` and team roster design.

Smallest closing primitive:

- 5-minute pulse LaunchAgent per active session, or fleet-level pulse collector.

Complexity:

- S.

### Gap 10 - Tentacle plans are in `/tmp`

Today's state:

- Ten substrate plans exist in `/tmp`.

Almost-working primitive:

- Beads workflow / plan archiving.

Smallest closing primitive:

- `recovery artifact-promote` copies named `/tmp` mission artifacts into a
  repo plan directory and records pointers in handoff.

Complexity:

- S.

### Gap 11 - CASR binary absent / provider mapping mismatch

Today's state:

- `casr` command not found.
- Skill-local script exists but reports zero sessions despite raw files.

Almost-working primitive:

- Skill-local `session_converter.py`.

Smallest closing primitive:

- CASR install/doctor bead plus provider path reconciliation.

Complexity:

- M.

### Gap 12 - Recovery does not know boot readiness

Today's state:

- launchd plists can fire before dependent volumes/services/provider CLIs are
  ready.

Almost-working primitive:

- Existing launchd plists and fleet health daemon.

Smallest closing primitive:

- `recovery boot-gate` waits for home dir, repos, NTM binary, provider CLIs,
  Agent Mail DB, and network-independent prerequisites before restore.

Complexity:

- M.

## 5. Failure Modes to Design Against

### F1 - Reboot mid-worker-generation

Scenario:

- Codex or Claude is generating or using tools when reboot occurs.

Mitigation sketch:

- Capture pane resume pointer before dispatch.
- Dispatch ledger marks task `sent`, `accepted`, `callback_received`.
- Recovery marks missing callback as `orphan_candidate`, not done.

### F2 - Reboot during `ntm checkpoint save`

Scenario:

- Checkpoint dir partially written.

Mitigation sketch:

- Save to temp dir.
- Verify manifest/checksums.
- Atomically mark `current`.
- Recovery ignores checkpoints without valid manifest.

### F3 - Reboot with dirty git state

Scenario:

- Worktree survives, but owner/intent is lost.

Mitigation sketch:

- Checkpoint includes `git status --short`, patch, current bead/dispatch id,
  and pane owner.
- Recovery blocks automatic edits until owner map is reviewed.

### F4 - Reboot with active Agent Mail FD leak

Scenario:

- AM service restarts, but DB/lock/FD wedge class recurs.

Mitigation sketch:

- Recovery AM probe checks process, FD count, DB integrity, liveness, API
  health, and file reservation smoke only if safe.
- If FD pressure high, restart service before worker dispatch resumes.

### F5 - Reboot during dispatch send

Scenario:

- `ntm send` wrote prompt to pane but agent did not submit or callback.

Mitigation sketch:

- Dispatch ledger writes `prepared` before send and `sent` after successful
  `ntm send`.
- Codex pane submit assurance becomes part of send wrapper.
- Recovery replays only tasks in `prepared`/`sent_no_ack` states with explicit
  duplicate guard.

### F6 - Launchd watcher fires before user login readiness

Scenario:

- LaunchAgent starts while home paths, keychains, network, or provider CLIs are
  unavailable.

Mitigation sketch:

- Boot gate checks required paths and binaries.
- Use retry with backoff and bounded error logs.
- Do not spawn agents until config and repo paths verify.

### F7 - Two watchers race on same session

Scenario:

- Old process and new process both try to own watcher loop.

Mitigation sketch:

- Keep Go flock as source of truth.
- Recovery should verify one watcher PID per session.
- Avoid shell PID assumptions.

### F8 - Stale `session_paths` causes silent wrong repo

Scenario:

- Watcher resolves old path or falls back to `$HOME/Developer/$SESSION`.

Mitigation sketch:

- Recovery preflight compares `session_paths`, roster `repo_path`, topology, and
  checkpoint working dir.
- Any mismatch blocks restore until canonical path is selected.

### F9 - Agent CLI updates between crash and restore

Scenario:

- Codex/Claude/Gemini version changes and old transcript cannot resume.

Mitigation sketch:

- Checkpoint records agent binary path/version/hash per pane.
- Recovery detects version drift and routes to CASR or manual resume review.

### F10 - Disk pressure prevents checkpoint write

Scenario:

- Checkpoint save truncates or fails.

Mitigation sketch:

- Preflight disk space check.
- Write temp + manifest.
- Verify size and checksum before marking checkpoint current.

### F11 - Beads DB WAL or lock corruption

Scenario:

- Reboot interrupts Beads DB mutation.

Mitigation sketch:

- Recovery runs read-only integrity check first.
- If corrupt, invoke existing beads DB repair ladder before dispatching work.

### F12 - Locked `STATE.md` drift after reboot

Scenario:

- Restored orchestrator reads stale lock hash or stale `last_revised`.

Mitigation sketch:

- Run `flywheel-loop doctor --strict --repo` for every active repo.
- Run `finalize-state-lock` only under a deliberate repair step.

### F13 - `/tmp` artifacts disappear

Scenario:

- Tentacle plans or dispatch files in `/tmp` are absent after reboot.

Mitigation sketch:

- Handoff/recovery bundle promotes mission-critical `/tmp` files into repo plan
  space or records missing artifact as recovery gap.

### F14 - CASR provider path mismatch

Scenario:

- Raw transcripts exist, but CASR script reports zero sessions.

Mitigation sketch:

- Provider path doctor reconciles raw filesystem counts with CASR expected
  directories before claiming session fungibility.

### F15 - Fleet health daemon reports success but sessions are absent

Scenario:

- Daemon checks existing sessions but does not restore missing sessions.

Mitigation sketch:

- Separate liveness from resurrection.
- Recovery bootstrap first restores sessions; fleet health then verifies.

### F16 - Callback pane registry stale

Scenario:

- Callback sent to pane 1 when active orchestrator is pane 0, or vice versa.

Mitigation sketch:

- Use latest topology/roster row with `joshua_confirmed_at`.
- Recovery refuses callback dispatch for sessions without authoritative
  callback pane.

## 6. References and Verified Paths

### NTM command references

- `/Users/josh/.local/bin/ntm --help`: exists and lists checkpoint/save/adopt/health.
- `/Users/josh/.local/bin/ntm checkpoint --help`: captured.
- `/Users/josh/.local/bin/ntm checkpoint save --help`: captured.
- `/Users/josh/.local/bin/ntm checkpoint list --help`: captured.
- `/Users/josh/.local/bin/ntm checkpoint restore --help`: captured.
- `/Users/josh/.local/bin/ntm checkpoint export --help`: captured.
- `/Users/josh/.local/bin/ntm save --help`: captured.
- `/Users/josh/.local/bin/ntm adopt --help`: captured.
- `/Users/josh/.local/bin/ntm health --help`: captured.

### NTM launchd references

- `/Users/josh/Developer/ntm/scripts/ntm-launchd.sh`: exists and executable.
- `/Users/josh/Developer/ntm/scripts/ntm-watcher.sh`: exists and executable.
- `~/Library/LaunchAgents/com.ntm.watcher.*.plist`: zero matches.
- `/Users/josh/Library/LaunchAgents/ai.zeststream.ntm-fleet-health.plist`: exists.

### Skills

- `/Users/josh/.claude/skills/ntm-session-plist/SKILL.md`: exists.
- `/Users/josh/.claude/skills/cross-agent-session-resumer/SKILL.md`: exists.
- `/Users/josh/.claude/skills/cross-agent-session-resumer/scripts/session_converter.py`: exists.
- `/Users/josh/.claude/commands/flywheel/handoff.md`: exists.

### State paths

- `/Users/josh/.config/ntm/config.toml`: exists.
- `/Users/josh/.config/ntm/state.db`: exists, 5.1M.
- `/Users/josh/.local/state/flywheel/session-topology.jsonl`: exists.
- `/Users/josh/.local/state/flywheel/team-roster.jsonl`: exists.
- `/Users/josh/.local/state/flywheel/team-pulse.jsonl`: missing.
- `/Users/josh/.local/state/flywheel/ntm-fleet-health.jsonl`: exists.
- `/Users/josh/.local/state/flywheel/fuckup-log.jsonl`: exists.
- `/Users/josh/.claude/skills/.flywheel/data/substrate-registry.json`: exists.
- `/Users/josh/.claude/skills/.flywheel/logs/`: exists.
- `/Users/josh/.cubcloud/mem/cache/context/`: exists.

### Agent Mail references

- `/Users/josh/.local/share/mcp_agent_mail`: exists.
- `/Users/josh/.local/share/mcp_agent_mail/storage.sqlite3`: exists.
- `/Users/josh/Library/LaunchAgents/ai.zeststream.mcp-agent-mail-local.plist`: exists.

### Active repo references

- `/Users/josh/Developer/alpsinsurance`: exists.
- `/Users/josh/Developer/clutterfreespaces`: exists.
- `/Users/josh/Developer/flywheel`: exists.
- `/Users/josh/Developer/picoz`: exists.
- `/Users/josh/Developer/polymarket-pico-z`: exists.
- `/Users/josh/Developer/skillos`: exists.
- `/Users/josh/Developer/vrtx`: exists.
- `/Users/josh/Developer/zeststream-v2`: exists.
- `/Users/josh/Developer/zesttube`: exists.

## 7. Recommended Recovery Architecture for Later Lanes

Lane A is inventory only. The smallest practical design appears to be three
separate primitives:

1. `recovery snapshot`
   - Captures fleet topology, current sessions, checkpoints, dirty git,
     dispatch ledger, per-agent resume pointers, and state docs.
   - Writes one manifest with atomic temp-to-final semantics.

2. `recovery bootstrap`
   - Runs at boot/login.
   - Waits for readiness.
   - Validates paths.
   - Restores or recreates missing sessions.
   - Starts watchers only after sessions exist.

3. `recovery verify`
   - Runs after bootstrap.
   - Calls `ntm health --json`, repo doctors, Beads integrity, AM health, and
     callback ledger reconciliation.
   - Emits a single recovery verdict for Joshua.

Important design rule:

- Do not conflate watcher liveness with session resurrection. Current
  `ntm-watcher.sh` intentionally exits cleanly when a session is missing.

## 8. Validation Ladder

1. At least 10 state layers inventoried with all fields populated: PASS, 21
   layers inventoried.
2. Reboot survival matrix complete with criticality ratings: PASS.
3. All listed NTM primitives audited with gap analysis: PASS, checkpoint
   save/list/restore/export, launchd installer, save, adopt, CASR, and handoff
   covered.
4. Each gap has proposed primitive + complexity: PASS, 12 gaps.
5. At least 10 failure modes with mitigation sketch: PASS, 16 failure modes.
6. References complete and paths verified via `ls`/`test -e`/help reads: PASS.
7. Read-only inspection, no mutations: PASS.
8. No fabrication: PASS; behavior claims backed by `--help`, script/skill
   contents, or path probes listed above.
9. Cross-references to fuckup-log classes: PASS.
10. `ladder_passed`: yes.

Callback metrics:

- `layers=21`
- `gaps=12`
- `failure_modes=16`
