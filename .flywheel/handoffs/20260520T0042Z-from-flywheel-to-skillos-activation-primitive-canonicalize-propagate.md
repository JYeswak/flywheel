Cross-orch row: flywheel:1 -> skillos:1
ts: 2026-05-20T00:42Z
re: Codex /goal activation primitive + /flywheel:dispatch lock-in
subject: CANONICALIZE — activation primitive ready for skillos absorption + fleet propagation
posture: REQUEST
block: none
schema_version: cross_orch_handoff.v1

JOSHUA-DIRECT: "lock this into /flywheel:dispatch and get skillos on the same page"

LOCKED IN flywheel-side (commit pending push):
- .flywheel/scripts/codex-goal-activate.sh — 7-step canonical activation primitive
  Mechanism: keystroke /goal → primed-blue probe → leading space → tmux paste-buffer -p (BRACKETED) → Enter → Replace-goal-dialog handler → Pursuing-goal verify
  shellcheck PASS. End-to-end canary verified at 14s Goal achieved.
  Handles paused/active/idle pre-flight states; classifier matches v0.2 taxonomy regexes.

- ~/.claude/commands/flywheel/dispatch.md — UPDATED with CODEX-VS-CLAUDE TRANSPORT BRANCH:
  Codex panes → codex-goal-activate.sh (short-directive-plus-payload-file pattern)
  Claude/CC panes → raw ntm send (no slash palette in their input)
  AGENT_TYPE detection from existing session-topology read; backward compatible.

T1+0..24h flywheel work shipped via this primitive (proves end-to-end):
- flywheel-701fi closed (probe primitive + 5 trauma classes + 8-state classifier)
- flywheel-rrrqk closed (/flywheel:dispatch wrapper + dispatch-log v2 schema)
- 6 scripts shipped: probe (15758b) + daemon (4161b) + installer (3842b) + wrapper (7277b) + 2 smoke fixtures
- Commits cf6fec64 + 9d3fa3fc
- Codex pane 2 STAYED IN Pursuing-goal state for entire 13min work window

ASKS — your canonicalization track (T1+0..24h skillos-side already in motion):

1. ABSORB .flywheel/scripts/codex-goal-activate.sh into JSM canonical as the
   codex-goal-mode-activation skill (single source of truth for fleet).
   Source at flywheel commit pending push (review/flywheel-2.0-private-20260513).

2. PROPAGATE the dispatch-skill update across the 8-orch fleet:
   - skillos:1 /skillos:dispatch (if exists, parity update)
   - mobile-eats:1 /goal-format hook (extend with activation primitive call-path)
   - picoz + clutterfreespaces + alps + vrtx + terratitle dispatch surfaces
   - Per ratified T1+48..72h propagation phase

3. UPDATE pane-work-signal v0.2 taxonomy regexes with canary-verified set:
   - goal-in-progress: Pursuing goal \(([0-9]+[ms]|[0-9]+m [0-9]+s)\)
   - goal-completed: Goal achieved \([0-9]+[ms]?\) OR Goal complete\.
   - replace-goal-dialog: Replace current goal literal
   - All 3 are CONFIRMED via canary, supersede the joint codesign packet guesses

4. INCLUDE bracketed-paste fact in your codex-goal-mode-discipline.md doctrine:
   "tmux paste-buffer -p (bracketed paste) is REQUIRED. Without -p, codex's
   slash-command palette eats every / char in pasted content → file paths
   corrupt + Conversation-interrupted class fires."

5. CONFIRM 4 ratified trauma classes still apply correctly with the new
   activation primitive in place. The 5th class (codex-goal-mode-flapping) is
   especially relevant — entry↔pause transitions during a Pursuing-goal session
   would indicate prompt structure problem, not activation problem.

NEW SUBSTRATE OBSERVATION (for your trauma corpus):
Pane 2 finished T1 work + entered ghost-stall state at 13m52s ("Waiting for background terminal"). This is the EXACT class your skillos-6tf9x classifier covers. The new flywheel codex-goal-mode-monitor-probe should also detect this — your Layer 3 monitor and your ghost-stall classifier converge here. Worth confirming the two don't double-fire trauma on same evidence.

— flywheel:1
