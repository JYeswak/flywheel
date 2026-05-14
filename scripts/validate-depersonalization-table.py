#!/usr/bin/env python3
"""Validate Flywheel's source-side de-personalization table."""

from __future__ import annotations

import json
import re
import sys
from pathlib import Path
from typing import Any

SCHEMA_VERSION = "flywheel.depersonalization_table.v0"
REQUIRED_FIELDS = {
    "id",
    "class",
    "private_value",
    "match_type",
    "action",
    "public_value",
    "risk",
    "utility_impact",
    "residual_risk",
    "review_required",
    "notes",
}
MATCH_TYPES = {"literal", "regex", "path-prefix", "glob"}
ACTIONS = {"replace", "redact", "generalize", "drop", "manual-review"}
RISKS = {
    "direct_identifier",
    "quasi_identifier",
    "client_confidentiality",
    "credential",
    "live_state",
    "relationship_identifier",
    "linkage_identifier",
}
LEVELS = {"low", "medium", "high"}
SCHEMA_PATH = Path("scripts/de-personalization-table.schema.json")
TABLE_PATH = Path("de-personalization-table.yaml")


def strip_yaml_value(value: str) -> Any:
    value = value.strip()
    if value in {"true", "false"}:
        return value == "true"
    if len(value) >= 2 and value[0] == value[-1] == '"':
        return value[1:-1]
    return value


def load_table(path: Path) -> dict[str, Any]:
    rows: list[dict[str, Any]] = []
    current: dict[str, Any] | None = None
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
            raise ValueError(f"unexpected top-level line: {raw_line}")
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
            raise ValueError(f"malformed row near: {raw_line}")
        key, value = stripped.split(":", 1)
        current[key.strip()] = strip_yaml_value(value)
    if current is not None:
        rows.append(current)
    return {"schema_version": schema_version, "rows": rows}


def validate_schema_file(path: Path) -> list[str]:
    errors: list[str] = []
    try:
        schema = json.loads(path.read_text(encoding="utf-8"))
    except (OSError, json.JSONDecodeError) as exc:
        return [f"schema file invalid: {exc}"]
    if schema.get("properties", {}).get("schema_version", {}).get("const") != SCHEMA_VERSION:
        errors.append("schema const does not match table schema_version")
    required = set(schema.get("properties", {}).get("rows", {}).get("items", {}).get("required", []))
    missing = sorted(REQUIRED_FIELDS - required)
    if missing:
        errors.append(f"schema missing required row fields: {missing}")
    return errors


def validate_table(table: dict[str, Any]) -> list[str]:
    errors: list[str] = []
    if table.get("schema_version") != SCHEMA_VERSION:
        errors.append("unsupported schema_version")
    rows = table.get("rows")
    if not isinstance(rows, list) or not rows:
        errors.append("rows must be a non-empty list")
        return errors
    seen_ids: set[str] = set()
    seen_values: set[str] = set()
    for index, row in enumerate(rows, start=1):
        row_id = str(row.get("id", f"row-{index}"))
        missing = sorted(REQUIRED_FIELDS - set(row))
        if missing:
            errors.append(f"{row_id}: missing fields {missing}")
            continue
        if not re.fullmatch(r"[a-z0-9][a-z0-9-]*", row_id):
            errors.append(f"{row_id}: invalid id")
        if row_id in seen_ids:
            errors.append(f"{row_id}: duplicate id")
        seen_ids.add(row_id)
        private_value = row["private_value"]
        if not isinstance(private_value, str) or not private_value:
            errors.append(f"{row_id}: private_value must be non-empty string")
        if private_value in seen_values:
            errors.append(f"{row_id}: duplicate private_value")
        seen_values.add(private_value)
        if row["match_type"] not in MATCH_TYPES:
            errors.append(f"{row_id}: invalid match_type")
        if row["action"] not in ACTIONS:
            errors.append(f"{row_id}: invalid action")
        if row["risk"] not in RISKS:
            errors.append(f"{row_id}: invalid risk")
        if row["utility_impact"] not in LEVELS:
            errors.append(f"{row_id}: invalid utility_impact")
        if row["residual_risk"] not in LEVELS:
            errors.append(f"{row_id}: invalid residual_risk")
        if not isinstance(row["review_required"], bool):
            errors.append(f"{row_id}: review_required must be boolean")
        if row["match_type"] == "regex":
            try:
                re.compile(private_value)
            except re.error as exc:
                errors.append(f"{row_id}: invalid regex: {exc}")
        if row["risk"] in {"client_confidentiality", "credential"} and row["review_required"] is not True:
            errors.append(f"{row_id}: high-risk rows must require review")
    return errors


def main() -> int:
    table_path = Path(sys.argv[1]) if len(sys.argv) > 1 else TABLE_PATH
    schema_path = Path(sys.argv[2]) if len(sys.argv) > 2 else SCHEMA_PATH
    errors = validate_schema_file(schema_path)
    try:
        table = load_table(table_path)
    except (OSError, ValueError) as exc:
        errors.append(f"table file invalid: {exc}")
        table = {"rows": []}
    errors.extend(validate_table(table))
    payload = {
        "schema_version": "flywheel.depersonalization_table_validation.v0",
        "status": "fail" if errors else "pass",
        "table": str(table_path),
        "schema": str(schema_path),
        "rows": len(table.get("rows", [])),
        "errors": errors,
    }
    print(json.dumps(payload, indent=2, sort_keys=True))
    return 1 if errors else 0


if __name__ == "__main__":
    raise SystemExit(main())
