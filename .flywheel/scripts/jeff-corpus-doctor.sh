#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd -P)"
MANIFEST="${JEFF_CORPUS_MANIFEST:-$ROOT/.flywheel/jeff-corpus/v1/manifest.json}"
JSON_OUT=1

usage() {
  printf '%s\n' \
    "Usage:" \
    "  jeff-corpus-doctor.sh [--json] [--manifest PATH]" \
    "  jeff-corpus-doctor.sh --help" \
    "" \
    "Reports jeff_corpus_indexed_count, jeff_corpus_v1_total_mb, and jeff_corpus_storage_health."
}

while [ $# -gt 0 ]; do
  case "$1" in
    --help|-h) usage; exit 0 ;;
    --json|--doctor|--health) JSON_OUT=1; shift ;;
    --manifest) [ $# -ge 2 ] || { printf 'ERROR: --manifest requires PATH\n' >&2; exit 2; }; MANIFEST="$2"; shift 2 ;;
    *) printf 'ERROR: unknown argument: %s\n' "$1" >&2; exit 2 ;;
  esac
done

python3 - "$MANIFEST" <<'PY'
import json
import sys
from pathlib import Path

manifest_path = Path(sys.argv[1])
if not manifest_path.exists():
    print(json.dumps({
        "schema_version": "jeff-corpus-doctor/v1",
        "status": "warn",
        "manifest_path": str(manifest_path),
        "repo_count": 0,
        "jeff_corpus_indexed_count": 0,
        "jeff_corpus_index_target": 177,
        "jeff_corpus_v1_total_mb": 0,
        "jeff_corpus_storage_health": "GREEN",
        "errors": [],
        "warnings": [{"code": "jeff_corpus_manifest_missing", "message": "manifest not found"}],
    }, separators=(",", ":")))
    raise SystemExit(0)

manifest = json.loads(manifest_path.read_text())
repo_count = int(manifest.get("repo_count") or len(manifest.get("repos", [])))
total_mb = float(manifest.get("total_repo_size_mb") or 0)
if total_mb >= 5000:
    health = "RED"
    status = "fail"
elif total_mb >= 1000:
    health = "YELLOW"
    status = "warn"
else:
    health = "GREEN"
    status = "pass"

errors = []
warnings = []
if health == "RED":
    errors.append({"code": "jeff_corpus_storage_red", "message": "Jeff corpus storage exceeds 5000 MB; block new ingestion until compaction runs", "total_mb": total_mb})
elif health == "YELLOW":
    warnings.append({"code": "jeff_corpus_storage_yellow", "message": "Jeff corpus storage exceeds 1000 MB; recommend compaction", "total_mb": total_mb})

print(json.dumps({
    "schema_version": "jeff-corpus-doctor/v1",
    "status": status,
    "manifest_path": str(manifest_path),
    "repo_count": repo_count,
    "jeff_corpus_indexed_count": repo_count,
    "jeff_corpus_index_target": 177,
    "jeff_corpus_v1_total_mb": total_mb,
    "jeff_corpus_storage_health": health,
    "thresholds_mb": {"green_lt": 1000, "yellow_lt": 5000, "red_gte": 5000},
    "errors": errors,
    "warnings": warnings,
}, separators=(",", ":")))
PY
