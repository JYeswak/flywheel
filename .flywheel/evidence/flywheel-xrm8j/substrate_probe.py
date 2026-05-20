#!/usr/bin/env python3
"""Disposable JSM-like substrate latency probe."""

from __future__ import annotations

import argparse
import json
import os
import platform
import shutil
import sqlite3
import statistics
import string
import subprocess
import sys
import tempfile
import time
from pathlib import Path
from typing import Any, Callable


PRIMITIVES = [
    "codex goal format hook",
    "stale descendant reaper",
    "canonical cli scoping timeout",
    "repo local cli floor",
    "canonical cli checker timeout",
    "supabase prepush mirror",
    "auto push canonical",
    "br stage wrapper",
]


def tokens(text: str) -> list[str]:
    table = str.maketrans("", "", string.punctuation)
    return [part for part in text.lower().translate(table).split() if part]


def make_rows(count: int) -> list[tuple[str, str, str]]:
    rows: list[tuple[str, str, str]] = []
    for idx in range(count):
        primitive = PRIMITIVES[idx % len(PRIMITIVES)]
        rows.append(
            (
                f"skill-{idx:05d}",
                primitive,
                f"{primitive} substrate recovery evidence row {idx} "
                "with jsm ingest search cache primary mutation gate semantics",
            )
        )
    return rows


def percentile(values: list[float], pct: float) -> float:
    if not values:
        return 0.0
    ordered = sorted(values)
    index = min(len(ordered) - 1, round((len(ordered) - 1) * pct))
    return ordered[index]


def time_call(fn: Callable[[], Any]) -> float:
    start = time.perf_counter()
    fn()
    return (time.perf_counter() - start) * 1000


def summarize_search(times: list[float], counts: list[int]) -> dict[str, Any]:
    return {
        "runs": len(times),
        "p50_ms": round(statistics.median(times), 3),
        "p95_ms": round(percentile(times, 0.95), 3),
        "min_ms": round(min(times), 3),
        "max_ms": round(max(times), 3),
        "hit_counts": sorted(set(counts)),
    }


def sqlite_probe(rows: list[tuple[str, str, str]], root: Path, queries: list[str]) -> dict[str, Any]:
    db_path = root / "sqlite-wal.db"
    conn = sqlite3.connect(db_path)
    conn.execute("PRAGMA journal_mode=WAL")
    conn.execute("PRAGMA synchronous=NORMAL")
    conn.execute("PRAGMA busy_timeout=5000")
    conn.execute("CREATE TABLE skills(id TEXT PRIMARY KEY, title TEXT, body TEXT)")
    conn.execute("CREATE VIRTUAL TABLE skills_fts USING fts5(id, title, body)")

    def ingest() -> None:
        conn.executemany("INSERT INTO skills VALUES (?, ?, ?)", rows)
        conn.executemany("INSERT INTO skills_fts VALUES (?, ?, ?)", rows)
        conn.commit()

    ingest_ms = time_call(ingest)
    search_times: list[float] = []
    counts: list[int] = []
    for query in queries:
        def run() -> None:
            count = conn.execute(
                "SELECT count(*) FROM skills_fts WHERE skills_fts MATCH ?",
                (query,),
            ).fetchone()[0]
            counts.append(int(count))

        search_times.append(time_call(run))
    integrity = conn.execute("PRAGMA integrity_check").fetchone()[0]
    conn.close()
    return {
        "status": "ok",
        "ingest_ms": round(ingest_ms, 3),
        "search": summarize_search(search_times, counts),
        "integrity": integrity,
        "notes": "SQLite-WAL FTS5 baseline; retains current malformation class under disk/process stress.",
    }


def postgres_probe(rows: list[tuple[str, str, str]], queries: list[str], dsn: str) -> dict[str, Any]:
    try:
        import psycopg
    except ImportError as exc:
        return {"status": "skipped", "reason": f"psycopg unavailable: {exc}"}

    try:
        conn = psycopg.connect(dsn, connect_timeout=3)
    except Exception as exc:
        return {"status": "skipped", "reason": f"connect failed: {type(exc).__name__}: {exc}"}

    with conn:
        with conn.cursor() as cur:
            cur.execute("CREATE TEMP TABLE skills_probe(id text PRIMARY KEY, title text, body text) ON COMMIT DROP")

            def ingest() -> None:
                cur.executemany("INSERT INTO skills_probe VALUES (%s, %s, %s)", rows)
                cur.execute(
                    "CREATE INDEX skills_probe_fts_idx ON skills_probe "
                    "USING gin (to_tsvector('english', title || ' ' || body))"
                )

            ingest_ms = time_call(ingest)
            search_times: list[float] = []
            counts: list[int] = []
            for query in queries:
                def run() -> None:
                    cur.execute(
                        "SELECT count(*) FROM skills_probe "
                        "WHERE to_tsvector('english', title || ' ' || body) @@ plainto_tsquery('english', %s)",
                        (query,),
                    )
                    counts.append(int(cur.fetchone()[0]))

                search_times.append(time_call(run))
    return {
        "status": "ok",
        "ingest_ms": round(ingest_ms, 3),
        "search": summarize_search(search_times, counts),
        "notes": "Temp-table probe only; no persistent schema mutation.",
    }


def lmdb_probe(rows: list[tuple[str, str, str]], root: Path, queries: list[str]) -> dict[str, Any]:
    try:
        import lmdb
    except ImportError as exc:
        return {"status": "skipped", "reason": f"lmdb unavailable: {exc}"}

    env = lmdb.open(str(root / "lmdb"), map_size=128 * 1024 * 1024, max_dbs=2)
    records = env.open_db(b"records")
    terms = env.open_db(b"terms")

    def ingest() -> None:
        with env.begin(write=True) as txn:
            index: dict[str, list[str]] = {}
            for row_id, title, body in rows:
                payload = json.dumps({"id": row_id, "title": title, "body": body}, separators=(",", ":")).encode()
                txn.put(row_id.encode(), payload, db=records)
                for token in set(tokens(f"{title} {body}")):
                    index.setdefault(token, []).append(row_id)
            for token, ids in index.items():
                txn.put(token.encode(), json.dumps(ids, separators=(",", ":")).encode(), db=terms)

    ingest_ms = time_call(ingest)
    search_times: list[float] = []
    counts: list[int] = []
    for query in queries:
        def run() -> None:
            with env.begin() as txn:
                sets: list[set[str]] = []
                for token in tokens(query):
                    raw = txn.get(token.encode(), db=terms)
                    sets.append(set(json.loads(raw.decode())) if raw else set())
                hits = set.intersection(*sets) if sets else set()
                counts.append(len(hits))

        search_times.append(time_call(run))
    env.close()
    return {
        "status": "ok",
        "ingest_ms": round(ingest_ms, 3),
        "search": summarize_search(search_times, counts),
        "notes": "LMDB key-value plus in-probe inverted index; real migration needs explicit index schema.",
    }


def duckdb_probe(rows: list[tuple[str, str, str]], root: Path, queries: list[str]) -> dict[str, Any]:
    try:
        import duckdb
    except ImportError as exc:
        return {"status": "skipped", "reason": f"duckdb unavailable: {exc}"}

    conn = duckdb.connect(str(root / "duckdb.db"))
    conn.execute("CREATE TABLE skills(id VARCHAR PRIMARY KEY, title VARCHAR, body VARCHAR)")

    def ingest() -> None:
        conn.executemany("INSERT INTO skills VALUES (?, ?, ?)", rows)

    ingest_ms = time_call(ingest)
    search_times: list[float] = []
    counts: list[int] = []
    for query in queries:
        parts = [f"%{token}%" for token in tokens(query)]

        def run() -> None:
            clauses = " AND ".join(["lower(title || ' ' || body) LIKE ?" for _ in parts])
            count = conn.execute(f"SELECT count(*) FROM skills WHERE {clauses}", parts).fetchone()[0]
            counts.append(int(count))

        search_times.append(time_call(run))
    conn.close()
    return {
        "status": "ok",
        "ingest_ms": round(ingest_ms, 3),
        "search": summarize_search(search_times, counts),
        "notes": "DuckDB row-store-like probe using LIKE; good analytics substrate, weaker fit for hot OLTP ingest.",
    }


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(description="Run disposable JSM substrate comparison probes.")
    parser.add_argument("--rows", type=int, default=2000)
    parser.add_argument("--tmp-dir", type=Path, default=None)
    parser.add_argument("--json-out", type=Path, required=True)
    parser.add_argument("--postgres-dsn", default="postgresql://josh@localhost:5432/postgres")
    return parser.parse_args()


def main() -> int:
    args = parse_args()
    root = args.tmp_dir or Path(tempfile.mkdtemp(prefix="flywheel-xrm8j-probe."))
    root.mkdir(parents=True, exist_ok=True)
    rows = make_rows(args.rows)
    queries = PRIMITIVES * 4
    results = {
        "schema_version": "jsm-substrate-comparison-probe/v1",
        "rows": args.rows,
        "query_runs_per_substrate": len(queries),
        "runtime": {
            "python": sys.version.split()[0],
            "platform": platform.platform(),
            "tmp_dir": str(root),
            "psql": shutil.which("psql"),
        },
        "substrates": {
            "sqlite_wal": sqlite_probe(rows, root, queries),
            "postgres": postgres_probe(rows, queries, args.postgres_dsn),
            "lmdb": lmdb_probe(rows, root, queries),
            "duckdb": duckdb_probe(rows, root, queries),
        },
    }
    args.json_out.parent.mkdir(parents=True, exist_ok=True)
    args.json_out.write_text(json.dumps(results, indent=2, sort_keys=True) + "\n")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
