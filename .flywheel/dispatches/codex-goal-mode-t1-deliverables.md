codex /goal-mode 4-layer enforcement — flywheel T1+0..24h deliverables (flywheel-701fi + flywheel-rrrqk)

CONTEXT: Joshua-RATIFIED 2026-05-20T00:25Z (T1). Joint codesign packet: .flywheel/handoffs/20260520T0020Z-joint-from-skillos-flywheel-to-joshua-codex-goal-mode-4layer-enforcement.md. Quote: "yes proceed - make sure that you both know how to do this and get it fucking settled system wide". Both fleets had stalled codex panes; this sprint is the first ratified work to lift the stall + start propagation.

THIS SPRINT = 2 paired beads in single dispatch (T1+0..24h flywheel side):
1. flywheel-701fi: polling probe primitive (Layer 2/3/4 monitor)
2. flywheel-rrrqk: /flywheel:dispatch integration with the probe

SPECS ALREADY WRITTEN (paper-only, ratified):
- .flywheel/specs/codex-goal-mode-monitor-probe.md (probe primitive design)
- .flywheel/specs/codex-goal-mode-bypass-design.md (bypass hatch design)
Both contain implementation Qs you should resolve during socraticode + before coding.

DELIVERABLES:

A. .flywheel/scripts/codex-goal-mode-monitor-probe.sh
- Implements spec at .flywheel/specs/codex-goal-mode-monitor-probe.md
- Flags: --pane (int) --dispatch-id (str) --layer (2|3|4) --max-entry-wait-s (default 30) --persistence-poll-interval-s (default 60) --flap-threshold (default 3) --flap-window-s (default 300) --respawn-residue-s (default 15) --completing-window-s (default 5) --json --dry-run
- Reads pane state via tmux capture-pane (canonical method; do NOT call ntm --robot-activity for this — codex pane state needs the visible Goal-box text)
- Implements 8-state classifier per the taxonomy table:
  goal-in-progress / goal-paused / goal-completing / goal-completed / idle-chat / working-non-goal / error-state / respawn-residue
- Detection regex CAUTION: codex text format may evolve. Use loose-tolerance regex with explicit "fall through" logging when no state matches → classify as "unknown" + emit telemetry for skillos canonical-detector lane to absorb back
- Emits trauma envelope per spec to ~/.flywheel/evidence/codex-goal-mode-trauma.jsonl
- Exit codes: 0=OK, 1=trauma fired, 2=defer (respawn-residue/completing-window), 3=unknown-state

B. .flywheel/scripts/codex-goal-mode-monitor-daemon.sh
- Layer 3 daemon-loop wrapper: reads dispatch-log.jsonl, finds in-flight rows (dispatch-ts present, callback-ts absent), invokes probe --layer 3 for each
- Polls every --interval-s (default 60s)
- Idempotent: re-invocation does NOT double-fire trauma for same state-window
- State-history persisted at ~/.flywheel/state/codex-goal-mode-monitor/state-history-{dispatch_id}.jsonl

C. .flywheel/scripts/codex-goal-mode-monitor-install.sh
- Idempotent installer: writes launchd plist for daemon at ~/Library/LaunchAgents/ai.zeststream.codex-goal-mode-monitor.plist
- Pattern: SHA-match to existing bridge daemon plist for symmetry

D. .flywheel/scripts/flywheel-dispatch-wrapper.sh (rename if exists OR write new)
- Wraps ntm send pattern: PreToolUse hook fires (czwpu Layer 1) → ntm send → probe --layer 2 in background → write dispatch-log.jsonl row with monitor_probe_id field → daemon picks up next cycle (Layer 3) → callback triggers Layer 4
- Use this from /flywheel:dispatch skill (do NOT modify the skill in this sprint — wire-in scope is just the wrapper script + dispatch-log schema extension)

E. Bypass hatch
- Single env var: CODEX_GOAL_FORMAT_BYPASS=<reason>
- Already exists for Layer 1 (czwpu) — extend probe to consult ~/.local/state/codex-goal-mode-bypass-audit.jsonl for matching bypass row before firing Layer 2-4 trauma
- Audit row written by /flywheel:dispatch wrapper when CODEX_GOAL_FORMAT_BYPASS env var present at dispatch-time
- Schema: codex_goal_mode_bypass_audit.v1 per .flywheel/specs/codex-goal-mode-bypass-design.md

F. tests/codex-goal-mode-monitor-probe-smoke.sh
- 8+ assertions covering all 5 trauma classes:
  1. Layer 2: goal-in-progress detected within 30s → exit 0
  2. Layer 2: idle-chat at 30s deadline → fires codex-goal-entry-failed
  3. Layer 3: goal-paused for 120s → fires codex-goal-resume-stuck
  4. Layer 3: mode-regression mid-dispatch → fires codex-goal-abandoned
  5. Layer 3: 3 entry↔pause transitions in 240s → fires codex-goal-mode-flapping
  6. Layer 4: callback without ever showing goal-in-progress → fires codex-goal-mode-bypassed
  7. respawn-residue window suppresses classifiers for <15s post-respawn
  8. CODEX_GOAL_FORMAT_BYPASS=test-reason suppresses Layer 2-4 trauma + writes audit row
- Use mock tmux pane scrollback fixtures under tests/fixtures/codex-goal-mode/ for each state

G. tests/flywheel-dispatch-wrapper-smoke.sh
- 4+ assertions:
  1. Dispatch with valid /goal prefix writes monitor_probe_id field to dispatch-log row
  2. Layer 2 probe fires in background within 30s post-dispatch
  3. Layer 3 daemon picks up the dispatch on next poll cycle
  4. Callback write triggers Layer 4 synchronously

H. dispatch-log.jsonl schema extension
- Add field: monitor_probe_id (UUID, optional, present only for codex pane dispatches)
- Add field: goal_mode_trauma_fired (array of trauma class ids, optional)
- Document in .flywheel/doctrine/dispatch-log-schema-v2.md (new doc, schema v2 marker)
- Backward compat: existing rows without these fields treated as legacy/non-monitored

ACCEPTANCE:
- All 5 scripts ship (probe, daemon, install, wrapper, smoke fixtures)
- shellcheck PASS on all bash scripts
- Smoke fixtures pass (8+4 assertions all green)
- Daemon launchd plist installed locally + verified running
- Dispatch a synthetic /goal probe through the wrapper, verify Layer 2 fires within 30s
- Dispatch a synthetic non-goal probe (CODEX_GOAL_FORMAT_BYPASS=test) verify bypass audit row written
- 2 beads closed: flywheel-701fi + flywheel-rrrqk
- ZERO modifications to existing czwpu Layer 1 hook (no contract surface change)
- ZERO modifications to claude/CC pane handling (rule is codex-specific)

LOOP CONTRACT (DEEP-WORK):
- Track 3 only.
- mcp-agent-mail file_reservation_paths before edits.
- socraticode K>=10 with 2 phrasings on existing pane-work-signal patterns + bridge daemon plist + czwpu hook pattern + dispatch-log.jsonl schema.
- DEEP-WORK validate: shellcheck + smoke fixtures + 1 synthetic dispatch dry-run through the wrapper.
- Bridge daemon LIVE — auto-routes callback. Belt+suspenders: explicit ntm send flywheel --pane=1.
- SCR event: C7_verification_density (new monitoring layer).
- STOP on Track 1/2 breach, BLOCKED, agent-mail loop fail (skip+exit do NOT loop), >8h hard cap (this is a bigger sprint than usual; budget accordingly).
- DO NOT propose fleet-wide install in this sprint — skillos:1 owns fleet propagation (T1+48..72h).

PHASE BOUNDARY: This sprint = 2 paired beads (probe primitive + dispatch integration). On completion REMAIN IDLE. Skillos:1 is on parallel track (taxonomy spec + reference impl + 5 trauma class doctrine, all T1+0..24h skillos-side); coordinate via cross-orch handoffs at .flywheel/handoffs/ if interface mismatch surfaces.

PHRASING: "scoped to T1+0..24h flywheel polling probe primitive + dispatch integration" framing.

FIRST ACTION:
1. br show flywheel-701fi flywheel-rrrqk (both beads).
2. Read .flywheel/specs/codex-goal-mode-monitor-probe.md + .flywheel/specs/codex-goal-mode-bypass-design.md end-to-end.
3. Read .flywheel/handoffs/20260520T0020Z-joint-from-skillos-flywheel-to-joshua-codex-goal-mode-4layer-enforcement.md for ratified design.
4. ACK row.
5. socraticode existing patterns.
6. Implement 5 scripts + 2 smoke fixtures + schema extension doc.
7. Self-validate.
8. Commit + close both beads + DIRECT pane-1 ntm send + truth-verify status=closed.

Go.
