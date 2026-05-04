#!/usr/bin/env bash
set -euo pipefail

VERSION="headless-browser-probe.v1"
MAX_COUNT="${FLYWHEEL_HEADLESS_BROWSER_MAX_COUNT:-5}"
MAX_OLDEST_MINUTES="${FLYWHEEL_HEADLESS_BROWSER_MAX_OLDEST_MINUTES:-60}"
PRIMARY_PROFILE="${FLYWHEEL_CHROME_PRIMARY_PROFILE:-$HOME/Library/Application Support/Google/Chrome}"
HISTORY="${FLYWHEEL_HEADLESS_BROWSER_REAP_HISTORY:-$HOME/.local/state/flywheel/headless-browser-reaps.jsonl}"
FIXTURE=""
NOW_EPOCH=""

usage() {
  printf '%s\n' \
    "Usage:" \
    "  headless-browser-probe.sh [--json] [--doctor]" \
    "  headless-browser-probe.sh --fixture PATH [--now-epoch EPOCH] [--json]" \
    "  headless-browser-probe.sh --schema|--info|--examples|--help" \
    "" \
    "Detects orphaned agent-browser-chrome processes without touching the primary Chrome profile."
}

examples() {
  printf '%s\n' \
    "Examples:" \
    "  .flywheel/scripts/headless-browser-probe.sh --json" \
    "  .flywheel/scripts/headless-browser-probe.sh --doctor --json" \
    "  .flywheel/scripts/headless-browser-probe.sh --fixture /tmp/ps-fixture.txt --now-epoch 1777850400 --json"
}

schema_json() {
  jq -nc '{
    "$schema":"https://json-schema.org/draft/2020-12/schema",
    title:"flywheel headless browser leak probe",
    type:"object",
    required:["version","status","headless_agent_browser_count","agent_browser_processes","oldest_age_minutes","total_memory_mb","thresholds","errors","warnings"],
    properties:{
      status:{enum:["pass","fail"]},
      headless_agent_browser_count:{type:"integer"},
      oldest_age_minutes:{type:"integer"},
      total_memory_mb:{type:"number"}
    }
  }'
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --json|--doctor)
      shift ;;
    --fixture)
      FIXTURE="${2:?missing fixture path}"; shift 2 ;;
    --now-epoch)
      NOW_EPOCH="${2:?missing epoch}"; shift 2 ;;
    --schema)
      schema_json; exit 0 ;;
    --info)
      jq -nc --arg version "$VERSION" --arg history "$HISTORY" --arg primary "$PRIMARY_PROFILE" \
        '{version:$version,history_path:$history,primary_chrome_profile:$primary,thresholds:{max_count:5,max_oldest_age_minutes:60}}'
      exit 0 ;;
    --examples)
      examples; exit 0 ;;
    --help|-h)
      usage; exit 0 ;;
    *)
      printf 'unknown argument: %s\n' "$1" >&2
      usage >&2
      exit 2 ;;
  esac
done

if [[ -n "$FIXTURE" ]]; then
  if [[ ! -f "$FIXTURE" ]]; then
    jq -nc --arg path "$FIXTURE" '{version:"headless-browser-probe.v1",status:"fail",headless_agent_browser_count:0,agent_browser_processes:[],oldest_age_minutes:0,total_memory_mb:0,thresholds:{max_count:5,max_oldest_age_minutes:60},errors:[{code:"fixture_missing",path:$path}],warnings:[]}'
    exit 1
  fi
  PS_INPUT="$(cat "$FIXTURE")"
else
  PS_INPUT="$(ps -axo pid=,ppid=,lstart=,rss=,command=)"
fi

export PS_INPUT VERSION MAX_COUNT MAX_OLDEST_MINUTES PRIMARY_PROFILE HISTORY NOW_EPOCH
python3 - <<'PY'
import datetime as dt
import hashlib
import json
import os
import re
import shlex
import sys

version = os.environ["VERSION"]
max_count = int(float(os.environ["MAX_COUNT"]))
max_oldest = int(float(os.environ["MAX_OLDEST_MINUTES"]))
primary_profile = os.path.expanduser(os.environ["PRIMARY_PROFILE"])
history = os.path.expanduser(os.environ["HISTORY"])
now_epoch = os.environ.get("NOW_EPOCH", "")
now = dt.datetime.fromtimestamp(float(now_epoch), dt.timezone.utc) if now_epoch else dt.datetime.now(dt.timezone.utc)
ps_input = os.environ.get("PS_INPUT", "")

line_re = re.compile(
    r"^\s*(?P<pid>\d+)\s+(?P<ppid>\d+)\s+"
    r"(?P<lstart>[A-Z][a-z]{2}\s+[A-Z][a-z]{2}\s+\d{1,2}\s+\d{2}:\d{2}:\d{2}\s+\d{4})\s+"
    r"(?P<rss>\d+)\s+(?P<command>.*)$"
)

def parse_lstart(value):
    normalized = re.sub(r"\s+", " ", value.strip())
    parsed = dt.datetime.strptime(normalized, "%a %b %d %H:%M:%S %Y")
    return parsed.replace(tzinfo=dt.datetime.now().astimezone().tzinfo).astimezone(dt.timezone.utc)

def user_data_dir(command):
    try:
        parts = shlex.split(command)
    except ValueError:
        parts = command.split()
    for idx, part in enumerate(parts):
        if part.startswith("--user-data-dir="):
            return part.split("=", 1)[1]
        if part == "--user-data-dir" and idx + 1 < len(parts):
            return parts[idx + 1]
    match = re.search(r"--user-data-dir=(\S+)", command)
    return match.group(1) if match else ""

processes = []
warnings = []
for raw in ps_input.splitlines():
    match = line_re.match(raw)
    if not match:
        if "agent-browser-chrome" in raw:
            warnings.append({"code": "ps_line_unparsed", "line_hash": hashlib.sha256(raw.encode()).hexdigest()[:16]})
        continue
    command = match.group("command")
    udir = user_data_dir(command)
    if "agent-browser-chrome" not in udir:
        continue
    if udir and os.path.abspath(os.path.expanduser(udir)).startswith(os.path.abspath(primary_profile)):
        continue
    if "Google/Chrome" in command and "agent-browser-chrome" not in command and "agent-browser-chrome" not in udir:
        continue
    try:
        start = parse_lstart(match.group("lstart"))
    except ValueError:
        warnings.append({"code": "start_time_unparsed", "pid": int(match.group("pid"))})
        start = now
    age_minutes = max(0, int((now - start).total_seconds() // 60))
    rss_kb = int(match.group("rss"))
    lock_paths = []
    if udir and os.path.isdir(udir):
        for name in ("SingletonLock", "SingletonSocket", "SingletonCookie"):
            path = os.path.join(udir, name)
            if os.path.exists(path):
                lock_paths.append(path)
    processes.append({
        "pid": int(match.group("pid")),
        "ppid": int(match.group("ppid")),
        "start_time": start.isoformat().replace("+00:00", "Z"),
        "age_minutes": age_minutes,
        "rss_mb": round(rss_kb / 1024, 2),
        "user_data_dir": udir,
        "singleton_locks_count": len(lock_paths),
        "command_hash": hashlib.sha256(command.encode()).hexdigest()[:16],
    })

processes.sort(key=lambda row: row["age_minutes"], reverse=True)
count = len(processes)
oldest = max((row["age_minutes"] for row in processes), default=0)
total_memory = round(sum(row["rss_mb"] for row in processes), 2)
singleton_locks = sum(row["singleton_locks_count"] for row in processes)
errors = []
if count > max_count:
    errors.append({"code": "agent_browser_count_high", "message": f"headless agent browser count {count} exceeds {max_count}"})
if oldest > max_oldest:
    errors.append({"code": "agent_browser_oldest_age_high", "message": f"oldest agent browser age {oldest}m exceeds {max_oldest}m"})
status = "fail" if errors else "pass"
payload = {
    "version": version,
    "schema_version": "headless-browser-leak/v1",
    "status": status,
    "headless_agent_browser_count": count,
    "agent_browser_processes": processes,
    "oldest_age_minutes": oldest,
    "total_memory_mb": total_memory,
    "primary_chrome_profile": primary_profile,
    "history_path": history,
    "singleton_locks_count": singleton_locks,
    "chrome_launch_blocked_suspected": bool(count > max_count and singleton_locks > 0),
    "thresholds": {"max_count": max_count, "max_oldest_age_minutes": max_oldest},
    "errors": errors,
    "warnings": warnings,
    "signals": [{
        "name": "agent_browser_leak",
        "producer": ".flywheel/scripts/headless-browser-probe.sh --doctor --json",
        "measurement": "count and oldest age of agent-browser-chrome user-data-dir processes",
        "consumer": "flywheel-loop doctor; doctor-signal-bead-promotion.sh",
        "threshold": "fail when headless_agent_browser_count > 5 or oldest_age_minutes > 60"
    }]
}
json.dump(payload, sys.stdout, separators=(",", ":"))
print()
PY
