#!/usr/bin/env python3
"""Validate the ZestStream holding-company Mobile Eats shipping ledger."""

from __future__ import annotations

import argparse
import json
import re
import sys
from pathlib import Path
from typing import Any

from jsonschema import Draft202012Validator, FormatChecker


ROOT = Path(__file__).resolve().parents[2]
DEFAULT_SCHEMA = ROOT / ".flywheel/validation-schema/v1/holding-company-mobile-eats-shipping.schema.json"
DEFAULT_LEDGER = ROOT / "state/holding-company-mobile-eats-shipping.json"
SECRETISH_RE = re.compile(r"(\$[0-9]|sk-[A-Za-z0-9]|AKIA[0-9A-Z]{16})")
FIRST_PORTFOLIO_COMPANY_OVERCLAIM_RE = re.compile(r"\bfirst\s+portfolio\s+company\b", re.IGNORECASE)
FORMATION_RECEIPT_FIELDS = (
    "signed_owner_operator_receipt",
    "equity_receipt",
    "first_paying_customer_receipt",
)


def load_json(path: Path) -> Any:
    with path.open("r", encoding="utf-8") as handle:
        return json.load(handle)


def path_for_ref(ref: str) -> Path | None:
    if ref.startswith("urn:") or "://" in ref:
        return None
    path = Path(ref)
    if not path.is_absolute():
        path = ROOT / path
    return path


def ref_exists(ref: str) -> bool:
    path = path_for_ref(ref)
    return True if path is None else path.exists()


def load_local_json_ref(ref: Any) -> dict[str, Any] | None:
    if not isinstance(ref, str):
        return None
    path = path_for_ref(ref)
    if path is None or not path.exists():
        return None
    data = load_json(path)
    return data if isinstance(data, dict) else None


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


def first_portfolio_company_overclaim(value: Any) -> bool:
    return isinstance(value, str) and bool(FIRST_PORTFOLIO_COMPANY_OVERCLAIM_RE.search(value))


def registry_company(registry: dict[str, Any] | None, slug: str) -> dict[str, Any] | None:
    if not registry:
        return None
    for company in registry.get("companies", []):
        if isinstance(company, dict) and company.get("slug") == slug:
            return company
    return None


def validate_ledger(ledger: dict[str, Any], schema: dict[str, Any], *, check_paths: bool) -> dict[str, Any]:
    failures: list[dict[str, Any]] = []
    try:
        Draft202012Validator.check_schema(schema)
        Draft202012Validator(schema, format_checker=FormatChecker()).validate(ledger)
    except Exception as exc:
        failures.append({"code": "schema_invalid", "detail": str(exc)})

    company_slug = ledger.get("company_slug")
    required_min = ledger.get("required_min_zeststream_packages")
    package_count = ledger.get("substrate_package_count")
    status = ledger.get("status")

    if has_secretish_string(ledger):
        failures.append({"code": "secret_or_raw_value_shape_detected"})

    if isinstance(required_min, int) and isinstance(package_count, int) and ledger.get("package_threshold_met") != (package_count >= required_min):
        failures.append(
            {
                "code": "package_threshold_flag_mismatch",
                "claimed": ledger.get("package_threshold_met"),
                "computed": package_count >= required_min,
            }
        )

    if check_paths:
        for field in (
            "repo_path",
            "share_ready_packet_ref",
            "tenant_declaration_ref",
            "package_manifest_ref",
            "substrate_share_receipt_ref",
            "portfolio_registry_ref",
        ):
            ref = ledger.get(field)
            if isinstance(ref, str) and not ref_exists(ref):
                failures.append({"code": f"{field}_missing", "ref": ref})
        for ref in ledger.get("evidence_refs", []):
            if isinstance(ref, str) and not ref_exists(ref):
                failures.append({"code": "evidence_ref_missing", "ref": ref})
        for field in FORMATION_RECEIPT_FIELDS:
            ref = ledger.get(field)
            if isinstance(ref, str) and not ref_exists(ref):
                failures.append({"code": f"{field}_missing", "ref": ref})

    substrate = load_local_json_ref(ledger.get("substrate_share_receipt_ref"))
    if substrate:
        if substrate.get("company_slug") != company_slug:
            failures.append({"code": "substrate_company_slug_mismatch", "claimed": company_slug, "receipt": substrate.get("company_slug")})
        counts = substrate.get("counts") if isinstance(substrate.get("counts"), dict) else {}
        receipt_count = counts.get("total_packages")
        if receipt_count != package_count:
            failures.append({"code": "substrate_package_count_mismatch", "claimed": package_count, "receipt": receipt_count})

    registry = load_local_json_ref(ledger.get("portfolio_registry_ref"))
    company = registry_company(registry, str(company_slug))
    if registry and not company:
        failures.append({"code": "registry_company_missing", "company_slug": company_slug})
    if company:
        counted = bool(company.get("counted_as_portfolio_company"))
        if counted != ledger.get("counted_as_portfolio_company"):
            failures.append({"code": "registry_counted_status_mismatch", "claimed": ledger.get("counted_as_portfolio_company"), "registry": counted})
        gate_evidence = company.get("gate_evidence") if isinstance(company.get("gate_evidence"), dict) else {}
        for field in FORMATION_RECEIPT_FIELDS:
            registry_ref = gate_evidence.get(field)
            ledger_ref = ledger.get(field)
            if registry_ref != ledger_ref:
                failures.append({"code": "registry_formation_receipt_mismatch", "field": field, "claimed": ledger_ref, "registry": registry_ref})

    product_substrate_present = (
        ledger.get("repo_present") is True
        and ledger.get("share_ready_packet_present") is True
        and ledger.get("tenant_declaration_present") is True
        and ledger.get("package_manifest_present") is True
        and ledger.get("public_surface_declared") is True
        and ledger.get("substrate_share_receipt_present") is True
        and ledger.get("package_threshold_met") is True
    )
    formation_receipts_present = all(has_ref(ledger.get(field)) for field in FORMATION_RECEIPT_FIELDS)
    portfolio_claim_clear = ledger.get("counted_as_portfolio_company") is True and ledger.get("first_portfolio_company_claim_clear") is True

    if status == "proven" and ledger.get("repo_present") is not True:
        failures.append({"code": "proven_without_repo"})
    if status == "proven" and ledger.get("share_ready_packet_present") is not True:
        failures.append({"code": "proven_without_share_ready_packet"})
    if status == "proven" and ledger.get("substrate_share_receipt_present") is not True:
        failures.append({"code": "proven_without_substrate_receipt"})
    if status == "proven" and ledger.get("package_threshold_met") is not True:
        failures.append({"code": "proven_below_package_threshold"})
    if status == "proven" and ledger.get("counted_as_portfolio_company") is not True:
        failures.append({"code": "proven_without_counted_portfolio_company"})
    if status == "proven" and ledger.get("first_portfolio_company_claim_clear") is not True:
        failures.append({"code": "proven_without_first_portfolio_company_clear"})
    if status == "proven":
        for field in FORMATION_RECEIPT_FIELDS:
            if not has_ref(ledger.get(field)):
                failures.append({"code": f"proven_without_{field}"})
    if (
        status != "proven"
        and (
            ledger.get("counted_as_portfolio_company") is not True
            or ledger.get("first_portfolio_company_claim_clear") is not True
            or not formation_receipts_present
        )
        and first_portfolio_company_overclaim(ledger.get("claim_text"))
    ):
        failures.append({"code": "claim_text_overstates_first_portfolio_company"})

    if status == "proven" and product_substrate_present and formation_receipts_present and portfolio_claim_clear:
        gate_status = "proven"
    elif status == "partial" and product_substrate_present:
        gate_status = "partial"
    else:
        gate_status = "blocked"

    return {
        "schema_version": "zeststream.holding_company_mobile_eats_shipping.validation.v1",
        "status": "fail" if failures else "pass",
        "gate": ledger.get("gate"),
        "mobile_eats_shipping_gate_status": gate_status,
        "company_slug": company_slug,
        "required_min_zeststream_packages": required_min,
        "substrate_package_count": package_count,
        "package_threshold_met": ledger.get("package_threshold_met"),
        "product_substrate_present": product_substrate_present,
        "counted_as_portfolio_company": ledger.get("counted_as_portfolio_company"),
        "first_portfolio_company_claim_clear": ledger.get("first_portfolio_company_claim_clear"),
        "formation_receipts_present": formation_receipts_present,
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
            "status={status} gate_status={mobile_eats_shipping_gate_status} packages={substrate_package_count} counted={counted_as_portfolio_company}".format(
                **result
            )
        )
        for failure in result["failures"]:
            print(f"FAIL {failure}")
    return 0 if result["status"] == "pass" else 1


if __name__ == "__main__":
    sys.exit(main())
