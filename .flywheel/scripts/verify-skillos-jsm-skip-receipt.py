#!/usr/bin/env python3
"""Verify a SkillOS JSM skip receipt against the current JSM failure surface."""

from __future__ import annotations

import argparse
import json
import subprocess
import sys
from pathlib import Path
from typing import Any


EXPECTED_SCHEMA = "skillos.jsm_validate_skip_receipt.v1"
DEFAULT_RECEIPT = Path(
    "/Users/josh/Developer/skillos/state/"
    "jsm-validate-skip-receipt-agent-ergonomics-20260515T2200Z.json"
)
DEFAULT_SKILL_DIR = Path(
    "/Users/josh/.claude/skills/"
    "agent-ergonomics-and-agent-intuitiveness-maximization-for-cli-tools"
)
DEFAULT_BEAD_ID = "flywheel-75m9o"

FAILURE_PATTERNS = {
    "JSM_VALIDATE_FAIL_DIR_NAME_MISMATCH": [
        "Directory name",
        "must match skill name",
    ],
    "JSM_VALIDATE_FAIL_FILE_COUNT_OVER_50": [
        "exceeding limit of 50",
    ],
}


def load_json(path: Path) -> dict[str, Any]:
    try:
        data = json.loads(path.read_text())
    except FileNotFoundError as exc:
        raise SystemExit(f"receipt missing: {path}") from exc
    except json.JSONDecodeError as exc:
        raise SystemExit(f"receipt invalid json: {path}: {exc}") from exc
    if not isinstance(data, dict):
        raise SystemExit(f"receipt must be a JSON object: {path}")
    return data


def run_jsm(jsm_bin: str, skill_dir: Path, timeout: int) -> tuple[int, str]:
    proc = subprocess.run(
        [jsm_bin, "validate", str(skill_dir)],
        text=True,
        stdout=subprocess.PIPE,
        stderr=subprocess.STDOUT,
        timeout=timeout,
        check=False,
    )
    return proc.returncode, proc.stdout


def addressed_codes(receipt: dict[str, Any]) -> set[str]:
    codes: set[str] = set()
    for raw in receipt.get("fail_codes_addressed", []) or []:
        if not isinstance(raw, str):
            continue
        code = raw.split(" ", 1)[0].split("(", 1)[0].strip()
        if code:
            codes.add(code)
    return codes


def validate(args: argparse.Namespace) -> dict[str, Any]:
    receipt_path = Path(args.receipt)
    skill_dir = Path(args.skill_dir)
    receipt = load_json(receipt_path)
    errors: list[dict[str, str]] = []
    warnings: list[dict[str, str]] = []

    if receipt.get("schema_version") != EXPECTED_SCHEMA:
        errors.append(
            {
                "code": "RECEIPT_SCHEMA_INVALID",
                "detail": str(receipt.get("schema_version")),
            }
        )
    if receipt.get("skip_decision") != "explicit_skip_jsm_validate_for_this_skill_v1":
        errors.append(
            {
                "code": "SKIP_DECISION_INVALID",
                "detail": str(receipt.get("skip_decision")),
            }
        )

    cross_refs = receipt.get("cross_references", {})
    blockers = cross_refs.get("flywheel_blockers", []) if isinstance(cross_refs, dict) else []
    if args.bead_id not in blockers:
        errors.append(
            {
                "code": "BEAD_REF_MISSING",
                "detail": f"{args.bead_id} not in cross_references.flywheel_blockers",
            }
        )

    skip_scope = receipt.get("skip_scope", {})
    applies_to = str(skip_scope.get("applies_to", "")) if isinstance(skip_scope, dict) else ""
    if "jsm validate" not in applies_to or "jsm push" not in applies_to:
        errors.append(
            {
                "code": "SKIP_SCOPE_INCOMPLETE",
                "detail": applies_to,
            }
        )

    receipt_skill_dir = str(receipt.get("skill_dir", ""))
    if receipt_skill_dir and receipt_skill_dir != skill_dir.name:
        warnings.append(
            {
                "code": "RECEIPT_SKILL_DIR_LABEL_MISMATCH",
                "detail": f"receipt={receipt_skill_dir} actual={skill_dir.name}",
            }
        )

    rc, output = run_jsm(args.jsm_bin, skill_dir, args.timeout)
    covered_codes: list[str] = []
    missing_codes: list[str] = []
    codes = addressed_codes(receipt)
    for code, patterns in FAILURE_PATTERNS.items():
        matched = all(pattern in output for pattern in patterns)
        if matched and code in codes:
            covered_codes.append(code)
        elif matched:
            missing_codes.append(code)

    if rc == 0:
        errors.append(
            {
                "code": "JSM_VALIDATE_UNEXPECTED_PASS",
                "detail": "skip receipt is stale because jsm validate now passes",
            }
        )
    if missing_codes:
        errors.append(
            {
                "code": "JSM_FAILURE_NOT_COVERED",
                "detail": ",".join(missing_codes),
            }
        )
    if not covered_codes:
        errors.append(
            {
                "code": "NO_CURRENT_JSM_FAILURES_COVERED",
                "detail": "current jsm output did not match receipt fail_codes_addressed",
            }
        )

    status = "pass" if not errors else "fail"
    return {
        "schema_version": "flywheel.verify_skillos_jsm_skip_receipt.v1",
        "status": status,
        "bead_id": args.bead_id,
        "receipt": str(receipt_path),
        "skill_dir": str(skill_dir),
        "jsm_rc": rc,
        "covered_codes": covered_codes,
        "errors": errors,
        "warnings": warnings,
        "jsm_output_excerpt": output[:600],
    }


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--receipt", default=str(DEFAULT_RECEIPT))
    parser.add_argument("--skill-dir", default=str(DEFAULT_SKILL_DIR))
    parser.add_argument("--bead-id", default=DEFAULT_BEAD_ID)
    parser.add_argument("--jsm-bin", default="jsm")
    parser.add_argument("--timeout", type=int, default=20)
    parser.add_argument("--json", action="store_true")
    args = parser.parse_args()

    result = validate(args)
    if args.json:
        print(json.dumps(result, indent=2, sort_keys=True))
    else:
        print(f"{result['status']}: {result['bead_id']} covered={','.join(result['covered_codes'])}")
        for warning in result["warnings"]:
            print(f"WARN {warning['code']}: {warning['detail']}")
        for error in result["errors"]:
            print(f"FAIL {error['code']}: {error['detail']}")
    return 0 if result["status"] == "pass" else 1


if __name__ == "__main__":
    sys.exit(main())

# Meta-Learning Cross-References (2026-05-19)
# Batch-16 comment backfill; citations are documentation-only and do not alter runtime behavior.
# Related: `/Users/josh/Developer/skillos/.flywheel/doctrine/meta-learnings/MP-04-receipt-callback-envelope.md`
# Related: `/Users/josh/Developer/skillos/.flywheel/doctrine/meta-learnings/MP-88-content-addressed-evidence-pack.md`
