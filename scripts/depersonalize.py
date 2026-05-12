#!/usr/bin/env python3
"""Public extraction guardrails for Flywheel depersonalization work."""

from __future__ import annotations

import argparse
import fnmatch
import json
import os
import sys
from dataclasses import dataclass
from pathlib import Path
from typing import Iterable

SCHEMA_VERSION = "flywheel.depersonalize.v0"
DENYLIST_SCHEMA_VERSION = "flywheel.live_state_denylist.v0"
DEFAULT_DENYLIST = "state/live-state-denylist.yaml"
REQUIRED_ROW_FIELDS = {
    "id",
    "class",
    "pattern",
    "decision",
    "reason_code",
    "public_replacement",
    "probe_fixture",
}
EXIT_DENY = 30
EXIT_MANUAL_REVIEW = 31
EXIT_CREDENTIAL = 32
EXIT_SCHEMA = 33
DEFAULT_IGNORED_DIR_NAMES = {
    ".git",
    ".next",
    ".pytest_cache",
    ".ruff_cache",
    ".venv",
    "__pycache__",
    "build",
    "dist",
    "node_modules",
    "venv",
}


@dataclass(frozen=True)
class DenyRow:
    id: str
    kind: str
    pattern: str
    decision: str
    reason_code: str
    public_replacement: str
    probe_fixture: str


def repo_root() -> Path:
    return Path(__file__).resolve().parents[1]


def strip_yaml_value(value: str) -> str:
    value = value.strip()
    if (value.startswith('"') and value.endswith('"')) or (
        value.startswith("'") and value.endswith("'")
    ):
        return value[1:-1]
    return value


def load_denylist(path: Path) -> list[DenyRow]:
    if not path.exists():
        raise ValueError(f"denylist not found: {path}")
    rows: list[dict[str, str]] = []
    current: dict[str, str] | None = None
    schema_version = ""
    in_rows = False
    for raw_line in path.read_text(encoding="utf-8").splitlines():
        line = raw_line.split("#", 1)[0].rstrip()
        if not line.strip():
            continue
        stripped = line.strip()
        if stripped.startswith("schema_version:"):
            schema_version = strip_yaml_value(stripped.split(":", 1)[1])
            continue
        if stripped == "rows:":
            in_rows = True
            continue
        if not in_rows:
            continue
        if stripped.startswith("- "):
            if current is not None:
                rows.append(current)
            current = {}
            payload = stripped[2:]
            if payload:
                key, value = payload.split(":", 1)
                current[key.strip()] = strip_yaml_value(value)
            continue
        if current is None or ":" not in stripped:
            raise ValueError(f"malformed denylist row near: {raw_line}")
        key, value = stripped.split(":", 1)
        current[key.strip()] = strip_yaml_value(value)
    if current is not None:
        rows.append(current)
    if schema_version != DENYLIST_SCHEMA_VERSION:
        raise ValueError(f"unsupported denylist schema_version: {schema_version}")
    parsed: list[DenyRow] = []
    for row in rows:
        missing = sorted(REQUIRED_ROW_FIELDS - set(row))
        if missing:
            raise ValueError(f"denylist row {row.get('id', '<unknown>')} missing {missing}")
        if row["decision"] not in {"deny", "manual-review", "fixture-only"}:
            raise ValueError(f"denylist row {row['id']} has invalid decision")
        parsed.append(
            DenyRow(
                id=row["id"],
                kind=row["class"],
                pattern=row["pattern"],
                decision=row["decision"],
                reason_code=row["reason_code"],
                public_replacement=row["public_replacement"],
                probe_fixture=row["probe_fixture"],
            )
        )
    if not parsed:
        raise ValueError("denylist has no rows")
    return parsed


def iter_paths(root: Path, ignored_dir_names: set[str]) -> Iterable[str]:
    for dirpath, dirnames, filenames in os.walk(root):
        dirnames[:] = sorted(d for d in dirnames if d not in ignored_dir_names)
        for name in sorted(dirnames + filenames):
            path = Path(dirpath, name)
            yield path.relative_to(root).as_posix()


def row_matches(row: DenyRow, relpath: str) -> bool:
    pattern = row.pattern
    if fnmatch.fnmatchcase(relpath, pattern):
        return True
    if pattern.startswith("**/") and fnmatch.fnmatchcase(relpath, pattern[3:]):
        return True
    return False


def scan(
    root: Path, rows: list[DenyRow], ignored_dir_names: set[str]
) -> list[dict[str, str]]:
    findings: list[dict[str, str]] = []
    for relpath in iter_paths(root, ignored_dir_names):
        for row in rows:
            if row_matches(row, relpath):
                finding = {
                    "id": row.id,
                    "class": row.kind,
                    "decision": row.decision,
                    "reason_code": row.reason_code,
                    "path": relpath,
                    "public_replacement": row.public_replacement,
                }
                findings.append(finding)
                break
    return findings


def status_for(findings: list[dict[str, str]]) -> tuple[str, int]:
    if not findings:
        return "pass", 0
    decisions = {finding["decision"] for finding in findings}
    classes = {finding["class"] for finding in findings}
    if "credential-state" in classes:
        return "fail", EXIT_CREDENTIAL
    if "deny" in decisions:
        return "fail", EXIT_DENY
    if "manual-review" in decisions:
        return "manual_review_required", EXIT_MANUAL_REVIEW
    return "pass", 0


def emit(payload: dict[str, object], json_out: bool) -> None:
    if json_out:
        print(json.dumps(payload, sort_keys=True))
        return
    print(f"status={payload['status']} exit_code={payload['exit_code']}")
    for finding in payload.get("findings", []):
        print(
            "finding "
            f"id={finding['id']} decision={finding['decision']} "
            f"reason_code={finding['reason_code']} path={finding['path']}"
        )


def probe_denylist(args: argparse.Namespace) -> int:
    root = Path(args.root).resolve()
    denylist = Path(args.denylist)
    if not denylist.is_absolute():
        denylist = repo_root() / denylist
    try:
        rows = load_denylist(denylist)
    except ValueError as exc:
        payload = {
            "schema_version": SCHEMA_VERSION,
            "command": "probe-denylist",
            "status": "fail",
            "exit_code": EXIT_SCHEMA,
            "error": str(exc),
        }
        emit(payload, args.json)
        return EXIT_SCHEMA
    ignored_dir_names = set() if args.include_ignored_dirs else DEFAULT_IGNORED_DIR_NAMES
    findings = scan(root, rows, ignored_dir_names)
    status, exit_code = status_for(findings)
    payload = {
        "schema_version": SCHEMA_VERSION,
        "command": "probe-denylist",
        "status": status,
        "exit_code": exit_code,
        "root": str(root),
        "denylist": str(denylist),
        "ignored_dir_names": sorted(ignored_dir_names),
        "findings": findings,
    }
    emit(payload, args.json)
    return exit_code


def main(argv: list[str] | None = None) -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--json", action="store_true")
    parser.add_argument("--denylist", default=DEFAULT_DENYLIST)
    parser.add_argument("--root", default=".")
    parser.add_argument("--probe-denylist", action="store_true")
    parser.add_argument(
        "--include-ignored-dirs",
        action="store_true",
        help="scan dependency/cache/build directories that are skipped by default",
    )
    args = parser.parse_args(argv)
    if not args.probe_denylist:
        parser.error("only --probe-denylist is implemented")
    return probe_denylist(args)


if __name__ == "__main__":
    raise SystemExit(main())
