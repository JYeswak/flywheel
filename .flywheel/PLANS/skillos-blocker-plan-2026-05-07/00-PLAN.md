---
title: "skillos Blocker Plan — 2026-05-07"
type: plan
created: 2026-05-08
frontmatter_source: scaffold-doc-frontmatter
---

# skillos Blocker Plan — 2026-05-07

## 1. Root Cause Analysis

`state/blocker-tick-counters.json.current.blocker_id` is `skillos-storage_low_headroom-agentmail_fd_pressure`, with `status=escalated_waiting`, `ticks_survived=2`, `br_ready_count=20`, and `local_fix_attempts=[]`. Pre-probes show global disk and FD headroom are healthy: `/dev/disk3s1s1` is 12% used, Mac FD limits are high, and the Agent Mail process has ~15 FDs. The pressured surface is local perception: skillos has `.flywheel/` state accretion (`du=26M`, 239 top-level entries) and `state/` accretion (`du=3.7M`, 276 top-level entries). `.current.hypothesis` correctly says not to run live JSM sync/apply/upgrade and to keep `stop_local_retry=true` until a flywheel plan lands. `skillos-1uj` shows the callback grader originally failed with `callback_missing`, so normal-flow validation can falsely hold the blocker. `skillos-1jv` closed the live-probe guard but preserved a remaining gap: external daily mutation/read surfaces must be guarded before broad sync/apply/upgrade resumes.

## 2. Three-Step Remediation

### Step 1 — skillos Local State Cleanup

Add one-shot, idempotent script:

```bash
/Users/josh/Developer/skillos/.flywheel/scripts/skillos-local-state-prune.sh \
  --repo /Users/josh/Developer/skillos \
  --days 7 \
  --dry-run \
  --json

/Users/josh/Developer/skillos/.flywheel/scripts/skillos-local-state-prune.sh \
  --repo /Users/josh/Developer/skillos \
  --days 7 \
  --apply \
  --idempotency-key skillos-storage-low-headroom-2026-05-07 \
  --json
```

Adapt from flywheel prior art:

```bash
/Users/josh/Developer/flywheel/.flywheel/scripts/storage-prune.sh
```

Required behavior:

- Default `--dry-run`; never mutates unless `--apply` and `--idempotency-key` are both present.
- Archive, do not delete, into `/tmp/skillos-local-state-prune.<ts>/`.
- Target 1: `/Users/josh/Developer/skillos/.flywheel/agent-mail-fd-pressure-repair-*.json` older than 7 days.
- Target 2: `/Users/josh/Developer/skillos/state/blocker-escalations-*.jsonl` older than 7 days.
- Output JSON fields: `schema_version`, `repo`, `apply`, `idempotency_key`, `older_than_days`, `planned.files`, `planned.bytes`, `archived.files`, `archived.bytes`, `bytes_recovered`, `archive_dir`.
- Current dry-run probe found 0 matching old files for those two target globs; still ship the primitive because the blocker is recurring perception pressure, not current global exhaustion.

Acceptance:

```bash
bash -n /Users/josh/Developer/skillos/.flywheel/scripts/skillos-local-state-prune.sh
/Users/josh/Developer/skillos/.flywheel/scripts/skillos-local-state-prune.sh --repo /Users/josh/Developer/skillos --dry-run --json | jq -e '.apply == false and has("bytes_recovered")'
/Users/josh/Developer/skillos/.flywheel/scripts/skillos-local-state-prune.sh --repo /Users/josh/Developer/skillos --apply --json ; test $? -eq 2
```

### Step 2 — skillos-1jv External Daily Wrapper Hardening

Harden:

```bash
/Users/josh/.local/bin/claude-jsm-daily-sync.sh
/Users/josh/Developer/skillos/scripts/jsm_daily_version_upgrade_sync.py
```

Guard requirements:

- Mutation surface: `jsm sync`, `jsm apply`, `jsm upgrade`, `jsm update`, `jsm install`, `jsm push` must be unreachable from the daily wrapper unless `--apply` plus `--idempotency-key` plus valid sandbox-auth marker plus pre/post SQLite integrity receipts exist.
- Read surface: live reads must go through `scripts/jsm_guarded_runner.py live-probe batch` or a pre-collected manifest. No direct `jsm upgrade --list`, `jsm sync --status`, `jsm doctor`, or `jsm notify` from the external daily wrapper while the blocker is active.
- Fail closed on: missing guarded runner, missing/invalid sandbox auth marker, integrity precheck not `ok`, lock contention, missing manifest for upgrade planning, or any JSON receipt with `raw_live_jsm_used=true`.
- Default mode: dry-run/diagnose only. `--apply` must be explicit and must refuse without an idempotency key.

Pseudocode:

```bash
mode=dry-run
case "$1" in --apply) mode=apply ;; --dry-run|--diagnose|"") mode=dry-run ;; *) exit 2 ;; esac
[ "$mode" = apply ] && [ -n "${IDEMPOTENCY_KEY:-}" ] || mode=dry-run
python3 scripts/jsm_guarded_runner.py scheduled tick --dry-run --json >receipt.json || exit 4
jq -e '.lock.status=="acquired" and .lock.released==true and .integrity.pre.status=="ok" and .integrity.post.status=="ok" and .raw_live_jsm_used==false' receipt.json || exit 4
[ "$mode" = apply ] || exit 0
python3 scripts/jsm_daily_version_upgrade_sync.py apply --manifest "$MANIFEST" --idempotency-key "$IDEMPOTENCY_KEY" --json
```

Acceptance:

```bash
/Users/josh/.local/bin/claude-jsm-daily-sync.sh --diagnose
python3 /Users/josh/Developer/skillos/scripts/jsm_daily_version_upgrade_sync.py --fixture /Users/josh/Developer/skillos/tests/fixtures/jsm_daily_sync/mixed.json plan --output /tmp/skillos-jsm-daily-manifest.json --json
python3 /Users/josh/Developer/skillos/scripts/jsm_daily_version_upgrade_sync.py --fixture /Users/josh/Developer/skillos/tests/fixtures/jsm_daily_sync/mixed.json dry-run --manifest /tmp/skillos-jsm-daily-manifest.json --json
python3 -m unittest /Users/josh/Developer/skillos/tests/unit/test_jsm_daily_sync.py
bash /Users/josh/Developer/skillos/tests/e2e/e2e_jsm_daily_sync_dryrun.sh
```

### Step 3 — skillos-1uj Callback-Grading Repair

Broken assertion:

```text
orchestrator-callback-grade.py --task-id <manual-task> reports callback_missing when the callback was pane-visible/user-pasted but not imported into .flywheel/dispatch-log.jsonl.
```

Replacement:

```text
Manual dispatch is not gradable until both rows exist:
1. dispatch_sent row keyed by task_id
2. worker_callback_received row keyed by task_id with callback_received_at, callback_verdict, and capture_provenance
```

Concrete command path:

```bash
python3 /Users/josh/Developer/skillos/.flywheel/scripts/manual-dispatch-record.py \
  --repo /Users/josh/Developer/skillos \
  --task-id <task-id> \
  --task-file <prompt-file> \
  --apply \
  --json

python3 /Users/josh/Developer/skillos/.flywheel/scripts/import-user-pasted-callback.py \
  --repo /Users/josh/Developer/skillos \
  --task-id <task-id> \
  --verdict PASS \
  --callback-text-file <callback-file> \
  --apply \
  --json

python3 /Users/josh/Developer/skillos/.flywheel/scripts/orchestrator-callback-grade.py \
  --repo /Users/josh/Developer/skillos \
  --task-id <task-id> \
  --write-state \
  --json
```

Acceptance:

```bash
python3 -m unittest /Users/josh/Developer/skillos/tests/test_callback_grader_manual_dispatch.py
python3 /Users/josh/Developer/skillos/.flywheel/scripts/orchestrator-callback-grade.py --repo /Users/josh/Developer/skillos --latest-callback --write-state --json | jq -e '.callback.row_found == true and (.grade_reasons | index("callback_missing") | not)'
```

Manual dispatch callback must be graded within one tick; if import is needed, pane1 performs import before grading, not after blocker escalation.

## 3. Unblock Signal Contract

When resolved, skillos:1 writes this exact shape to `/Users/josh/Developer/skillos/state/blocker-tick-counters.json.current`:

```json
{
  "blocker_id": "skillos-storage_low_headroom-agentmail_fd_pressure",
  "status": "resolved",
  "resolved_by": "flywheel-plan-2026-05-07",
  "resolved_at": "<utc-iso8601>",
  "ticks_survived": 2,
  "br_ready_count": 20,
  "stop_local_retry": false,
  "evidence_paths": [
    "/Users/josh/Developer/flywheel/.flywheel/plans/skillos-blocker-plan-2026-05-07/00-PLAN.md",
    "<skillos-local-state-prune-receipt>",
    "<skillos-1jv-hardening-receipt>",
    "<skillos-1uj-callback-grade-receipt>"
  ],
  "verification": {
    "global_disk_used_pct": 12,
    "agentmail_fd_count": 15,
    "skillos_flywheel_dir_entries": "<measured-int>",
    "skillos_state_dir_entries": "<measured-int>",
    "local_state_prune_bytes_recovered": "<measured-int>",
    "callback_grading_pass_rate_24h": "<measured-number>",
    "manual_dispatch_callback_grade_latency_ticks": 1,
    "jsm_daily_wrapper_default_mode": "dry-run",
    "jsm_live_mutations_guarded": true
  }
}
```

Keep top-level `schema_version=skillos.blocker_tick_counters.v1`, append the prior `.current` to `history`, and update top-level `updated_at`.

## 4. Bead Proposals

1. `P0` — `Add skillos local state prune primitive`
   - Expected delta: new `.flywheel/scripts/skillos-local-state-prune.sh` plus focused tests.
   - Acceptance: dry-run default, `--apply` requires `--idempotency-key`, archives target globs older than 7 days, emits `bytes_recovered`, idempotent re-run shows zero new work.

2. `P0` — `Harden external daily JSM wrapper fail-closed`
   - Expected delta: `claude-jsm-daily-sync.sh` defaults to diagnose/dry-run and refuses live reads/mutations unless guarded-runner receipt is clean.
   - Acceptance: missing marker, missing manifest, lock contention, or integrity failure exits blocked; dry-run fixture tests pass; no raw live JSM commands in daily path.

3. `P0` — `Wire daily version-upgrade apply boundary`
   - Expected delta: `scripts/jsm_daily_version_upgrade_sync.py` consumes pre-collected manifests only; apply requires idempotency key and emits rollback/count receipt.
   - Acceptance: fixture plan/dry-run/apply-with-dry-run pass; direct live `jsm upgrade --list` remains forbidden; identity-drift rows refused.

4. `P0` — `Repair callback-grade manual dispatch one-tick path`
   - Expected delta: pane1 flow imports user-pasted/pane-visible callbacks before grading and uses timestamp-based latest callback selection.
   - Acceptance: `tests/test_callback_grader_manual_dispatch.py` passes; manual callback row drops `callback_missing`; grade artifact written within one tick.

5. `P1` — `Blocker counter resolved-state writer`
   - Expected delta: helper that atomically moves `.current` to `history` and writes the resolved JSON contract above.
   - Acceptance: schema preserved, `updated_at` refreshed, stale projection guard still validates bead ids before action, and no `escalated_waiting` row remains for this blocker after verification.

## Callback Notes

- No `br create` performed; these are proposals for skillos:1.
- L107 lsof gate: `lsof | grep skillos-blocker-plan` returned no rows before write.
- Socraticode survey used skillos and flywheel indexed source for blocker counters, daily JSM wrapper, callback grader, and storage-prune prior art.
