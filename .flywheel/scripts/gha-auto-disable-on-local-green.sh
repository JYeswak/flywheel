#!/usr/bin/env bash
set -euo pipefail

ROOT="$(git rev-parse --show-toplevel 2>/dev/null || pwd -P)"
REMOTE=""
THRESHOLD=5
APPLY=0
RUNS_JSON=""
CLASSIFICATION=""
RECEIPTS="${ACT_GREEN_RECEIPTS:-$HOME/.local/state/flywheel/act-green-receipts.jsonl}"
LEDGER="${GHA_AUTO_DISABLE_LEDGER:-$HOME/.local/state/flywheel/gha-auto-disable-actions.jsonl}"

usage() {
  cat <<'EOF'
Usage: gha-auto-disable-on-local-green.sh [--repo PATH] [--remote OWNER/REPO]
       [--threshold N] [--runs-json PATH] [--classification PATH] [--apply] [--json]

Finds workflows with N consecutive GitHub Actions failures while a recent local
act receipt is green. Default mode reports planned disables only.
EOF
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --repo)
      ROOT="$(cd "$2" && pwd -P)"
      shift 2
      ;;
    --remote)
      REMOTE="$2"
      shift 2
      ;;
    --threshold)
      THRESHOLD="$2"
      shift 2
      ;;
    --runs-json)
      RUNS_JSON="$2"
      shift 2
      ;;
    --classification)
      CLASSIFICATION="$2"
      shift 2
      ;;
    --apply)
      APPLY=1
      shift
      ;;
    --json)
      shift
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      printf 'gha-auto-disable: unknown argument: %s\n' "$1" >&2
      usage >&2
      exit 64
      ;;
  esac
done

CLASSIFICATION="${CLASSIFICATION:-$ROOT/.flywheel/state/workflow-classification.json}"
if [[ ! -s "$CLASSIFICATION" ]]; then
  "$ROOT/.flywheel/scripts/act-workflow-classify.sh" --repo "$ROOT" --write >/dev/null
fi

if [[ -z "$REMOTE" ]]; then
  REMOTE="$(git -C "$ROOT" remote get-url origin 2>/dev/null | sed -E 's#.*github.com[:/](.+/[^/.]+)(\.git)?#\1#' || true)"
fi

tmp_runs=""
if [[ -n "$RUNS_JSON" ]]; then
  tmp_runs="$RUNS_JSON"
else
  command -v gh >/dev/null 2>&1 || { printf '{"schema_version":"flywheel.gha_auto_disable.v1","status":"skipped","reason":"gh_missing"}\n'; exit 0; }
  tmp_runs="$(mktemp -t gha-runs.XXXXXX)"
  trap 'rm -f "$tmp_runs"' EXIT
  gh run list --repo "$REMOTE" --limit 100 --json databaseId,workflowName,conclusion,status,headBranch,createdAt >"$tmp_runs"
fi

result="$(python3 - "$ROOT" "$CLASSIFICATION" "$tmp_runs" "$RECEIPTS" "$THRESHOLD" "$APPLY" "$REMOTE" <<'PY'
import datetime as dt
import json
import sys
from pathlib import Path

root = Path(sys.argv[1]).resolve()
classification_path = Path(sys.argv[2])
runs_path = Path(sys.argv[3])
receipts_path = Path(sys.argv[4]).expanduser()
threshold = int(sys.argv[5])
apply = sys.argv[6] == "1"
remote = sys.argv[7]
now = dt.datetime.now(dt.timezone.utc)

classification = json.loads(classification_path.read_text())
runs = json.loads(runs_path.read_text())
if isinstance(runs, dict):
    runs = runs.get("workflow_runs") or runs.get("runs") or runs.get("data") or []

receipt_rows = []
if receipts_path.exists():
    for line in receipts_path.read_text(errors="replace").splitlines():
        try:
            receipt_rows.append(json.loads(line))
        except Exception:
            pass

act_names = {
    row.get("name"): row for row in classification.get("workflows", [])
    if row.get("classification") == "act-compatible"
}


def parse_ts(value):
    try:
        return dt.datetime.fromisoformat(str(value).replace("Z", "+00:00"))
    except Exception:
        return None


def has_recent_green(workflow):
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
        if ts and now - ts <= dt.timedelta(hours=24):
            return row
    return None


by_name = {}
for row in runs:
    name = row.get("workflowName") or row.get("name")
    if name:
        by_name.setdefault(name, []).append(row)

actions = []
for name, workflow in sorted(act_names.items()):
    recent = by_name.get(name, [])
    failures = []
    for run in recent:
        conclusion = str(run.get("conclusion") or "").lower()
        status = str(run.get("status") or "").lower()
        if status and status != "completed":
            continue
        if conclusion == "failure":
            failures.append(run)
            continue
        break
    green = has_recent_green(workflow)
    if len(failures) >= threshold and green:
        actions.append({
            "workflow": name,
            "workflow_path": workflow.get("path"),
            "classification": workflow.get("classification"),
            "consecutive_failures": len(failures),
            "failure_run_ids": [run.get("databaseId") for run in failures[:threshold]],
            "local_green_evidence": green,
            "disable_command": f"gh workflow disable {name!r} --repo {remote}" if remote else None,
            "issue_update_command": f"br comment flywheel-ic6td 'auto-disable candidate: {name} failures={[run.get('databaseId') for run in failures[:threshold]]}'",
            "workflow_dispatch_preserved": True,
        })

for action in actions:
    action["apply_status"] = "not_applied"

if apply:
    for action in actions:
        path = root / action["workflow_path"]
        if not path.exists():
            action["apply_status"] = "workflow_file_missing"
            continue
        text = path.read_text()
        lines = text.splitlines(keepends=True)
        replaced = False
        out = []
        idx = 0
        while idx < len(lines):
            line = lines[idx]
            if line.startswith("on:"):
                out.append("on:\n")
                out.append("  workflow_dispatch:\n")
                idx += 1
                while idx < len(lines):
                    nxt = lines[idx]
                    if nxt.strip() and not nxt.startswith((" ", "\t")):
                        break
                    idx += 1
                replaced = True
                continue
            out.append(line)
            idx += 1
        if not replaced:
            action["apply_status"] = "on_block_missing"
            continue
        path.write_text("".join(out))
        action["apply_status"] = "workflow_dispatch_only"

status = "would_disable" if actions and not apply else "disabled" if actions else "pass"
print(json.dumps({
    "schema_version": "flywheel.gha_auto_disable.v1",
    "repo": str(root),
    "remote": remote,
    "threshold": threshold,
    "apply": apply,
    "status": status,
    "actions": actions,
}, separators=(",", ":")))
PY
)"

mkdir -p "$(dirname "$LEDGER")"
printf '%s\n' "$result" >>"$LEDGER"
printf '%s\n' "$result"
