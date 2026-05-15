#!/usr/bin/env python3
"""Render L168 tenant evidence packets into machine-readable patch plans."""

from __future__ import annotations

import argparse
import json
from datetime import UTC, datetime
from pathlib import Path
from typing import Any

import yaml


SCHEMA_VERSION = "flywheel.l168_registry_patch_plan.v1"


def load_json(path: Path) -> dict[str, Any]:
    with path.open("r", encoding="utf-8") as handle:
        data = json.load(handle)
    if not isinstance(data, dict):
        raise ValueError(f"{path} did not contain a JSON object")
    return data


def first_present(mapping: dict[str, Any], *keys: str) -> Any:
    for key in keys:
        value = mapping.get(key)
        if value not in (None, "", []):
            return value
    return None


def canonical_key_spec(key: str, ref: str | None, url: str | None) -> dict[str, Any]:
    upper = key.upper()
    if "DATABASE_URL" in upper or upper == "DATABASE_URL":
        return {
            "validator": "postgres_url_contains_supabase_ref",
            "expected_supabase_ref": ref,
        }
    if upper.endswith("PROJECT_REF"):
        return {"validator": "equals", "expected_value": ref}
    if "SUPABASE_URL" in upper or upper.endswith("_URL"):
        return {"validator": "equals", "expected_value": url}
    if "KEY" in upper or "JWT" in upper:
        return {"validator": "supabase_jwt_ref_claim_equals", "expected_ref_claim": ref}
    return {"validator": "equals", "expected_value": "DECISION_REQUIRED"}


def collect_key_names(known: dict[str, Any]) -> list[str]:
    keys: list[str] = []
    for field in ("candidate_server_keys", "candidate_client_keys"):
        values = known.get(field)
        if isinstance(values, list):
            keys.extend(str(value) for value in values if value)
    for value in known.get("canonical_keys", []) if isinstance(known.get("canonical_keys"), list) else []:
        keys.append(str(value))
    return list(dict.fromkeys(keys))


def registry_candidate(slug: str, known: dict[str, Any]) -> tuple[dict[str, Any] | None, list[str]]:
    infisical_project_id = first_present(known, "infisical_project_id")
    ref = first_present(
        known,
        "supabase_project_ref",
        "supabase_runtime_project_ref",
        "supabase_candidate_project_ref",
    )
    url = first_present(
        known,
        "supabase_project_url",
        "supabase_runtime_project_url",
        "supabase_candidate_project_url",
    )
    vercel_project_id = first_present(known, "vercel_project_id")
    vercel_project_name = first_present(known, "vercel_project_name")
    decision_required: list[str] = []
    if not infisical_project_id:
        decision_required.append("infisical_project_id")
    if not ref:
        decision_required.append("supabase.project_ref")
    if not url and ref:
        url = f"https://{ref}.supabase.co"
    if not url:
        decision_required.append("supabase.project_url")

    key_names = collect_key_names(known)
    if not key_names:
        decision_required.append("canonical_keys")

    if decision_required:
        return None, decision_required

    row: dict[str, Any] = {
        "infisical_project_id": infisical_project_id,
        "description": f"{slug} tenant routing row",
        "supabase": {
            "project_ref": ref,
            "project_url": url,
            "pooler_mode": known.get("pooler_mode") or "dedicated",
        },
        "canonical_keys": {
            key: canonical_key_spec(key, str(ref), str(url)) for key in key_names
        },
    }
    if vercel_project_id or vercel_project_name:
        row["vercel"] = {
            "project_id": vercel_project_id or "DECISION_REQUIRED",
            "project_name": vercel_project_name or slug,
        }
    return row, []


def declaration_overlay(slug: str, known: dict[str, Any], row: dict[str, Any] | None) -> dict[str, Any] | None:
    if row is None:
        return None
    overlay: dict[str, Any] = {
        "schema_version": "skillos.tenant_routing_repo_declaration.v1",
        "project_slug": slug,
        "infisical_project_id": row["infisical_project_id"],
        "expected_supabase_ref": row["supabase"]["project_ref"],
    }
    vercel = row.get("vercel")
    if isinstance(vercel, dict) and vercel.get("project_id") != "DECISION_REQUIRED":
        overlay["expected_vercel_project_id"] = vercel["project_id"]
    keys = list((row.get("canonical_keys") or {}).keys())
    if keys:
        overlay["deploy_targets"] = [
            {
                "kind": "tenant-bound-runtime",
                "env": "production",
                "keys": keys,
            }
        ]
    if known.get("legacy_declaration_schema_version"):
        overlay["migration_note"] = (
            "Preserve existing declaration content; add these top-level "
            "SkillOS v1 fields without deleting repo-specific metadata."
        )
    return overlay


def action_from_row(source_ref: str, row: dict[str, Any]) -> dict[str, Any]:
    slug = str(row.get("slug") or "")
    known = row.get("known_non_secret_identifiers")
    if not isinstance(known, dict):
        known = {}
    classification = str(row.get("classification") or "")
    if "skip_with_reason" in classification:
        return {
            "slug": slug,
            "action": "apply_disposition_receipt",
            "source_ref": source_ref,
            "disposition_ref": row.get("disposition_ref"),
            "status": "ready",
        }

    registry_row, missing = registry_candidate(slug, known)
    if registry_row is None:
        return {
            "slug": slug,
            "action": "decision_required",
            "source_ref": source_ref,
            "missing_fields": missing,
            "needed_decisions": row.get("skillos_needed_decision") or row.get("needs_owner_decision") or [],
            "status": "blocked_until_decision",
        }

    return {
        "slug": slug,
        "action": "apply_registry_row_and_repo_declaration",
        "source_ref": source_ref,
        "status": "ready",
        "registry_row": registry_row,
        "repo_declaration_overlay": declaration_overlay(slug, known, registry_row),
        "evidence_refs": row.get("evidence_refs") or [],
        "notes": row.get("skillos_needed_decision") or [],
    }


def actions_from_packet(path: Path, packet: dict[str, Any]) -> list[dict[str, Any]]:
    schema = packet.get("schema_version")
    actions: list[dict[str, Any]] = []
    source_ref = str(path)
    if schema == "flywheel.l168_skillos_registry_input.v1":
        for row in packet.get("rows") or []:
            if isinstance(row, dict):
                actions.append(action_from_row(source_ref, row))
    elif schema == "flywheel.l168_wave_registry_input.v1":
        failures = packet.get("current_failures") if isinstance(packet.get("current_failures"), dict) else {}
        evidence = packet.get("non_secret_evidence") if isinstance(packet.get("non_secret_evidence"), dict) else {}
        for slug, current_failures in failures.items():
            known = evidence.get(slug) if isinstance(evidence.get(slug), dict) else {}
            actions.append(
                action_from_row(
                    source_ref,
                    {
                        "slug": slug,
                        "known_non_secret_identifiers": known,
                        "current_failures": current_failures,
                        "needs_owner_decision": known.get("needs_owner_decision") or [],
                    },
                )
            )
    else:
        raise ValueError(f"unsupported packet schema in {path}: {schema}")
    return actions


def render_plan(paths: list[Path], generated_at: str) -> dict[str, Any]:
    actions: list[dict[str, Any]] = []
    for path in paths:
        actions.extend(actions_from_packet(path, load_json(path)))
    ready_count = sum(1 for action in actions if action.get("status") == "ready")
    blocked_count = sum(1 for action in actions if action.get("status") != "ready")
    return {
        "schema_version": SCHEMA_VERSION,
        "generated_at": generated_at,
        "status": "ready_with_decisions" if blocked_count else "ready",
        "source_evidence_refs": [str(path) for path in paths],
        "action_count": len(actions),
        "ready_action_count": ready_count,
        "decision_required_count": blocked_count,
        "actions": actions,
    }


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--input", action="append", required=True, type=Path)
    parser.add_argument("--out", type=Path)
    parser.add_argument("--generated-at", default=datetime.now(UTC).strftime("%Y-%m-%dT%H:%M:%SZ"))
    parser.add_argument("--json", action="store_true")
    args = parser.parse_args()

    plan = render_plan(args.input, args.generated_at)
    text = json.dumps(plan, indent=2, sort_keys=True)
    if args.out:
        args.out.parent.mkdir(parents=True, exist_ok=True)
        args.out.write_text(text + "\n", encoding="utf-8")
    if args.json or not args.out:
        print(text)
    else:
        print(yaml.safe_dump(plan, sort_keys=False), end="")
    return 0 if plan["action_count"] else 1


if __name__ == "__main__":
    raise SystemExit(main())
