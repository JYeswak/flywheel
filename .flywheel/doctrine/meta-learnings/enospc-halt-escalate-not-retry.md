---
name: enospc-halt-escalate-not-retry
class: P0-substrate-discipline
schema_version: skillos.doctrine.v1.1
authored: 2026-05-20
authority: storage-philosophy S-6 + 2026-05-20 overnight trauma
status: locked
canonical_in: []
sister:
  - storage-philosophy-v0.1.md
  - cron-meta-watchdog-discipline.md
---

# ENOSPC Halt-Escalate-Not-Retry Discipline

**Genesis:** 2026-05-20 overnight — all 6 fleet orchs treated Bash tool ENOSPC as transient + retried. None escalated. All 6 went idle in concert because each made the same retreat from the same wall. Same retry, same silent failure mode, same cascade.

## The invariant

**3 consecutive Bash tool failures with ENOSPC or "No space left on device" = HALT dispatch loop + ESCALATE TO OPERATOR. Never retry.**

Retry is the wrong abstraction when the OS is broken. The disk isn't transiently full — it's full because something accreted faster than the prune cron can keep up, OR the prune cron itself is broken. Both require operator action, not retry.

## Detection primitive

Pattern matchers (any of):
- Stderr contains literal: `No space left on device`
- Stderr contains: `write error: ENOSPC`
- Errno: `ENOSPC` (errno 28)
- `df` shows >= 99% on primary volume (preemptive)

## Detection scope

Wherever Bash tool calls happen:
1. Orchestrator pane (claude/cc) running `Bash` tool calls
2. Worker pane (codex) running shell commands inside /goal mode
3. cron-fired scripts (when called by launchd)
4. Hook scripts (PreToolUse, PostToolUse)

## The 3-strike rule

Counter at `~/.local/state/flywheel/enospc-counter.jsonl`:
- Append row on each ENOSPC detection: `{ts, source, command_snippet, errno}`
- Compute rolling 3-event window per source
- If 3 events within 5 minutes from same source: HALT class

After halt: counter resets when disk-pressure < 90% AND 60min elapsed.

## Halt action

When 3-strike threshold tripped:
1. Stop dispatching further work to ANY pane
2. Emit halt-event to `~/.local/state/flywheel/enospc-halt-events.jsonl`
3. Probe disk pressure: `df -h /System/Volumes/Data`
4. Run emergency-reap-safe janitor (S-3 in storage-philosophy)
5. Emit cross-orch handoff to all active sister orchs: "ENOSPC halt fired here; check your disk-pressure"

## Escalate action

Concurrent with halt:
1. Cross-orch handoff to flywheel:1 (fleet-coord)
2. agent-mail notification to Joshua: subject `ENOSPC fleet-halt fired — disk pressure ≥ X%`
3. ntm send to skillos pane 1 (orchestrator) if not already at that pane: visible nudge
4. Append row to `~/.local/state/flywheel/founder-page-events.jsonl` (per S-7 in storage-philosophy)

## NOT retry

Explicit anti-patterns:
- `while true; do <cmd> || true; sleep N; done` — no
- `retry 3 <cmd>` — no
- Backoff-then-retry — no (this is OS-broken, not transient)
- "Maybe the disk freed up by now" optimism — no

If operator-intervention or auto-emergency-reap freed disk: counter resets after 60min cooldown + disk-pressure-clear. ONLY then can dispatch resume.

## Preemptive probe (orchestrator-side)

Before any large task-file write (>1MB) or work-dir creation:
```bash
DISK_PRESSURE=$(df -P /System/Volumes/Data | tail -1 | awk '{print $5}' | tr -d %)
if [[ $DISK_PRESSURE -ge 95 ]]; then
  enospc_escalate "preemptive probe >= 95% before write"
  exit 88  # canonical disk-pressure exit code
fi
```

## Tool-fail rate fleet-wide

Companion: when ≥3 distinct sister orchs hit ENOSPC class within 30min:
- Fleet-wide halt fires (not just per-orch)
- All orchs receive "fleet-halt active" cross-orch message
- Joshua paged with fleet impact summary
- Active dispatches pause until fleet-halt clears

## Trauma exemplar (2026-05-20 overnight)

All 6 orchs (flywheel + skillos + mobile-eats + alps + vrtx + zesttube + picoz + clutterfreespaces) silently went idle:
- Each tried 2-5 dispatch retries against full disk
- Each treated dispatch-fail as transient
- None had 3-strike counter
- None escalated
- Joshua woke up to discover via fleet-wide pane idle

Mitigations from this doctrine:
- Each orch ships 3-strike counter + halt logic
- Cross-orch handoff fires on halt (first-orch-detects warns others)
- Fleet-halt fires on ≥3 sister orchs hitting class
- Joshua-pager fires per S-7 threshold

## Wiring contract

For every orchestrator/worker pane:
1. Wrap Bash invocations with ENOSPC detector (PreToolUse hook OR shell wrapper)
2. Append to enospc-counter on detection
3. Halt-escalate on 3-strike
4. Reset counter on disk-pressure-clear + 60min cooldown

Hook example: `.flywheel/scripts/enospc-halt-hook.sh` (PostToolUse:Bash, fires after Bash tool calls, scans stderr for ENOSPC literals).

## Cross-references

- Parent: `storage-philosophy-v0.1.md` S-6 + S-7
- Sister: `cron-meta-watchdog-discipline.md` (S-4 — cron health monitoring)
- Trauma: 2026-05-20 overnight 6h-12h fleet downtime
- Skills: `storage-health`, `flywheel-recovery`

## Version history

- v0.1 (this doc, 2026-05-20T18:12Z): initial doctrine post-trauma joint authorship
