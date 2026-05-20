#!/usr/bin/env python3
"""Validate a ZestStream substrate-share receipt."""

from __future__ import annotations

import argparse
import json
import sys
from pathlib import Path
from typing import Any

from jsonschema import Draft202012Validator, FormatChecker


ROOT = Path(__file__).resolve().parents[2]
DEFAULT_SCHEMA = ROOT / ".flywheel/validation-schema/v1/substrate-share-receipt.schema.json"


def load_json(path: Path) -> Any:
    with path.open("r", encoding="utf-8") as handle:
        return json.load(handle)


def resolve_ref(ref: str, base_dir: Path) -> Path | None:
    if "://" in ref or ref.startswith("urn:"):
        return None
    path = Path(ref)
    if not path.is_absolute():
        path = base_dir / path
    return path


def manifest_packages(manifest_path: Path) -> dict[str, str]:
    manifest = load_json(manifest_path)
    packages: dict[str, str] = {}
    for section, scope in (("dependencies", "production"), ("devDependencies", "development")):
        deps = manifest.get(section) if isinstance(manifest, dict) else None
        if not isinstance(deps, dict):
            continue
        for name, version in deps.items():
            if str(name).startswith("@zeststream/"):
                packages[str(name)] = scope
    return packages


def validate_receipt(receipt_path: Path, schema_path: Path, *, check_paths: bool, check_manifest: bool) -> dict[str, Any]:
    receipt = load_json(receipt_path)
    schema = load_json(schema_path)
    failures: list[dict[str, str]] = []

    try:
        Draft202012Validator.check_schema(schema)
        Draft202012Validator(schema, format_checker=FormatChecker()).validate(receipt)
    except Exception as exc:
        failures.append({"code": "schema_invalid", "detail": str(exc)})

    base_dir = ROOT
    paths_to_check = [
        ("repo_path", receipt.get("repo_path")),
        ("tenant_declaration", receipt.get("tenant_declaration")),
        ("package_manifest", receipt.get("package_manifest")),
    ]
    if check_paths:
        for field, ref in paths_to_check:
            if not isinstance(ref, str):
                continue
            path = resolve_ref(ref, base_dir)
            if path is not None and not path.exists():
                failures.append({"code": f"path_missing:{field}", "ref": ref})
        for ref in receipt.get("evidence_refs", []):
            if isinstance(ref, str):
                path = resolve_ref(ref, base_dir)
                if path is not None and not path.exists():
                    failures.append({"code": "evidence_ref_missing", "ref": ref})

    packages = receipt.get("packages") if isinstance(receipt.get("packages"), list) else []
    production_count = sum(1 for row in packages if row.get("scope") == "production")
    development_count = sum(1 for row in packages if row.get("scope") == "development")
    total_count = production_count + development_count
    counts = receipt.get("counts") if isinstance(receipt.get("counts"), dict) else {}
    expected_counts = {
        "production_packages": production_count,
        "development_packages": development_count,
        "total_packages": total_count,
    }
    for field, expected in expected_counts.items():
        if counts.get(field) != expected:
            failures.append({"code": f"count_mismatch:{field}", "detail": f"declared={counts.get(field)} actual={expected}"})

    metrics = receipt.get("n_plus_one_metrics") if isinstance(receipt.get("n_plus_one_metrics"), dict) else {}
    if metrics.get("reused_package_count") != total_count:
        failures.append(
            {
                "code": "n_plus_one_reused_package_count_mismatch",
                "detail": f"declared={metrics.get('reused_package_count')} actual={total_count}",
            }
        )

    if check_manifest and isinstance(receipt.get("package_manifest"), str):
        manifest_path = resolve_ref(receipt["package_manifest"], base_dir)
        if manifest_path is not None and manifest_path.exists():
            manifest = manifest_packages(manifest_path)
            receipt_packages = {row.get("name"): row.get("scope") for row in packages if isinstance(row, dict)}
            if receipt_packages != manifest:
                failures.append(
                    {
                        "code": "manifest_package_set_mismatch",
                        "detail": f"receipt={len(receipt_packages)} manifest={len(manifest)}",
                    }
                )

    return {
        "schema_version": "zeststream.substrate_share_receipt.validation.v1",
        "receipt": str(receipt_path),
        "status": "fail" if failures else "pass",
        "company_slug": receipt.get("company_slug"),
        "counts": counts,
        "check_paths": check_paths,
        "check_manifest": check_manifest,
        "failures": failures,
    }


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("receipt", type=Path)
    parser.add_argument("--schema", type=Path, default=DEFAULT_SCHEMA)
    parser.add_argument("--check-paths", action="store_true")
    parser.add_argument("--check-manifest", action="store_true")
    parser.add_argument("--json", action="store_true")
    args = parser.parse_args()

    result = validate_receipt(args.receipt, args.schema, check_paths=args.check_paths, check_manifest=args.check_manifest)
    if args.json:
        print(json.dumps(result, indent=2, sort_keys=True))
    else:
        print(f"status={result['status']} company_slug={result['company_slug']}")
        for failure in result["failures"]:
            print(f"FAIL {failure}")
    return 0 if result["status"] == "pass" else 1


if __name__ == "__main__":
    sys.exit(main())

# Meta-Learning Cross-References (2026-05-19)
# Batch-16 comment backfill; citations are documentation-only and do not alter runtime behavior.
# Related: `/Users/josh/Developer/skillos/.flywheel/doctrine/meta-learnings/MP-04-receipt-callback-envelope.md`
# Related: `/Users/josh/Developer/skillos/.flywheel/doctrine/meta-learnings/MP-88-content-addressed-evidence-pack.md`
