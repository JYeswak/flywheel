---
title: "Auto-Assign Daemon Reinstatement Plan"
type: plan
created: 2026-05-07
frontmatter_source: scaffold-doc-frontmatter
---

# Auto-Assign Daemon Reinstatement Plan

Source bead: `flywheel-qv2fs`

Upstream state: ntm#122 is closed in `c0f8f222`; ntm#124 is closed in
`3e44fe9e`. The dry-run watch path now emits "Would assign" instead of live
assignment wording, and the watch loop has an `IsLiveBusy` defense against
busy-pane dispatch.

This document does not enable the daemon. Operator-driven `/flywheel:dispatch`
remains canonical until Joshua explicitly approves live auto-assignment.

## Phase 1: Dry-Run Preflight

Run the preflight test from this bead:

```bash
bash tests/test_ntm_assign_watch_dry_run_preflight.sh
```

Then run the live planner probe from the flywheel repo:

```bash
ntm assign flywheel --repo /Users/josh/Developer/flywheel --watch --dry-run --limit=1 --stop-when-done
```

Acceptance:

- Output contains at least one "Would assign" planner line when work is
  available.
- Output contains no live assignment wording.
- Pane activity before and after the probe is unchanged.
- No dispatch-log mutation is attributed to the daemon.

## Phase 2: 24h Observation Daemon

Install or re-enable the daemon only in observation mode:

- `auto_assign=false`
- command includes `--watch --dry-run`
- command includes `--repo /Users/josh/Developer/flywheel`
- logs write under `~/.local/state/flywheel/logs/`
- expected planner signal is "Would assign"

Run for 24h. Review the daemon log, dispatch ledger, and pane activity ledger.
Any live assignment wording, pane mutation, or dispatch row attributed to the
daemon fails Phase 2 and returns to operator-driven dispatch only.

Known local LaunchAgent probe on 2026-05-08 found no dedicated coordinator
auto-assign watcher plist. Existing related LaunchAgents were fleet-health,
bead-status, and unrelated coordinator watchers, so the reinstatement path may
need a new disabled-by-default plist in a later bead.

## Phase 3: Live Flip By Approval Only

After Phase 2 is clean for 24h, Joshua may approve a live flip:

- set `auto_assign=true`
- remove dry-run only after the same command line has passed Phase 2
- keep `--repo /Users/josh/Developer/flywheel`
- keep `--limit=1` for the first live window
- monitor for "Assigned" lines and validate that each line corresponds to an
  idle pane at assignment time

Do not bundle Phase 3 with unrelated coordinator, pipeline, or dispatch
rewrites. The live flip is its own reversible operation with a receipt.

## Rollback

Set:

```bash
FLYWHEEL_PANE_WORK_SIGNAL_DISABLE=1
```

Then halt the LaunchAgent and return to operator-driven `/flywheel:dispatch`.
Rollback is complete only after:

- the daemon process is absent
- no new daemon-attributed dispatch rows appear
- `ntm health flywheel` confirms panes are available for manual dispatch

## Non-Goals

- This plan does not delete the transitional shadow wrappers.
- This plan does not enable live auto-assignment.
- This plan does not change `/flywheel:dispatch`.
