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
OWNER_SEARCH_PHASING_REF = "state/holding-company-owner-search-phasing.json"
OWNER_ECONOMICS_REF = "state/holding-company-owner-economics.json"
CANDIDATE_FIT_REF = "state/holding-company-candidate-fit.json"
OWNER_VOICE_REF = "state/holding-company-owner-voice.json"
ANTI_PITCH_VOICE_REF = "state/holding-company-anti-pitch-voice.json"
PUBLIC_STORY_REF = "state/holding-company-public-story.json"
BRAND_VOICE_SKILL_REF = "state/holding-company-brand-voice-skill.json"
FOUNDER_POST_VOICE_REF = "state/holding-company-founder-post-voice.json"
PEEL_INTERVIEWS_REF = "state/holding-company-peel-interviews.json"
PRESS_READINESS_REF = "state/holding-company-press-readiness.json"
POUR_READINESS_REF = "state/holding-company-pour-readiness.json"
SHARED_STACK_REF = "state/holding-company-shared-stack.json"
PEER_COACH_REF = "state/holding-company-peer-coach.json"
LAUNCH_ECONOMICS_REF = "state/holding-company-launch-economics.json"
RECYCLE_LOOP_REF = "state/holding-company-recycle-loop.json"
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
    if anti_pitch_voice_path is not None and anti_pitch_voice_path.exists():
        public_receipt_statuses["anti_pitch"] = anti_pitch_voice_gate_status(load_json(anti_pitch_voice_path))
    else:
        failures.append({"code": "anti_pitch_voice_ref_missing", "ref": ANTI_PITCH_VOICE_REF})
    if public_story_path is not None and public_story_path.exists():
        public_receipt_statuses["public_story"] = public_story_gate_status(load_json(public_story_path))
    else:
        failures.append({"code": "public_story_ref_missing", "ref": PUBLIC_STORY_REF})
    if brand_voice_skill_path is not None and brand_voice_skill_path.exists():
        public_receipt_statuses["brand_voice"] = brand_voice_skill_gate_status(load_json(brand_voice_skill_path))
    else:
        failures.append({"code": "brand_voice_skill_ref_missing", "ref": BRAND_VOICE_SKILL_REF})
    if founder_post_voice_path is not None and founder_post_voice_path.exists():
        public_receipt_statuses["founder_post"] = founder_post_voice_gate_status(load_json(founder_post_voice_path))
    else:
        failures.append({"code": "founder_post_voice_ref_missing", "ref": FOUNDER_POST_VOICE_REF})

    anti_pitch_requirement = requirements_by_id.get("anti_pitch_voice_gate")
    if anti_pitch_requirement is not None:
        evidence_refs = anti_pitch_requirement.get("evidence_refs", [])
        for required_ref, code in (
            (ANTI_PITCH_VOICE_REF, "anti_pitch_requirement_missing_anti_pitch_voice_ref"),
            (BRAND_VOICE_SKILL_REF, "anti_pitch_requirement_missing_brand_voice_skill_ref"),
            (FOUNDER_POST_VOICE_REF, "anti_pitch_requirement_missing_founder_post_voice_ref"),
        ):
            if required_ref not in evidence_refs:
                failures.append({"code": code, "requirement_id": "anti_pitch_voice_gate", "required_ref": required_ref})
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
    if brand_voice_requirement is not None:
        evidence_refs = brand_voice_requirement.get("evidence_refs", [])
        if BRAND_VOICE_SKILL_REF not in evidence_refs:
            failures.append(
                {
                    "code": "brand_voice_requirement_missing_brand_voice_skill_ref",
                    "requirement_id": "recent_brand_voice_claim",
                    "required_ref": BRAND_VOICE_SKILL_REF,
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
        evidence_refs = no_custom_apps_requirement.get("evidence_refs", [])
        for required_ref, code in (
            (PUBLIC_STORY_REF, "no_custom_apps_requirement_missing_public_story_ref"),
            (ANTI_PITCH_VOICE_REF, "no_custom_apps_requirement_missing_anti_pitch_voice_ref"),
        ):
            if required_ref not in evidence_refs:
                failures.append({"code": code, "requirement_id": "no_custom_apps_positioning", "required_ref": required_ref})
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
        evidence_refs = public_story_requirement.get("evidence_refs", [])
        for required_ref, code in (
            (PUBLIC_STORY_REF, "public_story_requirement_missing_public_story_ref"),
            (FOUNDER_POST_VOICE_REF, "public_story_requirement_missing_founder_post_voice_ref"),
        ):
            if required_ref not in evidence_refs:
                failures.append({"code": code, "requirement_id": "public_story_show_receipts", "required_ref": required_ref})
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
    peer_coach_status = None
    if shared_stack_path is not None and shared_stack_path.exists():
        shared_stack_status = shared_stack_gate_status(load_json(shared_stack_path))
    else:
        failures.append({"code": "shared_stack_ref_missing", "ref": SHARED_STACK_REF})
    if peer_coach_path is not None and peer_coach_path.exists():
        peer_coach_status = peer_coach_gate_status(load_json(peer_coach_path))
    else:
        failures.append({"code": "peer_coach_ref_missing", "ref": PEER_COACH_REF})

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
