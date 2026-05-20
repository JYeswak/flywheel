#!/usr/bin/env bash
set -euo pipefail

# cross-session-pane-truth-dashboard.sh
#
# Information-flow surface (Meadows #6) for live pane truth across all tmux
# sessions. Aggregates frozen-pane-detector v2 verdicts, ntm activity state,
# driver proof age, last callback recency, and unknown/stale counts.
#
# Doctrine:
#   L60 — LOOP-INTEGRITY-5-SIGNAL-CONTRACT
#   L68 — NO-SILENT-DARKNESS-GOAL-CONTRACT
#   canonical-cli-scoping (doctor/health/info + validate/audit/why + --json)
#
# Native producers (read-only):
#   - tmux list-sessions
#   - .flywheel/scripts/frozen-pane-detector.sh --session=<s> --json
#   - /Users/josh/.local/bin/ntm activity <s> --json
#   - ~/.flywheel/loops/<project>.json
#   - ~/.local/state/flywheel-loop/last_tick_<project>.json (mtime)
#   - <repo>/.flywheel/dispatch-log.jsonl (last callback_received_at)

SCHEMA_VERSION="cross-session-pane-truth-dashboard.v1"
SCRIPT_NAME="cross-session-pane-truth-dashboard.sh"

DETECTOR="${PANE_TRUTH_DETECTOR:-/Users/josh/Developer/flywheel/.flywheel/scripts/frozen-pane-detector.sh}"
NTM_BIN="${PANE_TRUTH_NTM_BIN:-/Users/josh/.local/bin/ntm}"
LOOPS_DIR="${PANE_TRUTH_LOOPS_DIR:-$HOME/.flywheel/loops}"
LAST_TICK_DIR="${PANE_TRUTH_LAST_TICK_DIR:-$HOME/.local/state/flywheel-loop}"
DEFAULT_REPO_ROOT="${PANE_TRUTH_REPO_ROOT:-$HOME/Developer}"
TIMEOUT_SEC="${PANE_TRUTH_TIMEOUT_SEC:-10}"

JSON_OUT=0
NO_COLOR=0
NO_EMOJI=0
MODE="render"
SESSION_FILTER=""

usage() {
  cat <<EOF
$SCRIPT_NAME — cross-session pane truth dashboard

Usage:
  $SCRIPT_NAME [--session=<name>] [--json] [--no-color] [--no-emoji]
  $SCRIPT_NAME --doctor [--json]
  $SCRIPT_NAME --health [--json]
  $SCRIPT_NAME --info [--json]
  $SCRIPT_NAME --validate [--json]
  $SCRIPT_NAME --audit [--json]
  $SCRIPT_NAME --why=<session>:<pane> [--json]
  $SCRIPT_NAME --schema | --examples | --help

Modes:
  (default)    render dashboard rows for every tmux session
  --doctor     producer/measurement/consumer manifest + dependency probes
  --health     terse OK|DEGRADED|DOWN summary, exit code matches
  --info       script identity and version
  --validate   re-emit one rendered row through the JSON schema
  --audit      list known data sources and last-seen ages
  --why        explain one pane verdict + raw source values

Flags:
  --session=NAME      filter to one tmux session
  --json              emit machine-readable JSON envelope
  --no-color          suppress ANSI color codes
  --no-emoji          suppress emoji glyphs (deterministic ASCII output)

Exit codes:
  0  all sources healthy, dashboard rendered
  1  one or more sources unavailable; dashboard rendered with degraded marks
  2  all primary sources unavailable; dashboard could not render
  3  invalid usage
EOF
}

emit_info() {
  if [[ "$JSON_OUT" -eq 1 ]]; then
    cat <<EOF
{"schema_version":"$SCHEMA_VERSION","mode":"info","script":"$SCRIPT_NAME","detector":"$DETECTOR","ntm_bin":"$NTM_BIN","loops_dir":"$LOOPS_DIR","last_tick_dir":"$LAST_TICK_DIR"}
EOF
  else
    echo "$SCRIPT_NAME ($SCHEMA_VERSION)"
    echo "  detector:      $DETECTOR"
    echo "  ntm_bin:       $NTM_BIN"
    echo "  loops_dir:     $LOOPS_DIR"
    echo "  last_tick_dir: $LAST_TICK_DIR"
  fi
}

emit_schema() {
  cat <<'EOF'
{
  "$schema": "https://json-schema.org/draft/2020-12/schema",
  "title": "cross-session-pane-truth-dashboard.v1",
  "type": "object",
  "required": ["schema_version", "mode", "checked_at", "sessions", "summary"],
  "properties": {
    "schema_version": {"const": "cross-session-pane-truth-dashboard.v1"},
    "mode": {"enum": ["render", "doctor", "health", "validate", "audit", "why"]},
    "checked_at": {"type": "string", "format": "date-time"},
    "summary": {
      "type": "object",
      "required": ["total_sessions", "total_panes", "verdict_counts", "source_health"],
      "properties": {
        "total_sessions": {"type": "integer", "minimum": 0},
        "total_panes": {"type": "integer", "minimum": 0},
        "verdict_counts": {
          "type": "object",
          "additionalProperties": {"type": "integer", "minimum": 0}
        },
        "source_health": {
          "type": "object",
          "required": ["overall"],
          "properties": {
            "overall": {"enum": ["healthy", "degraded", "down"]},
            "detector": {"enum": ["healthy", "unavailable", "error"]},
            "ntm": {"enum": ["healthy", "unavailable", "error"]},
            "loops": {"enum": ["healthy", "unavailable", "error"]}
          }
        }
      }
    },
    "sessions": {
      "type": "array",
      "items": {
        "type": "object",
        "required": ["session", "project", "panes", "driver_proof_age_sec", "last_callback_age_sec"],
        "properties": {
          "session": {"type": "string"},
          "project": {"type": ["string", "null"]},
          "driver_proof_age_sec": {"type": ["integer", "null"]},
          "last_callback_age_sec": {"type": ["integer", "null"]},
          "panes": {
            "type": "array",
            "items": {
              "type": "object",
              "required": ["pane", "verdict", "agent_state", "reason"],
              "properties": {
                "pane": {"type": "integer"},
                "verdict": {"enum": ["HEALTHY", "FROZEN", "UNKNOWN", "STALE", "DEGRADED", "UNAVAILABLE"]},
                "agent_state": {"type": ["string", "null"]},
                "reason": {"type": "string"}
              }
            }
          }
        }
      }
    }
  }
}
EOF
}

# emit_doctor: producer/measurement/consumer triad per canonical-cli-scoping.
emit_doctor() {
  local detector_health ntm_health loops_health overall
  detector_health="unavailable"
  ntm_health="unavailable"
  loops_health="unavailable"
  if [[ -x "$DETECTOR" ]]; then
    if "$DETECTOR" --doctor --json >/dev/null 2>&1; then
      detector_health="healthy"
    else
      detector_health="error"
    fi
  fi
  if [[ -x "$NTM_BIN" ]]; then
    if "$NTM_BIN" sessions list >/dev/null 2>&1 || "$NTM_BIN" --help >/dev/null 2>&1; then
      ntm_health="healthy"
    else
      ntm_health="error"
    fi
  fi
  if [[ -d "$LOOPS_DIR" ]]; then
    loops_health="healthy"
  fi
  overall="healthy"
  if [[ "$detector_health" != "healthy" || "$ntm_health" != "healthy" ]]; then
    overall="degraded"
  fi
  if [[ "$detector_health" != "healthy" && "$ntm_health" != "healthy" ]]; then
    overall="down"
  fi
  if [[ "$JSON_OUT" -eq 1 ]]; then
    python3 -c "
import json, sys
print(json.dumps({
    'schema_version': '$SCHEMA_VERSION',
    'mode': 'doctor',
    'producer': [
        'tmux list-sessions',
        '$DETECTOR --session=<s> --json',
        '$NTM_BIN activity <s> --json',
        '$LOOPS_DIR/<project>.json',
        '$LAST_TICK_DIR/last_tick_<project>.json (mtime)',
        '<repo>/.flywheel/dispatch-log.jsonl (callback_received_at)',
    ],
    'measurement': '$SCRIPT_NAME --json',
    'consumer': '/flywheel:tick observability surfaces, agentmail status digests',
    'source_health': {
        'overall': '$overall',
        'detector': '$detector_health',
        'ntm': '$ntm_health',
        'loops': '$loops_health',
    },
}))
"
  else
    echo "doctor: overall=$overall detector=$detector_health ntm=$ntm_health loops=$loops_health"
    echo "producers:"
    echo "  tmux list-sessions"
    echo "  $DETECTOR --session=<s> --json"
    echo "  $NTM_BIN activity <s> --json"
    echo "  $LOOPS_DIR/<project>.json"
    echo "  $LAST_TICK_DIR/last_tick_<project>.json (mtime)"
    echo "  <repo>/.flywheel/dispatch-log.jsonl (callback_received_at)"
    echo "measurement: $SCRIPT_NAME --json"
    echo "consumer: /flywheel:tick observability surfaces, agentmail status digests"
  fi
  case "$overall" in
    healthy) return 0 ;;
    degraded) return 1 ;;
    down) return 2 ;;
  esac
}

emit_health() {
  local rc
  set +e
  emit_doctor >/dev/null 2>&1
  rc=$?
  set -e
  case "$rc" in
    0)  level="OK" ;;
    1)  level="DEGRADED" ;;
    *)  level="DOWN" ;;
  esac
  if [[ "$JSON_OUT" -eq 1 ]]; then
    printf '{"schema_version":"%s","mode":"health","level":"%s","exit_code":%d}\n' "$SCHEMA_VERSION" "$level" "$rc"
  else
    echo "health: $level"
  fi
  return "$rc"
}

list_sessions() {
  if ! command -v tmux >/dev/null 2>&1; then
    return 1
  fi
  tmux list-sessions -F '#{session_name}' 2>/dev/null | sort -u
}

# session_to_project: best-effort map session name to project key.
# The convention in this repo is that loop registry filename matches session.
session_to_project() {
  local s="$1"
  if [[ -f "$LOOPS_DIR/$s.json" ]]; then
    echo "$s"
    return 0
  fi
  echo ""
}

driver_proof_age_sec() {
  local project="$1"
  local f="$LAST_TICK_DIR/last_tick_$project.json"
  if [[ -z "$project" || ! -f "$f" ]]; then
    echo "null"
    return
  fi
  python3 -c "
import os, time
try:
    print(int(time.time() - os.path.getmtime('$f')))
except Exception:
    print('null')
"
}

last_callback_age_sec() {
  local project="$1"
  local repo="$DEFAULT_REPO_ROOT/$project"
  local log="$repo/.flywheel/dispatch-log.jsonl"
  if [[ -z "$project" || ! -f "$log" ]]; then
    echo "null"
    return
  fi
  python3 -c "
import json, time, sys
latest = None
try:
    with open('$log') as f:
        for line in f:
            line = line.strip()
            if not line:
                continue
            try:
                row = json.loads(line)
            except Exception:
                continue
            ts = row.get('callback_received_at') or row.get('callback_at')
            if ts:
                try:
                    import datetime
                    t = datetime.datetime.fromisoformat(ts.replace('Z', '+00:00')).timestamp()
                    if latest is None or t > latest:
                        latest = t
                except Exception:
                    continue
    if latest is None:
        print('null')
    else:
        print(int(time.time() - latest))
except Exception:
    print('null')
"
}

# render_session: emit one session's pane rows as JSON-array fragment.
# Stdout: a single JSON object suitable for inclusion in sessions[].
render_session() {
  local s="$1"
  local project age_drv age_cb
  project="$(session_to_project "$s")"
  age_drv="$(driver_proof_age_sec "$project")"
  age_cb="$(last_callback_age_sec "$project")"
  local detector_json ntm_json
  detector_json=""
  ntm_json=""
  if [[ -x "$DETECTOR" ]]; then
    detector_json="$("$DETECTOR" --session="$s" --json 2>/dev/null || echo '')"
  fi
  if [[ -x "$NTM_BIN" ]]; then
    ntm_json="$("$NTM_BIN" activity "$s" --json 2>/dev/null || echo '')"
  fi
  python3 - "$s" "$project" "$age_drv" "$age_cb" <<'PY' "$detector_json" "$ntm_json"
import json, sys
session, project, age_drv, age_cb, detector_json, ntm_json = sys.argv[1], sys.argv[2], sys.argv[3], sys.argv[4], sys.argv[5], sys.argv[6]
def _intnull(s):
    if s == "null" or s == "":
        return None
    try:
        return int(s)
    except Exception:
        return None
def _safe_load(s):
    if not s:
        return None
    try:
        return json.loads(s)
    except Exception:
        return None
det = _safe_load(detector_json)
ntm = _safe_load(ntm_json)
detector_panes = {}
if det and isinstance(det.get("panes"), list):
    for p in det["panes"]:
        detector_panes[int(p.get("pane", -1))] = p
ntm_agents = {}
if ntm and isinstance(ntm.get("agents"), list):
    for a in ntm["agents"]:
        ntm_agents[int(a.get("pane", -1))] = a
all_panes = sorted(set(detector_panes) | set(ntm_agents))
rows = []
for p in all_panes:
    d = detector_panes.get(p) or {}
    a = ntm_agents.get(p) or {}
    verdict = d.get("verdict") or "UNAVAILABLE"
    if verdict == "UNAVAILABLE" and a:
        verdict = "DEGRADED"
    rows.append({
        "pane": p,
        "verdict": verdict,
        "agent_state": a.get("state"),
        "agent_kind": a.get("agent_type"),
        "reason": d.get("reason") or "no_detector_row",
        "live_delta_bytes": d.get("live_delta_bytes"),
        "age_seconds": d.get("age_seconds"),
    })
out = {
    "session": session,
    "project": project or None,
    "driver_proof_age_sec": _intnull(age_drv),
    "last_callback_age_sec": _intnull(age_cb),
    "source_health": {
        "detector": "healthy" if det else "unavailable",
        "ntm": "healthy" if ntm else "unavailable",
    },
    "panes": rows,
}
print(json.dumps(out))
PY
}

# render_dashboard: aggregate every session, emit JSON envelope or table.
render_dashboard() {
  local sessions
  if ! sessions="$(list_sessions)"; then
    if [[ "$JSON_OUT" -eq 1 ]]; then
      printf '{"schema_version":"%s","mode":"render","error":"tmux_unavailable"}\n' "$SCHEMA_VERSION"
    else
      echo "ERROR: tmux unavailable" >&2
    fi
    return 2
  fi
  if [[ -n "$SESSION_FILTER" ]]; then
    sessions="$(printf '%s\n' "$sessions" | grep -F -x "$SESSION_FILTER" || true)"
    if [[ -z "$sessions" ]]; then
      if [[ "$JSON_OUT" -eq 1 ]]; then
        printf '{"schema_version":"%s","mode":"render","error":"session_not_found","session":"%s"}\n' "$SCHEMA_VERSION" "$SESSION_FILTER"
      else
        echo "ERROR: session $SESSION_FILTER not found" >&2
      fi
      return 3
    fi
  fi
  local rows="["
  local first=1
  while IFS= read -r s; do
    [[ -z "$s" ]] && continue
    local row
    row="$(render_session "$s")"
    if [[ "$first" -eq 1 ]]; then
      rows="$rows$row"
      first=0
    else
      rows="$rows,$row"
    fi
  done <<< "$sessions"
  rows="$rows]"

  if [[ "$JSON_OUT" -eq 1 ]]; then
    python3 - <<PY "$rows"
import json, sys, datetime, collections
rows = json.loads(sys.argv[1])
counts = collections.Counter()
total_panes = 0
overall_health = "healthy"
for s in rows:
    for p in s.get("panes", []):
        counts[p.get("verdict", "UNKNOWN")] += 1
        total_panes += 1
    sh = s.get("source_health") or {}
    if sh.get("detector") != "healthy" or sh.get("ntm") != "healthy":
        if overall_health == "healthy":
            overall_health = "degraded"
print(json.dumps({
    "schema_version": "$SCHEMA_VERSION",
    "mode": "render",
    "checked_at": datetime.datetime.now(datetime.timezone.utc).strftime("%Y-%m-%dT%H:%M:%SZ"),
    "summary": {
        "total_sessions": len(rows),
        "total_panes": total_panes,
        "verdict_counts": dict(counts),
        "source_health": {"overall": overall_health},
    },
    "sessions": rows,
}))
PY
  else
    render_table "$rows"
  fi

  python3 - <<PY "$rows"
import json, sys
rows = json.loads(sys.argv[1])
degraded = False
for s in rows:
    sh = s.get("source_health") or {}
    if sh.get("detector") != "healthy" or sh.get("ntm") != "healthy":
        degraded = True
sys.exit(1 if degraded else 0)
PY
}

# render_table: human-readable view, deterministic when --no-color/--no-emoji.
render_table() {
  local rows="$1"
  local no_emoji="$NO_EMOJI"
  python3 - "$no_emoji" <<'PY' "$rows"
import json, sys
no_emoji = sys.argv[1] == "1"
rows = json.loads(sys.argv[2])
def glyph(v):
    if no_emoji:
        return v
    return {
        "HEALTHY": "[OK]",
        "FROZEN": "[FROZEN]",
        "UNKNOWN": "[UNKNOWN]",
        "STALE": "[STALE]",
        "DEGRADED": "[DEGRADED]",
        "UNAVAILABLE": "[N/A]",
    }.get(v, v)
def fmt_age(n):
    if n is None:
        return "-"
    if n < 60:
        return "%ds" % n
    if n < 3600:
        return "%dm" % (n // 60)
    if n < 86400:
        return "%dh" % (n // 3600)
    return "%dd" % (n // 86400)
print("%-18s %-14s %4s %-12s %-10s %-10s %-10s" % ("session", "project", "pane", "verdict", "agent", "drv-age", "cb-age"))
print("-" * 88)
for s in rows:
    proj = s.get("project") or "-"
    drv = fmt_age(s.get("driver_proof_age_sec"))
    cb = fmt_age(s.get("last_callback_age_sec"))
    panes = s.get("panes") or []
    if not panes:
        print("%-18s %-14s %4s %-12s %-10s %-10s %-10s" % (s["session"], proj, "-", glyph("UNAVAILABLE"), "-", drv, cb))
        continue
    for p in panes:
        print("%-18s %-14s %4d %-12s %-10s %-10s %-10s" % (
            s["session"], proj, p["pane"], glyph(p["verdict"]),
            (p.get("agent_state") or "-")[:10], drv, cb,
        ))
PY
}

# emit_validate: re-render and validate against the schema's required fields.
emit_validate() {
  local rendered
  rendered="$(JSON_OUT=1; export JSON_OUT; "$0" --json 2>/dev/null || true)"
  python3 - <<'PY' "$rendered"
import json, sys
try:
    d = json.loads(sys.argv[1])
except Exception as e:
    print(json.dumps({"schema_version": "cross-session-pane-truth-dashboard.v1", "mode": "validate", "status": "fail", "reason": "non_json_output", "detail": str(e)}))
    sys.exit(1)
required = ["schema_version", "mode", "checked_at", "summary", "sessions"]
missing = [k for k in required if k not in d]
status = "ok" if not missing else "fail"
print(json.dumps({"schema_version": "cross-session-pane-truth-dashboard.v1", "mode": "validate", "status": status, "missing": missing}))
sys.exit(0 if status == "ok" else 1)
PY
}

# emit_audit: list known sources and last-seen ages.
emit_audit() {
  python3 - <<'PY' "$DETECTOR" "$NTM_BIN" "$LOOPS_DIR" "$LAST_TICK_DIR"
import json, os, sys, time
detector, ntm_bin, loops_dir, last_tick_dir = sys.argv[1:5]
def stat(p):
    try:
        return int(time.time() - os.path.getmtime(p))
    except Exception:
        return None
sources = {
    "detector_executable": {"path": detector, "exists": os.access(detector, os.X_OK)},
    "ntm_executable": {"path": ntm_bin, "exists": os.access(ntm_bin, os.X_OK)},
    "loops_dir": {"path": loops_dir, "exists": os.path.isdir(loops_dir), "newest_age_sec": None},
    "last_tick_dir": {"path": last_tick_dir, "exists": os.path.isdir(last_tick_dir), "newest_age_sec": None},
}
for key in ("loops_dir", "last_tick_dir"):
    p = sources[key]["path"]
    if os.path.isdir(p):
        ages = []
        for n in os.listdir(p):
            full = os.path.join(p, n)
            a = stat(full)
            if a is not None:
                ages.append(a)
        sources[key]["newest_age_sec"] = min(ages) if ages else None
print(json.dumps({"schema_version": "cross-session-pane-truth-dashboard.v1", "mode": "audit", "sources": sources}))
PY
}

emit_why() {
  local target="$1"
  local s p
  s="${target%%:*}"
  p="${target##*:}"
  if [[ -z "$s" || -z "$p" || "$s" == "$target" ]]; then
    echo "ERROR: --why expects format <session>:<pane>" >&2
    return 3
  fi
  local row
  row="$(render_session "$s")"
  python3 - <<'PY' "$row" "$p"
import json, sys
row = json.loads(sys.argv[1])
target = int(sys.argv[2])
match = next((p for p in row.get("panes", []) if p.get("pane") == target), None)
print(json.dumps({"schema_version": "cross-session-pane-truth-dashboard.v1", "mode": "why", "target": {"session": row["session"], "pane": target}, "row": match, "session_context": {"driver_proof_age_sec": row.get("driver_proof_age_sec"), "last_callback_age_sec": row.get("last_callback_age_sec"), "source_health": row.get("source_health")}}))
PY
}

# Argument parsing.
for arg in "$@"; do
  case "$arg" in
    --json) JSON_OUT=1 ;;
    --no-color) NO_COLOR=1 ;;
    --no-emoji) NO_EMOJI=1 ;;
    --doctor) MODE="doctor" ;;
    --health) MODE="health" ;;
    --info) MODE="info" ;;
    --schema) MODE="schema" ;;
    --validate) MODE="validate" ;;
    --audit) MODE="audit" ;;
    --examples) MODE="examples" ;;
    --why=*) MODE="why"; WHY_TARGET="${arg#--why=}" ;;
    --session=*) SESSION_FILTER="${arg#--session=}" ;;
    -h|--help) usage; exit 0 ;;
    *) echo "ERROR: unknown arg: $arg" >&2; usage; exit 3 ;;
  esac
done

case "$MODE" in
  info) emit_info ;;
  schema) emit_schema ;;
  doctor) emit_doctor ;;
  health) emit_health ;;
  validate) emit_validate ;;
  audit) emit_audit ;;
  why) emit_why "${WHY_TARGET:-}" ;;
  examples)
    cat <<'EOF'
# render the dashboard for every tmux session
.flywheel/scripts/cross-session-pane-truth-dashboard.sh

# JSON envelope for robot consumption
.flywheel/scripts/cross-session-pane-truth-dashboard.sh --json

# deterministic ASCII output (no color, no emoji)
.flywheel/scripts/cross-session-pane-truth-dashboard.sh --no-color --no-emoji

# explain one pane's verdict
.flywheel/scripts/cross-session-pane-truth-dashboard.sh --why=flywheel:2 --json
EOF
    ;;
  render) render_dashboard ;;
esac

# Meta-Learning Cross-References (2026-05-19)
# Batch-16 comment backfill; citations are documentation-only and do not alter runtime behavior.
# Related: `/Users/josh/Developer/skillos/.flywheel/doctrine/meta-learnings/MP-20-cross-orch-handoff.md`
# Related: `/Users/josh/Developer/skillos/.flywheel/doctrine/meta-learnings/MP-63-phase-tick-bounded-action.md`
