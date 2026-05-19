#!/usr/bin/env bash
set -euo pipefail

VERSION="orch-p0-completion-gate.v1.0.0"
SCHEMA_VERSION="orch-p0-completion-gate/v1"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)"
REPO="$(cd "$SCRIPT_DIR/../.." && pwd -P)"
ISSUES_JSONL="$REPO/.beads/issues.jsonl"
COMMAND_TEXT=""
JSON_OUT=0
NOW_EPOCH=""
ORCH_IDS=()

usage() {
  cat <<'EOF'
usage:
  orch-p0-completion-gate.sh check --command TEXT --orch-id ID [--issues-jsonl PATH] [--json]
  orch-p0-completion-gate.sh --info|--help|--examples

Exit codes: 0=ok, 1=block, 2=malformed-input, 3=read-error.
EOF
}

examples() {
  cat <<'EOF'
examples:
  .flywheel/scripts/orch-p0-completion-gate.sh check --command 'br create "new"' --orch-id flywheel:1 --json
  .flywheel/scripts/orch-p0-completion-gate.sh check --command 'br update flywheel-x --priority 1' --orch-id flywheel:1 --json
EOF
}

info() {
  jq -nc \
    --arg version "$VERSION" \
    --arg schema "$SCHEMA_VERSION" \
    --arg repo "$REPO" \
    --arg issues "$ISSUES_JSONL" \
    '{name:"orch-p0-completion-gate.sh",version:$version,schema_version:$schema,repo:$repo,
      issues_jsonl:$issues,read_only:true,
      commands:["check","--command","--orch-id","--issues-jsonl","--repo","--json","--info","--examples","--help"],
      exit_codes:{"0":"ok","1":"block","2":"malformed-input","3":"read-error"}}'
}

emit_text() {
  local payload="$1"
  jq -r 'if .decision == "block" then
    "BLOCK oldest_unfinished_p0=\(.oldest_unfinished_p0.id) age_seconds=\(.oldest_unfinished_p0.age_seconds)"
  elif .decision == "error" then
    "ERROR reason=\(.reason)"
  else
    "ALLOW reason=\(.reason)"
  end' <<<"$payload"
}

run_check() {
  local payload rc
  set +e
  payload="$(python3 - "$ISSUES_JSONL" "$COMMAND_TEXT" "$NOW_EPOCH" "${ORCH_IDS[@]}" <<'PY'
import json, re, sys, time
from datetime import datetime, timezone

issues, command, now_arg, *orch_ids = sys.argv[1:]
schema = "orch-p0-completion-gate/v1"
orch_ids = [x for x in orch_ids if x]
now = int(now_arg) if now_arg else int(time.time())

def out(decision, reason, exit_code, **extra):
    payload = {
        "schema_version": schema, "decision": decision, "reason": reason,
        "exit_code": exit_code, "read_only": True, "issues_jsonl": issues,
        "command_action": action_for(command), "current_orch_ids": orch_ids,
    }
    payload.update(extra)
    print(json.dumps(payload, separators=(",", ":")))
    sys.exit(exit_code)

def action_for(cmd):
    if not cmd.strip():
        return "none"
    tool = r'(?<![\w./-])(?:\S*/)?(?:br|bd)(?:\s+--db\s+\S+)?'
    if re.search(tool + r'\s+create\b', cmd):
        return "create"
    if re.search(tool + r'\s+update\b', cmd):
        m = re.search(r'--priority(?:=|\s+)([^\s;&|]+)|(?:^|\s)-p\s+([^\s;&|]+)', cmd)
        if m:
            val = (m.group(1) or m.group(2) or "").strip("'\"").lower()
            if val not in {"0", "p0"}:
                return "p0_downgrade"
        return "update_other"
    return "none"

def epoch(value):
    if not value:
        return None
    try:
        return int(datetime.fromisoformat(str(value).replace("Z", "+00:00")).timestamp())
    except Exception:
        return None

def owner_values(row):
    keys = ["owner", "assignee", "created_by", "updated_by", "orch_identity",
            "owning_orch", "orchestrator", "owner_identity", "actor", "session"]
    vals = []
    for key in keys:
        value = row.get(key)
        if isinstance(value, str):
            vals.append(value)
        elif isinstance(value, list):
            vals.extend(str(v) for v in value)
        elif isinstance(value, dict):
            vals.extend(str(v) for v in value.values() if isinstance(v, (str, int)))
    return {v for v in vals if v and v != "unassigned"}

def p0(value):
    return value == 0 or str(value).lower() in {"0", "p0"}

latest = {}
try:
    handle = open(issues, encoding="utf-8")
except OSError as exc:
    out("error", "issues_jsonl_read_error", 3, error=str(exc))

with handle:
    for line_no, line in enumerate(handle, 1):
        text = line.strip()
        if not text:
            continue
        try:
            row = json.loads(text)
        except json.JSONDecodeError as exc:
            out("error", "malformed_jsonl", 2, malformed_line=line_no, error=str(exc))
        if not isinstance(row, dict):
            out("error", "malformed_jsonl_non_object", 2, malformed_line=line_no)
        issue_id = row.get("id")
        if not issue_id:
            continue
        merged = dict(latest.get(issue_id, {}))
        merged.update(row)
        latest[issue_id] = merged

action = action_for(command)
if action not in {"create", "p0_downgrade"}:
    out("allow", "action_not_gated", 0, unfinished_p0_count=0, oldest_unfinished_p0=None)

matches = []
for row in latest.values():
    owners = owner_values(row)
    if row.get("status") == "in_progress" and p0(row.get("priority")) and (set(orch_ids) & owners or "*" in orch_ids):
        created_epoch = epoch(row.get("created_at"))
        age = None if created_epoch is None else max(0, now - created_epoch)
        matches.append({
            "id": row.get("id"), "title": row.get("title"), "status": row.get("status"),
            "priority": row.get("priority"), "created_at": row.get("created_at"),
            "age_seconds": age, "owner_matches": sorted(set(orch_ids) & owners),
        })

matches.sort(key=lambda r: (r["age_seconds"] is None, -(r["age_seconds"] or 0), str(r["id"])))
if matches:
    out("block", "owned_unfinished_p0_exists", 1, unfinished_p0_count=len(matches), oldest_unfinished_p0=matches[0])
out("allow", "no_owned_unfinished_p0", 0, unfinished_p0_count=0, oldest_unfinished_p0=None)
PY
)"
  rc=$?
  set -e
  if [[ "$JSON_OUT" -eq 1 ]]; then
    printf '%s\n' "$payload"
  else
    emit_text "$payload"
  fi
  return "$rc"
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    check) shift ;;
    --command) COMMAND_TEXT="${2:-}"; shift 2 ;;
    --command=*) COMMAND_TEXT="${1#*=}"; shift ;;
    --orch-id) ORCH_IDS+=("${2:-}"); shift 2 ;;
    --orch-id=*) ORCH_IDS+=("${1#*=}"); shift ;;
    --issues-jsonl) ISSUES_JSONL="${2:-}"; shift 2 ;;
    --issues-jsonl=*) ISSUES_JSONL="${1#*=}"; shift ;;
    --repo) REPO="${2:-}"; ISSUES_JSONL="$REPO/.beads/issues.jsonl"; shift 2 ;;
    --repo=*) REPO="${1#*=}"; ISSUES_JSONL="$REPO/.beads/issues.jsonl"; shift ;;
    --now-epoch) NOW_EPOCH="${2:-}"; shift 2 ;;
    --now-epoch=*) NOW_EPOCH="${1#*=}"; shift ;;
    --json) JSON_OUT=1; shift ;;
    --info) info; exit 0 ;;
    --examples) examples; exit 0 ;;
    --help|-h) usage; exit 0 ;;
    *) printf 'ERR unknown argument: %s\n' "$1" >&2; usage >&2; exit 2 ;;
  esac
done

run_check

# Meta-Learning Cross-References (2026-05-19)
# Batch-16 comment backfill; citations are documentation-only and do not alter runtime behavior.
# Related: `/Users/josh/Developer/skillos/.flywheel/doctrine/meta-learnings/MP-20-cross-orch-handoff.md`
# Related: `/Users/josh/Developer/skillos/.flywheel/doctrine/meta-learnings/MP-63-phase-tick-bounded-action.md`
