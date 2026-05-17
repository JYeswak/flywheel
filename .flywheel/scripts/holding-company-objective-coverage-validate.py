#!/usr/bin/env python3
"""Validate the ZestStream holding-company objective coverage matrix."""

from __future__ import annotations

import argparse
import json
import re
import sys
from collections import Counter
from pathlib import Path
from typing import Any

from jsonschema import Draft202012Validator, FormatChecker


ROOT = Path(__file__).resolve().parents[2]
DEFAULT_SCHEMA = ROOT / ".flywheel/validation-schema/v1/holding-company-objective-coverage.schema.json"
DEFAULT_LEDGER = ROOT / "state/holding-company-objective-coverage.json"
SECRETISH_RE = re.compile(r"(\$[0-9]|sk-[A-Za-z0-9]|AKIA[0-9A-Z]{16})")
REQUIRED_REQUIREMENT_IDS = {
    "standing_non_closing_goal",
    "management_plane_portfolio",
    "customer_smb_owner_operator",
    "owner_equity_distribution_terms",
    "shared_substrate_stack",
    "n_plus_one_cheaper_than_n",
    "peel_loop",
    "press_loop",
    "pour_loop",
    "nurture_loop",
    "recycle_loop",
    "runway_gate",
    "portfolio_company_existence_gate",
    "anti_pitch_voice_gate",
    "sustainable_pace_gate",
    "owner_search_phasing_gate",
    "legal_structure_gate",
    "recent_progress_velocity_claim",
    "recent_mobile_eats_shipping_claim",
    "recent_anthropic_adoption_claim",
    "recent_brand_voice_claim",
    "recent_skillos_forever_os_claim",
    "no_custom_apps_positioning",
    "each_business_own_brand_owner_customers",
    "joshua_coach_sustainable_pace",
    "one_year_small_portfolio_making_money",
    "future_nonprofit_extension",
    "public_story_show_receipts",
    "company_close_pivot_graduate",
}


def load_json(path: Path) -> Any:
    with path.open("r", encoding="utf-8") as handle:
        return json.load(handle)


def path_for_ref(ref: str) -> Path | None:
    if ref.startswith("urn:") or "://" in ref or ref.startswith("git "):
        return None
    path = Path(ref)
    if not path.is_absolute():
        path = ROOT / path
    return path


def ref_exists(ref: str) -> bool:
    path = path_for_ref(ref)
    return True if path is None else path.exists()


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

    requirements = [row for row in ledger.get("requirements", []) if isinstance(row, dict)]
    ids = [str(row.get("requirement_id")) for row in requirements]
    counts = Counter(row.get("coverage_status") for row in requirements)
    computed_counts = {
        "proven": counts.get("proven", 0),
        "partial": counts.get("partial", 0),
        "blocked": counts.get("blocked", 0),
        "deferred": counts.get("deferred", 0),
        "total": len(requirements),
    }

    if has_secretish_string(ledger):
        failures.append({"code": "secret_or_raw_value_shape_detected"})

    duplicates = sorted(requirement_id for requirement_id, count in Counter(ids).items() if count > 1)
    if duplicates:
        failures.append({"code": "duplicate_requirement_id", "requirement_ids": duplicates})

    missing_ids = sorted(REQUIRED_REQUIREMENT_IDS - set(ids))
    extra_ids = sorted(set(ids) - REQUIRED_REQUIREMENT_IDS)
    if missing_ids:
        failures.append({"code": "missing_required_requirement_ids", "requirement_ids": missing_ids})
    if extra_ids:
        failures.append({"code": "unknown_requirement_ids", "requirement_ids": extra_ids})

    if ledger.get("summary_counts") != computed_counts:
        failures.append({"code": "summary_counts_mismatch", "claimed": ledger.get("summary_counts"), "computed": computed_counts})

    if ledger.get("coverage_status") == "complete":
        failures.append({"code": "standing_goal_cannot_be_complete"})
    if ledger.get("coverage_status") == "not_complete" and computed_counts["blocked"] == 0 and computed_counts["partial"] == 0:
        failures.append({"code": "not_complete_without_open_gaps"})

    if check_paths:
        for field in ("source_goal_ref", "audit_ref"):
            ref = ledger.get(field)
            if isinstance(ref, str) and not ref_exists(ref):
                failures.append({"code": f"{field}_missing", "ref": ref})
        for row in requirements:
            requirement_id = row.get("requirement_id")
            for field in ("primary_evidence_ref",):
                ref = row.get(field)
                if isinstance(ref, str) and not ref_exists(ref):
                    failures.append({"code": f"{field}_missing", "requirement_id": requirement_id, "ref": ref})
            for ref in row.get("evidence_refs", []):
                if isinstance(ref, str) and not ref_exists(ref):
                    failures.append({"code": "evidence_ref_missing", "requirement_id": requirement_id, "ref": ref})

    return {
        "schema_version": "zeststream.holding_company_objective_coverage.validation.v1",
        "status": "fail" if failures else "pass",
        "objective": ledger.get("objective"),
        "objective_status": ledger.get("objective_status"),
        "coverage_status": ledger.get("coverage_status"),
        "objective_coverage_gate_status": "not_complete",
        "summary_counts": computed_counts,
        "missing_required_requirement_ids": missing_ids,
        "unknown_requirement_ids": extra_ids,
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
        counts = result["summary_counts"]
        print(
            "status={status} coverage={coverage_status} proven={proven} partial={partial} blocked={blocked} deferred={deferred}".format(
                **result,
                **counts,
            )
        )
        for failure in result["failures"]:
            print(f"FAIL {failure}")
    return 0 if result["status"] == "pass" else 1


if __name__ == "__main__":
    sys.exit(main())
