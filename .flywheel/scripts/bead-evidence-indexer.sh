#!/usr/bin/env bash
set -euo pipefail

python3 - "$@" <<'PY'
from __future__ import annotations

import argparse
import hashlib
import json
import os
import re
import shutil
import sys
import time
from datetime import datetime, timezone
from pathlib import Path

SCHEMA = "bead-evidence-index/v1"
DEFAULT_STATE_DIR = Path.home() / ".local/state/flywheel"


def iso_now() -> str:
    return datetime.now(timezone.utc).strftime("%Y-%m-%dT%H:%M:%SZ")


def expand(path: str | Path) -> Path:
    return Path(path).expanduser()


def sha256_file(path: Path) -> str:
    h = hashlib.sha256()
    with path.open("rb") as handle:
        for chunk in iter(lambda: handle.read(1024 * 1024), b""):
            h.update(chunk)
    return h.hexdigest()


def read_jsonl(path: Path) -> list[dict]:
    rows: list[dict] = []
    if not path.exists():
        return rows
    with path.open(encoding="utf-8", errors="ignore") as handle:
        for line_no, line in enumerate(handle, 1):
            text = line.strip()
            if not text:
                continue
            try:
                row = json.loads(text)
            except Exception:
                continue
            if isinstance(row, dict):
                row["_line"] = line_no
                rows.append(row)
    return rows


def append_jsonl(path: Path, row: dict) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    encoded = json.dumps(row, sort_keys=True, separators=(",", ":"))
    with path.open("a", encoding="utf-8") as handle:
        handle.write(encoded + "\n")


def callback_evidence_path(text: str) -> str | None:
    match = re.search(r"(?:^|\s)evidence=([^ \t\n]+)", text)
    if match:
        return match.group(1)
    match = re.search(r"(?:^|\s)evidence_path=([^ \t\n]+)", text)
    if match:
        return match.group(1)
    return None


def callback_bead_id(text: str) -> str | None:
    match = re.search(r"\b(?:DONE|BLOCKED)\s+(flywheel-[A-Za-z0-9._-]+)\b", text)
    if match:
        return match.group(1)
    match = re.search(r"\bbead_id=(flywheel-[A-Za-z0-9._-]+)\b", text)
    if match:
        return match.group(1)
    return None


def existing_latest(index_path: Path) -> dict[str, dict]:
    latest: dict[str, dict] = {}
    for row in read_jsonl(index_path):
        bead_id = str(row.get("bead_id") or "")
        if bead_id:
            latest[bead_id] = row
    return latest


def resolve_candidate(raw: str | None, repo: Path) -> Path | None:
    if not raw:
        return None
    path = expand(raw)
    if not path.is_absolute():
        path = repo / path
    return path


def source_from_callback_file(path: Path, repo: Path) -> tuple[Path, str] | None:
    try:
        text = path.read_text(encoding="utf-8", errors="ignore")
    except Exception:
        return None
    raw = callback_evidence_path(text)
    candidate = resolve_candidate(raw, repo)
    if candidate and candidate.exists() and candidate.is_file():
        return candidate, "callback_evidence_field"
    return None


def scan_tmp_for_evidence(bead_id: str, tmp_dir: Path, repo: Path) -> tuple[Path, str] | None:
    suffix = bead_id.removeprefix("flywheel-")
    candidates: list[Path] = []
    for pattern in (f"*{bead_id}*", f"*{suffix}*"):
        candidates.extend(path for path in tmp_dir.glob(pattern) if path.is_file())
    unique = sorted(set(candidates), key=lambda p: (
        0 if "evidence" in p.name else 1,
        0 if p.suffix in {".md", ".txt", ".json"} else 1,
        len(p.name),
        p.name,
    ))
    for path in unique:
        if "callback" in path.name:
            resolved = source_from_callback_file(path, repo)
            if resolved:
                return resolved
        if "evidence" in path.name or bead_id in path.name or suffix in path.name:
            return path, "tmp_scan"
    return None


def durable_name(bead_id: str, source: Path) -> str:
    suffix = source.suffix if source.suffix else ".evidence"
    return f"{bead_id}{suffix}"


def build_records_from_dispatch_log(args: argparse.Namespace) -> list[dict]:
    dispatch_log = expand(args.dispatch_log)
    if not dispatch_log.is_absolute():
        dispatch_log = expand(args.repo).resolve() / dispatch_log
    rows = read_jsonl(dispatch_log)
    records: list[dict] = []
    for row in rows:
        if row.get("event") != "closed":
            continue
        bead_id = str(row.get("bead_id") or "")
        if not bead_id:
            continue
        if args.bead and bead_id != args.bead:
            continue
        raw = row.get("evidence_path") or row.get("evidence") or row.get("jeff_issue_body") or row.get("report_path")
        records.append({
            "bead_id": bead_id,
            "task_id": row.get("task_id"),
            "dispatch_ts": row.get("ts"),
            "dispatch_line": row.get("_line"),
            "raw_source": raw,
            "record_source": "dispatch_log",
        })
    return records


def build_records_from_callback(args: argparse.Namespace) -> list[dict]:
    text = ""
    if args.callback:
        text = args.callback
    elif args.callback_file:
        text = expand(args.callback_file).read_text(encoding="utf-8", errors="ignore")
    if not text:
        return []
    bead_id = args.bead or callback_bead_id(text)
    if not bead_id:
        return []
    return [{
        "bead_id": bead_id,
        "task_id": None,
        "dispatch_ts": None,
        "dispatch_line": None,
        "raw_source": callback_evidence_path(text),
        "record_source": "callback",
    }]


def index_record(record: dict, args: argparse.Namespace, latest: dict[str, dict], now: str) -> dict:
    repo = expand(args.repo).resolve()
    tmp_dir = expand(args.tmp_dir)
    evidence_dir = expand(args.evidence_dir)
    index_path = expand(args.index)
    bead_id = record["bead_id"]

    source_kind = "missing"
    source_path = resolve_candidate(record.get("raw_source"), repo)
    if source_path and source_path.exists() and source_path.is_file():
        source_kind = "dispatch_field" if record["record_source"] == "dispatch_log" else "callback_field"
    else:
        scanned = scan_tmp_for_evidence(bead_id, tmp_dir, repo)
        if scanned:
            source_path, source_kind = scanned

    base = {
        "schema_version": SCHEMA,
        "ts": now,
        "bead_id": bead_id,
        "task_id": record.get("task_id"),
        "dispatch_ts": record.get("dispatch_ts"),
        "dispatch_line": record.get("dispatch_line"),
        "record_source": record.get("record_source"),
        "source_kind": source_kind,
        "apply": bool(args.apply),
    }

    if not source_path or not source_path.exists() or not source_path.is_file():
        row = {**base, "status": "missing", "source_path": str(source_path) if source_path else None}
        if args.apply:
            append_jsonl(index_path, row)
        return row

    source_hash = sha256_file(source_path)
    dest = evidence_dir / durable_name(bead_id, source_path)
    previous = latest.get(bead_id)
    if previous and previous.get("source_sha256") == source_hash and previous.get("durable_path"):
        return {
            **base,
            "status": "already_indexed",
            "source_path": str(source_path),
            "source_sha256": source_hash,
            "durable_path": previous.get("durable_path"),
        }

    row = {
        **base,
        "status": "indexed" if args.apply else "would_index",
        "source_path": str(source_path),
        "source_sha256": source_hash,
        "source_bytes": source_path.stat().st_size,
        "durable_path": str(dest),
    }
    if args.apply:
        evidence_dir.mkdir(parents=True, exist_ok=True)
        shutil.copy2(source_path, dest)
        append_jsonl(index_path, row)
        latest[bead_id] = row
    return row


def run_once(args: argparse.Namespace) -> dict:
    now = iso_now()
    index_path = expand(args.index)
    latest = existing_latest(index_path)
    records = build_records_from_callback(args) or build_records_from_dispatch_log(args)
    rows = [index_record(record, args, latest, now) for record in records]
    status_counts: dict[str, int] = {}
    for row in rows:
        status_counts[row["status"]] = status_counts.get(row["status"], 0) + 1
    missing_count = status_counts.get("missing", 0)
    return {
        "schema_version": SCHEMA,
        "mode": "apply" if args.apply else "dry-run",
        "status": "missing_evidence" if missing_count else "ok",
        "record_count": len(rows),
        "status_counts": status_counts,
        "index_path": str(index_path),
        "evidence_dir": str(expand(args.evidence_dir)),
        "rows": rows[: args.limit] if args.limit else rows,
    }


def doctor(args: argparse.Namespace) -> dict:
    args.apply = False
    result = run_once(args)
    return {
        "schema_version": SCHEMA,
        "status": "warn" if result["status_counts"].get("missing", 0) else "ok",
        "closed_records_observed": result["record_count"],
        "missing_evidence_count": result["status_counts"].get("missing", 0),
        "indexed_count": len(existing_latest(expand(args.index))),
        "index_path": str(expand(args.index)),
        "evidence_dir": str(expand(args.evidence_dir)),
    }


def emit(payload: dict, json_mode: bool) -> None:
    if json_mode:
        print(json.dumps(payload, sort_keys=True))
    else:
        print(f"{payload.get('status', 'ok')}: {payload.get('record_count', payload.get('indexed_count', 0))}")


def parser() -> argparse.ArgumentParser:
    p = argparse.ArgumentParser(description="Persist durable evidence paths for closed flywheel beads.")
    p.add_argument("--repo", default=os.getcwd())
    p.add_argument("--dispatch-log", default=".flywheel/dispatch-log.jsonl")
    p.add_argument("--state-dir", default=str(DEFAULT_STATE_DIR))
    p.add_argument("--evidence-dir", default=None)
    p.add_argument("--index", default=None)
    p.add_argument("--tmp-dir", default="/tmp")
    p.add_argument("--bead")
    p.add_argument("--callback")
    p.add_argument("--callback-file")
    p.add_argument("--apply", action="store_true")
    p.add_argument("--dry-run", action="store_true")
    p.add_argument("--json", action="store_true")
    p.add_argument("--watch", action="store_true")
    p.add_argument("--sleep-seconds", type=float, default=5.0)
    p.add_argument("--max-cycles", type=int, default=0)
    p.add_argument("--limit", type=int, default=0)
    p.add_argument("--doctor", action="store_true")
    p.add_argument("--repair", action="store_true")
    p.add_argument("--info", action="store_true")
    p.add_argument("--schema", action="store_true")
    return p


def main() -> int:
    args = parser().parse_args()
    state_dir = expand(args.state_dir)
    if args.evidence_dir is None:
        args.evidence_dir = str(state_dir / "bead-evidence")
    if args.index is None:
        args.index = str(state_dir / "bead-evidence-index.jsonl")
    if args.repair:
        args.apply = True

    if args.info:
        emit({
            "schema_version": SCHEMA,
            "commands": ["--doctor", "--repair", "--watch", "--apply", "--dry-run"],
            "default_mode": "dry-run",
            "mutates_only_with": "--apply or --repair",
            "index_path": args.index,
            "evidence_dir": args.evidence_dir,
        }, args.json)
        return 0
    if args.schema:
        emit({
            "schema_version": SCHEMA,
            "row_required": ["schema_version", "ts", "bead_id", "status", "source_kind", "durable_path"],
            "statuses": ["would_index", "indexed", "already_indexed", "missing"],
            "exit_codes": {"0": "completed", "1": "doctor found missing evidence", "2": "usage error"},
        }, args.json)
        return 0
    if args.doctor:
        payload = doctor(args)
        emit(payload, args.json)
        return 1 if payload["status"] == "warn" else 0

    cycles = 0
    last_payload: dict | None = None
    while True:
        last_payload = run_once(args)
        cycles += 1
        if not args.watch or (args.max_cycles and cycles >= args.max_cycles):
            break
        time.sleep(args.sleep_seconds)
    emit(last_payload or {}, args.json)
    return 0


if __name__ == "__main__":
    try:
        raise SystemExit(main())
    except BrokenPipeError:
        raise SystemExit(0)
PY
