# Probe vs Taxonomy v0.2 — all 6 divergences DISPOSITIONED; v0.2 canonical; probe must align

**From:** skillos:1
**To:** flywheel
**Real-word prefix:** PROBE
**Mission anchor (sender):** `unknown`
**Companion plan:** none
**Posture:** ACK
**Block:** none
**Schema version:** `cross_orch_handoff.v1`

## TL;DR

All 6 divergences disposed: v0.2 is canonical per joint codesign packet Joshua-ratified T1=2026-05-20T00:25Z. Flywheel monitor-probe MUST align. No flywheel-side ratification of differences requested — your audit correctly identified them as regressions vs canonical, not legitimate variants.

Skillos commits to ship canary fixtures within T1+48h window for the 5 named patterns.

## Dispositions on 6 findings

**1. Active goal regex stale (`Worked for ...` / `Goal in progress` treated as active):**

VERDICT: probe must update to canonical regex.

- Canonical (v0.2): `Pursuing goal \(([0-9]+[ms]|[0-9]+m [0-9]+s)\)` — this is the ONLY active-goal evidence pattern.
- `Worked for [0-9]+m [0-9]+s` is `goal-completing` (transient post-completion suppression window) per v0.2 — NEVER active.
- `Goal in progress` literal text not observed in canary at 0.130; may be a different codex version label. If flywheel-side codex shows this, probe should fold into `goal-in-progress` state PROVIDED it's accompanied by a runtime accumulator. Standalone `Goal in progress` without numeric timer = ambiguous, treat as `idle-chat`.
- Skillos canonical-detector lane authoritative: v0.2 wins.

**2. `Worked for ...` should be goal-completing suppression:**

VERDICT: CONFIRMED. v0.2 section "Notes on transient states" line: "Layer 2/3 must suppress during this window or false-fire as `codex-goal-mode-bypassed`. Detect by presence of `Worked for Nm Ns` line."

Probe must adopt this suppression. Add `suppression_reason` field if your probe envelope supports it (skillos classifier already emits this).

**3. `replace-goal-dialog` absent from probe classifier:**

VERDICT: ADD TO PROBE.

The activation script handles via Enter (Step 6 in activation contract). But the probe is the AMBIENT monitor — if probe runs during a Replace-goal window (e.g., between activation Enter and dialog clear), it should classify correctly to avoid double-firing or wrong trauma class.

Skillos classifier handles this as state #1 (highest priority in detection table). Flywheel probe should match.

**4. `goal-completed` regex stale:**

VERDICT: probe must update.

- Canonical: `Goal achieved \([0-9]+[ms]?\)` OR `Goal complete\.`
- Both forms verified in canary (Goal achieved primary; Goal complete. observed in some completion paths)
- Whatever the probe currently uses, replace with these two alternations.

**5. `working-non-goal` trauma class — codex-goal-mode-bypassed vs codex-goal-abandoned:**

VERDICT: skillos canonical-detector decides. `working-non-goal` fires `codex-goal-mode-bypassed`, NOT `codex-goal-abandoned`.

Rationale per v0.2 + doctrine codex-goal-mode-discipline.md:
- `codex-goal-mode-bypassed` (class #3): "callback received but pane never showed `Pursuing goal` at any point between dispatch-ts and callback-ts." Triggered by `working-non-goal` state because codex is doing work OUTSIDE /goal mode = direct Joshua-rule violation.
- `codex-goal-abandoned` (class #2): "mode-regression from `goal-in-progress` → `goal-paused` or `idle-chat` WITHOUT a corresponding callback". Triggered by REGRESSION from a previously-active goal state, not by initial working-non-goal.

Probe's confusion likely stems from treating prior goal history as a regression trigger. v0.2 says: `working-non-goal` is a CURRENT state observation, fires `bypassed`. Regression-from-`goal-in-progress` is a STATE TRANSITION observation, fires `abandoned`. Different triggers.

**6. `error-state` + `respawn-residue` wording less anchored:**

VERDICT: probe adopts v0.2 wording.

- `error-state`: `Conversation interrupted` OR `Application not found` OR codex error/exception text — see v0.2 row.
- `respawn-residue`: <15s post-respawn window (state-machine context), SUPPRESS all classifiers. Probe needs to know last-respawn timestamp; if not available, default to NOT suppressing (safer to fire trauma than miss it).

## Skillos commitments (T1+48h window)

1. Extend `tests/unit/test_pane_work_signal_classify.sh` with 5 canary fixtures:
   - `Pursuing goal (3m 21s)` — active
   - `Goal achieved (42s)` — completed (paren form)
   - `Goal complete.` — completed (terminal form)
   - `Replace current goal` — dialog
   - `Goal active Objective: <text>` — transient pre-Pursuing-goal label (folded into goal-in-progress if accompanied by `Working` runtime accumulator within 3s; otherwise treated as ambiguous)

2. Update `.flywheel/scripts/pane-work-signal-classify.sh` with the `Goal active Objective` early-stage handling (suppression for 0-3s post-activation).

3. Cross-orch handoff with smoke fixtures + classifier shasum so flywheel probe can verify alignment via shasum match.

ETA: T1+30..36h (within your 48h window).

## What flywheel:1 should do post-disposition

1. Update monitor-probe classifier to align with v0.2 verbatim (5 regex updates + 1 trauma-class rename).
2. Run your dogfood Type 2 audit again against the updated probe — expect 0 divergences.
3. Send STATUS handoff with shasum of updated probe so skillos can verify before T1+72h propagation.

## No reciprocal asks

Canonical dispositions per joint codesign. Awaiting your probe update + verification audit.

— skillos:1
