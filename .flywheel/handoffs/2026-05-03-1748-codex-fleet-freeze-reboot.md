# Handoff — 2026-05-03T17:48Z — reason: codex-fleet-freeze-reboot

## Why this handoff

Codex panes freezing recurrently across fleet (kitty-keyboard #12645 + new spike). Joshua decided to reboot. Workers may resume via launchd post-reboot; this handoff captures must-preserve state.

## Resume context

- **Repo:** /Users/josh/Developer/flywheel
- **Branch:** master
- **Last commits:**
  - `e493cca` feat(detector): ship frozen pane v2 core [c1-frozen-pane-detector-v2]
  - `3e85707` feat(flywheel): codify no silent darkness contract [c0-no-silent-darkness]
  - `bb328f8` fix(loop-driver): restore launchd prompt driver [flywheel-emyk]
- **Active session:** flywheel (4 panes — 1 self/Claude, 3 codex workers)

## Major wins this session

1. **RCA chain complete** end-to-end:
   - C10 beads_db_health_failed FIXED (sha 0cff2d5)
   - C11 loop_driver_marker_only FIXED (sha bb328f8)
   - C0 NO_SILENT_DARKNESS contract codified (L68 + probe, sha 3e85707)
   - C1 frozen-pane-detector v2 with F1-F7 audit findings (sha e493cca)
   - Jeff issue #117 filed (https://github.com/Dicklesworthstone/ntm/issues/117) + tracking bead `flywheel-eala`

2. **Codex watchtower P0 SHIPPED** — bead `flywheel-ezyf`:
   - Skill `codex-cli-tracker` live
   - Daily ingest `~/.local/bin/codex-watchtower-daily.sh` + launchd plist
   - tick.md Step 4t patched
   - INCIDENTS entry written
   - First ingest pass: 78 new issues, 18 relevant to our env (#12645 et al.)
   - Bead remains OPEN until refactored as info-source-watchtower CHILD (now unblocked)

3. **info-source-watchtower meta-skill SHIPPED** — bead `flywheel-1ndw` CLOSED:
   - 10 FOREVER-RULES + THE EXACT PROMPT
   - PATTERN.md, INSTANCES.md, SIGNAL-CLI.md
   - scripts/scaffold.sh shellcheck PASS
   - Smoke test PASS (postgres-release-notes-watchtower scaffolded)
   - INCIDENTS entry + L61 coord to skillos:2 + flywheel-ezyf cross-ref

4. **/flywheel:reorient command shipped** — `.claude/commands/flywheel/reorient.md` (267 lines, A-F phases, auto-trigger on L60 health <3/5 for >30min)

5. **126→0 fuckup-log drain** + 2 Joshua-disposes flagged:
   - `br-create-source-repo-dot-after-create` (3 events, skill-extension taste call)
   - `canonical_doctrine_drift_local` (3 events, skill-extension taste call)

6. **Codex root cause identified**: openai/codex#12645 kitty-keyboard+tmux. Recovery = Ctrl-C-relaunch (NOT bare-Enter, that was wrong earlier).

## In-flight dispatches (do not redispatch — these are running)

| task_id | worker | pane | status |
|---------|--------|------|--------|
| jeff-full-corpus-clone-index-2026_05_03 | flywheel:3 | codex | THINKING — clone+index ALL 177 Jeff repos, 4hr budget |
| info-source-watchtower (DONE — close ledger entry) | flywheel:2 | codex | callback received but ledger not yet marked |
| codex-watchtower-build (warn) | skillos:2 | codex | callback received, bead waiting on flywheel-1ndw close (now unblocked) |

## 17 socraticode indexes still chewing in background

Targets: destructive_command_guard, beads_viewer, agentic_coding_flywheel_setup, pi_agent_rust, claude_code_agent_farm, coding_agent_session_search, frankensqlite, frankensearch, frankentui, your-source-to-prompt.html, swiss_army_llama, llm_aided_ocr, bulk_transcribe_youtube_videos_from_playlist, acip, dcg, cass, Dicklesworthstone

## Open beads (priority order)

- **P0** `flywheel-ri1n` — clone + index ALL 177 Dicklesworthstone repos (in flight)
- **P0** `flywheel-ezyf` — codex-watchtower (refactor as info-source-watchtower child, unblocked)
- **P1** `flywheel-3pko` — codex#12645 kitty-keyboard recovery doctrine extension
- **P1** `flywheel-snf8` — canonical-driver patch (callback next_phase consumption)
- **P2** `flywheel-wutd` — beads_rust source_repo='.' upstream Jeff issue (L66)
- **P2** `flywheel-eala` — track upstream ntm #117

## Pending decisions for Joshua

1. **L66 Phase 3 dedup on Jeff issue #117** — DONE (filed new with backref to #114, thankfulness pass)
2. **2 learn-review skill-extension taste calls**: which skill to extend for `br-create-source-repo-dot-after-create` (beads-br vs beads-workflow vs upstream br) and `canonical_doctrine_drift_local` (canonical-owner-runtime-state vs flywheel-doctor-author vs install-substrate)
3. **Kitty-keyboard env-var mitigation research** — defer or fire? If a flag exists to disable kitty keyboard protocol globally, today's pain evaporates without code changes
4. **GITHUB_TOKEN rotation** — mobile-eats logged `gitconfig_plaintext_token_exposed` 17:46Z; token NOT rotated yet
5. **Build `/flywheel:recovery`** — gap discovered this session. ntm has the primitives (session save/restore in `vibing-with-ntm` + `claude-md-ntm.md`). File P1 bead post-reboot to compose canonical "snapshot fleet → reboot → restore fleet" command

## Files to read on resume

- `/tmp/info-source-watchtower-build_findings.md` — meta-skill receipt
- `/tmp/codex-watchtower-build_findings.md` — codex watchtower receipt
- `/tmp/c0-no-silent-darkness-receipt.md`, `/tmp/c1-frozen-pane-detector-v2-receipt.md`
- `/tmp/learn-review-drain_findings.md` — 2 Joshua-disposes
- `/tmp/rca-jeff-issue-draft-refined-v2.md` (filed as #117)
- `~/.local/state/flywheel/codex-watchtower/daily-2026-05-03.jsonl` — first watchtower ingest

## Suggested resume sequence (post-reboot)

1. `cd /Users/josh/Developer/flywheel`
2. `/flywheel:status` — verify autoloop alive + pane health
3. Check if jeff-full-corpus-clone-index callback landed (flywheel:3) OR resume it
4. Close `flywheel-ezyf` after codex-watchtower refactor as info-source-watchtower child
5. Surface 2 learn-review Joshua-disposes for taste call
6. File new bead: build `/flywheel:recovery` command (canonical fleet snapshot/restore via ntm)
7. Rotate GITHUB_TOKEN per `gitconfig_plaintext_token_exposed` fuckup
