# Recovery r1 Audit - Idempotency + Race Conditions

Task: `recovery_audit_idempotency`
Date: 2026-05-01
Lens: idempotency, races, atomicity, ordering, partial failure
Audited plan: `02-REFINE-r1.md`

## Summary

The r1 plan has the right recovery shape: dry-run before mutation, JSON authority,
state-machine ordering, verified checkpoints, temp-to-final manifest writes,
protected session policy, and append-only audit rows.

The main gap is mechanical concurrency discipline. The plan names the right
principles, but several implementation beads need explicit lock scopes,
idempotency-key semantics, operation journals, atomic write contracts, and
parallel-race tests before code-space work is safe.

Severity counts:

- CRITICAL: 4
- HIGH: 8
- MEDIUM: 4
- LOW: 0

Race-condition count:

- 7 concerns are primarily race conditions.

Highest-risk decisions before bead conversion:

- Add fleet/session lock hierarchy before any mutating implementation.
- Make idempotency keys first-class in manifest/audit logic.
- Split snapshot writing from retention pruning with staging + atomic publish.
- Require restore leases so two panes cannot restore one session concurrently.
- Treat watcher/bootstrap/snapshot collisions as explicit state-machine cases.

## Concern 1 - Install Re-Run Safety

Type: idempotency / partial-failure

Severity: HIGH

Current mitigation:

- Dry-run is mandatory before mutation (`02-REFINE-r1.md:232`).
- Phase 1 requires TOML-aware repair, backup, audit row, topology check (`02-REFINE-r1.md:492-497`).
- Phase 2 requires per-session watcher plists and launchd verifier (`02-REFINE-r1.md:509-518`).

Gap: The plan does not explicitly say `install --apply` is safe when run twice, nor whether existing config/plists are skipped, diffed, or replaced.

Suggested fix: B03 and B04-B11 acceptance should require `status=already_current` for matching config/plist hashes, with audit fields `planned_action`, `old_hash`, `new_hash`, and `idempotency_key`.

Test case: Apply install twice against temp config/plist dirs and assert no duplicate TOML keys, no duplicate plists, and stable hashes.

## Concern 2 - Snapshot During Active Worker Generation

Type: race

Severity: HIGH

Current mitigation:

- Manifest tracks agents with `last_activity` and `dispatch_id` (`02-REFINE-r1.md:295-303`).
- Manifest tracks dispatch `in_flight`, orphan candidates, and last callback (`02-REFINE-r1.md:305-309`).
- Reboot mid-worker generation is mapped to dispatch ledger/orphan reconciliation (`02-REFINE-r1.md:682`).

Gap: No quiescence protocol defines whether active generation is skipped, waited on, or snapshotted best-effort.

Suggested fix: Add `snapshot_quiescence` to B12. Record pane `active|idle|unknown`, bounded wait result, and `snapshot_consistency=verified|best_effort`.

Test case: Snapshot a disposable session while a pane streams output; verify manifest marks active pane and restore classifies in-flight work as orphan candidate.

## Concern 3 - Simultaneous Restore Of Same Session

Type: race

Severity: CRITICAL

Current mitigation:

- Restore requires `restore_plan_ready` before apply (`02-REFINE-r1.md:366-369`).
- Protected sessions restore only by explicit policy (`02-REFINE-r1.md:236`).
- Restore apply checkpoints the live target first when feasible (`02-REFINE-r1.md:462`).
- Phase 5 includes dry-run, apply, doctor, and dispatch reconciliation (`02-REFINE-r1.md:558-564`).

Gap: No session-level restore lock prevents two panes from applying the same restore, especially with `--force`.

Suggested fix: Add `locks/restore.<session>.lock`, acquired atomically by `mkdir` or `flock`, with owner PID/session/run ID and stale-steal gates.

Test case: Run two restore applies in parallel against fixture wrappers; assert one acquires lock and one exits blocked without touching session state.

## Concern 4 - Launchd Watcher Fires During Snapshot

Type: race / ordering

Severity: CRITICAL

Current mitigation:

- Watcher liveness and session resurrection are distinct checks (`02-REFINE-r1.md:238`).
- Boot helper restores missing sessions before watchers latch (`02-REFINE-r1.md:511-512`).
- Failure matrix calls out launchd-before-readiness and watcher race (`02-REFINE-r1.md:687-688`).
- Risk register calls watcher plists loaded while sessions absent high/high (`02-REFINE-r1.md:703`).

Gap: No lock ordering says whether watcher/bootstrap may create or latch a session while snapshot is reading layout.

Suggested fix: Add a shared `session.<name>.lock`; watcher/bootstrap exits retry-safe when snapshot/restore owns it and snapshot records `watcher_state`.

Test case: Hold a snapshot/session lock, invoke watcher dry-run wrapper, and assert watcher defers without creating/modifying session state.

## Concern 5 - Retention Prune While Snapshot Writes

Type: race / atomicity

Severity: CRITICAL

Current mitigation:

- Latest verified checkpoint is never pruned (`02-REFINE-r1.md:424`).
- Checkpoints referenced by current manifest are never pruned (`02-REFINE-r1.md:432`).
- Retention dry-run reports prune rows/files and latest verified checkpoint (`02-REFINE-r1.md:434-440`).
- Phase 4 acceptance protects latest verified checkpoint (`02-REFINE-r1.md:550-551`).

Gap: Snapshot export has no staging marker, so retention could inspect or prune around partial archives/manifests.

Suggested fix: Snapshot writes under `checkpoints/.staging/<run_id>/`, verifies there, then atomically renames/publishes. Retention ignores staging and shares the checkpoint lock.

Test case: Fixture snapshot sleeps with `.staging` file present; retention dry-run must ignore staging and prune nothing related to the in-flight checkpoint.

## Concern 6 - Atomic Write Contract Per Mutation

Type: atomicity

Severity: HIGH

Current mitigation:

- Config repair backs up before write and logs old/new SHA256 (`02-REFINE-r1.md:459`).
- Manifest is temp-to-final (`02-REFINE-r1.md:533-534`).
- Manifest source cites append-only/atomic-write patterns (`02-REFINE-r1.md:245-246`).
- Non-redacted archives must be mode `0600` (`02-REFINE-r1.md:449`).

Gap: Atomicity is explicit for manifest only; config, plist, JSONL, nightly, retention, and archive writes do not each have contracts.

Suggested fix: Add a B01 mutation contract table covering backup/temp/fsync/rename, hash verification, append locks, staging checksums, and publish rename.

Test case: Kill helper between temp write and rename; assert original survives and rerun cleans/resumes safely.

## Concern 7 - Idempotency Key Semantics

Type: idempotency

Severity: HIGH

Current mitigation:

- Recovery manifest includes `idempotency_key` (`02-REFINE-r1.md:257`).
- Dispatch duplication after reboot names idempotency keys as mitigation (`02-REFINE-r1.md:707`).
- ACFS adoption maps idempotency to B01/B02/B03 (`02-REFINE-r1.md:675`).
- CLI/schema contract includes dry-run/apply and idempotency (`02-REFINE-r1.md:579`).

Gap: Key scope, storage, replay behavior, and conflict behavior are undefined.

Suggested fix: Add an idempotency registry keyed by command + session set + fire/run ID + input hash. Same key/input returns prior result; same key/different input exits `idempotency_conflict`.

Test case: Run snapshot twice with same key/input and assert no new checkpoint; rerun same key with different session set and assert conflict.

## Concern 8 - Partial Install Failure After 5/8 Plists

Type: partial-failure / idempotency

Severity: HIGH

Current mitigation:

- Plist install rollback is per-session uninstall (`02-REFINE-r1.md:460`).
- Failed apply leaves `status=partial` and `next_safe_action` (`02-REFINE-r1.md:464`).
- B04-B11 are per-session installs depending on B03 (`02-REFINE-r1.md:582-590`).
- Phase 2 acceptance requires plist exists and is loaded for approved sessions (`02-REFINE-r1.md:517`).

Gap: Fleet install semantics are not declared as all-or-nothing or converge-forward.

Suggested fix: Default to converge-forward. Audit per-session `not_started|applied|already_current|failed|rolled_back`; rerun reads live state and resumes only missing/failed sessions.

Test case: Fixture fails session 6 after 1-5 succeed; rerun after fixing 6 and assert 1-5 skip while 6-8 apply once.

## Concern 9 - Crash Mid-Install And Resume

Type: partial-failure / crash recovery

Severity: HIGH

Current mitigation:

- Manifest tracks dispatch `in_flight` and `orphan_candidates` (`02-REFINE-r1.md:305-308`).
- Reboot marks in-flight dispatch without callback as `orphan_candidate` (`02-REFINE-r1.md:415`).
- Reboot during dispatch send uses state machine and replay guard (`02-REFINE-r1.md:686`).
- Phase 5 includes dispatch/callback orphan reconciliation (`02-REFINE-r1.md:563`).

Gap: Dispatch-orphan recovery exists, but recovery-operation orphans are not journaled.

Suggested fix: Add `runs/<run_id>.json` journal with step states `planned -> started -> applied|failed|skipped`, then resume by comparing journal and live probes.

Test case: Kill after config backup and before final rename; rerun same run ID and assert deterministic resume or exact cleanup block.

## Concern 10 - Lock File Discipline And Stale Locks

Type: race / partial-failure

Severity: HIGH

Current mitigation:

- State stores enumerate audit, snapshots, checkpoints, nightly, drills, topology, repo docs, and beads DB (`02-REFINE-r1.md:217-226`).
- Recovery prefers precise blocked preconditions over guessing (`02-REFINE-r1.md:241`).
- Beads DB WAL/lock corruption is covered as a failure mode (`02-REFINE-r1.md:692`).

Gap: No lock directory, owner schema, stale policy, or lock ordering exists.

Suggested fix: Add `~/.local/state/flywheel-recovery/locks/` with directory locks containing owner JSON and steal gates: PID dead, heartbeat stale, no active child process.

Test case: Create dead-PID stale lock and live-PID fresh lock; dry-run reports `would_steal` for stale and apply blocks on fresh.

## Concern 11 - Phase Ordering Invariants

Type: ordering

Severity: HIGH

Current mitigation:

- Restore state allows watcher install only after `path_ready` (`02-REFINE-r1.md:354-360`).
- Bead graph orders B01 -> B02 -> B03 -> B04-B11 -> B12 (`02-REFINE-r1.md:609-626`).
- Cycle validation forbids edges back to earlier phase (`02-REFINE-r1.md:629-632`).
- Watcher coverage is not reboot recovery without bootstrap (`02-REFINE-r1.md:517-519`).

Gap: Lower-level helper entry points could bypass phase preconditions if invoked directly.

Suggested fix: Every mutating command calls `precondition_check(form, session)` and exits 4 with `blocked_by` before writes.

Test case: Run per-session install on fixture with no `path_ready`; assert blocked exit and no plist/config write.

## Concern 12 - Checkpoint Name Collision

Type: idempotency / atomicity

Severity: MEDIUM

Current mitigation:

- Manifest checkpoint row stores `latest_id`, `export_path`, and `sha256` (`02-REFINE-r1.md:281-287`).
- Snapshot requires protected sessions in `checkpoint_ready` (`02-REFINE-r1.md:398`).
- Phase 3 requires latest verified checkpoint per session (`02-REFINE-r1.md:533`).
- Retention protects current manifest references (`02-REFINE-r1.md:432`).

Gap: Checkpoint ID/export path uniqueness is not specified; same timestamp/message could collide.

Suggested fix: Export path includes session, native checkpoint ID, and recovery run ID. Existing path with different hash blocks; matching hash returns idempotent prior result.

Test case: Fixture two snapshots with same message/timestamp; assert distinct run IDs or idempotent skip, never overwrite different content.

## Concern 13 - Watcher Restart Loop

Type: race / partial-failure

Severity: HIGH

Current mitigation:

- Missing sessions with loaded watcher plists are high/high risk (`02-REFINE-r1.md:703`).
- Boot helper runs before watchers latch (`02-REFINE-r1.md:511-512`).
- Launchd readiness and watcher race are in failure matrix (`02-REFINE-r1.md:687-688`).
- Launchd command drift has adapter/status probes (`02-REFINE-r1.md:710`).

Gap: KeepAlive/RunAtLoad, backoff, failure counts, and disabled-state behavior are not defined.

Suggested fix: Plist contract requires bounded retry/backoff or clean exit on missing prerequisites; watcher writes `watcher_status.<session>.json` with failure count and last exit.

Test case: Broken-command watcher fixture must report loop risk and disable/recommend uninstall instead of repeatedly bootstrapping.

## Concern 14 - Fuckup-Log Append Race

Type: race / atomicity

Severity: MEDIUM

Current mitigation:

- Fuckup-log is adopted as protected layer via B02/B12 (`02-REFINE-r1.md:650`).
- Raw `audit.jsonl` rows are retained then summarized/rotated (`02-REFINE-r1.md:430`).
- Helper writes audit before and after every mutating action (`02-REFINE-r1.md:234`).
- Failed apply leaves audit row with status and next safe action (`02-REFINE-r1.md:464`).

Gap: JSONL append locking and one-record write discipline are not specified.

Suggested fix: Recovery writes compact one-line JSON under append lock, preferably through existing flywheel-loop logger for global fuckup-log.

Test case: Parallel fixture appenders write 100 rows each; assert expected row count and `jq -c .` validity for every line.

## Concern 15 - Beads DB During Restore

Type: race

Severity: CRITICAL

Current mitigation:

- Manifest repo row includes `beads_integrity` (`02-REFINE-r1.md:288-293`).
- Beads DBs are protected by B02 and B12 (`02-REFINE-r1.md:645`).
- Beads local state/history are adopted in B02/B12 (`02-REFINE-r1.md:671-672`).
- Beads WAL/lock corruption is covered by inventory/integrity gate (`02-REFINE-r1.md:692`).

Gap: Restore may inspect or replay beads while live workers read/write; no SQLite snapshot/backup or quiescence rule exists.

Suggested fix: V1 restore should never replace `.beads/*.db`; it should require no active workers for mutating recovery, use read-only snapshot copy, and mark orphan work.

Test case: Concurrent writer fixture writes temp SQLite while restore audits; assert restore uses read-only snapshot copy and performs no DB mutation.

## Concern 16 - Schedule Cron Payload Uniqueness

Type: idempotency / race

Severity: MEDIUM

Current mitigation:

- Phase 4 uses local deterministic nightly helper and optional remote schedule after validation (`02-REFINE-r1.md:541-545`).
- Nightly JSONL receives aggregate and per-session rows (`02-REFINE-r1.md:550`).
- Local helper is recommended authority, remote schedule is nudge/monitor (`02-REFINE-r1.md:734-740`).
- Test plan includes seven nightly cycles and fake-session failure callback (`02-REFINE-r1.md:837-842`).

Gap: No cron fire ID is defined, so retries or duplicate schedule payloads can duplicate snapshots.

Suggested fix: Cron key `nightly:<local-date>:<scheduled-time>:<schedule-id>`; manual key `manual:<timestamp>:<operator>:<uuid>`. Same cron key returns prior result.

Test case: Simulate identical schedule payload twice and assert second invocation returns prior result without new checkpoint.

## Critical Race Conditions For Joshua Decision

1. Simultaneous restore of same session.
   - Severity: CRITICAL.
   - Decision needed: approve per-session restore locks before implementation.

2. Watcher/bootstrap firing during snapshot.
   - Severity: CRITICAL.
   - Decision needed: approve lock hierarchy shared by watcher, bootstrap, snapshot, restore.

3. Retention pruning while snapshot/export is writing.
   - Severity: CRITICAL.
   - Decision needed: require staging directories and publish-only-after-verify.

4. Beads DB access during restore.
   - Severity: CRITICAL.
   - Decision needed: v1 restore should inspect, never replace, Beads DBs.

## Common Patterns In Gaps

1. Principle exists but mechanical lock is missing.
   - The plan says dry-run, state machine, verified manifest, and blocked preconditions.
   - It needs lock files, acquisition, stale-lock recovery, and lock ordering.

2. Manifest has fields but no transaction contract.
   - `idempotency_key`, checkpoint IDs, dispatch state, health, and artifacts exist.
   - Implementation needs run journals and "same key same input" semantics.

3. Atomic write is named only for manifest.
   - Config, plists, audit JSONL, checkpoint archive, retention index, and nightly logs need explicit atomicity.

4. Partial failures are acknowledged but not replayable enough.
   - `status=partial` exists, but resume behavior needs step-level operation journals.

5. Tests are present but not concurrency-specific enough.
   - Add parallel restore, retention-vs-write, append race, stale/active lock, duplicate cron, and watcher-vs-snapshot tests.

## Lock-File Inventory

Recommended root:

```text
~/.local/state/flywheel-recovery/locks/
```

Required locks:

| Lock | Scope | Used by | Stale policy |
|---|---|---|---|
| `fleet.install.lock` | whole fleet install/config repair | install, repair paths | PID dead + heartbeat stale + no child command |
| `config.ntm.lock` | `~/.config/ntm/config.toml` | session path repair | no auto-steal if temp file exists |
| `session.<name>.lock` | per NTM session | watcher, snapshot, restore | steal only if owner dead and launchd not mid-step |
| `snapshot.<name>.lock` | checkpoint/export | snapshot, retention | retention never steals; snapshot may clean own stale staging |
| `restore.<name>.lock` | restore apply | restore | no auto-steal on protected sessions |
| `retention.lock` | retention pass | retention, snapshot publish | stale steal after heartbeat timeout |
| `audit-jsonl.lock` | recovery audit | mutating forms | short TTL; append only |
| `fuckup-log.lock` | global fuckup-log append if used | recovery + workers | prefer existing flywheel-loop logger |
| `schedule.lock` | cron registration | install/repair cron | no auto-steal without operator |
| `drill.lock` | E2E drill | drill runner | stale steal after test session cleanup |

Lock owner schema:

```json
{
  "schema_version": 1,
  "lock": "restore.flywheel.lock",
  "owner_pid": 12345,
  "owner_session": "flywheel",
  "owner_pane": 1,
  "command": "restore",
  "run_id": "2026-05-01T03:17:00Z-uuid",
  "created_at": "2026-05-01T03:17:00Z",
  "heartbeat_at": "2026-05-01T03:17:05Z",
  "protected": true
}
```

Lock ordering:

1. `fleet.install.lock`
2. `config.ntm.lock`
3. `session.<name>.lock`
4. `snapshot.<name>.lock` or `restore.<name>.lock`
5. `audit-jsonl.lock`

Never acquire a higher-order lock while holding a lower-order lock.

## Test-Plan Implications

Add these to r1 test plan:

1. Install idempotency: apply twice; assert stable config/plist hashes.
2. Partial install resume: fail session 6/8; rerun and verify skip/resume.
3. Snapshot while active: streaming pane during checkpoint; manifest marks best-effort.
4. Parallel restore: two restore commands; one blocked by lock.
5. Watcher during snapshot: watcher sees session lock and defers.
6. Retention while snapshot writes: staging exists; retention ignores it.
7. Crash mid-config write: kill between temp and rename; original survives.
8. Crash mid-restore: kill after live pre-checkpoint; resume blocks with exact next action.
9. JSONL append race: parallel appenders; valid JSON per line and expected count.
10. Beads DB restore read: concurrent writer; restore uses read-only snapshot copy.
11. Duplicate cron fire: same fire ID twice; second returns prior result.
12. Stale lock handling: dead PID vs live PID locks; dry-run/apply behavior differs.

## Bead Acceptance Additions

Add to B01:

- Defines lock hierarchy.
- Defines idempotency registry and conflict semantics.
- Defines atomic write contract per file class.

Add to B03:

- Proves config repair re-run is stable.
- Proves no duplicate TOML keys.
- Proves backup + temp + fsync + rename.

Add to B04-B11:

- Proves plist install re-run is stable.
- Proves matching plist is skipped.
- Proves per-session install lock.

Add to B12:

- Proves snapshot/retention lock interaction.
- Proves duplicate cron fire idempotency.
- Proves restore lock blocks simultaneous apply.
- Proves Beads DB is inspect-only in v1 restore.
- Proves interrupted snapshot recovery.

## Validation Ladder

1. >=15 distinct concerns evaluated:
   - PASS: 16 concerns evaluated.

2. Each concern has all 6 fields:
   - PASS: every concern includes Type, Severity, Current mitigation, Gap, Suggested fix, Test case.

3. Critical list present:
   - PASS: four critical race conditions listed.

4. Common-pattern synthesis >=3 patterns:
   - PASS: five common patterns listed.

5. Lock-file inventory complete:
   - PASS: root, locks, owner schema, and ordering included.

6. Test-plan implications listed:
   - PASS: twelve test additions listed.

7. NO fabrication; every concern has a plan-line citation:
   - PASS: each concern cites `02-REFINE-r1.md` line numbers.

8. Read-only; no mutations or test-runs of actual races:
   - PASS: this audit only read plan files and wrote the required output file.

9. `ladder_passed=yes` only if 1-8 clean:
   - PASS.

```text
ladder_passed=yes
concerns=16
criticals=4
races=7
```
