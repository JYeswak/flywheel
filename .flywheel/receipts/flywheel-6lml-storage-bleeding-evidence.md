# flywheel-6lml storage bleeding evidence

Task: `flywheel-6lml`
Status: active bleeding response
Evidence date: 2026-05-08

## First Probe

Command:

```bash
df -h /
df -h / /System/Volumes/Data
.flywheel/scripts/storage-probe.sh --json | jq '{status,disk_free_gb,disk_free_pct,developer_dir_gb,local_state_gb,qdrant_volumes_size_mb,tmp_dispatch_artifacts_count,errors}'
```

Results:

- `/`: `16Gi` available.
- `/System/Volumes/Data`: `887Gi` used, `16Gi` available, `99%` capacity.
- Storage probe: `status=fail`, `disk_free_gb=15.79`, `disk_free_pct=1.7`.
- Storage error: `storage_low_headroom`, below `threshold_pct=10`.

Verdict: active bleeding / emergency headroom. This is not stale-resolved.

## Source Checks

- Read `feedback_storage_pressure_blocks_substrate.md`: below 10% is substrate breaker; below 5% is emergency serialization/cleanup territory.
- Read `feedback_private_tmp_accretes_until_disk_dies.md`: `/private/tmp` growth is a silent disk killer; prune is allowlist-gated and host cleanup must not become ad-hoc deletion.
- Read `.flywheel/scripts/storage-prune.sh`: repo-local prune is dry-run first and does not prune Docker volumes.
- Checked `.flywheel/scripts/private-tmp-prune.sh` and `.flywheel/scripts/tmp-prune.sh` dry-run surfaces.
- Read `user_joshua_lens_judgment_depth.md`: Joshua lens must cite operator-grade durability, team-fit, company-building leverage, or turnover resilience.

## Socraticode Survey

Required K=10 searches against `/Users/josh/Developer/flywheel`: 5.

Findings:

- `AGENTS.md` L72: doctor fails when `disk_free_pct < 10`; daily Jeff ingest and growth jobs must run storage preflight before pulls/mirrors/indexing.
- `AGENTS.md` L124: substrate-discipline work should use encoded safe primitives rather than pausing for manual direction.
- `README.md`: storage probe and doctor expose `.storage`; `<5%` free triggers priority alert path.
- `tests/private-tmp-prune.sh`: `/private/tmp` cleanup is an allowlist-gated primitive.
- Halt-disease fixture: low storage must block growth-heavy actions while preserving safe non-growth work.

## Read-Only Discovery

Commands:

```bash
.flywheel/scripts/storage-prune.sh --repo /Users/josh/Developer/flywheel --dry-run --json --idempotency-key flywheel-6lml
.flywheel/scripts/private-tmp-prune.sh --dry-run --json
.flywheel/scripts/tmp-prune.sh --dry-run --json
ps -axo pid=,ppid=,stat=,comm=,args= | rg -i 'socraticode|qdrant|comfy|jeff-corpus|index|embedding|ollama|alps|beads-rust|mobile-eats-next-dev-cache|pytest|cargo|ffmpeg'
launchctl list | rg -i 'socraticode|cass|comfy|qdrant|jeff|storage|tmp|prune|flywheel'
```

Results:

- Repo-local storage prune planned no reclaim: stale backups `0`, tmp dispatch artifacts `0`, recovery archives `0`, stale Beads sidecars `0`, Jeff corpus archives `0`.
- Private tmp prune dry-run found no allowlisted flywheel candidates.
- tmp prune dry-run found no candidates.
- `com.cass.autoindex` / `cass index` was active during process inventory and held a 20GB CASS database plus WAL writer under `~/Library/Application Support/com.coding-agent-search.coding-agent-search/`.
- ALPS headless Chrome sandbox tree was active under `/private/tmp/alps-3lens-audit/profile2` with open write handles.
- ComfyUI MCP and Socraticode MCP servers existed, but no ComfyUI build/generation process was identified from the process inventory.

## Pause Actions

Host-tier reclaim/delete was not performed.

Workers identified: 2.

1. `cass-autoindex`
   - Inventory showed PID `95216` as `/Users/josh/.local/bin/cass index`.
   - It exited before pause application.
   - Receipt issued as quiescent, not stopped:
     `~/.local/state/flywheel/storage-pause-receipts/cass-autoindex-quiescent.20260508T043226Z.json`.

2. `alps-headless-chrome`
   - PIDs stopped with reversible `SIGSTOP`: `37581`, `37607`, `37608`, `37609`, `37618`, `37619`, `37652`, `40241`.
   - Verified post-pause state is `T` for each process.
   - Receipt:
     `~/.local/state/flywheel/storage-pause-receipts/alps-headless-chrome.20260508T043121Z.json`.

Doctor-readable signal:

```text
~/.local/state/flywheel/storage-pause-active.json
```

Signal fields:

- `schema_version=storage-pause-active/v1`
- `storage_pause_active=true`
- `doctor_signal_path=/Users/josh/.local/state/flywheel/storage-pause-active.json`
- `paused_workers[0].status=already_quiescent`
- `paused_workers[1].status=paused_sigstop`
- `forced_decision_options=["reclaim_now","pause_indexing","accept_5pct_floor"]`

## Auto-Resume Hook

Added:

```text
.flywheel/scripts/storage-pause-auto-resume.sh
tests/storage-pause-auto-resume.sh
```

Behavior:

- Default dry-run.
- Reads `~/.local/state/flywheel/storage-pause-active.json`.
- Waits for a reclaim receipt under `~/.local/state/flywheel/reclaim-receipts`.
- On `--apply`, sends `SIGCONT` to paused PIDs recorded in the active signal.

Validation:

```bash
TMPDIR=/var/folders/d0/09qgt_0n1m1ff8nyzbxppx9c0000gn/T/6lml.XXXXXX.zMV6X0s0V4 bash tests/storage-pause-auto-resume.sh
.flywheel/scripts/storage-pause-auto-resume.sh --json | jq '{status, state_path, reclaim_receipt, resumed_count}'
```

Results:

- `PASS storage-pause-auto-resume`
- Current hook status: `waiting_for_reclaim_receipt`, `resumed_count=0`.

## Joshua Alert

Command:

```bash
/Users/josh/.local/bin/notify "STORAGE BLEEDING: 1.7% free" "Paused ALPS headless Chrome sandbox; CASS autoindex already quiescent. Decision needed: reclaim_now, keep pause_indexing, or accept_5pct_floor."
```

Result:

- `notify` returned success.
- Forced decision surfaced: `reclaim_now`, `pause_indexing`, or `accept_5pct_floor`.

## Joshua 25-Year Ops Lens

Storage bleed during an active session is the silent ops emergency. Joshua's 25-year operations-management lens says pause first, ask second when the substrate is at risk: preserving WAL/JSONL reliability beats preserving growth throughput. The durable pattern is operator-grade: identify growth workers, pause reversible work with receipts, expose a doctor-readable signal, and leave host-tier reclaim or threshold acceptance as an explicit human decision.

## Acceptance Summary

- Probe first: PASS.
- Active bleeding path selected: PASS (`disk_free_pct=1.7`).
- In-flight disk-growth workers identified: PASS (`cass-autoindex`, `alps-headless-chrome`).
- Pause receipts issued: PASS (2 receipts; one stopped worker, one quiescent worker).
- Doctor-readable `storage_pause_active=true` signal: PASS.
- Auto-resume hook on reclaim receipt: PASS.
- Joshua forced decision surfaced: PASS.
- Host-tier reclaim/delete avoided: PASS.
