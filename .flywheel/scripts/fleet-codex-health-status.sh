#!/usr/bin/env bash
set -euo pipefail

LEDGER="${FLEET_CODEX_HEALTH_LEDGER:-/Users/josh/.local/state/flywheel/fleet-codex-health.jsonl}"
JSON_OUT=0
[[ "${1:-}" == "--json" ]] && JSON_OUT=1

python3 - "$LEDGER" "$JSON_OUT" <<'PY'
import json
import sys
from collections import defaultdict
from datetime import datetime, timezone
from pathlib import Path

ledger = Path(sys.argv[1]).expanduser()
json_out = sys.argv[2] == "1"
latest_by_session = defaultdict(list)
latest_ts = None

if ledger.exists():
    for raw in ledger.read_text(encoding="utf-8").splitlines():
        if not raw.strip():
            continue
        try:
            row = json.loads(raw)
        except json.JSONDecodeError:
            continue
        if row.get("schema_version") != "flywheel.fleet_codex_health.v1":
            continue
        session = row.get("session") or "unknown"
        ts = row.get("ts")
        try:
            parsed = datetime.fromisoformat(str(ts).replace("Z", "+00:00"))
        except Exception:
            parsed = None
        if parsed and (latest_ts is None or parsed > latest_ts):
            latest_ts = parsed
        latest_by_session[session].append(row)

states = {}
for session, rows in latest_by_session.items():
    max_ts = max((r.get("ts") or "" for r in rows), default="")
    current = [r for r in rows if (r.get("ts") or "") == max_ts]
    values = {r.get("state") for r in current}
    if values == {"NO_CODEX"}:
        states[session] = "dormant"
    elif values and values <= {"ALIVE"}:
        states[session] = "active"
    elif values:
        states[session] = "distressed"
    else:
        states[session] = "unknown"

counts = {name: list(states.values()).count(name) for name in ["active", "dormant", "distressed", "unknown"]}
age_seconds = None
if latest_ts is not None:
    age_seconds = round((datetime.now(timezone.utc) - latest_ts).total_seconds(), 3)

payload = {
    "schema_version": "flywheel.fleet_codex_health.status.v1",
    "status": "pass" if latest_ts is not None and counts["distressed"] == 0 else "warn",
    "ledger": str(ledger),
    "latest_ts": latest_ts.isoformat().replace("+00:00", "Z") if latest_ts else None,
    "latest_age_seconds": age_seconds,
    "sessions_total": len(states),
    **counts,
}
payload["dashboard_line"] = (
    f"Fleet Codex health: active={counts['active']} dormant={counts['dormant']} "
    f"distressed={counts['distressed']} latest_age_s={int(age_seconds) if age_seconds is not None else 'unknown'}"
)
print(json.dumps(payload, sort_keys=True) if json_out else payload["dashboard_line"])
raise SystemExit(0 if payload["latest_ts"] else 1)
PY
