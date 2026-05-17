#!/usr/bin/env python3
"""Validate the holding-company N+1 cheaper-than-N launch economics ledger."""

from __future__ import annotations

import argparse
import json
import sys
from pathlib import Path
from typing import Any

from jsonschema import Draft202012Validator, FormatChecker


ROOT = Path(__file__).resolve().parents[2]
DEFAULT_SCHEMA = ROOT / ".flywheel/validation-schema/v1/holding-company-launch-economics.schema.json"
DEFAULT_LEDGER = ROOT / "state/holding-company-launch-economics.json"


def load_json(path: Path) -> Any:
    with path.open("r", encoding="utf-8") as handle:
        return json.load(handle)


def ref_exists(ref: str, base_dir: Path) -> bool:
    if "://" in ref or ref.startswith("urn:"):
        return True
    path = Path(ref)
    if not path.is_absolute():
        path = base_dir / path
    return path.exists()


def comparable(launch: dict[str, Any]) -> bool:
    return isinstance(launch.get("peel_hours"), (int, float)) and isinstance(launch.get("press_build_hours"), (int, float))


def cheaper(prev: dict[str, Any], current: dict[str, Any]) -> bool:
    if not comparable(prev) or not comparable(current):
        return False
    prev_hours = float(prev["peel_hours"]) + float(prev["press_build_hours"])
    current_hours = float(current["peel_hours"]) + float(current["press_build_hours"])
    return current_hours < prev_hours and int(current["reused_package_count"]) >= int(prev["reused_package_count"])


def validate_ledger(ledger: dict[str, Any], schema: dict[str, Any], *, check_paths: bool) -> dict[str, Any]:
    failures: list[dict[str, str]] = []
    try:
        Draft202012Validator.check_schema(schema)
        Draft202012Validator(schema, format_checker=FormatChecker()).validate(ledger)
    except Exception as exc:
        failures.append({"code": "schema_invalid", "detail": str(exc)})

    launches = ledger.get("launches") if isinstance(ledger.get("launches"), list) else []
    sorted_launches = sorted((row for row in launches if isinstance(row, dict)), key=lambda row: row.get("sequence", 0))
    sequences = [row.get("sequence") for row in sorted_launches]
    if sequences != list(range(1, len(sequences) + 1)):
        failures.append({"code": "sequence_gap_or_duplicate", "detail": f"sequences={sequences}"})

    if check_paths:
        for row in sorted_launches:
            slug = str(row.get("company_slug", "<missing>"))
            for field in ("substrate_share_receipt",):
                ref = row.get(field)
                if isinstance(ref, str) and not ref_exists(ref, ROOT):
                    failures.append({"code": f"path_missing:{field}", "company_slug": slug})
            for ref in row.get("evidence_refs", []):
                if isinstance(ref, str) and not ref_exists(ref, ROOT):
                    failures.append({"code": "evidence_ref_missing", "company_slug": slug, "ref": ref})

    measured_pairs: list[dict[str, Any]] = []
    for prev, current in zip(sorted_launches, sorted_launches[1:]):
        measured_pairs.append(
            {
                "from": prev.get("launch_id"),
                "to": current.get("launch_id"),
                "comparable": comparable(prev) and comparable(current),
                "cheaper": cheaper(prev, current),
            }
        )

    pass_pairs = [pair for pair in measured_pairs if pair["cheaper"]]
    status = ledger.get("measurement_status")
    if status == "baseline" and len(sorted_launches) > 1:
        failures.append({"code": "baseline_status_with_multiple_launches"})
    if status in {"measured_pass", "measured_fail"} and len(sorted_launches) < 2:
        failures.append({"code": "measured_status_without_two_launches"})
    if status == "measured_pass" and not pass_pairs:
        failures.append({"code": "measured_pass_without_cheaper_pair"})
    if status == "measured_fail" and pass_pairs:
        failures.append({"code": "measured_fail_but_cheaper_pair_exists"})

    return {
        "schema_version": "zeststream.holding_company_launch_economics.validation.v1",
        "status": "fail" if failures else "pass",
        "measurement_status": status,
        "launch_count": len(sorted_launches),
        "measured_pairs": measured_pairs,
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
        print(f"status={result['status']} measurement_status={result['measurement_status']} launch_count={result['launch_count']}")
        for failure in result["failures"]:
            print(f"FAIL {failure}")
    return 0 if result["status"] == "pass" else 1


if __name__ == "__main__":
    sys.exit(main())
