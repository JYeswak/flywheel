---
name: cron-meta-watchdog-discipline
class: P1-substrate-discipline
schema_version: skillos.doctrine.v1.1
authored: 2026-05-20
authority: storage-philosophy S-4 + 2026-05-20 overnight trauma
status: locked
canonical_in: []
sister:
  - storage-philosophy-v0.1.md
  - enospc-halt-escalate-not-retry.md  # planned
---

# Cron Meta-Watchdog Discipline

**Genesis:** 2026-05-20 overnight — temp-janitor.sh cron silently died when disk filled (couldn't write own stdout log → ENOSPC → reaped zero → no alarm). 6h-12h fleet downtime. The cure required the disease to be absent.

## The invariant

**Every flywheel-managed cron MUST emit a heartbeat row to canonical ledger AFTER its work completes. A meta-watchdog cron audits all registered crons + alerts when any heartbeat is stale.**

## Heartbeat contract

### Canonical ledger
`~/.local/state/flywheel/cron-heartbeat.jsonl` — append-only, one row per cron-tick.

### Row schema
```json
{
  "schema_version": "skillos.cron_heartbeat.v1",
  "ts": "<UTC ISO8601>",
  "cron_id": "<unique identifier matching launchd Label>",
  "expected_cadence_sec": <int>,
  "status": "ok|warn|fail|emergency_no_log",
  "work_done": {
    "<metric>": <value>
  },
  "host": "<hostname>",
  "pid": <int>
}
```

### Emit point
After cron's primary work completes successfully OR after emergency-reap path (S-3 in storage-philosophy). Failure to emit = silent death (the trauma class).

### Emergency-reap-safe emit
When disk-pressure ≥ critical threshold, emit to `/dev/null` is NOT acceptable. Options:
1. Reserve N bytes via APFS sparse file at install time; release pre-emit
2. Write to separate volume (e.g., `/Volumes/External/heartbeat.jsonl`)
3. Emit via stderr only (captured by launchd's own log rotation)
4. systemd-journal equivalent (macOS: `log stream` cannot be source; use `os_log` if going native)

Doctrine: emergency-reap mode MUST still emit a heartbeat row even if reaped nothing — the heartbeat IS the work proof.

## Meta-watchdog

`.flywheel/scripts/cron-meta-watchdog.sh` (canonical, fleet-portable):

### Inputs
- `~/.local/state/flywheel/cron-heartbeat.jsonl` (read)
- `~/.local/state/flywheel/cron-registry.jsonl` (registered crons with expected cadence)

### Logic
For each registered cron:
- Read latest heartbeat row matching cron_id
- Compute staleness = `now - latest.ts`
- If staleness > `2 × expected_cadence_sec`: ALERT

### Alert channels
- Cross-orch handoff to flywheel:1 (fleet-coord)
- agent-mail notification to Joshua
- Append alert row to `~/.local/state/flywheel/cron-watchdog-alerts.jsonl`

### Meta-watchdog itself emits heartbeat
Yes. Avoids meta-recursion concerns: meta-watchdog is itself a cron registered in cron-registry. Its heartbeat is monitored by... itself? No — by a sister probe that runs daily (`cron-meta-watchdog-doctor.sh`) and checks the meta-watchdog's heartbeat freshness.

Fall-back: if meta-watchdog dies, sister-probe alerts. If sister-probe dies, daily Joshua-direct status check catches it (founder-dispose threshold S-7).

## cron-registry.jsonl schema

```json
{
  "schema_version": "skillos.cron_registry.v1",
  "ts": "<install ts>",
  "cron_id": "<launchd Label>",
  "expected_cadence_sec": <int>,
  "plist_path": "<absolute path>",
  "primary_purpose": "<one-line>",
  "owning_skill": "<skill name or canonical-doctrine>",
  "emergency_safe": true|false,
  "registered_by": "<system installer>"
}
```

## Registered crons (skillos-side baseline)

| cron_id | cadence | purpose | emergency-safe |
|---|---|---|---|
| ai.zeststream.skillos-codex-stall-detector | 60s | pane stall detection | yes (no disk write) |
| ai.zeststream.skillos-temp-janitor | 300s | /private/tmp prune | NO — current impl writes log |
| ai.zeststream.codex-storage-janitor | 86400s | ~/.codex/log rotation | NO — same issue |
| ai.zeststream.skillos-cron-meta-watchdog | 600s | THIS doctrine's watchdog | YES (designed emergency-safe) |
| ai.zeststream.skillos-cron-meta-watchdog-doctor | 86400s | sister-probe | YES |

Fleet-wide: registry mirrored cross-repo via canonical-locator sync.

## Failure modes prevented

1. **Cron silently dies during ENOSPC** (the 2026-05-20 trauma): heartbeat-emit gap detected within 2× cadence
2. **Cron is mis-configured + never runs**: heartbeat never appears; meta-watchdog flags within 2× cadence
3. **Cron runs but completes incorrectly**: status field carries pass/warn/fail; meta-watchdog flags status=fail patterns
4. **Cron registry drift** (plist exists but not registered): meta-watchdog-doctor cross-references launchd list vs registry; flags drift

## Wiring contract

For every new flywheel-managed cron:
1. Author cron script with heartbeat-emit at completion (success + emergency-reap paths both emit)
2. Install launchd plist
3. Append row to cron-registry.jsonl
4. Run meta-watchdog dry-run to confirm registry pickup
5. Wait 2× cadence + verify heartbeat appears
6. Wait 4× cadence + verify meta-watchdog NOT alerting (sanity)

Skip ANY step = doctrine violation; ship the fix in same commit.

## Cross-references

- Parent: `storage-philosophy-v0.1.md` S-4
- Sister: `enospc-halt-escalate-not-retry.md`
- Trauma: 2026-05-20 overnight 6h-12h fleet downtime
- Skills: `storage-health`, `disk-observer`, `flywheel-recovery`

## Version history

- v0.1 (this doc, 2026-05-20T18:10Z): initial doctrine post-trauma joint authorship
