---
title: "Lane B Research: Topology Freshness + Watcher Load"
type: plan
created: 2026-05-08
frontmatter_source: scaffold-doc-frontmatter
---

# Lane B Research: Topology Freshness + Watcher Load

Task: `orch-uptime-plan-2026-05-06` lane B  
Status: done, read-only research  
Identity: `MagentaPond` (`flywheel:3`)  
L112: `OK_orch_uptime_laneB_research_complete`

## Donella Trace

- Boundary: flywheel repo scripts, NTM session/pane substrate, `session-topology.jsonl`, launchd watcher registry, and mobile-eats loop driver.
- Stock: fresh, trusted pane-role topology that recovery gates can consume without paging Joshua.
- Flow: live NTM state should refresh the topology stock on every orchestrator tick; currently topology is written only by ad hoc/bootstrap registration.
- Loop: detector -> capacity authorization -> recovery primitive -> pane returns to productive state -> tick observes health.
- Leverage: Meadows #6 information flow and #5 rules; make freshness a scheduled stock, not a stale artifact.
- Intervention: add a pure freshness refresh primitive, wire it before topology-consuming recovery gates, register the two known flywheel-owned plists, and harden mobile-eats escalation arity.
- Measurement: max topology age below capacity gate TTL, zero `topology_stale` refusals when live pane roles are unchanged, launchctl guard allows the registered plists, mobile-eats tick no longer exits on `$2`.

## Skill Floor

Skills/references consulted:

- `ntm`: use NTM verbs for live session and robot-activity state, and for callback delivery.
- `dispatch-tool-contracts`: K>=10 Socraticode survey, diagnose-only scope, callback evidence envelope.
- `install-substrate`: new state writer must declare producer/consumer/validator and be wired into existing substrate.
- `accretive-cron-orchestration`: tick-driven periodic control loop, idempotent watcher/cron behavior.
- `loop-enforcement`: recurring loop logic belongs in the tick choke point, not ad hoc operator steps.
- `flywheel-doctor-author`: every new health stock needs producer, measurement, consumer, and promotion path.
- `background-jobs`: idempotency, timeout, liveness, and stale-job detection for scheduled refreshers.
- `observability-designer`: define SLI/SLO around freshness age and refusal counts.
- `donella-meadows-systems-thinking`: system trace above.

Socraticode queries: 10  
Indexed chunks observed: 978 from repo status plus query hits across topology, watcher, tick-driver, recovery gate, mobile-eats, and manifest surfaces.

## Current Evidence

- `~/.local/state/flywheel/session-topology.jsonl` latest row for `flywheel`:
  - `effective_at`: `2026-05-01T14:43:05Z`
  - `orchestrator_pane`: `1`
  - `callback_pane`: `1`
  - `worker_panes`: `[2,3,4]`
  - `worker_kinds`: `{"2":"codex","3":"codex","4":"codex"}`
  - `shell_panes`: `[0]`
  - `human_pane`: `0`
  - `expected_pane_count`: `5`
- Live `ntm list --json` for `flywheel` shows `pane_count=5`, `claude=1`, `codex=3`, `user=1`.
- Live `ntm --robot-activity=flywheel` shows pane 1 `claude`, panes 2/3/4 `codex`.
- `.flywheel/scripts/capacity-halt-pane-authorization.sh` uses latest row by `effective_at` and refuses when `age > 3600`.
- A read-only authorization probe for `flywheel` pane 2 returns `topology_stale`, `topology_age_sec=453348`, even though live topology shape still matches.

Conclusion: this is not a pane-role reclassification gap. The upstream gap is absence of a recurring pure-freshness writer for the existing JSONL topology ledger.

## Existing Substrate To Extend

- `.flywheel/scripts/capacity-halt-pane-authorization.sh`: consumes latest topology row and protects orchestrator/callback/human panes.
- `.flywheel/scripts/topology-gap-probe.sh`: validates topology schema/latest-wins/bootstrap fixtures, but does not refresh live topology.
- `.flywheel/flywheel-loop-tick`: central tick driver; already performs canonical doctrine pull, L102 meta-rule sync, frozen detector, stuck detector, and dispatch gates.
- `.flywheel/scripts/tick-driver-manifest.json`: canonical primitive registry, including event-driven primitives.
- `/Users/josh/.local/bin/flywheel-watchers` plus `~/.local/lib/flywheel-watchers/*.sh`: registry and launchd guard substrate.
- `/Users/josh/.local/bin/launchctl` -> `/Users/josh/.local/bin/launchctl-guard`: refuses unregistered plist bootstrap.
- `/Users/josh/.local/bin/mobile-eats-flywheel-loop-tick`: verified L57 launchd prompt driver with current `$2` crash.

## Proposed Primitive: `topology-tick-refresh`

New file proposed: `.flywheel/scripts/topology-tick-refresh.sh`

Purpose: append a fresh latest-wins topology row only when live NTM pane-role mapping matches the previous latest row. It must never invent roles, move panes, or reclassify sessions.

Interface:

```bash
.flywheel/scripts/topology-tick-refresh.sh \
  --topology /Users/josh/.local/state/flywheel/session-topology.jsonl \
  --ntm-bin /Users/josh/.local/bin/ntm \
  --apply \
  --json
```

Algorithm:

1. Load latest topology row per session with `max_by(.effective_at)`.
2. Read live sessions via `ntm list --json`.
3. For each session that has both a latest topology row and a live NTM session, run `ntm --robot-activity=<session>`.
4. Normalize live panes into:
   - pane count
   - agent kind by pane
   - expected worker pane/kind set
   - protected panes from the existing row
5. If the live shape exactly matches the latest row's declared role map, append a new JSONL row:
   - copy existing role fields unchanged
   - set `effective_at` to current UTC timestamp
   - set `registered_by` to `topology-tick-refresh`
   - add `refresh_of_effective_at`
   - add `refresh_reason=pure_freshness`
   - add `topology_shape_hash`
6. If any shape mismatch exists, do not append. Emit `needs_reclassify` with reason:
   - `missing_live_session`
   - `pane_count_changed`
   - `worker_pane_missing`
   - `worker_kind_changed`
   - `extra_agent_pane`
   - `no_topology_row`
   - `malformed_topology_row`
7. Append atomically under a lock and validate each row as JSON before write.
8. Emit JSON summary with `refreshed_count`, `refused_count`, `max_age_sec_before`, `max_age_sec_after`, and per-session statuses.

Append-only latest-wins is the right write model. The dispatch says "rewrites rows", but the existing substrate is JSONL with latest-by-`effective_at`; replacing history would fight the ledger design and make incident audit weaker.

## Tick Wire-In

Primary wire-in: `.flywheel/flywheel-loop-tick`

Insertion point:

- Run after canonical doctrine pull and L102 meta-rule cache sync.
- Run before `codex_watchtower_probe`, frozen detector, stuck detector, dispatch capacity gates, or any recovery path that can read topology.

Reasoning: L102 currently requires meta-rule sync immediately after canonical doctrine pull. Preserving that adjacency avoids creating a new doctrine-order violation while still refreshing topology before all topology-consuming detectors and capacity gates.

Sketch:

```bash
TOPOLOGY_REFRESH_RESULT="$(
  .flywheel/scripts/topology-tick-refresh.sh --apply --json 2>&1 || true
)"
log "topology_tick_refresh" "$TOPOLOGY_REFRESH_RESULT"
```

Record fields into `$LAST` / dispatch log:

- `topology_refresh_status`
- `topology_refreshed_count`
- `topology_refused_count`
- `topology_max_age_sec_before`
- `topology_max_age_sec_after`

Also add to `.flywheel/scripts/tick-driver-manifest.json`:

```json
{
  "name": "topology-tick-refresh",
  "path": ".flywheel/scripts/topology-tick-refresh.sh",
  "args": ["--apply", "--json"],
  "timeout_sec": 30
}
```

## Tick-Refresh vs Event-Refresh

Use tick-refresh now.

Reason: topology age is a consumed stock. The failure happened while the pane-role shape remained valid, so there was no useful event to reclassify. Event-refresh can supplement future pane creation/removal handling, but it will not reliably repair stale freshness after reboot, missed hooks, failed launchd runs, or idle-but-valid sessions.

Rule: event-refresh may trigger reclassification; tick-refresh may only extend freshness for unchanged role maps.

## Watcher Register Refusal

Observed:

- `~/Library/LaunchAgents/com.flywheel.shutdown-recovery.plist` exists.
- `~/Library/LaunchAgents/ai.zeststream.flywheel-idle-pane-watch.plist` exists.
- Neither label appears in `~/.local/state/flywheel/plist-registry.jsonl`.
- Neither label appears in `~/.local/state/flywheel/watcher-control-ledger.jsonl`.
- `launchctl-guard` refuses `bootstrap` when the plist label has no registry row.

Cause: plists were present but not registered through `flywheel-watchers register`. This is an ownership registry gap, not a launchd problem.

Safe registration plan, preview first:

```bash
/Users/josh/.local/bin/flywheel-watchers register \
  --label ai.zeststream.flywheel-idle-pane-watch \
  --owner flywheel-orch \
  --reason "flywheel-owned idle-pane auto-dispatch LaunchAgent for flywheel session" \
  --bead flywheel-orch-uptime-plan-2026-05-06 \
  --idempotency-key orch-uptime-2026-05-06:register:ai.zeststream.flywheel-idle-pane-watch \
  --json

/Users/josh/.local/bin/flywheel-watchers register \
  --label com.flywheel.shutdown-recovery \
  --owner flywheel-orch \
  --reason "flywheel-owned event-driven fleet shutdown recovery LaunchAgent" \
  --bead flywheel-orch-uptime-plan-2026-05-06 \
  --idempotency-key orch-uptime-2026-05-06:register:com.flywheel.shutdown-recovery \
  --json
```

Apply once the preview looks correct:

```bash
/Users/josh/.local/bin/flywheel-watchers register ... --apply --json
```

Do not use `LAUNCHCTL_GUARD_BYPASS`. After registration, the existing guard should allow bootstrap. Follow-up hardening: teach `flywheel-watchers doctor launchctl` to count `com.flywheel.*` labels as flywheel-owned scope too; today its unregistered-flywheel count focuses on `ai.zeststream.flywheel-*`, while `launchctl-guard` protects both.

## Mobile Eats Line 161

Observed stderr:

```text
/Users/josh/.local/bin/mobile-eats-flywheel-loop-tick: line 161: $2: unbound variable
```

Current source:

- Line 161 is the closing `fi` in `update_blocker_tick_counter`.
- The source of the unbound positional parameter is the callee at line 83:

```bash
local blocker_id="$1" ticks="$2" first_seen="$3" affected_beads="$4" attempts="$5" evidence_paths="$6" hypothesis="$7" capsule="$8"
```

Proposed one-line arity guard before that `local`:

```bash
(( $# >= 8 )) || { json_log "fleet_escalation_capsule_skipped" "$(jq -nc --argjson argc "$#" '{reason:"missing_args",argc:$argc}')"; return 0; }
```

This prevents `set -u` from killing the loop if the escalation helper is called with fewer than 8 args. It should be paired with a small fixture that calls `send_fleet_escalation_capsule one_arg_only` under `set -u` and asserts the script logs skip instead of exiting.

## Test Fixture Plan

1. Stale topology, unchanged live shape: appends refreshed row and `capacity-halt-pane-authorization` changes from `topology_stale` to worker-authorized.
2. Fresh topology within cooldown: emits `already_fresh` and does not append duplicate rows.
3. Missing worker pane: emits `needs_reclassify`, no append.
4. Extra live agent pane: emits `needs_reclassify`, no append.
5. Worker kind changed from `codex` to `claude`: emits `worker_kind_changed`, no append.
6. Session in topology but absent from `ntm list`: emits `missing_live_session`, no append.
7. Live session without topology row: emits `no_topology_row`, no role inference.
8. Malformed topology JSONL row: reports malformed input and writes nothing.
9. Append lock held/write failure: nonzero result and no partial row.
10. Protected pane semantics preserved: after refresh, worker pane authorizes but orchestrator/callback/human panes remain refused.
11. `flywheel-loop-tick` ordering fixture: `topology_tick_refresh` log appears before stuck/capacity recovery gates.
12. Manifest fixture: `tick-driver-manifest.json` contains `topology-tick-refresh`, and tick-driver evidence records its fire.
13. Watcher preview fixture: two register commands produce dry-run plans with no registry writes.
14. Watcher apply fixture: two registry rows are appended and `launchctl-guard` fixture permits bootstrap without bypass.
15. Watcher idempotency fixture: rerun with same idempotency key returns already-registered/no duplicate row.
16. Mobile-eats arity fixture: helper called with insufficient args under `set -u` logs skip and script survives.

## Joshua-Blocker Class Check

None of the TRUE Joshua-blocker classes fire.

- No secret rotation or token exposure is proposed.
- No provider billing, production deploy, or client-data mutation is proposed.
- No `caam activate`, no `launchctl` operation, and no destructive command is required by this research.
- Future watcher registration mutates only local flywheel ownership registry and follows the existing `flywheel-watchers` guarded path.
- Future topology refresh writes only flywheel local state after proving live shape unchanged.

## Proposed Change Set

New files proposed: 2

- `.flywheel/scripts/topology-tick-refresh.sh`
- `tests/topology-tick-refresh.sh`

Existing files to extend:

- `.flywheel/flywheel-loop-tick`
- `.flywheel/scripts/tick-driver-manifest.json`
- `.flywheel/scripts/flywheel-watchers*` tests or launchctl-guard fixture tests
- `/Users/josh/.local/bin/mobile-eats-flywheel-loop-tick`

DID/DIDNT/GAPS:

- DID: identified upstream topology freshness gap.
- DID: designed refresh primitive and tick wire-in.
- DID: identified two-watcher registration cause and safe register path.
- DID: identified mobile-eats `$2` crash source and one-line guard.
- DID: designed 16 tests.
- DIDNT: no source edits, no tests run, no `launchctl`, no `caam activate` per read-only dispatch.
- GAPS: none requiring a new bead from this read-only lane; `no_bead_reason=read-only-research-no-new-gap`.

Four-Lens Self-Grade:

- Brand: 9
- Sniff: 9
- Jeff: 8
- Public: 8
- Overall: Y

Mission-anchor: continuous-orchestrator-uptime-self-sustaining-fleet
