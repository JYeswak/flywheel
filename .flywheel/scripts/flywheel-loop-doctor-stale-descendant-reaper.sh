#!/usr/bin/env bash
# flywheel-loop-doctor-stale-descendant-reaper.sh
#
# oar1m cleanup primitive, 2026-05-19:
# flywheel:1 manually SIGKILLed stale PIDs 1737/2254/4546/4547/4551 from a
# Mon May 18 11:36 flywheel-loop doctor tree (~36h stale). The wedge path was
# bash flywheel-loop doctor -> check-cli-scoping.sh -> wait4path, where
# wait4path was stuck in kevent and survived SIGTERM.
set -euo pipefail

max_age_hours="1"
mode="dry-run"
json=0
root_pid=""

usage() {
  cat <<'EOF'
usage: flywheel-loop-doctor-stale-descendant-reaper.sh [--dry-run|--apply] [--json] [--max-age-hours N] [--root-pid PID]

Finds stale flywheel-loop doctor process trees that contain the oar1m runaway
shape: bash flywheel-loop doctor -> check-cli-scoping.sh ... wait4path ->
wait4path descendant. Dry-run is the default. --apply reaps leaf-first with
SIGTERM, waits 2s, then escalates surviving PIDs to SIGKILL.
EOF
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --dry-run) mode="dry-run"; shift ;;
    --apply) mode="apply"; shift ;;
    --json) json=1; shift ;;
    --max-age-hours) max_age_hours="${2:?missing value for --max-age-hours}"; shift 2 ;;
    --max-age-hours=*) max_age_hours="${1#*=}"; shift ;;
    --root-pid) root_pid="${2:?missing value for --root-pid}"; shift 2 ;;
    --root-pid=*) root_pid="${1#*=}"; shift ;;
    --help|-h) usage; exit 0 ;;
    *) printf 'unknown arg: %s\n' "$1" >&2; usage >&2; exit 2 ;;
  esac
done

case "$mode" in dry-run|apply) ;; *) printf 'invalid mode: %s\n' "$mode" >&2; exit 2 ;; esac
[[ "$max_age_hours" =~ ^[0-9]+([.][0-9]+)?$ ]] || { printf 'invalid --max-age-hours: %s\n' "$max_age_hours" >&2; exit 2; }
[[ -z "$root_pid" || "$root_pid" =~ ^[0-9]+$ ]] || { printf 'invalid --root-pid: %s\n' "$root_pid" >&2; exit 2; }

export FLYWHEEL_REAPER_MODE="$mode"
export FLYWHEEL_REAPER_JSON="$json"
export FLYWHEEL_REAPER_MAX_AGE_HOURS="$max_age_hours"
export FLYWHEEL_REAPER_ROOT_PID="$root_pid"

python3 - <<'PY'
import json
import os
import re
import signal
import subprocess
import sys
import time
from collections import defaultdict, deque
from datetime import datetime, timezone

SCHEMA = "flywheel-loop-doctor-stale-descendant-reaper/v1"
MODE = os.environ["FLYWHEEL_REAPER_MODE"]
AS_JSON = os.environ["FLYWHEEL_REAPER_JSON"] == "1"
MAX_AGE_HOURS = float(os.environ["FLYWHEEL_REAPER_MAX_AGE_HOURS"])
ROOT_PID_FILTER = os.environ.get("FLYWHEEL_REAPER_ROOT_PID") or ""
SELF_PIDS = {os.getpid(), os.getppid()}


def etime_seconds(value):
    value = value.strip()
    days = 0
    if "-" in value:
        day_s, value = value.split("-", 1)
        days = int(day_s)
    parts = [int(p) for p in value.split(":")]
    if len(parts) == 3:
        hours, minutes, seconds = parts
    elif len(parts) == 2:
        hours, minutes, seconds = 0, parts[0], parts[1]
    elif len(parts) == 1:
        hours, minutes, seconds = 0, 0, parts[0]
    else:
        return 0
    return days * 86400 + hours * 3600 + minutes * 60 + seconds


def load_processes():
    proc = subprocess.run(
        ["ps", "-axo", "pid=,ppid=,etime=,comm=,args="],
        text=True,
        capture_output=True,
        check=False,
    )
    rows = {}
    for line in proc.stdout.splitlines():
        parts = line.strip().split(None, 4)
        if len(parts) < 5:
            continue
        pid_s, ppid_s, etime, comm, args = parts
        if not pid_s.isdigit() or not ppid_s.isdigit():
            continue
        pid = int(pid_s)
        rows[pid] = {
            "pid": pid,
            "ppid": int(ppid_s),
            "etime": etime,
            "age_seconds": etime_seconds(etime),
            "comm": comm,
            "args": args,
        }
    return rows


def descendants(root, children):
    seen = []
    queue = deque(children.get(root, []))
    while queue:
        pid = queue.popleft()
        if pid in seen:
            continue
        seen.append(pid)
        queue.extend(children.get(pid, []))
    return seen


def depth_map(root, children):
    depths = {root: 0}
    queue = deque([(child, 1) for child in children.get(root, [])])
    while queue:
        pid, depth = queue.popleft()
        if pid in depths:
            continue
        depths[pid] = depth
        queue.extend((child, depth + 1) for child in children.get(pid, []))
    return depths


def is_alive(pid):
    try:
        os.kill(pid, 0)
        return True
    except ProcessLookupError:
        return False
    except PermissionError:
        return True


def send_signal(pid, sig):
    try:
        os.kill(pid, sig)
        return True
    except ProcessLookupError:
        return False
    except PermissionError:
        return False


def candidate_roots(processes):
    max_age_seconds = MAX_AGE_HOURS * 3600
    roots = []
    for pid, row in processes.items():
        args = row["args"]
        if ROOT_PID_FILTER and str(pid) != ROOT_PID_FILTER:
            continue
        if pid in SELF_PIDS:
            continue
        if row["age_seconds"] < max_age_seconds:
            continue
        if re.search(r"\bbash\b.*flywheel-loop\b.*\bdoctor\b", args):
            roots.append(pid)
    return roots


def classify_tree(root, processes, children):
    desc = descendants(root, children)
    checker = [
        pid for pid in desc
        if "check-cli-scoping.sh" in processes.get(pid, {}).get("args", "")
        and "wait4path" in processes.get(pid, {}).get("args", "")
    ]
    waiters = [
        pid for pid in desc
        if "wait4path" in processes.get(pid, {}).get("args", "")
        and pid not in checker
    ]
    if not checker or not waiters:
        return []
    depths = depth_map(root, children)
    pids = [root] + desc
    rows = []
    for pid in sorted(set(pids), key=lambda p: depths.get(p, 0), reverse=True):
        if pid in SELF_PIDS or pid not in processes:
            continue
        row = dict(processes[pid])
        row["depth"] = depths.get(pid, 0)
        row["root_pid"] = root
        rows.append(row)
    return rows


processes = load_processes()
children = defaultdict(list)
for pid, row in processes.items():
    children[row["ppid"]].append(pid)

candidates = []
for root in candidate_roots(processes):
    candidates.extend(classify_tree(root, processes, children))

dedup = {}
for row in candidates:
    dedup[row["pid"]] = row
candidates = sorted(dedup.values(), key=lambda r: (r["root_pid"], -r["depth"], r["pid"]))

actions = []
if MODE == "apply":
    term_targets = []
    for row in candidates:
        pid = row["pid"]
        if not is_alive(pid):
            actions.append({**row, "signal": "missing", "recovered": True, "signal_escalated": False})
            continue
        sent = send_signal(pid, signal.SIGTERM)
        term_targets.append(row)
        actions.append({**row, "signal": "SIGTERM", "recovered": False, "signal_escalated": False, "sent": sent})
    if term_targets:
        time.sleep(2)
    by_pid = {a["pid"]: a for a in actions}
    for row in term_targets:
        pid = row["pid"]
        action = by_pid[pid]
        if is_alive(pid):
            sent = send_signal(pid, signal.SIGKILL)
            time.sleep(0.05)
            action["signal"] = "SIGKILL"
            action["signal_escalated"] = True
            action["sent"] = sent
            action["recovered"] = not is_alive(pid)
        else:
            action["recovered"] = True
else:
    for row in candidates:
        actions.append({**row, "signal": "dry-run", "recovered": False, "signal_escalated": False})

residual = []
if MODE == "apply":
    for row in candidates:
        if is_alive(row["pid"]):
            residual.append(row["pid"])

envelope = {
    "schema_version": SCHEMA,
    "ts": datetime.now(timezone.utc).strftime("%Y-%m-%dT%H:%M:%SZ"),
    "mode": MODE,
    "max_age_hours": MAX_AGE_HOURS,
    "root_pid_filter": int(ROOT_PID_FILTER) if ROOT_PID_FILTER else None,
    "stale_descendant_count": len(candidates),
    "killed_count": sum(1 for a in actions if a.get("signal") in {"SIGTERM", "SIGKILL"} and a.get("recovered")),
    "signal_escalation_count": sum(1 for a in actions if a.get("signal_escalated")),
    "residual_count": len(residual),
    "residual_pids": residual,
    "candidates": [
        {
            "pid": r["pid"],
            "ppid": r["ppid"],
            "root_pid": r["root_pid"],
            "age_seconds": r["age_seconds"],
            "etime": r["etime"],
            "comm": r["comm"],
            "args": r["args"],
            "depth": r["depth"],
        }
        for r in candidates
    ],
    "actions": [
        {
            "pid": a["pid"],
            "age_seconds": a["age_seconds"],
            "etime": a["etime"],
            "comm": a["comm"],
            "signal": a["signal"],
            "recovered": bool(a.get("recovered")),
            "signal_escalated": bool(a.get("signal_escalated")),
        }
        for a in actions
    ],
}

if AS_JSON:
    print(json.dumps(envelope, separators=(",", ":")))
else:
    print(
        "flywheel-loop-doctor-stale-descendant-reaper "
        f"mode={MODE} stale_descendant_count={envelope['stale_descendant_count']} "
        f"killed_count={envelope['killed_count']} "
        f"signal_escalation_count={envelope['signal_escalation_count']} "
        f"residual_count={envelope['residual_count']}"
    )
    for row in envelope["candidates"]:
        print(f"candidate pid={row['pid']} ppid={row['ppid']} etime={row['etime']} comm={row['comm']} args={row['args']}")

sys.exit(1 if MODE == "apply" and residual else 0)
PY
