#!/usr/bin/env bash
set -euo pipefail

VERSION="halt-disease-watchdog 1.0.0"
SESSIONS="flywheel,skillos,mobile-eats,clutterfreespaces"
WINDOW_MINUTES=30
JSON_OUT=0
QUIET=0
ONCE=0
LEDGER="${FLYWHEEL_HALT_DISEASE_WATCHDOG_LEDGER:-/Users/josh/.local/state/flywheel/halt-disease-watchdog.jsonl}"
NTM_BIN="${NTM_BIN:-/Users/josh/.local/bin/ntm}"
FLYWHEEL_LOOP="${FLYWHEEL_LOOP:-/Users/josh/.claude/skills/.flywheel/bin/flywheel-loop}"
TIMEOUT_SECONDS="${FLYWHEEL_HALT_WATCHDOG_TIMEOUT_SECONDS:-10}"

usage() {
  printf '%s\n' "usage: halt-disease-watchdog.sh [--sessions a,b,c] [--window-minutes N] [--json] [--quiet] [--once]"
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --sessions) SESSIONS="${2:?}"; shift 2 ;;
    --window-minutes) WINDOW_MINUTES="${2:?}"; shift 2 ;;
    --json) JSON_OUT=1; shift ;;
    --quiet) QUIET=1; shift ;;
    --once) ONCE=1; shift ;;
    --help|-h) usage; exit 0 ;;
    --version) printf '%s\n' "$VERSION"; exit 0 ;;
    *) printf 'ERR: unknown argument: %s\n' "$1" >&2; usage >&2; exit 64 ;;
  esac
done

export FLYWHEEL_HALT_WATCHDOG_SESSIONS="$SESSIONS"
export FLYWHEEL_HALT_WATCHDOG_WINDOW_MINUTES="$WINDOW_MINUTES"
export FLYWHEEL_HALT_WATCHDOG_LEDGER="$LEDGER"
export FLYWHEEL_HALT_WATCHDOG_NTM="$NTM_BIN"
export FLYWHEEL_HALT_WATCHDOG_LOOP="$FLYWHEEL_LOOP"
export FLYWHEEL_HALT_WATCHDOG_TIMEOUT="$TIMEOUT_SECONDS"
export FLYWHEEL_HALT_WATCHDOG_JSON_OUT="$JSON_OUT"
export FLYWHEEL_HALT_WATCHDOG_QUIET="$QUIET"

python3 - <<'PY'
import json
import os
import subprocess
import sys
from datetime import datetime, timezone
from pathlib import Path

REPO_MAP = {
    "flywheel": "/Users/josh/Developer/flywheel",
    "skillos": "/Users/josh/Developer/skillos",
    "mobile-eats": "/Users/josh/Developer/mobile-eats",
    "clutterfreespaces": "/Users/josh/Developer/clutterfreespaces",
}

sessions = [s.strip() for s in os.environ["FLYWHEEL_HALT_WATCHDOG_SESSIONS"].split(",") if s.strip()]
window_minutes = int(os.environ["FLYWHEEL_HALT_WATCHDOG_WINDOW_MINUTES"])
window_seconds = window_minutes * 60
ledger_path = Path(os.environ["FLYWHEEL_HALT_WATCHDOG_LEDGER"])
ntm_bin = os.environ["FLYWHEEL_HALT_WATCHDOG_NTM"]
loop_bin = os.environ["FLYWHEEL_HALT_WATCHDOG_LOOP"]
timeout_seconds = int(os.environ["FLYWHEEL_HALT_WATCHDOG_TIMEOUT"])
json_out = os.environ["FLYWHEEL_HALT_WATCHDOG_JSON_OUT"] == "1"
quiet = os.environ["FLYWHEEL_HALT_WATCHDOG_QUIET"] == "1"
now = datetime.now(timezone.utc)
now_s = now.strftime("%Y-%m-%dT%H:%M:%SZ")

def run_json(cmd, timeout=timeout_seconds, extra_env=None):
    try:
        env = os.environ.copy()
        if extra_env:
            env.update(extra_env)
        proc = subprocess.run(cmd, text=True, capture_output=True, timeout=timeout, env=env)
    except subprocess.TimeoutExpired:
        return None, {"cmd": cmd, "rc": 124, "error": "timeout"}
    if proc.returncode != 0:
        return None, {"cmd": cmd, "rc": proc.returncode, "error": proc.stderr.strip()[:500]}
    try:
        return json.loads(proc.stdout), None
    except Exception as exc:
        return None, {"cmd": cmd, "rc": proc.returncode, "error": f"invalid_json:{exc}", "stdout_head": proc.stdout[:500]}

def parse_ts(value):
    if not value:
        return None
    text = str(value).replace("Z", "+00:00")
    try:
        dt = datetime.fromisoformat(text)
    except Exception:
        return None
    if dt.tzinfo is None:
        dt = dt.replace(tzinfo=timezone.utc)
    return dt.astimezone(timezone.utc)

def age_seconds(value):
    dt = parse_ts(value)
    if not dt:
        return 0
    return max(0, int((now - dt).total_seconds()))

def read_ready_count(repo):
    path = Path(repo) / ".beads" / "issues.jsonl"
    count = 0
    if not path.exists():
        return 0, f"{path}:missing"
    for line in path.read_text(errors="ignore").splitlines():
        if not line.strip():
            continue
        try:
            row = json.loads(line)
        except Exception:
            continue
        status = str(row.get("status", "")).lower()
        priority = row.get("priority", 99)
        deps = row.get("dependencies") or []
        if status in {"open", "ready"} and isinstance(priority, int) and priority <= 1 and not deps:
            count += 1
    return count, str(path)

def recent_dispatch_count(repo, since_seconds):
    path = Path(repo) / ".flywheel" / "dispatch-log.jsonl"
    if not path.exists():
        return 0, f"{path}:missing"
    count = 0
    for line in path.read_text(errors="ignore").splitlines():
        if not line.strip():
            continue
        try:
            row = json.loads(line)
        except Exception:
            continue
        ts = row.get("ts") or row.get("created_at")
        if ts and age_seconds(ts) <= since_seconds and (
            row.get("event") == "ntm_dispatch_sent" or row.get("dispatch_status") == "sent"
        ):
            count += 1
    return count, str(path)

def doctor_contracts(doctor):
    if not isinstance(doctor, dict):
        return []
    contracts = []
    direct = doctor.get("halt_contract") or doctor.get("halt_contracts")
    if isinstance(direct, dict):
        contracts.append(direct)
    elif isinstance(direct, list):
        contracts.extend([x for x in direct if isinstance(x, dict)])
    routing = doctor.get("routing")
    if isinstance(routing, dict):
        contracts.extend([x for x in routing.values() if isinstance(x, dict) and x.get("schema_version") == "halt-contract/v1"])
    if contracts:
        return contracts
    status = str(doctor.get("status", "unknown")).lower()
    if status in {"fail", "error", "red"}:
        return [{
            "schema_version": "halt-contract/v1-inferred",
            "severity": "red",
            "blocked_actions": ["unknown_unscoped_doctor_fail"],
            "permitted_actions": [],
            "reason": "plain doctor status inferred conservatively",
        }]
    if status in {"warn", "warning", "yellow"}:
        return [{
            "schema_version": "halt-contract/v1-inferred",
            "severity": "yellow",
            "blocked_actions": ["unknown_scoped_doctor_warning"],
            "permitted_actions": ["plan", "validate", "dispatch_non_dangerous"],
            "reason": "plain doctor warn inferred with safe plan/validate work",
        }]
    return []

violations = []
dispatches_continued = {}
session_rows = {}

for session in sessions:
    repo = REPO_MAP.get(session, f"/Users/josh/Developer/{session}")
    ready_count, ready_evidence = read_ready_count(repo)
    recent_dispatches, dispatch_evidence = recent_dispatch_count(repo, window_seconds)
    recent_dispatches_10m, _ = recent_dispatch_count(repo, 600)
    activity, activity_error = run_json([ntm_bin, f"--robot-activity={session}", "--activity-type=codex,claude", "--json"])
    doctor, doctor_error = run_json(
        [loop_bin, "doctor", "--repo", repo, "--json"],
        extra_env={"FLYWHEEL_DOCTOR_NTM_HEALTH_DISABLED": "1"},
    )
    agents = activity.get("agents", []) if isinstance(activity, dict) else []
    idle_agents = []
    for agent in agents:
        state = str(agent.get("state", "")).upper()
        pane = agent.get("pane_idx", agent.get("pane"))
        idle_age = age_seconds(agent.get("state_since"))
        if state in {"WAITING", "IDLE"}:
            idle_agents.append({"pane": pane, "state": state, "age_seconds": idle_age})
    idle_over_window = [a for a in idle_agents if a["age_seconds"] >= window_seconds]
    if ready_count > 0 and idle_over_window:
        violations.append({
            "session": session,
            "repo": repo,
            "signal": "fleet_idle_with_ready_work",
            "severity": "critical",
            "blocked_actions": [],
            "permitted_actions": ["dispatch_ready_bead"],
            "evidence": f"{ready_evidence}; idle_panes={idle_over_window}",
        })
    contracts = doctor_contracts(doctor)
    yellow_contracts = [c for c in contracts if str(c.get("severity", "")).lower() == "yellow"]
    red_contracts = [c for c in contracts if str(c.get("severity", "")).lower() == "red"]
    if yellow_contracts:
        dispatches_continued[session] = recent_dispatches_10m
        if recent_dispatches_10m == 0:
            for contract in yellow_contracts:
                violations.append({
                    "session": session,
                    "repo": repo,
                    "signal": "yellow_without_permitted_work",
                    "severity": "high",
                    "blocked_actions": contract.get("blocked_actions", []),
                    "permitted_actions": contract.get("permitted_actions", []),
                    "evidence": f"doctor={contract.get('reason','yellow')}; dispatch_log={dispatch_evidence}",
                })
        for contract in yellow_contracts:
            if not contract.get("permitted_actions") and not contract.get("no_safe_work_reason"):
                violations.append({
                    "session": session,
                    "repo": repo,
                    "signal": "unscoped_yellow_halt",
                    "severity": "high",
                    "blocked_actions": contract.get("blocked_actions", []),
                    "permitted_actions": [],
                    "evidence": "yellow contract has no permitted_actions and no no_safe_work_reason",
                })
    if red_contracts and recent_dispatches_10m > 0:
        for contract in red_contracts:
            violations.append({
                "session": session,
                "repo": repo,
                "signal": "red_ignored",
                "severity": "critical",
                "blocked_actions": contract.get("blocked_actions", []),
                "permitted_actions": contract.get("permitted_actions", []),
                "evidence": f"red doctor contract plus {recent_dispatches_10m} dispatches in 10m",
            })
    if activity_error:
        violations.append({
            "session": session,
            "repo": repo,
            "signal": "activity_probe_failed",
            "severity": "high",
            "blocked_actions": [],
            "permitted_actions": ["retry_probe", "read_only_diagnosis"],
            "evidence": json.dumps(activity_error, sort_keys=True),
        })
    if doctor_error:
        violations.append({
            "session": session,
            "repo": repo,
            "signal": "doctor_probe_failed",
            "severity": "high",
            "blocked_actions": [],
            "permitted_actions": ["retry_probe", "read_only_diagnosis"],
            "evidence": json.dumps(doctor_error, sort_keys=True),
        })
    session_rows[session] = {
        "repo": repo,
        "ready_count": ready_count,
        "recent_dispatches_window": recent_dispatches,
        "recent_dispatches_10m": recent_dispatches_10m,
        "idle_agents": idle_agents,
        "doctor_status": doctor.get("status") if isinstance(doctor, dict) else None,
        "activity_error": activity_error,
        "doctor_error": doctor_error,
    }

fleet_idle = sum(1 for v in violations if v["signal"] == "fleet_idle_with_ready_work")
yellow_missing = sum(1 for v in violations if v["signal"] in {"yellow_without_permitted_work", "unscoped_yellow_halt"})
red_ignored = sum(1 for v in violations if v["signal"] == "red_ignored")
critical_count = sum(1 for v in violations if v["severity"] == "critical")
high_count = sum(1 for v in violations if v["severity"] == "high")
status = "healthy"
exit_code = 0
if critical_count:
    status = "critical"
    exit_code = 2
elif high_count:
    status = "high"
    exit_code = 1

row = {
    "schema_version": "halt-disease-watchdog/v1",
    "ts": now_s,
    "status": status,
    "fleet_idle_with_ready_work_count": fleet_idle,
    "joshua_mornings_with_idle_fleet_count": fleet_idle,
    "yellow_without_permitted_work_count": yellow_missing,
    "red_ignored_count": red_ignored,
    "joshua_mornings_with_idle_fleet_risk": fleet_idle >= 2,
    "dispatches_continued_per_doctor_yellow": dispatches_continued,
    "time_between_yellow_signal_and_halt_propagation_seconds": 0 if yellow_missing == 0 else None,
    "session_rows": session_rows,
    "violations": violations,
}
row["dashboard_line"] = (
    f"halt_disease status={status} idle_ready={fleet_idle} "
    f"yellow_no_work={yellow_missing} red_ignored={red_ignored} "
    f"joshua_morning_risk={str(row['joshua_mornings_with_idle_fleet_risk']).lower()}"
)

ledger_path.parent.mkdir(parents=True, exist_ok=True)
with ledger_path.open("a") as fh:
    fh.write(json.dumps(row, sort_keys=True) + "\n")

if json_out:
    print(json.dumps(row, sort_keys=True))
elif not quiet:
    print(row["dashboard_line"])
sys.exit(exit_code)
PY
