#!/usr/bin/env python3
"""Validate the public user journey pack contract."""

from __future__ import annotations

import argparse
import html
import json
import re
import sys
from pathlib import Path
from typing import Any


SCHEMA_VERSION = "flywheel.public_user_journey_pack.v0"
SOURCE_PACK_ID = "user-journey-wireframe-pack"
TABLE_HEADING = "## Machine-Readable Journey Rows"
REQUIRED_COLUMNS = [
    "asset_id",
    "persona_lane",
    "journey_stage",
    "entrypoint",
    "visible_wording",
    "visual_cue",
    "primary_cta",
    "required_proof_refs",
    "signoff_status",
    "blocker_or_skip_receipt_ref",
    "source_pack_id",
]
JOURNEY_STAGES = {"trigger", "orient", "decide", "act", "recover", "retain"}
PRIVATE_PATTERNS = [
    re.compile(r"/Users/josh"),
    re.compile(re.escape("$HOME")),
    re.compile(r"\bBlackfoot\b", re.IGNORECASE),
    re.compile(r"\bALPS\b"),
    re.compile(r"\bTerraTitle\b", re.IGNORECASE),
]


def clean_cell(value: str) -> str:
    value = value.strip()
    value = re.sub(r"<br\s*/?>", ", ", value, flags=re.IGNORECASE)
    value = re.sub(r"`([^`]*)`", r"\1", value)
    value = re.sub(r"\[([^\]]+)\]\([^)]+\)", r"\1", value)
    value = re.sub(r"<[^>]+>", "", value)
    return html.unescape(value).strip()


def add_error(
    errors: list[dict[str, str]],
    code: str,
    message: str,
    row: str | None = None,
    field: str | None = None,
) -> None:
    error = {"code": code, "message": message}
    if row:
        error["row"] = row
    if field:
        error["field"] = field
    errors.append(error)


def split_refs(value: str) -> list[str]:
    return [ref.strip() for ref in value.split(";") if ref.strip()]


def ref_exists(repo_root: Path, ref: str) -> bool:
    normalized = ref.strip()
    if not normalized:
        return False
    if normalized.startswith(("http://", "https://", "mailto:")):
        return True
    if normalized.startswith("python3 "):
        normalized = normalized.split(maxsplit=1)[1]
    normalized = normalized.split()[0]
    return (repo_root / normalized).exists()


def parse_table(text: str, errors: list[dict[str, str]]) -> list[dict[str, str]]:
    lines = text.splitlines()
    try:
        start = lines.index(TABLE_HEADING)
    except ValueError:
        add_error(errors, "JOURNEY_SPEC_MISSING", f"missing heading {TABLE_HEADING}")
        return []

    header_index = None
    for index in range(start + 1, len(lines)):
        if lines[index].strip().startswith("|"):
            header_index = index
            break
    if header_index is None or header_index + 1 >= len(lines):
        add_error(errors, "JOURNEY_SPEC_MISSING", "missing journey table")
        return []

    headers = [clean_cell(cell) for cell in lines[header_index].strip().strip("|").split("|")]
    missing_columns = [column for column in REQUIRED_COLUMNS if column not in headers]
    if missing_columns:
        add_error(
            errors,
            "JOURNEY_SPEC_MISSING",
            f"missing required columns: {', '.join(missing_columns)}",
        )
        return []

    rows: list[dict[str, str]] = []
    for line in lines[header_index + 2 :]:
        stripped = line.strip()
        if not stripped.startswith("|"):
            break
        cells = [clean_cell(cell) for cell in stripped.strip("|").split("|")]
        if len(cells) != len(headers):
            add_error(errors, "JOURNEY_SPEC_MISSING", "row has wrong cell count")
            continue
        rows.append(dict(zip(headers, cells, strict=True)))

    if not rows:
        add_error(errors, "JOURNEY_SPEC_MISSING", "journey table has no rows")
    return rows


def validate(path: Path) -> dict[str, Any]:
    repo_root = Path(__file__).resolve().parents[1]
    text = path.read_text(encoding="utf-8")
    errors: list[dict[str, str]] = []

    if f"Schema: `{SCHEMA_VERSION}`" not in text:
        add_error(errors, "JOURNEY_SPEC_MISSING", "missing expected schema version")
    if SOURCE_PACK_ID not in text:
        add_error(errors, "JOURNEY_SPEC_MISSING", "missing source_pack_id")
    for pattern in PRIVATE_PATTERNS:
        if pattern.search(text):
            add_error(errors, "PRIVATE_STATE_LEAK", f"private marker matched: {pattern.pattern}")

    rows = parse_table(text, errors)
    seen_assets: set[str] = set()
    for row in rows:
        row_id = row.get("asset_id", "unknown")
        if row_id in seen_assets:
            add_error(errors, "JOURNEY_SPEC_MISSING", "duplicate asset_id", row_id, "asset_id")
        seen_assets.add(row_id)

        for column in REQUIRED_COLUMNS:
            if not row.get(column):
                code = "JOURNEY_SPEC_MISSING"
                if column == "visual_cue":
                    code = "STEP_VISUAL_CUE_MISSING"
                elif column in {"entrypoint", "primary_cta", "blocker_or_skip_receipt_ref"}:
                    code = "E2E_MAPPING_MISSING"
                elif column == "required_proof_refs":
                    code = "CLAIM_WITHOUT_EVIDENCE"
                add_error(errors, code, f"missing {column}", row_id, column)

        if row.get("journey_stage") not in JOURNEY_STAGES:
            add_error(errors, "JOURNEY_SPEC_MISSING", "invalid journey_stage", row_id, "journey_stage")
        if row.get("source_pack_id") != SOURCE_PACK_ID:
            add_error(errors, "JOURNEY_SPEC_MISSING", "invalid source_pack_id", row_id, "source_pack_id")
        if row.get("required_proof_refs", "").lower() in {"none", "n/a", "na"}:
            add_error(errors, "CLAIM_WITHOUT_EVIDENCE", "required_proof_refs cannot be empty", row_id, "required_proof_refs")
        for proof_ref in split_refs(row.get("required_proof_refs", "")):
            if not ref_exists(repo_root, proof_ref):
                add_error(
                    errors,
                    "CLAIM_WITHOUT_EVIDENCE",
                    f"required proof ref does not exist: {proof_ref}",
                    row_id,
                    "required_proof_refs",
                )
        blocker_ref = row.get("blocker_or_skip_receipt_ref", "")
        if blocker_ref and not ref_exists(repo_root, blocker_ref):
            add_error(
                errors,
                "E2E_MAPPING_MISSING",
                f"blocker_or_skip_receipt_ref does not exist: {blocker_ref}",
                row_id,
                "blocker_or_skip_receipt_ref",
            )

    return {
        "schema_version": SCHEMA_VERSION,
        "status": "pass" if not errors else "fail",
        "path": str(path),
        "row_count": len(rows),
        "errors": errors,
    }


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--pack", default="docs/runbooks/public-user-journey-pack.md")
    parser.add_argument("--json", action="store_true")
    args = parser.parse_args()

    result = validate(Path(args.pack))
    if args.json:
        print(json.dumps(result, sort_keys=True))
    else:
        print(f"status={result['status']} row_count={result['row_count']}")
        for error in result["errors"]:
            print(f"{error['code']}: {error.get('row', '-')}: {error['message']}", file=sys.stderr)
    return 0 if result["status"] == "pass" else 1


if __name__ == "__main__":
    raise SystemExit(main())
