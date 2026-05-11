# ai.zeststream.flywheel-blocker-discipline-tick-chain

Hourly per-tick orchestration chain for blocker-discipline primitives in the
flywheel repo. Wires the chain shipped by `flywheel-yy9qi` into a launchd cadence
per `flywheel-tlclp`.

## What it runs

```
/Users/josh/Developer/flywheel/.flywheel/scripts/blocker-discipline-tick-chain.sh tick --apply --json
```

The chain sequences three independent stages (each idempotent; chain does NOT
halt on a stage failure):

1. `blocker-ac-tick-cadence.sh tick` — bumps tick counter; fires
   `flywheel_replay_verify --blocker-ac` on stale blockers at Nth-tick cadence
   (default `BLOCKER_DISCIPLINE_THRESHOLD_N=4` → replay-verify every 4 ticks =
   every 4 hours at our 3600s cadence).
2. `blocker-auto-close.sh scan` — for each open blocker whose AC passes,
   append `blocker_auto_closed` row + mutate blocker file to status=closed.
3. `blocker-fail-escalator.sh scan` — for each open blocker whose AC fails,
   increment per-blocker counter; on threshold reach, append
   `blocker_ac_failed_escalated` row and send Agent Mail (best-effort).

## Cadence

`StartInterval=3600` (hourly). RunAtLoad=false (don't fire on system boot or
launchctl bootstrap; first run waits for the first scheduled hour boundary).

Rationale: blocker discipline is steady-state hygiene, not urgent recovery. Per
`THRESHOLD_N=4` semantics, escalation kicks in after 4 hours of consecutive AC
failure — appropriate for "real" stuck blockers without flapping on transient
green→red flips.

## Environment

- `BLOCKER_DISCIPLINE_SKIP_AGENT_MAIL=1` — Agent Mail dispatch from
  fail-escalator is suppressed under launchd because no interactive identity
  is bound. The fail-escalator's audit log row is still appended to
  `.flywheel/state/escalations.jsonl`, and operator review surfaces via
  `blocker-discipline-tick-chain.sh audit`.

## Logs

- stdout: `~/.local/state/flywheel/blocker-discipline-tick-chain.out.log`
- stderr: `~/.local/state/flywheel/blocker-discipline-tick-chain.err.log`

JSON envelopes (one per run) accumulate on stdout. Inspect with:

```bash
tail -200 ~/.local/state/flywheel/blocker-discipline-tick-chain.out.log \
  | grep -E '^\{' \
  | tail -1 \
  | jq .
```

## Install

```bash
.flywheel/scripts/blocker-discipline-tick-chain-launchd-install.sh apply
```

The installer is canonical-cli (`doctor`/`health`/`validate`/`apply`/`unload`
subcommands). It symlinks this plist to `~/Library/LaunchAgents/` and runs
`launchctl bootstrap gui/$(id -u)` to activate.

## Uninstall

```bash
.flywheel/scripts/blocker-discipline-tick-chain-launchd-install.sh unload
```

## Probe (active state)

```bash
launchctl print gui/$(id -u)/ai.zeststream.flywheel-blocker-discipline-tick-chain \
  | grep -E 'state|last exit|next firing'
```

## Fleet propagation (deferred)

The blocker-discipline-tick-chain.sh primitive currently exists ONLY in the
flywheel repo. Sister fleet repos (alps, mobile-eats, skillos, vrtx) do not
yet have it; their `.flywheel/state/blockers/` directories are also absent
as of 2026-05-11. This bead (`flywheel-tlclp`) wires the flywheel-only
cadence; fleet propagation is captured in a sister bead filed at close time
(see `.flywheel/audit/flywheel-tlclp/evidence.md` Sister Beads section).

When chains ship to a fleet member, replicate this plist with the repo path
substituted, e.g. for alps:

```
Label: ai.zeststream.alps-blocker-discipline-tick-chain
ProgramArguments: cd /Users/josh/Developer/alpsinsurance; .flywheel/scripts/blocker-discipline-tick-chain.sh tick --apply --json
```

## Source beads

- `flywheel-yy9qi` (P1, CLOSED 2026-05-10) — shipped the chain script
- `flywheel-tlclp` (P2, this bead) — launchd wire-in
