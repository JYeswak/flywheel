#!/usr/bin/env python3
"""Public extraction guardrails for Flywheel depersonalization work."""

from __future__ import annotations

import argparse
import difflib
import fnmatch
import json
import os
import re
from dataclasses import dataclass
from pathlib import Path
from typing import Iterable

SCHEMA_VERSION = "flywheel.depersonalize.v0"
DENYLIST_SCHEMA_VERSION = "flywheel.live_state_denylist.v0"
TABLE_SCHEMA_VERSION = "flywheel.depersonalization_table.v0"
DEFAULT_DENYLIST = "state/live-state-denylist.yaml"
DEFAULT_TABLE = "de-personalization-table.yaml"
DEFAULT_ALLOWLIST = "state/depersonalization-scan-allowlist.yaml"
REQUIRED_DENY_ROW_FIELDS = {
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
EXIT_RESIDUAL = 40
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
TEXT_FILE_SUFFIXES = {
    "",
    ".bash",
    ".css",
    ".env",
    ".html",
    ".js",
    ".json",
    ".jsonl",
    ".md",
    ".mdx",
    ".py",
    ".rs",
    ".sh",
    ".svg",
    ".toml",
    ".ts",
    ".tsx",
    ".tmpl",
    ".txt",
    ".yaml",
    ".yml",
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


@dataclass(frozen=True)
class ReplacementRow:
    id: str
    kind: str
    private_value: str
    match_type: str
    action: str
    public_value: str


@dataclass(frozen=True)
class AllowRow:
    id: str
    root_pattern: str | None
    path_pattern: str
    row_id: str
    reason: str


def repo_root() -> Path:
    return Path(__file__).resolve().parents[1]


def strip_yaml_value(value: str) -> object:
    value = value.strip()
    if value in {"true", "false"}:
        return value == "true"
    if (value.startswith('"') and value.endswith('"')) or (
        value.startswith("'") and value.endswith("'")
    ):
        return value[1:-1]
    return value


def load_simple_yaml(path: Path) -> tuple[str, list[dict[str, object]]]:
    if not path.exists():
        raise ValueError(f"yaml file not found: {path}")
    rows: list[dict[str, object]] = []
    current: dict[str, object] | None = None
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
    return schema_version, rows


def load_denylist(path: Path) -> list[DenyRow]:
    schema_version, rows = load_simple_yaml(path)
    if schema_version != DENYLIST_SCHEMA_VERSION:
        raise ValueError(f"unsupported denylist schema_version: {schema_version}")
    parsed: list[DenyRow] = []
    for row in rows:
        missing = sorted(REQUIRED_DENY_ROW_FIELDS - set(row))
        if missing:
            raise ValueError(f"denylist row {row.get('id', '<unknown>')} missing {missing}")
        if row["decision"] not in {"deny", "manual-review", "fixture-only"}:
            raise ValueError(f"denylist row {row['id']} has invalid decision")
        parsed.append(
            DenyRow(
                id=str(row["id"]),
                kind=str(row["class"]),
                pattern=str(row["pattern"]),
                decision=str(row["decision"]),
                reason_code=str(row["reason_code"]),
                public_replacement=str(row["public_replacement"]),
                probe_fixture=str(row["probe_fixture"]),
            )
        )
    if not parsed:
        raise ValueError("denylist has no rows")
    return parsed


def load_replacement_table(path: Path) -> list[ReplacementRow]:
    schema_version, rows = load_simple_yaml(path)
    if schema_version != TABLE_SCHEMA_VERSION:
        raise ValueError(f"unsupported table schema_version: {schema_version}")
    parsed: list[ReplacementRow] = []
    for row in rows:
        required = {"id", "class", "private_value", "match_type", "action", "public_value"}
        missing = sorted(required - set(row))
        if missing:
            raise ValueError(f"table row {row.get('id', '<unknown>')} missing {missing}")
        parsed.append(
            ReplacementRow(
                id=str(row["id"]),
                kind=str(row["class"]),
                private_value=str(row["private_value"]),
                match_type=str(row["match_type"]),
                action=str(row["action"]),
                public_value=str(row["public_value"]),
            )
        )
    if not parsed:
        raise ValueError("replacement table has no rows")
    return sorted(
        parsed,
        key=lambda row: (row.match_type == "regex", len(row.private_value)),
        reverse=True,
    )


def load_allowlist(path: Path) -> list[AllowRow]:
    if not path.exists():
        return []
    schema_version, rows = load_simple_yaml(path)
    if schema_version != "flywheel.depersonalization_scan_allowlist.v0":
        raise ValueError(f"unsupported allowlist schema_version: {schema_version}")
    parsed: list[AllowRow] = []
    for row in rows:
        required = {"id", "path_pattern", "row_id", "reason"}
        missing = sorted(required - set(row))
        if missing:
            raise ValueError(f"allowlist row {row.get('id', '<unknown>')} missing {missing}")
        parsed.append(
            AllowRow(
                id=str(row["id"]),
                root_pattern=str(row["root_pattern"]) if "root_pattern" in row else None,
                path_pattern=str(row["path_pattern"]),
                row_id=str(row["row_id"]),
                reason=str(row["reason"]),
            )
        )
    return parsed


def iter_paths(root: Path, ignored_dir_names: set[str]) -> Iterable[str]:
    if root.is_file():
        yield root.name
        return
    for dirpath, dirnames, filenames in os.walk(root):
        dirnames[:] = sorted(d for d in dirnames if d not in ignored_dir_names)
        for name in sorted(dirnames + filenames):
            path = Path(dirpath, name)
            yield path.relative_to(root).as_posix()


def iter_text_files(root: Path, ignored_dir_names: set[str]) -> Iterable[tuple[str, Path]]:
    if root.is_file():
        if root.suffix in TEXT_FILE_SUFFIXES:
            yield root.name, root
        return
    for relpath in iter_paths(root, ignored_dir_names):
        path = root / relpath
        if not path.is_file():
            continue
        if path.suffix not in TEXT_FILE_SUFFIXES:
            continue
        yield relpath, path


def row_matches(row: DenyRow, relpath: str) -> bool:
    pattern = row.pattern
    if fnmatch.fnmatchcase(relpath, pattern):
        return True
    if pattern.startswith("**/") and fnmatch.fnmatchcase(relpath, pattern[3:]):
        return True
    return False


def path_pattern_matches(pattern: str, relpath: str) -> bool:
    if fnmatch.fnmatchcase(relpath, pattern):
        return True
    if pattern.startswith("**/") and fnmatch.fnmatchcase(relpath, pattern[3:]):
        return True
    return False


def is_allowed_finding(
    root: Path, relpath: str, row_id: str, allowlist: list[AllowRow]
) -> bool:
    return any(
        row.row_id == row_id
        and (row.root_pattern is None or path_pattern_matches(row.root_pattern, root.as_posix()))
        and path_pattern_matches(row.path_pattern, relpath)
        for row in allowlist
    )


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


def replacement_for(row: ReplacementRow) -> str:
    if row.action == "drop":
        return ""
    if row.action == "redact":
        return row.public_value or "[REDACTED]"
    return row.public_value


def row_pattern(row: ReplacementRow) -> re.Pattern[str]:
    if row.match_type in {"literal", "path-prefix", "glob"}:
        if row.match_type == "glob":
            return re.compile(fnmatch.translate(row.private_value))
        return re.compile(re.escape(row.private_value))
    if row.match_type == "regex":
        return re.compile(row.private_value)
    raise ValueError(f"table row {row.id} has unsupported match_type {row.match_type}")


def public_value_masks(rows: list[ReplacementRow]) -> list[tuple[str, str]]:
    values = sorted(
        {replacement_for(row) for row in rows if replacement_for(row)},
        key=len,
        reverse=True,
    )
    return [(value, f"@@FW_PUBLIC_VALUE_{index}@@") for index, value in enumerate(values)]


def mask_public_values(text: str, masks: list[tuple[str, str]]) -> str:
    masked = text
    for value, sentinel in masks:
        masked = masked.replace(value, sentinel)
    return masked


def unmask_public_values(text: str, masks: list[tuple[str, str]]) -> str:
    unmasked = text
    for value, sentinel in reversed(masks):
        unmasked = unmasked.replace(sentinel, value)
    return unmasked


def transform_text(text: str, rows: list[ReplacementRow]) -> tuple[str, list[str]]:
    changed_ids: list[str] = []
    transformed = text
    masks = public_value_masks(rows)
    for row in rows:
        pattern = row_pattern(row)
        protected = mask_public_values(transformed, masks)
        updated, count = pattern.subn(replacement_for(row), protected)
        if count:
            if row.id not in changed_ids:
                changed_ids.append(row.id)
            transformed = unmask_public_values(updated, masks)
    return transformed, changed_ids


def scan_table_values(
    root: Path, rows: list[ReplacementRow], ignored_dir_names: set[str]
) -> list[dict[str, object]]:
    findings: list[dict[str, object]] = []
    compiled = [(row, row_pattern(row)) for row in rows]
    masks = public_value_masks(rows)
    for relpath, path in iter_text_files(root, ignored_dir_names):
        try:
            text = path.read_text(encoding="utf-8")
        except UnicodeDecodeError:
            continue
        for line_no, line in enumerate(text.splitlines(), start=1):
            protected = mask_public_values(line, masks)
            matched_ids = [
                row.id for row, pattern in compiled if pattern.search(protected)
            ]
            if matched_ids:
                findings.append(
                    {
                        "path": relpath,
                        "line": line_no,
                        "row_ids": matched_ids,
                    }
                )
    return findings


def table_changes(
    root: Path, rows: list[ReplacementRow], ignored_dir_names: set[str]
) -> tuple[list[dict[str, object]], str]:
    changes: list[dict[str, object]] = []
    diff_parts: list[str] = []
    for relpath, path in iter_text_files(root, ignored_dir_names):
        try:
            original = path.read_text(encoding="utf-8")
        except UnicodeDecodeError:
            continue
        transformed, row_ids = transform_text(original, rows)
        if transformed == original:
            continue
        changes.append({"path": relpath, "row_ids": row_ids})
        diff_parts.extend(
            difflib.unified_diff(
                original.splitlines(keepends=True),
                transformed.splitlines(keepends=True),
                fromfile=f"a/{relpath}",
                tofile=f"b/{relpath}",
            )
        )
    return changes, "".join(diff_parts)


def apply_table_changes(
    root: Path, rows: list[ReplacementRow], ignored_dir_names: set[str]
) -> list[dict[str, object]]:
    changes: list[dict[str, object]] = []
    for relpath, path in iter_text_files(root, ignored_dir_names):
        try:
            original = path.read_text(encoding="utf-8")
        except UnicodeDecodeError:
            continue
        transformed, row_ids = transform_text(original, rows)
        if transformed == original:
            continue
        path.write_text(transformed, encoding="utf-8")
        changes.append({"path": relpath, "row_ids": row_ids})
    return changes


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


def load_common_inputs(
    args: argparse.Namespace,
) -> tuple[Path, list[DenyRow], list[ReplacementRow], list[AllowRow], set[str]]:
    root = Path(args.root).resolve()
    denylist = Path(args.denylist)
    table = Path(args.table)
    allowlist = Path(args.allowlist)
    if not denylist.is_absolute():
        denylist = repo_root() / denylist
    if not table.is_absolute():
        table = repo_root() / table
    if not allowlist.is_absolute():
        allowlist = repo_root() / allowlist
    ignored_dir_names = set() if args.include_ignored_dirs else DEFAULT_IGNORED_DIR_NAMES
    table_rows = load_replacement_table(table)
    selected_row_ids = set(args.row_id or [])
    if selected_row_ids:
        table_rows = [row for row in table_rows if row.id in selected_row_ids]
        missing = sorted(selected_row_ids - {row.id for row in table_rows})
        if missing:
            raise ValueError(f"unknown depersonalization row_id(s): {', '.join(missing)}")
    return (
        root,
        load_denylist(denylist),
        table_rows,
        load_allowlist(allowlist),
        ignored_dir_names,
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


def table_guard_findings(
    root: Path, rows: list[DenyRow], ignored_dir_names: set[str]
) -> tuple[str, int, list[dict[str, str]]]:
    findings = scan(root, rows, ignored_dir_names)
    status, exit_code = status_for(findings)
    return status, exit_code, findings


def filter_allowed_guard_findings(
    root: Path, findings: list[dict[str, str]], allowlist: list[AllowRow]
) -> tuple[str, int, list[dict[str, str]]]:
    filtered = [
        finding
        for finding in findings
        if not is_allowed_finding(root, str(finding["path"]), str(finding["id"]), allowlist)
    ]
    status, exit_code = status_for(filtered)
    return status, exit_code, filtered


def scan_table(args: argparse.Namespace) -> int:
    try:
        root, deny_rows, table_rows, allowlist, ignored_dir_names = load_common_inputs(args)
    except ValueError as exc:
        emit(
            {
                "schema_version": SCHEMA_VERSION,
                "command": "scan-table",
                "status": "fail",
                "exit_code": EXIT_SCHEMA,
                "error": str(exc),
            },
            args.json,
        )
        return EXIT_SCHEMA
    deny_status, deny_exit, deny_findings = table_guard_findings(
        root, deny_rows, ignored_dir_names
    )
    deny_status, deny_exit, deny_findings = filter_allowed_guard_findings(
        root, deny_findings, allowlist
    )
    if deny_status != "pass":
        emit(
            {
                "schema_version": SCHEMA_VERSION,
                "command": "scan-table",
                "status": deny_status,
                "exit_code": deny_exit,
                "root": str(root),
                "findings": deny_findings,
            },
            args.json,
        )
        return deny_exit
    findings = scan_table_values(root, table_rows, ignored_dir_names)
    findings = [
        finding
        for finding in findings
        if not all(
            is_allowed_finding(root, str(finding["path"]), row_id, allowlist)
            for row_id in finding["row_ids"]
        )
    ]
    status = "fail" if findings else "pass"
    exit_code = EXIT_RESIDUAL if findings else 0
    emit(
        {
            "schema_version": SCHEMA_VERSION,
            "command": "scan-table",
            "status": status,
            "exit_code": exit_code,
            "root": str(root),
            "findings": findings,
        },
        args.json,
    )
    return exit_code


def dry_run(args: argparse.Namespace) -> int:
    try:
        root, deny_rows, table_rows, allowlist, ignored_dir_names = load_common_inputs(args)
    except ValueError as exc:
        emit(
            {
                "schema_version": SCHEMA_VERSION,
                "command": "dry-run",
                "status": "fail",
                "exit_code": EXIT_SCHEMA,
                "error": str(exc),
            },
            args.json,
        )
        return EXIT_SCHEMA
    deny_status, deny_exit, deny_findings = table_guard_findings(
        root, deny_rows, ignored_dir_names
    )
    deny_status, deny_exit, deny_findings = filter_allowed_guard_findings(
        root, deny_findings, allowlist
    )
    if deny_status != "pass":
        emit(
            {
                "schema_version": SCHEMA_VERSION,
                "command": "dry-run",
                "status": deny_status,
                "exit_code": deny_exit,
                "root": str(root),
                "findings": deny_findings,
            },
            args.json,
        )
        return deny_exit
    changes, diff = table_changes(root, table_rows, ignored_dir_names)
    payload = {
        "schema_version": SCHEMA_VERSION,
        "command": "dry-run",
        "status": "pass",
        "exit_code": 0,
        "root": str(root),
        "changes": changes,
        "changed_files": len(changes),
    }
    if args.json:
        payload["diff"] = diff
        print(json.dumps(payload, sort_keys=True))
        return 0
    print(diff, end="")
    return 0


def apply_changes(args: argparse.Namespace) -> int:
    try:
        root, deny_rows, table_rows, allowlist, ignored_dir_names = load_common_inputs(args)
    except ValueError as exc:
        emit(
            {
                "schema_version": SCHEMA_VERSION,
                "command": "apply",
                "status": "fail",
                "exit_code": EXIT_SCHEMA,
                "error": str(exc),
            },
            args.json,
        )
        return EXIT_SCHEMA
    deny_status, deny_exit, deny_findings = table_guard_findings(
        root, deny_rows, ignored_dir_names
    )
    deny_status, deny_exit, deny_findings = filter_allowed_guard_findings(
        root, deny_findings, allowlist
    )
    if deny_status != "pass":
        emit(
            {
                "schema_version": SCHEMA_VERSION,
                "command": "apply",
                "status": deny_status,
                "exit_code": deny_exit,
                "root": str(root),
                "findings": deny_findings,
            },
            args.json,
        )
        return deny_exit
    changes = apply_table_changes(root, table_rows, ignored_dir_names)
    emit(
        {
            "schema_version": SCHEMA_VERSION,
            "command": "apply",
            "status": "pass",
            "exit_code": 0,
            "root": str(root),
            "changes": changes,
            "changed_files": len(changes),
            "findings": [],
        },
        args.json,
    )
    return 0


def main(argv: list[str] | None = None) -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--json", action="store_true")
    parser.add_argument("--denylist", default=DEFAULT_DENYLIST)
    parser.add_argument("--table", default=DEFAULT_TABLE)
    parser.add_argument("--allowlist", default=DEFAULT_ALLOWLIST)
    parser.add_argument(
        "--row-id",
        action="append",
        help="limit replacement-table scanning/codemod to a row id; may be repeated",
    )
    parser.add_argument("--root", default=".")
    parser.add_argument("--probe-denylist", action="store_true")
    parser.add_argument("--dry-run", action="store_true")
    parser.add_argument("--apply", action="store_true")
    parser.add_argument("--scan-table", action="store_true")
    parser.add_argument(
        "--include-ignored-dirs",
        action="store_true",
        help="scan dependency/cache/build directories that are skipped by default",
    )
    args = parser.parse_args(argv)
    selected = [args.probe_denylist, args.dry_run, args.apply, args.scan_table]
    if sum(1 for item in selected if item) != 1:
        parser.error("select exactly one of --probe-denylist, --dry-run, --apply, --scan-table")
    if args.probe_denylist:
        return probe_denylist(args)
    if args.dry_run:
        return dry_run(args)
    if args.apply:
        return apply_changes(args)
    return scan_table(args)


if __name__ == "__main__":
    raise SystemExit(main())
