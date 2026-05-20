#!/usr/bin/env bash
set -euo pipefail

VERSION="doctrine-drift-trend-probe.v1.0.0"
SCHEMA_VERSION="doctrine-drift-trend/v1"
LEDGER="${DOCTRINE_DRIFT_TREND_LEDGER:-$HOME/.local/state/flywheel/doctrine-sync-ledger.jsonl}"
TOP_N="${DOCTRINE_DRIFT_TREND_TOP_N:-5}"
NOW="${DOCTRINE_DRIFT_TREND_NOW:-}"
JSON_OUT=0
QUIET=0
MODE="probe"

usage() { printf '%s\n' "usage: doctrine-drift-trend-probe.sh [--ledger PATH] [--top N] [--now ISO] [--json] [--quiet]" "       doctrine-drift-trend-probe.sh --info|--examples|--help"; }
examples() { printf '%s\n' "doctrine-drift-trend-probe.sh --json" "DOCTRINE_DRIFT_TREND_LEDGER=/tmp/ledger.jsonl doctrine-drift-trend-probe.sh --top 10 --json" "doctrine-drift-trend-probe.sh --quiet"; }
info_json() { jq -nc --arg version "$VERSION" --arg schema "$SCHEMA_VERSION" --arg ledger "$LEDGER" '{name:"doctrine-drift-trend-probe.sh",version:$version,schema_version:$schema,ledger_path:$ledger,commands:["--info","--help","--examples","--json","--quiet"],exit_codes:{"0":"probe completed","2":"usage or malformed ledger"}}'; }

while [[ $# -gt 0 ]]; do
  case "$1" in
    --ledger) LEDGER="${2:?}"; shift 2 ;;
    --ledger=*) LEDGER="${1#*=}"; shift ;;
    --top) TOP_N="${2:?}"; shift 2 ;;
    --top=*) TOP_N="${1#*=}"; shift ;;
    --now) NOW="${2:?}"; shift 2 ;;
    --now=*) NOW="${1#*=}"; shift ;;
    --json) JSON_OUT=1; shift ;;
    --quiet) QUIET=1; shift ;;
    --info) MODE="info"; shift ;;
    --examples) MODE="examples"; shift ;;
    -h|--help) MODE="help"; shift ;;
    *) printf 'ERR: unknown argument: %s\n' "$1" >&2; usage >&2; exit 2 ;;
  esac
done

[[ "$TOP_N" =~ ^[1-9][0-9]*$ ]] || { printf 'ERR: --top must be positive integer\n' >&2; exit 2; }
case "$MODE" in
  info) info_json; exit 0 ;;
  examples) examples; exit 0 ;;
  help) usage; exit 0 ;;
esac

set +e
payload="$(
python3 - "$LEDGER" "$TOP_N" "$NOW" <<'PY'
import json, sys
from datetime import datetime, timedelta, timezone
from pathlib import Path

ledger, top_n, now_arg = Path(sys.argv[1]).expanduser(), int(sys.argv[2]), sys.argv[3]
schema = "doctrine-drift-trend/v1"

def parse_ts(value):
    if not value:
        return None
    text = str(value)
    text = text[:-1] + "+00:00" if text.endswith("Z") else text
    try:
        dt = datetime.fromisoformat(text)
    except ValueError:
        return None
    return (dt.replace(tzinfo=timezone.utc) if dt.tzinfo is None else dt).astimezone(timezone.utc)

def iso(dt):
    return dt.astimezone(timezone.utc).isoformat().replace("+00:00", "Z")

def drift_count(row):
    for key in ("drifted_count", "fleet_doctrine_drift_count_after", "fleet_doctrine_drift_count", "current_drift_count"):
        if isinstance(row.get(key), int):
            return row[key]
    return None

def surface(path):
    text = str(path or "")
    if text.endswith(".flywheel/AGENTS-CANONICAL.md"):
        return "AGENTS-CANONICAL.md"
    if text.endswith("AGENTS.md"):
        return "AGENTS.md"
    if "validation-schema" in text:
        return "validation-schema"
    if "bead-quality-mining.sh" in text:
        return "bead-quality-mining"
    return "unknown"

def add_entry(out, repo, surface_name="unknown", target=None, missing=None):
    if not repo:
        return
    item = out.setdefault(repo, {"repo": repo, "surfaces": set(), "targets": [], "missing_rules": set()})
    item["surfaces"].add(surface_name or "unknown")
    if target:
        item["targets"].append(target)
    item["missing_rules"].update(missing or [])

def repo_entries(row):
    out = {}
    for key in ("root_details", "details"):
        for item in row.get(key) or []:
            if isinstance(item, dict) and item.get("status") == "drifted":
                add_entry(out, item.get("repo"), surface(item.get("target")), item.get("target"), item.get("missing_rules"))
    for key in ("drifted_repos", "fleet_doctrine_drift_repos"):
        for item in row.get(key) or []:
            if isinstance(item, str):
                add_entry(out, item)
            elif isinstance(item, dict):
                add_entry(out, item.get("repo") or item.get("path"), item.get("surface"), item.get("target"), item.get("missing_rules"))
    for item in row.get("repos") or []:
        if isinstance(item, dict) and item.get("drift") is True:
            add_entry(out, item.get("repo"), item.get("surface"), item.get("agents_md"), item.get("missing_rules"))
    return out

rows = []
if ledger.exists():
    for line_no, line in enumerate(ledger.read_text(encoding="utf-8", errors="replace").splitlines(), 1):
        if not line.strip():
            continue
        try:
            row = json.loads(line)
        except json.JSONDecodeError as exc:
            print(json.dumps({"schema_version": schema, "status": "error", "classification": "malformed_ledger", "ledger_path": str(ledger), "line": line_no, "message": str(exc)}, separators=(",", ":")))
            sys.exit(2)
        count, ts = drift_count(row), parse_ts(row.get("ts") or row.get("timestamp"))
        if isinstance(row, dict) and count is not None and ts is not None:
            rows.append({"ts": ts, "count": count, "row": row})

if rows:
    rows.sort(key=lambda item: item["ts"])
    current, now = rows[-1], parse_ts(now_arg) or rows[-1]["ts"]
    cutoff = current["ts"] - timedelta(hours=24)
    prior = ([item for item in rows[:-1] if item["ts"] <= cutoff] or rows[:-1])
    previous = prior[-1] if prior else None
else:
    current, previous = {"ts": parse_ts(now_arg) or datetime.now(timezone.utc), "count": 0, "row": {}}, None

first_seen = {}
for item in rows:
    for repo in repo_entries(item["row"]):
        first_seen.setdefault(repo, item["ts"])

top = []
for repo, entry in repo_entries(current["row"]).items():
    first = first_seen.get(repo, current["ts"])
    lag = int((current["ts"] - first).total_seconds())
    top.append({"repo": repo, "lag_seconds": lag, "lag_hours": round(lag / 3600, 2), "last_sync_ts": iso(first), "surfaces": sorted(entry["surfaces"]), "targets": entry["targets"][:5], "missing_rules_count": len(entry["missing_rules"])})
top.sort(key=lambda item: (-item["lag_seconds"], item["repo"]))
delta = None if previous is None else current["count"] - previous["count"]
print(json.dumps({
    "schema_version": schema, "status": "pass" if current["count"] == 0 else "warn",
    "ledger_path": str(ledger), "rows_observed": len(rows), "current_ts": iso(current["ts"]),
    "current_drift_count": current["count"], "previous_24h_ts": iso(previous["ts"]) if previous else None,
    "previous_24h_drift_count": previous["count"] if previous else None, "drift_count_delta_24h": delta,
    "alert": bool(delta is not None and delta > 0), "top_n": top_n, "top_drifted_repos": top[:top_n],
}, sort_keys=True, separators=(",", ":")))
PY
)"
rc=$?
set -e

if [[ "$JSON_OUT" -eq 1 ]]; then
  printf '%s\n' "$payload"
elif [[ "$QUIET" -ne 1 ]]; then
  printf '%s\n' "$payload" | jq -r '"status=\(.status) drift_count=\(.current_drift_count) delta_24h=\(.drift_count_delta_24h) alert=\(.alert)"'
fi
exit "$rc"

# Meta-Learning Cross-References (2026-05-19)
# Batch-16 comment backfill; citations are documentation-only and do not alter runtime behavior.
# Related: `/Users/josh/Developer/skillos/.flywheel/doctrine/meta-learnings/MP-02-conformance-fixtures.md`
# Related: `/Users/josh/Developer/skillos/.flywheel/doctrine/meta-learnings/MP-68-schema-executable-validator-pair.md`
