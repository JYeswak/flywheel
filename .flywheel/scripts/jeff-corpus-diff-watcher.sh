#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd -P)"
MANIFEST="${JEFF_CORPUS_MANIFEST:-$ROOT/.flywheel/jeff-corpus/v1/manifest.json}"
PENDING="${JEFF_CORPUS_PENDING:-$ROOT/.flywheel/jeff-corpus/pending-reindex.jsonl}"
REMOTE_HEADS=""
NOW="${JEFF_CORPUS_NOW:-}"
JSON_OUT=0

usage() {
  printf '%s\n' \
    "Usage:" \
    "  jeff-corpus-diff-watcher.sh [--json] [--manifest PATH] [--pending PATH]" \
    "  jeff-corpus-diff-watcher.sh --remote-heads PATH [--json]" \
    "" \
    "Recommended daily schedule: 03:00Z via launchd or fleet-cron." \
    "The script writes deterministic pending-reindex JSONL rows for SHA changes."
}

while [ $# -gt 0 ]; do
  case "$1" in
    --help|-h) usage; exit 0 ;;
    --json) JSON_OUT=1; shift ;;
    --manifest) [ $# -ge 2 ] || { printf 'ERROR: --manifest requires PATH\n' >&2; exit 2; }; MANIFEST="$2"; shift 2 ;;
    --pending) [ $# -ge 2 ] || { printf 'ERROR: --pending requires PATH\n' >&2; exit 2; }; PENDING="$2"; shift 2 ;;
    --remote-heads) [ $# -ge 2 ] || { printf 'ERROR: --remote-heads requires PATH\n' >&2; exit 2; }; REMOTE_HEADS="$2"; shift 2 ;;
    --now) [ $# -ge 2 ] || { printf 'ERROR: --now requires ISO timestamp\n' >&2; exit 2; }; NOW="$2"; shift 2 ;;
    *) printf 'ERROR: unknown argument: %s\n' "$1" >&2; exit 2 ;;
  esac
done

python3 - "$MANIFEST" "$PENDING" "$REMOTE_HEADS" "$NOW" "$JSON_OUT" <<'PY'
import json
import subprocess
import sys
import time
from pathlib import Path

manifest_path = Path(sys.argv[1])
pending_path = Path(sys.argv[2])
remote_heads_path = Path(sys.argv[3]) if sys.argv[3] else None
now = sys.argv[4] or time.strftime("%Y-%m-%dT%H:%M:%SZ", time.gmtime())
json_out = sys.argv[5] == "1"

manifest = json.loads(manifest_path.read_text())
remote_heads = {}
if remote_heads_path:
    loaded = json.loads(remote_heads_path.read_text())
    if isinstance(loaded, dict):
        remote_heads = loaded

def live_head(repo):
    if repo["repo"] in remote_heads:
        return remote_heads[repo["repo"]]
    if repo.get("upstream_url") in remote_heads:
        return remote_heads[repo["upstream_url"]]
    target = repo.get("upstream_url") or repo.get("path")
    if not target:
        return None
    try:
        out = subprocess.run(["git", "ls-remote", target, "HEAD"], check=True, stdout=subprocess.PIPE, stderr=subprocess.PIPE, text=True, timeout=45).stdout
        return out.split()[0] if out.split() else None
    except Exception:
        return None

rows = []
warnings = []
for repo in sorted(manifest.get("repos", []), key=lambda r: r.get("repo", "")):
    current = repo.get("git_sha")
    new = live_head(repo)
    if not new:
        warnings.append({"repo": repo.get("repo"), "code": "remote_head_unavailable"})
        continue
    if new != current:
        rows.append({
            "schema_version": "jeff-corpus-pending-reindex/v1",
            "queued_at": now,
            "repo": repo.get("repo"),
            "path": repo.get("path"),
            "upstream_url": repo.get("upstream_url"),
            "old_sha": current,
            "new_sha": new,
            "reason": "upstream_head_changed",
        })

pending_path.parent.mkdir(parents=True, exist_ok=True)
tmp = pending_path.with_suffix(pending_path.suffix + ".tmp")
tmp.write_text("".join(json.dumps(row, sort_keys=True, separators=(",", ":")) + "\n" for row in rows))
tmp.replace(pending_path)

summary = {
    "status": "pass",
    "manifest_path": str(manifest_path),
    "pending_path": str(pending_path),
    "checked": len(manifest.get("repos", [])),
    "changed": len(rows),
    "warnings": warnings,
    "recommended_schedule": "daily 03:00Z",
}
print(json.dumps(summary, separators=(",", ":")) if json_out else f"changed={len(rows)} pending={pending_path}")
PY

# Meta-Learning Cross-References (2026-05-19)
# Batch-16 comment backfill; citations are documentation-only and do not alter runtime behavior.
# Related: `/Users/josh/Developer/skillos/.flywheel/doctrine/meta-learnings/MP-09-info-source-watchtower.md`
# Related: `/Users/josh/Developer/skillos/.flywheel/doctrine/meta-learnings/MP-76-authority-ranked-retrieval-maintenance.md`
