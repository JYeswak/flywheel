# flywheel-zynit — Fix flywheel-dispatch-wrapper.sh to use codex-goal-activate.sh

## Context

T1+0..24h shipped `.flywheel/scripts/flywheel-dispatch-wrapper.sh` (7277 bytes) which monitors goal-mode via Layer 2/3/4 probe BUT the dispatch transport itself still uses raw `ntm send`. This means:
- Raw `ntm send` pastes content unbracketed → codex slash-command palette eats every `/` char
- The probe immediately fires `codex-goal-entry-failed` trauma on every dispatch because goal-mode never enters
- The canonical fix exists in `~/.claude/commands/flywheel/dispatch.md` (the slash command itself) and `.flywheel/scripts/codex-goal-activate.sh` (the activation primitive)

## Deliverable

Fix `.flywheel/scripts/flywheel-dispatch-wrapper.sh` to:

1. Replace the raw `ntm send` call site with invocation of `.flywheel/scripts/codex-goal-activate.sh` for codex panes
2. Use `AGENT_TYPE` detection from session-topology.jsonl (already wired in wrapper at line ~13)
3. For codex panes: short-directive-plus-payload-file pattern — task body written to `.flywheel/dispatches/codex-${TASK_ID}.md`, short directive points at it
4. For claude/CC panes: keep raw ntm send (no slash palette in their input)
5. Preserve all existing telemetry: dispatch-log row, Layer 2 probe spawn in background, callback fields

## Tests

Extend `tests/flywheel-dispatch-wrapper-smoke.sh`:
1. New assertion: synthetic codex dispatch verified Pursuing-goal state achieved within 30s (use Layer 2 probe in foreground mode)
2. New assertion: synthetic claude/CC dispatch uses raw ntm send (no activation primitive call)
3. Existing 4 assertions stay PASS

## Acceptance

- Wrapper uses codex-goal-activate.sh for codex panes
- Wrapper still uses ntm send for claude/CC panes
- shellcheck PASS
- Smoke fixture: 6+ assertions all PASS
- Probe via wrapper now produces Pursuing-goal state, NOT codex-goal-entry-failed trauma
- Bead flywheel-zynit closed

## Loop contract

- Track 3 only
- mcp-agent-mail file_reservation_paths before edits
- Bridge daemon LIVE — auto-routes callback. Belt+suspenders: ntm send flywheel --pane=1.
- SCR event: C7_verification_density
- STOP on Track 1/2 breach, BLOCKED, agent-mail loop fail, >2h hard cap
- DEEP-WORK: validate (smoke + 1 live wrapper dispatch dry-run that verifies Pursuing goal), clean tree, flag scope creep

## FIRST ACTION

1. br show flywheel-zynit.
2. Read .flywheel/scripts/flywheel-dispatch-wrapper.sh end-to-end.
3. Read .flywheel/scripts/codex-goal-activate.sh end-to-end.
4. Read ~/.claude/commands/flywheel/dispatch.md (look for CODEX-VS-CLAUDE TRANSPORT BRANCH section — that's the canonical pattern to mirror).
5. ACK row.
6. Edit wrapper. Extend smoke. Self-validate.
7. Commit + close bead + DIRECT pane-1 ntm send + truth-verify status=closed.
