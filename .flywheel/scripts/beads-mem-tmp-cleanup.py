#!/usr/bin/env python3
"""Protected cleanup primitive for top-level beads_mem temp DB files."""

from __future__ import annotations

import argparse
import json
import os
import re
import subprocess
import sys
import time
from dataclasses import asdict, dataclass
from datetime import datetime, timezone
from pathlib import Path


SCHEMA_VERSION = "beads-mem-tmp-cleanup/v1"
FILENAME_RE = re.compile(r"^beads_mem_[0-9]+_0\.db(?:-wal|-shm)?$")
DEFAULT_LEDGER = Path.home() / ".local/state/flywheel/beads-mem-tmp-cleanup.jsonl"
ROOT = Path(__file__).resolve().parents[2]
STORAGE_DOCTOR = ROOT / ".flywheel/scripts/storage-pressure-doctor.sh"


@dataclass(frozen=True)
class FilePlan:
    path: str
    name: str
    size_bytes: int
    age_seconds: int
    action: str
    reason: str
    lsof_checked: bool
    lsof_open: bool
    lsof_exit_code: int | None


@dataclass(frozen=True)
class OpenHandleSnapshot:
    open_paths: set[str]
    checked: bool
    exit_code: int | None
    error: str | None = None


def utc_now() -> str:
    return datetime.now(timezone.utc).strftime("%Y-%m-%dT%H:%M:%SZ")


def emit(payload: dict[str, object], json_mode: bool) -> None:
    if json_mode:
        print(json.dumps(payload, sort_keys=True))
    else:
        print(f"{payload.get('status')} planned={payload.get('planned_count')} deleted={payload.get('deleted_count')}")


def tmpdir_from_env() -> Path:
    return Path(os.environ.get("TMPDIR") or "/tmp").expanduser().resolve(strict=False)


def candidate_files(tmpdir: Path) -> list[Path]:
    if not tmpdir.exists() or not tmpdir.is_dir():
        return []
    return sorted(
        path
        for path in tmpdir.iterdir()
        if path.is_file() and FILENAME_RE.fullmatch(path.name)
    )


def lsof_snapshot(tmpdir: Path, lsof_bin: str) -> OpenHandleSnapshot:
    try:
        proc = subprocess.run(
            [lsof_bin, "-F", "n", "+d", str(tmpdir)],
            text=True,
            stdout=subprocess.PIPE,
            stderr=subprocess.PIPE,
            timeout=10,
            check=False,
        )
    except FileNotFoundError:
        return OpenHandleSnapshot(set(), False, None, "lsof_not_found")
    except subprocess.TimeoutExpired:
        return OpenHandleSnapshot(set(), False, None, "lsof_timeout")
    open_paths = {
        str(Path(line[1:]).resolve(strict=False))
        for line in proc.stdout.splitlines()
        if line.startswith("n")
    }
    return OpenHandleSnapshot(open_paths, True, proc.returncode)


def build_plan(tmpdir: Path, min_age_seconds: int, lsof_bin: str) -> list[FilePlan]:
    now = time.time()
    plan: list[FilePlan] = []
    open_handles = lsof_snapshot(tmpdir, lsof_bin)
    for path in candidate_files(tmpdir):
        stat = path.stat()
        age_seconds = max(0, int(now - stat.st_mtime))
        resolved = str(path.resolve(strict=False))
        lsof_open = not open_handles.checked or resolved in open_handles.open_paths
        action = "delete"
        reason = "eligible"
        if age_seconds < min_age_seconds:
            action = "skip"
            reason = "too_young"
        elif lsof_open:
            action = "skip"
            reason = "open_handle" if open_handles.checked else str(open_handles.error or "lsof_unavailable")
        plan.append(
            FilePlan(
                path=str(path),
                name=path.name,
                size_bytes=stat.st_size,
                age_seconds=age_seconds,
                action=action,
                reason=reason,
                lsof_checked=open_handles.checked,
                lsof_open=lsof_open,
                lsof_exit_code=open_handles.exit_code,
            )
        )
    return plan


def storage_pressure_summary(doctor_fixture: str | None, timeout_seconds: int) -> dict[str, object]:
    if doctor_fixture:
        try:
            payload = json.loads(Path(doctor_fixture).read_text())
            return {
                "status": payload.get("status", "unknown"),
                "storage": payload.get("storage", {}),
                "private_tmp": payload.get("private_tmp", {}),
                "source": doctor_fixture,
            }
        except (OSError, json.JSONDecodeError) as exc:
            return {"status": "unknown", "error": str(exc), "source": doctor_fixture}
    if not STORAGE_DOCTOR.exists():
        return {"status": "unknown", "error": "storage-pressure-doctor missing", "source": str(STORAGE_DOCTOR)}
    try:
        proc = subprocess.run(
            [str(STORAGE_DOCTOR), "--doctor", "--json"],
            text=True,
            stdout=subprocess.PIPE,
            stderr=subprocess.PIPE,
            timeout=timeout_seconds,
            check=False,
        )
    except subprocess.TimeoutExpired:
        return {
            "status": "unknown",
            "error": "storage_pressure_doctor_timeout",
            "source": str(STORAGE_DOCTOR),
            "timeout_seconds": timeout_seconds,
        }
    try:
        payload = json.loads(proc.stdout or "{}")
    except json.JSONDecodeError:
        payload = {"status": "unknown", "raw_stdout": proc.stdout[:500], "stderr": proc.stderr[:500]}
    return {
        "status": payload.get("status", "unknown"),
        "storage": payload.get("storage", {}),
        "private_tmp": payload.get("private_tmp", {}),
        "source": str(STORAGE_DOCTOR),
        "exit_code": proc.returncode,
    }


def write_ledger(path: Path, row: dict[str, object]) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    with path.open("a", encoding="utf-8") as handle:
        handle.write(json.dumps(row, sort_keys=True, separators=(",", ":")) + "\n")


def schema() -> dict[str, object]:
    return {
        "schema_version": SCHEMA_VERSION,
        "command": "beads-mem-tmp-cleanup.py",
        "default_mode": "dry-run",
        "mutation_modes": ["--dry-run", "--apply"],
        "stable_exit_codes": {"0": "ok", "2": "usage", "3": "protected"},
        "scope": {
            "root": "current-user TMPDIR only unless --tmpdir fixture is supplied",
            "depth": "top-level files only",
            "filename_regex": FILENAME_RE.pattern,
        },
        "apply_requires": ["--idempotency-key", "--min-age-seconds"],
        "ledger": str(DEFAULT_LEDGER),
    }


def examples() -> dict[str, object]:
    return {
        "examples": [
            "beads-mem-tmp-cleanup.py --dry-run --min-age-seconds 86400 --json",
            "beads-mem-tmp-cleanup.py --apply --idempotency-key flywheel-1935y-20260509 --min-age-seconds 86400 --json",
        ]
    }


def parse_args(argv: list[str]) -> argparse.Namespace:
    parser = argparse.ArgumentParser(description="Protected beads_mem TMPDIR cleanup")
    parser.add_argument("--tmpdir", default=str(tmpdir_from_env()))
    parser.add_argument("--ledger", default=str(DEFAULT_LEDGER))
    parser.add_argument("--min-age-seconds", type=int)
    parser.add_argument("--min-age-hours", type=float)
    parser.add_argument("--dry-run", action="store_true")
    parser.add_argument("--apply", action="store_true")
    parser.add_argument("--idempotency-key", default="")
    parser.add_argument("--lsof-bin", default=os.environ.get("LSOF_BIN", "lsof"))
    parser.add_argument("--doctor-fixture")
    parser.add_argument("--doctor-timeout-seconds", type=int, default=20)
    parser.add_argument("--json", action="store_true")
    parser.add_argument("--schema", action="store_true")
    parser.add_argument("--examples", action="store_true")
    return parser.parse_args(argv)


def main(argv: list[str]) -> int:
    args = parse_args(argv)
    if args.schema:
        emit(schema(), args.json)
        return 0
    if args.examples:
        emit(examples(), args.json)
        return 0
    if args.apply and args.dry_run:
        print("ERROR: choose exactly one of --dry-run or --apply", file=sys.stderr)
        return 2
    apply = bool(args.apply)
    min_age_seconds = args.min_age_seconds
    if min_age_seconds is None and args.min_age_hours is not None:
        min_age_seconds = int(args.min_age_hours * 3600)
    if min_age_seconds is None:
        min_age_seconds = 24 * 3600
    if min_age_seconds < 0:
        print("ERROR: age threshold must be non-negative", file=sys.stderr)
        return 2
    if apply and not args.idempotency_key:
        print("ERROR: --apply requires --idempotency-key", file=sys.stderr)
        return 2
    tmpdir = Path(args.tmpdir).expanduser().resolve(strict=False)
    if not tmpdir.exists() or not tmpdir.is_dir():
        print(f"ERROR: tmpdir is not a directory: {tmpdir}", file=sys.stderr)
        return 2

    plan = build_plan(tmpdir, min_age_seconds, args.lsof_bin)
    deleted_bytes = 0
    deleted_count = 0
    errors: list[dict[str, str]] = []
    if apply:
        for item in plan:
            if item.action != "delete":
                continue
            path = Path(item.path)
            try:
                path.unlink()
                deleted_bytes += item.size_bytes
                deleted_count += 1
            except OSError as exc:
                errors.append({"path": item.path, "error": str(exc)})

    planned_delete = [item for item in plan if item.action == "delete"]
    skipped = [item for item in plan if item.action == "skip"]
    doctor = storage_pressure_summary(args.doctor_fixture, args.doctor_timeout_seconds)
    row: dict[str, object] = {
        "schema_version": SCHEMA_VERSION,
        "ts": utc_now(),
        "tmpdir": str(tmpdir),
        "apply": apply,
        "idempotency_key": args.idempotency_key if apply else None,
        "age_threshold_seconds": min_age_seconds,
        "planned_count": len(planned_delete),
        "planned_bytes": sum(item.size_bytes for item in planned_delete),
        "deleted_count": deleted_count,
        "deleted_bytes": deleted_bytes,
        "skipped_count": len(skipped),
        "skipped_bytes": sum(item.size_bytes for item in skipped),
        "lsof": {
            "checked_count": len(plan),
            "open_count": sum(1 for item in plan if item.lsof_open),
            "bin": args.lsof_bin,
        },
        "post_run_storage_pressure_doctor": doctor,
        "errors": errors,
    }
    write_ledger(Path(args.ledger), row)
    payload = {
        **row,
        "status": "ok" if not errors else "warn",
        "dry_run": not apply,
        "files": [asdict(item) for item in plan],
    }
    emit(payload, args.json)
    return 0 if not errors else 3


if __name__ == "__main__":
    raise SystemExit(main(sys.argv[1:]))
