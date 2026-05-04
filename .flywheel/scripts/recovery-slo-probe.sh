#!/usr/bin/env bash
set -euo pipefail

VERSION="recovery-slo-probe/v1"
LEDGER="${RECOVERY_SLO_LEDGER:-$HOME/.local/state/flywheel-loop/frozen-pane-recovery-ledger.jsonl}"
WINDOW_HOURS="${RECOVERY_SLO_WINDOW_HOURS:-24}"
SLO_SECONDS="${RECOVERY_SLO_SECONDS:-180}"
JSON_OUT=0
MODE="probe"

usage() {
  cat <<'USAGE'
Usage:
  recovery-slo-probe.sh [--json]
  recovery-slo-probe.sh --ledger PATH [--window-hours N] [--slo-seconds N] [--json]
  recovery-slo-probe.sh --doctor [--json]
  recovery-slo-probe.sh --health [--json]
  recovery-slo-probe.sh --info [--json]
  recovery-slo-probe.sh --examples
  recovery-slo-probe.sh --schema

Measures frozen-pane recovery latency over the last 24h. The SLO is p95 <= 180s.
USAGE
}

emit_info() {
  jq -nc --arg version "$VERSION" --arg ledger "$LEDGER" --argjson window "$WINDOW_HOURS" --argjson slo "$SLO_SECONDS" '{
    schema_version:$version,
    command:"recovery-slo-probe.sh",
    purpose:"Expose frozen-pane recovery SLO fields for doctor and status surfaces",
    ledger:$ledger,
    window_hours:$window,
    slo_seconds:$slo,
    doctor_fields:["recovery_latency_p50_seconds_24h","recovery_latency_p95_seconds_24h","recovery_slo_breach_count_24h","recovery_slo_status"],
    canonical_flags:["--help","--info","--examples","--schema","--doctor","--health","--json","--ledger","--window-hours","--slo-seconds"]
  }'
}

emit_examples() {
  cat <<'EXAMPLES'
recovery-slo-probe.sh --json
recovery-slo-probe.sh --ledger /tmp/recovery-ledger.jsonl --window-hours 24 --slo-seconds 180 --json
recovery-slo-probe.sh --doctor --json
EXAMPLES
}

emit_schema() {
  jq -nc --arg version "$VERSION" '{
    "$schema":"https://json-schema.org/draft/2020-12/schema",
    title:"recovery SLO probe output",
    type:"object",
    required:["schema_version","success","recovery_slo_status","recovery_latency_p50_seconds_24h","recovery_latency_p95_seconds_24h","recovery_slo_breach_count_24h"],
    properties:{
      schema_version:{const:$version},
      success:{type:"boolean"},
      recovery_slo_status:{enum:["green","yellow","red"]},
      recovery_latency_p50_seconds_24h:{type:"number"},
      recovery_latency_p95_seconds_24h:{type:"number"},
      recovery_slo_breach_count_24h:{type:"integer"},
      measured_recovery_count_24h:{type:"integer"},
      unmeasured_recovery_count_24h:{type:"integer"}
    }
  }'
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --json) JSON_OUT=1; shift ;;
    --doctor) MODE="doctor"; shift ;;
    --health) MODE="health"; shift ;;
    --info) MODE="info"; shift ;;
    --examples) MODE="examples"; shift ;;
    --schema) MODE="schema"; shift ;;
    --ledger) LEDGER="${2:?--ledger requires PATH}"; shift 2 ;;
    --ledger=*) LEDGER="${1#*=}"; shift ;;
    --window-hours) WINDOW_HOURS="${2:?--window-hours requires N}"; shift 2 ;;
    --window-hours=*) WINDOW_HOURS="${1#*=}"; shift ;;
    --slo-seconds) SLO_SECONDS="${2:?--slo-seconds requires N}"; shift 2 ;;
    --slo-seconds=*) SLO_SECONDS="${1#*=}"; shift ;;
    --help|-h) usage; exit 0 ;;
    --version) printf '%s\n' "$VERSION"; exit 0 ;;
    *) printf 'ERR: unknown argument: %s\n' "$1" >&2; usage >&2; exit 64 ;;
  esac
done

case "$MODE" in
  info) emit_info; exit 0 ;;
  examples) emit_examples; exit 0 ;;
  schema) emit_schema; exit 0 ;;
esac

python3 - "$VERSION" "$LEDGER" "$WINDOW_HOURS" "$SLO_SECONDS" "$MODE" <<'PY'
import json
import math
import sys
from datetime import datetime, timedelta, timezone
from pathlib import Path
from typing import Any

version, ledger_raw, window_hours_raw, slo_raw, mode = sys.argv[1:]
ledger = Path(ledger_raw).expanduser()
window_hours = float(window_hours_raw)
slo_seconds = float(slo_raw)
now = datetime.now(timezone.utc)
cutoff = now - timedelta(hours=window_hours)

def parse_ts(value: Any):
    if not value:
        return None
    try:
        return datetime.fromisoformat(str(value).replace("Z", "+00:00")).astimezone(timezone.utc)
    except Exception:
        return None

def numeric(value: Any):
    if value is None:
        return None
    try:
        number = float(value)
    except Exception:
        return None
    if math.isnan(number) or number < 0:
        return None
    return number

def read_rows(path: Path):
    if not path.exists():
        return []
    rows = []
    try:
        lines = path.read_text(encoding="utf-8", errors="replace").splitlines()
    except Exception:
        return rows
    for line in lines:
        if not line.strip():
            continue
        try:
            row = json.loads(line)
        except Exception:
            continue
        if isinstance(row, dict):
            rows.append(row)
    return rows

def row_latency(row: dict[str, Any]):
    total = numeric(row.get("total_recovery_latency_seconds"))
    if total is not None:
        return total
    detection = numeric(row.get("detection_latency_seconds"))
    recovery = numeric(row.get("recovery_latency_seconds"))
    if detection is not None and recovery is not None:
        return detection + recovery
    return numeric(row.get("latency_seconds") or row.get("recovery_latency_seconds"))

def percentile(values: list[float], q: float) -> float:
    if not values:
        return 0.0
    ordered = sorted(values)
    idx = max(0, min(len(ordered) - 1, math.ceil(q * len(ordered)) - 1))
    return ordered[idx]

eligible_rows = []
for row in read_rows(ledger):
    if row.get("event") != "recovery":
        continue
    ts = parse_ts(row.get("ts"))
    if ts is None or ts < cutoff:
        continue
    eligible_rows.append(row)

latencies = [lat for row in eligible_rows if (lat := row_latency(row)) is not None]
breaches = [lat for lat in latencies if lat > slo_seconds]
p50 = percentile(latencies, 0.50)
p95 = percentile(latencies, 0.95)
unmeasured = len(eligible_rows) - len(latencies)

if breaches:
    status = "red"
elif unmeasured and not latencies:
    status = "yellow"
else:
    status = "green"

payload = {
    "schema_version": version,
    "success": True,
    "mode": mode,
    "checked_at": now.replace(microsecond=0).isoformat().replace("+00:00", "Z"),
    "ledger": str(ledger),
    "window_hours": window_hours,
    "slo_seconds": slo_seconds,
    "recovery_slo_status": status,
    "recovery_latency_p50_seconds_24h": int(p50) if p50.is_integer() else round(p50, 3),
    "recovery_latency_p95_seconds_24h": int(p95) if p95.is_integer() else round(p95, 3),
    "recovery_slo_breach_count_24h": len(breaches),
    "measured_recovery_count_24h": len(latencies),
    "unmeasured_recovery_count_24h": unmeasured,
    "eligible_recovery_count_24h": len(eligible_rows),
    "worst_recovery_latency_seconds_24h": int(max(latencies)) if latencies and max(latencies).is_integer() else (round(max(latencies), 3) if latencies else 0),
}
print(json.dumps(payload, separators=(",", ":")))
PY
