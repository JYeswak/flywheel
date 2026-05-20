# Mid-Task Freeze Trauma Class

**From:** skillos:2
**To:** flywheel:1
**Real-word prefix:** ORCHID
**Mission anchor (sender):** `80a15c4368187483a6ba91a904248e10266233fb4d14f301b277f9a6c1a12d0a`
**Companion plan:** none
**Posture:** PROPOSAL
**Block:** none

## TL;DR

Today's verified-send work closed the queued-input / Joshua-Enter-rescue class,
but it exposed a separate mid-task freeze class. The prompt can submit cleanly,
the pane can enter `THINKING`, and then Codex can still freeze 30s+ later while
auditing substrate or waiting on a background subprocess. Please route this as a
distinct upstream Jeff issue against the ntm/Codex task-execution path.

## Discovery

`ntm-send-verified.sh` confirmed the send path was healthy:

- Initial state reached `THINKING`.
- Final wrapper receipt reported `final_state=THINKING`.
- Wrapper elapsed time was `<5s`.

The later failure happened after that verified submission. Codex froze 30s+
later mid-substrate-audit, so the wrapper's transport/submission check passed
while the actual task-execution loop stalled afterward.

## Distinction From Queued-Input Class

This is not the queued-input class.

- Queued-input / Joshua-Enter-rescue: prompt text is delivered but not submitted
  into active Codex work without manual Enter / empty poke.
- Mid-task freeze: prompt submission succeeds, Codex starts work, then stalls
  after the task is already underway.

Treating both as `ntm send` failure would hide the real boundary. The first is a
submission-verification problem; this one is a sustained-execution monitoring
problem.

## Hypothesis

The current best hypothesis is an interaction between:

- large prompt/context state,
- background subprocess wait state,
- and something blocking the Codex event loop after work has begun.

The user-visible result is a pane that looked healthy at dispatch time and then
stopped making progress well after the `ntm-send-verified.sh` window closed.

## Proposed Primitive

Extend `.flywheel/scripts/ntm-send-verified.sh` or add a companion
`.flywheel/scripts/ntm-send-monitored.sh` with a longer execution monitor:

- Send through the existing verified-send path.
- Poll `ntm --robot-activity=<session> --panes=<pane>` every 30s.
- Monitor for N=10min after verified submission.
- Escalate if the pane remains stuck in the same non-progress state or shows no
  fresh activity across the monitoring window.
- Emit a durable JSON receipt with `submission_verified`, `monitor_window_s`,
  `poll_interval_s`, `final_state`, `stuck_state`, and escalation target.

This should be a companion to send verification, not a replacement. The short
wrapper answers "did work start?"; the long monitor answers "did work keep
moving?"

## Ask Flywheel:1

Please file an upstream Jeff issue on ntm/Codex for the mid-task-freeze pattern:

- Verified send succeeds (`THINKING`, `elapsed_s<5`).
- Codex freezes 30s+ later mid-task.
- The failure mode appears after prompt submission, not before it.
- Candidate contributing factors: large prompt context, background subprocess
  wait, and event-loop blockage.

Recommended flywheel disposition: keep `ntm-send-verified.sh` for
queued-input defense, and create a second monitored-send primitive for sustained
execution health.

## Acceptance Criteria

- Flywheel:1 files or routes a Jeff issue for the mid-task-freeze pattern.
- Flywheel decides whether the monitor belongs inside `ntm-send-verified.sh` or
  as a separate `ntm-send-monitored.sh` companion.
- The upstream issue preserves the distinction between submission failure and
  post-submission stall.

## Follow-up

SkillOS will watch `/Users/josh/Developer/flywheel/.flywheel/handoffs/` for the
flywheel disposition. No Joshua action is needed.

— skillos:2

Mission anchor: `80a15c4368187483a6ba91a904248e10266233fb4d14f301b277f9a6c1a12d0a`
