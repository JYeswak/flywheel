# flywheel-66cl7 — codex CLI issue triage (daily-2026-05-11.jsonl)

Source ledger: `/Users/josh/.local/state/flywheel/codex-watchtower/daily-2026-05-11.jsonl`
Pinned: codex-cli 0.125.0
Date triaged: 2026-05-11

## Classification distribution

| Class | Count | % |
|---|---:|---:|
| blocker | **0** | 0% |
| workaround-needed | **6** | 20% |
| informational | **7** | 23% |
| out-of-scope | **17** | 57% |
| **Total** | 30 | 100% |

## Triage table

| # | Title (summary) | Class | Flywheel-impact-cite / Memory anchor |
|---|---|---|---|
| 22028 | fast mode has disappeared [TUI, app] | informational | TUI feature regression. Joshua's /fast mode is documented in CLAUDE.md; if it fully disappears in a future release, flagged. Currently informational. |
| 22032 | Support Cmd+Up/Cmd+Down keyboard | informational | enhancement-request; not affecting orchestration |
| 22034 | Chinese UI /pet inconsistency | out-of-scope | i18n localization; fleet runs in en-US |
| 22037 | TUI /resume picker blocks on global rollout scan | **workaround-needed** | Affects orch pane when /resume invoked. Memory anchor: `feedback_chevron_visible_does_not_mean_submits_work` (chevron-state-vs-actual-work). The session-resume hang class IS observed in flywheel. Workaround: use canonical-cli respawn instead of /resume on hung panes. |
| 22040 | Codex CLI burns subscription tokens repeatedly checking /status | **workaround-needed** | Direct fleet concern — flywheel orch pane invokes /status patterns. Memory anchor: `feedback_caam_swap_then_respawn_for_usage_limit` (when codex panes show "usage limit" → swap caam profile + respawn). The token-burn class makes this even more important; don't repeat /status under low-quota. |
| 22041 | Hybrid Local/Cloud Instant Models | informational | enhancement-request; not affecting orchestration |
| 22044 | [Windows] Restricted-token sandbox | out-of-scope | Windows-only; fleet is macOS Apple Silicon |
| 22049 | macOS app native /goal | out-of-scope | Desktop app feature; CLI is fleet substrate |
| 22050 | Windows taskkill leaks into TUI | out-of-scope | Windows-only |
| 22053 | Codex Desktop 280% CPU on macOS | out-of-scope | Desktop app, not CLI |
| 22056 | ANSI background colors dropped | informational | TUI rendering; doesn't affect dispatch packets |
| 22067 | Idle output leaks into input | **workaround-needed** | Could affect orch pane (idle output → next-prompt contamination). Memory anchor: `feedback_ntm_rotate_stdin_contamination_use_respawn_path` (canonical fleet rotation = respawn, never `ntm rotate` directly). Stdin contamination class. Workaround: never type into a pane mid-output; use respawn path. |
| 22071 | False positive cybersecurity warning [Windows] | out-of-scope | Windows-only |
| 22072 | MCP startup_timeout doesn't cover pre-init OAuth | **workaround-needed** | MCP timeout affects mcp-agent-mail (uses MCP). Memory anchor: `feedback_agent_mail_token_echo` + `reference_agent_mail_service` (AM at ~/.local/share/mcp_agent_mail). If startup_timeout fires before OAuth completes, agent-mail won't respond — fleet observed pattern. Workaround: pre-init OAuth tokens before agent-mail uses MCP. |
| 22074 | Mermaid erDiagram dark mode | out-of-scope | Desktop app rendering |
| 22075 | Desktop project rename leaves stale metadata | out-of-scope | Desktop app |
| 22081 | Process termination messages over input box [Windows] | out-of-scope | Windows-only |
| 22082 | MacBook 2019 pro intel codex app UI | out-of-scope | Intel mac + Desktop app |
| 22087 | PHPStorm/JetBrains terminal arrow keys [Windows] | out-of-scope | Windows + JetBrains |
| 22089 | Codex CLI stream disconnects (hatch-pet imagen workflow) | **workaround-needed** | CLI stream disconnect class — directly relevant to long-running orch workers. Memory anchor: `feedback_post_callback_stale_chevron_input_deaf_class` (route stale chevron/input-deaf states through existing recovery families first). Workaround: post-disconnect respawn + callback re-send. |
| 22091 | Codex Desktop context bloats | out-of-scope | Desktop app |
| 22096 | Codex desktop Plugins page macOS Intel | out-of-scope | Desktop + Intel |
| 22098 | Codex refers to git state as worktree | informational | model behavior; downstream consumer's interpretation |
| 22101 | `/side` inherits unexpected model | **workaround-needed** | /side affects orch context-switching when /side is invoked. Model-inheritance bug class. Memory anchor: `feedback_chevron_visible_does_not_mean_submits_work` (model-mismatch can produce silent stalls). Workaround: explicitly set /model in /side. |
| 22104 | Chrome plugin setupAtlasRuntime hangs | out-of-scope | Chrome plugin not CLI |
| 22107 | Codex Desktop compaction fails | out-of-scope | Desktop app |
| 22108 | Codex Desktop browser-use hangs | out-of-scope | Desktop app |
| 22120 | git-branch status_line on Windows worktree | out-of-scope | Windows-only |
| 22121 | iTerm2 tab title rename feature | informational | enhancement-request |
| 22123 | /title slash command sent to model | informational | minor TUI; /title is rarely used in flywheel workflows |

## Workaround-needed details (5 patterns with flywheel impact)

### 22037 — /resume picker blocks on global rollout scan
- **Class**: hang
- **Affected flywheel pattern**: pane-recovery when /resume is invoked on a hung session
- **Existing workaround**: canonical-cli respawn (per `feedback_ntm_rotate_stdin_contamination_use_respawn_path`)
- **Net signal**: don't introduce /resume into flywheel-tick workflows; keep respawn canonical
- **Action**: no new bead; signal already covered by existing respawn doctrine

### 22040 — /status token burn
- **Class**: token-economy / rate-limit
- **Affected flywheel pattern**: orch pane /status invocations under low-quota
- **Existing workaround**: caam-swap + respawn (per `feedback_caam_swap_then_respawn_for_usage_limit`)
- **Net signal**: avoid repeated /status calls; rate-limit /status in orch loop
- **Action**: no new bead; existing caam-swap pattern covers the remediation

### 22067 — Idle output leaks into input
- **Class**: stdin contamination
- **Affected flywheel pattern**: orch pane next-prompt contamination after idle
- **Existing workaround**: respawn over rotate (per `feedback_ntm_rotate_stdin_contamination_use_respawn_path`)
- **Net signal**: confirms the respawn-vs-rotate doctrine is correct upstream
- **Action**: no new bead; existing doctrine covers

### 22072 — MCP startup_timeout pre-init OAuth
- **Class**: MCP timeout
- **Affected flywheel pattern**: mcp-agent-mail startup with saved tokens
- **Existing workaround**: pre-init OAuth via direct service ping before MCP-using-code invokes it
- **Net signal**: agent-mail OAuth needs warm-up; flywheel-tick should not assume cold-start works
- **Action**: defer — current flywheel doesn't appear to cold-start agent-mail under this path; if observed, file then

### 22089 — Stream disconnect on long workflow
- **Class**: connectivity / long-running worker
- **Affected flywheel pattern**: long codex worker dispatches that exceed N minutes
- **Existing workaround**: stale-chevron recovery class (per `feedback_post_callback_stale_chevron_input_deaf_class`)
- **Net signal**: long workers DO disconnect; canonical recovery is respawn + callback re-send
- **Action**: no new bead; existing recovery family covers

### 22101 — /side inherits unexpected model
- **Class**: model-inheritance / context-switch
- **Affected flywheel pattern**: orch context-switching (e.g., side conversations for research)
- **Existing workaround**: explicit /model in /side invocations
- **Net signal**: /side context model is non-deterministic upstream; flywheel doesn't currently use /side in tick path
- **Action**: no new bead; orch tick doesn't use /side

## Net AG outcome

- **AG1 classify**: 30/30 ✓
- **AG2 cite flywheel pattern**: 6 workaround-needed each cite a memory anchor + existing pattern ✓
- **AG3 produce triage-table.md**: this file ✓
- **AG4 file follow-on bead**: NONE — 0 blockers; all 6 workaround-needed are covered by existing memory rules + recovery patterns. No new flywheel-orch action required.

## Flywheel-orch-action-required: none

All 6 workaround-needed items map to existing memory rules + recovery patterns. The codex upstream issues are confirming patterns flywheel already mitigates via its own respawn/caam-swap/recovery-family doctrine. No new bead required.

If any of these issues escalate (e.g., codex upstream fixes one and changes contract), re-triage at that time.
