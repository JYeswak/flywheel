#!/usr/bin/env python3
"""Classify Flywheel extraction candidates as engine, overlay, or rewrite."""

from __future__ import annotations

import argparse
import fnmatch
import json
import os
import re
import sys
from collections import Counter
from pathlib import Path
from typing import Iterable

SCRIPT_DIR = Path(__file__).resolve().parent
if str(SCRIPT_DIR) not in sys.path:
    sys.path.insert(0, str(SCRIPT_DIR))

from depersonalize import (  # noqa: E402
    DEFAULT_IGNORED_DIR_NAMES,
    DEFAULT_TABLE,
    TEXT_FILE_SUFFIXES,
    load_replacement_table,
    repo_root,
    row_pattern,
    ReplacementRow,
)

SCHEMA_VERSION = "flywheel.classification.v0"
VALID_CLASSES = {"engine", "overlay", "engine-after-rewrite"}
OVERLAY_PATH_PATTERNS = (
    ".ntm/**",
    ".beads/**",
    ".flywheel/PLANS/**",
    ".flywheel/audit/**",
    ".flywheel/evidence/**",
    ".flywheel/receipts/**",
    ".flywheel/handoffs/**",
    ".flywheel/extraction/**",
    "**/state.db",
    "**/state.db-shm",
    "**/state.db-wal",
    "**/beads.db",
    "**/beads.db-shm",
    "**/beads.db-wal",
    "**/dispatch-log.jsonl",
    "**/issues.jsonl",
)
GENERATED_EXTRACTION_PATH_PREFIX = ".flywheel/extraction/"
OVERLAY_CONTENT_PATTERNS = (
    ("credential_shape", re.compile(r"\b(AKIA[0-9A-Z]{16}|eyJ[A-Za-z0-9_-]{20,})\b")),
    ("secret_assignment", re.compile(r"\b[A-Z0-9_]*(TOKEN|SECRET|PASSWORD|KEY)\s*=")),
)
PRIVATE_STATE_MARKER = re.compile(r"\b(live pane state|dispatch log|handoff history)\b", re.I)
PUBLIC_REQUIRED_ENGINE_FILES = {"README.md", "ARCHITECTURE.md", "scripts/classify.py"}
INCIDENT_MARKERS = re.compile(
    r"\b(incident|postmortem|handoff|receipt|rollback|operator-specific|client-specific)\b",
    re.I,
)


def path_pattern_matches(pattern: str, relpath: str) -> bool:
    if fnmatch.fnmatchcase(relpath, pattern):
        return True
    if pattern.startswith("**/") and fnmatch.fnmatchcase(relpath, pattern[3:]):
        return True
    return False


def iter_paths(root: Path, ignored_dir_names: set[str]) -> Iterable[tuple[str, Path]]:
    if root.is_file():
        yield root.name, root
        return
    for dirpath, dirnames, filenames in os.walk(root):
        dirnames[:] = sorted(d for d in dirnames if d not in ignored_dir_names)
        rel_dir = Path(dirpath).relative_to(root).as_posix()
        if rel_dir == ".flywheel":
            dirnames[:] = [d for d in dirnames if d != "extraction"]
        for name in sorted(filenames):
            path = Path(dirpath, name)
            relpath = path.relative_to(root).as_posix()
            if relpath.startswith(GENERATED_EXTRACTION_PATH_PREFIX):
                continue
            if path.suffix not in TEXT_FILE_SUFFIXES:
                continue
            yield relpath, path


def compile_rewrite_patterns(table_path: Path) -> list[tuple[ReplacementRow, re.Pattern[str]]]:
    return [(row, row_pattern(row)) for row in load_replacement_table(table_path)]


def matched_rewrite_rows(
    text: str, compiled_patterns: list[tuple[ReplacementRow, re.Pattern[str]]]
) -> list[str]:
    return sorted({row.id for row, pattern in compiled_patterns if pattern.search(text)})


def classify_path(relpath: str) -> tuple[str | None, str | None]:
    for pattern in OVERLAY_PATH_PATTERNS:
        if path_pattern_matches(pattern, relpath):
            return "overlay", f"path:{pattern}"
    return None, None


def classify_content(
    relpath: str, text: str, rewrite_rows: list[str]
) -> tuple[str, str, bool, list[str]]:
    for signal, pattern in OVERLAY_CONTENT_PATTERNS:
        if pattern.search(text):
            return "overlay", signal, True, []
    if PRIVATE_STATE_MARKER.search(text) and relpath not in PUBLIC_REQUIRED_ENGINE_FILES:
        return "overlay", "private_state_marker", True, []
    if rewrite_rows:
        review = bool(INCIDENT_MARKERS.search(text)) or len(rewrite_rows) >= 3
        return "engine-after-rewrite", "mode_a_codemod_sufficient", review, rewrite_rows
    if INCIDENT_MARKERS.search(text):
        return "engine-after-rewrite", "mode_b_pattern_rewrite_required", True, []
    return "engine", "passes_pure_pattern_filter", False, []


def classify_file(
    root: Path,
    relpath: str,
    path: Path,
    compiled_patterns: list[tuple[ReplacementRow, re.Pattern[str]]],
) -> dict[str, object]:
    path_class, path_reason = classify_path(relpath)
    if path_class:
        return {
            "schema_version": SCHEMA_VERSION,
            "path": relpath,
            "class": path_class,
            "reason": path_reason or "path_overlay",
            "manual_review_recommended": True,
            "rewrite_required": [],
            "signals": {
                "root": root.as_posix(),
                "rewrite_row_count": 0,
            },
        }
    try:
        text = path.read_text(encoding="utf-8")
    except UnicodeDecodeError:
        text = ""
    rewrite_rows = matched_rewrite_rows(text, compiled_patterns)
    artifact_class, reason, manual_review, rewrite_required = classify_content(
        relpath, text, rewrite_rows
    )
    if artifact_class not in VALID_CLASSES:
        artifact_class = "engine-after-rewrite"
        reason = "classifier_fallback"
        manual_review = True
    return {
        "schema_version": SCHEMA_VERSION,
        "path": relpath,
        "class": artifact_class,
        "reason": reason,
        "manual_review_recommended": manual_review,
        "rewrite_required": rewrite_required,
        "signals": {
            "root": root.as_posix(),
            "rewrite_row_count": len(rewrite_rows),
        },
    }


def classify_root(root: Path, table_path: Path, ignored_dir_names: set[str]) -> list[dict[str, object]]:
    compiled_patterns = compile_rewrite_patterns(table_path)
    return [
        classify_file(root, relpath, path, compiled_patterns)
        for relpath, path in iter_paths(root, ignored_dir_names)
    ]


def write_jsonl(rows: list[dict[str, object]], output: Path | None) -> None:
    handle = output.open("w", encoding="utf-8") if output else sys.stdout
    try:
        for row in rows:
            handle.write(json.dumps(row, sort_keys=True, separators=(",", ":")) + "\n")
    finally:
        if output:
            handle.close()


def summary(rows: list[dict[str, object]], output: Path | None) -> dict[str, object]:
    class_counts = Counter(str(row.get("class")) for row in rows)
    null_class_count = sum(1 for row in rows if not row.get("class"))
    manual_review_count = sum(1 for row in rows if row.get("manual_review_recommended"))
    return {
        "schema_version": SCHEMA_VERSION,
        "status": "fail" if null_class_count else "pass",
        "output": str(output) if output else "<stdout>",
        "total_files": len(rows),
        "null_class_count": null_class_count,
        "class_counts": dict(sorted(class_counts.items())),
        "manual_review_count": manual_review_count,
    }


def self_test(args: argparse.Namespace) -> int:
    fixture = Path(args.fixture).resolve()
    rows = classify_root(fixture, Path(args.table).resolve(), DEFAULT_IGNORED_DIR_NAMES)
    errors: list[str] = []
    if len(rows) != 22:
        errors.append(f"expected 22 fixture rows, got {len(rows)}")
    if any(not row.get("class") for row in rows):
        errors.append("fixture emitted null class")
    classes = {row["class"] for row in rows}
    if classes != VALID_CLASSES:
        errors.append(f"expected classes {sorted(VALID_CLASSES)}, got {sorted(classes)}")
    payload = summary(rows, None)
    payload["status"] = "fail" if errors else "pass"
    payload["fixture"] = str(fixture)
    payload["errors"] = errors
    print(json.dumps(payload, sort_keys=True, separators=(",", ":")))
    return 1 if errors else 0


def main(argv: list[str] | None = None) -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--root", default=".")
    parser.add_argument("--table", default=str(repo_root() / DEFAULT_TABLE))
    parser.add_argument("--output")
    parser.add_argument("--json", action="store_true", help="emit summary JSON to stdout")
    parser.add_argument("--self-test", action="store_true")
    parser.add_argument("--fixture", default="fixtures/classify/source")
    parser.add_argument(
        "--include-ignored-dirs",
        action="store_true",
        help="include dependency/cache/build directories skipped by default",
    )
    args = parser.parse_args(argv)

    table_path = Path(args.table)
    if not table_path.is_absolute():
        table_path = repo_root() / table_path
    args.table = str(table_path)
    if args.self_test:
        return self_test(args)

    root = Path(args.root).resolve()
    ignored_dir_names = set() if args.include_ignored_dirs else DEFAULT_IGNORED_DIR_NAMES
    rows = classify_root(root, table_path, ignored_dir_names)
    output = Path(args.output).resolve() if args.output else None
    if output or not args.json:
        write_jsonl(rows, output)
    if args.json:
        print(json.dumps(summary(rows, output), sort_keys=True, separators=(",", ":")))
    return 1 if any(not row.get("class") for row in rows) else 0


if __name__ == "__main__":
    raise SystemExit(main())
