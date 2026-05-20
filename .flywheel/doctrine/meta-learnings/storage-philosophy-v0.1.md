---
name: storage-philosophy
class: P0-foundation-doctrine
schema_version: skillos.doctrine.v1.1
version: 0.1
authored: 2026-05-20
authority: joshua-direct-2026-05-20T11:30Z + flywheel:1 joint plan-space
status: locked
extends:
  - repo-hygiene-operational-protocol.md
  - storage-override-schema.md
canonical_in: []
sister:
  - cron-meta-watchdog-discipline.md  # planned
  - enospc-halt-escalate-not-retry.md  # planned
---

# Storage Philosophy — Foundation Doctrine

**Joshua-direct genesis 2026-05-20T11:30Z:**

> "For weeks now I have to stop everything I'm doing, all my workers die, and I have to find ways to get storage back. There are a lot more things we can do on this system to measure, optimize, and intelligently prune. I want you and skillos to both use whatever tools we have /research-triad, git searches, etc. and figure out a way to optimize this for today, tomorrow, forever across all of our systems - if I add another system, it adopts that storage philosophy. it has to be baked into the foundation of skillos and flywheel."

This doctrine extends the existing single-repo substrate-hygiene cluster (H-1..H-4 in `repo-hygiene-operational-protocol.md`) to **fleet-wide + system-level** scope. It is the foundation other skills inherit.

## The seven universal invariants (S-1 through S-7)

### S-1 — Every accreting surface declares retention at creation (extends H-3)

ANY directory, file, or substrate that grows unbounded MUST declare its retention policy at the SAME change that creates it. Policy forms:
- `max_age_days: N` — TTL-based prune
- `max_size_bytes: N` — size-cap-based prune (oldest first)
- `max_count: N` — keep-last-N rotation
- `cron_schedule: <cron>` — explicit prune cadence

Declaration lives in one of: source code header comment, `.flywheel/RETENTION.yaml` per-repo, OR `STORAGE-MANIFEST.yaml` per-system. Declaration without enforcement is hypocritical — see S-3.

Anti-pattern (caught 2026-05-14): `.flywheel/extraction/` reached 1.3GB because retention was TODO. The author of the generator owns the retention rule.

### S-2 — Substrate is rebuildable, not precious (extends H-4)

`beads.db`, `node_modules/`, extraction output, audit output, `.git-archive/` contents — all regenerable from source of truth. Pruning loses a rebuild, not work. Treat accordingly.

Corollary: if losing a file costs hours of work, it's not substrate — it's source. Move it to `state/`, `.flywheel/handoffs/`, or git-tracked.

### S-3 — Every retention policy has an enforcement primitive

Declaration without enforcement = lying-config (sister to dade2314 lying-cache class in picoz). For each declared policy:
- Enforcement script that reads the policy + acts
- Cron/launchd that runs the script at declared cadence
- Heartbeat ledger row showing enforcement fired

A retention policy declared but not enforced is a worse failure than no policy — it lulls operators into false confidence.

### S-4 — Cron health is fleet-observable (NEW from 2026-05-20 trauma)

Every cron writes `last_success_ts` to canonical heartbeat ledger `~/.local/state/flywheel/cron-heartbeat.jsonl`. Meta-watchdog cron audits all registered crons; alerts when any `last_success_ts < now - 2*expected_cadence`.

Trauma genesis: 2026-05-20 overnight — janitor cron silently died when disk filled (couldn't write own stdout log → ENOSPC → reaped zero → no alarm fired → 6h-12h fleet downtime).

Failure mode `the-cure-requires-the-disease-to-be-absent`: any prune-tool that itself writes to the disk it's pruning is vulnerable. Mitigations:
- Emergency-reap mode (mode-flag) that writes nothing, just unlinks
- launchd plist with `LowPriorityIO=true` + reserved-APFS-bytes pre-emption
- Log to separate volume OR `/dev/null` in emergency mode
- Meta-watchdog probes the prune-tool's pulse, not just its config

### S-5 — Workers + orchestrators clean own work-dirs

Every dispatch creates ephemeral work-dirs/files. Cleanup contract:
- Worker pane: `/private/tmp/<orch>-<bead>-<ts>/` work-dir owned by worker; `rm -rf` before callback
- Orchestrator pane: `/tmp/<orch>-*.task.md` task-files written by orchestrator; cleanup post-callback OR cron-pruned by prefix
- Dispatch-log v3 schema MUST carry `work_dir` + `work_dir_cleaned: yes|no|pending` fields
- Janitor consumes dispatch-log to find orphan work-dirs (status=done + cleaned=no + dir-still-exists)

Trauma genesis: 2026-05-20 — workers created /private/tmp/<orch>-<bead>-<ts>/ work-dirs without cleanup contract; 28GB accreted across 358 entries; vrtx alone had 289 work-dirs. SKILLOS finding: orchestrator-side /tmp/*.task.md files ALSO leak (1.1GB on skillos at peak); contract applies to BOTH sides.

### S-6 — ENOSPC is OS-broken, not transient (NEW from 2026-05-20 trauma)

When Bash tool returns ENOSPC or "No space left on device" 3 consecutive times: HALT + ESCALATE TO OPERATOR. Never retry. Retry is the wrong abstraction when the OS is broken.

Escalation path:
1. Orchestrator-side detection: probe disk-pressure before any task-file write
2. 3 consecutive ENOSPC = halt dispatch loop + emit cross-orch handoff to ALL active sister orchs
3. Page Joshua at `disk_pressure >= 95%` capacity (founder-dispose threshold per S-7)

Trauma genesis: 2026-05-20 — orchs retried dispatches against full disk; all 6 orchs went idle in concert because each treated ENOSPC as transient; no escalation fired.

### S-7 — Founder-dispose threshold (paging contract)

Joshua gets paged at:
- Disk capacity ≥ 95% on `/System/Volumes/Data` for >5min
- Cron heartbeat stale on any P0 cron for >2× cadence
- Cross-orch handoff backlog >24h on Joshua-gated decisions
- Fleet-wide tool-fail rate >threshold (e.g., 3+ orchs hitting same class within 30min)

Below threshold: orchs auto-handle + log. Above threshold: Joshua-direct cross-orch handoff + Slack/agent-mail notification.

## Measurement layer (single source of truth)

`scripts/storage_health_probe.sh` (canonical, fleet-portable):
- `/System/Volumes/Data` usage% + free bytes
- `/private/tmp/` size + top-10 accreting prefixes  
- `~/Library/Caches/` size + age distribution
- Per-repo accretion (matches `.flywheel/RETENTION.yaml` declared surfaces)
- Cron heartbeat freshness for all registered crons
- ENOSPC event count in last 24h

Output: JSON envelope `skillos.storage_health.v1` consumed by `/flywheel:status` dashboard.

## Pruning hierarchy (tiered)

| Tier | Cadence | Scope | Triggered by |
|---|---|---|---|
| 0 — Continuous | per-write | Worker-tick contract: `rm -rf $WORK_DIR` post-callback | Worker discipline (S-5) |
| 1 — Short-cycle | 5min | temp-janitor.sh: `/private/tmp/<orch>-*` patterns | launchd StartInterval=300 |
| 2 — Mid-cycle | hourly | Repo-local accreting surfaces (`.flywheel/extraction/`, etc.) | launchd StartInterval=3600 |
| 3 — Daily | 24h | `~/Library/Caches/` aged > policy, `.git-archive/` rotation | launchd at fixed time |
| 4 — Emergency | disk-pressure-triggered | Aggressive reap mode: ignore retention, only protect git-tracked + Desktop/Documents | APFS-reserved-bytes pre-emption |

## Per-surface-class doctrine

| Class | Policy template | Enforcement |
|---|---|---|
| Transcripts (`~/.claude/projects/.../`) | max_age 7 days | session-end hook reap |
| Evidence ledgers (`~/.local/state/flywheel/*.jsonl`) | max_count 10k rows per file → rotate | launchd nightly |
| Build artifacts (`node_modules`, `target/`, `.next/`) | n/a (gitignored) | manual prune OR pre-build cleanup |
| Token state (`~/.codex/`, caam profile vaults) | max_age never (auth) — backed up + rotated | manual rotation |
| Media (zesttube/raw/) | max_age 30 days post-publish | manual review + R2 archive |
| Work-dirs (`/private/tmp/<orch>-<bead>-<ts>/`) | max_age 1h after callback | worker-tick contract OR 5min cron |
| Task-files (`/tmp/<orch>-*.task.md`) | max_age 24h | orchestrator-cleanup OR daily cron |
| Cache (`~/Library/Caches/`) | max_age 30 days | system cron |

## Inheritance mechanism

New systems opt in via single command:

```bash
~/.claude/skills/install-substrate/bin/install --storage-philosophy
```

Installer applies:
1. Copies canonical `STORAGE-MANIFEST.yaml` template
2. Wires launchd plists for tier 0-3 prune crons
3. Registers cron heartbeat ledger
4. Installs `storage_health_probe.sh` + adds to `/flywheel:status`
5. Adds `.flywheel/RETENTION.yaml` skeleton requiring per-surface fill-in
6. Installs ENOSPC-halt-escalate doctrine + dispatch-log v3 work_dir field

Removal: `~/.claude/skills/install-substrate/bin/uninstall --storage-philosophy` reverses cleanly.

## Failure-mode prevention checklist

For every new accreting surface OR cron:

- [ ] Retention policy declared in `RETENTION.yaml` or doctrine header
- [ ] Enforcement primitive ships in same commit
- [ ] Cron-heartbeat row registered
- [ ] Emergency-reap-safe (won't die when disk full)
- [ ] Janitor scope updated if new prefix
- [ ] dispatch-log v3 schema captures work-dir if worker-created
- [ ] Measurement layer (probe script) detects new surface
- [ ] Per-surface-class doctrine row exists for the class

If any unchecked = doctrinal-debt; ship the fix in the SAME commit.

## Cross-references

- Sister: `repo-hygiene-operational-protocol.md` (H-1..H-4, single-repo scope)
- Sister (planned): `cron-meta-watchdog-discipline.md` (S-4 enforcement)
- Sister (planned): `enospc-halt-escalate-not-retry.md` (S-6 enforcement)
- Trauma corpus: 2026-05-20 overnight 6h-12h fleet downtime (joint investigation handoff `20260520T100000Z-from-flywheel-to-skillos-joint-storage-philosophy-investigation.md`)
- Skill catalog cross-refs: `storage-health`, `dev-cache-janitor`, `git-repo-janitor`, `git-stash-janitor`, `storage-ballast-helper`, `disk-observer`, `apfs-snapshot-ops`, `orbstack-migration`, `docker-storage-ops`

## Version history

- v0.1 (this doc, 2026-05-20T11:35Z): skillos+flywheel joint authorship per Joshua-direct request; 7 universal invariants (S-1..S-7); measurement layer; tiered prune hierarchy; per-surface-class doctrine; inheritance mechanism via install-substrate skill.

## Next steps (skillos-side commitments)

1. Author sister doctrines `cron-meta-watchdog-discipline.md` + `enospc-halt-escalate-not-retry.md`
2. Ratify `dispatch-log v3` schema with work_dir + work_dir_cleaned fields
3. Co-author `install-substrate --storage-philosophy` with flywheel
4. Cross-orch handoff to flywheel for joint review + ratification
5. Phase A propagation to 6+ orchs once ratified (per skillos canonical-locator lane authority)
