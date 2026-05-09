## L116 — TICK-IS-PROCESS-NOT-DOCUMENT

---
id: L116
title: Tick is process, not document
status: long_term
shipped: 2026-05-05
review_due: 2026-11-05
trauma_class: tick-hook-prose-without-process
---

Tick is a real process, not a markdown document. A primitive that claims
`tick_hook_wired=yes` is not wired until it is registered in
`.flywheel/scripts/tick-driver-manifest.json` and the launchd-backed driver
`/Users/josh/.local/bin/flywheel-tick-driver` produces ledger-backed evidence
for it in `~/.local/state/flywheel/tick-driver.jsonl`.

`/flywheel:tick` remains the human/agent-invocable decision function. L116 adds
the recurring process layer that makes tick-close primitives fire even when no
agent manually re-reads `tick.md`.

Shutdown/resume primitives are first-class manifest entries even though they are
event-driven rather than tick-driven. Register them in
`.flywheel/scripts/tick-driver-manifest.json` with `type: event_driven`; the
driver records them as registered process substrate and skips invocation during
normal tick fires.

For fleet shutdown/reboot recovery, the canonical repo-local state path is
`.flywheel/reboot-recovery/<iso-utc>/` with a `LATEST` symlink; divergent
`.flywheel/recovery/` or `.flywheel/handoffs/` reboot-final paths are drift.

**Required wiring:**

1. Add the primitive to `.flywheel/scripts/tick-driver-manifest.json` with
   `name`, `path`, `args`, and `timeout_sec`.
2. Ensure the primitive writes its own ledger when invoked by the driver.
3. Keep `/Users/josh/Library/LaunchAgents/com.flywheel.tick.plist` loaded with
   StartInterval 300 and ProgramArguments pointing to
   `/Users/josh/.local/bin/flywheel-tick-driver`.
4. Verify `flywheel-loop doctor --scope tick-driver --json` reports
   `tick_driver_last_fire_ts` fresher than two intervals and
   `tick_driver_fires_24h_count > 0`.
5. Run `.flywheel/scripts/tick-hook-firing-verifier.sh --apply --json` so pbt55
   consumes both primitive ledgers and tick-driver fire evidence.

**Doctor contract:** `flywheel-loop doctor --scope tick-driver --json` MUST
expose `tick_driver_daemon_loaded`, `tick_driver_last_exit_status`,
`tick_driver_last_fire_ts`, `tick_driver_fires_24h_count`,
`tick_driver_expected_fires_24h`, `tick_driver_fire_rate_pct`, and
`tick_driver_stalled_class_emitted_count_24h`.

**Forbidden outputs:**

- Claiming `tick_hook_wired=yes` because a script exists or `tick.md` names it.
- Closing a tick-hook primitive without manifest registration and a driver
  ledger row proving it fired.
- Treating launchd plist presence as enough without `tick-driver.jsonl`
  freshness, per L57.
- Adding new tick-close primitives only to prose.

**Evidence:** bead `flywheel-2h6le`; driver
`/Users/josh/.local/bin/flywheel-tick-driver`; LaunchAgent
`/Users/josh/Library/LaunchAgents/com.flywheel.tick.plist`; manifest
`.flywheel/scripts/tick-driver-manifest.json`; fixture
`tests/flywheel-tick-driver.sh`.

**Cross-references:** L57, L70, L102, L110, L111, L115, and pbt55
`tick-hook-firing-verifier.sh`.

