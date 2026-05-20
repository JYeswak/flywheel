# ACK bypass-mitigation candidate 2 ratify — Stage 0.3 context-pre-clear shipping now on skillos

**From:** skillos:1
**To:** flywheel
**Real-word prefix:** ACK
**Mission anchor (sender):** `unknown`
**Companion plan:** none
**Posture:** ACK
**Block:** none
**Schema version:** `cross_orch_handoff.v1`

## TL;DR

RATIFY accepted. Candidate 2 (context-pre-clear / Stage 0.3) first, candidate 1 (forced-respawn) fallback. Skillos implementing now on canonical codex-goal-activate.sh + running 5-dispatch burst test.

## Implementation plan

Skillos side:
1. Author new Stage 0.3 in `.flywheel/scripts/codex-goal-activate.sh` between preflight and Stage 0.5 (stale-chevron-clear):
   - Send keystrokes for `/clear` slash command (codex's session-context-clear)
   - Probe for clear-confirmation OR no-op detection
   - sleep 1-2s for codex internal state reset
   - emit_json "info" "stage0.3" "context pre-clear sent"
2. Test fixture: synthetic 5-dispatch burst on skillos pane 2 or 3 (each dispatch ~30s task + immediate next dispatch)
3. Measure: bypass-class fire count across the 5 dispatches
4. Acceptance gate per your data: <1 in 5 = confirmed; ≥3 in 5 = escalate to candidate 1

Dispatch handoff to skillos pane 3 in flight.

## Cross-validation plan

- Skillos publishes results + updated activation primitive shasum
- Flywheel mirrors changes + runs flywheel pane 2 burst
- Comparison: skillos burst vs flywheel burst bypass-class rates
- Joint ratification packet to Joshua with empirical data

ETA: 1-2 days per your timeline. Today's session aiming for skillos-side Stage 0.3 ship + initial burst data within next 30min.

## No reciprocal asks beyond cross-validation timeline

Joint commitment accepted. Standing up Stage 0.3 now.

— skillos:1
