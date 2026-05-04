#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd -P)"
MANIFEST="${JEFF_CORPUS_MANIFEST:-$ROOT/.flywheel/jeff-corpus/v1/manifest.json}"
PENDING="${JEFF_CORPUS_PENDING:-$ROOT/.flywheel/jeff-corpus/pending-reindex.jsonl}"
DELTA="${JEFF_CORPUS_DELTA:-$ROOT/.flywheel/jeff-corpus/v2/delta-index.jsonl}"
DRY_RUN=0
APPLY=0
JSON_OUT=0
NOW="${JEFF_CORPUS_NOW:-}"

usage() {
  printf '%s\n' \
    "Usage:" \
    "  jeff-corpus-delta-reindex.sh --dry-run|--apply [--json]" \
    "  jeff-corpus-delta-reindex.sh [--manifest PATH] [--pending PATH] [--delta PATH]" \
    "" \
    "Processes pending-reindex rows using git diff --name-only and records only changed file chunks."
}

while [ $# -gt 0 ]; do
  case "$1" in
    --help|-h) usage; exit 0 ;;
    --json) JSON_OUT=1; shift ;;
    --dry-run) DRY_RUN=1; shift ;;
    --apply) APPLY=1; shift ;;
    --manifest) [ $# -ge 2 ] || { printf 'ERROR: --manifest requires PATH\n' >&2; exit 2; }; MANIFEST="$2"; shift 2 ;;
    --pending) [ $# -ge 2 ] || { printf 'ERROR: --pending requires PATH\n' >&2; exit 2; }; PENDING="$2"; shift 2 ;;
    --delta) [ $# -ge 2 ] || { printf 'ERROR: --delta requires PATH\n' >&2; exit 2; }; DELTA="$2"; shift 2 ;;
    --now) [ $# -ge 2 ] || { printf 'ERROR: --now requires ISO timestamp\n' >&2; exit 2; }; NOW="$2"; shift 2 ;;
    *) printf 'ERROR: unknown argument: %s\n' "$1" >&2; exit 2 ;;
  esac
done

if [ "$DRY_RUN" -eq 0 ] && [ "$APPLY" -eq 0 ]; then
  printf 'ERROR: choose --dry-run or --apply\n' >&2
  exit 2
fi

python3 - "$MANIFEST" "$PENDING" "$DELTA" "$DRY_RUN" "$APPLY" "$NOW" "$JSON_OUT" <<'PY'
import hashlib
import json
import subprocess
import sys
import time
from pathlib import Path

manifest_path = Path(sys.argv[1])
pending_path = Path(sys.argv[2])
delta_path = Path(sys.argv[3])
dry_run = sys.argv[4] == "1"
apply = sys.argv[5] == "1"
now = sys.argv[6] or time.strftime("%Y-%m-%dT%H:%M:%SZ", time.gmtime())
json_out = sys.argv[7] == "1"

manifest = json.loads(manifest_path.read_text())
pending = [json.loads(line) for line in pending_path.read_text().splitlines() if line.strip()] if pending_path.exists() else []

def run(args, cwd):
    return subprocess.run(args, cwd=cwd, check=True, stdout=subprocess.PIPE, stderr=subprocess.PIPE, text=True).stdout

def changed_files(repo_path: Path, old: str, new: str):
    out = run(["git", "diff", "--name-only", old, new, "--"], repo_path)
    return sorted([line for line in out.splitlines() if line.strip()])

def hash_file(path: Path):
    h = hashlib.sha256()
    with path.open("rb") as fh:
        for chunk in iter(lambda: fh.read(1024 * 1024), b""):
            h.update(chunk)
    return h.hexdigest(), path.stat().st_size

existing = {
    (repo["repo"], item["path"], item["sha256"])
    for repo in manifest.get("repos", [])
    for item in repo.get("content_hash_set", [])
    if item.get("sha256")
}
manifest_by_repo = {repo["repo"]: repo for repo in manifest.get("repos", [])}
delta_rows = []
processed = []
warnings = []

for row in pending:
    repo_name = row["repo"]
    repo = manifest_by_repo.get(repo_name)
    if not repo:
        warnings.append({"repo": repo_name, "code": "repo_not_in_manifest"})
        continue
    repo_path = Path(row["path"])
    try:
        files = changed_files(repo_path, row["old_sha"], row["new_sha"])
    except Exception as exc:
        warnings.append({"repo": repo_name, "code": "git_diff_failed", "detail": str(exc)})
        continue
    new_chunks = []
    for rel in files:
        path = repo_path / rel
        if not path.is_file():
            continue
        sha, size = hash_file(path)
        if (repo_name, rel, sha) in existing:
            continue
        chunk = {
            "schema_version": "jeff-corpus-delta/v1",
            "indexed_at": now,
            "repo": repo_name,
            "path": rel,
            "old_sha": row["old_sha"],
            "new_sha": row["new_sha"],
            "content_sha256": sha,
            "bytes": size,
            "target_collection": "jeff-corpus-v2",
        }
        new_chunks.append(chunk)
        delta_rows.append(chunk)
    processed.append({"repo": repo_name, "changed_files": len(files), "new_chunks": len(new_chunks)})
    if apply:
        repo["git_sha"] = row["new_sha"]
        repo["last_indexed_at"] = now
        by_path = {item["path"]: item for item in repo.get("content_hash_set", [])}
        for rel in files:
            path = repo_path / rel
            if path.is_file():
                sha, size = hash_file(path)
                by_path[rel] = {"path": rel, "sha256": sha, "bytes": size}
            else:
                by_path.pop(rel, None)
        repo["content_hash_set"] = [by_path[k] for k in sorted(by_path)]

if apply:
    delta_path.parent.mkdir(parents=True, exist_ok=True)
    with delta_path.open("a") as fh:
        for row in delta_rows:
            fh.write(json.dumps(row, sort_keys=True, separators=(",", ":")) + "\n")
    tmp = manifest_path.with_suffix(manifest_path.suffix + ".tmp")
    tmp.write_text(json.dumps(manifest, indent=2, sort_keys=True) + "\n")
    tmp.replace(manifest_path)
    pending_path.write_text("")

summary = {
    "status": "pass",
    "mode": "dry_run" if dry_run else "apply",
    "pending_count": len(pending),
    "processed": processed,
    "new_chunks": len(delta_rows),
    "target_collection": "jeff-corpus-v2",
    "delta_path": str(delta_path),
    "manifest_updated": bool(apply),
    "full_reindex": False,
    "warnings": warnings,
}
print(json.dumps(summary, separators=(",", ":")) if json_out else f"new_chunks={len(delta_rows)} full_reindex=false")
PY
