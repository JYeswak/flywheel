#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd -P)"
REPOS_JSONL="${JEFF_CORPUS_REPOS_JSONL:-$HOME/.local/state/jeff-intel/repos.jsonl}"
MANIFEST="${JEFF_CORPUS_MANIFEST:-$ROOT/.flywheel/jeff-corpus/v1/manifest.json}"
QDRANT_URL="${JEFF_CORPUS_QDRANT_URL:-http://localhost:16333}"
JSON_OUT=0

usage() {
  printf '%s\n' \
    "Usage:" \
    "  jeff-corpus-freeze-baseline.sh [--json] [--manifest PATH] [--repos-jsonl PATH]" \
    "  jeff-corpus-freeze-baseline.sh --help" \
    "" \
    "Writes a frozen jeff-corpus/v1 manifest from verified repos.jsonl rows."
}

while [ $# -gt 0 ]; do
  case "$1" in
    --help|-h) usage; exit 0 ;;
    --json) JSON_OUT=1; shift ;;
    --manifest) [ $# -ge 2 ] || { printf 'ERROR: --manifest requires PATH\n' >&2; exit 2; }; MANIFEST="$2"; shift 2 ;;
    --repos-jsonl) [ $# -ge 2 ] || { printf 'ERROR: --repos-jsonl requires PATH\n' >&2; exit 2; }; REPOS_JSONL="$2"; shift 2 ;;
    --qdrant-url) [ $# -ge 2 ] || { printf 'ERROR: --qdrant-url requires URL\n' >&2; exit 2; }; QDRANT_URL="$2"; shift 2 ;;
    *) printf 'ERROR: unknown argument: %s\n' "$1" >&2; exit 2 ;;
  esac
done

python3 - "$ROOT" "$REPOS_JSONL" "$MANIFEST" "$QDRANT_URL" "$JSON_OUT" <<'PY'
import hashlib
import json
import os
import subprocess
import sys
import time
from pathlib import Path
from urllib.request import urlopen

root = Path(sys.argv[1])
repos_jsonl = Path(sys.argv[2]).expanduser()
manifest_path = Path(sys.argv[3])
qdrant_url = sys.argv[4].rstrip("/")
json_out = sys.argv[5] == "1"

def now_iso():
    return time.strftime("%Y-%m-%dT%H:%M:%SZ", time.gmtime())

def run(args, cwd=None, text=True):
    return subprocess.run(args, cwd=cwd, check=True, stdout=subprocess.PIPE, stderr=subprocess.PIPE, text=text).stdout

def git_or_empty(args, cwd):
    try:
        return run(["git", *args], cwd=cwd).strip()
    except Exception:
        return ""

def du_bytes(path: Path) -> int:
    try:
        out = run(["du", "-sk", str(path)])
        return int(out.split()[0]) * 1024
    except Exception:
        total = 0
        for p in path.rglob("*"):
            try:
                if p.is_file():
                    total += p.stat().st_size
            except OSError:
                pass
        return total

def collection_points(name: str):
    if not name:
        return None
    try:
        with urlopen(f"{qdrant_url}/collections/{name}", timeout=10) as resp:
            data = json.load(resp)
        return int(data.get("result", {}).get("points_count") or 0)
    except Exception:
        return None

def file_hash_set(repo_path: Path):
    try:
        raw = subprocess.run(
            ["git", "ls-files", "-z"],
            cwd=repo_path,
            check=True,
            stdout=subprocess.PIPE,
            stderr=subprocess.PIPE,
        ).stdout
    except Exception:
        raw = b""
    items = []
    for rel_b in raw.split(b"\0"):
        if not rel_b:
            continue
        rel = rel_b.decode("utf-8", "surrogateescape")
        path = repo_path / rel
        if not path.is_file():
            continue
        h = hashlib.sha256()
        try:
            with path.open("rb") as fh:
                for chunk in iter(lambda: fh.read(1024 * 1024), b""):
                    h.update(chunk)
            items.append({"path": rel, "sha256": h.hexdigest(), "bytes": path.stat().st_size})
        except OSError:
            items.append({"path": rel, "sha256": None, "bytes": None, "unreadable": True})
    return sorted(items, key=lambda row: row["path"])

if not repos_jsonl.exists():
    raise SystemExit(f"repos jsonl missing: {repos_jsonl}")

repos = []
for line in repos_jsonl.read_text().splitlines():
    if not line.strip():
        continue
    row = json.loads(line)
    if row.get("index_status") == "verified_indexed":
        repos.append(row)

entries = []
errors = []
for row in sorted(repos, key=lambda r: r.get("name", "")):
    repo_path = Path(row.get("path", ""))
    name = row.get("name") or repo_path.name
    if not repo_path.exists():
        errors.append({"repo": name, "code": "repo_path_missing", "path": str(repo_path)})
        continue
    git_sha = git_or_empty(["rev-parse", "HEAD"], repo_path) or row.get("head_sha") or ""
    upstream_url = git_or_empty(["config", "--get", "remote.origin.url"], repo_path)
    collection = row.get("qdrant_collection") or ""
    qdrant_points = collection_points(collection)
    chunk_count = int(qdrant_points if qdrant_points is not None else (row.get("qdrant_points") or row.get("indexed_chunks") or 0))
    hashes = file_hash_set(repo_path)
    if not hashes:
        errors.append({"repo": name, "code": "content_hash_set_empty", "path": str(repo_path)})
    entries.append({
        "repo": name,
        "path": str(repo_path),
        "upstream_url": upstream_url,
        "git_sha": git_sha,
        "last_indexed_at": row.get("index_verified_at") or row.get("indexed_at") or now_iso(),
        "chunk_count": chunk_count,
        "repo_size_bytes": du_bytes(repo_path),
        "content_hash_set": hashes,
        "qdrant_collection": collection,
        "qdrant_points": qdrant_points,
    })

total_bytes = sum(int(e["repo_size_bytes"] or 0) for e in entries)
manifest = {
    "schema_version": "jeff-corpus-manifest/v1",
    "generated_at": now_iso(),
    "corpus": "jeff-corpus",
    "baseline": "jeff-corpus-v1",
    "qdrant_url": qdrant_url,
    "source_repos_jsonl": str(repos_jsonl),
    "repo_count": len(entries),
    "total_repo_size_bytes": total_bytes,
    "total_repo_size_mb": round(total_bytes / 1024 / 1024, 2),
    "errors": errors,
    "repos": entries,
}

manifest_path.parent.mkdir(parents=True, exist_ok=True)
tmp = manifest_path.with_suffix(manifest_path.suffix + ".tmp")
tmp.write_text(json.dumps(manifest, indent=2, sort_keys=True) + "\n")
tmp.replace(manifest_path)

summary = {
    "status": "pass" if len(errors) == 0 else "warn",
    "manifest_path": str(manifest_path),
    "repo_count": len(entries),
    "total_repo_size_mb": manifest["total_repo_size_mb"],
    "errors_count": len(errors),
}
print(json.dumps(summary, separators=(",", ":")) if json_out else f"manifest={manifest_path} repo_count={len(entries)} errors={len(errors)}")
PY
