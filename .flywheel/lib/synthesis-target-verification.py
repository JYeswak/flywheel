#!/usr/bin/env python3
"""synthesis-target-verification.py — byte-identical mirror of skillos canonical.

Canonical owner: skillos:1 (commits 974fb36 + 7f938ba).
Reference: scripts/skillos_pack_feedback_pkg/triage_helpers.py.
Mirror reason: cross-orch-anti-divergence-v1.0.0; per Joshua doctrine
"everything we build is flywheel-wide, not bolted on" (2026-05-11T04:18Z).
Mirror handoff: .flywheel/handoffs/20260511T0426Z-from-flywheel-1-to-skillos-1-ack-pack-feedback-cadence-loop-b4-and-phase-c.md

When flywheel grows its own mission-claim ingestion path (none today),
this module is the single point of supersede-decision logic. The skillos-side
behavior is the source of truth — any divergence is a defect.

Usage:
    from synthesis_target_verification import synthesis_supersede_ts_for_row
    ts = synthesis_supersede_ts_for_row(receipts, gap_type, gap_hash)
    # ts is the latest verified receipt ts (or None if no valid supersede)
"""
from __future__ import annotations

from typing import Any, Iterable

GAP_TYPES_REQUIRING_VERIFICATION = frozenset({"mission_claim_unwired"})


def latest_verified_synthesis_ts(
    receipts: Iterable[dict[str, Any]],
    gap_type: str,
    gap_hash: str = "",
) -> str | None:
    """Return latest matching receipt ts.

    A receipt matches iff ALL of:
      - synthesis_target_verification.gap_type == gap_type
      - verified_targets is a non-empty list
      - If target_gap_hashes is present and non-empty, gap_hash must be a
        member. Absent/empty = broad-coverage (legacy compatibility).
    """
    best: str | None = None
    for receipt in receipts:
        ts = receipt.get("ts")
        if not isinstance(ts, str) or not ts:
            continue
        verification = receipt.get("synthesis_target_verification")
        if not isinstance(verification, dict):
            continue
        if verification.get("gap_type") != gap_type:
            continue
        verified_targets = verification.get("verified_targets")
        if not isinstance(verified_targets, list) or not verified_targets:
            continue
        target_gap_hashes = verification.get("target_gap_hashes")
        if isinstance(target_gap_hashes, list) and target_gap_hashes:
            if gap_hash and gap_hash not in target_gap_hashes:
                continue
        if best is None or ts > best:
            best = ts
    return best


def max_synthesis_ts(receipts: Iterable[dict[str, Any]]) -> str | None:
    """Legacy fallback: latest ts across all receipts (timestamp-only).

    Used for gap_types NOT in GAP_TYPES_REQUIRING_VERIFICATION.
    """
    best: str | None = None
    for receipt in receipts:
        ts = receipt.get("ts")
        if not isinstance(ts, str) or not ts:
            continue
        if best is None or ts > best:
            best = ts
    return best


def synthesis_supersede_ts_for_row(
    receipts: Iterable[dict[str, Any]],
    gap_type: str,
    gap_hash: str = "",
) -> str | None:
    """Dispatch: verified-path for guarded gap_types, legacy ts for others."""
    if gap_type in GAP_TYPES_REQUIRING_VERIFICATION:
        return latest_verified_synthesis_ts(receipts, gap_type, gap_hash)
    return max_synthesis_ts(receipts)


def receipt_has_matching_verification(
    receipt: dict[str, Any],
    gap_type: str,
    gap_hash: str = "",
) -> bool:
    """Single-receipt match check (for cadence_metric.py parity)."""
    verification = receipt.get("synthesis_target_verification")
    if not isinstance(verification, dict):
        return False
    if verification.get("gap_type") != gap_type:
        return False
    verified_targets = verification.get("verified_targets")
    if not isinstance(verified_targets, list) or not verified_targets:
        return False
    target_gap_hashes = verification.get("target_gap_hashes")
    if isinstance(target_gap_hashes, list) and target_gap_hashes:
        if gap_hash and gap_hash not in target_gap_hashes:
            return False
    return True


if __name__ == "__main__":
    # Smoke test mirrors skillos test fixtures from cross-orch handoff.
    import sys

    fixtures = [
        # Case: verified positive
        {
            "name": "verified_supersede",
            "receipts": [{
                "schema_version": "skillos.pack_synthesis_receipt.v1",
                "ts": "2026-05-11T04:34:38Z",
                "synthesis_target_verification": {
                    "gap_type": "mission_claim_unwired",
                    "target_gap_hashes": ["31b8ba7f75fb"],
                    "verified_targets": [
                        {"target_kind": "ci_script", "target_ref": "scripts/trust_gate_check.sh"}
                    ],
                },
            }],
            "gap_type": "mission_claim_unwired",
            "gap_hash": "31b8ba7f75fb",
            "want_supersede": True,
        },
        # Case: gap_hash not in list
        {
            "name": "scoped_to_other_finding",
            "receipts": [{
                "ts": "2026-05-11T04:34:38Z",
                "synthesis_target_verification": {
                    "gap_type": "mission_claim_unwired",
                    "target_gap_hashes": ["31b8ba7f75fb"],
                    "verified_targets": [{"target_kind": "ci_script", "target_ref": "x.sh"}],
                },
            }],
            "gap_type": "mission_claim_unwired",
            "gap_hash": "DIFFERENT_HASH",
            "want_supersede": False,
        },
        # Case: empty verified_targets
        {
            "name": "empty_targets",
            "receipts": [{
                "ts": "2026-05-11T04:34:38Z",
                "synthesis_target_verification": {
                    "gap_type": "mission_claim_unwired",
                    "verified_targets": [],
                },
            }],
            "gap_type": "mission_claim_unwired",
            "gap_hash": "31b8ba7f75fb",
            "want_supersede": False,
        },
        # Case: gap_type mismatch
        {
            "name": "gap_type_mismatch",
            "receipts": [{
                "ts": "2026-05-11T04:34:38Z",
                "synthesis_target_verification": {
                    "gap_type": "some_other_type",
                    "verified_targets": [{"target_kind": "ci_script", "target_ref": "x.sh"}],
                },
            }],
            "gap_type": "mission_claim_unwired",
            "gap_hash": "31b8ba7f75fb",
            "want_supersede": False,
        },
        # Case: legacy fallback (no verification field)
        {
            "name": "legacy_fallback_other_gap_type",
            "receipts": [{"ts": "2026-05-11T04:34:38Z"}],
            "gap_type": "doctor_subsystem_transition",
            "gap_hash": "x",
            "want_supersede": True,
        },
    ]
    failures = []
    for f in fixtures:
        got = synthesis_supersede_ts_for_row(f["receipts"], f["gap_type"], f["gap_hash"])
        got_supersede = got is not None
        if got_supersede != f["want_supersede"]:
            failures.append(f"FAIL {f['name']}: want_supersede={f['want_supersede']} got={got_supersede} (ts={got})")
        else:
            print(f"PASS {f['name']}: supersede={got_supersede} ts={got}")
    if failures:
        print("\n".join(failures), file=sys.stderr)
        sys.exit(1)
    print(f"\nSUMMARY pass={len(fixtures)} fail=0")
