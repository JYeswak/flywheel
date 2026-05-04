#!/usr/bin/env bash
set -euo pipefail

VERSION="worker-stall-alert-probe/v1"
NTM_BIN="${NTM_BIN:-/Users/josh/.local/bin/ntm}"
SESSION="flywheel"
REPO="/Users/josh/Developer/flywheel"
TOPOLOGY="${FLYWHEEL_SESSION_TOPOLOGY:-$HOME/.local/state/flywheel/session-topology.jsonl}"
STATE_DIR="${FLYWHEEL_STALL_ALERT_STATE_DIR:-$HOME/.local/state/flywheel/worker-stall-alerts}"
ACTIVITY_FIXTURE=""
TAIL_FIXTURE=""
TOPOLOGY_FIXTURE=""
DISPATCH_LOG_FIXTURE=""
JSON_OUT=0
APPLY=0
DRY_RUN=1
TICK_THRESHOLD=2
MIN_AGE_SECONDS=120
ALERT_COOLDOWN_SECONDS=600
TAIL_LINES=80
PROBE_TEXT="L95 stall probe: are you still making progress? Reply briefly, continue if working, or send DONE/BLOCKED callback if complete."

usage() {
  cat <<'USAGE'
Usage:
  worker-stall-alert-probe.sh --session NAME [--repo PATH] [--dry-run|--apply] [--json]
  worker-stall-alert-probe.sh --info [--json]
  worker-stall-alert-probe.sh --examples [--json]
  worker-stall-alert-probe.sh --schema [--json]

Detects two-tick worker stalls and alerts the session orchestrator. Default is
dry-run. Apply mode writes state/receipts and sends L95 probe/alert messages.
USAGE
}

emit_info() {
  if [[ "$JSON_OUT" -eq 1 ]]; then
    jq -nc --arg version "$VERSION" '{
      schema_version:$version,
      command:"worker-stall-alert-probe.sh",
      mutation_default:"dry-run",
      purpose:"Detect repeated unchanged THINKING/WORKING worker state and alert orchestrators with L95 receipt fields",
      thresholds:{tick_threshold:2,min_age_seconds:120,alert_cooldown_seconds:600},
      canonical_flags:["--help","--info","--examples","--schema","--dry-run","--apply","--json","--session","--repo"]
    }'
  else
    printf '%s\nmutation_default=dry-run\n' "$VERSION"
  fi
}

emit_examples() {
  if [[ "$JSON_OUT" -eq 1 ]]; then
    jq -nc '{examples:[
      "worker-stall-alert-probe.sh --session flywheel --dry-run --json",
      "worker-stall-alert-probe.sh --session mobile-eats --apply --json",
      "worker-stall-alert-probe.sh --session flywheel --tick-threshold 2 --min-age-seconds 0 --json"
    ]}'
  else
    printf '%s\n' \
      "worker-stall-alert-probe.sh --session flywheel --dry-run --json" \
      "worker-stall-alert-probe.sh --session mobile-eats --apply --json" \
      "worker-stall-alert-probe.sh --session flywheel --tick-threshold 2 --min-age-seconds 0 --json"
  fi
}

emit_schema() {
  jq -nc --arg version "$VERSION" '{
    "$schema":"https://json-schema.org/draft/2020-12/schema",
    title:"worker stall alert probe output",
    type:"object",
    required:["schema_version","session","dry_run","apply","worker_stall_candidate_count","alerts_sent_count","receipts"],
    properties:{
      schema_version:{const:$version},
      session:{type:"string"},
      dry_run:{type:"boolean"},
      apply:{type:"boolean"},
      worker_stall_candidate_count:{type:"integer"},
      alerts_sent_count:{type:"integer"},
      receipts:{type:"array"}
    }
  }'
}

for arg in "$@"; do
  [[ "$arg" == "--json" ]] && JSON_OUT=1
done

while [[ $# -gt 0 ]]; do
  case "$1" in
    --session) SESSION="${2:?--session requires NAME}"; shift 2 ;;
    --session=*) SESSION="${1#*=}"; shift ;;
    --repo) REPO="${2:?--repo requires PATH}"; shift 2 ;;
    --repo=*) REPO="${1#*=}"; shift ;;
    --topology) TOPOLOGY="${2:?--topology requires PATH}"; shift 2 ;;
    --topology=*) TOPOLOGY="${1#*=}"; shift ;;
    --state-dir) STATE_DIR="${2:?--state-dir requires PATH}"; shift 2 ;;
    --state-dir=*) STATE_DIR="${1#*=}"; shift ;;
    --activity-fixture) ACTIVITY_FIXTURE="${2:?--activity-fixture requires PATH}"; shift 2 ;;
    --activity-fixture=*) ACTIVITY_FIXTURE="${1#*=}"; shift ;;
    --tail-fixture) TAIL_FIXTURE="${2:?--tail-fixture requires PATH}"; shift 2 ;;
    --tail-fixture=*) TAIL_FIXTURE="${1#*=}"; shift ;;
    --topology-fixture) TOPOLOGY_FIXTURE="${2:?--topology-fixture requires PATH}"; shift 2 ;;
    --topology-fixture=*) TOPOLOGY_FIXTURE="${1#*=}"; shift ;;
    --dispatch-log-fixture) DISPATCH_LOG_FIXTURE="${2:?--dispatch-log-fixture requires PATH}"; shift 2 ;;
    --dispatch-log-fixture=*) DISPATCH_LOG_FIXTURE="${1#*=}"; shift ;;
    --tick-threshold) TICK_THRESHOLD="${2:?--tick-threshold requires N}"; shift 2 ;;
    --tick-threshold=*) TICK_THRESHOLD="${1#*=}"; shift ;;
    --min-age-seconds) MIN_AGE_SECONDS="${2:?--min-age-seconds requires N}"; shift 2 ;;
    --min-age-seconds=*) MIN_AGE_SECONDS="${1#*=}"; shift ;;
    --alert-cooldown-seconds) ALERT_COOLDOWN_SECONDS="${2:?--alert-cooldown-seconds requires N}"; shift 2 ;;
    --alert-cooldown-seconds=*) ALERT_COOLDOWN_SECONDS="${1#*=}"; shift ;;
    --tail-lines) TAIL_LINES="${2:?--tail-lines requires N}"; shift 2 ;;
    --tail-lines=*) TAIL_LINES="${1#*=}"; shift ;;
    --probe-text) PROBE_TEXT="${2:?--probe-text requires TEXT}"; shift 2 ;;
    --dry-run) APPLY=0; DRY_RUN=1; shift ;;
    --apply) APPLY=1; DRY_RUN=0; shift ;;
    --json) JSON_OUT=1; shift ;;
    --help|-h) usage; exit 0 ;;
    --info) emit_info; exit 0 ;;
    --examples) emit_examples; exit 0 ;;
    --schema) emit_schema; exit 0 ;;
    --version) printf '%s\n' "$VERSION"; exit 0 ;;
    *) printf 'ERR: unknown argument: %s\n' "$1" >&2; usage >&2; exit 64 ;;
  esac
done

tmpdir="$(mktemp -d "${TMPDIR:-/tmp}/worker-stall-alert.XXXXXX")"
trap 'rm -rf "$tmpdir"' EXIT

if [[ -n "$ACTIVITY_FIXTURE" ]]; then
  cp "$ACTIVITY_FIXTURE" "$tmpdir/activity.json"
else
  "$NTM_BIN" "--robot-activity=$SESSION" --activity-type=codex,claude --json >"$tmpdir/activity.json" 2>/dev/null || printf '{"agents":[]}' >"$tmpdir/activity.json"
fi

if [[ -n "$TOPOLOGY_FIXTURE" ]]; then
  cp "$TOPOLOGY_FIXTURE" "$tmpdir/topology.json"
elif [[ -s "$TOPOLOGY" ]]; then
  jq -sc --arg session "$SESSION" 'map(select(.session == $session)) | sort_by(.effective_at // "") | last // {session:$session}' "$TOPOLOGY" >"$tmpdir/topology.json" 2>/dev/null || printf '{"session":"%s"}\n' "$SESSION" >"$tmpdir/topology.json"
else
  printf '{"session":"%s"}\n' "$SESSION" >"$tmpdir/topology.json"
fi

panes_csv="$(jq -r 'if ((.worker_panes // []) | length) > 0 then (.worker_panes | map(tostring) | join(",")) else "2,3,4" end' "$tmpdir/topology.json")"
if [[ -n "$TAIL_FIXTURE" ]]; then
  cp "$TAIL_FIXTURE" "$tmpdir/tail.json"
else
  "$NTM_BIN" "--robot-tail=$SESSION" --panes="$panes_csv" --lines="$TAIL_LINES" >"$tmpdir/tail.json" 2>/dev/null || printf '{"panes":{}}\n' >"$tmpdir/tail.json"
fi

dispatch_log="${DISPATCH_LOG_FIXTURE:-$REPO/.flywheel/dispatch-log.jsonl}"
state_file="$STATE_DIR/$(printf '%s' "$SESSION" | tr -c 'A-Za-z0-9_.-' '_').json"

python3 - "$VERSION" "$SESSION" "$REPO" "$STATE_DIR" "$state_file" "$tmpdir/activity.json" "$tmpdir/tail.json" "$tmpdir/topology.json" "$dispatch_log" "$NTM_BIN" "$APPLY" "$DRY_RUN" "$TICK_THRESHOLD" "$MIN_AGE_SECONDS" "$ALERT_COOLDOWN_SECONDS" "$PROBE_TEXT" <<'PY'
import hashlib
import json
import re
import subprocess
import sys
from datetime import datetime, timezone
from pathlib import Path

version, session, repo, state_dir_raw, state_file_raw, activity_path, tail_path, topology_path, dispatch_log, ntm_bin, apply_raw, dry_raw, tick_threshold_raw, min_age_raw, cooldown_raw, probe_text = sys.argv[1:]
apply = apply_raw == "1"
dry_run = dry_raw == "1"
tick_threshold = int(tick_threshold_raw)
min_age_seconds = int(min_age_raw)
alert_cooldown_seconds = int(cooldown_raw)
state_dir = Path(state_dir_raw).expanduser()
state_file = Path(state_file_raw).expanduser()
now = datetime.now(timezone.utc)
now_iso = now.replace(microsecond=0).isoformat().replace("+00:00", "Z")
now_ts = now.timestamp()

def load_json(path, default):
    try:
        return json.loads(Path(path).read_text(encoding="utf-8"))
    except Exception:
        return default

def parse_ts(value):
    if not value:
        return None
    try:
        return datetime.fromisoformat(str(value).replace("Z", "+00:00")).astimezone(timezone.utc)
    except Exception:
        return None

def jsonl_rows(path):
    p = Path(path).expanduser()
    if not p.exists():
        return []
    rows = []
    for line in p.read_text(encoding="utf-8", errors="replace").splitlines():
        if not line.strip():
            continue
        try:
            row = json.loads(line)
        except Exception:
            continue
        if isinstance(row, dict):
            rows.append(row)
    return rows

def active_dispatch_by_pane(rows):
    active = {}
    for row in rows:
        if row.get("callback_received_at") not in (None, "", "null"):
            continue
        pane = row.get("target_pane") if row.get("target_pane") is not None else row.get("pane")
        if pane is None or not str(pane).isdigit():
            continue
        task_id = row.get("task_id")
        if not task_id:
            continue
        status = str(row.get("status") or "")
        if status and status not in {"dispatched", "dispatching", "sent", "send_failed"}:
            continue
        active[str(int(pane))] = row
    return active

def normalize_tail(payload):
    panes = payload.get("panes") if isinstance(payload, dict) else {}
    result = {}
    if isinstance(panes, dict):
        iterator = panes.items()
    elif isinstance(panes, list):
        iterator = [(str(row.get("pane") or row.get("pane_idx") or ""), row) for row in panes if isinstance(row, dict)]
    else:
        iterator = []
    for key, row in iterator:
        lines = row.get("lines")
        text = "\n".join(str(x) for x in lines) if isinstance(lines, list) else str(row.get("text") or row.get("content") or row.get("capture") or row.get("output") or "")
        result[str(key)] = {
            "fresh_output_hash": hashlib.sha256(text.encode("utf-8", errors="replace")).hexdigest(),
            "checkpoint_capture_ts": row.get("capture_collected_at") or payload.get("captured_at") or payload.get("timestamp"),
            "capture_provenance": row.get("capture_provenance") or "unknown",
        }
    return result

activity = load_json(activity_path, {"agents": []})
tail = normalize_tail(load_json(tail_path, {"panes": {}}))
topology = load_json(topology_path, {"session": session})
previous = load_json(state_file, {"panes": {}})
prev_panes = previous.get("panes") if isinstance(previous.get("panes"), dict) else {}
worker_panes = [str(int(p)) for p in topology.get("worker_panes") or [2, 3, 4]]
callback_pane = topology.get("callback_pane", topology.get("orchestrator_pane", 1))
try:
    callback_pane = int(callback_pane)
except Exception:
    callback_pane = 1

active_by_pane = active_dispatch_by_pane(jsonl_rows(dispatch_log))
observations = {}
receipts = []
alerts_sent = []
probe_sends = []
candidate_count = 0
alertable_states = {"THINKING", "WORKING", "GENERATING", "RUNNING"}

for agent in activity.get("agents") or []:
    pane_raw = agent.get("pane_idx", agent.get("pane"))
    if pane_raw is None or not str(pane_raw).isdigit():
        continue
    pane = str(int(pane_raw))
    if pane not in worker_panes:
        continue
    state = str(agent.get("state") or "UNKNOWN")
    if state not in alertable_states:
        continue
    if str(agent.get("capture_provenance") or "") != "live":
        continue
    task = active_by_pane.get(pane, {"task_id": f"unknown-pane-{pane}", "callback_received_at": None})
    task_id = str(task.get("task_id"))
    tail_row = tail.get(pane, {"fresh_output_hash": hashlib.sha256(b"").hexdigest(), "checkpoint_capture_ts": now_iso, "capture_provenance": "missing"})
    prev = prev_panes.get(pane, {})
    same_state = prev.get("state") == state
    same_task = prev.get("task_id") == task_id
    same_hash = prev.get("fresh_output_hash") == tail_row["fresh_output_hash"]
    same_state_since = prev.get("state_since") == agent.get("state_since")
    stable = same_state and same_task and same_hash and same_state_since
    same_tick_count = int(prev.get("same_tick_count") or 0) + 1 if stable else 1
    first_seen = prev.get("first_seen_ts") if stable and prev.get("first_seen_ts") else now_iso
    first_seen_dt = parse_ts(first_seen) or now
    age_seconds = max(0, int(now_ts - first_seen_dt.timestamp()))
    alert_key = hashlib.sha256(f"{session}:{pane}:{task_id}:{tail_row['fresh_output_hash']}".encode()).hexdigest()
    last_alert_at = parse_ts(prev.get("last_alert_ts"))
    cooldown_open = bool(prev.get("last_alert_key") == alert_key and last_alert_at and (now_ts - last_alert_at.timestamp()) < alert_cooldown_seconds)
    is_candidate = same_tick_count >= tick_threshold and age_seconds >= min_age_seconds and not cooldown_open
    if is_candidate:
        candidate_count += 1
    receipt_path = str(state_dir / "receipts" / f"{session}-pane{pane}-{re.sub(r'[^A-Za-z0-9_.-]', '_', task_id)}-{now.strftime('%Y%m%dT%H%M%SZ')}.json")
    receipt = {
        "schema_version": "worker-stall-alert-receipt/v1",
        "stall_detection_ts": now_iso,
        "session": session,
        "pane": int(pane),
        "task_id": task_id,
        "last_output_hash": prev.get("fresh_output_hash"),
        "fresh_output_hash": tail_row["fresh_output_hash"],
        "fresh_output_advanced": not same_hash,
        "callback_delivered": False,
        "probe_attempted": False,
        "probe_response_ts": None,
        "grace_window_seconds": 0,
        "checkpoint_capture_ts": tail_row.get("checkpoint_capture_ts") or now_iso,
        "robot_activity_before": prev.get("robot_activity_after"),
        "robot_activity_after": agent,
        "resolution": "alerted" if is_candidate else "observing",
        "same_tick_count": same_tick_count,
        "first_seen_ts": first_seen,
        "age_seconds": age_seconds,
        "work_timer_same": same_state_since,
        "state_same": same_state,
        "task_same": same_task,
        "output_hash_same": same_hash,
        "receipt_path": receipt_path if is_candidate else None,
    }
    if is_candidate and apply:
        state_dir.joinpath("receipts").mkdir(parents=True, exist_ok=True)
        probe = subprocess.run([ntm_bin, "send", session, f"--pane={pane}", "--no-cass-check", probe_text], text=True, stdout=subprocess.PIPE, stderr=subprocess.PIPE)
        receipt["probe_attempted"] = True
        receipt["probe_send_exit_code"] = probe.returncode
        probe_sends.append({"pane": int(pane), "exit_code": probe.returncode})
        alert = f"L95_STALL_ALERT session={session} pane={pane} task_id={task_id} same_tick_count={same_tick_count} age_seconds={age_seconds} receipt={receipt_path} l95_recovery_required=true no_respawn=true no_raw_tokens=true"
        sent = subprocess.run([ntm_bin, "send", session, f"--pane={callback_pane}", "--no-cass-check", alert], text=True, stdout=subprocess.PIPE, stderr=subprocess.PIPE)
        receipt["orchestrator_alert_sent"] = sent.returncode == 0
        receipt["orchestrator_alert_exit_code"] = sent.returncode
        receipt["orchestrator_alert_pane"] = callback_pane
        Path(receipt_path).write_text(json.dumps(receipt, indent=2, sort_keys=True) + "\n", encoding="utf-8")
        alerts_sent.append({"pane": int(pane), "callback_pane": callback_pane, "exit_code": sent.returncode, "receipt_path": receipt_path})
    if is_candidate:
        receipts.append(receipt)
    observations[pane] = {
        "state": state,
        "state_since": agent.get("state_since"),
        "task_id": task_id,
        "fresh_output_hash": tail_row["fresh_output_hash"],
        "same_tick_count": same_tick_count,
        "first_seen_ts": first_seen,
        "last_seen_ts": now_iso,
        "last_alert_key": alert_key if (is_candidate and apply) else prev.get("last_alert_key"),
        "last_alert_ts": now_iso if (is_candidate and apply) else prev.get("last_alert_ts"),
        "robot_activity_after": agent,
    }

if apply:
    state_file.parent.mkdir(parents=True, exist_ok=True)
    state_file.write_text(json.dumps({"schema_version": version, "session": session, "updated_at": now_iso, "panes": observations}, indent=2, sort_keys=True) + "\n", encoding="utf-8")

print(json.dumps({
    "schema_version": version,
    "session": session,
    "repo": repo,
    "dry_run": dry_run,
    "apply": apply,
    "state_file": str(state_file),
    "tick_threshold": tick_threshold,
    "min_age_seconds": min_age_seconds,
    "alert_cooldown_seconds": alert_cooldown_seconds,
    "worker_panes": [int(p) for p in worker_panes],
    "callback_pane": callback_pane,
    "worker_stall_candidate_count": candidate_count,
    "alerts_sent_count": len(alerts_sent),
    "probe_sends_count": len(probe_sends),
    "alerts_sent": alerts_sent,
    "probe_sends": probe_sends,
    "receipts": receipts,
}, separators=(",", ":")))
PY
