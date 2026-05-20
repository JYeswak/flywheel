#!/usr/bin/env bash
set -euo pipefail

exec python3 - "$@" <<'PY'
from __future__ import annotations

import argparse
import json
import sys
from pathlib import Path
from typing import Any


SCHEMA_VERSION = "callback-envelope-v3-validator/v1"
V3_FIELDS = {
    "post_callback_worktree_removed",
    "post_callback_branch_local_deleted",
    "post_callback_stash_dropped",
    "post_callback_main_ff_status",
    "post_callback_auto_push_status",
    "close_class",
    "runtime_receipt_path",
    "runtime_artifacts",
}
MAIN_FF = {"ok", "behind", "diverged", "unknown"}
AUTO_PUSH = {"ok", "blocked", "swept", "skipped"}
CLOSE_CLASSES = {"substrate_class", "runtime_class"}


def load_row(args: argparse.Namespace) -> dict[str, Any]:
    if args.row_json:
        return json.loads(args.row_json)
    if args.row_file:
        return json.loads(Path(args.row_file).read_text(encoding="utf-8"))
    if args.dispatch_log and args.task_id:
        for line in Path(args.dispatch_log).read_text(encoding="utf-8").splitlines():
            if not line.strip():
                continue
            row = json.loads(line)
            if row.get("task_id") == args.task_id:
                return row
        raise SystemExit(f"task_id not found: {args.task_id}")
    if not sys.stdin.isatty():
        return json.loads(sys.stdin.read())
    raise SystemExit("provide --row-json, --row-file, --dispatch-log + --task-id, or stdin")


def opted_into_v3(row: dict[str, Any]) -> bool:
    version = row.get("schema_version")
    return version in {3, "3", "callback-envelope/v3", "dispatch-log-entry-v3"} or any(field in row for field in V3_FIELDS)


def has_runtime_artifacts(row: dict[str, Any]) -> bool:
    artifacts = row.get("runtime_artifacts")
    return isinstance(artifacts, dict) and bool(artifacts)


def tests_pass(row: dict[str, Any]) -> bool:
    value = str(row.get("tests", "")).upper()
    return "PASS" in value and "FAIL" not in value


def commit_present(row: dict[str, Any]) -> bool:
    for field in ("commit_sha", "commit"):
        value = row.get(field)
        if isinstance(value, str) and len(value.strip()) >= 7:
            return True
    return False


def validate(row: dict[str, Any]) -> dict[str, Any]:
    reasons: list[str] = []
    warnings: list[str] = []

    if not isinstance(row, dict):
        return {
            "schema_version": SCHEMA_VERSION,
            "status": "fail",
            "valid": False,
            "reasons": ["row_not_object"],
        }

    if not opted_into_v3(row):
        return {
            "schema_version": SCHEMA_VERSION,
            "status": "pass",
            "valid": True,
            "mode": "legacy_v2_backcompat",
            "reasons": [],
        }

    close_class = row.get("close_class")
    if close_class not in CLOSE_CLASSES:
        reasons.append("missing_or_invalid_close_class")

    main_ff = row.get("post_callback_main_ff_status")
    if main_ff is not None and main_ff not in MAIN_FF:
        reasons.append("invalid_post_callback_main_ff_status")

    auto_push = row.get("post_callback_auto_push_status")
    if auto_push is not None and auto_push not in AUTO_PUSH:
        reasons.append("invalid_post_callback_auto_push_status")
    if auto_push == "blocked":
        warnings.append("auto_push_blocked")

    for field in (
        "post_callback_worktree_removed",
        "post_callback_branch_local_deleted",
        "post_callback_stash_dropped",
    ):
        if field in row and row[field] is not None and not isinstance(row[field], bool):
            reasons.append(f"invalid_{field}")

    if close_class == "runtime_class":
        if not isinstance(row.get("runtime_receipt_path"), str) or not row.get("runtime_receipt_path", "").strip():
            reasons.append("runtime_receipt_path_required")
        if not has_runtime_artifacts(row):
            reasons.append("runtime_artifacts_required")
    elif close_class == "substrate_class":
        if not commit_present(row):
            reasons.append("substrate_commit_required")
        if not tests_pass(row):
            reasons.append("substrate_tests_pass_required")

    valid = not reasons
    return {
        "schema_version": SCHEMA_VERSION,
        "status": "pass" if valid else "fail",
        "valid": valid,
        "mode": "v3",
        "close_class": close_class,
        "reasons": reasons,
        "warnings": warnings,
    }


def main() -> int:
    parser = argparse.ArgumentParser(description="Validate dispatch-log callback envelope v3 close semantics.")
    parser.add_argument("--row-json")
    parser.add_argument("--row-file")
    parser.add_argument("--dispatch-log")
    parser.add_argument("--task-id")
    parser.add_argument("--json", action="store_true")
    args = parser.parse_args()

    row = load_row(args)
    result = validate(row)
    if args.json:
        print(json.dumps(result, sort_keys=True))
    else:
        print(f"{result['status']} {' '.join(result.get('reasons', []))}".strip())
    return 0 if result["valid"] else 1


if __name__ == "__main__":
    raise SystemExit(main())
PY
