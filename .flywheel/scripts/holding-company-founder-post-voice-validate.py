#!/usr/bin/env python3
"""Validate the ZestStream holding-company founder-post voice ledger."""

from __future__ import annotations

import argparse
import json
import re
import sys
from pathlib import Path
from typing import Any

from jsonschema import Draft202012Validator, FormatChecker


ROOT = Path(__file__).resolve().parents[2]
DEFAULT_SCHEMA = ROOT / ".flywheel/validation-schema/v1/holding-company-founder-post-voice.schema.json"
DEFAULT_LEDGER = ROOT / "state/holding-company-founder-post-voice.json"
CLEAR_STATUSES = {"clear", "ratified"}
FACT_CHECK_CLEAR = {"pass", "no_claims"}
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

    computed_clear_count = 0
    post_results: list[dict[str, Any]] = []

    for post in ledger.get("posts", []):
        if not isinstance(post, dict):
            continue
        post_id = post.get("post_id")
        status = post.get("status")
        clear_claim = status in CLEAR_STATUSES
        builder_hits = post.get("builder_framing_hits", [])
        proof_refs = post.get("proof_or_receipt_refs", [])
        post_failures: list[dict[str, Any]] = []

        if clear_claim and post.get("holding_company_positioning_present") is not True:
            post_failures.append({"code": "founder_post_clear_without_holding_company_positioning"})
        if clear_claim and post.get("receipt_story_present") is not True:
            post_failures.append({"code": "founder_post_clear_without_receipt_story"})
        if clear_claim and not proof_refs:
            post_failures.append({"code": "founder_post_clear_missing_proof_refs"})
        if clear_claim and builder_hits:
            post_failures.append({"code": "founder_post_clear_with_builder_framing", "hit_count": len(builder_hits)})
        if clear_claim and post.get("claim_fact_check_status") not in FACT_CHECK_CLEAR:
            post_failures.append(
                {
                    "code": "founder_post_clear_without_fact_check_pass",
                    "claim_fact_check_status": post.get("claim_fact_check_status"),
                }
            )
        if clear_claim and post.get("human_ratification_required") is not True:
            post_failures.append({"code": "founder_post_clear_without_human_ratification_gate"})
        if clear_claim and not has_ref(post.get("publisher_receipt_ref")):
            post_failures.append({"code": "founder_post_clear_without_publisher_receipt"})
        if has_secretish_string(post):
            post_failures.append({"code": "secret_or_raw_value_shape_detected"})

        if check_paths:
            for key in ("draft_ref", "publisher_receipt_ref", "fact_check_ref"):
                ref = post.get(key)
                if isinstance(ref, str) and not ref_exists(ref):
                    post_failures.append({"code": f"{key}_missing", "ref": ref})
            for ref in proof_refs:
                if isinstance(ref, str) and not ref_exists(ref):
                    post_failures.append({"code": "proof_or_receipt_ref_missing", "ref": ref})
            for ref in post.get("evidence_refs", []):
                if isinstance(ref, str) and not ref_exists(ref):
                    post_failures.append({"code": "evidence_ref_missing", "ref": ref})
            for hit in builder_hits:
                if not isinstance(hit, dict):
                    continue
                ref = hit.get("path")
                if isinstance(ref, str) and not ref_exists(ref):
                    post_failures.append({"code": "builder_hit_path_missing", "ref": ref})

        clear = (
            clear_claim
            and post.get("holding_company_positioning_present") is True
            and post.get("receipt_story_present") is True
            and bool(proof_refs)
            and not builder_hits
            and post.get("claim_fact_check_status") in FACT_CHECK_CLEAR
            and post.get("human_ratification_required") is True
            and has_ref(post.get("publisher_receipt_ref"))
        )
        if clear and not post_failures:
            computed_clear_count += 1
        for failure in post_failures:
            failures.append({"post_id": post_id, **failure})

        post_results.append(
            {
                "post_id": post_id,
                "status": status,
                "channel": post.get("channel"),
                "holding_company_positioning_present": post.get("holding_company_positioning_present"),
                "receipt_story_present": post.get("receipt_story_present"),
                "claim_fact_check_status": post.get("claim_fact_check_status"),
                "proof_or_receipt_ref_count": len(proof_refs) if isinstance(proof_refs, list) else 0,
                "builder_framing_hit_count": len(builder_hits) if isinstance(builder_hits, list) else 0,
                "founder_post_voice_gate_status": "clear" if clear and not post_failures else "blocked",
                "failures": post_failures,
            }
        )

    claimed_clear_count = ledger.get("clear_count")
    if claimed_clear_count != computed_clear_count:
        failures.append({"code": "founder_post_clear_count_mismatch", "claimed": claimed_clear_count, "computed": computed_clear_count})

    return {
        "schema_version": "zeststream.holding_company_founder_post_voice.validation.v1",
        "status": "fail" if failures else "pass",
        "gate": ledger.get("gate"),
        "required_positioning": ledger.get("required_positioning"),
        "clear_count": computed_clear_count,
        "post_count": len(post_results),
        "posts": post_results,
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
        print("status={status} clear_count={clear_count} post_count={post_count}".format(**result))
        for failure in result["failures"]:
            print(f"FAIL {failure}")
    return 0 if result["status"] == "pass" else 1


if __name__ == "__main__":
    sys.exit(main())
