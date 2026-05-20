#!/usr/bin/env python3
from __future__ import annotations

import argparse
import json
import os
import statistics
import subprocess
import sys
from datetime import datetime, timezone
from pathlib import Path
from typing import Any


VERSION = "jeff-corpus-storage-projection/1.0.0"


def now_iso() -> str:
    return datetime.now(timezone.utc).replace(microsecond=0).isoformat().replace("+00:00", "Z")


def read_jsonl(path: Path) -> list[dict[str, Any]]:
    if not path.exists():
        return []
    rows: list[dict[str, Any]] = []
    for line in path.read_text(errors="replace").splitlines():
        if not line.strip():
            continue
        try:
            row = json.loads(line)
        except json.JSONDecodeError:
            continue
        if isinstance(row, dict):
            rows.append(row)
    return rows


def run_json(cmd: list[str], cwd: Path) -> dict[str, Any] | None:
    try:
        proc = subprocess.run(cmd, cwd=str(cwd), text=True, stdout=subprocess.PIPE, stderr=subprocess.DEVNULL, timeout=30, check=False)
        payload = json.loads(proc.stdout)
    except Exception:
        return None
    return payload if isinstance(payload, dict) else None


def run_text(cmd: list[str], cwd: Path) -> str:
    try:
        proc = subprocess.run(cmd, cwd=str(cwd), text=True, stdout=subprocess.PIPE, stderr=subprocess.DEVNULL, timeout=20, check=False)
    except Exception:
        return ""
    return proc.stdout.strip()


def storage_probe(repo: Path, fixture: Path | None) -> dict[str, Any]:
    if fixture:
        try:
            payload = json.loads(fixture.read_text())
            return payload if isinstance(payload, dict) else {}
        except Exception:
            return {}
    probe = repo / ".flywheel/scripts/storage-probe.sh"
    if not probe.exists():
        probe = Path.home() / "Developer/flywheel/.flywheel/scripts/storage-probe.sh"
    return run_json([str(probe), "--repo", str(repo), "--json"], repo) or {}


def qdrant_storage_mb(container: str, fixture_mb: float | None, repo: Path) -> float | None:
    if fixture_mb is not None:
        return fixture_mb
    raw = run_text(["docker", "exec", container, "du", "-sm", "/qdrant/storage"], repo)
    if not raw:
        return None
    try:
        return float(raw.split()[0])
    except Exception:
        return None


def collection_size_mb(container: str, collection: str, fixture: dict[str, Any], repo: Path) -> float | None:
    if collection in fixture:
        try:
            return float(fixture[collection])
        except Exception:
            return None
    raw = run_text(["docker", "exec", container, "du", "-sm", f"/qdrant/storage/collections/{collection}"], repo)
    if not raw:
        return None
    try:
        return float(raw.split()[0])
    except Exception:
        return None


def choose_sample(rows: list[dict[str, Any]], n: int) -> list[dict[str, Any]]:
    with_collections = [r for r in rows if r.get("qdrant_collection")]
    if len(with_collections) <= n:
        return with_collections
    ranked = sorted(with_collections, key=lambda r: float(r.get("qdrant_points") or r.get("indexed_chunks") or 0))
    indexes = sorted({round(i * (len(ranked) - 1) / max(n - 1, 1)) for i in range(n)})
    return [ranked[i] for i in indexes]


def recommendation(actual_remaining: int, projected_actual_gb: float, free_gb: float, free_pct: float, required_headroom_gb: float) -> str:
    if actual_remaining == 0:
        return "full_already_indexed_increase_headroom_first" if free_pct < 10 or required_headroom_gb < 2 else "full_already_indexed_monitor"
    if free_pct < 10:
        return "increase_headroom_first"
    if projected_actual_gb > required_headroom_gb:
        return "increase_headroom_first"
    return "full"


def project(args: argparse.Namespace) -> dict[str, Any]:
    repo = Path(args.repo).expanduser().resolve()
    repos_path = Path(args.repos_jsonl).expanduser()
    rows = read_jsonl(repos_path)
    verified = [r for r in rows if r.get("index_status") == "verified_indexed"]
    remaining = [r for r in rows if r.get("index_status") != "verified_indexed"]
    storage = storage_probe(repo, Path(args.storage_fixture).expanduser() if args.storage_fixture else None)
    qdrant_fixture = {}
    if args.collection_size_fixture:
        qdrant_fixture = json.loads(Path(args.collection_size_fixture).expanduser().read_text())
    qdrant_total_mb = qdrant_storage_mb(args.qdrant_container, args.qdrant_storage_mb, repo)
    sample_rows = choose_sample(verified, args.sample_size)
    samples: list[dict[str, Any]] = []
    for row in sample_rows:
        collection = str(row.get("qdrant_collection"))
        size_mb = collection_size_mb(args.qdrant_container, collection, qdrant_fixture, repo)
        samples.append({
            "name": row.get("name"),
            "path": row.get("path"),
            "collection": collection,
            "points": row.get("qdrant_points") or row.get("indexed_chunks") or 0,
            "collection_size_mb": size_mb,
        })
    measured = [float(s["collection_size_mb"]) for s in samples if s.get("collection_size_mb") is not None]
    avg_sample_mb = statistics.mean(measured) if measured else None
    median_sample_mb = statistics.median(measured) if measured else None
    avg_total_mb = (qdrant_total_mb / len(verified)) if qdrant_total_mb is not None and verified else avg_sample_mb
    per_repo_mb = avg_total_mb or avg_sample_mb or 0
    actual_remaining = len(remaining)
    scenario_remaining = int(args.scenario_remaining)
    projected_actual_gb = round((per_repo_mb * actual_remaining) / 1024, 2)
    projected_scenario_gb = round((per_repo_mb * scenario_remaining) / 1024, 2)
    free_gb = float(storage.get("disk_free_gb") or 0)
    free_pct = float(storage.get("disk_free_pct") or 0)
    total_gb = float(storage.get("disk_total_gb") or 0)
    reserve_pct = float(args.reserve_free_pct)
    required_reserve_gb = round(total_gb * reserve_pct / 100, 2) if total_gb else 0
    headroom_above_reserve_gb = round(free_gb - required_reserve_gb, 2)
    rec = recommendation(actual_remaining, projected_actual_gb, free_gb, free_pct, headroom_above_reserve_gb)
    status = "fail" if rec == "increase_headroom_first" or free_pct < reserve_pct else "pass"
    warnings = []
    if actual_remaining == 0:
        warnings.append({"code": "jeff_corpus_already_fully_indexed", "message": "repos.jsonl reports no remaining unverified repos"})
    if free_pct < reserve_pct:
        warnings.append({"code": "storage_below_reserve", "message": "disk free percent is below reserve threshold"})
    result = {
        "schema_version": "jeff-corpus-storage-projection/v1",
        "version": VERSION,
        "status": status,
        "ts": now_iso(),
        "repos_jsonl": str(repos_path),
        "storage": storage,
        "qdrant_container": args.qdrant_container,
        "qdrant_storage_mb": qdrant_total_mb,
        "verified_indexed_count": len(verified),
        "index_target": len(rows),
        "remaining_actual_count": actual_remaining,
        "scenario_remaining_count": scenario_remaining,
        "sample_size": len(samples),
        "sample_collections": samples,
        "average_sample_collection_mb": avg_sample_mb,
        "median_sample_collection_mb": median_sample_mb,
        "average_total_qdrant_mb_per_verified_repo": avg_total_mb,
        "per_repo_projection_mb": per_repo_mb,
        "projected_actual_remaining_gb": projected_actual_gb,
        "projected_scenario_remaining_gb": projected_scenario_gb,
        "disk_free_gb": free_gb,
        "disk_free_pct": free_pct,
        "reserve_free_pct": reserve_pct,
        "headroom_above_reserve_gb": headroom_above_reserve_gb,
        "recommendation": rec,
        "warnings": warnings,
        "errors": [],
    }
    out_path = Path(args.out).expanduser() if args.out else None
    if out_path:
        out_path.parent.mkdir(parents=True, exist_ok=True)
        out_path.write_text(json.dumps(result, indent=2, sort_keys=True) + "\n")
        result["out_path"] = str(out_path)
    return result


def main(argv: list[str]) -> int:
    parser = argparse.ArgumentParser(description="Project storage impact for remaining Jeff corpus Socraticode indexes.")
    parser.add_argument("--repo", default=os.getcwd())
    parser.add_argument("--repos-jsonl", default=os.environ.get("JEFF_INTEL_REPOS_JSONL", str(Path.home() / ".local/state/jeff-intel/repos.jsonl")))
    parser.add_argument("--storage-fixture", default="")
    parser.add_argument("--collection-size-fixture", default="")
    parser.add_argument("--qdrant-container", default=os.environ.get("JEFF_CORPUS_QDRANT_CONTAINER", "socraticode-qdrant"))
    parser.add_argument("--qdrant-storage-mb", type=float)
    parser.add_argument("--sample-size", type=int, default=10)
    parser.add_argument("--scenario-remaining", type=int, default=92)
    parser.add_argument("--reserve-free-pct", type=float, default=10)
    parser.add_argument("--out", default=os.environ.get("JEFF_CORPUS_STORAGE_PROJECTION_OUT", str(Path.home() / ".local/state/jeff-intel/storage-projection.json")))
    parser.add_argument("--json", action="store_true")
    parser.add_argument("--info", action="store_true")
    parser.add_argument("--examples", action="store_true")
    parser.add_argument("--version", action="store_true")
    args = parser.parse_args(argv)

    if args.version:
        print(VERSION)
        return 0
    if args.info:
        print(json.dumps({"version": VERSION, "script": __file__, "mutates": ["--out path only"]}, separators=(",", ":")))
        return 0
    if args.examples:
        print(".flywheel/scripts/jeff-corpus-storage-projection.sh --json")
        print(".flywheel/scripts/jeff-corpus-storage-projection.sh --scenario-remaining 92 --json")
        return 0

    result = project(args)
    print(json.dumps(result, separators=(",", ":")) if args.json else json.dumps(result, indent=2, sort_keys=True))
    return 0 if result["status"] in {"pass", "warn"} else 1


if __name__ == "__main__":
    raise SystemExit(main(sys.argv[1:]))

# Meta-Learning Cross-References (2026-05-19)
# Batch-16 comment backfill; citations are documentation-only and do not alter runtime behavior.
# Related: `/Users/josh/Developer/skillos/.flywheel/doctrine/meta-learnings/MP-09-info-source-watchtower.md`
# Related: `/Users/josh/Developer/skillos/.flywheel/doctrine/meta-learnings/MP-76-authority-ranked-retrieval-maintenance.md`
