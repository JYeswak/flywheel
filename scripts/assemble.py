#!/usr/bin/env python3
"""Assemble a public Flywheel staging tree from classified source files."""

from __future__ import annotations

import argparse
import hashlib
import json
import shutil
import subprocess
import sys
from datetime import datetime, timezone
from pathlib import Path
from typing import Iterable

SCRIPT_DIR = Path(__file__).resolve().parent
if str(SCRIPT_DIR) not in sys.path:
    sys.path.insert(0, str(SCRIPT_DIR))

from classify import SCHEMA_VERSION as CLASSIFY_SCHEMA_VERSION  # noqa: E402
from classify import classify_root  # noqa: E402
from depersonalize import (  # noqa: E402
    DEFAULT_DENYLIST,
    DEFAULT_IGNORED_DIR_NAMES,
    DEFAULT_TABLE,
    DenyRow,
    load_replacement_table,
    load_denylist,
    repo_root,
    row_matches,
    transform_text,
)

SCHEMA_VERSION = "flywheel.assembly.v0"
MARKER_NAME = ".flywheel-assembly-staging.json"
EXIT_UNSAFE_STAGING = 42
EXIT_CLASSIFICATION = 43


def utc_run_id() -> str:
    return datetime.now(timezone.utc).strftime("%Y%m%dT%H%M%SZ")


def emit(payload: dict[str, object], json_out: bool) -> None:
    if json_out:
        print(json.dumps(payload, sort_keys=True))
        return
    print(f"status={payload['status']} copied={payload.get('copied_count', 0)}")


def git_status(path: Path) -> list[str] | None:
    result = subprocess.run(
        ["git", "-C", str(path), "status", "--porcelain"],
        check=False,
        text=True,
        stdout=subprocess.PIPE,
        stderr=subprocess.DEVNULL,
    )
    if result.returncode != 0:
        return None
    return [line for line in result.stdout.splitlines() if line]


def sha256_file(path: Path) -> str:
    digest = hashlib.sha256()
    with path.open("rb") as handle:
        for chunk in iter(lambda: handle.read(1024 * 1024), b""):
            digest.update(chunk)
    return digest.hexdigest()


def safe_relpath(value: object) -> str:
    relpath = str(value)
    path = Path(relpath)
    if path.is_absolute() or ".." in path.parts:
        raise ValueError(f"unsafe classified path: {relpath}")
    return relpath


def prepare_staging(path: Path, clean: bool) -> None:
    marker = path / MARKER_NAME
    if path.exists():
        if not clean:
            raise RuntimeError(f"staging path already exists: {path}")
        if not marker.exists():
            raise RuntimeError(f"refusing to clean unmarked staging path: {path}")
        shutil.rmtree(path)
    path.mkdir(parents=True, exist_ok=True)


def load_classification(path: Path) -> list[dict[str, object]]:
    rows: list[dict[str, object]] = []
    with path.open("r", encoding="utf-8") as handle:
        for line_no, line in enumerate(handle, start=1):
            if not line.strip():
                continue
            row = json.loads(line)
            if row.get("schema_version") != CLASSIFY_SCHEMA_VERSION:
                raise ValueError(f"classification row {line_no} has wrong schema")
            if not row.get("class") or not row.get("path"):
                raise ValueError(f"classification row {line_no} is incomplete")
            rows.append(row)
    return rows


def is_generated_extraction_path(row: dict[str, object]) -> bool:
    return str(row.get("path", "")).startswith(".flywheel/extraction/")


def filter_generated_extraction_rows(
    rows: list[dict[str, object]],
) -> list[dict[str, object]]:
    return [row for row in rows if not is_generated_extraction_path(row)]


def write_jsonl(path: Path, rows: Iterable[dict[str, object]]) -> int:
    path.parent.mkdir(parents=True, exist_ok=True)
    count = 0
    with path.open("w", encoding="utf-8") as handle:
        for row in rows:
            handle.write(json.dumps(row, sort_keys=True, separators=(",", ":")) + "\n")
            count += 1
    return count


def copy_and_rewrite(
    source: Path,
    staging: Path,
    rows: list[dict[str, object]],
    table_path: Path,
    deny_rows: list[DenyRow],
) -> tuple[list[dict[str, object]], list[dict[str, object]]]:
    table_rows = load_replacement_table(table_path)
    copied: list[dict[str, object]] = []
    manual_review: list[dict[str, object]] = []
    for row in rows:
        artifact_class = str(row["class"])
        relpath = safe_relpath(row["path"])
        deny_match = next((deny for deny in deny_rows if row_matches(deny, relpath)), None)
        if deny_match:
            if deny_match.decision == "manual-review":
                manual_review.append(
                    {
                        "path": relpath,
                        "class": artifact_class,
                        "reason": f"denylist:{deny_match.id}",
                        "rewrite_required": row.get("rewrite_required", []),
                        "signed_off_by": None,
                    }
                )
            continue
        if artifact_class == "overlay":
            continue
        if artifact_class not in {"engine", "engine-after-rewrite"}:
            raise ValueError(f"unsupported class for {relpath}: {artifact_class}")
        src = source / relpath
        dst = staging / relpath
        dst.parent.mkdir(parents=True, exist_ok=True)
        shutil.copy2(src, dst)
        rewrite_rows: list[str] = []
        try:
            text = dst.read_text(encoding="utf-8")
        except UnicodeDecodeError:
            text = ""
        if text:
            requested_row_ids = set(row.get("rewrite_required", []))
            requested_rows = [row for row in table_rows if row.id in requested_row_ids]
            if requested_rows:
                transformed, rewrite_rows = transform_text(text, requested_rows)
                if transformed != text:
                    dst.write_text(transformed, encoding="utf-8")
        copied.append(
            {
                "path": relpath,
                "class": artifact_class,
                "reason": row.get("reason"),
                "rewrite_rows": rewrite_rows,
                "sha256": sha256_file(dst),
            }
        )
        if row.get("manual_review_recommended"):
            manual_review.append(
                {
                    "path": relpath,
                    "class": artifact_class,
                    "reason": row.get("reason"),
                    "rewrite_required": row.get("rewrite_required", []),
                    "signed_off_by": None,
                }
            )
    return copied, manual_review


def resolve_path(value: str, root: Path) -> Path:
    path = Path(value)
    return path if path.is_absolute() else root / path


def main(argv: list[str] | None = None) -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--source", "--root", dest="source", default=".")
    parser.add_argument("--staging", default=".flywheel/extraction/staging")
    parser.add_argument("--run-root", default=".flywheel/extraction")
    parser.add_argument("--run-id", default=utc_run_id())
    parser.add_argument("--table", default=str(repo_root() / DEFAULT_TABLE))
    parser.add_argument("--denylist", default=str(repo_root() / DEFAULT_DENYLIST))
    parser.add_argument("--classification")
    parser.add_argument("--json", action="store_true")
    parser.add_argument("--clean", action="store_true")
    parser.add_argument(
        "--include-ignored-dirs",
        action="store_true",
        help="include dependency/cache/build directories skipped by default",
    )
    args = parser.parse_args(argv)

    source = Path(args.source).resolve()
    run_root = resolve_path(args.run_root, source).resolve()
    staging = resolve_path(args.staging, source).resolve()
    table_path = Path(args.table)
    if not table_path.is_absolute():
        table_path = repo_root() / table_path
    denylist_path = Path(args.denylist)
    if not denylist_path.is_absolute():
        denylist_path = repo_root() / denylist_path
    deny_rows = load_denylist(denylist_path)
    ignored_dir_names = set() if args.include_ignored_dirs else DEFAULT_IGNORED_DIR_NAMES
    status_before = git_status(source)

    try:
        prepare_staging(staging, args.clean)
        if args.classification:
            classification_path = resolve_path(args.classification, source).resolve()
            classification_rows = filter_generated_extraction_rows(
                load_classification(classification_path)
            )
        else:
            classification_rows = filter_generated_extraction_rows(
                classify_root(source, table_path, ignored_dir_names)
            )
            classification_path = run_root / "classification-runs" / args.run_id / "classification.jsonl"
            write_jsonl(classification_path, classification_rows)
        copied, manual_review = copy_and_rewrite(
            source, staging, classification_rows, table_path, deny_rows
        )
    except (OSError, RuntimeError, ValueError, json.JSONDecodeError) as exc:
        payload = {
            "schema_version": SCHEMA_VERSION,
            "status": "fail",
            "error": str(exc),
            "exit_code": EXIT_UNSAFE_STAGING,
        }
        emit(payload, args.json)
        return EXIT_UNSAFE_STAGING

    manifest_path = run_root / "assembly-runs" / args.run_id / "manifest.json"
    manual_review_path = (
        run_root / "manual-review-queue" / args.run_id / "manual-review.jsonl"
    )
    marker = staging / MARKER_NAME
    status_after = git_status(source)
    manifest = {
        "schema_version": SCHEMA_VERSION,
        "run_id": args.run_id,
        "source": str(source),
        "staging": str(staging),
        "classification_path": str(classification_path),
        "manual_review_path": str(manual_review_path),
        "copied_count": len(copied),
        "manual_review_count": len(manual_review),
        "overlay_count": sum(1 for row in classification_rows if row.get("class") == "overlay"),
        "denylist_excluded_count": sum(
            1
            for row in classification_rows
            if any(row_matches(deny, str(row.get("path", ""))) for deny in deny_rows)
        ),
        "source_git_status_before": status_before,
        "source_git_status_after": status_after,
        "source_git_status_unchanged": status_before == status_after,
        "files": copied,
    }
    manifest_path.parent.mkdir(parents=True, exist_ok=True)
    manifest_path.write_text(
        json.dumps(manifest, indent=2, sort_keys=True) + "\n", encoding="utf-8"
    )
    marker.write_text(
        json.dumps(
            {
                "schema_version": SCHEMA_VERSION,
                "run_id": args.run_id,
            },
            sort_keys=True,
        )
        + "\n",
        encoding="utf-8",
    )
    manual_review_count = write_jsonl(manual_review_path, manual_review)
    payload = {
        "schema_version": SCHEMA_VERSION,
        "status": "pass",
        "exit_code": 0,
        "run_id": args.run_id,
        "source": str(source),
        "staging": str(staging),
        "classification_path": str(classification_path),
        "manifest_path": str(manifest_path),
        "manual_review_path": str(manual_review_path),
        "classification_count": len(classification_rows),
        "copied_count": len(copied),
        "overlay_count": manifest["overlay_count"],
        "denylist_excluded_count": manifest["denylist_excluded_count"],
        "manual_review_count": manual_review_count,
        "source_git_status_unchanged": status_before == status_after,
    }
    emit(payload, args.json)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
