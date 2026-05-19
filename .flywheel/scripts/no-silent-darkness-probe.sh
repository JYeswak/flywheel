#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)"
REPO_ROOT_DEFAULT="$(cd "$SCRIPT_DIR/../.." && pwd -P)"
export NO_SILENT_DARKNESS_REPO_ROOT_DEFAULT="${NO_SILENT_DARKNESS_REPO_ROOT_DEFAULT:-$REPO_ROOT_DEFAULT}"

exec python3 - "$@" <<'PY'
import argparse
import glob
import json
import os
import subprocess
import sys
import time
from datetime import datetime, timezone
from pathlib import Path

VERSION = "2026-05-03.1"
NTM_BIN = Path(os.environ.get("NO_SILENT_DARKNESS_NTM_BIN", "/Users/josh/.local/bin/ntm"))
STATE_DIR = Path(os.environ.get("NO_SILENT_DARKNESS_STATE_DIR", str(Path.home() / ".local/state/flywheel")))
LOOP_STATE_DIR = Path(os.environ.get("NO_SILENT_DARKNESS_LOOP_STATE_DIR", str(Path.home() / ".local/state/flywheel-loop")))
LOOP_MARKER_DIR = Path(os.environ.get("NO_SILENT_DARKNESS_LOOP_MARKER_DIR", str(Path.home() / ".flywheel/loops")))


def parse_iso(value):
    if not value or not isinstance(value, str):
        return None
    raw = value.strip()
    if raw.endswith("Z"):
        raw = raw[:-1] + "+00:00"
    try:
        return datetime.fromisoformat(raw).timestamp()
    except Exception:
        return None


def now_iso():
    return datetime.now(timezone.utc).replace(microsecond=0).isoformat().replace("+00:00", "Z")


def parse_interval(value):
    raw = str(value or "").strip().lower()
    if not raw:
        return 1800
    try:
        return int(raw)
    except ValueError:
        pass
    units = {"s": 1, "m": 60, "h": 3600}
    suffix = raw[-1]
    if suffix in units:
        try:
            return int(float(raw[:-1]) * units[suffix])
        except ValueError:
            return 1800
    return 1800


def mtime_epoch(path):
    try:
        return Path(path).stat().st_mtime
    except OSError:
        return None


def signal_file_recent(name, paths, window):
    newest_path = None
    newest = None
    for pattern in paths:
        candidates = glob.glob(str(pattern)) if any(ch in str(pattern) for ch in "*?[") else [str(pattern)]
        for candidate in candidates:
            epoch = mtime_epoch(candidate)
            if epoch is not None and (newest is None or epoch > newest):
                newest = epoch
                newest_path = candidate
    if newest is None:
        return {"name": name, "ok": False, "age_seconds": None, "evidence": "no_candidate_file"}
    age = max(0, int(time.time() - newest))
    return {"name": name, "ok": age <= window, "age_seconds": age, "evidence": f"{newest_path} age_sec={age} window_sec={window}"}


def read_json(path):
    try:
        return json.loads(Path(path).read_text())
    except Exception:
        return {}


def latest_topology(session):
    path = STATE_DIR / "session-topology.jsonl"
    latest = {}
    try:
        for line in path.read_text(errors="replace").splitlines():
            if not line.strip():
                continue
            try:
                row = json.loads(line)
            except Exception:
                continue
            if row.get("session") == session:
                latest = row
    except Exception:
        pass
    return latest


def pane_key(value):
    try:
        return str(int(value))
    except Exception:
        return str(value or "").strip()


def worker_panes(marker, topology):
    panes = set()
    for item in topology.get("worker_panes") or []:
        panes.add(pane_key(item.get("pane") if isinstance(item, dict) else item))
    if marker.get("worker_pane") is not None:
        panes.add(pane_key(marker.get("worker_pane")))
    return {pane for pane in panes if pane}


def signal_pane_state(session, marker, interval):
    if not NTM_BIN.exists():
        return {"name": "pane_state_changed_since_last_tick", "ok": False, "age_seconds": None, "evidence": f"ntm_missing:{NTM_BIN}"}
    try:
        proc = subprocess.run(
            [str(NTM_BIN), f"--robot-activity={session}", "--activity-type=codex,claude"],
            text=True,
            stdout=subprocess.PIPE,
            stderr=subprocess.PIPE,
            timeout=10,
            check=False,
        )
    except Exception as exc:
        return {"name": "pane_state_changed_since_last_tick", "ok": False, "age_seconds": None, "evidence": f"ntm_failed:{exc}"}
    if proc.returncode != 0:
        return {"name": "pane_state_changed_since_last_tick", "ok": False, "age_seconds": None, "evidence": proc.stderr.strip()[:180]}
    try:
        payload = json.loads(proc.stdout)
    except Exception:
        return {"name": "pane_state_changed_since_last_tick", "ok": False, "age_seconds": None, "evidence": "robot_activity_non_json"}
    topology = latest_topology(session)
    panes = worker_panes(marker, topology)
    orch = pane_key(topology.get("orchestrator_pane") or marker.get("orchestrator_pane"))
    recent = []
    ages = []
    considered = 0
    now = time.time()
    for agent in payload.get("agents") or []:
        pane = pane_key(agent.get("pane") or agent.get("pane_idx"))
        if not pane:
            continue
        if panes and pane not in panes:
            continue
        if not panes and orch and pane == orch:
            continue
        considered += 1
        since = parse_iso(agent.get("state_since"))
        if since is None:
            continue
        age = max(0, int(now - since))
        ages.append(age)
        if age <= interval:
            recent.append(f"pane={pane} state={agent.get('state')} age_sec={age}")
    if recent:
        return {"name": "pane_state_changed_since_last_tick", "ok": True, "age_seconds": min(ages) if ages else None, "evidence": "; ".join(recent[:4])}
    age = min(ages) if ages else None
    return {"name": "pane_state_changed_since_last_tick", "ok": False, "age_seconds": age, "evidence": f"no_recent_worker_state considered={considered} window_sec={interval}"}


def jsonl_rows(path):
    try:
        for line in Path(path).read_text(errors="replace").splitlines():
            if not line.strip():
                continue
            try:
                yield json.loads(line)
            except Exception:
                continue
    except Exception:
        return


def newest_callback(repo, session, window):
    newest_path = None
    newest = None
    for path in [repo / ".flywheel/dispatch-log.jsonl", STATE_DIR / "dispatch-log.jsonl"]:
        for row in jsonl_rows(path):
            if row.get("session") and session != "flywheel" and row.get("session") != session:
                continue
            epoch = parse_iso(row.get("callback_received_at"))
            if epoch is not None and (newest is None or epoch > newest):
                newest = epoch
                newest_path = path
    if newest is None:
        return {"name": "callback_received_in_last_2_ticks", "ok": False, "age_seconds": None, "evidence": "no_callback_received_at"}
    age = max(0, int(time.time() - newest))
    return {"name": "callback_received_in_last_2_ticks", "ok": age <= window, "age_seconds": age, "evidence": f"{newest_path} callback_age_sec={age} window_sec={window}"}


def row_matches(row, project, repo):
    if row.get("session") == project or row.get("project") == project:
        return True
    if row.get("repo") == str(repo) or row.get("git_repo") == str(repo):
        return True
    return project == "flywheel" and not (row.get("session") or row.get("project") or row.get("repo") or row.get("git_repo"))


def signal_fuckup_decisions(project, repo, interval):
    since = time.time() - interval
    processed = [
        row for row in jsonl_rows(STATE_DIR / "fuckup-processed.jsonl")
        if (parse_iso(row.get("processed_at") or row.get("callback_received_at") or row.get("ts") or row.get("created_at")) or 0) >= since
        and row_matches(row, project, repo)
    ]
    if processed:
        return {"name": "fuckup_log_decisions_made_since_last_tick", "ok": True, "age_seconds": 0, "evidence": f"processed_rows={len(processed)} window_sec={interval}"}
    recent_fuckups = [
        row for row in jsonl_rows(STATE_DIR / "fuckup-log.jsonl")
        if (parse_iso(row.get("ts") or row.get("created_at")) or 0) >= since and row_matches(row, project, repo)
    ]
    if not recent_fuckups:
        return {"name": "fuckup_log_decisions_made_since_last_tick", "ok": True, "age_seconds": 0, "evidence": f"no_recent_project_fuckups_to_decide window_sec={interval}"}
    return {"name": "fuckup_log_decisions_made_since_last_tick", "ok": False, "age_seconds": None, "evidence": f"recent_project_fuckups_without_processed_row={len(recent_fuckups)}"}


def count_recent_recoveries(repo, interval, unknown_only=False):
    since = time.time() - interval
    count = 0
    path = STATE_DIR / "frozen-strike-counter.jsonl"
    for row in jsonl_rows(path):
        epoch = parse_iso(row.get("ts") or row.get("created_at") or row.get("callback_received_at"))
        if epoch is None or epoch < since:
            continue
        action = str(row.get("action") or row.get("recovery_action") or row.get("status") or "").lower()
        encoded = json.dumps(row, sort_keys=True).lower()
        recovered = any(token in action for token in ("recover", "respawn", "relaunch"))
        if not recovered:
            continue
        if unknown_only and "unknown" not in encoded:
            continue
        count += 1
    return count


def build_report(args):
    repo = Path(args.repo).resolve()
    project = args.project
    marker = read_json(LOOP_MARKER_DIR / f"{project}.json")
    interval = args.interval_seconds or parse_interval(marker.get("interval"))
    session = marker.get("session") or project
    signals = [
        signal_file_recent("ledger_writes_since_last_tick", [LOOP_STATE_DIR / f"last_tick_{project}.json", STATE_DIR / "gap-hunt.jsonl", repo / ".flywheel/dispatch-log.jsonl"], interval),
        signal_pane_state(session, marker, interval),
        signal_file_recent("receipt_files_written_since_last_tick", [repo / ".flywheel/ticks/*.json", repo / ".flywheel/last_closeout_receipt.json", LOOP_STATE_DIR / f"last_tick_{project}.json"], interval),
        newest_callback(repo, session, interval * 2),
        signal_fuckup_decisions(project, repo, interval),
    ]
    present = sum(1 for signal in signals if signal["ok"])
    failed = [signal["name"] for signal in signals if not signal["ok"]]
    silent_dark_minutes = 0 if present == 5 else max(1, int(interval / 60))
    false_recovery_count = count_recent_recoveries(repo, interval, unknown_only=False)
    unknown_autorecovery_count = count_recent_recoveries(repo, interval, unknown_only=True)
    violations = []
    if silent_dark_minutes > 0 or present < 5:
        violations.append({
            "severity": "SOFT",
            "class": "orch_silent_darkness_breach",
            "halt_consumer": True,
            "reason": "silent_dark_minutes>0 or L60_signals_present<5/5",
            "failed_signals": failed,
        })
    verdict = "HEALTHY" if present == 5 else ("DEAD" if len(failed) >= 3 else "LIMPING")
    return {
        "success": True,
        "schema_version": 1,
        "mode": "doctor" if args.doctor else "probe",
        "checked_at": now_iso(),
        "version": VERSION,
        "project": project,
        "session": session,
        "repo": str(repo),
        "interval_seconds": interval,
        "goal": "NO_SILENT_DARKNESS",
        "verdict": verdict,
        "metrics": {
            "silent_dark_minutes": {"value": silent_dark_minutes, "target": 0},
            "blackout_detection_latency_p95_minutes": {"value": 0 if present == 5 else int(interval / 60), "target_lte": 2},
            "false_recovery_count": {"value": false_recovery_count, "target": 0},
            "unknown_autorecovery_count": {"value": unknown_autorecovery_count, "target": 0},
            "L60_signals_present": {"value": present, "target": 5, "total": 5},
        },
        "signals": signals,
        "violations": violations,
        "contract": {
            "producer": "last_tick receipts, ntm robot activity, dispatch-log callbacks, fuckup processed ledger",
            "measurement_command": ".flywheel/scripts/no-silent-darkness-probe.sh --doctor --json",
            "consumer": "/flywheel:tick Step 3a and flywheel doctor wrappers halt dispatch/recovery on orch_silent_darkness_breach",
            "promotion": "SOFT violation now; promote to fail after C5 consumes this contract in tick receipts",
        },
    }


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--doctor", action="store_true")
    parser.add_argument("--json", action="store_true")
    parser.add_argument("--repo", default=os.environ.get("NO_SILENT_DARKNESS_REPO_ROOT_DEFAULT", "/Users/josh/Developer/flywheel"))
    parser.add_argument("--project", default="flywheel")
    parser.add_argument("--interval-seconds", type=int, default=0)
    args = parser.parse_args()
    report = build_report(args)
    if args.json or args.doctor:
        print(json.dumps(report, sort_keys=True))
    else:
        print(f"{report['goal']} {report['verdict']} L60={report['metrics']['L60_signals_present']['value']}/5")
    return 0


if __name__ == "__main__":
    sys.exit(main())
PY

# Meta-Learning Cross-References (2026-05-19)
# Batch-16 comment backfill; citations are documentation-only and do not alter runtime behavior.
# Related: `/Users/josh/Developer/skillos/.flywheel/doctrine/meta-learnings/MP-02-conformance-fixtures.md`
# Related: `/Users/josh/Developer/skillos/.flywheel/doctrine/meta-learnings/MP-68-schema-executable-validator-pair.md`
