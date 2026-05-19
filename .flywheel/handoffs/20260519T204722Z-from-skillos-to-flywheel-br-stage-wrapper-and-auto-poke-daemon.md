# BR Stage Wrapper And Auto-Poke Daemon

**From:** skillos:2
**To:** flywheel:1
**Real-word prefix:** MAPLE
**Mission anchor (sender):** `80a15c4368187483a6ba91a904248e10266233fb4d14f301b277f9a6c1a12d0a`
**Companion plan:** `skillos-etnn9`
**Posture:** PROPOSAL
**Block:** none

## TL;DR

SkillOS shipped two Joshua-flagged trauma responses today:
`.flywheel/scripts/br-stage-wrapper.sh` for Beads JSONL staging drift and
`.flywheel/scripts/codex-auto-poke-daemon.sh` for recurring queued-input rescue.
Please propagate both through the same fleet-package lane as the auto-push
4-tier stack after flywheel accepts package ownership.

## A. br-stage-wrapper (Option A) Shipped

- Primitive: `.flywheel/scripts/br-stage-wrapper.sh`
- Commit: `2eb08c16 feat(beads): add br staging wrapper`
- Contract: detects `br create`, `br close`, `br update`, `br comment`, and
  `br comments`; delegates via `command br "$@"`; after a successful mutating
  command, silently runs `git add .beads/issues.jsonl`; exits with the original
  `br` status.
- Validation: `bash -n .flywheel/scripts/br-stage-wrapper.sh`; wrapper test
  `bash .flywheel/scripts/br-stage-wrapper.sh comments add skillos-etnn9
  test-stage-wrapper-comment`; `git status` showed `.beads/issues.jsonl`
  staged.

This is flywheel Option A: make the CLI boundary stage the Beads export
immediately after known mutating commands instead of depending on humans or
workers to notice drift after the fact.

## B. codex-auto-poke-daemon Shipped

- Primitive: `.flywheel/scripts/codex-auto-poke-daemon.sh`
- Commit: `942e164f feat(daemon): codex-auto-poke for queued-input rescue`
- Contract: continuous 30s polling by default
  (`SKILLOS_AUTO_POKE_POLL_INTERVAL:-30`), scans Codex panes for queued-input /
  idle submit-rescue markers, and sends an empty `ntm send` poke only when the
  pane shape indicates pending input that needs submission.
- Trauma response: Joshua saw the Enter-rescue / queued-input class recur 10+
  times today. `ntm-send-verified.sh` closes the dispatch-time edge; this daemon
  covers the ambient interval after the dispatch wrapper has returned.

This is not a replacement for dispatch verification. It is the continuous
polling antidote for panes that later return to a queued-input / idle-submit
shape.

## C. Current Substrate Stack Coverage

| Trauma class | Current substrate response |
|---|---|
| Queued-input / Joshua-Enter-rescue | `.flywheel/scripts/ntm-send-verified.sh` at dispatch + `.flywheel/scripts/codex-auto-poke-daemon.sh` at 30s polling |
| Mid-task-freeze | `.flywheel/scripts/ntm-send-monitored.sh` long-poll monitor |
| Beads JSONL drift | `.flywheel/scripts/br-stage-wrapper.sh` Option A staging wrapper |
| Pane death / dead pane sweep | `.flywheel/scripts/pane-watchdog.sh` sweep |
| Fleet Codex health observability | `.flywheel/scripts/fleet-codex-health-tick.sh` plus launchd 60s health/stuck-detector surfaces |

The stack now covers both send-time and post-send failure modes:

- Did the prompt submit? `ntm-send-verified.sh`.
- Did the pane later need an Enter-rescue poke? `codex-auto-poke-daemon.sh`.
- Did the task stall after submission? `ntm-send-monitored.sh`.
- Did the pane die or go structurally unhealthy? `pane-watchdog.sh` and
  fleet-codex-health observability.
- Did Beads mutate outside the commit view? `br-stage-wrapper.sh`.

## D. Ask Flywheel:1

Please propagate both:

1. `.flywheel/scripts/codex-auto-poke-daemon.sh`
2. `.flywheel/scripts/br-stage-wrapper.sh`

through the same fleet-package lane as the auto-push 4-tier package. The
package already has a readiness shape under `state/auto-push-fleet-package/`;
these two primitives should travel with that rollout rather than becoming
manual per-repo copy/paste.

Recommended package additions:

- install paths for both scripts,
- repo-local enablement notes,
- launchd template or onboarding hook for `codex-auto-poke-daemon.sh`,
- shell alias/PATH guidance for `br-stage-wrapper.sh`,
- smoke checks proving queued-input poke and Beads JSONL staging behavior.

## Acceptance Criteria

- Flywheel decides whether these two primitives join the auto-push fleet package.
- If accepted, package docs include install + smoke instructions for both.
- The rollout preserves the distinction between dispatch-time verification,
  ambient queued-input rescue, mid-task freeze monitoring, and Beads staging
  discipline.

## Follow-up

SkillOS will watch `/Users/josh/Developer/flywheel/.flywheel/handoffs/` for a
disposition. No Joshua action is needed.

— skillos:2

Mission anchor: `80a15c4368187483a6ba91a904248e10266233fb4d14f301b277f9a6c1a12d0a`
