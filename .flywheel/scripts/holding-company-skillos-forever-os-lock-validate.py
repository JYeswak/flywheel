#!/usr/bin/env python3
"""Validate the ZestStream holding-company SkillOS Forever-OS lock ledger."""

from __future__ import annotations

import argparse
import hashlib
import json
import re
import sys
from pathlib import Path
from typing import Any

from jsonschema import Draft202012Validator, FormatChecker


ROOT = Path(__file__).resolve().parents[2]
DEFAULT_SCHEMA = ROOT / ".flywheel/validation-schema/v1/holding-company-skillos-forever-os-lock.schema.json"
DEFAULT_LEDGER = ROOT / "state/holding-company-skillos-forever-os-lock.json"
SECRETISH_RE = re.compile(r"(\$[0-9]|sk-[A-Za-z0-9]|AKIA[0-9A-Z]{16})")
STRUCTURE_LOCK_OVERCLAIM_RE = re.compile(r"\bstructure\s+locked\b|\blocked\s+2026-05-17\b", re.IGNORECASE)


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


def sha256_file(path: Path) -> str:
    digest = hashlib.sha256()
    with path.open("rb") as handle:
        for chunk in iter(lambda: handle.read(1024 * 1024), b""):
            digest.update(chunk)
    return digest.hexdigest()


def has_secretish_string(value: Any) -> bool:
    if isinstance(value, str):
        return bool(SECRETISH_RE.search(value))
    if isinstance(value, dict):
        return any(has_secretish_string(v) for v in value.values())
    if isinstance(value, list):
        return any(has_secretish_string(v) for v in value)
    return False


def non_empty_ref(value: Any) -> bool:
    return isinstance(value, str) and bool(value.strip())


def structure_lock_overclaim(value: Any) -> bool:
    return isinstance(value, str) and bool(STRUCTURE_LOCK_OVERCLAIM_RE.search(value))


def check_ref_hash(ref: Any, expected_hash: Any, code_prefix: str, failures: list[dict[str, Any]]) -> None:
    if not isinstance(ref, str):
        return
    path = path_for_ref(ref)
    if path is None:
        return
    if not path.exists():
        failures.append({"code": f"{code_prefix}_missing", "ref": ref})
        return
    if isinstance(expected_hash, str) and re.fullmatch(r"[a-f0-9]{64}", expected_hash):
        actual_hash = sha256_file(path)
        if actual_hash != expected_hash:
            failures.append({"code": f"{code_prefix}_sha256_mismatch", "ref": ref, "expected": expected_hash, "actual": actual_hash})


def validate_ledger(ledger: dict[str, Any], schema: dict[str, Any], *, check_paths: bool) -> dict[str, Any]:
    failures: list[dict[str, Any]] = []
    try:
        Draft202012Validator.check_schema(schema)
        Draft202012Validator(schema, format_checker=FormatChecker()).validate(ledger)
    except Exception as exc:
        failures.append({"code": "schema_invalid", "detail": str(exc)})

    status = ledger.get("status")
    receipts = [receipt for receipt in ledger.get("ratification_receipts", []) if isinstance(receipt, dict)]
    present_receipts = [receipt for receipt in receipts if receipt.get("status") == "present"]
    all_receipts_present = bool(receipts) and len(present_receipts) == len(receipts)

    if has_secretish_string(ledger):
        failures.append({"code": "secret_or_raw_value_shape_detected"})

    if ledger.get("ratification_receipts_present") is not all_receipts_present:
        failures.append(
            {
                "code": "ratification_receipts_present_mismatch",
                "claimed": ledger.get("ratification_receipts_present"),
                "computed": all_receipts_present,
            }
        )

    if check_paths:
        check_ref_hash(ledger.get("goal_ref"), ledger.get("goal_sha256"), "goal", failures)
        for receipt in receipts:
            before = len(failures)
            check_ref_hash(receipt.get("receipt_ref"), receipt.get("receipt_sha256"), "receipt", failures)
            if len(failures) > before:
                failures[-1]["receipt_id"] = receipt.get("receipt_id")
        structure_ref = ledger.get("structure_lock_receipt_ref")
        if isinstance(structure_ref, str):
            check_ref_hash(structure_ref, ledger.get("structure_lock_receipt_sha256"), "structure_lock", failures)
        for ref in ledger.get("inspected_paths", []):
            if isinstance(ref, str) and not ref_exists(ref):
                failures.append({"code": "inspected_path_missing", "ref": ref})
        for ref in ledger.get("evidence_refs", []):
            if isinstance(ref, str) and not ref_exists(ref):
                failures.append({"code": "evidence_ref_missing", "ref": ref})

    if status == "proven" and ledger.get("v3_goal_present") is not True:
        failures.append({"code": "proven_without_v3_goal"})
    if status == "proven" and ledger.get("v3_scope_clarifier_present") is not True:
        failures.append({"code": "proven_without_scope_clarifier"})
    if status == "proven" and ledger.get("anti_punt_forbid_list_present") is not True:
        failures.append({"code": "proven_without_anti_punt_forbid_list"})
    if status == "proven" and not all_receipts_present:
        failures.append({"code": "proven_without_ratification_receipts"})
    if (
        status == "proven"
        and (
            ledger.get("structure_locked_20260517") is not True
            or not non_empty_ref(ledger.get("structure_lock_receipt_ref"))
            or not non_empty_ref(ledger.get("structure_lock_receipt_sha256"))
        )
    ):
        failures.append({"code": "proven_without_structure_lock_receipt"})
    if ledger.get("structure_locked_20260517") is not True and structure_lock_overclaim(ledger.get("claim_text")):
        failures.append({"code": "claim_text_overstates_missing_structure_lock"})

    proven = (
        status == "proven"
        and ledger.get("v3_goal_present") is True
        and ledger.get("v3_scope_clarifier_present") is True
        and ledger.get("anti_punt_forbid_list_present") is True
        and all_receipts_present
        and ledger.get("structure_locked_20260517") is True
        and non_empty_ref(ledger.get("structure_lock_receipt_ref"))
        and non_empty_ref(ledger.get("structure_lock_receipt_sha256"))
    )

    if proven:
        gate_status = "proven"
    elif status == "partial" and all_receipts_present:
        gate_status = "partial"
    else:
        gate_status = "blocked"

    return {
        "schema_version": "zeststream.holding_company_skillos_forever_os_lock.validation.v1",
        "status": "fail" if failures else "pass",
        "gate": ledger.get("gate"),
        "forever_os_lock_gate_status": gate_status,
        "claim_text": ledger.get("claim_text"),
        "v3_goal_present": ledger.get("v3_goal_present"),
        "v3_scope_clarifier_present": ledger.get("v3_scope_clarifier_present"),
        "anti_punt_forbid_list_present": ledger.get("anti_punt_forbid_list_present"),
        "ratification_receipt_count": len(receipts),
        "ratification_receipts_present": all_receipts_present,
        "structure_locked_20260517": ledger.get("structure_locked_20260517"),
        "structure_lock_receipt_ref": ledger.get("structure_lock_receipt_ref"),
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
            "status={status} gate_status={forever_os_lock_gate_status} receipts={ratification_receipt_count} structure_locked={structure_locked_20260517}".format(
                **result
            )
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
