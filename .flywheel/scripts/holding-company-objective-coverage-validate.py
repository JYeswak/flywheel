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
REQUIRED_VALIDATION_COMMAND_ID = "standing_goal_aggregate"
REQUIRED_VALIDATION_COMMAND = "bash tests/zeststream-holding-company-standing-goal.sh"
REQUIRED_VALIDATION_COVERAGE = "state/zeststream-portfolio-company-registry.json"
PORTFOLIO_REGISTRY_REF = "state/zeststream-portfolio-company-registry.json"
RUNWAY_RECEIPT_REF = "state/holding-company-runway-current.json"
LEGAL_STRUCTURE_REF = "state/holding-company-legal-structure.json"
SUSTAINABLE_PACE_REF = "state/holding-company-sustainable-pace.json"
RECENT_PROGRESS_CLAIM_HONESTY_REF = "state/holding-company-recent-progress-claim-honesty-20260517T1017Z.json"
RECENT_PROGRESS_REQUIREMENT_CLAIMS = {
    "recent_anthropic_adoption_claim": "anthropic_adoption",
    "recent_mobile_eats_shipping_claim": "mobile_eats_shipping",
    "recent_progress_velocity_claim": "progress_velocity",
    "recent_skillos_forever_os_claim": "skillos_forever_os_lock",
}
ZERO_PORTFOLIO_REQUIREMENT_STATUSES = {
    "management_plane_portfolio": "partial",
    "pour_loop": "blocked",
    "portfolio_company_existence_gate": "blocked",
    "each_business_own_brand_owner_customers": "blocked",
    "one_year_small_portfolio_making_money": "blocked",
}
LEGAL_REQUIRED_BEFORE_SUB_2 = {
    "holding_company_operating_agreement",
    "peer_coach_equity_pathway",
    "annual_tier_review_process",
    "substrate_contributor_pool",
    "subsidiary_owner_operating_agreement",
    "intercompany_services_agreement",
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


def script_path_for_command(command: str) -> Path | None:
    parts = command.split()
    if len(parts) != 2 or parts[0] not in {"bash", "sh"}:
        return None
    return path_for_ref(parts[1])


def has_secretish_string(value: Any) -> bool:
    if isinstance(value, str):
        return bool(SECRETISH_RE.search(value))
    if isinstance(value, dict):
        return any(has_secretish_string(v) for v in value.values())
    if isinstance(value, list):
        return any(has_secretish_string(v) for v in value)
    return False


def has_zero_clear_count(value: dict[str, Any]) -> bool:
    return any(key.endswith("clear_count") and count == 0 for key, count in value.items())


def runway_gate_status(receipt: dict[str, Any]) -> str:
    status = receipt.get("status")
    required_months = receipt.get("required_months")
    verified_months = receipt.get("verified_runway_months")
    if (
        status == "pass"
        and isinstance(required_months, (int, float))
        and isinstance(verified_months, (int, float))
        and verified_months >= required_months
    ):
        return "clear"
    return "blocked"


def legal_structure_gate_status(receipt: dict[str, Any]) -> str:
    claimed_clear_count = receipt.get("clear_count")
    requirements = [row for row in receipt.get("requirements", []) if isinstance(row, dict)]
    cleared_required_rows = {
        row.get("requirement_id")
        for row in requirements
        if row.get("requirement_id") in LEGAL_REQUIRED_BEFORE_SUB_2
        and row.get("status") == "cleared"
        and isinstance(row.get("binding_artifact_ref"), str)
        and isinstance(row.get("attorney_review_ref"), str)
        and isinstance(row.get("cpa_review_ref"), str)
    }
    if claimed_clear_count == len(LEGAL_REQUIRED_BEFORE_SUB_2) and cleared_required_rows == LEGAL_REQUIRED_BEFORE_SUB_2:
        return "clear"
    return "blocked"


def is_number(value: Any) -> bool:
    return isinstance(value, (int, float)) and not isinstance(value, bool)


def sustainable_pace_gate_status(receipt: dict[str, Any]) -> str:
    claimed_clear_count = receipt.get("pace_clear_count")
    max_weekly_hours = receipt.get("max_weekly_hours_year2", 60)
    required_offset_ratio = receipt.get("required_substrate_time_offset_ratio", 0.5)
    if not is_number(max_weekly_hours) or not is_number(required_offset_ratio):
        return "blocked"
    for period in receipt.get("periods", []):
        if not isinstance(period, dict):
            continue
        lifecycle_year = period.get("lifecycle_year")
        weekly_hours = period.get("weekly_hours_total")
        manual_hours = period.get("coaching_hours_manual")
        offset_hours = period.get("coaching_hours_offset_by_substrate")
        denominator = manual_hours + offset_hours if is_number(manual_hours) and is_number(offset_hours) else None
        offset_ratio = offset_hours / denominator if is_number(denominator) and denominator > 0 else None
        if (
            is_number(claimed_clear_count)
            and claimed_clear_count >= 1
            and isinstance(lifecycle_year, int)
            and lifecycle_year >= 2
            and period.get("measurement_status") == "measured_clear"
            and is_number(weekly_hours)
            and weekly_hours <= max_weekly_hours
            and is_number(offset_ratio)
            and offset_ratio >= required_offset_ratio
        ):
            return "clear"
    return "blocked"


def validate_ledger(ledger: dict[str, Any], schema: dict[str, Any], *, check_paths: bool) -> dict[str, Any]:
    failures: list[dict[str, Any]] = []
    try:
        Draft202012Validator.check_schema(schema)
        Draft202012Validator(schema, format_checker=FormatChecker()).validate(ledger)
    except Exception as exc:
        failures.append({"code": "schema_invalid", "detail": str(exc)})

    requirements = [row for row in ledger.get("requirements", []) if isinstance(row, dict)]
    ids = [str(row.get("requirement_id")) for row in requirements]
    requirements_by_id = {str(row.get("requirement_id")): row for row in requirements}
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

    for requirement in requirements:
        requirement_id = requirement.get("requirement_id")
        primary_ref = requirement.get("primary_evidence_ref")
        evidence_refs = requirement.get("evidence_refs", [])
        if isinstance(primary_ref, str) and primary_ref not in evidence_refs:
            failures.append(
                {
                    "code": "primary_evidence_ref_missing_from_evidence_refs",
                    "requirement_id": requirement_id,
                    "primary_evidence_ref": primary_ref,
                }
            )
        if requirement.get("coverage_status") != "proven":
            continue
        if not isinstance(primary_ref, str) or not primary_ref.startswith("state/holding-company-"):
            continue
        primary_path = path_for_ref(primary_ref)
        if primary_path is None or not primary_path.exists():
            continue
        primary_evidence = load_json(primary_path)
        if has_zero_clear_count(primary_evidence):
            failures.append(
                {
                    "code": "proven_requirement_has_zero_clear_primary_evidence",
                    "requirement_id": requirement_id,
                    "primary_evidence_ref": primary_ref,
                }
            )

    runway_path = path_for_ref(RUNWAY_RECEIPT_REF)
    if runway_path is not None and runway_path.exists():
        runway_status = runway_gate_status(load_json(runway_path))
        runway_requirement = requirements_by_id.get("runway_gate")
        if runway_requirement is not None:
            evidence_refs = runway_requirement.get("evidence_refs", [])
            if RUNWAY_RECEIPT_REF not in evidence_refs:
                failures.append(
                    {
                        "code": "runway_requirement_missing_runway_receipt_ref",
                        "requirement_id": "runway_gate",
                        "required_ref": RUNWAY_RECEIPT_REF,
                    }
                )
            if runway_status == "blocked" and runway_requirement.get("coverage_status") != "blocked":
                failures.append(
                    {
                        "code": "requirement_status_mismatch_with_runway_receipt",
                        "requirement_id": "runway_gate",
                        "claimed": runway_requirement.get("coverage_status"),
                        "evidence_status": runway_status,
                    }
                )
    else:
        failures.append({"code": "runway_receipt_ref_missing", "ref": RUNWAY_RECEIPT_REF})

    legal_structure_path = path_for_ref(LEGAL_STRUCTURE_REF)
    if legal_structure_path is not None and legal_structure_path.exists():
        legal_structure_status = legal_structure_gate_status(load_json(legal_structure_path))
        legal_structure_requirement = requirements_by_id.get("legal_structure_gate")
        if legal_structure_requirement is not None:
            evidence_refs = legal_structure_requirement.get("evidence_refs", [])
            if LEGAL_STRUCTURE_REF not in evidence_refs:
                failures.append(
                    {
                        "code": "legal_requirement_missing_legal_structure_ref",
                        "requirement_id": "legal_structure_gate",
                        "required_ref": LEGAL_STRUCTURE_REF,
                    }
                )
            if legal_structure_status == "blocked" and legal_structure_requirement.get("coverage_status") != "blocked":
                failures.append(
                    {
                        "code": "requirement_status_mismatch_with_legal_structure_receipt",
                        "requirement_id": "legal_structure_gate",
                        "claimed": legal_structure_requirement.get("coverage_status"),
                        "evidence_status": legal_structure_status,
                    }
                )
    else:
        failures.append({"code": "legal_structure_ref_missing", "ref": LEGAL_STRUCTURE_REF})

    sustainable_pace_path = path_for_ref(SUSTAINABLE_PACE_REF)
    if sustainable_pace_path is not None and sustainable_pace_path.exists():
        sustainable_pace_status = sustainable_pace_gate_status(load_json(sustainable_pace_path))
        sustainable_pace_requirement = requirements_by_id.get("sustainable_pace_gate")
        if sustainable_pace_requirement is not None:
            evidence_refs = sustainable_pace_requirement.get("evidence_refs", [])
            if SUSTAINABLE_PACE_REF not in evidence_refs:
                failures.append(
                    {
                        "code": "sustainable_pace_requirement_missing_pace_ref",
                        "requirement_id": "sustainable_pace_gate",
                        "required_ref": SUSTAINABLE_PACE_REF,
                    }
                )
            if sustainable_pace_status == "blocked" and sustainable_pace_requirement.get("coverage_status") != "blocked":
                failures.append(
                    {
                        "code": "requirement_status_mismatch_with_sustainable_pace_receipt",
                        "requirement_id": "sustainable_pace_gate",
                        "claimed": sustainable_pace_requirement.get("coverage_status"),
                        "evidence_status": sustainable_pace_status,
                    }
                )
    else:
        failures.append({"code": "sustainable_pace_ref_missing", "ref": SUSTAINABLE_PACE_REF})

    portfolio_registry_path = path_for_ref(PORTFOLIO_REGISTRY_REF)
    counted_portfolio_companies = None
    if portfolio_registry_path is not None and portfolio_registry_path.exists():
        portfolio_registry = load_json(portfolio_registry_path)
        counted_portfolio_companies = portfolio_registry.get("counted_portfolio_companies")
    else:
        failures.append({"code": "portfolio_registry_ref_missing", "ref": PORTFOLIO_REGISTRY_REF})

    if counted_portfolio_companies == 0:
        for requirement_id, expected_status in ZERO_PORTFOLIO_REQUIREMENT_STATUSES.items():
            requirement = requirements_by_id.get(requirement_id)
            if requirement is None:
                continue
            evidence_refs = requirement.get("evidence_refs", [])
            if PORTFOLIO_REGISTRY_REF not in evidence_refs:
                failures.append(
                    {
                        "code": "portfolio_requirement_missing_registry_ref",
                        "requirement_id": requirement_id,
                        "required_ref": PORTFOLIO_REGISTRY_REF,
                    }
                )
            if requirement.get("coverage_status") != expected_status:
                failures.append(
                    {
                        "code": "requirement_status_mismatch_with_zero_portfolio_registry",
                        "requirement_id": requirement_id,
                        "counted_portfolio_companies": counted_portfolio_companies,
                        "claimed": requirement.get("coverage_status"),
                        "expected": expected_status,
                    }
                )

    claim_honesty_path = path_for_ref(RECENT_PROGRESS_CLAIM_HONESTY_REF)
    claim_status_by_id: dict[str, Any] = {}
    if claim_honesty_path is not None and claim_honesty_path.exists():
        claim_honesty = load_json(claim_honesty_path)
        claim_status_by_id = {
            str(claim.get("claim_id")): claim.get("current_gate_status")
            for claim in claim_honesty.get("claims", [])
            if isinstance(claim, dict)
        }
    else:
        failures.append({"code": "recent_progress_claim_honesty_ref_missing", "ref": RECENT_PROGRESS_CLAIM_HONESTY_REF})

    for requirement_id, claim_id in RECENT_PROGRESS_REQUIREMENT_CLAIMS.items():
        requirement = requirements_by_id.get(requirement_id)
        if requirement is None:
            continue
        evidence_refs = requirement.get("evidence_refs", [])
        if RECENT_PROGRESS_CLAIM_HONESTY_REF not in evidence_refs:
            failures.append(
                {
                    "code": "recent_progress_requirement_missing_claim_honesty_ref",
                    "requirement_id": requirement_id,
                    "required_ref": RECENT_PROGRESS_CLAIM_HONESTY_REF,
                }
            )
        evidence_status = claim_status_by_id.get(claim_id)
        if evidence_status is None:
            failures.append(
                {
                    "code": "recent_progress_claim_honesty_claim_missing",
                    "requirement_id": requirement_id,
                    "claim_id": claim_id,
                }
            )
        elif requirement.get("coverage_status") != evidence_status:
            failures.append(
                {
                    "code": "requirement_status_mismatch_with_claim_honesty",
                    "requirement_id": requirement_id,
                    "claim_id": claim_id,
                    "claimed": requirement.get("coverage_status"),
                    "evidence_status": evidence_status,
                }
            )

    validation_commands = [row for row in ledger.get("validation_commands", []) if isinstance(row, dict)]
    aggregate_commands = [row for row in validation_commands if row.get("command_id") == REQUIRED_VALIDATION_COMMAND_ID]
    if not aggregate_commands:
        failures.append({"code": "missing_standing_goal_aggregate_command"})
    else:
        aggregate_command = aggregate_commands[0]
        if aggregate_command.get("command") != REQUIRED_VALIDATION_COMMAND:
            failures.append(
                {
                    "code": "wrong_standing_goal_aggregate_command",
                    "claimed": aggregate_command.get("command"),
                    "required": REQUIRED_VALIDATION_COMMAND,
                }
            )
        if REQUIRED_VALIDATION_COVERAGE not in aggregate_command.get("covers", []):
            failures.append(
                {
                    "code": "standing_goal_aggregate_missing_registry_coverage",
                    "required": REQUIRED_VALIDATION_COVERAGE,
                }
            )

    if check_paths:
        for field in ("source_goal_ref", "audit_ref"):
            ref = ledger.get(field)
            if isinstance(ref, str) and not ref_exists(ref):
                failures.append({"code": f"{field}_missing", "ref": ref})
        for command_row in validation_commands:
            command_id = command_row.get("command_id")
            command = command_row.get("command")
            if not isinstance(command, str):
                continue
            script_path = script_path_for_command(command)
            if script_path is None:
                continue
            if not script_path.exists():
                failures.append({"code": "validation_command_script_missing", "command_id": command_id, "command": command})
            elif not script_path.is_file():
                failures.append({"code": "validation_command_script_not_file", "command_id": command_id, "command": command})
            elif not script_path.stat().st_mode & 0o111:
                failures.append({"code": "validation_command_script_not_executable", "command_id": command_id, "command": command})
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
        "validation_commands": validation_commands,
        "required_validation_command": {
            "command_id": REQUIRED_VALIDATION_COMMAND_ID,
            "command": REQUIRED_VALIDATION_COMMAND,
            "required_coverage": REQUIRED_VALIDATION_COVERAGE,
        },
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
