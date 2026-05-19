#!/usr/bin/env python3
"""Validate the holding-company recent-progress claim-honesty receipt."""

from __future__ import annotations

import argparse
import json
import re
import subprocess
import sys
from pathlib import Path
from typing import Any

from jsonschema import Draft202012Validator, FormatChecker


ROOT = Path(__file__).resolve().parents[2]
DEFAULT_SCHEMA = ROOT / ".flywheel/validation-schema/v1/holding-company-recent-progress-claim-honesty.schema.json"
DEFAULT_RECEIPT = ROOT / "state/holding-company-recent-progress-claim-honesty-20260517T1017Z.json"
SECRETISH_RE = re.compile(r"(\$[0-9]|sk-[A-Za-z0-9]|AKIA[0-9A-Z]{16})")
EXPECTED_CLAIM_IDS = {
    "anthropic_adoption",
    "mobile_eats_shipping",
    "progress_velocity",
    "skillos_forever_os_lock",
}
VALIDATOR_GATE_KEYS = {
    "anthropic_adoption": "anthropic_adoption_gate_status",
    "mobile_eats_shipping": "mobile_eats_shipping_gate_status",
    "progress_velocity": "progress_velocity_gate_status",
    "skillos_forever_os_lock": "forever_os_lock_gate_status",
}
EXPECTED_HONESTY_BY_CLAIM = {
    "anthropic_adoption": "safe_to_use",
    "mobile_eats_shipping": "formation_claim_blocked_in_text",
    "progress_velocity": "public_target_blocked_in_text",
    "skillos_forever_os_lock": "structure_lock_receipt_pending_in_text",
}


def load_json(path: Path) -> Any:
    with path.open("r", encoding="utf-8") as handle:
        return json.load(handle)


def path_for_ref(ref: str) -> Path:
    path = Path(ref)
    if not path.is_absolute():
        path = ROOT / path
    return path


def has_secretish_string(value: Any) -> bool:
    if isinstance(value, str):
        return bool(SECRETISH_RE.search(value))
    if isinstance(value, dict):
        return any(has_secretish_string(v) for v in value.values())
    if isinstance(value, list):
        return any(has_secretish_string(v) for v in value)
    return False


def run_claim_validator(claim: dict[str, Any], *, check_paths: bool) -> tuple[dict[str, Any] | None, dict[str, Any] | None]:
    validator_ref = claim.get("validator")
    ledger_ref = claim.get("ledger_ref")
    if not isinstance(validator_ref, str) or not isinstance(ledger_ref, str):
        return None, {"code": "claim_missing_validator_or_ledger_ref", "claim_id": claim.get("claim_id")}

    validator_path = path_for_ref(validator_ref)
    ledger_path = path_for_ref(ledger_ref)
    command = [sys.executable, str(validator_path), "--ledger", str(ledger_path), "--json"]
    if check_paths:
        command.insert(-1, "--check-paths")
    completed = subprocess.run(command, check=False, text=True, stdout=subprocess.PIPE, stderr=subprocess.PIPE)
    try:
        payload = json.loads(completed.stdout)
    except json.JSONDecodeError:
        payload = None

    if completed.returncode != 0:
        return payload, {
            "code": "claim_validator_failed",
            "claim_id": claim.get("claim_id"),
            "validator": validator_ref,
            "stderr": completed.stderr.strip(),
        }
    if not isinstance(payload, dict):
        return None, {"code": "claim_validator_output_invalid", "claim_id": claim.get("claim_id"), "validator": validator_ref}
    return payload, None


def validate_receipt(receipt: dict[str, Any], schema: dict[str, Any], *, check_paths: bool) -> dict[str, Any]:
    failures: list[dict[str, Any]] = []
    gate_status_by_claim: dict[str, Any] = {}

    try:
        Draft202012Validator.check_schema(schema)
        Draft202012Validator(schema, format_checker=FormatChecker()).validate(receipt)
    except Exception as exc:
        failures.append({"code": "schema_invalid", "detail": str(exc)})

    if has_secretish_string(receipt):
        failures.append({"code": "secret_or_raw_value_shape_detected"})

    claims = [row for row in receipt.get("claims", []) if isinstance(row, dict)]
    claim_ids = [str(row.get("claim_id")) for row in claims]
    duplicate_ids = sorted({claim_id for claim_id in claim_ids if claim_ids.count(claim_id) > 1})
    missing_ids = sorted(EXPECTED_CLAIM_IDS - set(claim_ids))
    unknown_ids = sorted(set(claim_ids) - EXPECTED_CLAIM_IDS)
    if duplicate_ids:
        failures.append({"code": "duplicate_claim_id", "claim_ids": duplicate_ids})
    if missing_ids:
        failures.append({"code": "missing_claim_ids", "claim_ids": missing_ids})
    if unknown_ids:
        failures.append({"code": "unknown_claim_ids", "claim_ids": unknown_ids})

    for claim in claims:
        claim_id = claim.get("claim_id")
        if not isinstance(claim_id, str):
            continue
        ledger_ref = claim.get("ledger_ref")
        validator_ref = claim.get("validator")
        ledger_path = path_for_ref(ledger_ref) if isinstance(ledger_ref, str) else None
        validator_path = path_for_ref(validator_ref) if isinstance(validator_ref, str) else None

        if check_paths:
            if ledger_path is None or not ledger_path.is_file():
                failures.append({"code": "ledger_ref_missing", "claim_id": claim_id, "ref": ledger_ref})
            if validator_path is None or not validator_path.is_file():
                failures.append({"code": "validator_ref_missing", "claim_id": claim_id, "ref": validator_ref})

        ledger = load_json(ledger_path) if ledger_path is not None and ledger_path.is_file() else {}
        if claim.get("claim_text") != ledger.get("claim_text"):
            failures.append({"code": "claim_text_mismatch", "claim_id": claim_id, "ledger_ref": ledger_ref})

        expected_honesty = EXPECTED_HONESTY_BY_CLAIM.get(claim_id)
        if expected_honesty is not None and claim.get("claim_honesty_status") != expected_honesty:
            failures.append(
                {
                    "code": "claim_honesty_status_mismatch",
                    "claim_id": claim_id,
                    "claimed": claim.get("claim_honesty_status"),
                    "expected": expected_honesty,
                }
            )

        validator_payload, validator_failure = run_claim_validator(claim, check_paths=check_paths)
        if validator_failure:
            failures.append(validator_failure)
        if validator_payload is not None:
            gate_key = VALIDATOR_GATE_KEYS.get(claim_id)
            gate_status = validator_payload.get(gate_key) if gate_key else None
            gate_status_by_claim[claim_id] = gate_status
            if claim.get("current_gate_status") != gate_status:
                failures.append(
                    {
                        "code": "current_gate_status_mismatch",
                        "claim_id": claim_id,
                        "claimed": claim.get("current_gate_status"),
                        "validator_status": gate_status,
                    }
                )

        claim_text = claim.get("claim_text", "")
        current_gate_status = claim.get("current_gate_status")
        if claim_id == "progress_velocity" and current_gate_status != "proven" and re.search(r"4,?000\+", claim_text):
            failures.append({"code": "recent_progress_claim_overstates_velocity_target", "claim_id": claim_id})
        if (
            claim_id == "mobile_eats_shipping"
            and current_gate_status != "proven"
            and re.search(r"first portfolio company on shared substrate", claim_text, re.IGNORECASE)
        ):
            failures.append({"code": "mobile_eats_first_company_overclaim", "claim_id": claim_id})
        if claim_id == "skillos_forever_os_lock" and current_gate_status != "proven":
            if re.search(r"structure locked|locked 2026-05-17", claim_text, re.IGNORECASE):
                failures.append({"code": "skillos_structure_lock_overclaim", "claim_id": claim_id})

    return {
        "schema_version": "zeststream.holding_company_recent_progress_claim_honesty.validation.v1",
        "status": "fail" if failures else "pass",
        "source_goal": receipt.get("source_goal"),
        "recent_progress_claim_honesty_status": "mixed_claims_guarded",
        "claim_count": len(claims),
        "claim_ids": sorted(claim_ids),
        "gate_status_by_claim": gate_status_by_claim,
        "failures": failures,
    }


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--receipt", type=Path, default=DEFAULT_RECEIPT)
    parser.add_argument("--schema", type=Path, default=DEFAULT_SCHEMA)
    parser.add_argument("--check-paths", action="store_true")
    parser.add_argument("--json", action="store_true")
    args = parser.parse_args()

    result = validate_receipt(load_json(args.receipt), load_json(args.schema), check_paths=args.check_paths)
    if args.json:
        print(json.dumps(result, indent=2, sort_keys=True))
    else:
        print(
            "status={status} recent_progress_claim_honesty_status={recent_progress_claim_honesty_status} "
            "claim_count={claim_count}".format(**result)
        )
        for failure in result["failures"]:
            print(f"FAIL {failure}")
    return 0 if result["status"] == "pass" else 1


if __name__ == "__main__":
    sys.exit(main())

# Meta-Learning Cross-References (2026-05-19)
# Batch-16 comment backfill; citations are documentation-only and do not alter runtime behavior.
# Related: `/Users/josh/Developer/skillos/.flywheel/doctrine/meta-learnings/MP-02-conformance-fixtures.md`
# Related: `/Users/josh/Developer/skillos/.flywheel/doctrine/meta-learnings/MP-68-schema-executable-validator-pair.md`
