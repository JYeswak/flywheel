#!/usr/bin/env python3
"""Validate the ZestStream holding-company owner-search phasing ledger."""

from __future__ import annotations

import argparse
import json
import re
import sys
from pathlib import Path
from typing import Any

from jsonschema import Draft202012Validator, FormatChecker


ROOT = Path(__file__).resolve().parents[2]
DEFAULT_SCHEMA = ROOT / ".flywheel/validation-schema/v1/holding-company-owner-search-phasing.schema.json"
DEFAULT_LEDGER = ROOT / "state/holding-company-owner-search-phasing.json"
WARM_CHANNELS = {"warm_network", "referral", "client_talk", "community", "field_trip"}
PUBLIC_OR_COLD_CHANNELS = {"public_open_call", "inbound_public", "cold_outreach"}
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


def validate_ledger(ledger: dict[str, Any], schema: dict[str, Any], *, check_paths: bool) -> dict[str, Any]:
    failures: list[dict[str, Any]] = []
    try:
        Draft202012Validator.check_schema(schema)
        Draft202012Validator(schema, format_checker=FormatChecker()).validate(ledger)
    except Exception as exc:
        failures.append({"code": "schema_invalid", "detail": str(exc)})

    warm_only_through = ledger.get("warm_network_only_through_sequence", 2)
    public_min = ledger.get("public_open_call_min_sequence", 3)
    row_results: list[dict[str, Any]] = []
    computed_clear_count = 0

    for search in ledger.get("searches", []):
        if not isinstance(search, dict):
            continue
        slug = search.get("candidate_slug")
        sequence = search.get("sequence")
        status = search.get("search_status")
        channel = search.get("sourcing_channel")
        public_open_call_active = search.get("public_open_call_active")

        early_sequence = isinstance(sequence, int) and sequence <= warm_only_through
        public_allowed = isinstance(sequence, int) and sequence >= public_min
        warm_proven = channel in WARM_CHANNELS and public_open_call_active is False
        early_public_violation = early_sequence and (channel in PUBLIC_OR_COLD_CHANNELS or public_open_call_active is True)
        phasing_clear = (early_sequence and warm_proven) or (public_allowed and channel != "unknown")

        row_failures: list[dict[str, Any]] = []
        if early_public_violation:
            row_failures.append(
                {
                    "code": "public_or_cold_sourcing_before_sub_3",
                    "sequence": sequence,
                    "sourcing_channel": channel,
                    "public_open_call_active": public_open_call_active,
                }
            )
        if status in {"allowed", "signed_owner"} and not phasing_clear:
            row_failures.append(
                {
                    "code": "search_status_without_phasing_clear",
                    "sequence": sequence,
                    "sourcing_channel": channel,
                }
            )
        if has_secretish_string(search):
            row_failures.append({"code": "secret_or_raw_amount_shape_detected"})

        if check_paths:
            for ref in search.get("evidence_refs", []):
                if isinstance(ref, str) and not ref_exists(ref):
                    row_failures.append({"code": "evidence_ref_missing", "ref": ref})

        if phasing_clear and not row_failures:
            computed_clear_count += 1
        for failure in row_failures:
            failures.append({"candidate_slug": slug, **failure})

        row_results.append(
            {
                "candidate_slug": slug,
                "sequence": sequence,
                "search_status": status,
                "sourcing_channel": channel,
                "public_open_call_active": public_open_call_active,
                "phasing_gate_status": "clear" if phasing_clear and not row_failures else "blocked",
                "failures": row_failures,
            }
        )

    claimed_clear_count = ledger.get("phasing_clear_count")
    if claimed_clear_count != computed_clear_count:
        failures.append(
            {
                "code": "phasing_clear_count_mismatch",
                "claimed": claimed_clear_count,
                "computed": computed_clear_count,
            }
        )

    return {
        "schema_version": "zeststream.holding_company_owner_search_phasing.validation.v1",
        "status": "fail" if failures else "pass",
        "gate": ledger.get("gate"),
        "warm_network_only_through_sequence": warm_only_through,
        "public_open_call_min_sequence": public_min,
        "phasing_clear_count": computed_clear_count,
        "search_count": len(row_results),
        "searches": row_results,
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
            "status={status} phasing_clear_count={phasing_clear_count} search_count={search_count}".format(
                **result
            )
        )
        for failure in result["failures"]:
            print(f"FAIL {failure}")
    return 0 if result["status"] == "pass" else 1


if __name__ == "__main__":
    sys.exit(main())
