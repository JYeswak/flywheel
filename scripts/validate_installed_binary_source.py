#!/usr/bin/env python3
from __future__ import annotations

import json
import sys
from pathlib import Path
from typing import Any


ROOT = Path(__file__).resolve().parents[1]
DEFAULT_MANIFEST = ROOT / "docs/evidence/installed-binary-source-manifest.json"
DEFAULT_BEADS = ROOT / ".beads/issues.jsonl"


def load_json(path: Path) -> dict[str, Any]:
    with path.open(encoding="utf-8") as handle:
        data = json.load(handle)
    if not isinstance(data, dict):
        raise ValueError(f"{path} must contain a JSON object")
    return data


def latest_beads(path: Path) -> dict[str, dict[str, Any]]:
    rows: dict[str, dict[str, Any]] = {}
    if not path.exists():
        return rows
    with path.open(encoding="utf-8") as handle:
        for line in handle:
            line = line.strip()
            if not line:
                continue
            row = json.loads(line)
            bead_id = row.get("id")
            if isinstance(bead_id, str):
                rows[bead_id] = row
    return rows


def validate(manifest_path: Path = DEFAULT_MANIFEST, beads_path: Path = DEFAULT_BEADS) -> dict[str, Any]:
    manifest = load_json(manifest_path)
    beads = latest_beads(beads_path)
    failures: list[dict[str, str]] = []
    rows: list[dict[str, Any]] = []

    if manifest.get("schema_version") != "flywheel.installed_binary_source_manifest.v0":
        failures.append({"code": "MANIFEST_SCHEMA_INVALID", "path": str(manifest_path)})

    shipped = set(manifest.get("reduced_public_install", {}).get("shipped_binaries", []))
    if "bin/flywheel" not in shipped:
        failures.append({"code": "REDUCED_INSTALL_BINARY_MISSING", "path": "bin/flywheel"})

    for item in manifest.get("binaries", []):
        if not isinstance(item, dict):
            failures.append({"code": "BINARY_ROW_INVALID", "path": str(manifest_path)})
            continue
        name = str(item.get("name", ""))
        receipt_ref = str(item.get("closeout_receipt_ref", ""))
        source_gap_bead = str(item.get("source_gap_bead", ""))
        source_status = str(item.get("source_status", ""))
        shipped_in_reduced = bool(item.get("shipped_in_reduced_install", False))

        receipt_path = ROOT / receipt_ref
        receipt: dict[str, Any] = {}
        if not receipt_ref or not receipt_path.exists():
            failures.append({"code": "CLOSEOUT_RECEIPT_MISSING", "binary": name})
        else:
            receipt = load_json(receipt_path)

        tracked = receipt.get("installed_binary", {}).get("tracked_in_flywheel_repo")
        if tracked is False:
            if source_status != "source-gap-receipt-required":
                failures.append({"code": "UNTRACKED_BINARY_STATUS_INVALID", "binary": name})
            if not source_gap_bead:
                failures.append({"code": "SOURCE_GAP_BEAD_MISSING", "binary": name})
            elif source_gap_bead not in beads:
                failures.append({"code": "SOURCE_GAP_BEAD_NOT_FOUND", "binary": name, "bead": source_gap_bead})
        elif tracked is not True:
            failures.append({"code": "TRACKED_STATUS_MISSING", "binary": name})

        if shipped_in_reduced:
            failures.append({"code": "FULL_SUBSTRATE_BINARY_IN_REDUCED_INSTALL", "binary": name})
        if name and name in shipped:
            failures.append({"code": "REDUCED_INSTALL_SHIPS_FULL_SUBSTRATE_BINARY", "binary": name})

        rows.append(
            {
                "name": name,
                "tracked_in_flywheel_repo": tracked,
                "source_status": source_status,
                "source_gap_bead": source_gap_bead or None,
                "receipt_ref": receipt_ref or None,
                "shipped_in_reduced_install": shipped_in_reduced,
            }
        )

    status = "pass" if not failures else "fail"
    return {
        "schema_version": "flywheel.installed_binary_source_validation.v0",
        "status": status,
        "manifest": str(manifest_path.relative_to(ROOT)),
        "binary_count": len(rows),
        "rows": rows,
        "failure_count": len(failures),
        "failures": failures,
    }


def main() -> int:
    result = validate()
    json.dump(result, sys.stdout, indent=2)
    sys.stdout.write("\n")
    return 0 if result["status"] == "pass" else 1


if __name__ == "__main__":
    raise SystemExit(main())
