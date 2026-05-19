#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd -P)"
MANIFEST="${JEFF_CORPUS_MANIFEST:-$ROOT/.flywheel/jeff-corpus/v1/manifest.json}"
STORAGE_ROOT="${JEFF_CORPUS_STORAGE_ROOT:-}"
JSON_OUT=1

usage() {
  printf '%s\n' \
    "Usage:" \
    "  jeff-corpus-doctor.sh [--json] [--manifest PATH] [--storage-root PATH]" \
    "  jeff-corpus-doctor.sh --help" \
    "" \
    "Reports Jeff corpus source size, local storage use, and storage health."
}

while [ $# -gt 0 ]; do
  case "$1" in
    --help|-h) usage; exit 0 ;;
    --json|--doctor|--health) JSON_OUT=1; shift ;;
    --manifest) [ $# -ge 2 ] || { printf 'ERROR: --manifest requires PATH\n' >&2; exit 2; }; MANIFEST="$2"; shift 2 ;;
    --storage-root) [ $# -ge 2 ] || { printf 'ERROR: --storage-root requires PATH\n' >&2; exit 2; }; STORAGE_ROOT="$2"; shift 2 ;;
    *) printf 'ERROR: unknown argument: %s\n' "$1" >&2; exit 2 ;;
  esac
done

python3 - "$MANIFEST" "$STORAGE_ROOT" <<'PY'
import json
import os
import subprocess
import sys
from pathlib import Path

manifest_path = Path(sys.argv[1])
storage_root_arg = sys.argv[2]
if storage_root_arg:
    storage_root = Path(storage_root_arg)
elif manifest_path.name == "manifest.json" and manifest_path.parent.name == "v1":
    storage_root = manifest_path.parent.parent
else:
    storage_root = manifest_path.parent

def local_storage_mb(path: Path) -> float:
    fixture = os.environ.get("JEFF_CORPUS_LOCAL_STORAGE_MB_FIXTURE")
    if fixture is not None:
        return float(fixture)
    if not path.exists():
        return 0.0
    try:
        proc = subprocess.run(
            ["du", "-sk", str(path)],
            check=True,
            stdout=subprocess.PIPE,
            stderr=subprocess.DEVNULL,
            text=True,
        )
        kb = int(proc.stdout.split()[0])
        return round(kb / 1024, 1)
    except Exception:
        total = 0
        for root, _, files in os.walk(path):
            for name in files:
                try:
                    total += (Path(root) / name).stat().st_size
                except OSError:
                    pass
        return round(total / 1024 / 1024, 1)

if not manifest_path.exists():
    print(json.dumps({
        "schema_version": "jeff-corpus-doctor/v1",
        "status": "warn",
        "manifest_path": str(manifest_path),
        "storage_root": str(storage_root),
        "repo_count": 0,
        "jeff_corpus_indexed_count": 0,
        "jeff_corpus_index_target": 177,
        "jeff_corpus_v1_total_mb": 0,
        "jeff_corpus_source_total_mb": 0,
        "jeff_corpus_local_storage_mb": local_storage_mb(storage_root),
        "jeff_corpus_storage_health": "GREEN",
        "errors": [],
        "warnings": [{"code": "jeff_corpus_manifest_missing", "message": "manifest not found"}],
    }, separators=(",", ":")))
    raise SystemExit(0)

manifest = json.loads(manifest_path.read_text())
repo_count = int(manifest.get("repo_count") or len(manifest.get("repos", [])))
source_total_mb = float(manifest.get("total_repo_size_mb") or 0)
storage_mb = local_storage_mb(storage_root)
if storage_mb >= 5000:
    health = "RED"
    status = "fail"
elif storage_mb >= 1000:
    health = "YELLOW"
    status = "warn"
else:
    health = "GREEN"
    status = "pass"

errors = []
warnings = []
if health == "RED":
    errors.append({"code": "jeff_corpus_storage_red", "message": "Jeff corpus local storage exceeds 5000 MB; block new ingestion until compaction runs", "local_storage_mb": storage_mb})
elif health == "YELLOW":
    warnings.append({"code": "jeff_corpus_storage_yellow", "message": "Jeff corpus local storage exceeds 1000 MB; recommend compaction", "local_storage_mb": storage_mb})

print(json.dumps({
    "schema_version": "jeff-corpus-doctor/v1",
    "status": status,
    "manifest_path": str(manifest_path),
    "storage_root": str(storage_root),
    "repo_count": repo_count,
    "jeff_corpus_indexed_count": repo_count,
    "jeff_corpus_index_target": 177,
    "jeff_corpus_v1_total_mb": source_total_mb,
    "jeff_corpus_source_total_mb": source_total_mb,
    "jeff_corpus_local_storage_mb": storage_mb,
    "jeff_corpus_storage_health": health,
    "thresholds_mb": {"green_lt": 1000, "yellow_lt": 5000, "red_gte": 5000},
    "errors": errors,
    "warnings": warnings,
}, separators=(",", ":")))
PY

# Meta-Learning Cross-References (2026-05-19)
# Batch-16 comment backfill; citations are documentation-only and do not alter runtime behavior.
# Related: `/Users/josh/Developer/skillos/.flywheel/doctrine/meta-learnings/MP-02-conformance-fixtures.md`
# Related: `/Users/josh/Developer/skillos/.flywheel/doctrine/meta-learnings/MP-68-schema-executable-validator-pair.md`
