#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd -P)"
MANIFEST="${JEFF_CORPUS_MANIFEST:-$ROOT/.flywheel/jeff-corpus/v1/manifest.json}"
DELTA="${JEFF_CORPUS_DELTA:-$ROOT/.flywheel/jeff-corpus/v2/delta-index.jsonl}"
OUT="${JEFF_CORPUS_COMPACT_OUT:-$ROOT/.flywheel/jeff-corpus/v3/manifest.json}"
RECEIPT_DIR="${JEFF_CORPUS_COMPACT_RECEIPTS:-$ROOT/.flywheel/jeff-corpus/compaction-receipts}"
IDEMPOTENCY_KEY=""
QDRANT_URL="${JEFF_CORPUS_QDRANT_URL:-}"
DRY_RUN=0
APPLY=0
JSON_OUT=0
NOW="${JEFF_CORPUS_NOW:-}"

usage() {
  printf '%s\n' \
    "Usage:" \
    "  jeff-corpus-compact.sh --dry-run|--apply [--idempotency-key KEY] [--json]" \
    "  jeff-corpus-compact.sh [--manifest PATH] [--delta PATH] [--out PATH] [--receipt-dir PATH] [--qdrant-url URL]" \
    "" \
    "Recommended weekly schedule: Sunday 04:00Z."
}

while [ $# -gt 0 ]; do
  case "$1" in
    --help|-h) usage; exit 0 ;;
    --json) JSON_OUT=1; shift ;;
    --dry-run) DRY_RUN=1; shift ;;
    --apply) APPLY=1; shift ;;
    --manifest) [ $# -ge 2 ] || { printf 'ERROR: --manifest requires PATH\n' >&2; exit 2; }; MANIFEST="$2"; shift 2 ;;
    --delta) [ $# -ge 2 ] || { printf 'ERROR: --delta requires PATH\n' >&2; exit 2; }; DELTA="$2"; shift 2 ;;
    --out) [ $# -ge 2 ] || { printf 'ERROR: --out requires PATH\n' >&2; exit 2; }; OUT="$2"; shift 2 ;;
    --receipt-dir) [ $# -ge 2 ] || { printf 'ERROR: --receipt-dir requires PATH\n' >&2; exit 2; }; RECEIPT_DIR="$2"; shift 2 ;;
    --idempotency-key) [ $# -ge 2 ] || { printf 'ERROR: --idempotency-key requires KEY\n' >&2; exit 2; }; IDEMPOTENCY_KEY="$2"; shift 2 ;;
    --qdrant-url) [ $# -ge 2 ] || { printf 'ERROR: --qdrant-url requires URL\n' >&2; exit 2; }; QDRANT_URL="$2"; shift 2 ;;
    --now) [ $# -ge 2 ] || { printf 'ERROR: --now requires ISO timestamp\n' >&2; exit 2; }; NOW="$2"; shift 2 ;;
    *) printf 'ERROR: unknown argument: %s\n' "$1" >&2; exit 2 ;;
  esac
done

if [ "$DRY_RUN" -eq 0 ] && [ "$APPLY" -eq 0 ]; then
  printf 'ERROR: choose --dry-run or --apply\n' >&2
  exit 2
fi

python3 - "$MANIFEST" "$DELTA" "$OUT" "$DRY_RUN" "$APPLY" "$NOW" "$JSON_OUT" "$RECEIPT_DIR" "$IDEMPOTENCY_KEY" "$QDRANT_URL" <<'PY'
import gzip
import json
import os
import re
import sys
import time
import urllib.error
import urllib.parse
import urllib.request
from pathlib import Path

manifest_path = Path(sys.argv[1])
delta_path = Path(sys.argv[2])
out_path = Path(sys.argv[3])
dry_run = sys.argv[4] == "1"
apply = sys.argv[5] == "1"
now = sys.argv[6] or time.strftime("%Y-%m-%dT%H:%M:%SZ", time.gmtime())
json_out = sys.argv[7] == "1"
receipt_dir = Path(sys.argv[8])
idempotency_key = sys.argv[9]
qdrant_url_arg = sys.argv[10].rstrip("/")

safe_ts = re.sub(r"[^0-9A-Za-z]+", "", now)
safe_key = re.sub(r"[^0-9A-Za-z_.-]+", "_", idempotency_key)
receipt_path = receipt_dir / f"{safe_key}.json" if idempotency_key else None
if apply and receipt_path and receipt_path.exists():
    receipt = json.loads(receipt_path.read_text())
    receipt["idempotent_replay"] = True
    print(json.dumps(receipt, separators=(",", ":")) if json_out else f"idempotent_replay=true receipt={receipt_path}")
    raise SystemExit(0)

manifest = json.loads(manifest_path.read_text())
delta_rows = [json.loads(line) for line in delta_path.read_text().splitlines() if line.strip()] if delta_path.exists() else []
by_repo = {repo["repo"]: repo for repo in manifest.get("repos", [])}
qdrant_url = qdrant_url_arg or manifest.get("qdrant_url") or "http://localhost:16333"
qdrant_fixture_path = os.environ.get("JEFF_CORPUS_QDRANT_FIXTURE")
qdrant_fixture = None
if qdrant_fixture_path:
    qdrant_fixture = json.loads(Path(qdrant_fixture_path).read_text())

superseded = 0
qdrant_ops = []
refused_collections = []

def collection_count(collection):
    if qdrant_fixture is not None:
        return int(qdrant_fixture.get("collections", {}).get(collection, {}).get("points_count", 0))
    url = f"{qdrant_url}/collections/{urllib.parse.quote(collection, safe='')}"
    try:
        with urllib.request.urlopen(url, timeout=10) as response:
            payload = json.loads(response.read().decode())
        result = payload.get("result") or {}
        return int(result.get("points_count") or result.get("indexed_vectors_count") or 0)
    except (OSError, urllib.error.URLError, json.JSONDecodeError, ValueError) as exc:
        raise RuntimeError(f"qdrant count failed for {collection}: {exc}") from exc

def delete_superseded_point(collection, relative_path, old_sha):
    old_hash = (old_sha or "")[:16]
    if not old_hash:
        return 0
    if qdrant_fixture is not None:
        coll = qdrant_fixture.setdefault("collections", {}).setdefault(collection, {})
        deleted = int(coll.get("delete_matches", 0))
        coll["points_count"] = max(0, int(coll.get("points_count", 0)) - deleted)
        coll["delete_matches"] = 0
        return deleted
    body = {
        "filter": {
            "must": [
                {"key": "relativePath", "match": {"value": relative_path}},
                {"key": "contentHash", "match": {"value": old_hash}},
            ]
        }
    }
    data = json.dumps(body).encode()
    url = f"{qdrant_url}/collections/{urllib.parse.quote(collection, safe='')}/points/delete?wait=true"
    request = urllib.request.Request(url, data=data, headers={"Content-Type": "application/json"}, method="POST")
    try:
        with urllib.request.urlopen(request, timeout=30) as response:
            response.read()
        return -1
    except (OSError, urllib.error.URLError) as exc:
        raise RuntimeError(f"qdrant delete failed for {collection}:{relative_path}: {exc}") from exc

for row in delta_rows:
    repo = by_repo.get(row["repo"])
    if not repo:
        continue
    by_path = {item["path"]: item for item in repo.get("content_hash_set", [])}
    old_item = by_path.get(row["path"])
    if row["path"] in by_path:
        superseded += 1
        collection = repo.get("qdrant_collection")
        target = row.get("target_collection") or collection
        if target and target.startswith("codebase_") and target != collection:
            refused_collections.append({"repo": row["repo"], "path": row["path"], "target_collection": target, "allowed_collection": collection})
        if collection:
            op = {
                "repo": row["repo"],
                "path": row["path"],
                "collection": collection,
                "old_content_hash": (old_item or {}).get("sha256", "")[:16],
                "delete_issued": False,
                "points_before": None,
                "points_after": None,
                "points_deleted": 0,
            }
            if apply:
                op["points_before"] = collection_count(collection)
                deleted = delete_superseded_point(collection, row["path"], (old_item or {}).get("sha256"))
                op["delete_issued"] = True
                op["points_after"] = collection_count(collection)
                op["points_deleted"] = deleted if deleted >= 0 else max(0, op["points_before"] - op["points_after"])
            qdrant_ops.append(op)
    by_path[row["path"]] = {"path": row["path"], "sha256": row["content_sha256"], "bytes": row["bytes"]}
    repo["content_hash_set"] = [by_path[k] for k in sorted(by_path)]
    repo["git_sha"] = row.get("new_sha") or repo.get("git_sha")
    repo["last_indexed_at"] = row.get("indexed_at") or now
    repo["chunk_count"] = int(repo.get("chunk_count") or 0) + 1

raw_total_bytes = int(manifest.get("raw_total_repo_size_bytes") or manifest.get("total_repo_size_bytes") or 0)
compacted_total_bytes = 0
for repo in manifest.get("repos", []):
    raw_repo_bytes = int(repo.get("raw_repo_size_bytes") or repo.get("repo_size_bytes") or 0)
    repo["raw_repo_size_bytes"] = raw_repo_bytes
    compacted_repo_bytes = sum(int(item.get("bytes") or 0) for item in repo.get("content_hash_set", []))
    repo["repo_size_bytes"] = compacted_repo_bytes
    repo["compacted_content_bytes"] = compacted_repo_bytes
    compacted_total_bytes += compacted_repo_bytes

manifest["schema_version"] = "jeff-corpus-manifest/v1"
manifest["baseline"] = "jeff-corpus-v3"
manifest["compacted_at"] = now
manifest["delta_rows_merged"] = len(delta_rows)
manifest["superseded_chunks_dropped"] = superseded
manifest["raw_total_repo_size_bytes"] = raw_total_bytes
manifest["raw_total_repo_size_mb"] = round(raw_total_bytes / 1024 / 1024, 1) if raw_total_bytes else 0
manifest["total_repo_size_bytes"] = compacted_total_bytes
manifest["total_repo_size_mb"] = round(compacted_total_bytes / 1024 / 1024, 1)
manifest["compaction_semantics"] = {
    "storage_metric": "sum(content_hash_set[].bytes)",
    "raw_repo_size_preserved_as": "raw_repo_size_bytes",
    "qdrant_cleanup": "delete superseded old relativePath/contentHash points in each repo manifest collection",
}
manifest["qdrant_cleanup"] = {
    "qdrant_url": qdrant_url,
    "superseded_rows": len(qdrant_ops),
    "points_deleted": sum(int(op.get("points_deleted") or 0) for op in qdrant_ops),
    "refused_collections": refused_collections,
}

archive_root = manifest_path.parent.parent if manifest_path.parent.name == "v1" else manifest_path.parent
archive_manifest_path = archive_root / f"v1.archived-{safe_ts}.json.gz"
archive_delta_path = archive_root / f"v2.archived-{safe_ts}.jsonl.gz"
if apply:
    archive_root.mkdir(parents=True, exist_ok=True)
    with gzip.open(archive_manifest_path, "wt") as fh:
        json.dump(json.loads(manifest_path.read_text()), fh, sort_keys=True)
    if delta_path.exists():
        with gzip.open(archive_delta_path, "wt") as fh:
            fh.write(delta_path.read_text())
    for target in {out_path, manifest_path}:
        target.parent.mkdir(parents=True, exist_ok=True)
        tmp = target.with_suffix(target.suffix + ".tmp")
        tmp.write_text(json.dumps(manifest, indent=2, sort_keys=True) + "\n")
        tmp.replace(target)
    if delta_path.exists():
        delta_path.write_text("")

summary = {
    "status": "pass",
    "mode": "dry_run" if dry_run else "apply",
    "source_manifest": str(manifest_path),
    "delta_path": str(delta_path),
    "output_manifest": str(out_path),
    "delta_rows_merged": len(delta_rows),
    "superseded_chunks_dropped": superseded,
    "qdrant_deletes_attempted": len([op for op in qdrant_ops if op.get("delete_issued")]),
    "qdrant_points_deleted": sum(int(op.get("points_deleted") or 0) for op in qdrant_ops),
    "qdrant_ops": qdrant_ops,
    "qdrant_refused_collections": refused_collections,
    "pre_total_mb": round(raw_total_bytes / 1024 / 1024, 1) if raw_total_bytes else 0,
    "post_total_mb": manifest["total_repo_size_mb"],
    "archive_manifest_path": str(archive_manifest_path) if apply else None,
    "archive_delta_path": str(archive_delta_path) if apply and delta_path.exists() else None,
    "retired_to_cold_storage": bool(apply),
    "promoted_to_doctor_baseline": bool(apply),
    "idempotency_key": idempotency_key or None,
    "receipt_path": str(receipt_path) if receipt_path else None,
    "idempotent_replay": False,
    "recommended_schedule": "Sunday 04:00Z",
}
if apply and receipt_path:
    receipt_dir.mkdir(parents=True, exist_ok=True)
    receipt_path.write_text(json.dumps(summary, indent=2, sort_keys=True) + "\n")
print(json.dumps(summary, separators=(",", ":")) if json_out else f"merged={len(delta_rows)} superseded={superseded}")
PY
