#!/usr/bin/env bash
set -euo pipefail

# customer-facing-observability.sh
#
# Value-gap dimension #3 measurement (Step 4o, bead flywheel-1rmp.4):
# summarize customer-visible value and risk per client engagement.
# Internal flywheel health is well-measured; customer-facing health is
# not. This probe aggregates per-client signals that proxy "what would
# the client see right now" — bead velocity, stale beads, last shipped
# deliverable age, last close-out receipt, recent dispatch activity,
# open INCIDENTS count.
#
# Read-only by design. No bead filing, no dispatch, no source mutation.
# Per Step 4o anti-pattern guardrail: "do not dispatch directly from
# this finding." This script SURFACES per-client value/risk signals;
# the orchestrator decides when a customer-visible risk needs action.
#
# Doctrine:
#   Step 4o tick.md (canonical wire-in via value-gap-probe.sh)
#   canonical-cli-scoping (doctor/health + validate/audit/why + --json)
#
# Native producers (read-only, per client repo):
#   - <repo>/.beads/issues.jsonl (bead state aggregates)
#   - <repo>/.flywheel/last_closeout_receipt.json (last shipped close)
#   - <repo>/.flywheel/dispatch-log.jsonl (recent activity)
#   - <repo>/INCIDENTS.md (## section count = trauma surface)

SCHEMA_VERSION="customer-facing-observability.v1"
SCRIPT_NAME="customer-facing-observability.sh"
SCRIPT_PATH="${BASH_SOURCE[0]:-$0}"

# Default client roster: known flywheel-managed client engagements.
# Blackfoot Telecom is intentionally absent — that engagement runs on
# external substrate (Sonar, etc.), not a flywheel-managed repo.
CLIENT_ROSTER_DEFAULT="alpsinsurance:ALPS terratitle:TerraTitle"
CLIENT_ROSTER="${CFO_CLIENT_ROSTER:-$CLIENT_ROSTER_DEFAULT}"
DEV_ROOT="${CFO_DEV_ROOT:-/Users/josh/Developer}"
LEDGER="${CFO_LEDGER:-$HOME/.local/state/flywheel/customer-facing-observability.jsonl}"
STALE_BEAD_DAYS="${CFO_STALE_BEAD_DAYS:-14}"

JSON_OUT=0
MODE="run"
WHY_TARGET=""

usage() {
  cat <<EOF
$SCRIPT_NAME — customer-facing observability (value-gap dim #3)

Usage:
  $SCRIPT_NAME [--client NAME] [--json]
  $SCRIPT_NAME --doctor [--json]
  $SCRIPT_NAME --health [--json]
  $SCRIPT_NAME --info [--json]
  $SCRIPT_NAME --validate [--json]
  $SCRIPT_NAME --audit [--json]
  $SCRIPT_NAME --why=<client> [--json]
  $SCRIPT_NAME --schema | --examples | --help

Modes:
  (default)    aggregate signals for every client in the roster
  --doctor     producer/measurement/consumer manifest + dependency probes
  --health     terse OK|DEGRADED|DOWN summary (exit code matches)
  --info       script identity and version
  --validate   re-emit one envelope through schema check
  --audit      list configured client repos with their freshness
  --why        explain one client's signals in detail

Flags:
  --client NAME    filter to one client (e.g. alpsinsurance)
  --json           emit machine-readable JSON envelope

Exit codes:
  0  measurement ran cleanly
  1  one or more clients missing a producer; partial results
  2  no clients available; no measurement possible
  3  invalid usage
EOF
}

emit_info() {
  if [[ "$JSON_OUT" -eq 1 ]]; then
    cat <<EOF
{"schema_version":"$SCHEMA_VERSION","mode":"info","script":"$SCRIPT_NAME","dev_root":"$DEV_ROOT","client_roster":"$CLIENT_ROSTER","ledger":"$LEDGER","stale_bead_days":$STALE_BEAD_DAYS}
EOF
  else
    echo "$SCRIPT_NAME ($SCHEMA_VERSION)"
    echo "  dev_root:         $DEV_ROOT"
    echo "  client_roster:    $CLIENT_ROSTER"
    echo "  ledger:           $LEDGER"
    echo "  stale_bead_days:  $STALE_BEAD_DAYS"
  fi
}

emit_schema() {
  cat <<'EOF'
{
  "$schema": "https://json-schema.org/draft/2020-12/schema",
  "title": "customer-facing-observability.v1",
  "type": "object",
  "required": ["schema_version", "mode", "checked_at", "summary", "clients"],
  "properties": {
    "schema_version": {"const": "customer-facing-observability.v1"},
    "mode": {"enum": ["run", "doctor", "health", "validate", "audit", "why", "info"]},
    "checked_at": {"type": "string", "format": "date-time"},
    "summary": {
      "type": "object",
      "required": ["clients_total", "clients_available", "clients_at_risk"],
      "properties": {
        "clients_total": {"type": "integer"},
        "clients_available": {"type": "integer"},
        "clients_at_risk": {"type": "integer"}
      }
    },
    "clients": {
      "type": "array",
      "items": {
        "type": "object",
        "required": ["client", "label", "repo", "available", "value_signals", "risk_signals"],
        "properties": {
          "client": {"type": "string"},
          "label": {"type": "string"},
          "repo": {"type": "string"},
          "available": {"type": "boolean"},
          "value_signals": {"type": "object"},
          "risk_signals": {"type": "object"}
        }
      }
    }
  }
}
EOF
}

emit_doctor() {
  local available=0 total=0 overall
  for entry in $CLIENT_ROSTER; do
    total=$((total + 1))
    local name="${entry%%:*}"
    local repo="$DEV_ROOT/$name"
    [[ -d "$repo" ]] && available=$((available + 1))
  done
  if [[ "$available" -eq 0 ]]; then
    overall="down"
  elif [[ "$available" -lt "$total" ]]; then
    overall="degraded"
  else
    overall="healthy"
  fi
  if [[ "$JSON_OUT" -eq 1 ]]; then
    python3 -c "
import json
print(json.dumps({
  'schema_version': '$SCHEMA_VERSION',
  'mode': 'doctor',
  'producer': [
    '<repo>/.beads/issues.jsonl (bead aggregates)',
    '<repo>/.flywheel/last_closeout_receipt.json (last shipped close)',
    '<repo>/.flywheel/dispatch-log.jsonl (recent activity)',
    '<repo>/INCIDENTS.md (## section count = trauma surface)',
  ],
  'measurement': '$SCRIPT_NAME --json',
  'consumer': '/flywheel:tick Step 4o + fleet observatory + future client-status digest',
  'clients_available': $available,
  'clients_total': $total,
  'overall': '$overall',
}))
"
  else
    echo "doctor: overall=$overall clients=$available/$total"
    echo "producers (per client):"
    echo "  <repo>/.beads/issues.jsonl"
    echo "  <repo>/.flywheel/last_closeout_receipt.json"
    echo "  <repo>/.flywheel/dispatch-log.jsonl"
    echo "  <repo>/INCIDENTS.md"
    echo "measurement: $SCRIPT_NAME --json"
    echo "consumer: /flywheel:tick Step 4o + fleet observatory"
  fi
  case "$overall" in
    healthy) return 0 ;;
    degraded) return 1 ;;
    down) return 2 ;;
  esac
}

emit_health() {
  local rc level
  set +e
  emit_doctor >/dev/null 2>&1
  rc=$?
  set -e
  case "$rc" in
    0) level="OK" ;;
    1) level="DEGRADED" ;;
    *) level="DOWN" ;;
  esac
  if [[ "$JSON_OUT" -eq 1 ]]; then
    printf '{"schema_version":"%s","mode":"health","level":"%s","exit_code":%d}\n' "$SCHEMA_VERSION" "$level" "$rc"
  else
    echo "health: $level"
  fi
  return "$rc"
}

emit_audit() {
  python3 - <<'PY' "$DEV_ROOT" "$CLIENT_ROSTER" "$SCHEMA_VERSION"
import json, os, sys, time

dev_root, roster, schema_version = sys.argv[1:4]
items = []
for entry in roster.split():
    name = entry.split(":", 1)[0]
    label = entry.split(":", 1)[1] if ":" in entry else name
    repo = os.path.join(dev_root, name)
    sources = {"repo": repo, "exists": os.path.isdir(repo)}
    for sub in (".beads/issues.jsonl", ".flywheel/last_closeout_receipt.json", ".flywheel/dispatch-log.jsonl", "INCIDENTS.md"):
        path = os.path.join(repo, sub)
        if os.path.isfile(path):
            try:
                age = int(time.time() - os.path.getmtime(path))
            except Exception:
                age = None
            sources[sub] = {"exists": True, "age_seconds": age}
        else:
            sources[sub] = {"exists": False}
    items.append({"client": name, "label": label, "sources": sources})
print(json.dumps({"schema_version": schema_version, "mode": "audit", "clients": items}))
PY
}

# probe_one_client: emit a JSON object describing the client's signals.
# Read-only. Fields are populated from durable per-repo sources.
probe_one_client() {
  local entry="$1"
  local name="${entry%%:*}"
  local label="${entry#*:}"
  [[ "$label" == "$entry" ]] && label="$name"
  local repo="$DEV_ROOT/$name"
  python3 - "$name" "$label" "$repo" "$STALE_BEAD_DAYS" <<'PY'
import json, os, re, sys, time, datetime

name, label, repo, stale_days_s = sys.argv[1:5]
stale_days = int(stale_days_s)
now = time.time()
available = os.path.isdir(repo)

value_signals = {}
risk_signals = {}

# Bead aggregates from .beads/issues.jsonl
beads_path = os.path.join(repo, ".beads/issues.jsonl")
if os.path.isfile(beads_path):
    counts = {"open": 0, "in_progress": 0, "closed": 0, "blocked": 0, "ready": 0, "stale_open": 0}
    last_close_ts = None
    closed_last_7d = 0
    seven_d = now - 7 * 86400
    stale_cutoff = now - stale_days * 86400
    try:
        with open(beads_path) as f:
            for line in f:
                line = line.strip()
                if not line:
                    continue
                try:
                    row = json.loads(line)
                except Exception:
                    continue
                status = (row.get("status") or "").lower()
                counts[status] = counts.get(status, 0) + 1
                # ready beads: status open AND no open dependencies (best-effort heuristic)
                if status == "open" and not (row.get("dependencies") or row.get("deps")):
                    counts["ready"] += 1
                if status == "closed":
                    closed_at = row.get("closed_at") or row.get("updated_at")
                    if closed_at:
                        try:
                            t = datetime.datetime.fromisoformat(closed_at.replace("Z", "+00:00")).timestamp()
                            if last_close_ts is None or t > last_close_ts:
                                last_close_ts = t
                            if t >= seven_d:
                                closed_last_7d += 1
                        except Exception:
                            pass
                if status in ("open", "in_progress"):
                    updated = row.get("updated_at") or row.get("created_at")
                    if updated:
                        try:
                            t = datetime.datetime.fromisoformat(updated.replace("Z", "+00:00")).timestamp()
                            if t < stale_cutoff:
                                counts["stale_open"] += 1
                        except Exception:
                            pass
    except Exception:
        counts = None

    if counts is not None:
        value_signals["bead_counts"] = {k: v for k, v in counts.items() if k != "stale_open"}
        value_signals["closed_last_7d"] = closed_last_7d
        if last_close_ts:
            age = int(now - last_close_ts)
            value_signals["last_close_age_seconds"] = age
            value_signals["last_close_age_days"] = age // 86400
        if counts["stale_open"] > 0:
            risk_signals["stale_open_beads"] = counts["stale_open"]
        if counts["open"] > 0 and closed_last_7d == 0:
            risk_signals["no_closes_last_7d"] = True
        if counts["blocked"] > 0:
            risk_signals["blocked_beads"] = counts["blocked"]

# Last close-out receipt
receipt_path = os.path.join(repo, ".flywheel/last_closeout_receipt.json")
if os.path.isfile(receipt_path):
    try:
        age = int(now - os.path.getmtime(receipt_path))
        value_signals["last_closeout_receipt_age_seconds"] = age
        value_signals["last_closeout_receipt_age_days"] = age // 86400
        if age > 7 * 86400:
            risk_signals["stale_closeout_receipt_days"] = age // 86400
    except Exception:
        pass
else:
    if available:
        risk_signals["missing_closeout_receipt"] = True

# Recent dispatch activity
dispatch_path = os.path.join(repo, ".flywheel/dispatch-log.jsonl")
if os.path.isfile(dispatch_path):
    try:
        age = int(now - os.path.getmtime(dispatch_path))
        value_signals["dispatch_log_age_seconds"] = age
        if age > 3 * 86400:
            risk_signals["stale_dispatch_log_days"] = age // 86400
    except Exception:
        pass

# INCIDENTS surface (open trauma proxy)
incidents_path = os.path.join(repo, "INCIDENTS.md")
if os.path.isfile(incidents_path):
    try:
        with open(incidents_path) as f:
            text = f.read()
        section_count = sum(1 for line in text.splitlines() if line.startswith("## "))
        value_signals["incidents_section_count"] = section_count
    except Exception:
        pass

out = {
    "client": name,
    "label": label,
    "repo": repo,
    "available": available,
    "value_signals": value_signals,
    "risk_signals": risk_signals,
}
print(json.dumps(out))
PY
}

run_measurement() {
  local entries
  if [[ -n "${CLIENT_FILTER:-}" ]]; then
    entries=""
    for e in $CLIENT_ROSTER; do
      [[ "${e%%:*}" == "$CLIENT_FILTER" ]] && entries="$e"
    done
    if [[ -z "$entries" ]]; then
      echo "ERROR: client '$CLIENT_FILTER' not in roster" >&2
      return 3
    fi
  else
    entries="$CLIENT_ROSTER"
  fi

  local rows="["
  local first=1
  for entry in $entries; do
    local row
    row="$(probe_one_client "$entry")"
    if [[ "$first" -eq 1 ]]; then
      rows="$rows$row"
      first=0
    else
      rows="$rows,$row"
    fi
  done
  rows="$rows]"

  python3 - "$rows" "$SCHEMA_VERSION" "$LEDGER" "$JSON_OUT" "$SCRIPT_PATH" <<'PY'
import json, os, sys, datetime

rows_s, schema_version, ledger_path, json_out, script_path = sys.argv[1:6]
json_out = json_out == "1"
clients = json.loads(rows_s)
clients_total = len(clients)
clients_available = sum(1 for c in clients if c.get("available"))
clients_at_risk = sum(1 for c in clients if c.get("risk_signals"))

now = datetime.datetime.now(datetime.timezone.utc).strftime("%Y-%m-%dT%H:%M:%SZ")
out = {
    "schema_version": schema_version,
    "mode": "run",
    "checked_at": now,
    "summary": {
        "clients_total": clients_total,
        "clients_available": clients_available,
        "clients_at_risk": clients_at_risk,
    },
    "clients": clients,
}

# Self-log to ledger
try:
    os.makedirs(os.path.dirname(ledger_path), exist_ok=True)
    enriched = dict(out)
    enriched["script"] = script_path
    with open(ledger_path, "a") as f:
        f.write(json.dumps(enriched) + "\n")
except Exception:
    pass

if json_out:
    print(json.dumps(out))
else:
    print(f"checked_at: {now}")
    print(f"clients: {clients_available}/{clients_total} available, {clients_at_risk} at risk")
    print()
    for c in clients:
        avail = "✓" if c["available"] else "✗"
        risk = "RISK" if c.get("risk_signals") else "ok"
        bc = c.get("value_signals", {}).get("bead_counts") or {}
        print(f"{avail} {c['label']:<14} ({c['client']})  status={risk}")
        if bc:
            print(f"    beads: open={bc.get('open',0)} ready={bc.get('ready',0)} in_progress={bc.get('in_progress',0)} blocked={bc.get('blocked',0)} closed={bc.get('closed',0)}")
        last_close = c.get("value_signals", {}).get("last_close_age_days")
        if last_close is not None:
            print(f"    last_close: {last_close}d ago ({c['value_signals'].get('closed_last_7d',0)} closes in last 7d)")
        if c.get("risk_signals"):
            for k, v in c["risk_signals"].items():
                print(f"    risk: {k} = {v}")

if clients_available == 0:
    sys.exit(2)
if clients_available < clients_total:
    sys.exit(1)
sys.exit(0)
PY
}

emit_validate() {
  local rendered
  rendered="$($0 --json 2>/dev/null || true)"
  python3 - <<'PY' "$rendered" "$SCHEMA_VERSION"
import json, sys
rendered, schema_version = sys.argv[1:3]
try:
    d = json.loads(rendered)
except Exception as e:
    print(json.dumps({"schema_version": schema_version, "mode": "validate", "status": "fail", "reason": "non_json_output", "detail": str(e)}))
    sys.exit(1)
required = ["schema_version", "mode", "checked_at", "summary", "clients"]
missing = [k for k in required if k not in d]
status = "ok" if not missing else "fail"
print(json.dumps({"schema_version": schema_version, "mode": "validate", "status": status, "missing": missing}))
sys.exit(0 if status == "ok" else 1)
PY
}

emit_why() {
  local target="$1"
  if [[ -z "$target" ]]; then
    echo "ERROR: --why requires a client name" >&2
    return 3
  fi
  local matched=""
  for e in $CLIENT_ROSTER; do
    [[ "${e%%:*}" == "$target" ]] && matched="$e"
  done
  if [[ -z "$matched" ]]; then
    echo "ERROR: client '$target' not in roster ($CLIENT_ROSTER)" >&2
    return 3
  fi
  probe_one_client "$matched"
}

# Argument parsing
CLIENT_FILTER=""
while [[ $# -gt 0 ]]; do
  case "$1" in
    --json) JSON_OUT=1; shift ;;
    --client) CLIENT_FILTER="$2"; shift 2 ;;
    --client=*) CLIENT_FILTER="${1#--client=}"; shift ;;
    --doctor) MODE="doctor"; shift ;;
    --health) MODE="health"; shift ;;
    --info) MODE="info"; shift ;;
    --schema) MODE="schema"; shift ;;
    --validate) MODE="validate"; shift ;;
    --audit) MODE="audit"; shift ;;
    --examples) MODE="examples"; shift ;;
    --why=*) MODE="why"; WHY_TARGET="${1#--why=}"; shift ;;
    --why) MODE="why"; WHY_TARGET="$2"; shift 2 ;;
    -h|--help) usage; exit 0 ;;
    *) echo "ERROR: unknown arg: $1" >&2; usage; exit 3 ;;
  esac
done

case "$MODE" in
  info) emit_info ;;
  schema) emit_schema ;;
  doctor) emit_doctor ;;
  health) emit_health ;;
  validate) emit_validate ;;
  audit) emit_audit ;;
  why) emit_why "$WHY_TARGET" ;;
  examples)
    cat <<'EOF'
# default: aggregate signals for every client in roster
.flywheel/scripts/customer-facing-observability.sh --json | jq '.clients[]'

# filter to one client
.flywheel/scripts/customer-facing-observability.sh --client alpsinsurance --json

# explain one client's signals (skips summary aggregation)
.flywheel/scripts/customer-facing-observability.sh --why=terratitle --json
EOF
    ;;
  run) run_measurement ;;
esac
