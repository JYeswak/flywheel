#!/usr/bin/env python3
"""Validate the ZestStream holding-company Yuzu owner-operator voice ledger."""

from __future__ import annotations

import argparse
import json
import re
import sys
from pathlib import Path
from typing import Any

from jsonschema import Draft202012Validator, FormatChecker


ROOT = Path(__file__).resolve().parents[2]
DEFAULT_SCHEMA = ROOT / ".flywheel/validation-schema/v1/holding-company-owner-voice.schema.json"
DEFAULT_LEDGER = ROOT / "state/holding-company-owner-voice.json"
REQUIRED_REFS = [
    "owner_operator_ref",
    "owner_voice_ref",
    "community_context_ref",
    "yuzu_review_ref",
    "public_surface_ref",
]
SECRETISH_RE = re.compile(r"(\$[0-9]|sk-[A-Za-z0-9]|AKIA[0-9A-Z]{16})")


def load_json(path: Path) -> Any:
    with path.open("r", encoding="utf-8") as handle:
        return json.load(handle)


def ref_exists(ref: str) -> bool:
    if "://" in ref or ref.startswith("urn:"):
        return True
    path = Path(ref)
    if not path.is_absolute():
        path = ROOT / path
    return path.exists()


def has_secretish_string(value: Any) -> bool:
    if isinstance(value, str):
        return bool(SECRETISH_RE.search(value))
    if isinstance(value, dict):
        return any(has_secretish_string(v) for v in value.values())
    if isinstance(value, list):
        return any(has_secretish_string(v) for v in value)
    return False


def has_ref(value: Any) -> bool:
    return isinstance(value, str) and bool(value.strip())


def validate_ledger(ledger: dict[str, Any], schema: dict[str, Any], *, check_paths: bool) -> dict[str, Any]:
    failures: list[dict[str, Any]] = []
    try:
        Draft202012Validator.check_schema(schema)
        Draft202012Validator(schema, format_checker=FormatChecker()).validate(ledger)
    except Exception as exc:
        failures.append({"code": "schema_invalid", "detail": str(exc)})

    surface_results: list[dict[str, Any]] = []
    computed_clear_count = 0

    for surface in ledger.get("surfaces", []):
        if not isinstance(surface, dict):
            continue
        surface_id = surface.get("surface_id")
        status = surface.get("status")
        missing_refs = [field for field in REQUIRED_REFS if not has_ref(surface.get(field))]
        surface_failures: list[dict[str, Any]] = []

        voice_clear = (
            status == "clear"
            and not missing_refs
            and surface.get("owner_voice_present") is True
            and surface.get("community_context_present") is True
            and surface.get("zeststream_meta_voice_detected") is False
        )

        if status == "clear" and missing_refs:
            surface_failures.append({"code": "owner_voice_clear_missing_refs", "missing_refs": missing_refs})
        if status == "clear" and surface.get("owner_voice_present") is not True:
            surface_failures.append({"code": "owner_voice_clear_without_owner_voice"})
        if status == "clear" and surface.get("community_context_present") is not True:
            surface_failures.append({"code": "owner_voice_clear_without_community_context"})
        if status == "clear" and surface.get("zeststream_meta_voice_detected") is not False:
            surface_failures.append({"code": "owner_voice_clear_with_zeststream_meta_voice"})
        if has_secretish_string(surface):
            surface_failures.append({"code": "secret_or_raw_amount_shape_detected"})

        if check_paths:
            for field in REQUIRED_REFS:
                ref = surface.get(field)
                if isinstance(ref, str) and not ref_exists(ref):
                    surface_failures.append({"code": "required_ref_missing", "field": field, "ref": ref})
            for ref in surface.get("evidence_refs", []):
                if isinstance(ref, str) and not ref_exists(ref):
                    surface_failures.append({"code": "evidence_ref_missing", "ref": ref})

        if voice_clear and not surface_failures:
            computed_clear_count += 1
        for failure in surface_failures:
            failures.append({"surface_id": surface_id, **failure})

        surface_results.append(
            {
                "surface_id": surface_id,
                "company_slug": surface.get("company_slug"),
                "status": status,
                "owner_voice_present": surface.get("owner_voice_present"),
                "community_context_present": surface.get("community_context_present"),
                "zeststream_meta_voice_detected": surface.get("zeststream_meta_voice_detected"),
                "missing_refs": missing_refs,
                "owner_voice_gate_status": "clear" if voice_clear and not surface_failures else "blocked",
                "failures": surface_failures,
            }
        )

    claimed_clear_count = ledger.get("clear_count")
    if claimed_clear_count != computed_clear_count:
        failures.append({"code": "clear_count_mismatch", "claimed": claimed_clear_count, "computed": computed_clear_count})

    return {
        "schema_version": "zeststream.holding_company_owner_voice.validation.v1",
        "status": "fail" if failures else "pass",
        "gate": ledger.get("gate"),
        "clear_count": computed_clear_count,
        "surface_count": len(surface_results),
        "surfaces": surface_results,
        "failures": failures,
    }


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--ledger", type=Path, default=DEFAULT_LEDGER)
    parser.add_argument("--schema", type=Path, default=DEFAULT_SCHEMA)
    parser.add_argument("--check-paths", action="store_true")
    parser.add_argument("--json", action="store_true")
    args = parser.parse_args()

    result = validate_ledger(load_json(args.ledger), load_json(args.schema), check_paths=args.check_paths)
    if args.json:
        print(json.dumps(result, indent=2, sort_keys=True))
    else:
        print("status={status} clear_count={clear_count} surface_count={surface_count}".format(**result))
        for failure in result["failures"]:
            print(f"FAIL {failure}")
    return 0 if result["status"] == "pass" else 1


if __name__ == "__main__":
    sys.exit(main())
