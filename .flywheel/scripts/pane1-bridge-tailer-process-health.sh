#!/usr/bin/env bash
set -euo pipefail

LABEL="${PANE1_BRIDGE_LABEL:-ai.zeststream.flywheel-pane1-bridge-tailer}"
LAUNCHCTL="${PANE1_BRIDGE_LAUNCHCTL:-launchctl}"
BOOTSTRAP_DOMAIN="${PANE1_BRIDGE_BOOTSTRAP_DOMAIN:-gui/$(id -u)}"
LEDGER="${PANE1_BRIDGE_LEDGER:-$HOME/.local/state/flywheel/pane1-sprint-complete-bridge.jsonl}"
PS_BIN="${PANE1_BRIDGE_PS:-ps}"
PATTERN="${PANE1_BRIDGE_PROCESS_PATTERN:-pane1-bridge-tailer.sh.*--follow}"

launchctl_print=""
launchctl_rc=0
if launchctl_print="$("$LAUNCHCTL" print "$BOOTSTRAP_DOMAIN/$LABEL" 2>&1)"; then
  launchctl_rc=0
else
  launchctl_rc=$?
fi

pid="$(printf '%s\n' "$launchctl_print" | awk -F'= ' '/^[[:space:]]*pid = / {print $2; exit}' | tr -d '[:space:]')"
if [[ -z "$pid" ]]; then
  pid="$("$PS_BIN" -axo pid=,command= 2>/dev/null | awk -v self="$$" -v pattern="$PATTERN" '$1 != self && $0 ~ pattern {print $1; exit}' || true)"
fi

uptime=""
if [[ -n "$pid" ]]; then
  uptime="$("$PS_BIN" -o etime= -p "$pid" 2>/dev/null | awk '{print $1}' || true)"
fi

python3 - "$LABEL" "$BOOTSTRAP_DOMAIN" "$LEDGER" "$launchctl_rc" "${pid:-}" "${uptime:-}" <<'PY'
import json
import sys
from datetime import datetime, timezone
from pathlib import Path

label, domain, ledger, launchctl_rc, pid, uptime = sys.argv[1:]

def parse_uptime_seconds(value):
    value = str(value or "").strip()
    if not value:
        return None
    if value.isdigit():
        return int(value)
    days = 0
    if "-" in value:
        day_text, value = value.split("-", 1)
        if day_text.isdigit():
            days = int(day_text)
    parts = value.split(":")
    if not all(part.isdigit() for part in parts):
        return None
    nums = [int(part) for part in parts]
    if len(nums) == 2:
        hours = 0
        minutes, seconds = nums
    elif len(nums) == 3:
        hours, minutes, seconds = nums
    else:
        return None
    return days * 86400 + hours * 3600 + minutes * 60 + seconds
ledger_path = Path(ledger).expanduser()
latest = None
if ledger_path.exists():
    with ledger_path.open("r", encoding="utf-8") as handle:
        for raw in handle:
            raw = raw.strip()
            if not raw:
                continue
            try:
                row = json.loads(raw)
            except json.JSONDecodeError:
                continue
            ts = row.get("ts")
            if not ts:
                continue
            try:
                parsed = datetime.fromisoformat(str(ts).replace("Z", "+00:00"))
            except ValueError:
                continue
            if latest is None or parsed > latest:
                latest = parsed

age_seconds = None
if latest is not None:
    age_seconds = round((datetime.now(timezone.utc) - latest).total_seconds(), 3)

payload = {
    "schema_version": "pane1-bridge-tailer-health/v1",
    "label": label,
    "bootstrap_domain": domain,
    "loaded": int(launchctl_rc) == 0,
    "tailer_process_alive": bool(pid),
    "pid": int(pid) if str(pid).isdigit() else None,
    "uptime_seconds": parse_uptime_seconds(uptime),
    "ledger": str(ledger_path),
    "last_ledger_row_age_seconds": age_seconds,
    "last_ledger_row_age_hours": round(age_seconds / 3600, 6) if age_seconds is not None else None,
    "launchctl_print_exit": int(launchctl_rc),
    "status": "pass" if int(launchctl_rc) == 0 and bool(pid) else "warn",
}
print(json.dumps(payload, sort_keys=True, separators=(",", ":")))
raise SystemExit(0 if payload["status"] == "pass" else 1)
PY
