#!/usr/bin/env bash
set -euo pipefail
payload_file=""
if [[ " $* " != *" --info "* ]]; then
  payload_file="$(mktemp "${TMPDIR:-/tmp}/append-safe-write.stdin.XXXXXX")"
  trap 'rm -f "$payload_file"' EXIT
  cat >"$payload_file"
  export APPEND_SAFE_PAYLOAD_FILE="$payload_file"
fi
python3 - "$@" <<'PY'
from __future__ import annotations

import argparse
import json
import os
import shutil
import time
from pathlib import Path

VERSION = "append-safe-write/v1"
TAIL_BYTES = 4096

def emit(payload: dict, json_mode: bool) -> None:
    if json_mode:
        print(json.dumps(payload, sort_keys=True, separators=(",", ":")))
    else:
        print(payload.get("message") or payload.get("status", "ok"))


def info(json_mode: bool) -> int:
    payload = {
        "schema_version": VERSION,
        "status": "ok",
        "exit_codes": {
            "0": "success",
            "1": "lease-failed",
            "2": "tail-divergence-exhausted",
            "3": "invalid-args",
        },
    }
    emit(payload, json_mode)
    return 0


def read_tail(path: Path) -> bytes:
    if not path.exists():
        return b""
    size = path.stat().st_size
    with path.open("rb") as handle:
        handle.seek(max(0, size - TAIL_BYTES))
        return handle.read()


def lock_paths(target: Path) -> tuple[Path, Path]:
    lock_dir = target.with_name(target.name + ".append-safe.lock")
    return lock_dir, lock_dir / "owner.json"


def stale(lock_dir: Path, owner: Path, lease_ms: int) -> bool:
    threshold = max(lease_ms * 2, 1) / 1000.0
    now = time.time()
    try:
        raw = json.loads(owner.read_text(encoding="utf-8"))
        created = float(raw.get("created_at_epoch", 0))
    except Exception:
        try:
            created = lock_dir.stat().st_mtime
        except FileNotFoundError:
            return False
    return now - created > threshold


def acquire(lock_dir: Path, owner: Path, lease_ms: int) -> bool:
    deadline = time.monotonic() + max(lease_ms, 1) / 1000.0
    while True:
        try:
            lock_dir.mkdir(mode=0o700)
            owner.write_text(json.dumps({
                "pid": os.getpid(),
                "created_at_epoch": time.time(),
                "host": os.uname().nodename,
            }), encoding="utf-8")
            return True
        except FileExistsError:
            if stale(lock_dir, owner, lease_ms):
                shutil.rmtree(lock_dir, ignore_errors=True)
                continue
            if time.monotonic() >= deadline:
                return False
            time.sleep(0.01)


def release(lock_dir: Path) -> None:
    shutil.rmtree(lock_dir, ignore_errors=True)


def sleep_env_ms(name: str) -> None:
    try:
        ms = int(os.environ.get(name, "0"))
    except ValueError:
        ms = 0
    if ms > 0:
        time.sleep(ms / 1000.0)


def maybe_force_diverge(target: Path, attempt: int) -> None:
    once = os.environ.get("APPEND_SAFE_TEST_DIVERGE_ONCE")
    each = os.environ.get("APPEND_SAFE_TEST_DIVERGE_EACH_ATTEMPT")
    if each or (once and attempt == 1):
        target.parent.mkdir(parents=True, exist_ok=True)
        with target.open("ab") as handle:
            handle.write(f"test-diverge-{attempt}\n".encode())
            handle.flush()
            os.fsync(handle.fileno())


def contains_key(target: Path, key: str) -> bool:
    if not target.exists():
        return False
    with target.open("rb") as handle:
        return key.encode() in handle.read()


def append_payload(target: Path, payload: bytes) -> None:
    target.parent.mkdir(parents=True, exist_ok=True)
    data = payload if payload.endswith(b"\n") else payload + b"\n"
    with target.open("ab") as handle:
        handle.write(data)
        handle.flush()
        os.fsync(handle.fileno())


def run(args: argparse.Namespace, payload: bytes) -> int:
    if not args.target or args.lease_ms <= 0 or args.max_retries < 0:
        emit({"schema_version": VERSION, "status": "invalid_args"}, args.json)
        return 3
    if not payload:
        emit({"schema_version": VERSION, "status": "invalid_args", "reason": "empty stdin"}, args.json)
        return 3

    target = Path(args.target).expanduser().resolve(strict=False)
    target.parent.mkdir(parents=True, exist_ok=True)
    lock_dir, owner = lock_paths(target)
    divergences = 0

    for attempt in range(1, args.max_retries + 2):
        before = read_tail(target)
        sleep_env_ms("APPEND_SAFE_TEST_SLEEP_AFTER_TAIL_MS")
        maybe_force_diverge(target, attempt)
        if not acquire(lock_dir, owner, args.lease_ms):
            emit({"schema_version": VERSION, "status": "lease_failed", "attempt": attempt}, args.json)
            return 1
        try:
            if read_tail(target) != before:
                divergences += 1
                if divergences > args.max_retries:
                    emit({
                        "schema_version": VERSION,
                        "status": "tail_divergence_exhausted",
                        "attempts": attempt,
                        "divergences": divergences,
                    }, args.json)
                    return 2
                continue
            if args.idempotency_key and contains_key(target, args.idempotency_key):
                emit({"schema_version": VERSION, "status": "ok", "idempotent_skip": True}, args.json)
                return 0
            append_payload(target, payload)
            tail = read_tail(target)
            data = payload if payload.endswith(b"\n") else payload + b"\n"
            ok = data in tail
            emit({
                "schema_version": VERSION,
                "status": "ok" if ok else "readback_failed",
                "target": str(target),
                "attempts": attempt,
                "divergences": divergences,
                "bytes_appended": len(data),
                "idempotent_skip": False,
            }, args.json)
            return 0 if ok else 1
        finally:
            release(lock_dir)
    return 2


parser = argparse.ArgumentParser(description="Append one stdin payload using a short EOF lease.")
parser.add_argument("--target")
parser.add_argument("--lease-ms", type=int, default=300)
parser.add_argument("--max-retries", type=int, default=5)
parser.add_argument("--idempotency-key")
parser.add_argument("--json", action="store_true")
parser.add_argument("--info", action="store_true")
ns = parser.parse_args()
if ns.info:
    raise SystemExit(info(ns.json))
payload_path = os.environ.get("APPEND_SAFE_PAYLOAD_FILE")
payload = Path(payload_path).read_bytes() if payload_path else b""
raise SystemExit(run(ns, payload))
PY
