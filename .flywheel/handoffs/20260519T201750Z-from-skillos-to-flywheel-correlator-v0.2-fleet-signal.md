# Correlator v0.2 Fleet Signal

**From:** skillos:3
**To:** flywheel:1
**Real-word prefix:** SIGNAL
**Mission anchor (sender):** `77e4c703`
**Companion plan:** `/Users/josh/Developer/skillos/state/respawn-pattern-analysis-20260519T195754Z.md`
**Posture:** PROPOSAL
**Block:** none

## TL;DR

SkillOS shipped and verified the Codex freeze correlator v0.2 signal stack. The
live `recurring_today` field now exposes three same-day recurring pane pairs:
`skillos:3`, `clutterfreespaces:3`, and `picoz:2`. The repeated shape points to
queued-input / send-verification failure as the prevention lane, so I recommend
flywheel:1 mirror `ntm-send-verified.sh` adoption to clutterfreespaces and
picoz next.

## Live Correlator Evidence

Source:
`/Users/josh/.local/state/flywheel/codex-freeze-correlator-latest.json`

Current recurring pairs:

| Session | Pane | Respawns today | Primary cause | Secondary cause | Confidence |
|---|---:|---:|---|---|---|
| `skillos` | 3 | 5 | `unknown` | `queued-input` | high |
| `clutterfreespaces` | 3 | 3 | `queued-input` | none | medium |
| `picoz` | 2 | 2 | `picoz-cross-orch-clobber` | `queued-input` | low |

The current total is 12 same-day respawn rows. The older two-pair analysis
expanded after a new `picoz:2` respawn at 2026-05-19T20:13:06Z, which pushed
`picoz:2` over the `>=2/day` recurrence threshold.

## Cause Distribution

Primary cause labels across recurring pairs are split 1/1/1:

- `queued-input`: `clutterfreespaces:3`
- `unknown`: `skillos:3`
- `picoz-cross-orch-clobber`: `picoz:2`

However, queued-input is present in all three recurring pairs when secondary
causes are included:

- `skillos:3`: secondary `queued-input`
- `clutterfreespaces:3`: primary `queued-input`
- `picoz:2`: secondary `queued-input`

That matches the Joshua-Enter-rescue pattern: transport looked accepted, but
work did not reliably start until the pane was manually rescued or respawned.

## Antidote

Adopt `.flywheel/scripts/ntm-send-verified.sh` fleet-wide for recurring victim
panes before further batch dispatches.

SkillOS evidence:

- `30c67038` — `feat(ntm): add verified send wrapper`
  - Adds `.flywheel/scripts/ntm-send-verified.sh`.
- `687e8e27` — `docs(ntm): record verified send smoke test`
  - Records `state/ntm-send-verified-smoke-20260519T195949Z.md`.

The wrapper is the right primitive because it turns `ntm send` from a
transport-only success into a verified send receipt. Fleet-wide adoption should
make queued prompts, visible-but-not-started prompts, and background-terminal
stalls observable before the orchestrator believes work is in flight.

## Substrate Stack Today

SkillOS now has a three-layer stack for this incident class:

1. `fleet-codex-health` observability records pane health and freeze symptoms.
2. `codex-freeze-correlator.sh` v0.2 folds health plus fuckup rows into
   recurrence signals, cause fields, malformed JSONL counts, and the root
   `recurring_today` field.
3. `ntm-send-verified.sh` prevents the dominant send-consumption class from
   silently becoming another respawn.

## Ask To flywheel:1

Please mirror the prevention primitive to the two cross-orch recurring victims:

| Target | Why | Proposed receiver action |
|---|---|---|
| `clutterfreespaces:3` | 3 same-day respawns; primary `queued-input`. | Require `ntm-send-verified.sh` or equivalent four-state receipt before new pane-3 dispatches. |
| `picoz:2` | 2 same-day respawns; cross-orch plus queued-input signature. | Require verified send plus `/Users/josh/Developer/flywheel/.flywheel/scripts/peer-orch-respawn-permit.sh` before further cross-orch recovery. |

`skillos:3` already has the local prevention path and should remain a proving
ground for the wrapper.

## Acceptance Criteria

- flywheel:1 acknowledges this handoff or mirrors the file into its active
  handoff queue.
- `clutterfreespaces` and `picoz` receive a receiver-local adoption path for
  verified send before the next recurring-pane dispatch.
- Future correlator output shows either no recurring pairs or recurring pairs
  with verified-send receipts attached before respawn.

## Provenance

- Correlator root field fix: `77e4c703`
- Correlator v0.2 implementation: `e70b1320`
- Recurring remediation report:
  `/Users/josh/Developer/skillos/state/recurring-pane-remediation-20260519T200515Z.md`
- Verified send wrapper: `30c67038`
- Verified send smoke receipt: `687e8e27`
- Recovery permit gate:
  `/Users/josh/Developer/flywheel/.flywheel/scripts/peer-orch-respawn-permit.sh`

— skillos:3

Mission anchor: `77e4c703`
