#!/usr/bin/env python3
"""Validate the ZestStream holding-company PRESS readiness ledger."""

from __future__ import annotations

import argparse
import json
import re
import sys
from pathlib import Path
from typing import Any

from jsonschema import Draft202012Validator, FormatChecker


ROOT = Path(__file__).resolve().parents[2]
DEFAULT_SCHEMA = ROOT / ".flywheel/validation-schema/v1/holding-company-press-readiness.schema.json"
DEFAULT_LEDGER = ROOT / "state/holding-company-press-readiness.json"
CLEAR_STATUSES = {"press_clear", "formation_ready"}
REQUIRED_REFS = [
    "candidate_fit_ref",
    "v0_1_release_ref",
    "skillos_hardening_ref",
    "flywheel_coordination_ref",
    "package_delivery_ref",
    "yuzu_owner_voice_ref",
    "signed_equity_ref",
    "owner_economics_ref",
    "substrate_share_receipt",
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


def release_version_ok(value: Any) -> bool:
    return isinstance(value, str) and (value == "v0.1" or value.startswith("v0.1."))


def validate_ledger(ledger: dict[str, Any], schema: dict[str, Any], *, check_paths: bool) -> dict[str, Any]:
    failures: list[dict[str, Any]] = []
    try:
        Draft202012Validator.check_schema(schema)
        Draft202012Validator(schema, format_checker=FormatChecker()).validate(ledger)
    except Exception as exc:
        failures.append({"code": "schema_invalid", "detail": str(exc)})

    press_results: list[dict[str, Any]] = []
    computed_clear_count = 0

    for press in ledger.get("presses", []):
        if not isinstance(press, dict):
            continue
        press_id = press.get("press_id")
        status = press.get("status")
        claims_clear = status in CLEAR_STATUSES
        missing_refs = [field for field in REQUIRED_REFS if not has_ref(press.get(field))]
        row_failures: list[dict[str, Any]] = []

        version_ok = release_version_ok(press.get("release_version"))
        refs_ok = not missing_refs
        evidence_ok = bool(press.get("evidence_refs"))
        clear = claims_clear and version_ok and refs_ok and evidence_ok

        if claims_clear and not version_ok:
            row_failures.append(
                {
                    "code": "press_clear_without_v0_1_release_version",
                    "release_version": press.get("release_version"),
                }
            )
        if claims_clear and missing_refs:
            row_failures.append({"code": "press_clear_missing_required_refs", "missing_refs": missing_refs})
        if claims_clear and not evidence_ok:
            row_failures.append({"code": "press_clear_without_evidence_refs"})
        if has_secretish_string(press):
            row_failures.append({"code": "secret_or_raw_value_shape_detected"})

        if check_paths:
            for field in REQUIRED_REFS:
                ref = press.get(field)
                if isinstance(ref, str) and not ref_exists(ref):
                    row_failures.append({"code": "required_ref_missing", "field": field, "ref": ref})
            for ref in press.get("evidence_refs", []):
                if isinstance(ref, str) and not ref_exists(ref):
                    row_failures.append({"code": "evidence_ref_missing", "ref": ref})

        if clear and not row_failures:
            computed_clear_count += 1
        for failure in row_failures:
            failures.append({"press_id": press_id, **failure})

        press_results.append(
            {
                "press_id": press_id,
                "company_slug": press.get("company_slug"),
                "status": status,
                "release_version": press.get("release_version"),
                "missing_refs": missing_refs,
                "release_version_status": "clear" if version_ok else "blocked",
                "press_readiness_gate_status": "clear" if clear and not row_failures else "blocked",
                "failures": row_failures,
            }
        )

    claimed_clear_count = ledger.get("clear_count")
    if claimed_clear_count != computed_clear_count:
        failures.append({"code": "press_readiness_clear_count_mismatch", "claimed": claimed_clear_count, "computed": computed_clear_count})

    return {
        "schema_version": "zeststream.holding_company_press_readiness.validation.v1",
        "status": "fail" if failures else "pass",
        "gate": ledger.get("gate"),
        "clear_count": computed_clear_count,
        "press_count": len(press_results),
        "presses": press_results,
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
        print("status={status} clear_count={clear_count} press_count={press_count}".format(**result))
        for failure in result["failures"]:
            print(f"FAIL {failure}")
    return 0 if result["status"] == "pass" else 1


if __name__ == "__main__":
    sys.exit(main())

# Meta-Learning Cross-References (2026-05-19)
# Batch-16 comment backfill; citations are documentation-only and do not alter runtime behavior.
# Related: `/Users/josh/Developer/skillos/.flywheel/doctrine/meta-learnings/MP-02-conformance-fixtures.md`
# Related: `/Users/josh/Developer/skillos/.flywheel/doctrine/meta-learnings/MP-68-schema-executable-validator-pair.md`
