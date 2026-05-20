#!/usr/bin/env bash
set -euo pipefail

exec python3 - "$@" <<'PY'
from __future__ import annotations

import argparse
import json
import sys
from pathlib import Path
from typing import Any


SCHEMA_VERSION = "worker-tick-postcallback-verify/v1"
MAIN_FF = {"ok", "behind", "diverged", "unknown"}
AUTO_PUSH_OK = {"ok", "swept"}
CLOSE_CLASSES = {"substrate_class", "runtime_class"}


def load_row(args: argparse.Namespace) -> dict[str, Any]:
    if args.row_json:
        return json.loads(args.row_json)
    if args.row_file:
        return json.loads(Path(args.row_file).read_text(encoding="utf-8"))
    if not sys.stdin.isatty():
        return json.loads(sys.stdin.read())
    raise SystemExit("provide --row-json, --row-file, or stdin")


def receipt_path(row: dict[str, Any], repo: Path) -> Path | None:
    raw = row.get("runtime_receipt_path")
    if not isinstance(raw, str) or not raw.strip():
        return None
    path = Path(raw).expanduser()
    if not path.is_absolute():
        path = repo / path
    return path


def artifacts_populated(row: dict[str, Any]) -> bool:
    artifacts = row.get("runtime_artifacts")
    return isinstance(artifacts, dict) and bool(artifacts)


def verify(row: dict[str, Any], repo: Path) -> tuple[dict[str, Any], int]:
    reasons: list[str] = []
    if not isinstance(row, dict):
        return {
            "schema_version": SCHEMA_VERSION,
            "status": "fail",
            "ok": False,
            "exit_code": 1,
            "reasons": ["row_not_object"],
        }, 1

    close_class = row.get("close_class")
    if close_class not in CLOSE_CLASSES:
        return {
            "schema_version": SCHEMA_VERSION,
            "status": "fail",
            "ok": False,
            "exit_code": 2,
            "reasons": ["close_class_undeclared"],
        }, 2

    for field in (
        "post_callback_worktree_removed",
        "post_callback_branch_local_deleted",
        "post_callback_stash_dropped",
    ):
        if row.get(field) is False:
            reasons.append(f"{field}_unfinished")
        elif field in row and row.get(field) is not None and not isinstance(row.get(field), bool):
            reasons.append(f"{field}_invalid")

    main_ff = row.get("post_callback_main_ff_status")
    if main_ff not in MAIN_FF:
        reasons.append("post_callback_main_ff_status_invalid")
    elif main_ff in {"behind", "diverged"}:
        reasons.append(f"main_ff_{main_ff}")

    auto_push = row.get("post_callback_auto_push_status")
    if auto_push not in {"ok", "blocked", "swept", "skipped"}:
        reasons.append("post_callback_auto_push_status_invalid")
    elif auto_push not in AUTO_PUSH_OK:
        reasons.append(f"auto_push_{auto_push}")

    if close_class == "runtime_class":
        path = receipt_path(row, repo)
        if path is None:
            reasons.append("runtime_receipt_path_required")
        elif not path.exists() or path.stat().st_size == 0:
            reasons.append("runtime_receipt_missing_or_empty")
        if not artifacts_populated(row):
            reasons.append("runtime_artifacts_required")

    ok = not reasons
    result = {
        "schema_version": SCHEMA_VERSION,
        "status": "pass" if ok else "fail",
        "ok": ok,
        "exit_code": 0 if ok else 1,
        "close_class": close_class,
        "reasons": reasons,
    }
    return result, 0 if ok else 1


def main() -> int:
    parser = argparse.ArgumentParser(description="Verify v3 callback fields before a worker sends DONE.")
    parser.add_argument("--row-json")
    parser.add_argument("--row-file")
    parser.add_argument("--repo", default=".")
    parser.add_argument("--json", action="store_true")
    args = parser.parse_args()

    row = load_row(args)
    result, rc = verify(row, Path(args.repo).expanduser().resolve())
    if args.json:
        print(json.dumps(result, sort_keys=True))
    else:
        print(f"{result['status']} {' '.join(result.get('reasons', []))}".strip())
    return rc


if __name__ == "__main__":
    raise SystemExit(main())
PY
