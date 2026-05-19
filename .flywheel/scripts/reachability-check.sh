#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd -P)"
DEFAULT_INVENTORY="$ROOT/.flywheel/inventory/2026-05-19-rebuild/inventory-rebuild.jsonl"

inventory="$DEFAULT_INVENTORY"
dispatch_log=""
json=0

usage() {
  cat <<'EOF'
usage: .flywheel/scripts/reachability-check.sh [--json] [--inventory PATH] [--dispatch-log PATH] <surface-path>

Returns 0 when a surface is mechanically reachable:
  1. inventory/dispatch evidence shows invoke_count_30d > 0, OR
  2. another tracked file in the same repo references the surface path.

Returns 1 for dead-code candidates, including missing files.
EOF
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --json) json=1; shift ;;
    --inventory) inventory="$2"; shift 2 ;;
    --dispatch-log) dispatch_log="$2"; shift 2 ;;
    -h|--help) usage; exit 0 ;;
    --) shift; break ;;
    -*) printf 'unknown arg: %s\n' "$1" >&2; usage >&2; exit 64 ;;
    *) break ;;
  esac
done

[[ "$#" -eq 1 ]] || { usage >&2; exit 64; }
surface="$1"

emit() {
  local payload="$1"
  if [[ "$json" -eq 1 ]]; then
    printf '%s\n' "$payload"
  else
    printf '%s\n' "$payload" | jq -r '.reason'
  fi
}

if [[ "$surface" != /* ]]; then
  surface="$(cd "$(dirname "$surface")" 2>/dev/null && pwd -P)/$(basename "$surface")"
fi
surface="$(python3 - "$surface" <<'PY'
import os
import sys

print(os.path.realpath(sys.argv[1]))
PY
)"

if [[ ! -e "$surface" ]]; then
  payload="$(jq -nc --arg surface "$surface" '{surface:$surface,reachable:false,reason:"missing_surface",invoke_count_30d:0,dispatch_log_hits:0,inbound_caller_count:0,inbound_callers:[]}')"
  emit "$payload"
  exit 1
fi

repo_root="$(git -C "$(dirname "$surface")" rev-parse --show-toplevel 2>/dev/null || true)"
if [[ -z "$repo_root" ]]; then
  repo_root="$(cd "$(dirname "$surface")" && pwd -P)"
fi
rel_path="$(python3 - "$repo_root" "$surface" <<'PY'
import os, sys
print(os.path.relpath(sys.argv[2], sys.argv[1]))
PY
)"

if [[ -z "$dispatch_log" ]]; then
  dispatch_log="$repo_root/.flywheel/dispatch-log.jsonl"
fi

evidence_json="$(python3 - "$inventory" "$dispatch_log" "$repo_root" "$rel_path" "$surface" <<'PY'
import json
import os
import sys
from datetime import datetime, timezone, timedelta

inventory, dispatch_log, repo_root, rel_path, surface = sys.argv[1:6]
abs_surface = os.path.realpath(surface)
invoke_count = 0

def load_jsonl(path):
    if not path or not os.path.exists(path):
        return
    with open(path, "r", encoding="utf-8") as f:
        for line in f:
            line = line.strip()
            if not line:
                continue
            try:
                yield json.loads(line)
            except json.JSONDecodeError:
                continue

for row in load_jsonl(inventory) or []:
    if os.path.realpath(os.path.join(str(row.get("repo_path", "")), str(row.get("path", "")))) == abs_surface:
        try:
            invoke_count = max(invoke_count, int(row.get("invoke_count_30d") or 0))
        except (TypeError, ValueError):
            pass

since = datetime.now(timezone.utc) - timedelta(days=30)

def parse_ts(value):
    if not value:
        return None
    text = str(value).replace("Z", "+00:00")
    try:
        dt = datetime.fromisoformat(text)
    except ValueError:
        return None
    if dt.tzinfo is None:
        dt = dt.replace(tzinfo=timezone.utc)
    return dt

def string_values(obj):
    if isinstance(obj, str):
        yield obj
    elif isinstance(obj, dict):
        for v in obj.values():
            yield from string_values(v)
    elif isinstance(obj, list):
        for v in obj:
            yield from string_values(v)

dispatch_hits = 0
for row in load_jsonl(dispatch_log) or []:
    dt = parse_ts(row.get("ts") or row.get("timestamp") or row.get("created_at"))
    if dt is not None and dt < since:
        continue
    haystack = "\n".join(string_values(row))
    if rel_path in haystack or abs_surface in haystack:
        dispatch_hits += 1

print(json.dumps({
    "invoke_count_30d": invoke_count,
    "dispatch_log_hits": dispatch_hits,
}, separators=(",", ":")))
PY
)"

invoke_count="$(jq -r '.invoke_count_30d' <<<"$evidence_json")"
dispatch_hits="$(jq -r '.dispatch_log_hits' <<<"$evidence_json")"

if [[ "$invoke_count" -gt 0 ]]; then
  payload="$(jq -nc --arg surface "$surface" --arg repo_root "$repo_root" --arg path "$rel_path" --argjson invoke "$invoke_count" --argjson hits "$dispatch_hits" '{surface:$surface,repo_root:$repo_root,path:$path,reachable:true,reason:"invoke_count_30d",invoke_count_30d:$invoke,dispatch_log_hits:$hits,inbound_caller_count:0,inbound_callers:[]}')"
  emit "$payload"
  exit 0
fi

if [[ "$dispatch_hits" -gt 0 ]]; then
  payload="$(jq -nc --arg surface "$surface" --arg repo_root "$repo_root" --arg path "$rel_path" --argjson invoke "$invoke_count" --argjson hits "$dispatch_hits" '{surface:$surface,repo_root:$repo_root,path:$path,reachable:true,reason:"dispatch_log_reference",invoke_count_30d:$invoke,dispatch_log_hits:$hits,inbound_caller_count:0,inbound_callers:[]}')"
  emit "$payload"
  exit 0
fi

mapfile -t callers < <(
  git -C "$repo_root" grep -F -l -- "$rel_path" -- . 2>/dev/null \
    | awk -v self="$rel_path" '$0 != self' \
    | head -20 || true
)

if [[ "${#callers[@]}" -gt 0 ]]; then
  callers_json="$(printf '%s\n' "${callers[@]}" | jq -R . | jq -s .)"
  payload="$(jq -nc --arg surface "$surface" --arg repo_root "$repo_root" --arg path "$rel_path" --argjson invoke "$invoke_count" --argjson hits "$dispatch_hits" --argjson callers "$callers_json" '{surface:$surface,repo_root:$repo_root,path:$path,reachable:true,reason:"tracked_inbound_reference",invoke_count_30d:$invoke,dispatch_log_hits:$hits,inbound_caller_count:($callers|length),inbound_callers:$callers}')"
  emit "$payload"
  exit 0
fi

payload="$(jq -nc --arg surface "$surface" --arg repo_root "$repo_root" --arg path "$rel_path" --argjson invoke "$invoke_count" --argjson hits "$dispatch_hits" '{surface:$surface,repo_root:$repo_root,path:$path,reachable:false,reason:"no_invoke_or_tracked_inbound_reference",invoke_count_30d:$invoke,dispatch_log_hits:$hits,inbound_caller_count:0,inbound_callers:[]}')"
emit "$payload"
exit 1
