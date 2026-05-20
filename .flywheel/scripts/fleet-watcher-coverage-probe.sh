#!/usr/bin/env bash
set -euo pipefail

VERSION="fleet-watcher-coverage/v1"
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd -P)"
IDLE_PROBE="${FLYWHEEL_IDLE_STATE_PROBE:-$ROOT/.flywheel/scripts/idle-state-probe.sh}"
LOOPS_DIR="${FLYWHEEL_LOOP_STATE_DIR:-$HOME/.flywheel/loops}"
STATE_DIR="${FLYWHEEL_STATE_DIR:-$HOME/.local/state/flywheel}"
JSON_OUT=0
FLEET=1
SESSION_FILTER=""

usage() {
  cat <<'USAGE'
Usage:
  fleet-watcher-coverage-probe.sh [--json]
  fleet-watcher-coverage-probe.sh --session NAME [--json]
  fleet-watcher-coverage-probe.sh --info [--json]
  fleet-watcher-coverage-probe.sh --examples [--json]
  fleet-watcher-coverage-probe.sh --schema [--json]

Reports watcher coverage, idle ready workers, and stale dispatch count.
USAGE
}

emit_info() {
  if [[ "$JSON_OUT" -eq 1 ]]; then
    jq -nc --arg version "$VERSION" '{
      schema_version:$version,
      command:"fleet-watcher-coverage-probe.sh",
      purpose:"Expose idle-pane watcher coverage for doctor and status surfaces",
      doctor_fields:["fleet_watcher_coverage_count","fleet_watcher_coverage_total","fleet_idle_workers_with_ready_beads_count","fleet_watcher_last_dispatch_age_seconds"],
      canonical_flags:["--help","--info","--examples","--schema","--json","--session"]
    }'
  else
    printf '%s\n' "$VERSION"
  fi
}

emit_examples() {
  if [[ "$JSON_OUT" -eq 1 ]]; then
    jq -nc '{examples:[
      "fleet-watcher-coverage-probe.sh --json",
      "fleet-watcher-coverage-probe.sh --session alpsinsurance --json"
    ]}'
  else
    printf '%s\n' \
      "fleet-watcher-coverage-probe.sh --json" \
      "fleet-watcher-coverage-probe.sh --session alpsinsurance --json"
  fi
}

emit_schema() {
  jq -nc --arg version "$VERSION" '{
    "$schema":"https://json-schema.org/draft/2020-12/schema",
    title:"fleet watcher coverage probe output",
    type:"object",
    required:["schema_version","fleet_watcher_coverage_count","fleet_watcher_coverage_total","fleet_idle_workers_with_ready_beads_count","fleet_watcher_last_dispatch_age_seconds"],
    properties:{
      schema_version:{const:$version},
      fleet_watcher_coverage_count:{type:"integer"},
      fleet_watcher_coverage_total:{type:"integer"},
      fleet_idle_workers_with_ready_beads_count:{type:"integer"},
      fleet_watcher_last_dispatch_age_seconds:{type:["integer","null"]},
      stale_dispatches_count:{type:"integer"},
      rows:{type:"array"}
    }
  }'
}

for arg in "$@"; do
  [[ "$arg" == "--json" ]] && JSON_OUT=1
done

while [[ $# -gt 0 ]]; do
  case "$1" in
    --session) SESSION_FILTER="${2:?--session requires NAME}"; FLEET=0; shift 2 ;;
    --session=*) SESSION_FILTER="${1#*=}"; FLEET=0; shift ;;
    --json) JSON_OUT=1; shift ;;
    --help|-h) usage; exit 0 ;;
    --info) emit_info; exit 0 ;;
    --examples) emit_examples; exit 0 ;;
    --schema) emit_schema; exit 0 ;;
    --version) printf '%s\n' "$VERSION"; exit 0 ;;
    *) printf 'ERR: unknown argument: %s\n' "$1" >&2; usage >&2; exit 64 ;;
  esac
done

python3 - "$VERSION" "$ROOT" "$IDLE_PROBE" "$LOOPS_DIR" "$STATE_DIR" "$SESSION_FILTER" <<'PY'
import json
import subprocess
import sys
from datetime import datetime, timezone
from pathlib import Path
from typing import Any

version, root_raw, idle_probe_raw, loops_dir_raw, state_dir_raw, session_filter = sys.argv[1:]
root = Path(root_raw)
idle_probe = Path(idle_probe_raw)
loops_dir = Path(loops_dir_raw).expanduser()
state_dir = Path(state_dir_raw).expanduser()
now = datetime.now(timezone.utc)

FLEET = {
    "flywheel": {
        "repo": "/Users/josh/Developer/flywheel",
        "label": "com.zeststream.flywheel-idle-pane-watch",
        "plist": "/Users/josh/Library/LaunchAgents/com.zeststream.flywheel-idle-pane-watch.plist",
        "log": str(state_dir / "idle-pane-auto-dispatch.log"),
    },
    "alpsinsurance": {
        "repo": "/Users/josh/Developer/alpsinsurance",
        "label": "ai.zeststream.alps-idle-pane-watch",
        "plist": "/Users/josh/Library/LaunchAgents/ai.zeststream.alps-idle-pane-watch.plist",
        "log": str(state_dir / "idle-pane-watch.alpsinsurance.log"),
    },
    "skillos": {
        "repo": "/Users/josh/Developer/skillos",
        "label": "ai.zeststream.skillos-idle-pane-watch",
        "plist": "/Users/josh/Library/LaunchAgents/ai.zeststream.skillos-idle-pane-watch.plist",
        "log": str(state_dir / "idle-pane-watch.skillos.log"),
    },
    "mobile-eats": {
        "repo": "/Users/josh/Developer/mobile-eats",
        "label": "ai.zeststream.mobile-eats-idle-pane-watch",
        "plist": "/Users/josh/Library/LaunchAgents/ai.zeststream.mobile-eats-idle-pane-watch.plist",
        "log": str(state_dir / "idle-pane-watch.mobile-eats.log"),
    },
    "vrtx": {
        "repo": "/Users/josh/Developer/vrtx",
        "label": "ai.zeststream.vrtx-idle-pane-watch",
        "plist": "/Users/josh/Library/LaunchAgents/ai.zeststream.vrtx-idle-pane-watch.plist",
        "log": str(state_dir / "idle-pane-watch.vrtx.log"),
    },
}

def load_json(path: Path) -> dict[str, Any]:
    try:
        data = json.loads(path.read_text(encoding="utf-8"))
        return data if isinstance(data, dict) else {}
    except Exception:
        return {}

def parse_ts(value: Any):
    if not value:
        return None
    try:
        return datetime.fromisoformat(str(value).replace("Z", "+00:00")).astimezone(timezone.utc)
    except Exception:
        return None

def launchctl_loaded(label: str) -> bool:
    try:
        result = subprocess.run(["launchctl", "print", f"gui/{subprocess.check_output(['id','-u'], text=True).strip()}/{label}"], stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL, timeout=3)
        return result.returncode == 0
    except Exception:
        return False

def idle_ready_count(session: str, repo: str) -> int:
    if not idle_probe.exists() or not Path(repo).exists():
        return 0
    try:
        out = subprocess.check_output([str(idle_probe), "--session", session, "--repo", repo, "--json"], text=True, stderr=subprocess.DEVNULL, timeout=20)
        data = json.loads(out)
        return int((data.get("idle_state_summary") or {}).get("dispatching") or 0)
    except Exception:
        return 0

def read_jsonl(path: Path):
    if not path.exists():
        return []
    rows = []
    try:
        lines = path.read_text(encoding="utf-8", errors="replace").splitlines()
    except Exception:
        return rows
    for line in lines[-500:]:
        if not line.strip():
            continue
        try:
            row = json.loads(line)
        except Exception:
            continue
        if isinstance(row, dict):
            rows.append(row)
    return rows

def watcher_last_dispatch_age(session: str, repo: str, log: str):
    latest = None
    for row in read_jsonl(Path(log).expanduser()):
        if row.get("status") == "dispatched" or row.get("task_id"):
            latest = parse_ts(row.get("ts") or row.get("checked_at") or row.get("stall_detection_ts")) or latest
    for row in read_jsonl(Path(repo) / ".flywheel/dispatch-log.jsonl"):
        if row.get("event") in {"idle_pane_auto_dispatch", "ntm_dispatch_sent"} or row.get("from") == "flywheel:1-watcher-v4":
            latest = parse_ts(row.get("ts")) or latest
    if latest is None:
        return None
    return max(0, int((now - latest).total_seconds()))

def stale_dispatches(repo: str) -> int:
    count = 0
    for row in read_jsonl(Path(repo) / ".flywheel/dispatch-log.jsonl"):
        ts = parse_ts(row.get("ts"))
        if ts is None or (now - ts).total_seconds() <= 900:
            continue
        if row.get("callback_received_at") in (None, "", "null") and row.get("task_id"):
            count += 1
    return count

sessions = [session_filter] if session_filter else list(FLEET)
rows = []
for session in sessions:
    meta = dict(FLEET.get(session) or {})
    if not meta:
        continue
    loop_state = load_json(loops_dir / f"{session}.json")
    label = loop_state.get("watcher_label") or meta["label"]
    plist = loop_state.get("watcher_plist") or meta["plist"]
    loaded = launchctl_loaded(label)
    watcher_active = bool(loop_state.get("watcher_active") is True)
    repo = loop_state.get("repo") or meta["repo"]
    ready = idle_ready_count(session, repo)
    age = watcher_last_dispatch_age(session, repo, meta["log"])
    stale = stale_dispatches(repo)
    covered = bool(watcher_active and loaded)
    uncovered_ready = ready if not covered else 0
    rows.append({
        "session": session,
        "repo": repo,
        "watcher_label": label,
        "watcher_plist": plist,
        "watcher_active": watcher_active,
        "launchctl_loaded": loaded,
        "covered": covered,
        "idle_workers_ready_beads_observed": ready,
        "idle_workers_with_ready_beads": uncovered_ready,
        "last_dispatch_age_seconds": age,
        "stale_dispatches_count": stale,
        "loop_state_path": str(loops_dir / f"{session}.json"),
    })

coverage = sum(1 for row in rows if row["covered"])
ready_total = sum(int(row["idle_workers_with_ready_beads"]) for row in rows)
stale_total = sum(int(row["stale_dispatches_count"]) for row in rows)
ages = [row["last_dispatch_age_seconds"] for row in rows if row["last_dispatch_age_seconds"] is not None]
last_age = min(ages) if ages else None
total = len(rows)
dashboard = f"Watchers: {coverage}/{total} sessions | {ready_total} idle workers w/ ready beads | {stale_total} stale dispatches"

print(json.dumps({
    "schema_version": version,
    "checked_at": now.replace(microsecond=0).isoformat().replace("+00:00", "Z"),
    "fleet_watcher_coverage_count": coverage,
    "fleet_watcher_coverage_total": total,
    "fleet_idle_workers_with_ready_beads_count": ready_total,
    "fleet_watcher_last_dispatch_age_seconds": last_age,
    "stale_dispatches_count": stale_total,
    "dashboard_line": dashboard,
    "rows": rows,
}, separators=(",", ":")))
PY

# Meta-Learning Cross-References (2026-05-19)
# Batch-16 comment backfill; citations are documentation-only and do not alter runtime behavior.
# Related: `/Users/josh/Developer/skillos/.flywheel/doctrine/meta-learnings/MP-02-conformance-fixtures.md`
# Related: `/Users/josh/Developer/skillos/.flywheel/doctrine/meta-learnings/MP-68-schema-executable-validator-pair.md`
