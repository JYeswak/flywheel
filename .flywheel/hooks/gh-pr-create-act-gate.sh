#!/usr/bin/env bash
set -euo pipefail

INPUT="$(cat)"
TOOL="$(printf '%s' "$INPUT" | jq -r '.tool_name // ""' 2>/dev/null || true)"
[[ "$TOOL" == "Bash" ]] || exit 0

CMD="$(printf '%s' "$INPUT" | jq -r '.tool_input.command // ""' 2>/dev/null || true)"
[[ -n "$CMD" ]] || exit 0

if ! printf '%s' "$CMD" | grep -qE '(^|[[:space:];&|`(])gh[[:space:]]+pr[[:space:]]+create([[:space:]]|$)'; then
  exit 0
fi

CWD="$(printf '%s' "$INPUT" | jq -r '.cwd // empty' 2>/dev/null || true)"
[[ -n "$CWD" ]] || CWD="$PWD"
ROOT="$(git -C "$CWD" rev-parse --show-toplevel 2>/dev/null || true)"
[[ -n "$ROOT" ]] || exit 0

CLASSIFIER="${ACT_WORKFLOW_CLASSIFIER:-/Users/josh/Developer/flywheel/.flywheel/scripts/act-workflow-classify.sh}"
RECEIPTS="${ACT_GREEN_RECEIPTS:-$HOME/.local/state/flywheel/act-green-receipts.jsonl}"
OVERRIDES="${ACT_GATE_OVERRIDES:-$HOME/.local/state/flywheel/act-gate-overrides.jsonl}"
MAX_AGE_HOURS="${ACT_GREEN_MAX_AGE_HOURS:-24}"

if printf '%s' "$CMD" | grep -qE -- '--skip-act-gate='; then
  reason="$(printf '%s' "$CMD" | sed -nE 's/.*--skip-act-gate=("([^"]*)"|'\''([^'\'']*)'\''|([^[:space:]]+)).*/\2\3\4/p' | head -1)"
  mkdir -p "$(dirname "$OVERRIDES")" 2>/dev/null || true
  jq -nc \
    --arg schema_version "flywheel.act_gate_override.v1" \
    --arg ts "$(date -u +%Y-%m-%dT%H:%M:%SZ)" \
    --arg repo "$ROOT" \
    --arg reason "$reason" \
    --arg command "$CMD" \
    '{schema_version:$schema_version,ts:$ts,repo:$repo,reason:$reason,command_snippet:($command[:240])}' >>"$OVERRIDES" 2>/dev/null || true
  exit 0
fi

[[ -x "$CLASSIFIER" ]] || exit 0
CLASSIFICATION="$("$CLASSIFIER" --repo "$ROOT" --json 2>/dev/null || true)"
[[ -n "$CLASSIFICATION" ]] || exit 0

HOOK_INPUT="$INPUT" CLASSIFICATION="$CLASSIFICATION" python3 - "$ROOT" "$RECEIPTS" "$MAX_AGE_HOURS" <<'PY'
import datetime as dt
import json
import os
import sys
from pathlib import Path

root = Path(sys.argv[1]).resolve()
receipts = Path(sys.argv[2]).expanduser()
max_age = dt.timedelta(hours=int(sys.argv[3]))
now = dt.datetime.now(dt.timezone.utc)

try:
    classification = json.loads(os.environ["CLASSIFICATION"])
except Exception:
    sys.exit(0)

workflows = [
    row for row in classification.get("workflows", [])
    if row.get("classification") == "act-compatible"
    and "pull_request" in set(row.get("triggers") or [])
]
if not workflows:
    sys.exit(0)

receipt_rows = []
if receipts.exists():
    for line in receipts.read_text(errors="replace").splitlines():
        if not line.strip():
            continue
        try:
            receipt_rows.append(json.loads(line))
        except Exception:
            continue


def parse_ts(value):
    try:
        return dt.datetime.fromisoformat(str(value).replace("Z", "+00:00"))
    except Exception:
        return None


def green_for(workflow):
    wanted = {workflow.get("path"), workflow.get("name")}
    for row in reversed(receipt_rows):
        repo = row.get("repo") or row.get("repo_path")
        if repo and Path(str(repo)).expanduser().resolve() != root:
            continue
        status = str(row.get("status") or row.get("conclusion") or "").lower()
        if status not in {"pass", "passed", "success", "green", "ok"}:
            continue
        wf = row.get("workflow") or row.get("workflow_path") or row.get("workflowName") or row.get("workflow_name")
        if wf not in wanted:
            continue
        ts = parse_ts(row.get("ts") or row.get("created_at") or row.get("verified_at"))
        if ts and now - ts <= max_age:
            return True
    return False


missing = [row for row in workflows if not green_for(row)]
if not missing:
    sys.exit(0)

details = ", ".join(f"{row.get('path')} ({row.get('name')})" for row in missing)
print(
    "[gh-pr-create-act-gate] BLOCKED: gh pr create requires a <24h green local act receipt "
    f"for act-compatible workflow(s): {details}. "
    f"Run act locally, append a pass row to {receipts}, or use --skip-act-gate=\"reason\".",
    file=sys.stderr,
)
sys.exit(2)
PY
