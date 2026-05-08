#!/usr/bin/env bash
set -euo pipefail

VERSION="dispatch-log-backfill-v2/v1"
REPO="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd -P)"
MODE="dry-run"
JSON_OUT=0
IDEMPOTENCY_KEY=""
RECEIPT_PATH=""
EXPECTED_ANCHOR="${FLYWHEEL_MISSION_ANCHOR:-continuous-orchestrator-uptime-self-sustaining-fleet}"

usage() {
  cat <<'EOF'
usage: dispatch-log-backfill-v2.sh [--repo PATH] [--dry-run|--apply] [--idempotency-key KEY] [--receipt PATH] [--json]

Annotates legacy .flywheel/dispatch-log.jsonl rows into schema_version=2 shape.
Dry-run prints planned row annotations and does not mutate the dispatch log.
Apply requires --idempotency-key and writes an audit receipt.
EOF
}

die() {
  if [ "$JSON_OUT" -eq 1 ]; then
    jq -nc --arg status "error" --arg reason "$1" --arg version "$VERSION" \
      '{schema_version:$version,status:$status,reason:$reason}'
  else
    printf 'ERR: %s\n' "$1" >&2
  fi
  exit "${2:-2}"
}

while [ "$#" -gt 0 ]; do
  case "$1" in
    --repo) [ "$#" -ge 2 ] || die "--repo requires PATH"; REPO="$(cd "$2" && pwd -P)"; shift 2 ;;
    --repo=*) REPO="$(cd "${1#*=}" && pwd -P)"; shift ;;
    --dry-run) MODE="dry-run"; shift ;;
    --apply) MODE="apply"; shift ;;
    --idempotency-key) [ "$#" -ge 2 ] || die "--idempotency-key requires KEY"; IDEMPOTENCY_KEY="$2"; shift 2 ;;
    --idempotency-key=*) IDEMPOTENCY_KEY="${1#*=}"; shift ;;
    --receipt) [ "$#" -ge 2 ] || die "--receipt requires PATH"; RECEIPT_PATH="$2"; shift 2 ;;
    --receipt=*) RECEIPT_PATH="${1#*=}"; shift ;;
    --json) JSON_OUT=1; shift ;;
    --help|-h) usage; exit 0 ;;
    --info)
      jq -nc --arg version "$VERSION" --arg repo "$REPO" \
        '{name:"dispatch-log-backfill-v2.sh",version:$version,repo:$repo,default_mode:"dry-run",mutates:"--apply rewrites .flywheel/dispatch-log.jsonl atomically and writes receipt",requires_apply:["--idempotency-key"]}'
      exit 0
      ;;
    *) die "unknown argument: $1" ;;
  esac
done

[ -d "$REPO/.flywheel" ] || die "repo_missing_flywheel"
LOG_PATH="$REPO/.flywheel/dispatch-log.jsonl"
[ -f "$LOG_PATH" ] || die "dispatch_log_missing" 1

if [ "$MODE" = "apply" ] && [ -z "$IDEMPOTENCY_KEY" ]; then
  die "idempotency_key_required"
fi

if [ -z "$RECEIPT_PATH" ]; then
  safe_key="${IDEMPOTENCY_KEY:-dry-run}"
  safe_key="$(printf '%s' "$safe_key" | tr -cs 'A-Za-z0-9._-' '-')"
  RECEIPT_PATH="$REPO/.flywheel/receipts/dispatch-log-backfill-${safe_key}.json"
fi

TMPDIR_BACKFILL="$(mktemp -d -t u1x3.XXXXXX)"
trap 'rm -rf "$TMPDIR_BACKFILL"' EXIT
SUMMARY="$TMPDIR_BACKFILL/summary.json"
NEW_LOG="$TMPDIR_BACKFILL/dispatch-log.jsonl"

python3 - "$LOG_PATH" "$NEW_LOG" "$VERSION" "$MODE" "$IDEMPOTENCY_KEY" "$EXPECTED_ANCHOR" >"$SUMMARY" <<'PY'
import json
import re
import sys
from datetime import datetime, timezone
from pathlib import Path

log_path = Path(sys.argv[1])
new_log_path = Path(sys.argv[2])
version = sys.argv[3]
mode = sys.argv[4]
key = sys.argv[5]
mission_anchor = sys.argv[6]

now = datetime.now(timezone.utc).strftime("%Y-%m-%dT%H:%M:%SZ")

def is_v2(row):
    return str(row.get("schema_version", "")) == "2"

def first_str(row, *names, default=""):
    for name in names:
        value = row.get(name)
        if value is not None and str(value).strip():
            return str(value).strip()
    return default

def infer_session(row):
    direct = first_str(row, "session", "target_session")
    if direct:
        return direct
    for name in ("dispatched_to", "to", "target"):
        value = first_str(row, name)
        if ":" in value:
            return value.split(":", 1)[0]
    return "legacy"

def infer_pane(row):
    for name in ("pane", "target_pane", "topology_resolved_pane", "callback_pane"):
        value = row.get(name)
        if isinstance(value, int) and not isinstance(value, bool):
            return value
        if isinstance(value, str) and value.isdigit():
            return int(value)
    for name in ("dispatched_to", "to", "target"):
        value = first_str(row, name)
        match = re.search(r":([0-9]+)\b", value)
        if match:
            return int(match.group(1))
    return 0

def short_summary(row, line):
    value = first_str(row, "task_summary", "summary", "task", "bead_id", "bead", default=f"legacy dispatch row {line}")
    return value[:100] or f"legacy dispatch row {line}"

def task_file(row, line):
    value = first_str(row, "task_file", "dispatch_file", "file")
    if value.startswith("/"):
        return value
    return f"/tmp/legacy-dispatch-log-line-{line}.md"

def agent_type(row):
    value = first_str(row, "agent_type").lower()
    if value in {"codex", "claude", "gemini", "other"}:
        return value
    joined = " ".join(str(row.get(name, "")) for name in ("to", "agent", "agent_type", "worker_substrate")).lower()
    if "codex" in joined:
        return "codex"
    if "claude" in joined:
        return "claude"
    if "gemini" in joined:
        return "gemini"
    return "other"

def pane_state_source(row):
    value = first_str(row, "pane_state_source")
    if value in {"ntm_health", "ntm_copy", "raw_capture", "none"}:
        return value
    return "none"

def iso_or_now(row):
    value = first_str(row, "ts", "timestamp", "created_at")
    return value or now

def backfill(row, line):
    session = infer_session(row)
    pane = infer_pane(row)
    task_id = first_str(row, "task_id", "dispatch_id", "id", default=f"legacy-line-{line}")
    updated = dict(row)
    updated.update({
        "schema_version": 2,
        "task_id": task_id,
        "ts": iso_or_now(row),
        "from": first_str(row, "from", default="legacy-dispatch-log"),
        "to": first_str(row, "to", default=f"{session}:{pane}"),
        "pane": pane,
        "session": session,
        "task_summary": short_summary(row, line),
        "task_file": task_file(row, line),
        "agent_type": agent_type(row),
        "pane_state_source": pane_state_source(row),
        "mission_anchor": first_str(row, "mission_anchor", default=mission_anchor),
        "mission_fitness_claim": first_str(row, "mission_fitness_claim", default="legacy backfill: row predates dispatch-log v2 contract"),
        "mission_fitness_class": first_str(row, "mission_fitness_class", default="unknown"),
        "idempotency_token": first_str(row, "idempotency_token", default=f"{key or 'dry-run'}:{task_id}:{line}"),
        "callback_received_at": row.get("callback_received_at", None),
        "dispatch_skill_version": first_str(row, "dispatch_skill_version", default="legacy"),
        "backfilled": True,
        "backfill_schema_version": version,
        "backfill_source_line": line,
    })
    if key:
        updated["backfill_idempotency_key"] = key
    return updated

planned = []
output_lines = []
malformed = 0
already_v2 = 0
already_keyed = 0

for line_no, raw in enumerate(log_path.read_text(encoding="utf-8", errors="replace").splitlines(), 1):
    if not raw.strip():
        output_lines.append(raw)
        continue
    try:
        row = json.loads(raw)
    except json.JSONDecodeError:
        malformed += 1
        output_lines.append(raw)
        continue
    if not isinstance(row, dict):
        output_lines.append(raw)
        continue
    if is_v2(row):
        already_v2 += 1
        output_lines.append(json.dumps(row, sort_keys=True, separators=(",", ":")))
        continue
    if key and row.get("backfill_idempotency_key") == key:
        already_keyed += 1
        output_lines.append(json.dumps(row, sort_keys=True, separators=(",", ":")))
        continue
    new_row = backfill(row, line_no)
    planned.append({
        "line": line_no,
        "task_id": new_row["task_id"],
        "session": new_row["session"],
        "pane": new_row["pane"],
        "dispatch_skill_version": new_row["dispatch_skill_version"],
    })
    output_lines.append(json.dumps(new_row, sort_keys=True, separators=(",", ":")))

new_log_path.write_text("\n".join(output_lines) + ("\n" if output_lines else ""), encoding="utf-8")

summary = {
    "schema_version": version,
    "mode": mode,
    "status": "ok",
    "dispatch_log": str(log_path),
    "checked": len(output_lines),
    "planned_annotations": planned,
    "planned_annotations_count": len(planned),
    "already_v2_count": already_v2,
    "already_keyed_count": already_keyed,
    "malformed_skipped_count": malformed,
    "mutated": False,
}
if key:
    summary["idempotency_key"] = key
print(json.dumps(summary, sort_keys=True))
PY

if [ "$MODE" = "apply" ]; then
  tmp_log="$(mktemp "${LOG_PATH}.XXXXXX")"
  cp "$NEW_LOG" "$tmp_log"
  mv "$tmp_log" "$LOG_PATH"
  mkdir -p "$(dirname "$RECEIPT_PATH")"
  jq --arg ts "$(date -u +"%Y-%m-%dT%H:%M:%SZ")" --arg receipt "$RECEIPT_PATH" \
    '. + {mutated:true, applied_at:$ts, audit_receipt_path:$receipt}' "$SUMMARY" >"$RECEIPT_PATH"
  cp "$RECEIPT_PATH" "$SUMMARY"
fi

if [ "$JSON_OUT" -eq 1 ]; then
  cat "$SUMMARY"
else
  jq -r '
    "mode=\(.mode) planned_annotations=\(.planned_annotations_count) already_v2=\(.already_v2_count) malformed_skipped=\(.malformed_skipped_count) mutated=\(.mutated)",
    (.planned_annotations[]? | "line=\(.line) task_id=\(.task_id) session=\(.session) pane=\(.pane) dispatch_skill_version=\(.dispatch_skill_version)")
  ' "$SUMMARY"
fi
