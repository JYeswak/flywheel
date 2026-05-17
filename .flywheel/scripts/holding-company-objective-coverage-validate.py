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
LEGAL_HOUSE_SCAFFOLD_REF = "/Users/josh/Developer/skillos/state/legal-house/SCAFFOLD.md"
SUSTAINABLE_PACE_REF = "state/holding-company-sustainable-pace.json"
COACH_ROLE_REF = "state/holding-company-coach-role.json"
OWNER_SEARCH_PHASING_REF = "state/holding-company-owner-search-phasing.json"
OWNER_ECONOMICS_REF = "state/holding-company-owner-economics.json"
OPERATING_HEALTH_REF = "state/holding-company-operating-health.json"
CANDIDATE_FIT_REF = "state/holding-company-candidate-fit.json"
OWNER_VOICE_REF = "state/holding-company-owner-voice.json"
ANTI_PITCH_VOICE_REF = "state/holding-company-anti-pitch-voice.json"
PUBLIC_STORY_REF = "state/holding-company-public-story.json"
PUBLIC_STORY_ROUTE_REF = "state/holding-company-public-story-route-20260517T0948Z.json"
PUBLIC_SURFACE_AUDIT_SUPERSESSION_REF = "state/holding-company-public-surface-audit-supersession-20260517T1004Z.json"
BRAND_VOICE_SKILL_REF = "state/holding-company-brand-voice-skill.json"
FOUNDER_POST_VOICE_REF = "state/holding-company-founder-post-voice.json"
BRAND_NAMING_REF = "state/holding-company-brand-naming.json"
MOBILE_EATS_SHIPPING_REF = "state/holding-company-mobile-eats-shipping.json"
SKILLOS_FOREVER_OS_LOCK_REF = "state/holding-company-skillos-forever-os-lock.json"
PEEL_INTERVIEWS_REF = "state/holding-company-peel-interviews.json"
PRESS_READINESS_REF = "state/holding-company-press-readiness.json"
POUR_READINESS_REF = "state/holding-company-pour-readiness.json"
SHARED_STACK_REF = "state/holding-company-shared-stack.json"
MOBILE_EATS_SUBSTRATE_SHARE_REF = "state/substrate-share/mobile-eats-20260517T0654Z.json"
ANTHROPIC_ADOPTION_REF = "state/holding-company-anthropic-adoption.json"
PEER_COACH_REF = "state/holding-company-peer-coach.json"
LAUNCH_ECONOMICS_REF = "state/holding-company-launch-economics.json"
RECYCLE_LOOP_REF = "state/holding-company-recycle-loop.json"
NONPROFIT_EXTENSION_REF = "state/holding-company-nonprofit-extension.json"
LIFECYCLE_DISPOSITION_REF = "state/holding-company-lifecycle-disposition.json"
PROGRESS_VELOCITY_REF = "state/holding-company-progress-velocity.json"
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
OWNER_SEARCH_WARM_CHANNELS = {"warm_network", "referral", "client_talk", "community", "field_trip"}
OWNER_SEARCH_PUBLIC_OR_COLD_CHANNELS = {"public_open_call", "inbound_public", "cold_outreach"}
OWNER_ECONOMICS_REQUIRED_REFS = {
    "signed_owner_operator_receipt",
    "cap_table_ref",
    "distribution_terms_ref",
    "legal_review_ref",
    "substrate_share_receipt",
}
OPERATING_HEALTH_CLEAR_STATUSES = {"revenue_clear", "profit_clear"}
OPERATING_HEALTH_REVENUE_REFS = [
    "first_paying_customer_receipt",
    "revenue_snapshot_ref",
    "owner_operator_report_ref",
    "operating_control_ref",
    "substrate_share_receipt",
]
OPERATING_HEALTH_PROFIT_REFS = OPERATING_HEALTH_REVENUE_REFS + [
    "positive_gross_profit_ref",
    "owner_distribution_ref",
]
COACH_ROLE_REQUIRED_REFS = {
    "owner_operator_ref",
    "operating_control_handoff_ref",
    "coach_role_agreement_ref",
    "majority_stake_ref",
    "owner_operating_control_ack_ref",
}
CANDIDATE_FIT_CLEAR_STATUSES = {"candidate_clear", "press_clear", "formation_clear"}
CANDIDATE_FIT_CLASSIFICATIONS = {"sharpen_legacy_smb", "incubate_ai_first"}
OWNER_VOICE_REQUIRED_REFS = {
    "owner_operator_ref",
    "owner_voice_ref",
    "community_context_ref",
    "yuzu_review_ref",
    "public_surface_ref",
}
PUBLIC_POSITIONING_REQUIRED = "sharpen_legacy_incubate_new_not_builder"
BRAND_VOICE_CLEAR_STATUSES = {"aligned", "clear"}
FOUNDER_POST_CLEAR_STATUSES = {"clear", "ratified"}
FOUNDER_POST_FACT_CHECK_CLEAR = {"pass", "no_claims"}
BRAND_NAMING_CLEAR_STATUSES = {"name_clear", "launch_clear"}
BRAND_NAMING_REQUIRED_REFS = {
    "owner_operator_ref",
    "community_context_ref",
    "naming_decision_ref",
    "brand_identity_ref",
    "public_surface_ref",
}
PEEL_QUALIFYING_URGENCY = {"medium", "strong"}
PEEL_QUALIFYING_SOURCE_CHANNELS = {"client_talk", "community", "field_trip"}
PRESS_CLEAR_STATUSES = {"press_clear", "formation_ready"}
PRESS_REQUIRED_REFS = {
    "candidate_fit_ref",
    "v0_1_release_ref",
    "skillos_hardening_ref",
    "flywheel_coordination_ref",
    "package_delivery_ref",
    "yuzu_owner_voice_ref",
    "signed_equity_ref",
    "owner_economics_ref",
    "substrate_share_receipt",
}
POUR_REQUIRED_REFS = {
    "brand_identity_ref",
    "repo_ref",
    "public_surface_ref",
    "first_paying_customer_receipt",
    "owner_operator_ref",
    "operating_control_handoff_ref",
}
SHARED_STACK_REQUIRED_COMPONENTS = {"skillos", "flywheel", "jsm", "zeststream_packages", "brand_voice"}
PEER_COACH_REQUIRED_REFS = [
    "sustainable_cash_position_ref",
    "operating_control_ref",
    "peer_coach_agreement_ref",
    "equity_grant_ref",
]
RECYCLE_REQUIRED_REFS = [
    "friction_receipt_ref",
    "skillos_capability_ref",
    "package_or_substrate_ref",
    "portfolio_propagation_ref",
]
NONPROFIT_EXTENSION_REQUIRED_REFS = [
    "social_cause_scope_ref",
    "nonprofit_legal_review_ref",
    "governance_model_ref",
    "operating_separation_ref",
    "funding_policy_ref",
    "public_story_ref",
]
LIFECYCLE_DISPOSITION_REQUIRED_REFS = [
    "owner_operator_ref",
    "customer_obligation_disposition_ref",
    "financial_disposition_ref",
    "substrate_retention_ref",
    "brand_public_update_ref",
]
MOBILE_EATS_FORMATION_RECEIPT_FIELDS = (
    "signed_owner_operator_receipt",
    "equity_receipt",
    "first_paying_customer_receipt",
)
SOURCE_GOAL_REQUIRED_PHRASES = [
    "This is a standing operating system goal",
    "the holding plane operates forever",
    "ZestStream is the management plane",
]


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


def ref_text_contains(ref: str, phrases: list[str]) -> bool:
    path = path_for_ref(ref)
    if path is None or not path.exists() or not path.is_file():
        return False
    text = path.read_text(encoding="utf-8")
    return all(phrase in text for phrase in phrases)


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


def has_ref(value: Any) -> bool:
    return isinstance(value, str) and bool(value.strip())


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


def owner_search_phasing_gate_status(receipt: dict[str, Any]) -> str:
    claimed_clear_count = receipt.get("phasing_clear_count")
    warm_only_through = receipt.get("warm_network_only_through_sequence", 2)
    public_min = receipt.get("public_open_call_min_sequence", 3)
    if not isinstance(claimed_clear_count, int) or claimed_clear_count < 1:
        return "blocked"
    for search in receipt.get("searches", []):
        if not isinstance(search, dict):
            continue
        sequence = search.get("sequence")
        channel = search.get("sourcing_channel")
        public_open_call_active = search.get("public_open_call_active")
        early_sequence = isinstance(sequence, int) and isinstance(warm_only_through, int) and sequence <= warm_only_through
        public_allowed = isinstance(sequence, int) and isinstance(public_min, int) and sequence >= public_min
        warm_proven = channel in OWNER_SEARCH_WARM_CHANNELS and public_open_call_active is False
        early_public_violation = early_sequence and (
            channel in OWNER_SEARCH_PUBLIC_OR_COLD_CHANNELS or public_open_call_active is True
        )
        phasing_clear = (early_sequence and warm_proven) or (public_allowed and channel != "unknown")
        if phasing_clear and not early_public_violation:
            return "clear"
    return "blocked"


def owner_economics_gate_status(receipt: dict[str, Any]) -> str:
    claimed_clear_count = receipt.get("clear_count")
    required_owner_equity = receipt.get("required_owner_equity_percent", 25)
    distribution_min = receipt.get("owner_distribution_min_percent", 45)
    distribution_max = receipt.get("owner_distribution_max_percent", 75)
    if not isinstance(claimed_clear_count, int) or claimed_clear_count < 1:
        return "blocked"
    for deal in receipt.get("deals", []):
        if not isinstance(deal, dict) or deal.get("status") not in {"signed", "active"}:
            continue
        owner_equity = deal.get("owner_equity_percent")
        holding_equity = deal.get("holding_company_equity_percent")
        owner_equity_ok = is_number(owner_equity) and owner_equity == required_owner_equity
        holding_equity_ok = is_number(holding_equity) and owner_equity_ok and holding_equity + owner_equity == 100
        refs_ok = all(has_ref(deal.get(field)) for field in OWNER_ECONOMICS_REQUIRED_REFS)
        distribution_values = [
            tier.get("owner_distribution_percent")
            for tier in deal.get("profit_distribution_tiers", [])
            if isinstance(tier, dict) and is_number(tier.get("owner_distribution_percent"))
        ]
        distribution_bounds_ok = (
            len(distribution_values) >= 2
            and min(distribution_values) == distribution_min
            and max(distribution_values) == distribution_max
            and all(distribution_min <= value <= distribution_max for value in distribution_values)
        )
        if has_ref(deal.get("owner_operator_slug")) and owner_equity_ok and holding_equity_ok and refs_ok and distribution_bounds_ok:
            return "clear"
    return "blocked"


def operating_health_gate_status(receipt: dict[str, Any]) -> str:
    claimed_clear_count = receipt.get("clear_count")
    if not isinstance(claimed_clear_count, int) or claimed_clear_count < 1:
        return "blocked"
    for company in receipt.get("companies", []):
        if not isinstance(company, dict) or company.get("status") not in OPERATING_HEALTH_CLEAR_STATUSES:
            continue
        required_refs = (
            OPERATING_HEALTH_PROFIT_REFS
            if company.get("status") == "profit_clear"
            else OPERATING_HEALTH_REVENUE_REFS
        )
        refs_ok = all(has_ref(company.get(field)) for field in required_refs)
        if (
            refs_ok
            and company.get("metrics_are_redacted") is True
            and company.get("raw_amounts_present") is False
            and bool(company.get("evidence_refs"))
        ):
            return "clear"
    return "blocked"


def coach_role_gate_status(receipt: dict[str, Any]) -> str:
    claimed_clear_count = receipt.get("clear_count")
    required_min_stake = receipt.get("required_min_holding_stake_percent", 51)
    if not isinstance(claimed_clear_count, int) or claimed_clear_count < 1 or not is_number(required_min_stake):
        return "blocked"
    for role in receipt.get("roles", []):
        if not isinstance(role, dict) or role.get("status") not in {"coach_role_clear", "active"}:
            continue
        stake = role.get("holding_stake_percent")
        refs_ok = all(has_ref(role.get(field)) for field in COACH_ROLE_REQUIRED_REFS)
        if is_number(stake) and stake >= required_min_stake and refs_ok:
            return "clear"
    return "blocked"


def candidate_problem_fit_clear(candidate: dict[str, Any]) -> bool:
    classification = candidate.get("classification")
    if classification == "sharpen_legacy_smb":
        return candidate.get("ai_transition_pain_present") is True
    if classification == "incubate_ai_first":
        return candidate.get("ai_first_opportunity_present") is True
    return False


def candidate_fit_gate_status(receipt: dict[str, Any]) -> str:
    claimed_clear_count = receipt.get("clear_count")
    if not isinstance(claimed_clear_count, int) or claimed_clear_count < 1:
        return "blocked"
    for candidate in receipt.get("candidates", []):
        if not isinstance(candidate, dict) or candidate.get("status") not in CANDIDATE_FIT_CLEAR_STATUSES:
            continue
        classification_clear = candidate.get("classification") in CANDIDATE_FIT_CLASSIFICATIONS and has_ref(
            candidate.get("classification_ref")
        )
        owner_operator_clear = (
            candidate.get("target_customer") == "smb_owner_operator"
            and candidate.get("smb_owner_operator_fit") is True
            and has_ref(candidate.get("persona_ref"))
        )
        problem_clear = (
            candidate_problem_fit_clear(candidate)
            and has_ref(candidate.get("problem_statement"))
            and has_ref(candidate.get("problem_ref"))
        )
        if classification_clear and owner_operator_clear and problem_clear and candidate.get("target_drift_flags") == []:
            return "clear"
    return "blocked"


def owner_voice_gate_status(receipt: dict[str, Any]) -> str:
    claimed_clear_count = receipt.get("clear_count")
    if not isinstance(claimed_clear_count, int) or claimed_clear_count < 1:
        return "blocked"
    for surface in receipt.get("surfaces", []):
        if not isinstance(surface, dict) or surface.get("status") != "clear":
            continue
        refs_ok = all(has_ref(surface.get(field)) for field in OWNER_VOICE_REQUIRED_REFS)
        if (
            refs_ok
            and surface.get("owner_voice_present") is True
            and surface.get("community_context_present") is True
            and surface.get("zeststream_meta_voice_detected") is False
        ):
            return "clear"
    return "blocked"


def anti_pitch_voice_gate_status(receipt: dict[str, Any]) -> str:
    claimed_clear_count = receipt.get("clear_count")
    if not isinstance(claimed_clear_count, int) or claimed_clear_count < 1:
        return "blocked"
    for surface in receipt.get("surfaces", []):
        if not isinstance(surface, dict) or surface.get("status") != "clear":
            continue
        if surface.get("holding_company_story_present") is True and not surface.get("builder_framing_hits", []):
            return "clear"
    return "blocked"


def public_story_gate_status(receipt: dict[str, Any]) -> str:
    claimed_clear_count = receipt.get("clear_count")
    if not isinstance(claimed_clear_count, int) or claimed_clear_count < 1:
        return "blocked"
    for surface in receipt.get("surfaces", []):
        if not isinstance(surface, dict) or surface.get("status") != "clear":
            continue
        if (
            surface.get("receipt_story_present") is True
            and surface.get("holding_company_positioning_present") is True
            and bool(surface.get("proof_or_receipt_refs", []))
            and not surface.get("build_app_framing_hits", [])
        ):
            return "clear"
    return "blocked"


def no_custom_apps_positioning_status(
    statuses: dict[str, str | None],
    route_receipt: dict[str, Any] | None,
    supersession_receipt: dict[str, Any] | None,
) -> str:
    if statuses["public_story"] != "clear" or statuses["anti_pitch"] != "clear":
        return "blocked"
    if route_receipt is None or supersession_receipt is None:
        return "blocked"

    public_surface = route_receipt.get("public_surface", {})
    route_clear = (
        isinstance(public_surface, dict)
        and route_receipt.get("schema_version") == "zeststream.holding_company_public_story_route.v1"
        and route_receipt.get("status") == "public_story_route_committed"
        and public_surface.get("route") == "/portfolio"
        and public_surface.get("posture") == "holding_company_not_services_shop"
        and {"/workflow-factory", "/roi-calculator"}.issubset(set(public_surface.get("retired_routes", [])))
        and bool(route_receipt.get("proof_refs"))
    )
    current_status = supersession_receipt.get("current_status", {})
    supersession_clear = (
        isinstance(current_status, dict)
        and supersession_receipt.get("schema_version")
        == "zeststream.holding_company_public_surface_audit_supersession.v1"
        and current_status.get("anti_pitch_voice_surface_status") == "clear"
        and current_status.get("public_story_surface_status") == "clear"
        and current_status.get("objective_coverage_status") == "not_complete"
        and PUBLIC_STORY_ROUTE_REF in supersession_receipt.get("current_receipts", [])
    )
    if not route_clear or not supersession_clear:
        return "blocked"
    if route_receipt.get("excluded_uncommitted_surfaces"):
        return "partial"
    return "proven"


def public_story_requirement_status(
    statuses: dict[str, str | None],
    route_receipt: dict[str, Any] | None,
    supersession_receipt: dict[str, Any] | None,
) -> str:
    if statuses["public_story"] != "clear":
        return "blocked"
    if route_receipt is None or supersession_receipt is None:
        return "blocked"

    public_surface = route_receipt.get("public_surface", {})
    route_clear = (
        isinstance(public_surface, dict)
        and route_receipt.get("schema_version") == "zeststream.holding_company_public_story_route.v1"
        and route_receipt.get("status") == "public_story_route_committed"
        and public_surface.get("route") == "/portfolio"
        and public_surface.get("posture") == "holding_company_not_services_shop"
        and bool(route_receipt.get("proof_refs"))
    )
    current_status = supersession_receipt.get("current_status", {})
    supersession_clear = (
        isinstance(current_status, dict)
        and supersession_receipt.get("schema_version")
        == "zeststream.holding_company_public_surface_audit_supersession.v1"
        and current_status.get("public_story_surface_status") == "clear"
        and current_status.get("objective_coverage_status") == "not_complete"
        and PUBLIC_STORY_ROUTE_REF in supersession_receipt.get("current_receipts", [])
    )
    if not route_clear or not supersession_clear:
        return "blocked"
    if statuses["founder_post"] == "clear":
        return "proven"
    return "partial"


def mobile_eats_shipping_gate_status(receipt: dict[str, Any]) -> str:
    product_substrate_present = (
        receipt.get("repo_present") is True
        and receipt.get("share_ready_packet_present") is True
        and receipt.get("tenant_declaration_present") is True
        and receipt.get("package_manifest_present") is True
        and receipt.get("public_surface_declared") is True
        and receipt.get("substrate_share_receipt_present") is True
        and receipt.get("package_threshold_met") is True
    )
    formation_receipts_present = all(has_ref(receipt.get(field)) for field in MOBILE_EATS_FORMATION_RECEIPT_FIELDS)
    portfolio_claim_clear = (
        receipt.get("counted_as_portfolio_company") is True
        and receipt.get("first_portfolio_company_claim_clear") is True
    )
    if receipt.get("status") == "proven" and product_substrate_present and formation_receipts_present and portfolio_claim_clear:
        return "proven"
    if receipt.get("status") == "partial" and product_substrate_present:
        return "partial"
    return "blocked"


def skillos_forever_os_lock_gate_status(receipt: dict[str, Any]) -> str:
    ratification_present = receipt.get("ratification_receipts_present") is True
    v3_foundation_present = (
        receipt.get("v3_goal_present") is True
        and receipt.get("v3_scope_clarifier_present") is True
        and receipt.get("anti_punt_forbid_list_present") is True
        and ratification_present
    )
    structure_lock_present = (
        receipt.get("structure_locked_20260517") is True
        and has_ref(receipt.get("structure_lock_receipt_ref"))
        and has_ref(receipt.get("structure_lock_receipt_sha256"))
    )
    if receipt.get("status") == "proven" and v3_foundation_present and structure_lock_present:
        return "proven"
    if receipt.get("status") == "partial" and v3_foundation_present:
        return "partial"
    return "blocked"


def anthropic_adoption_gate_status(receipt: dict[str, Any]) -> str:
    min_repo_count = receipt.get("min_real_consumer_repo_count")
    real_repo_count = receipt.get("real_consumer_repo_count")
    distinct_target_count = receipt.get("distinct_target_count")
    if (
        receipt.get("status") == "proven"
        and receipt.get("doctor_status") == "OK"
        and isinstance(min_repo_count, int)
        and isinstance(real_repo_count, int)
        and isinstance(distinct_target_count, int)
        and real_repo_count >= min_repo_count
        and distinct_target_count >= min_repo_count
        and receipt.get("target_repos_remaining_to_min_target_count") == 0
        and receipt.get("packages_phantom_fail") == 0
        and receipt.get("all_expected_events_present") is True
        and receipt.get("all_expected_repos_present") is True
    ):
        return "proven"
    return "blocked"


def progress_velocity_gate_status(receipt: dict[str, Any]) -> str:
    surfaces = [surface for surface in receipt.get("surface_counts", []) if isinstance(surface, dict)]
    computed_total = sum(surface.get("commit_count", 0) for surface in surfaces)
    target_min_commits = receipt.get("target_min_commits")
    target_surface_count = receipt.get("target_surface_count")
    if (
        receipt.get("status") == "proven"
        and receipt.get("exact_surface_set_established") is True
        and isinstance(target_min_commits, int)
        and isinstance(target_surface_count, int)
        and isinstance(receipt.get("target_window_days"), int)
        and computed_total >= target_min_commits
        and receipt.get("measured_total_commit_count") == computed_total
        and len(surfaces) == target_surface_count
        and all(surface.get("commit_count", 0) > 0 for surface in surfaces)
    ):
        return "proven"
    return "blocked"


def brand_voice_skill_gate_status(receipt: dict[str, Any]) -> str:
    claimed_clear_count = receipt.get("clear_count")
    if not isinstance(claimed_clear_count, int) or claimed_clear_count < 1:
        return "blocked"
    if receipt.get("required_positioning") != PUBLIC_POSITIONING_REQUIRED:
        return "blocked"
    for skill in receipt.get("skills", []):
        if not isinstance(skill, dict) or skill.get("status") not in BRAND_VOICE_CLEAR_STATUSES:
            continue
        if (
            skill.get("jsm_managed") is True
            and skill.get("holding_company_canon_present") is True
            and skill.get("grounding_rules_present") is True
            and skill.get("builder_frame_rejection_present") is True
            and has_ref(skill.get("approved_update_receipt"))
            and skill.get("required_positioning") == PUBLIC_POSITIONING_REQUIRED
        ):
            return "clear"
    return "blocked"


def recent_brand_voice_claim_status(receipt: dict[str, Any], anti_pitch_status: str | None) -> str:
    if brand_voice_skill_gate_status(receipt) == "clear":
        return "proven"
    grounding_present = any(
        isinstance(skill, dict) and skill.get("grounding_rules_present") is True
        for skill in receipt.get("skills", [])
    )
    if grounding_present and anti_pitch_status == "clear":
        return "partial"
    return "blocked"


def anti_pitch_requirement_status(statuses: dict[str, str | None]) -> str:
    if statuses["anti_pitch"] != "clear":
        return "blocked"
    if statuses["brand_voice"] == "clear" and statuses["founder_post"] == "clear":
        return "proven"
    return "partial"


def founder_post_voice_gate_status(receipt: dict[str, Any]) -> str:
    claimed_clear_count = receipt.get("clear_count")
    if not isinstance(claimed_clear_count, int) or claimed_clear_count < 1:
        return "blocked"
    for post in receipt.get("posts", []):
        if not isinstance(post, dict) or post.get("status") not in FOUNDER_POST_CLEAR_STATUSES:
            continue
        if (
            post.get("holding_company_positioning_present") is True
            and post.get("receipt_story_present") is True
            and bool(post.get("proof_or_receipt_refs", []))
            and not post.get("builder_framing_hits", [])
            and post.get("claim_fact_check_status") in FOUNDER_POST_FACT_CHECK_CLEAR
            and post.get("human_ratification_required") is True
            and has_ref(post.get("publisher_receipt_ref"))
        ):
            return "clear"
    return "blocked"


def brand_naming_gate_status(receipt: dict[str, Any]) -> str:
    claimed_clear_count = receipt.get("clear_count")
    if not isinstance(claimed_clear_count, int) or claimed_clear_count < 1:
        return "blocked"
    for row in receipt.get("names", []):
        if not isinstance(row, dict) or row.get("status") not in BRAND_NAMING_CLEAR_STATUSES:
            continue
        refs_ok = all(has_ref(row.get(field)) for field in BRAND_NAMING_REQUIRED_REFS)
        if (
            row.get("own_brand_name") is True
            and row.get("owner_involved_in_name") is True
            and row.get("community_context_in_name") is True
            and refs_ok
            and row.get("prohibited_name_flags") == []
            and bool(row.get("evidence_refs"))
        ):
            return "clear"
    return "blocked"


def peel_interview_qualifies(interview: dict[str, Any]) -> bool:
    signal = interview.get("buying_signal", {})
    return bool(
        isinstance(signal, dict)
        and signal.get("would_buy") is True
        and signal.get("urgency") in PEEL_QUALIFYING_URGENCY
        and has_ref(signal.get("price_point"))
        and has_ref(signal.get("evidence_ref"))
        and has_ref(interview.get("pain_point"))
        and has_ref(interview.get("current_alternative"))
    )


def peel_gate_status(receipt: dict[str, Any]) -> str:
    claimed_clear_count = receipt.get("formation_cash_clear_count")
    required = receipt.get("required_qualified_interviews", 5)
    if not isinstance(claimed_clear_count, int) or claimed_clear_count < 1 or not isinstance(required, int):
        return "blocked"
    for candidate in receipt.get("candidates", []):
        if not isinstance(candidate, dict) or candidate.get("formation_cash_status") not in {"clear", "committed"}:
            continue
        source = candidate.get("candidate_source") if isinstance(candidate.get("candidate_source"), dict) else {}
        source_clear = (
            source.get("source_channel") in PEEL_QUALIFYING_SOURCE_CHANNELS
            and has_ref(source.get("source_ref"))
            and has_ref(source.get("evidence_ref"))
        )
        qualified_count = sum(
            1
            for interview in candidate.get("interviews", [])
            if isinstance(interview, dict) and peel_interview_qualifies(interview)
        )
        if source_clear and qualified_count >= required:
            return "clear"
    return "blocked"


def press_release_version_ok(value: Any) -> bool:
    return isinstance(value, str) and (value == "v0.1" or value.startswith("v0.1."))


def press_gate_status(receipt: dict[str, Any]) -> str:
    claimed_clear_count = receipt.get("clear_count")
    if not isinstance(claimed_clear_count, int) or claimed_clear_count < 1:
        return "blocked"
    for press in receipt.get("presses", []):
        if not isinstance(press, dict) or press.get("status") not in PRESS_CLEAR_STATUSES:
            continue
        if (
            press_release_version_ok(press.get("release_version"))
            and all(has_ref(press.get(field)) for field in PRESS_REQUIRED_REFS)
            and bool(press.get("evidence_refs"))
        ):
            return "clear"
    return "blocked"


def pour_gate_status(receipt: dict[str, Any]) -> str:
    claimed_clear_count = receipt.get("clear_count")
    if not isinstance(claimed_clear_count, int) or claimed_clear_count < 1:
        return "blocked"
    for launch in receipt.get("launches", []):
        if not isinstance(launch, dict) or launch.get("status") not in {"pour_clear", "launched"}:
            continue
        if all(has_ref(launch.get(field)) for field in POUR_REQUIRED_REFS):
            return "clear"
    return "blocked"


def shared_stack_gate_status(receipt: dict[str, Any]) -> str:
    claimed_clear_count = receipt.get("clear_count")
    declared_components = set(receipt.get("required_components", []))
    if (
        not isinstance(claimed_clear_count, int)
        or claimed_clear_count < 1
        or declared_components != SHARED_STACK_REQUIRED_COMPONENTS
    ):
        return "blocked"
    for company in receipt.get("companies", []):
        if not isinstance(company, dict) or company.get("status") != "shared_stack_clear":
            continue
        component_rows = [row for row in company.get("components", []) if isinstance(row, dict)]
        by_component = {row.get("component"): row for row in component_rows}
        if set(by_component) != SHARED_STACK_REQUIRED_COMPONENTS:
            continue
        if all(
            by_component[component].get("status") == "present"
            and has_ref(by_component[component].get("receipt_ref"))
            for component in SHARED_STACK_REQUIRED_COMPONENTS
        ):
            return "clear"
    return "blocked"


def substrate_share_receipt_present(receipt: dict[str, Any]) -> bool:
    counts = receipt.get("counts", {})
    total_packages = counts.get("total_packages") if isinstance(counts, dict) else None
    packages = receipt.get("packages", [])
    return (
        receipt.get("schema_version") == "zeststream.substrate_share_receipt.v1"
        and receipt.get("company_slug") == "mobile-eats"
        and isinstance(total_packages, int)
        and total_packages >= 9
        and isinstance(packages, list)
        and len(packages) == total_packages
        and has_ref(receipt.get("tenant_declaration"))
        and has_ref(receipt.get("package_manifest"))
    )


def shared_stack_partial_evidence_present(receipt: dict[str, Any]) -> bool:
    declared_components = set(receipt.get("required_components", []))
    if declared_components != SHARED_STACK_REQUIRED_COMPONENTS:
        return False
    for company in receipt.get("companies", []):
        if not isinstance(company, dict) or company.get("company_slug") != "mobile-eats":
            continue
        component_rows = [row for row in company.get("components", []) if isinstance(row, dict)]
        by_component = {row.get("component"): row for row in component_rows}
        return (
            set(by_component) == SHARED_STACK_REQUIRED_COMPONENTS
            and by_component["flywheel"].get("status") == "present"
            and by_component["zeststream_packages"].get("status") == "present"
            and by_component["skillos"].get("status") == "partial"
            and by_component["brand_voice"].get("status") == "partial"
            and by_component["jsm"].get("status") == "missing"
        )
    return False


def shared_substrate_requirement_status(
    shared_stack_status: str | None,
    shared_stack_receipt: dict[str, Any] | None,
    substrate_share_receipt: dict[str, Any] | None,
    anthropic_adoption_status: str | None,
) -> str:
    if (
        shared_stack_status == "clear"
        and substrate_share_receipt is not None
        and substrate_share_receipt_present(substrate_share_receipt)
        and anthropic_adoption_status == "proven"
    ):
        return "proven"
    if (
        shared_stack_status == "blocked"
        and shared_stack_receipt is not None
        and shared_stack_partial_evidence_present(shared_stack_receipt)
        and substrate_share_receipt is not None
        and substrate_share_receipt_present(substrate_share_receipt)
        and anthropic_adoption_status == "proven"
    ):
        return "partial"
    return "blocked"


def peer_coach_gate_status(receipt: dict[str, Any]) -> str:
    claimed_clear_count = receipt.get("clear_count")
    min_tier = receipt.get("required_min_owner_tier", 2)
    required_equity = receipt.get("required_peer_coach_equity_percent", 5)
    if not isinstance(claimed_clear_count, int) or claimed_clear_count < 1:
        return "blocked"
    for coach in receipt.get("peer_coaches", []):
        if not isinstance(coach, dict) or coach.get("status") not in {"eligible", "active"}:
            continue
        owner_tier = coach.get("owner_tier")
        equity = coach.get("equity_grant_percent")
        tier_ok = isinstance(owner_tier, int) and owner_tier >= min_tier
        equity_ok = is_number(equity) and equity == required_equity
        refs_ok = all(has_ref(coach.get(field)) for field in PEER_COACH_REQUIRED_REFS)
        if tier_ok and equity_ok and refs_ok:
            return "clear"
    return "blocked"


def launch_economics_gate_status(receipt: dict[str, Any]) -> str:
    launches = receipt.get("launches") if isinstance(receipt.get("launches"), list) else []
    sorted_launches = sorted(
        (row for row in launches if isinstance(row, dict)),
        key=lambda row: row.get("sequence", 0),
    )
    if receipt.get("measurement_status") != "measured_pass" or len(sorted_launches) < 2:
        return "blocked"
    for previous, current in zip(sorted_launches, sorted_launches[1:]):
        previous_hours = previous.get("peel_hours"), previous.get("press_build_hours")
        current_hours = current.get("peel_hours"), current.get("press_build_hours")
        if not all(is_number(value) for value in (*previous_hours, *current_hours)):
            continue
        previous_total = float(previous_hours[0]) + float(previous_hours[1])
        current_total = float(current_hours[0]) + float(current_hours[1])
        previous_reuse = previous.get("reused_package_count")
        current_reuse = current.get("reused_package_count")
        if (
            current_total < previous_total
            and isinstance(previous_reuse, int)
            and isinstance(current_reuse, int)
            and current_reuse >= previous_reuse
        ):
            return "clear"
    return "blocked"


def recycle_loop_gate_status(receipt: dict[str, Any]) -> str:
    claimed_clear_count = receipt.get("clear_count")
    max_window = receipt.get("required_max_propagation_window_days", 30)
    if not isinstance(claimed_clear_count, int) or claimed_clear_count < 1 or not isinstance(max_window, int):
        return "blocked"
    for item in receipt.get("friction_items", []):
        if not isinstance(item, dict) or item.get("status") != "propagated":
            continue
        window = item.get("propagation_window_days")
        refs_ok = all(has_ref(item.get(field)) for field in RECYCLE_REQUIRED_REFS)
        window_ok = isinstance(window, int) and not isinstance(window, bool) and window <= max_window
        if refs_ok and window_ok:
            return "clear"
    return "blocked"


def nonprofit_extension_gate_status(receipt: dict[str, Any]) -> str:
    claimed_clear_count = receipt.get("clear_count")
    if not isinstance(claimed_clear_count, int) or claimed_clear_count < 1:
        return "blocked"
    for initiative in receipt.get("initiatives", []):
        if not isinstance(initiative, dict) or initiative.get("status") not in {"ready", "active"}:
            continue
        refs_ok = all(has_ref(initiative.get(field)) for field in NONPROFIT_EXTENSION_REQUIRED_REFS)
        if (
            refs_ok
            and initiative.get("portfolio_company_counting_excluded") is True
            and initiative.get("commingled_owner_economics_detected") is False
        ):
            return "clear"
    return "blocked"


def lifecycle_disposition_gate_status(receipt: dict[str, Any]) -> str:
    claimed_clear_count = receipt.get("clear_count")
    if not isinstance(claimed_clear_count, int) or claimed_clear_count < 1:
        return "blocked"
    for disposition in receipt.get("dispositions", []):
        if not isinstance(disposition, dict) or disposition.get("status") != "disposition_clear":
            continue
        disposition_type = disposition.get("disposition_type")
        if disposition_type not in {"pivot", "closed", "graduated"}:
            continue
        required_refs = list(LIFECYCLE_DISPOSITION_REQUIRED_REFS)
        if disposition_type == "graduated":
            required_refs.append("graduation_terms_ref")
        if disposition_type == "pivot":
            required_refs.append("pivot_scope_ref")
        if all(has_ref(disposition.get(field)) for field in required_refs) and disposition.get("holding_plane_continues") is True:
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

    source_goal_ref = ledger.get("source_goal_ref")
    audit_ref = ledger.get("audit_ref")
    if ledger.get("objective_status") != "standing_non_closing":
        failures.append({"code": "objective_status_not_standing_non_closing", "claimed": ledger.get("objective_status")})
    if isinstance(source_goal_ref, str) and not ref_text_contains(source_goal_ref, SOURCE_GOAL_REQUIRED_PHRASES):
        failures.append({"code": "source_goal_missing_required_identity_phrases", "ref": source_goal_ref})
    if isinstance(audit_ref, str):
        audit_path = path_for_ref(audit_ref)
        if audit_path is not None and audit_path.exists():
            audit = load_json(audit_path)
            if audit.get("objective_status") != "standing_non_closing":
                failures.append(
                    {
                        "code": "audit_objective_status_not_standing_non_closing",
                        "ref": audit_ref,
                        "claimed": audit.get("objective_status"),
                    }
                )
            if audit.get("source_goal") != source_goal_ref:
                failures.append(
                    {
                        "code": "audit_source_goal_mismatch",
                        "ref": audit_ref,
                        "claimed": audit.get("source_goal"),
                        "expected": source_goal_ref,
                    }
                )
            if audit.get("summary_verdict") != "active_with_receipt_gaps":
                failures.append(
                    {
                        "code": "audit_summary_verdict_mismatch",
                        "ref": audit_ref,
                        "claimed": audit.get("summary_verdict"),
                        "expected": "active_with_receipt_gaps",
                    }
                )

    standing_requirement = requirements_by_id.get("standing_non_closing_goal")
    if standing_requirement is not None:
        evidence_refs = standing_requirement.get("evidence_refs", [])
        for required_ref, code in (
            (source_goal_ref, "standing_requirement_missing_source_goal_ref"),
            (audit_ref, "standing_requirement_missing_audit_ref"),
        ):
            if isinstance(required_ref, str) and required_ref not in evidence_refs:
                failures.append(
                    {
                        "code": code,
                        "requirement_id": "standing_non_closing_goal",
                        "required_ref": required_ref,
                    }
                )
        if standing_requirement.get("coverage_status") != "proven":
            failures.append(
                {
                    "code": "standing_requirement_status_not_proven",
                    "requirement_id": "standing_non_closing_goal",
                    "claimed": standing_requirement.get("coverage_status"),
                    "expected": "proven",
                }
            )

    management_requirement = requirements_by_id.get("management_plane_portfolio")
    if management_requirement is not None:
        evidence_refs = management_requirement.get("evidence_refs", [])
        for required_ref, code in (
            (PORTFOLIO_REGISTRY_REF, "management_plane_requirement_missing_registry_ref"),
            (audit_ref, "management_plane_requirement_missing_audit_ref"),
        ):
            if isinstance(required_ref, str) and required_ref not in evidence_refs:
                failures.append(
                    {
                        "code": code,
                        "requirement_id": "management_plane_portfolio",
                        "required_ref": required_ref,
                    }
                )

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
            if LEGAL_HOUSE_SCAFFOLD_REF not in evidence_refs:
                failures.append(
                    {
                        "code": "legal_requirement_missing_legal_house_scaffold_ref",
                        "requirement_id": "legal_structure_gate",
                        "required_ref": LEGAL_HOUSE_SCAFFOLD_REF,
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

    coach_role_path = path_for_ref(COACH_ROLE_REF)
    if coach_role_path is not None and coach_role_path.exists():
        coach_role_status = coach_role_gate_status(load_json(coach_role_path))
    else:
        coach_role_status = None
        failures.append({"code": "coach_role_ref_missing", "ref": COACH_ROLE_REF})
    if sustainable_pace_path is not None and sustainable_pace_path.exists():
        coach_pace_status = sustainable_pace_gate_status(load_json(sustainable_pace_path))
    else:
        coach_pace_status = None
    coach_requirement = requirements_by_id.get("joshua_coach_sustainable_pace")
    if coach_requirement is not None:
        evidence_refs = coach_requirement.get("evidence_refs", [])
        for required_ref, code in (
            (COACH_ROLE_REF, "coach_requirement_missing_coach_role_ref"),
            (SUSTAINABLE_PACE_REF, "coach_requirement_missing_sustainable_pace_ref"),
        ):
            if required_ref not in evidence_refs:
                failures.append(
                    {
                        "code": code,
                        "requirement_id": "joshua_coach_sustainable_pace",
                        "required_ref": required_ref,
                    }
                )
        for evidence_status, code in (
            (coach_role_status, "requirement_status_mismatch_with_coach_role_receipt"),
            (coach_pace_status, "requirement_status_mismatch_with_sustainable_pace_receipt"),
        ):
            if evidence_status == "blocked" and coach_requirement.get("coverage_status") != "blocked":
                failures.append(
                    {
                        "code": code,
                        "requirement_id": "joshua_coach_sustainable_pace",
                        "claimed": coach_requirement.get("coverage_status"),
                        "evidence_status": evidence_status,
                    }
                )

    owner_search_phasing_path = path_for_ref(OWNER_SEARCH_PHASING_REF)
    if owner_search_phasing_path is not None and owner_search_phasing_path.exists():
        owner_search_phasing_status = owner_search_phasing_gate_status(load_json(owner_search_phasing_path))
        owner_search_phasing_requirement = requirements_by_id.get("owner_search_phasing_gate")
        if owner_search_phasing_requirement is not None:
            evidence_refs = owner_search_phasing_requirement.get("evidence_refs", [])
            if OWNER_SEARCH_PHASING_REF not in evidence_refs:
                failures.append(
                    {
                        "code": "owner_search_requirement_missing_phasing_ref",
                        "requirement_id": "owner_search_phasing_gate",
                        "required_ref": OWNER_SEARCH_PHASING_REF,
                    }
                )
            if owner_search_phasing_status == "blocked" and owner_search_phasing_requirement.get("coverage_status") != "blocked":
                failures.append(
                    {
                        "code": "requirement_status_mismatch_with_owner_search_phasing_receipt",
                        "requirement_id": "owner_search_phasing_gate",
                        "claimed": owner_search_phasing_requirement.get("coverage_status"),
                        "evidence_status": owner_search_phasing_status,
                    }
                )
    else:
        failures.append({"code": "owner_search_phasing_ref_missing", "ref": OWNER_SEARCH_PHASING_REF})

    owner_economics_path = path_for_ref(OWNER_ECONOMICS_REF)
    owner_economics_status = None
    if owner_economics_path is not None and owner_economics_path.exists():
        owner_economics_status = owner_economics_gate_status(load_json(owner_economics_path))
        owner_economics_requirement = requirements_by_id.get("owner_equity_distribution_terms")
        if owner_economics_requirement is not None:
            evidence_refs = owner_economics_requirement.get("evidence_refs", [])
            if OWNER_ECONOMICS_REF not in evidence_refs:
                failures.append(
                    {
                        "code": "owner_economics_requirement_missing_owner_economics_ref",
                        "requirement_id": "owner_equity_distribution_terms",
                        "required_ref": OWNER_ECONOMICS_REF,
                    }
                )
            if LEGAL_STRUCTURE_REF not in evidence_refs:
                failures.append(
                    {
                        "code": "owner_economics_requirement_missing_legal_structure_ref",
                        "requirement_id": "owner_equity_distribution_terms",
                        "required_ref": LEGAL_STRUCTURE_REF,
                    }
                )
            if owner_economics_status == "blocked" and owner_economics_requirement.get("coverage_status") != "blocked":
                failures.append(
                    {
                        "code": "requirement_status_mismatch_with_owner_economics_receipt",
                        "requirement_id": "owner_equity_distribution_terms",
                        "claimed": owner_economics_requirement.get("coverage_status"),
                        "evidence_status": owner_economics_status,
                    }
                )
    else:
        failures.append({"code": "owner_economics_ref_missing", "ref": OWNER_ECONOMICS_REF})

    candidate_fit_path = path_for_ref(CANDIDATE_FIT_REF)
    owner_voice_path = path_for_ref(OWNER_VOICE_REF)
    candidate_fit_status = None
    owner_voice_status = None
    if candidate_fit_path is not None and candidate_fit_path.exists():
        candidate_fit_status = candidate_fit_gate_status(load_json(candidate_fit_path))
    else:
        failures.append({"code": "candidate_fit_ref_missing", "ref": CANDIDATE_FIT_REF})
    if owner_voice_path is not None and owner_voice_path.exists():
        owner_voice_status = owner_voice_gate_status(load_json(owner_voice_path))
    else:
        failures.append({"code": "owner_voice_ref_missing", "ref": OWNER_VOICE_REF})

    customer_requirement = requirements_by_id.get("customer_smb_owner_operator")
    if customer_requirement is not None:
        evidence_refs = customer_requirement.get("evidence_refs", [])
        if CANDIDATE_FIT_REF not in evidence_refs:
            failures.append(
                {
                    "code": "customer_requirement_missing_candidate_fit_ref",
                    "requirement_id": "customer_smb_owner_operator",
                    "required_ref": CANDIDATE_FIT_REF,
                }
            )
        if OWNER_VOICE_REF not in evidence_refs:
            failures.append(
                {
                    "code": "customer_requirement_missing_owner_voice_ref",
                    "requirement_id": "customer_smb_owner_operator",
                    "required_ref": OWNER_VOICE_REF,
                }
            )
        if candidate_fit_status == "blocked" and customer_requirement.get("coverage_status") != "blocked":
            failures.append(
                {
                    "code": "requirement_status_mismatch_with_candidate_fit_receipt",
                    "requirement_id": "customer_smb_owner_operator",
                    "claimed": customer_requirement.get("coverage_status"),
                    "evidence_status": candidate_fit_status,
                }
            )
        if owner_voice_status == "blocked" and customer_requirement.get("coverage_status") != "blocked":
            failures.append(
                {
                    "code": "requirement_status_mismatch_with_owner_voice_receipt",
                    "requirement_id": "customer_smb_owner_operator",
                    "claimed": customer_requirement.get("coverage_status"),
                    "evidence_status": owner_voice_status,
                }
            )

    public_receipt_statuses: dict[str, str | None] = {
        "anti_pitch": None,
        "public_story": None,
        "brand_voice": None,
        "founder_post": None,
    }
    anti_pitch_voice_path = path_for_ref(ANTI_PITCH_VOICE_REF)
    public_story_path = path_for_ref(PUBLIC_STORY_REF)
    brand_voice_skill_path = path_for_ref(BRAND_VOICE_SKILL_REF)
    founder_post_voice_path = path_for_ref(FOUNDER_POST_VOICE_REF)
    public_story_route_path = path_for_ref(PUBLIC_STORY_ROUTE_REF)
    public_surface_supersession_path = path_for_ref(PUBLIC_SURFACE_AUDIT_SUPERSESSION_REF)
    brand_voice_receipt = None
    public_story_route_receipt = None
    public_surface_supersession_receipt = None
    if anti_pitch_voice_path is not None and anti_pitch_voice_path.exists():
        public_receipt_statuses["anti_pitch"] = anti_pitch_voice_gate_status(load_json(anti_pitch_voice_path))
    else:
        failures.append({"code": "anti_pitch_voice_ref_missing", "ref": ANTI_PITCH_VOICE_REF})
    if public_story_path is not None and public_story_path.exists():
        public_receipt_statuses["public_story"] = public_story_gate_status(load_json(public_story_path))
    else:
        failures.append({"code": "public_story_ref_missing", "ref": PUBLIC_STORY_REF})
    if brand_voice_skill_path is not None and brand_voice_skill_path.exists():
        brand_voice_receipt = load_json(brand_voice_skill_path)
        public_receipt_statuses["brand_voice"] = brand_voice_skill_gate_status(brand_voice_receipt)
    else:
        failures.append({"code": "brand_voice_skill_ref_missing", "ref": BRAND_VOICE_SKILL_REF})
    if founder_post_voice_path is not None and founder_post_voice_path.exists():
        public_receipt_statuses["founder_post"] = founder_post_voice_gate_status(load_json(founder_post_voice_path))
    else:
        failures.append({"code": "founder_post_voice_ref_missing", "ref": FOUNDER_POST_VOICE_REF})
    if public_story_route_path is not None and public_story_route_path.exists():
        public_story_route_receipt = load_json(public_story_route_path)
    else:
        failures.append({"code": "public_story_route_ref_missing", "ref": PUBLIC_STORY_ROUTE_REF})
    if public_surface_supersession_path is not None and public_surface_supersession_path.exists():
        public_surface_supersession_receipt = load_json(public_surface_supersession_path)
    else:
        failures.append(
            {"code": "public_surface_supersession_ref_missing", "ref": PUBLIC_SURFACE_AUDIT_SUPERSESSION_REF}
        )

    mobile_eats_shipping_path = path_for_ref(MOBILE_EATS_SHIPPING_REF)
    if mobile_eats_shipping_path is not None and mobile_eats_shipping_path.exists():
        mobile_eats_shipping_receipt = load_json(mobile_eats_shipping_path)
        mobile_eats_shipping_status = mobile_eats_shipping_gate_status(mobile_eats_shipping_receipt)
        mobile_eats_requirement = requirements_by_id.get("recent_mobile_eats_shipping_claim")
        if mobile_eats_requirement is not None:
            evidence_refs = mobile_eats_requirement.get("evidence_refs", [])
            for required_ref, code in (
                (MOBILE_EATS_SHIPPING_REF, "mobile_eats_requirement_missing_shipping_ref"),
                (MOBILE_EATS_SUBSTRATE_SHARE_REF, "mobile_eats_requirement_missing_substrate_share_ref"),
            ):
                if required_ref not in evidence_refs:
                    failures.append(
                        {
                            "code": code,
                            "requirement_id": "recent_mobile_eats_shipping_claim",
                            "required_ref": required_ref,
                        }
                    )
            if mobile_eats_requirement.get("coverage_status") != mobile_eats_shipping_status:
                failures.append(
                    {
                        "code": "requirement_status_mismatch_with_mobile_eats_shipping_receipt",
                        "requirement_id": "recent_mobile_eats_shipping_claim",
                        "claimed": mobile_eats_requirement.get("coverage_status"),
                        "evidence_status": mobile_eats_shipping_status,
                    }
                )
            package_count = mobile_eats_shipping_receipt.get("substrate_package_count")
            finding = mobile_eats_requirement.get("finding")
            if isinstance(package_count, int) and (
                not isinstance(finding, str) or f"{package_count:,}" not in finding
            ):
                failures.append(
                    {
                        "code": "mobile_eats_finding_missing_package_count",
                        "requirement_id": "recent_mobile_eats_shipping_claim",
                        "substrate_package_count": package_count,
                    }
                )
    else:
        failures.append({"code": "mobile_eats_shipping_ref_missing", "ref": MOBILE_EATS_SHIPPING_REF})

    skillos_forever_os_path = path_for_ref(SKILLOS_FOREVER_OS_LOCK_REF)
    if skillos_forever_os_path is not None and skillos_forever_os_path.exists():
        skillos_forever_os_status = skillos_forever_os_lock_gate_status(load_json(skillos_forever_os_path))
        skillos_forever_requirement = requirements_by_id.get("recent_skillos_forever_os_claim")
        if skillos_forever_requirement is not None:
            evidence_refs = skillos_forever_requirement.get("evidence_refs", [])
            if SKILLOS_FOREVER_OS_LOCK_REF not in evidence_refs:
                failures.append(
                    {
                        "code": "skillos_forever_os_requirement_missing_lock_ref",
                        "requirement_id": "recent_skillos_forever_os_claim",
                        "required_ref": SKILLOS_FOREVER_OS_LOCK_REF,
                    }
                )
            if skillos_forever_requirement.get("coverage_status") != skillos_forever_os_status:
                failures.append(
                    {
                        "code": "requirement_status_mismatch_with_skillos_forever_os_lock_receipt",
                        "requirement_id": "recent_skillos_forever_os_claim",
                        "claimed": skillos_forever_requirement.get("coverage_status"),
                        "evidence_status": skillos_forever_os_status,
                    }
                )
    else:
        failures.append({"code": "skillos_forever_os_lock_ref_missing", "ref": SKILLOS_FOREVER_OS_LOCK_REF})

    anthropic_adoption_path = path_for_ref(ANTHROPIC_ADOPTION_REF)
    anthropic_adoption_status = None
    if anthropic_adoption_path is not None and anthropic_adoption_path.exists():
        anthropic_adoption_status = anthropic_adoption_gate_status(load_json(anthropic_adoption_path))
        anthropic_adoption_requirement = requirements_by_id.get("recent_anthropic_adoption_claim")
        if anthropic_adoption_requirement is not None:
            evidence_refs = anthropic_adoption_requirement.get("evidence_refs", [])
            if ANTHROPIC_ADOPTION_REF not in evidence_refs:
                failures.append(
                    {
                        "code": "anthropic_adoption_requirement_missing_adoption_ref",
                        "requirement_id": "recent_anthropic_adoption_claim",
                        "required_ref": ANTHROPIC_ADOPTION_REF,
                    }
                )
            if anthropic_adoption_requirement.get("coverage_status") != anthropic_adoption_status:
                failures.append(
                    {
                        "code": "requirement_status_mismatch_with_anthropic_adoption_receipt",
                        "requirement_id": "recent_anthropic_adoption_claim",
                        "claimed": anthropic_adoption_requirement.get("coverage_status"),
                        "evidence_status": anthropic_adoption_status,
                    }
                )
    else:
        failures.append({"code": "anthropic_adoption_ref_missing", "ref": ANTHROPIC_ADOPTION_REF})

    progress_velocity_path = path_for_ref(PROGRESS_VELOCITY_REF)
    if progress_velocity_path is not None and progress_velocity_path.exists():
        progress_velocity_receipt = load_json(progress_velocity_path)
        progress_velocity_status = progress_velocity_gate_status(progress_velocity_receipt)
        progress_velocity_requirement = requirements_by_id.get("recent_progress_velocity_claim")
        if progress_velocity_requirement is not None:
            evidence_refs = progress_velocity_requirement.get("evidence_refs", [])
            if PROGRESS_VELOCITY_REF not in evidence_refs:
                failures.append(
                    {
                        "code": "progress_velocity_requirement_missing_progress_velocity_ref",
                        "requirement_id": "recent_progress_velocity_claim",
                        "required_ref": PROGRESS_VELOCITY_REF,
                    }
                )
            if progress_velocity_requirement.get("coverage_status") != progress_velocity_status:
                failures.append(
                    {
                        "code": "requirement_status_mismatch_with_progress_velocity_receipt",
                        "requirement_id": "recent_progress_velocity_claim",
                        "claimed": progress_velocity_requirement.get("coverage_status"),
                        "evidence_status": progress_velocity_status,
                    }
                )
            measured_total = progress_velocity_receipt.get("measured_total_commit_count")
            finding = progress_velocity_requirement.get("finding")
            if isinstance(measured_total, int) and (
                not isinstance(finding, str) or f"{measured_total:,}" not in finding
            ):
                failures.append(
                    {
                        "code": "progress_velocity_finding_missing_measured_total",
                        "requirement_id": "recent_progress_velocity_claim",
                        "measured_total_commit_count": measured_total,
                    }
                )
    else:
        failures.append({"code": "progress_velocity_ref_missing", "ref": PROGRESS_VELOCITY_REF})

    anti_pitch_requirement = requirements_by_id.get("anti_pitch_voice_gate")
    if anti_pitch_requirement is not None:
        anti_pitch_status = anti_pitch_requirement_status(public_receipt_statuses)
        evidence_refs = anti_pitch_requirement.get("evidence_refs", [])
        for required_ref, code in (
            (ANTI_PITCH_VOICE_REF, "anti_pitch_requirement_missing_anti_pitch_voice_ref"),
            (BRAND_VOICE_SKILL_REF, "anti_pitch_requirement_missing_brand_voice_skill_ref"),
            (FOUNDER_POST_VOICE_REF, "anti_pitch_requirement_missing_founder_post_voice_ref"),
        ):
            if required_ref not in evidence_refs:
                failures.append({"code": code, "requirement_id": "anti_pitch_voice_gate", "required_ref": required_ref})
        if anti_pitch_requirement.get("coverage_status") != anti_pitch_status:
            failures.append(
                {
                    "code": "requirement_status_mismatch_with_anti_pitch_voice_receipts",
                    "requirement_id": "anti_pitch_voice_gate",
                    "claimed": anti_pitch_requirement.get("coverage_status"),
                    "evidence_status": anti_pitch_status,
                }
            )
        if public_receipt_statuses["anti_pitch"] == "blocked" and anti_pitch_requirement.get("coverage_status") != "blocked":
            failures.append(
                {
                    "code": "requirement_status_mismatch_with_anti_pitch_voice_receipt",
                    "requirement_id": "anti_pitch_voice_gate",
                    "claimed": anti_pitch_requirement.get("coverage_status"),
                    "evidence_status": public_receipt_statuses["anti_pitch"],
                }
            )
        for status_key, code in (
            ("brand_voice", "proven_requirement_has_blocked_brand_voice_skill_receipt"),
            ("founder_post", "proven_requirement_has_blocked_founder_post_voice_receipt"),
        ):
            if public_receipt_statuses[status_key] == "blocked" and anti_pitch_requirement.get("coverage_status") == "proven":
                failures.append({"code": code, "requirement_id": "anti_pitch_voice_gate"})

    brand_voice_requirement = requirements_by_id.get("recent_brand_voice_claim")
    if brand_voice_requirement is not None and brand_voice_receipt is not None:
        recent_brand_voice_status = recent_brand_voice_claim_status(
            brand_voice_receipt,
            public_receipt_statuses["anti_pitch"],
        )
        evidence_refs = brand_voice_requirement.get("evidence_refs", [])
        for required_ref, code in (
            (BRAND_VOICE_SKILL_REF, "brand_voice_requirement_missing_brand_voice_skill_ref"),
            (ANTI_PITCH_VOICE_REF, "brand_voice_requirement_missing_anti_pitch_voice_ref"),
        ):
            if required_ref not in evidence_refs:
                failures.append(
                    {
                        "code": code,
                        "requirement_id": "recent_brand_voice_claim",
                        "required_ref": required_ref,
                    }
                )
        if brand_voice_requirement.get("coverage_status") != recent_brand_voice_status:
            failures.append(
                {
                    "code": "requirement_status_mismatch_with_recent_brand_voice_receipts",
                    "requirement_id": "recent_brand_voice_claim",
                    "claimed": brand_voice_requirement.get("coverage_status"),
                    "evidence_status": recent_brand_voice_status,
                }
            )
        if public_receipt_statuses["brand_voice"] == "blocked" and brand_voice_requirement.get("coverage_status") == "proven":
            failures.append(
                {
                    "code": "proven_requirement_has_blocked_brand_voice_skill_receipt",
                    "requirement_id": "recent_brand_voice_claim",
                }
            )

    no_custom_apps_requirement = requirements_by_id.get("no_custom_apps_positioning")
    if no_custom_apps_requirement is not None:
        no_custom_apps_status = no_custom_apps_positioning_status(
            public_receipt_statuses,
            public_story_route_receipt,
            public_surface_supersession_receipt,
        )
        evidence_refs = no_custom_apps_requirement.get("evidence_refs", [])
        for required_ref, code in (
            (PUBLIC_STORY_REF, "no_custom_apps_requirement_missing_public_story_ref"),
            (ANTI_PITCH_VOICE_REF, "no_custom_apps_requirement_missing_anti_pitch_voice_ref"),
            (PUBLIC_STORY_ROUTE_REF, "no_custom_apps_requirement_missing_public_story_route_ref"),
            (
                PUBLIC_SURFACE_AUDIT_SUPERSESSION_REF,
                "no_custom_apps_requirement_missing_public_surface_supersession_ref",
            ),
        ):
            if required_ref not in evidence_refs:
                failures.append({"code": code, "requirement_id": "no_custom_apps_positioning", "required_ref": required_ref})
        if no_custom_apps_requirement.get("coverage_status") != no_custom_apps_status:
            failures.append(
                {
                    "code": "requirement_status_mismatch_with_no_custom_apps_positioning_receipts",
                    "requirement_id": "no_custom_apps_positioning",
                    "claimed": no_custom_apps_requirement.get("coverage_status"),
                    "evidence_status": no_custom_apps_status,
                }
            )
        for status_key, code in (
            ("public_story", "requirement_status_mismatch_with_public_story_receipt"),
            ("anti_pitch", "requirement_status_mismatch_with_anti_pitch_voice_receipt"),
        ):
            if public_receipt_statuses[status_key] == "blocked" and no_custom_apps_requirement.get("coverage_status") != "blocked":
                failures.append(
                    {
                        "code": code,
                        "requirement_id": "no_custom_apps_positioning",
                        "claimed": no_custom_apps_requirement.get("coverage_status"),
                        "evidence_status": public_receipt_statuses[status_key],
                    }
                )

    public_story_requirement = requirements_by_id.get("public_story_show_receipts")
    if public_story_requirement is not None:
        public_story_status = public_story_requirement_status(
            public_receipt_statuses,
            public_story_route_receipt,
            public_surface_supersession_receipt,
        )
        evidence_refs = public_story_requirement.get("evidence_refs", [])
        for required_ref, code in (
            (PUBLIC_STORY_REF, "public_story_requirement_missing_public_story_ref"),
            (PUBLIC_STORY_ROUTE_REF, "public_story_requirement_missing_public_story_route_ref"),
            (
                PUBLIC_SURFACE_AUDIT_SUPERSESSION_REF,
                "public_story_requirement_missing_public_surface_supersession_ref",
            ),
            (FOUNDER_POST_VOICE_REF, "public_story_requirement_missing_founder_post_voice_ref"),
        ):
            if required_ref not in evidence_refs:
                failures.append({"code": code, "requirement_id": "public_story_show_receipts", "required_ref": required_ref})
        if public_story_requirement.get("coverage_status") != public_story_status:
            failures.append(
                {
                    "code": "requirement_status_mismatch_with_public_story_receipts",
                    "requirement_id": "public_story_show_receipts",
                    "claimed": public_story_requirement.get("coverage_status"),
                    "evidence_status": public_story_status,
                }
            )
        if public_receipt_statuses["public_story"] == "blocked" and public_story_requirement.get("coverage_status") != "blocked":
            failures.append(
                {
                    "code": "requirement_status_mismatch_with_public_story_receipt",
                    "requirement_id": "public_story_show_receipts",
                    "claimed": public_story_requirement.get("coverage_status"),
                    "evidence_status": public_receipt_statuses["public_story"],
                }
            )
        if public_receipt_statuses["founder_post"] == "blocked" and public_story_requirement.get("coverage_status") == "proven":
            failures.append(
                {
                    "code": "proven_requirement_has_blocked_founder_post_voice_receipt",
                    "requirement_id": "public_story_show_receipts",
                }
            )

    peel_interviews_path = path_for_ref(PEEL_INTERVIEWS_REF)
    if peel_interviews_path is not None and peel_interviews_path.exists():
        peel_status = peel_gate_status(load_json(peel_interviews_path))
        peel_requirement = requirements_by_id.get("peel_loop")
        if peel_requirement is not None:
            evidence_refs = peel_requirement.get("evidence_refs", [])
            if PEEL_INTERVIEWS_REF not in evidence_refs:
                failures.append(
                    {
                        "code": "peel_requirement_missing_interviews_ref",
                        "requirement_id": "peel_loop",
                        "required_ref": PEEL_INTERVIEWS_REF,
                    }
                )
            if CANDIDATE_FIT_REF not in evidence_refs:
                failures.append(
                    {
                        "code": "peel_requirement_missing_candidate_fit_ref",
                        "requirement_id": "peel_loop",
                        "required_ref": CANDIDATE_FIT_REF,
                    }
                )
            if peel_status == "blocked" and peel_requirement.get("coverage_status") != "blocked":
                failures.append(
                    {
                        "code": "requirement_status_mismatch_with_peel_interviews_receipt",
                        "requirement_id": "peel_loop",
                        "claimed": peel_requirement.get("coverage_status"),
                        "evidence_status": peel_status,
                    }
                )
    else:
        failures.append({"code": "peel_interviews_ref_missing", "ref": PEEL_INTERVIEWS_REF})

    press_readiness_path = path_for_ref(PRESS_READINESS_REF)
    if press_readiness_path is not None and press_readiness_path.exists():
        press_status = press_gate_status(load_json(press_readiness_path))
        press_requirement = requirements_by_id.get("press_loop")
        if press_requirement is not None:
            evidence_refs = press_requirement.get("evidence_refs", [])
            if PRESS_READINESS_REF not in evidence_refs:
                failures.append(
                    {
                        "code": "press_requirement_missing_press_readiness_ref",
                        "requirement_id": "press_loop",
                        "required_ref": PRESS_READINESS_REF,
                    }
                )
            if OWNER_ECONOMICS_REF not in evidence_refs:
                failures.append(
                    {
                        "code": "press_requirement_missing_owner_economics_ref",
                        "requirement_id": "press_loop",
                        "required_ref": OWNER_ECONOMICS_REF,
                    }
                )
            if press_status == "blocked" and press_requirement.get("coverage_status") != "blocked":
                failures.append(
                    {
                        "code": "requirement_status_mismatch_with_press_readiness_receipt",
                        "requirement_id": "press_loop",
                        "claimed": press_requirement.get("coverage_status"),
                        "evidence_status": press_status,
                    }
                )
    else:
        failures.append({"code": "press_readiness_ref_missing", "ref": PRESS_READINESS_REF})

    pour_readiness_path = path_for_ref(POUR_READINESS_REF)
    pour_status = None
    if pour_readiness_path is not None and pour_readiness_path.exists():
        pour_status = pour_gate_status(load_json(pour_readiness_path))
        pour_requirement = requirements_by_id.get("pour_loop")
        if pour_requirement is not None:
            evidence_refs = pour_requirement.get("evidence_refs", [])
            if POUR_READINESS_REF not in evidence_refs:
                failures.append(
                    {
                        "code": "pour_requirement_missing_pour_readiness_ref",
                        "requirement_id": "pour_loop",
                        "required_ref": POUR_READINESS_REF,
                    }
                )
            if pour_status == "blocked" and pour_requirement.get("coverage_status") != "blocked":
                failures.append(
                    {
                        "code": "requirement_status_mismatch_with_pour_readiness_receipt",
                        "requirement_id": "pour_loop",
                        "claimed": pour_requirement.get("coverage_status"),
                        "evidence_status": pour_status,
                    }
                )
    else:
        failures.append({"code": "pour_readiness_ref_missing", "ref": POUR_READINESS_REF})

    brand_naming_path = path_for_ref(BRAND_NAMING_REF)
    if brand_naming_path is not None and brand_naming_path.exists():
        brand_naming_status = brand_naming_gate_status(load_json(brand_naming_path))
    else:
        brand_naming_status = None
        failures.append({"code": "brand_naming_ref_missing", "ref": BRAND_NAMING_REF})
    own_brand_requirement = requirements_by_id.get("each_business_own_brand_owner_customers")
    if own_brand_requirement is not None:
        evidence_refs = own_brand_requirement.get("evidence_refs", [])
        for required_ref, code in (
            (BRAND_NAMING_REF, "own_brand_requirement_missing_brand_naming_ref"),
            (POUR_READINESS_REF, "own_brand_requirement_missing_pour_readiness_ref"),
            (PORTFOLIO_REGISTRY_REF, "own_brand_requirement_missing_registry_ref"),
        ):
            if required_ref not in evidence_refs:
                failures.append(
                    {
                        "code": code,
                        "requirement_id": "each_business_own_brand_owner_customers",
                        "required_ref": required_ref,
                    }
                )
        for evidence_status, code in (
            (brand_naming_status, "requirement_status_mismatch_with_brand_naming_receipt"),
            (pour_status, "requirement_status_mismatch_with_pour_readiness_receipt"),
        ):
            if evidence_status == "blocked" and own_brand_requirement.get("coverage_status") != "blocked":
                failures.append(
                    {
                        "code": code,
                        "requirement_id": "each_business_own_brand_owner_customers",
                        "claimed": own_brand_requirement.get("coverage_status"),
                        "evidence_status": evidence_status,
                    }
                )

    launch_economics_path = path_for_ref(LAUNCH_ECONOMICS_REF)
    if launch_economics_path is not None and launch_economics_path.exists():
        launch_economics_status = launch_economics_gate_status(load_json(launch_economics_path))
        launch_economics_requirement = requirements_by_id.get("n_plus_one_cheaper_than_n")
        if launch_economics_requirement is not None:
            evidence_refs = launch_economics_requirement.get("evidence_refs", [])
            if LAUNCH_ECONOMICS_REF not in evidence_refs:
                failures.append(
                    {
                        "code": "n_plus_one_requirement_missing_launch_economics_ref",
                        "requirement_id": "n_plus_one_cheaper_than_n",
                        "required_ref": LAUNCH_ECONOMICS_REF,
                    }
                )
            if MOBILE_EATS_SUBSTRATE_SHARE_REF not in evidence_refs:
                failures.append(
                    {
                        "code": "n_plus_one_requirement_missing_substrate_share_ref",
                        "requirement_id": "n_plus_one_cheaper_than_n",
                        "required_ref": MOBILE_EATS_SUBSTRATE_SHARE_REF,
                    }
                )
            if launch_economics_status == "blocked" and launch_economics_requirement.get("coverage_status") != "blocked":
                failures.append(
                    {
                        "code": "requirement_status_mismatch_with_launch_economics_receipt",
                        "requirement_id": "n_plus_one_cheaper_than_n",
                        "claimed": launch_economics_requirement.get("coverage_status"),
                        "evidence_status": launch_economics_status,
                    }
                )
    else:
        failures.append({"code": "launch_economics_ref_missing", "ref": LAUNCH_ECONOMICS_REF})

    recycle_loop_path = path_for_ref(RECYCLE_LOOP_REF)
    if recycle_loop_path is not None and recycle_loop_path.exists():
        recycle_status = recycle_loop_gate_status(load_json(recycle_loop_path))
        recycle_requirement = requirements_by_id.get("recycle_loop")
        if recycle_requirement is not None:
            evidence_refs = recycle_requirement.get("evidence_refs", [])
            if RECYCLE_LOOP_REF not in evidence_refs:
                failures.append(
                    {
                        "code": "recycle_requirement_missing_recycle_loop_ref",
                        "requirement_id": "recycle_loop",
                        "required_ref": RECYCLE_LOOP_REF,
                    }
                )
            if LAUNCH_ECONOMICS_REF not in evidence_refs:
                failures.append(
                    {
                        "code": "recycle_requirement_missing_launch_economics_ref",
                        "requirement_id": "recycle_loop",
                        "required_ref": LAUNCH_ECONOMICS_REF,
                    }
                )
            if recycle_status == "blocked" and recycle_requirement.get("coverage_status") != "blocked":
                failures.append(
                    {
                        "code": "requirement_status_mismatch_with_recycle_loop_receipt",
                        "requirement_id": "recycle_loop",
                        "claimed": recycle_requirement.get("coverage_status"),
                        "evidence_status": recycle_status,
                    }
                )
    else:
        failures.append({"code": "recycle_loop_ref_missing", "ref": RECYCLE_LOOP_REF})

    shared_stack_path = path_for_ref(SHARED_STACK_REF)
    peer_coach_path = path_for_ref(PEER_COACH_REF)
    shared_stack_status = None
    shared_stack_receipt = None
    substrate_share_receipt = None
    peer_coach_status = None
    if shared_stack_path is not None and shared_stack_path.exists():
        shared_stack_receipt = load_json(shared_stack_path)
        shared_stack_status = shared_stack_gate_status(shared_stack_receipt)
    else:
        failures.append({"code": "shared_stack_ref_missing", "ref": SHARED_STACK_REF})
    substrate_share_path = path_for_ref(MOBILE_EATS_SUBSTRATE_SHARE_REF)
    if substrate_share_path is not None and substrate_share_path.exists():
        substrate_share_receipt = load_json(substrate_share_path)
    else:
        failures.append({"code": "mobile_eats_substrate_share_ref_missing", "ref": MOBILE_EATS_SUBSTRATE_SHARE_REF})
    if peer_coach_path is not None and peer_coach_path.exists():
        peer_coach_status = peer_coach_gate_status(load_json(peer_coach_path))
    else:
        failures.append({"code": "peer_coach_ref_missing", "ref": PEER_COACH_REF})

    shared_substrate_requirement = requirements_by_id.get("shared_substrate_stack")
    if shared_substrate_requirement is not None:
        shared_substrate_status = shared_substrate_requirement_status(
            shared_stack_status,
            shared_stack_receipt,
            substrate_share_receipt,
            anthropic_adoption_status,
        )
        evidence_refs = shared_substrate_requirement.get("evidence_refs", [])
        for required_ref, code in (
            (SHARED_STACK_REF, "shared_substrate_requirement_missing_shared_stack_ref"),
            (MOBILE_EATS_SUBSTRATE_SHARE_REF, "shared_substrate_requirement_missing_substrate_share_ref"),
            (ANTHROPIC_ADOPTION_REF, "shared_substrate_requirement_missing_anthropic_adoption_ref"),
        ):
            if required_ref not in evidence_refs:
                failures.append(
                    {
                        "code": code,
                        "requirement_id": "shared_substrate_stack",
                        "required_ref": required_ref,
                    }
                )
        if shared_substrate_requirement.get("coverage_status") != shared_substrate_status:
            failures.append(
                {
                    "code": "requirement_status_mismatch_with_shared_substrate_receipts",
                    "requirement_id": "shared_substrate_stack",
                    "claimed": shared_substrate_requirement.get("coverage_status"),
                    "evidence_status": shared_substrate_status,
                }
            )
        if shared_stack_status == "blocked" and shared_substrate_requirement.get("coverage_status") == "proven":
            failures.append(
                {
                    "code": "proven_requirement_has_blocked_shared_stack_receipt",
                    "requirement_id": "shared_substrate_stack",
                    "claimed": shared_substrate_requirement.get("coverage_status"),
                    "evidence_status": shared_stack_status,
                }
            )

    nurture_requirement = requirements_by_id.get("nurture_loop")
    if nurture_requirement is not None:
        evidence_refs = nurture_requirement.get("evidence_refs", [])
        if SHARED_STACK_REF not in evidence_refs:
            failures.append(
                {
                    "code": "nurture_requirement_missing_shared_stack_ref",
                    "requirement_id": "nurture_loop",
                    "required_ref": SHARED_STACK_REF,
                }
            )
        if PEER_COACH_REF not in evidence_refs:
            failures.append(
                {
                    "code": "nurture_requirement_missing_peer_coach_ref",
                    "requirement_id": "nurture_loop",
                    "required_ref": PEER_COACH_REF,
                }
            )
        if shared_stack_status == "blocked" and nurture_requirement.get("coverage_status") != "blocked":
            failures.append(
                {
                    "code": "requirement_status_mismatch_with_shared_stack_receipt",
                    "requirement_id": "nurture_loop",
                    "claimed": nurture_requirement.get("coverage_status"),
                    "evidence_status": shared_stack_status,
                }
            )
        if peer_coach_status == "blocked" and nurture_requirement.get("coverage_status") != "blocked":
            failures.append(
                {
                    "code": "requirement_status_mismatch_with_peer_coach_receipt",
                    "requirement_id": "nurture_loop",
                    "claimed": nurture_requirement.get("coverage_status"),
                    "evidence_status": peer_coach_status,
                }
            )

    operating_health_path = path_for_ref(OPERATING_HEALTH_REF)
    operating_health_status = None
    if operating_health_path is not None and operating_health_path.exists():
        operating_health_status = operating_health_gate_status(load_json(operating_health_path))
    else:
        failures.append({"code": "operating_health_ref_missing", "ref": OPERATING_HEALTH_REF})

    one_year_requirement = requirements_by_id.get("one_year_small_portfolio_making_money")
    if one_year_requirement is not None:
        evidence_refs = one_year_requirement.get("evidence_refs", [])
        for required_ref, code in (
            (PORTFOLIO_REGISTRY_REF, "one_year_requirement_missing_registry_ref"),
            (OWNER_ECONOMICS_REF, "one_year_requirement_missing_owner_economics_ref"),
            (OPERATING_HEALTH_REF, "one_year_requirement_missing_operating_health_ref"),
            (SHARED_STACK_REF, "one_year_requirement_missing_shared_stack_ref"),
        ):
            if required_ref not in evidence_refs:
                failures.append(
                    {
                        "code": code,
                        "requirement_id": "one_year_small_portfolio_making_money",
                        "required_ref": required_ref,
                    }
                )
        for evidence_status, code in (
            (owner_economics_status, "requirement_status_mismatch_with_owner_economics_receipt"),
            (operating_health_status, "requirement_status_mismatch_with_operating_health_receipt"),
            (shared_stack_status, "requirement_status_mismatch_with_shared_stack_receipt"),
        ):
            if evidence_status == "blocked" and one_year_requirement.get("coverage_status") != "blocked":
                failures.append(
                    {
                        "code": code,
                        "requirement_id": "one_year_small_portfolio_making_money",
                        "claimed": one_year_requirement.get("coverage_status"),
                        "evidence_status": evidence_status,
                    }
                )

    nonprofit_extension_path = path_for_ref(NONPROFIT_EXTENSION_REF)
    if nonprofit_extension_path is not None and nonprofit_extension_path.exists():
        nonprofit_extension_status = nonprofit_extension_gate_status(load_json(nonprofit_extension_path))
        nonprofit_requirement = requirements_by_id.get("future_nonprofit_extension")
        if nonprofit_requirement is not None:
            evidence_refs = nonprofit_requirement.get("evidence_refs", [])
            if NONPROFIT_EXTENSION_REF not in evidence_refs:
                failures.append(
                    {
                        "code": "future_nonprofit_requirement_missing_nonprofit_extension_ref",
                        "requirement_id": "future_nonprofit_extension",
                        "required_ref": NONPROFIT_EXTENSION_REF,
                    }
                )
            if nonprofit_extension_status == "blocked" and nonprofit_requirement.get("coverage_status") != "deferred":
                failures.append(
                    {
                        "code": "requirement_status_mismatch_with_nonprofit_extension_receipt",
                        "requirement_id": "future_nonprofit_extension",
                        "claimed": nonprofit_requirement.get("coverage_status"),
                        "expected": "deferred",
                        "evidence_status": nonprofit_extension_status,
                    }
                )
    else:
        failures.append({"code": "nonprofit_extension_ref_missing", "ref": NONPROFIT_EXTENSION_REF})

    lifecycle_disposition_path = path_for_ref(LIFECYCLE_DISPOSITION_REF)
    if lifecycle_disposition_path is not None and lifecycle_disposition_path.exists():
        lifecycle_disposition_status = lifecycle_disposition_gate_status(load_json(lifecycle_disposition_path))
        lifecycle_requirement = requirements_by_id.get("company_close_pivot_graduate")
        if lifecycle_requirement is not None:
            evidence_refs = lifecycle_requirement.get("evidence_refs", [])
            if LIFECYCLE_DISPOSITION_REF not in evidence_refs:
                failures.append(
                    {
                        "code": "lifecycle_requirement_missing_lifecycle_disposition_ref",
                        "requirement_id": "company_close_pivot_graduate",
                        "required_ref": LIFECYCLE_DISPOSITION_REF,
                    }
                )
            if lifecycle_disposition_status == "blocked" and lifecycle_requirement.get("coverage_status") != "deferred":
                failures.append(
                    {
                        "code": "requirement_status_mismatch_with_lifecycle_disposition_receipt",
                        "requirement_id": "company_close_pivot_graduate",
                        "claimed": lifecycle_requirement.get("coverage_status"),
                        "expected": "deferred",
                        "evidence_status": lifecycle_disposition_status,
                    }
                )
    else:
        failures.append({"code": "lifecycle_disposition_ref_missing", "ref": LIFECYCLE_DISPOSITION_REF})

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
            finding = requirement.get("finding")
            if requirement_id == "management_plane_portfolio" and (
                not isinstance(finding, str) or str(counted_portfolio_companies) not in finding
            ):
                failures.append(
                    {
                        "code": "portfolio_finding_missing_counted_company_count",
                        "requirement_id": requirement_id,
                        "counted_portfolio_companies": counted_portfolio_companies,
                    }
                )
        portfolio_existence_requirement = requirements_by_id.get("portfolio_company_existence_gate")
        if portfolio_existence_requirement is not None:
            evidence_refs = portfolio_existence_requirement.get("evidence_refs", [])
            if MOBILE_EATS_SHIPPING_REF not in evidence_refs:
                failures.append(
                    {
                        "code": "portfolio_existence_requirement_missing_mobile_eats_shipping_ref",
                        "requirement_id": "portfolio_company_existence_gate",
                        "required_ref": MOBILE_EATS_SHIPPING_REF,
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
