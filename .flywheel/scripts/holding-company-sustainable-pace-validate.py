#!/usr/bin/env python3
"""Validate the ZestStream holding-company sustainable-pace ledger."""

from __future__ import annotations

import argparse
import json
import math
import re
import sys
from pathlib import Path
from typing import Any

from jsonschema import Draft202012Validator, FormatChecker


ROOT = Path(__file__).resolve().parents[2]
DEFAULT_SCHEMA = ROOT / ".flywheel/validation-schema/v1/holding-company-sustainable-pace.schema.json"
DEFAULT_LEDGER = ROOT / "state/holding-company-sustainable-pace.json"
SECRETISH_RE = re.compile(r"(\$[0-9]|sk-[A-Za-z0-9]|AKIA[0-9A-Z]{16})")
RATIO_TOLERANCE = 0.001


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


def is_number(value: Any) -> bool:
    return isinstance(value, (int, float)) and not isinstance(value, bool) and math.isfinite(value)


def computed_ratio(manual: Any, offset: Any) -> float | None:
    if not is_number(manual) or not is_number(offset):
        return None
    denominator = manual + offset
    if denominator <= 0:
        return None
    return offset / denominator


def validate_ledger(ledger: dict[str, Any], schema: dict[str, Any], *, check_paths: bool) -> dict[str, Any]:
    failures: list[dict[str, Any]] = []
    try:
        Draft202012Validator.check_schema(schema)
        Draft202012Validator(schema, format_checker=FormatChecker()).validate(ledger)
    except Exception as exc:
        failures.append({"code": "schema_invalid", "detail": str(exc)})

    max_weekly_hours = ledger.get("max_weekly_hours_year2", 60)
    required_offset_ratio = ledger.get("required_substrate_time_offset_ratio", 0.5)
    period_results: list[dict[str, Any]] = []
    computed_clear_count = 0

    for period in ledger.get("periods", []):
        if not isinstance(period, dict):
            continue
        period_id = period.get("period_id")
        lifecycle_year = period.get("lifecycle_year")
        status = period.get("measurement_status")
        weekly_hours = period.get("weekly_hours_total")
        manual_hours = period.get("coaching_hours_manual")
        offset_hours = period.get("coaching_hours_offset_by_substrate")
        supplied_ratio = period.get("substrate_offset_ratio")
        year2_or_later = isinstance(lifecycle_year, int) and lifecycle_year >= 2
        ratio = computed_ratio(manual_hours, offset_hours)

        period_failures: list[dict[str, Any]] = []
        metrics_present = all(is_number(value) for value in [weekly_hours, manual_hours, offset_hours, supplied_ratio])

        if status in {"measured_clear", "measured_fail"} and not metrics_present:
            period_failures.append({"code": "measured_status_without_complete_metrics"})
        if metrics_present and ratio is None:
            period_failures.append({"code": "substrate_offset_ratio_not_computable"})
        if ratio is not None and is_number(supplied_ratio) and abs(ratio - supplied_ratio) > RATIO_TOLERANCE:
            period_failures.append(
                {
                    "code": "substrate_offset_ratio_mismatch",
                    "computed": round(ratio, 6),
                    "supplied": supplied_ratio,
                }
            )

        hours_ok = is_number(weekly_hours) and weekly_hours <= max_weekly_hours
        offset_ok = ratio is not None and ratio >= required_offset_ratio
        pace_clear = year2_or_later and hours_ok and offset_ok and not period_failures

        if year2_or_later and is_number(weekly_hours) and weekly_hours > max_weekly_hours:
            period_failures.append(
                {
                    "code": "year2_weekly_hours_over_cap",
                    "weekly_hours_total": weekly_hours,
                    "max_weekly_hours": max_weekly_hours,
                }
            )
        if year2_or_later and ratio is not None and ratio < required_offset_ratio:
            period_failures.append(
                {
                    "code": "year2_substrate_offset_below_required",
                    "computed": round(ratio, 6),
                    "required": required_offset_ratio,
                }
            )
        if status == "measured_clear" and not pace_clear:
            period_failures.append({"code": "measured_clear_without_sustainable_pace"})
        if has_secretish_string(period):
            period_failures.append({"code": "secret_or_raw_amount_shape_detected"})

        if check_paths:
            for ref in period.get("evidence_refs", []):
                if isinstance(ref, str) and not ref_exists(ref):
                    period_failures.append({"code": "evidence_ref_missing", "ref": ref})

        if pace_clear and status == "measured_clear":
            computed_clear_count += 1
        for failure in period_failures:
            failures.append({"period_id": period_id, **failure})

        period_results.append(
            {
                "period_id": period_id,
                "company_slug": period.get("company_slug"),
                "sequence": period.get("sequence"),
                "lifecycle_year": lifecycle_year,
                "measurement_status": status,
                "computed_substrate_offset_ratio": round(ratio, 6) if ratio is not None else None,
                "pace_gate_status": "clear" if pace_clear and status == "measured_clear" else "blocked",
                "failures": period_failures,
            }
        )

    claimed_clear_count = ledger.get("pace_clear_count")
    if claimed_clear_count != computed_clear_count:
        failures.append(
            {
                "code": "pace_clear_count_mismatch",
                "claimed": claimed_clear_count,
                "computed": computed_clear_count,
            }
        )

    return {
        "schema_version": "zeststream.holding_company_sustainable_pace.validation.v1",
        "status": "fail" if failures else "pass",
        "gate": ledger.get("gate"),
        "max_weekly_hours_year2": max_weekly_hours,
        "required_substrate_time_offset_ratio": required_offset_ratio,
        "pace_clear_count": computed_clear_count,
        "period_count": len(period_results),
        "periods": period_results,
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
        print(
            "status={status} pace_clear_count={pace_clear_count} period_count={period_count}".format(
                **result
            )
        )
        for failure in result["failures"]:
            print(f"FAIL {failure}")
    return 0 if result["status"] == "pass" else 1


if __name__ == "__main__":
    sys.exit(main())
